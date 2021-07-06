
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
CREATE OR REPLACE PROCEDURE ADD_PEDIDO(Suministro NUMBER,Lugar NUMBER,Cant_Necesaria NUMBER,Cant_real NUMBER,Flag Number,Status_Flag Number) 
IS
   Randomprice NUMBER; 
   Organizacion NUMBER;
   Codigo_Temp NUMBER;
   MontTotal NUMBER(38,2);
   Estatus VARCHAR2(20);
   Fecha_Inicio DATE;
   Fecha_Final DATE;
BEGIN
    --Se define una cantidad aleatoria que vale el suministro generico-
    SELECT DBMS_RANDOM.value(25,100) INTO Randomprice
    FROM dual;
    MontTotal := Randomprice * Cant_Necesaria;
    
    --Si es 0, es insumo. En caso contrario, es vacuna--
    IF (FLAG = 1) THEN
        SELECT  * INTO Organizacion 
        FROM(
            SELECT  v.Organizacion 
            FROM VA_OR v 
            WHERE v.Vacuna=Suministro
            ORDER BY dbms_random.random)
        WHERE ROWNUM <2;
    ELSE 
        SELECT * INTO Organizacion 
        FROM (
            SELECT Codigo 
            FROM ORGANIZACION
            ORDER BY dbms_random.random)
        WHERE ROWNUM <2;
    END IF;
    
    IF (Status_Flag = 1) THEN
        Estatus:= 'ENVIADO';

        SELECT TO_DATE(TRUNC(DBMS_RANDOM.VALUE(TO_CHAR(DATE '2021-01-01','J'),TO_CHAR(DATE '2021-03-01','J'))),'J')  
        INTO Fecha_Inicio 
        FROM DUAL;

        SELECT TO_DATE(TRUNC(DBMS_RANDOM.VALUE(TO_CHAR(DATE '2021-03-01','J'),TO_CHAR(DATE '2021-07-01','J'))),'J')  
        INTO Fecha_Final 
        FROM DUAL;
    ELSE
        Estatus:= 'EN PROCESO';

        SELECT TO_DATE(TRUNC(DBMS_RANDOM.VALUE(TO_CHAR(DATE '2021-03-01','J'),TO_CHAR(DATE '2021-07-01','J'))),'J')  
        INTO Fecha_Inicio 
        FROM DUAL;

        SELECT TO_DATE(TRUNC(DBMS_RANDOM.VALUE(TO_CHAR(DATE '2021-08-01','J'),TO_CHAR(DATE '2021-09-01','J'))),'J')  
        INTO Fecha_Final 
        FROM DUAL;
    END IF;

    SELECT NVL(MAX(P.CODIGO), 1) INTO Codigo_Temp FROM PEDIDO P;
    Codigo_temp := Codigo_Temp+1;

    --Si es 0, es insumo. En caso contrario, es vacuna--
    IF (FLAG = 0) THEN
        INSERT INTO PEDIDO VALUES (Codigo_Temp,Lugar,Organizacion,MontTotal,Estatus,Suministro,null,Fecha(Fecha_Inicio,Fecha_Final),Existencia(Cant_real,Cant_Necesaria));
    ELSE 
        INSERT INTO PEDIDO VALUES (Codigo_Temp,Lugar,Organizacion,MontTotal,Estatus,null,Suministro,Fecha(Fecha_Inicio,Fecha_Final),Existencia(Cant_real,Cant_Necesaria));
    END IF;
END;



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
    DBMS_OUTPUT.PUT_LINE('-->Centro de Vacunacion: "' || Centro );
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
    END LOOP;
    
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
    Codigo_Temp NUMBER;
    
    -----CURSOR QUE CONTIENE LOS DATOS DE UN PACIENTES ALEATORIO CORRESPONDIENTE AL AREA (EQUIVALENTE AL 25% DE LOS HABITANTES DE ESA AREA) -----
    CURSOR Pacientes is 
    SELECT * 
    FROM (
     SELECT Codigo
     FROM PACIENTE
     WHERE Lugar=Codarea
     ORDER BY dbms_random.random)
    WHERE  rownum < 2;


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

        SELECT NVL(MAX(V.CODIGO), 1) INTO Codigo_Temp FROM Vacunacion V;
        Codigo_temp := Codigo_Temp+1;
        -----ASIGNACION DE LISTA DE ESPERA A ESOS 2 PACIENTES ALEATORIOS, con fecha 1 mes antes de la fecha actual
        INSERT INTO VACUNACION VALUES(Codigo_Temp,CodVac,CodCent,CodPac,FECHA(ADD_MONTHS(SYSDATE,-1),NULL));
        Codigo_temp := Codigo_Temp+1;
        INSERT INTO VACUNACION VALUES(Codigo_Temp,CodVac,CodCent,CodPac,FECHA(SYSDATE,NULL));


    END LOOP;
    CLOSE Pacientes;
END;



--Procedumiento de asignacion de fechas (Y vacunacion) de los pacientes--
CREATE OR REPLACE PROCEDURE Asignacion_Vacunacion(Codarea NUMBER)
IS
    CodPac PACIENTE.Codigo%TYPE;
    CodCent CENTRO_VACUNACION.Codigo%TYPE;
    CodVac VACUNA.Codigo%TYPE;
    GrupoEtario PACIENTE.Grupo_Etario%TYPE;
    FechaVac Date;
    NumAlt Number;
    Preferencia Number;
    Cant_Necesaria NUMBER;
    
    
    -----CURSOR QUE CONTIENE LOS DATOS LOS PACIENTES DEL AREA SUMINISTRADA-----
    CURSOR Pacientes is 
    SELECT * 
    FROM (
     SELECT Codigo
     FROM PACIENTE
     WHERE Lugar=Codarea
     ORDER BY dbms_random.random);


BEGIN
    SELECT c.Codigo INTO CodCent
    FROM CENTRO_VACUNACION c
    WHERE c.Lugar = CodArea;
    
    OPEN Pacientes;
    LOOP
        FETCH Pacientes INTO CodPac;
        EXIT WHEN Pacientes%notfound; 
        
        NumAlt:=-1;
        SELECT V.Paciente INTO NumAlt
        FROM VACUNACION V WHERE V.Paciente=CodPac;
        
        DBMS_OUTPUT.PUT_LINE('---------------------PACIENTES VACUNADOS------------------------');
        --Se verifica si el paciente ya esta asignado a una lista de espera--
        IF (NumAlt = -1) THEN
            select codigo into codcent from CENTRO_VACUNACION;
        
        ELSE
            
            --Se selecciona aleatoriamente si el paciente tiene preferencia o no, 1 siginifica que si tiene, 0 significa lo contrario--
            SELECT DBMS_RANDOM.value(0,1) INTO Preferencia
            FROM dual;
            
            IF (Preferencia = 1) then
            
                --Se selecciona aleatoriametne la vacuna que quiere el paciente--
                SELECT * INTO CodVac
                FROM (
                
                SELECT d.Vacuna
                FROM Dosis d
                WHERE 
                d.Centro=CodCent 
                ORDER BY dbms_random.random
                )
                WHERE rownum<2;
                
                --Se checkea si existe la vacuna con la cual se quiere vacunar el paciente--(6.3.3.3.1)
                SELECT d.Cantidad.Cant_real INTO NumAlt
                FROM Dosis d
                WHERE
                d.Centro=CodCent
                AND
                d.vacuna = CodVac;
                
                --Si numalt = 0, se le reasigna al paciente una fecha de programacion aleatoria dentro de 4 meses a partir de la fecha del sistema. (Flujo )

                IF (NumAlt = 0) THEN                   
                    
                    --ASIGNACION DE OTRA FECHA DE VACUNACIÓN DEBIDO A QUE NO HAY DOSIS DISPONIBLE              
                    SELECT DBMS_RANDOM.value(1,27) INTO NumAlt
                    FROM dual;

                    -- Cambio de 4 meses a 1 FechaVac := ADD_MONTHS(SYSDATE + NumAlt, 4);                   
                    FechaVac := ADD_MONTHS(SYSDATE + NumAlt, 1);
                    
                    INSERT INTO VACUNACION VALUES(CodVac,CodCent,CodPac,FECHA(FechaVac,FechaVac));
                    INSERT INTO VACUNACION VALUES(CodVac,CodCent,CodPac,FECHA(ADD_MONTHS(FechaVac,1),ADD_MONTHS(FechaVac,1)));
                    CONTINUE;

                    --SUMINISTROS_DISPONIBLES(Codarea,CodCent,CodVac);
                    
                END IF;

            ELSE
            
                --Se selecciona una vacuna aleatoria que dispone el centro de vacunacion del area-- (6.3.3.3.1)
                SELECT * INTO CodVac
                FROM (
                
                SELECT d.Vacuna
                FROM Dosis d
                WHERE 
                d.Centro=CodCent 
                and 
                (d.Cantidad.Cant_real > 0)
                ORDER BY dbms_random.random
                
                )
                WHERE rownum<2;
            
            END IF;
            
                NumAlt:=-1;
                SELECT I.Paciente into NumAlt
                FROM INFECCION I WHERE I.Paciente=CodPac;
            
            --Se establecen las prioridades en el variable de preferencia, si esta infectado se vacuna en menos de un mes, si es anciano, se vacuna en un mes, si es adulto, se vacuna en 2 meses, y si es joven, en 3 meses.
            IF (NumAlt = -1) THEN
                Preferencia := 0;
            ELSE
                SELECT p.GRUPO_ETARIO into Grupoetario
                from Paciente p
                where p.Codigo = CodPac;
                
                IF (Grupoetario = 'ANCIANO') THEN
                   Preferencia := 1;
                ELSIF (Grupoetario = 'ADULTO') THEN
                    Preferencia := 2;
                ELSE 
                    Preferencia := 3;
                END IF;
                        
            END IF;
                    
                    SELECT DBMS_RANDOM.value(0,27) INTO NumAlt
                    FROM dual;
                    
                    --Se asigna la FechaVAC la cual sera la fecha de vacunacion del paciente--
                    FechaVac := ADD_MONTHS(SYSDATE + NumAlt, Preferencia);
                
        
            -----ASIGNACION DE LISTA DE ESPERA A ESOS 2 PACIENTES ALEATORIOS
            INSERT INTO VACUNACION VALUES(CodVac,CodCent,CodPac,FECHA(FechaVac,Null));
            --GENERAR_EFECTOS_SECUNDARIOS(CodVac, CodCent, CodPac, FECHA.Fecha_inicio);

            --ASIGNACION DE LA SEGUNDA DOSIS PARA EL PACIENTE
            INSERT INTO VACUNACION VALUES(CodVac,CodCent,CodPac,FECHA(ADD_MONTHS(FechaVac,1),ADD_MONTHS(FechaVac,1)));

            
            
        END IF;

    END LOOP;
    CLOSE Pacientes;
END;



--Procedimiento para generar efecto secundario al paciente vacunado (Flujo 6.3.3.3.2.3.1)
CREATE OR REPLACE PROCEDURE GENERAR_EFECTOS_SECUNDARIOS(Codvac NUMBER, CodCent NUMBER, CodPac NUMBER, FechaVac Date)
IS
Probabilidad NUMBER(38,0);
DiaEfec NUMBER;
FechaInicio Date;
FechaFinal Date;
Efecto NUMBER;

BEGIN
    DBMS_OUTPUT.PUT_LINE('------------------EFECTOS SECUNDARIOS POR PACIENTE VACUNADO --------------------------');
    
    --Probabilidad de que el paciente tenga efectos secundarios es de 25%. 1-25%: Tiene efecto secundario; 2-50%, 3-75%, 4-100%: No tendrá efecto secundario.
        SELECT DBMS_RANDOM.value(1,4) INTO Probabilidad 
        FROM dual;
        DBMS_OUTPUT.PUT_LINE(Probabilidad);
        IF (Probabilidad = 1) THEN

            --Fecha en que inicia el efecto secundario, será 2 días despues de la vacunación.
            FechaInicio := FechaVac + 2;

            --DiaEfec (2-10 días) lo que durará una vez que inicie el efecto secundario del paciente.                   
            SELECT DBMS_RANDOM.value(2,10) INTO DiaEfec
            FROM dual;

            FechaFinal:=  FechaInicio + DiaEfec;

            SELECT * 
            INTO Efecto
            FROM(
                SELECT Codigo 
                FROM EFECTO_SECUNDARIO
                ORDER BY dbms_random.random)
            WHERE rownum < 2;

            --Se inserta el registro de la reacción por la vacuna al paciente
            INSERT INTO REGISTRO_REACCION VALUES(Codvac, CodCent, CodPac, Efecto, FECHA(FechaInicio, FechaFinal));

        END IF;

END;

--Se hace cuenta los suministros de los centro de vacunacion de un area, con un insumo determinado--
CREATE OR REPLACE FUNCTION CREATE_PEDIDO_INVENTARIO(Area NUMBER,Insumo_ext NUMBER) return NUMBER
IS
    CodCentro NUMBER;
    Total_Insumos NUMBER;
    Parcial_insumos NUMBER;

BEGIN
    Total_Insumos:=0;

    SELECT distinct i.centro into CodCentro
    FROM INVENTARIO i,CENTRO_VACUNACION c 
    WHERE i.Centro = c.Codigo
    AND c.Lugar=Area AND i.Insumo=Insumo_ext;

    SELECT I.Cantidad.Cant_real into Parcial_insumos
    FROM Inventario I
    WHERE I.Centro=CodCentro AND I.Insumo=Insumo_ext;

    Total_Insumos := Parcial_insumos + Total_Insumos;

    RETURN Total_Insumos;

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN 0;
END;

--Se hace cuenta los suministros de los centro de vacunacion de un area, con una vacuna determinada--
CREATE OR REPLACE FUNCTION CREATE_PEDIDO_DOSIS(Area NUMBER,Vacuna_ext NUMBER) return NUMBER
IS
    CodCentro NUMBER;
    Total_Vacuna NUMBER;
    Parcial_Vacuna Existencia;


BEGIN
    Total_Vacuna:=0;

    SELECT distinct d.centro into CodCentro
    FROM Dosis d,CENTRO_VACUNACION c 
    WHERE d.Centro = c.Codigo
    AND c.Lugar=Area and d.Vacuna=Vacuna_ext;

    SELECT D.Cantidad into Parcial_Vacuna
    FROM DOSIS D
    WHERE D.Centro=CodCentro and d.Vacuna=Vacuna_ext;

        Total_Vacuna := Parcial_Vacuna.Cant_real + Total_Vacuna;

    RETURN Total_Vacuna;

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN 0;
END;

--Se realizan los pedidos para el pais suministrado--
CREATE OR REPLACE PROCEDURE CREATE_PEDIDO(Pais NUMBER) 
IS
    CodInsumo NUMBER;
    CodArea NUMBER;
    CodVacuna NUMBER;

    NumRandom NUMBER;
    NumRand NUMBER;
    Parcial_Existencia NUMBER;
    Total_Existencia NUMBER;

    CURSOR Area is 
    SELECT Codigo 
    FROM Lugar
    WHERE Lugar=Pais 
    AND TIPO='AREA';

    CURSOR INSUMOS IS
    Select Codigo
    FROM INSUMO;

    CURSOR VACUNA IS
    Select Codigo
    FROM VACUNA;
    
BEGIN
    --Se hace un loop para encontrar la cantidad total de los insumos en un pais--
    OPEN INSUMOS;
    LOOP
         FETCH INSUMOS INTO CodInsumo;
         EXIT WHEN INSUMOS%NOTFOUND;
         Total_Existencia:=0;

        --Se hace otro loop para encontrar la cantidad total de los insumos en un area--
        OPEN Area;
            LOOP
                FETCH Area INTO CodArea;
                EXIT WHEN AREA%NOTFOUND;
                Parcial_Existencia:= CREATE_PEDIDO_INVENTARIO(CodArea,CodInsumo);
                Total_Existencia:= Total_Existencia + Parcial_Existencia;
            END LOOP;
        CLOSE Area;

        IF (Total_Existencia != 0) THEN

            SELECT DBMS_RANDOM.value(50,100) INTO NumRandom
            FROM dual;      
            Total_Existencia:= Total_Existencia + NumRandom;

            ADD_PEDIDO(CodInsumo,Pais,Total_existencia,NumRandom,0,1);

            SELECT DBMS_RANDOM.value(0,1) INTO NumRand
            FROM dual; 
            IF (NumRand = 1) THEN
                ADD_PEDIDO(CodInsumo,Pais,NumRandom,NumRandom,0,0);
            END IF;
        END IF;
    END LOOP;
    CLOSE INSUMOS;

    --Se hace un loop para encontrar la cantidad total de las dosis en un pais--
    OPEN VACUNA;
    LOOP
         FETCH VACUNA INTO CodVacuna;
         EXIT WHEN VACUNA%NOTFOUND;
         Total_Existencia:=0;

        --Se hace otro loop para encontrar la cantidad total de las dosis en un area--
        OPEN Area;
            LOOP
                FETCH Area INTO CodArea;
                EXIT WHEN AREA%NOTFOUND;
                Parcial_Existencia:= CREATE_PEDIDO_DOSIS(CodArea,CodVacuna);
                Total_Existencia:= Total_Existencia + Parcial_Existencia;
            END LOOP;
        CLOSE Area;

        IF (Total_Existencia != 0) THEN

            SELECT DBMS_RANDOM.value(50,100) INTO NumRandom
            FROM dual;      
            Total_Existencia:= Total_Existencia + NumRandom;

            ADD_PEDIDO(CodVacuna,Pais,Total_existencia,NumRandom,1,1);
        END IF;

        IF (NumRand = 1) THEN
                ADD_PEDIDO(CodVacuna,Pais,NumRandom,NumRandom,1,0);
        END IF;
    END LOOP;
    CLOSE VACUNA;

END;

--Se realizan los pedidos para todos los paises--
CREATE OR REPLACE PROCEDURE CREATE_PEDIDO_POR_PAIS
IS
    CodPais NUMBER;

    CURSOR Paises is 
    SELECT distinct p.Codigo 
    FROM Lugar p,Lugar a,Inventario I,CENTRO_VACUNACION c
    WHERE a.Lugar=p.Codigo AND a.Codigo=c.Lugar AND c.Codigo=i.Centro;

    
BEGIN

    OPEN PAISES;
    LOOP
        FETCH PAISES INTO CodPais;
        EXIT WHEN PAISES%NOTFOUND;
        CREATE_PEDIDO(CodPais);

    END LOOP;
    CLOSE PAISES;

END;

---------------PROCEDIMIENTO DE CENTROS POR AREA--------------------------

CREATE OR REPLACE PROCEDURE CENTRO_POR_AREA
IS
    Areas varrays2:=varrays2();
    Centros varrays:= varrays();
    Pais NUMBER;
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
            DBMS_OUTPUT.PUT_LINE('--Centro:'|| Centro ||  '--');
            Centros(counter):= Centro;
            ADD_INSUMOS(Centro);
            ADD_DOSIS(Centro);
            Asignacion_lista_espera(Areas(x)(j));
            --Asignacion_Vacunacion(Areas(x)(j));
        END LOOP;
    END LOOP;
END;

