
---------------PROCEDIMIENTO SELECCION DE PAISES--------------------------


CREATE OR REPLACE FUNCTION SELECCION_PAISES RETURN SYS_REFCURSOR
IS
 TYPE ref_cur IS REF CURSOR;
 p_paises ref_cur;
BEGIN
    OPEN p_paises FOR 
    SELECT * 
    FROM (
      SELECT *
      FROM LUGAR  
      WHERE Codigo IN (SELECT Lugar
                       FROM LUGAR
                       WHERE Tipo = 'AREA'
                       AND Codigo IN (SELECT Lugar 
                                      FROM BROTE)
                       )
     ORDER BY dbms_random.random)
     WHERE  rownum < 16;
    RETURN p_paises;
END;

---------------PROCEDIMIENTO SELECCION DE AREAS DE LOS PAISES INFECTADOS--------------------------

CREATE OR REPLACE FUNCTION SELECCION_AREAS(Pais LUGAR%ROWTYPE ) RETURN varrays
IS
    Areas varrays:=varrays();
    counter NUMBER :=0; 
    Area NUMBER;
    NomArea VARCHAR2(40);

    CURSOR c_area is 
    SELECT * 
    FROM (
     SELECT l.Codigo
     FROM LUGAR l INNER JOIN LUGAR m ON l.lugar = m.Codigo
     WHERE l.Codigo IN (SELECT Lugar FROM BROTE)
     AND l.Tipo = 'AREA'
     AND m.Tipo = 'PAIS'
     AND m.codigo = Pais.Codigo 
     ORDER BY dbms_random.random)
    WHERE  rownum < 3;
BEGIN
    OPEN c_area;
    DBMS_OUTPUT.PUT_LINE('-->AREAS-----------------------------------');
    LOOP
        FETCH c_area INTO Area; 
        EXIT WHEN c_area%notfound; 
        counter := counter + 1; 
        Areas.extend; 
        Areas(counter)  := Area;
        SELECT Nombre INTO NomArea FROM LUGAR WHERE Codigo=Area;
        DBMS_OUTPUT.PUT_LINE('' || NomArea);
    END LOOP;
    RETURN Areas;
END;


---------------FUNCION DE AREAS AFECTADAS--------------------------

CREATE OR REPLACE FUNCTION AREAS_AFECTADAS RETURN varrays2
IS
    Paises SYS_REFCURSOR;
    Pais LUGAR%ROWTYPE;
    
    Lugares varrays:=varrays();
    
    Areas varrays2:=varrays2();
    
    counter NUMBER :=0; 
    counter2 NUMBER :=0; 
BEGIN
    Paises:= SELECCION_PAISES;
    DBMS_OUTPUT.PUT_LINE('                                                  ');
    DBMS_OUTPUT.PUT_LINE('---------------------PAISES INFECTADOS------------------------');
    LOOP
        FETCH Paises INTO Pais;
        EXIT WHEN Paises%NOTFOUND;
        counter := counter + 1;
        DBMS_OUTPUT.PUT_LINE('                                                  ');
        DBMS_OUTPUT.PUT_LINE('--------------PAIS Nº' || Counter || ': ' || Pais.Nombre || '----------------');
        Areas.extend; 
        Areas(counter):=SELECCION_AREAS(Pais);
    END LOOP;
    Return Areas;
END;


---------------PROCEDIMIENTO SELECCION DE CENTROS DE VACUNACIÓN POR ÁREA--------------------------

CREATE OR REPLACE FUNCTION SELECCION_CENTRO(Area NUMBER ) RETURN NUMBER
IS

    CodCentro NUMBER;
    NomCentro VARCHAR2(40);
    NomArea VARCHAR2(40);

    CURSOR c_centro is 
    SELECT Codigo
    FROM CENTRO_VACUNACION
    WHERE Lugar = Area;
BEGIN
    OPEN c_centro;
    LOOP
        FETCH c_centro INTO CodCentro; 
        EXIT WHEN c_centro%notfound; 
        SELECT Nombre INTO NomCentro FROM CENTRO_VACUNACION WHERE Codigo=CodCentro;
        SELECT Nombre INTO NomArea FROM LUGAR WHERE Codigo = Area;
        DBMS_OUTPUT.PUT_LINE('-->Centro de Vacunacion: "' || NomCentro || '" correspondiente al Area: "' || NomArea || '"');
    END LOOP;
    
    RETURN CodCentro;
END;



-------------PROCEDIMIENTO AGREGAR PEDIDOS---------------------------------
CREATE OR REPLACE PROCEDURE ADD_PEDIDO(Suministro NUMBER,Centro NUMBER,Canti NUMBER,Flag Number) 
IS
   Randomprice NUMBER; 
   Organizacion NUMBER;
   Lugar NUMBER;
   MontTotal NUMBER(38,2);
BEGIN
    --Se define una cantidad aleatoria que vale el suministro generico-
    SELECT DBMS_RANDOM.value(25,100) INTO Randomprice
    FROM dual;
    MontTotal := Randomprice * Canti;
    
    --Se desglosa los datos suministrados
    select c.lugar into Lugar from CENTRO_VACUNACION c where c.codigo=centro;
    
    --Si es 0, es insumo. En caso contrario, es suministro--
    IF (FLAG = 1) THEN
        SELECT v.Organizacion 
        INTO Organizacion 
        FROM VA_OR v 
        WHERE v.Vacuna=Suministro;
    ELSE 
        SELECT Codigo 
        INTO Organizacion
        FROM ORGANIZACION
        ORDER BY dbms_random.random;
    END IF;
    
    --Si es 0, es insumo. En caso contrario, es suministro--
    IF (FLAG = 0) THEN
        INSERT INTO PEDIDO VALUES (Lugar,Organizacion,MontTotal,'ENVIADO',Suministro,null,Fecha(SYSDATE,SYSDATE),Existencia(Canti,Canti));
    ELSE 
        INSERT INTO PEDIDO VALUES (Lugar,Organizacion,MontTotal,'ENVIADO',null,Suministro,Fecha(SYSDATE,SYSDATE),Existencia(Canti,Canti));
     END IF;
END



-------------PROCEDIMIENTO AGREGAR DOSIS---------------------------------
CREATE OR REPLACE PROCEDURE ADD_DOSIS(Centro NUMBER) 
IS
    Capacid NUMBER;
    NumRandom NUMBER;
    CantNec NUMBER(38,0);
    CantReal NUMBER(38,0);
    CodVacuna NUMBER;
    NombreVac VACUNA.Nombre%TYPE;
    
    CURSOR Vacunas is 
    SELECT DISTINCT Nombre
    FROM VACUNA;
    
BEGIN
    ------QUERY REFERENTE A LA CAPACIDAD DEL CENTRO
    SELECT c.Capacidad INTO Capacid
    FROM CENTRO_VACUNACION c
    WHERE c.Codigo = Centro;
    
    ------PORCENTAJE ALEATORIO DE DOSIS 
    SELECT DBMS_RANDOM.value(25,50) INTO NumRandom 
    FROM dual; 
    
    CantReal:=Capacid*(NumRandom/100);
    
    OPEN Vacunas;
    LOOP  
       FETCH Vacunas INTO NombreVac;
       EXIT WHEN Vacunas%NOTFOUND;

    ------CANTIDAD ALEATORIA REQUERIDA DE LAS DOSIS
       SELECT DBMS_RANDOM.value(0,1) INTO CantNec
       FROM dual; 
       IF (CantNec !=0) THEN
        SELECT DBMS_RANDOM.value(1,25) INTO CantNec
        FROM dual; 
        END IF;

        ------DOSIS ALEATORIA CON QUE EL CUENTA EL CENTRO DE SALUD, PERTENECIENTE A UNA DE LAS 4 CATEGORIAS
        SELECT * INTO CodVacuna
        FROM (
            SELECT Codigo 
            FROM VACUNA
            WHERE Nombre = NombreVac 
            ORDER BY dbms_random.random)
        WHERE  rownum < 2;

       ------INSERT CORRESPONDIENTE AL DOSIS CON EL CUAL CUENTA EL CENTRO DE SALUD EN SU INVENTARIO
       INSERT INTO DOSIS VALUES(Centro,CodVacuna,Existencia(CantReal,CantNec));
       ADD_PEDIDO(CodVacuna,Centro,CantReal,1);
    
    END LOOP;
    
END;

-------------PROCEDIMIENTO AGREGAR INSUMOS---------------------------------

CREATE OR REPLACE PROCEDURE ADD_INSUMOS(Centro NUMBER) 
IS
    Capacid NUMBER;
    NumRandom NUMBER;
    CantNec NUMBER(38,0);
    CantReal NUMBER(38,0);
    CodInsum NUMBER;
    Categoria INSUMO.Tipo%TYPE;
    
    CURSOR Insumos is 
    SELECT DISTINCT Tipo
    FROM INSUMO;
    
BEGIN
    ------QUERY REFERENTE A LA CAPACIDAD DEL CENTRO
    SELECT c.Capacidad INTO Capacid
    FROM CENTRO_VACUNACION c
    WHERE c.Codigo = Centro;
    
    ------PORCENTAJE ALEATORIO DE SUMINISTROS 
    SELECT DBMS_RANDOM.value(25,50) INTO NumRandom 
    FROM dual; 
    
    CantReal:=Capacid*(NumRandom/100);
    
    OPEN Insumos;
    LOOP  
       FETCH Insumos INTO Categoria;
       EXIT WHEN Insumos%NOTFOUND;
       
       ------CANTIDAD ALEATORIA REQUERIDA DEL INSUMO
       SELECT DBMS_RANDOM.value(0,1) INTO CantNec
       FROM dual; 

       IF (CantNec = 1) THEN
        SELECT DBMS_RANDOM.value(1,50) INTO CantNec
        FROM dual; 
       END IF;

        ------INSUMO ALEATORIO CON QUE EL CUENTA EL CENTRO DE SALUD, PERTENECIENTE A UNA DE LAS 4 CATEGORIAS
        SELECT * INTO CodInsum
        FROM (
            SELECT Codigo 
            FROM INSUMO
            WHERE Tipo = Categoria 
            ORDER BY dbms_random.random)
        WHERE  rownum < 2;

       ------INSERT CORRESPONDIENTE AL INSUMO CON EL CUAL CUENTA EL CENTRO DE SALUD EN SU INVENTARIO
       INSERT INTO INVENTARIO VALUES(Centro,CodInsum,Existencia(CantReal,CantNec));
       ADD_PEDIDO(Codinsum,Centro,CantReal,0);
    END LOOP;
    
END;



-------------PROCEDIMIENTO PACIENTES ALEATORIOS POR AREA---------------------------------

CREATE OR REPLACE PROCEDURE PACIENTES_POR_AREA(Area NUMBER)
IS
    CodPac PACIENTE.Codigo%TYPE;
    
    -----CURSOR QUE CONTIENE LOS DATOS DE 5 PACIENTES ALEATORIOS, QUE NO TENGAN AREA ASIGNADA
    CURSOR Pacientes is 
    SELECT * 
    FROM (
     SELECT Codigo
     FROM PACIENTE
     WHERE Lugar is NULL
     ORDER BY dbms_random.random)
    WHERE  rownum < 6;
BEGIN
    OPEN Pacientes;
    LOOP
        FETCH Pacientes INTO CodPac;
        EXIT WHEN Pacientes%notfound; 
    
        -----ASIGNACION DEL AREA A ESOS 5 PACIENTES ALEATORIOS
        UPDATE PACIENTE 
        SET Lugar = Area
        WHERE Codigo = CodPac;
    
    END LOOP;
    CLOSE Pacientes;
END;

-------------PROCEDIMIENTO ASIGNACION_LISTA_ESPERA---------------------------------

CREATE OR REPLACE PROCEDURE Asignacion_lista_espera(Codarea NUMBER)
IS
    CodPac PACIENTE.Codigo%TYPE;
    CodCent CENTRO_VACUNACION.Codigo%TYPE;
    CodVac VACUNA.Codigo%TYPE;
    FechaFin Date;
    FechaInicio Date;
    NumAlt Number;
    
    -----CURSOR QUE CONTIENE LOS DATOS DE 2 PACIENTES ALEATORIOS-----
    CURSOR Pacientes is 
    SELECT * 
    FROM (
     SELECT Codigo
     FROM PACIENTE
     WHERE Lugar=Codarea
     ORDER BY dbms_random.random)
    WHERE  rownum < 3;


BEGIN

    SELECT c.Codigo INTO CodCent
    FROM CENTRO_VACUNACION c
    WHERE c.Lugar = CodArea;
    
   
    
    OPEN Pacientes;
    LOOP
        FETCH Pacientes INTO CodPac;
        EXIT WHEN Pacientes%notfound; 
        
        --Se selecciona una vacuna aleatoria que dispone el centro de vacunacion del area--
        SELECT * INTO CodVac
        FROM (
        
        SELECT d.Vacuna
        FROM Dosis d
        WHERE d.Centro=CodCent 
        ORDER BY dbms_random.random
        
        )
        WHERE rownum<2;
        
        
        --Se selecciona aleatoriamente una fecha de inicio antes de marzo, para la vacunacion--
        SELECT TO_DATE(TRUNC(DBMS_RANDOM.VALUE(TO_CHAR(DATE '2021-01-01','J'),TO_CHAR(DATE '2021-03-01','J'))),'J') 
        INTO FechaInicio
        FROM DUAL;
        
        --Se selecciona aleatoriamente una fecha fin antes de Junio, que dependiendo de NUMALT, sera null o una fecha tipo DATE--
        SELECT DBMS_RANDOM.value(0,1) INTO NumAlt
        FROM dual;
        IF (NumAlt = 1) THEN
            SELECT TO_DATE(TRUNC(DBMS_RANDOM.VALUE(TO_CHAR(DATE '2021-04-01','J'),TO_CHAR(DATE '2021-06-01','J'))),'J') 
            INTO FechaFin
            FROM DUAL;
        ELSE
            FechaFin := NULL;
        END IF;
        
        -----ASIGNACION DE LISTA DE ESPERA A ESOS 2 PACIENTES ALEATORIOS
        INSERT INTO VACUNACION VALUES(CodVac,CodCent,CodPac,FECHA(FechaInicio,FechaFin));


    END LOOP;
    CLOSE Pacientes;
END;

---------------PROCEDIMIENTO DE CENTROS POR AREA--------------------------

CREATE OR REPLACE PROCEDURE CENTRO_POR_AREA
IS
    Areas varrays2:=varrays2();
    Centros varrays:= varrays();
    counter NUMBER :=0; 
    counter2 NUMBER :=0; 
    Centro NUMBER;
BEGIN
    Areas:= AREAS_AFECTADAS;
    DBMS_OUTPUT.PUT_LINE('                                                  ');
    DBMS_OUTPUT.PUT_LINE('------------------CENTROS DE VACUNACIÓN--------------------------');
    FOR x IN 1..Areas.COUNT LOOP
        FOR j IN 1..Areas(x).COUNT LOOP
            counter:= counter +1;
            Centros.extend;
            Centro:=SELECCION_CENTRO(Areas(x)(j));
            Centros(counter):= Centro;
            ADD_INSUMOS(Centro);
            ADD_DOSIS(Centro);
            PACIENTES_POR_AREA(Areas(x)(j));
            Asignacion_lista_espera(Areas(x)(j));
        END LOOP;
    END LOOP;
END;



