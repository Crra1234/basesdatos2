CREATE OR REPLACE PROCEDURE REALIZAR_PEDIDO(CodSumi NUMBER, CodArea NUMBER, NomSumi VARCHAR2)
IS
DistriCovax NUMBER(38,0);
ParteCovax NUMBER(38,0);
CodPais NUMBER;
Financiamiento NUMBER;
BEGIN

   --Obtener el código del país
   SELECT p.Codigo INTO CodPais
   FROM LUGAR p INNER JOIN LUGAR a ON p.Codigo = a.Lugar
   WHERE a.Codigo = CodArea 
   AND p.Tipo= 'PAIS'
   AND a.Tipo= 'AREA';
   
   --Random para saber si quiere la distribución del COVAX
   SELECT DBMS_RANDOM.value(0,1) INTO DistriCovax
   FROM dual;

   --Si el país desea usar la distribución COVAX (Flujo 2.3.2)
   IF(DistriCovax = 1) THEN

      DBMS_OUTPUT.PUT_LINE('El país desea la distribución del COVAX');
      IF (PERTENENCIA_COVAX(CodArea)=1) THEN -- Si pertenece al COVAX (Flujo 2.3.2.2)

      ELSE -- No pertenece al COVAX (Flujo 2.3.2.3)

         --Random para saber si el país quire ser parte del COVAX
         SELECT DBMS_RANDOM.value(0,1) INTO ParteCovax
         FROM dual;

         IF(ParteCovax = 1) THEN --Si desea ser parte del mecanismo COVAX (Flujo 2.3.2.3.2)

            DBMS_OUTPUT.PUT_LINE('El país desea ser parte del COVAX');
            Financiamiento:= ASIGNAR_FINANCIAMIENTO;

         ELSE --No desea ser parte del mecanismo COVAX (Flujo 2.3.2.3.3)

            DBMS_OUTPUT.PUT_LINE('El país no desea ser parte del COVAX');

         END IF;

      END IF;

   --El pais no desea usar la distribución COVAX (Flujo 2.3.3)
   ELSE

      DBMS_OUTPUT.PUT_LINE('El país no desea la distribución del COVAX');

   END IF;

END;


CREATE OR REPLACE FUNCTION PERTENENCIA_COVAX(CodArea NUMBER) RETURN NUMBER
IS
BEGIN
   SELECT
         CASE
            WHEN  'COVAX' = ANY (SELECT o.Nombre 
                  FROM ORGANIZACION o
                  WHERE o.Codigo = (SELECT pe.Organizacion
                                    FROM PEDIDO pe
                                    WHERE pe.Lugar = (SELECT p.Codigo
                                    FROM LUGAR p INNER JOIN LUGAR a ON p.Codigo = a.Lugar
                                    WHERE a.Codigo = CodArea 
                                    AND p.Tipo= 'PAIS'
                                    AND a.Tipo= 'AREA'))) THEN 1
         ELSE 0
         END Clasificacion
   INTO Pertenece
   FROM Dual;

   RETURN Pertenece;
   
END;

--Se le asiganará al país un financiamiento aleatorio
CREATE OR REPLACE FUNCTION ASIGNAR_FINANCIAMIENTO RETURN NUMBER
IS
FinanAlea NUMBER(38,0);
BEGIN

   SELECT DBMS_RANDOM.value(0,4) INTO FinanAlea
   FROM dual;

   IF (FinanAlea = 0) THEN --0%

      DBMS_OUTPUT.PUT_LINE('');
      DBMS_OUTPUT.PUT_LINE('El país será autofinanciado 0%');
      Return 0;

   ELSIF (PorcAbonar = 1) THEN --25%

      DBMS_OUTPUT.PUT_LINE('');
      DBMS_OUTPUT.PUT_LINE('El país será financiado por un 25%');
      Return 25;

   ELSIF (PorcAbonar = 2) THEN --50%

      DBMS_OUTPUT.PUT_LINE('');
      DBMS_OUTPUT.PUT_LINE('El país será financiado por un 50%');
      Return 50;

   ELSIF (PorcAbonar = 3) THEN --75%

      DBMS_OUTPUT.PUT_LINE('');
      DBMS_OUTPUT.PUT_LINE('El país será financiado por un 75%');
      Return 75;

   ELSE --100%

      DBMS_OUTPUT.PUT_LINE('');
      DBMS_OUTPUT.PUT_LINE('El país será financiado por un 100%');
      Return 100;

   END IF;

END;