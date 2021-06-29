
------------------------------------  INFECTAR PAISES  ---------------------------------

CREATE OR REPLACE PROCEDURE INFECTAR_PAISES
IS
    Paises varrays:=varrays();
    counter NUMBER :=0;
    Ma NUMBER;
    Pais NUMBER;

    CURSOR c_paises_ale is 
    SELECT Codigo, Nombre
    FROM LUGAR
    WHERE Tipo = 'PAIS' AND rownum <= (SELECT MAX(Codigo) FROM LUGAR WHERE Tipo = 'PAIS')
    ORDER BY dbms_random.random;
    
    PaisAle LUGAR.Codigo%type;
    PaisAleNomb LUGAR.Nombre%type;
    
BEGIN
    OPEN c_paises_ale;
    LOOP
        FETCH c_paises_ale INTO PaisAle, PaisAleNomb;
        EXIT WHEN c_paises_ale%notfound;
        counter := counter + 1; 
        Paises.extend; 
        Paises(counter):= PaisAle;
        INFECTAR_AREAS_VIRUS(PaisAle);
    END LOOP;
    CLOSE c_paises_ale;
    --RETURN Paises;
END;


-------------------------------------- INFECTAR AREAS POR PAIS -------------------------------------

CREATE OR REPLACE PROCEDURE INFECTAR_AREAS_VIRUS(Pais NUMBER) 
IS
    CodArea LUGAR.Codigo%TYPE;
    Virus NUMBER;
    Infeccion NUMBER;
    
    
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
        -----REGISTRAR LA INFECCION EN BROTE
        INSERT INTO BROTE VALUES(Infeccion,CodArea);

    
    END LOOP;
    CLOSE Areas;
END;

EXECUTE INFECTAR_PAISES;

DELETE FROM  BROTE;

SELECT * FROM BROTE;