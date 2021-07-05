
------------------------------------  INFECTAR PAISES  ---------------------------------

CREATE OR REPLACE PROCEDURE INFECTAR_PAISES
IS
    CURSOR c_paises_ale is
    SELECT * 
    FROM(
        SELECT Codigo, Nombre
        FROM LUGAR
        WHERE Tipo = 'PAIS'
        ORDER BY dbms_random.random)
    WHERE rownum < 3;
    
    PaisAle LUGAR.Codigo%type;
    PaisAleNomb LUGAR.Nombre%type;
    
BEGIN
    OPEN c_paises_ale;
    LOOP
        FETCH c_paises_ale INTO PaisAle, PaisAleNomb;
        EXIT WHEN c_paises_ale%notfound;

        INFECTAR_AREAS_VIRUS(PaisAle);
    END LOOP;
    CLOSE c_paises_ale;
    
    --Llamar al modulo de vacunaciòn
END;


-------------------------------------- INFECTAR AREAS POR PAIS -------------------------------------

CREATE OR REPLACE PROCEDURE INFECTAR_AREAS_VIRUS(Pais NUMBER) 
IS
    CodArea LUGAR.Codigo%TYPE;
    Infeccion NUMBER;
    FechaInicio Date;
    FechaFin Date;
    
    
    CURSOR Areas is 
    SELECT * 
    FROM (
     SELECT a.Codigo
     FROM LUGAR a INNER JOIN LUGAR p ON a.Lugar = p.Codigo
     WHERE a.Codigo NOT IN (SELECT Lugar FROM BROTE)
     AND p.Codigo = Pais 
     AND p.Tipo= 'PAIS'
     AND a.Tipo= 'AREA'
     ORDER BY dbms_random.random)
    WHERE  rownum < 3;
BEGIN
    OPEN Areas;
    LOOP
        FETCH Areas INTO CodArea;
        EXIT WHEN Areas%notfound; 
        SELECT Codigo INTO Infeccion FROM VIRUS;

        --SE AGREGA UNA FECHA ALEATORIA EN LA QUE SE ORIGINARÁ
        SELECT TO_DATE(TRUNC(DBMS_RANDOM.VALUE(TO_CHAR(DATE '2020-01-01','J'),TO_CHAR(DATE '2020-12-31','J'))),'J')
        INTO FechaInicio
        FROM DUAL;

        --SE AGREGA UNA FECHA ALEATORIA EN LA QUE SE TERMINARÁ
        SELECT TO_DATE(TRUNC(DBMS_RANDOM.VALUE(TO_CHAR(DATE '2021-03-01','J'),TO_CHAR(DATE '2021-07-01','J'))),'J')
        INTO FechaFin
        FROM DUAL;

        --REGISTRAR LA INFECCION EN BROTE
        INSERT INTO BROTE VALUES(Infeccion,CodArea,Fecha(FechaInicio,FechaFin));

        --SE LE ASIGNA EL AREA A ALGUNOS PACIENTES
        PACIENTES_POR_AREA(CodArea);
        
        --SE LE ASIGNA EL CENTRO DE VACUNACION AL AREA
        ASIGNAR_CENTRO(CodArea);
        
        --SE INFECTA AL 45% DE LOS PACIENTES DEL AREA
        INFECTAR_PACIENTES(CodArea);
    
    END LOOP;
    CLOSE Areas;
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



-------------PROCEDIMIENTO INFECTAR 45% DE LOS PACIENTES DEL AREA ---------------------------------

CREATE OR REPLACE PROCEDURE INFECTAR_PACIENTES (Area NUMBER)
IS
    CodPac PACIENTE.Codigo%TYPE;
    Infeccion NUMBER;
    FechaInicio Date;
    Rango Fecha;
    
    -----CURSOR QUE CONTIENE LOS DATOS DE TODOS LOS PACIENTES DE UN AREA
    CURSOR Pacientes is 
    SELECT * 
    FROM (
     SELECT Codigo
     FROM PACIENTE
     WHERE Lugar = Area
     ORDER BY dbms_random.random)
    WHERE rownum < 3;
    
BEGIN
    OPEN Pacientes;
    
    LOOP
        FETCH Pacientes INTO CodPac;
        EXIT WHEN Pacientes%notfound;
        
        SELECT Codigo INTO Infeccion FROM VIRUS;
        
        --SELECCIONA EL PERIODO DE INFECCION
        SELECT Periodo INTO Rango
        FROM BROTE
        WHERE Lugar = Area;
        
        --SE AGREGA UNA FECHA ALEATORIA EN LA QUE SE ORIGINARÁ
        --SELECT TO_DATE(TRUNC(DBMS_RANDOM.VALUE(Rango.Fecha_inicio,Periodo.Fecha_inicio)))
        --INTO FechaInicio
        --FROM dual;
        
        SELECT TO_DATE(TRUNC(DBMS_RANDOM.VALUE(TO_CHAR(Rango.Fecha_inicio,'J'),TO_CHAR(Rango.Fecha_fin,'J'))),'J')
        INTO FechaInicio
        FROM dual;
        
        -----ASIGNACION DE LA INFECCION AL LOS PACIENTES
        INSERT INTO INFECCION VALUES(Infeccion, Area, CodPac, Fecha(FechaInicio,null));
        
    END LOOP;
    CLOSE Pacientes;
END;



-------------PROCEDIMIENTO QUE ASIGNA UN CENTRO ALEATORIO A UN AREA CORRESPONDIENTE---------------------------------

CREATE OR REPLACE PROCEDURE ASIGNAR_CENTRO(Area NUMBER)
IS
    CodCent CENTRO_VACUNACION.Codigo%TYPE;
    
    -----CURSOR QUE CONTIENE LOS DATOS DE UN CENTRO DE VACUNACION ALEATORIO, QUE NO TENGA AREA ASIGNADA
    CURSOR Centros is 
    SELECT * 
    FROM (
     SELECT Codigo
     FROM CENTRO_VACUNACION
     WHERE Lugar = 1
     ORDER BY dbms_random.random)
    WHERE  rownum < 2;
BEGIN
    OPEN Centros;
    LOOP
        FETCH Centros INTO CodCent;
        EXIT WHEN Centros%notfound; 
    
        -----ASIGNACION DEL AREA AL CENTRO DE VACUNACION ELEGIDO DE FORMA ALEATORIA
        UPDATE CENTRO_VACUNACION 
        SET Lugar = Area
        WHERE Codigo = CodCent;
    
    END LOOP;
    CLOSE Centros;
END;

--------REINICIAR LA SIMULACION--------------

CREATE OR REPLACE GENERAR_BROTE
IS
NuevoBrote NUMBER;

BEGIN
    SELECT DBMS_RANDOM.value(0,1) INTO Preferencia
    INTO NuevoBrote
    FROM dual;

    IF (NuevoBrote = 1) THEN
        INFECTAR_PAISES;
    ELSE    
        SELECCION_PAISES;
    END IF;
END;


DELETE FROM BROTE;

UPDATE PACIENTE
SET Lugar = NULL;

UPDATE CENTRO_VACUNACION
SET Lugar = 1;


------COMPROBACIONES--------------------

SELECT * FROM PACIENTE;

SELECT b.Virus,b.Lugar,b.Periodo.Fecha_inicio,b.Periodo.Fecha_fin FROM BROTE b;

SELECT i.Virus,i.Lugar,i.Paciente,i.Periodo.Fecha_inicio,i.Periodo.Fecha_fin FROM INFECCION i;

SELECT * FROM CENTRO_VACUNACION;