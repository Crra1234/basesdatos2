CREATE OR REPLACE PROCEDURE REALIZAR_PEDIDO(CodSumi NUMBER, CodArea NUMBER, NomSumi VARCHAR2, CodCen number)
IS
DistriCovax NUMBER(38,0);
CodPais NUMBER;
UltimoPedido NUMBER;
CodOrgaCovax NUMBER;
CantidadNece NUMBER;
NumRandom NUMBER(38,0);
CantNecePedi NUMBER;
MontoTotal NUMBER;
Fecha_Inicio DATE;
Fecha_Final DATE;
ParteCovax NUMBER(38,0);
Financiamiento NUMBER;
Financ NUMBER;
RestriccionLocal VARCHAR(100);
PedidoAgain NUMBER(38,0);
BEGIN

   --Obtener el código del país
   SELECT p.Codigo INTO CodPais
   FROM LUGAR p INNER JOIN LUGAR a ON p.Codigo = a.Lugar
   WHERE a.Codigo = CodArea 
   AND p.Tipo= 'PAIS'
   AND a.Tipo= 'AREA'

   IF(VERIFICACION_SUMINISTRO(NomSumi) = 'VACUNA') THEN --Si se pidió vacuna (Flujo 2)

      DBMS_OUTPUT.PUT_LINE('Se pidió Vacunas');

      --Random para saber si quiere la distribución del COVAX
      SELECT DBMS_RANDOM.value(0,1) INTO DistriCovax
      FROM dual;

      --Si el país desea usar la distribución COVAX (Flujo 2.3.2)
      IF(DistriCovax = 1) THEN

         DBMS_OUTPUT.PUT_LINE('El país desea la distribución del COVAX');

         IF (PERTENENCIA_COVAX(CodPais)=1) THEN -- Si pertenece al COVAX (Flujo 2.3.2.2)

            DBMS_OUTPUT.PUT_LINE('El país pertenece COVAX');

            IF (VERIFICAR_FINANCIAMIENTO(CodPais) = 1) THEN --Si el país está completamente financiado (Flujo 2.3.2.3.2.4.3)

               DBMS_OUTPUT.PUT_LINE('El país está completamente financiado');

               UltimoPedido:=ULTIMO_PEDIDO;  --Ultimo pedido del pais
               CodOrgaCovax:=CODIGO_COVAX;   --Codigo del COVAX

               --Cantidad necesaria del centro
               SELECT d.Cantidad.Cant_necesaria
               INTO CantidadNece 
               FROM DOSIS d
               WHERE d.Centro = CodCen
               AND d.Vacuna = CodSumi;

               SELECT DBMS_RANDOM.value(50,100) INTO NumRandom
               FROM dual;

               CantNecePedi:= CantidadNece + NumRandom; --Cantidad Necesaria del pedido

               MontoTotal:= CantNecePedi * 1000;

               SELECT TO_DATE(TRUNC(DBMS_RANDOM.VALUE(TO_CHAR(DATE '2021-01-01','J'),TO_CHAR(DATE '2021-03-01','J'))),'J')  
               INTO Fecha_Inicio 
               FROM DUAL;

               SELECT TO_DATE(TRUNC(DBMS_RANDOM.VALUE(TO_CHAR(DATE '2021-03-01','J'),TO_CHAR(DATE '2021-07-01','J'))),'J')  
               INTO Fecha_Final 
               FROM DUAL;

               INSERT INTO PEDIDO VALUES(UltimoPedido + 1, CodPais, CodOrgaCovax, MontoTotal,'ENVIADO', NULL, CodSumi, Cantidad(NumRandom,CantNecePedi), Fecha(Fecha_Inicio,Fecha_Final),100); --Se confirma la orden de compra de las dosis de las vacunas para distribuirse. (Flujo 2.3.2.3.2.4.3.3)
               DBMS_OUTPUT.PUT_LINE('Se registra el pedido ' ||UltimoPedido + 1||  'del país ' ||CodPais|| ' con la organización ' ||CodOrgaCovax|| ', por el monto de ' || || ', el pedido queda con el estatus ENVIADO, de la vacuna' ||CodSumi|| '' |||| '' |||| );
               DBMS_OUTPUT.PUT_LINE('Se inicia el modulo de distribucion');

            ELSE

               DBMS_OUTPUT.PUT_LINE('El país no está completamente financiado');

                  CodOrgaCovax:=CODIGO_COVAX; --Se selecciona aleatoriamente una organización para realizar el pedido (Flujo 2.3.3.1)   
                  UltimoPedido:=ULTIMO_PEDIDO;
                  Financ:= GET_FINANCIAMIENTO(CodPais);

                  IF(VERIFICACION_OMS(CodSumi) = 1) THEN --Si la vacuna está certificada por la OMS (Flujo 2.3.3.3)

                     SELECT d.Cantidad.Cant_necesaria
                     INTO CantidadNece 
                     FROM DOSIS d
                     WHERE d.Centro = CodCen
                     AND d.Vacuna = CodSumi;

                     SELECT DBMS_RANDOM.value(50,100) INTO NumRandom
                     FROM dual;

                     CantNecePedi:= CantidadNece + NumRandom;
                     MontoTotal:= CantNecePedi * 1000;

                     SELECT TO_DATE(TRUNC(DBMS_RANDOM.VALUE(TO_CHAR(DATE '2021-03-01','J'),TO_CHAR(DATE '2021-07-01','J'))),'J')  
                     INTO Fecha_Inicio 
                     FROM DUAL;

                     SELECT TO_DATE(TRUNC(DBMS_RANDOM.VALUE(TO_CHAR(DATE '2021-08-01','J'),TO_CHAR(DATE '2021-09-01','J'))),'J')  
                     INTO Fecha_Final 
                     FROM DUAL;      

                     INSERT INTO PEDIDO VALUES(UltimoPedido + 1, CodPais, CodOrgaAle, MontoTotal,'EN PROCESO', NULL, CodSumi, Fecha(Fecha_Inicio,Fecha_Final), Cantidad(NumRandom,CantNecePedi), Financiamiento); --Se confirma la orden de compra de las dosis de las vacunas para distribuirse. (Flujo 2.3.2.3.2.4.3.3)
                     DBMS_OUTPUT.PUT_LINE('Se registra el pedido ' ||UltimoPedido + 1||  'del país ' ||CodPais|| ' con la organización ' ||CodOrgaAle|| ', por el monto de ' || || ', el pedido queda con el estatus ENVIADO, de la vacuna' ||CodVacuAlea|| '' |||| '' |||| );

                     --DITRIBUCION

                  ELSE --Si No está certificada por la OMS la vacuna (Flujo 2.3.3.4)

                     DBMS_OUTPUT.PUT_LINE('La vacuna no está certificada por la OMS. Denegada solicitud del pedido');

                     SELECT DBMS_RANDOM.value(1,50) INTO VacunaAgain
                     FROM dual;

                     --Si se desea selecciona otra vacuna
                     IF(VacunaAgain = 1) THEN
                        REALIZAR_PEDIDO(CodSumi NUMBER, CodArea NUMBER, NomSumi VARCHAR2, CodCen NUMBER)
                     ELSE
                        --MODULO DISTRIBUCION
                     END IF;

                  END IF;

            END IF;

         ELSE

            DBMS_OUTPUT.PUT_LINE('El país no pertenece COVAX');

            --Random para saber si el país quire ser parte del COVAX
            SELECT DBMS_RANDOM.value(0,1) INTO ParteCovax
            FROM dual;

            IF(ParteCovax = 1) THEN --Si desea ser parte del mecanismo COVAX (Flujo 2.3.2.3.2)

               DBMS_OUTPUT.PUT_LINE('El país desea ser parte del COVAX');
               Financiamiento:= ASIGNAR_FINANCIAMIENTO;
               DBMS_OUTPUT.PUT_LINE('El país tendrá un finaciamiento de: ' || Financiamiento || '%');

               --Se obtiene el país tiene restricción local
               RestriccionLocal:= VERIFICAR_RESTRICCIONES(CodPais);

               IF(Financiamiento = 100) THEN --Si el país está completamente financiado (Flujo 2.3.2.3.2.4.3

                  DBMS_OUTPUT.PUT_LINE('El país está completamente financiado');

                  UltimoPedido:=ULTIMO_PEDIDO;  --Ultimo pedido del pais
                  CodOrgaCovax:=CODIGO_COVAX;   --Codigo del COVAX

                  --Cantidad necesaria del centro
                  SELECT d.Cantidad.Cant_necesaria
                  INTO CantidadNece 
                  FROM DOSIS d
                  WHERE d.Centro = CodCen
                  AND d.Vacuna = CodSumi;

                  SELECT DBMS_RANDOM.value(50,100) INTO NumRandom
                  FROM dual;

                  CantNecePedi:= CantidadNece + NumRandom; --Cantidad Necesaria del pedido

                  MontoTotal:= CantNecePedi * 1000;

                  SELECT TO_DATE(TRUNC(DBMS_RANDOM.VALUE(TO_CHAR(DATE '2021-01-01','J'),TO_CHAR(DATE '2021-03-01','J'))),'J')  
                  INTO Fecha_Inicio 
                  FROM DUAL;

                  SELECT TO_DATE(TRUNC(DBMS_RANDOM.VALUE(TO_CHAR(DATE '2021-03-01','J'),TO_CHAR(DATE '2021-07-01','J'))),'J')  
                  INTO Fecha_Final 
                  FROM DUAL;

                  INSERT INTO PEDIDO VALUES(UltimoPedido + 1, CodPais, CodOrgaCovax, MontoTotal,'ENVIADO', NULL, CodSumi, Cantidad(NumRandom,CantNecePedi), Fecha(Fecha_Inicio,Fecha_Final),100); --Se confirma la orden de compra de las dosis de las vacunas para distribuirse. (Flujo 2.3.2.3.2.4.3.3)
                  DBMS_OUTPUT.PUT_LINE('Se registra el pedido ' ||UltimoPedido + 1||  'del país ' ||CodPais|| ' con la organización ' ||CodOrgaCovax|| ', por el monto de ' || || ', el pedido queda con el estatus ENVIADO, de la vacuna' ||CodSumi|| '' |||| '' |||| );
                  DBMS_OUTPUT.PUT_LINE('Se inicia el modulo de distribucion');

               ELSE

                  DBMS_OUTPUT.PUT_LINE('No está completamente financiado');

                  CodOrgaCovax:=CODIGO_COVAX; --Se selecciona aleatoriamente una organización para realizar el pedido (Flujo 2.3.3.1)   
                  UltimoPedido:=ULTIMO_PEDIDO;

                  IF(VERIFICACION_OMS(CodSumi) = 1) THEN --Si la vacuna está certificada por la OMS (Flujo 2.3.3.3)

                     SELECT d.Cantidad.Cant_necesaria
                     INTO CantidadNece 
                     FROM DOSIS d
                     WHERE d.Centro = CodCen
                     AND d.Vacuna = CodSumi;

                     SELECT DBMS_RANDOM.value(50,100) INTO NumRandom
                     FROM dual;

                     CantNecePedi:= CantidadNece + NumRandom;

                     MontoTotal:= CantNecePedi * 1000;

                     SELECT TO_DATE(TRUNC(DBMS_RANDOM.VALUE(TO_CHAR(DATE '2021-03-01','J'),TO_CHAR(DATE '2021-07-01','J'))),'J')  
                     INTO Fecha_Inicio 
                     FROM DUAL;

                     SELECT TO_DATE(TRUNC(DBMS_RANDOM.VALUE(TO_CHAR(DATE '2021-08-01','J'),TO_CHAR(DATE '2021-09-01','J'))),'J')  
                     INTO Fecha_Final 
                     FROM DUAL;   

                     INSERT INTO PEDIDO VALUES(UltimoPedido + 1, CodPais, CodOrgaAle, MontoTotal,'EN PROCESO', NULL, CodSumi, Fecha(Fecha_Inicio,Fecha_Final), Cantidad(NumRandom,CantNecePedi), Financiamiento); --Se confirma la orden de compra de las dosis de las vacunas para distribuirse. (Flujo 2.3.2.3.2.4.3.3)
                     DBMS_OUTPUT.PUT_LINE('Se registra el pedido ' ||UltimoPedido + 1||  'del país ' ||CodPais|| ' con la organización ' ||CodOrgaAle|| ', por el monto de ' || || ', el pedido queda con el estatus ENVIADO, de la vacuna' ||CodVacuAlea|| '' |||| '' |||| );

                     --DITRIBUCION

                  ELSE --Si No está certificada por la OMS la vacuna (Flujo 2.3.3.4)

                     DBMS_OUTPUT.PUT_LINE('La vacuna no está certificada por la OMS. Denegada solicitud del pedido');

                     SELECT DBMS_RANDOM.value(1,50) INTO PedidoAgain
                     FROM dual;

                     --Si se desea selecciona otra vacuna
                     IF(PedidoAgain = 1) THEN
                        REALIZAR_PEDIDO(CodSumi NUMBER, CodArea NUMBER, NomSumi VARCHAR2, CodCen NUMBER)
                     ELSE
                        --MODULO DISTRIBUCION
                     END IF;

                  END IF;

               END IF;

         END IF;

      ELSE

         DBMS_OUTPUT.PUT_LINE('El país no desea la distribución del COVAX');

         NOT_COVAX(CodSumi, CodArea, NomSumi, CodCen);

      END IF;      

   ELSE

      DBMS_OUTPUT.PUT_LINE('Se pidió Insumos');

      CodOrgaAle:= ORGANIZACION_ALEATORIA;
      UltimoPedido:=ULTIMO_PEDIDO;

      SELECT i.Cantidad.Cant_necesaria
      INTO CantidadNece 
      FROM INVENTARIO i
      WHERE i.Centro = CodCen
      AND i.Insumo = CodSumi;

      SELECT DBMS_RANDOM.value(50,100) INTO NumRandom
      FROM dual;

      CantNecePedi:= CantidadNece + NumRandom;
      MontoTotal:= CantNecePedi * 1000;

      INSERT INTO PEDIDO VALUES(UltimoPedido + 1, CodPais, CodOrgaAle, MontoTotal,'EN PROCESO', CodSumi, NULL, Cantidad(NumRandom,CantNecePedi), Fecha(Fecha_Inicio,Fecha_Final),0); 
      DBMS_OUTPUT.PUT_LINE('Se registra el pedido ' ||UltimoPedido + 1||  'del país ' ||CodPais|| ' con la organización ' ||CodOrgaCovax|| ', por el monto de ' || || ', el pedido queda con el estatus ENVIADO, del insumo' ||CodSumi|| '' |||| '' |||| );

      
      SELECT DBMS_RANDOM.value(1,50) INTO PedidoAgain--Desea crear otra orden de compra (Flujo 3.2.3.5)
      FROM dual;

      IF(PedidoAgain = 1) THEN
         REALIZAR_PEDIDO(CodSumi NUMBER, CodArea NUMBER, NomSumi VARCHAR2, CodCen NUMBER)
      ELSE
         --MODULO PAGOS
      END IF;
   END;

END;



--Se verifica si el país esta finaciado completamente
CREATE OR REPLACE FUNCTION VERIFICAR_FINANCIAMIENTO(CodPais) RETURN INTEGER
IS
PorceFinan NUMBER;
BEGIN

   --Busca aunque sea un solo pedido que tenga finanza
   SELECT DISTINCT   CASE
                     WHEN p.Organizacion = (SELECT
                                       FROM ORGANIZACION
                                       WHERE o.Nombre = 'COVAX') THEN p.Financia
                     ELSE 0
                     END
   INTO PorceFinan
   FROM PEDIDO p, ORGANIZACION o
   WHERE p.Lugar = CodPais
   AND p.Organizacion = o.Codigo
   AND o.Nombre = 'COVAX';

   IF(PorceFinan = 100) THEN
      RETURN 1;
   ELSE
      RETURN 0;
   END IF;

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

--Se obtendrá una organización aleatoria distinta del COVAX
CREATE OR REPLACE FUNCTION ORGANIZACION_ALEATORIA RETURN NUMBER
IS
CodOrga NUMBER;
BEGIN

      SELECT * 
         FROM (
         SELECT Codigo
         FROM ORGANIZACION
         WHERE Nombre <> 'COVAX'
         AND Nombre <> 'OMS'
         ORDER BY dbms_random.random)
      INTO CodOrga
      WHERE  rownum < 2;

   RETURN CodOrga;

END;

--Se obtendrá una vacuna aleatoria
CREATE OR REPLACE FUNCTION VACUNA_ALEATORIA RETURN NUMBER
IS
CodVacuna NUMBER;
BEGIN

      SELECT * 
         FROM (
         SELECT Codigo
         FROM VACUNA
         ORDER BY dbms_random.random)
      INTO CodVacuna
      WHERE  rownum < 2;

   RETURN CodVacuna;

END;

--Se obtendrá una vacuna aleatoria
CREATE OR REPLACE FUNCTION VACUNA_ALEATORIA RETURN NUMBER
IS
CodVacuna NUMBER;
BEGIN

      SELECT * 
         FROM (
         SELECT Codigo
         FROM VACUNA
         ORDER BY dbms_random.random)
      INTO CodVacuna
      WHERE  rownum < 2;

   RETURN CodVacuna;

END;

--Se verificará si está aprobada por la OMS
CREATE OR REPLACE FUNCTION VERIFICACION_OMS(CodVacuAlea) RETURN NUMBER
IS
Verificado NUMBER;
BEGIN

   SELECT Aprobacion.Fecha_inicio
   FROM VA_OR
   WHERE Vacuna = CodVacuAlea;

      RETURN 1;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN 0;

END;

--Para obtener el ultimo codigo de pedido y sumarle 1 para ingresar nuevo pedido
CREATE OR REPLACE FUNCTION ULTIMO_PEDIDO RETURN NUMBER
IS
UltPedido NUMBER;
BEGIN

   SELECT MAX(Codigo)
   INTO UltPedido
   FROM PEDIDO;
   
   Return UltPedido;
END;
   
--Para obtener la organización COVAX   
CREATE OR REPLACE FUNCTION CODIGO_COVAX RETURN NUMBER
IS
CodCovax NUMBER;
BEGIN
   
   SELECT Codigo
   INTO CodCovax
   FROM ORGANIZACION
   WHERE Nombre = 'COVAX';

   Return CodCovax;
END;

--Obtener el financiamiento del pais
CREATE OR REPLACE FUNCTION GET_FINANCIAMIENTO(CodPais NUMBER) RETURN NUMBER
IS
Finan NUMBER;
BEGIN
   SELECT DISTINCT p.Financia
   INTO Finan
   FROM PEDIDO p, ORGANIZACION o
   WHERE p.Lugar = CodPais
   AND p.Organizacion = o.Codigo
   AND o.Nombre = 'COVAX';

   RETURN Finan;
END;


--
CREATE OR REPLACE PROCEDURE NOT_COVAX(CodSumi NUMBER, CodArea NUMBER, NomSumi VARCHAR2, CodCen NUMBER) 
IS
UltimoPedido NUMBER;
CodOrgaAle NUMBER;
CantidadNece NUMBER;
NumRandom NUMBER;
CantNecePedi NUMBER;
Fecha_Inicio DATE;
Fecha_Final DATE;
VacunaAgain NUMBER(38,0);
BEGIN
   CodOrgaAle:= ORGANIZACION_ALEATORIA; --Se selecciona aleatoriamente una organización para realizar el pedido (Flujo 2.3.3.1)   
   UltimoPedido:=ULTIMO_PEDIDO;

   IF(VERIFICACION_OMS(CodSumi) = 1) THEN --Si la vacuna está certificada por la OMS (Flujo 2.3.3.3)

      SELECT d.Cantidad.Cant_necesaria
      INTO CantidadNece 
      FROM DOSIS d
      WHERE d.Centro = CodCen
      AND d.Vacuna = CodSumi;

      SELECT DBMS_RANDOM.value(50,100) INTO NumRandom
      FROM dual;

      CantNecePedi:= CantidadNece + NumRandom;

      MontoTotal:= CantNecePedi * 1000;

      SELECT TO_DATE(TRUNC(DBMS_RANDOM.VALUE(TO_CHAR(DATE '2021-01-01','J'),TO_CHAR(DATE '2021-03-01','J'))),'J')  
      INTO Fecha_Inicio 
      FROM DUAL;

      SELECT TO_DATE(TRUNC(DBMS_RANDOM.VALUE(TO_CHAR(DATE '2021-03-01','J'),TO_CHAR(DATE '2021-07-01','J'))),'J')  
      INTO Fecha_Final 
      FROM DUAL;      

      INSERT INTO PEDIDO VALUES(UltimoPedido + 1, CodPais, CodOrgaAle, MontoTotal,'EN PROCESO', NULL, CodSumi, Fecha(Fecha_Inicio,Fecha_Final), Cantidad(NumRandom,CantNecePedi), 0); --Se confirma la orden de compra de las dosis de las vacunas para distribuirse. (Flujo 2.3.2.3.2.4.3.3)
      DBMS_OUTPUT.PUT_LINE('Se registra el pedido ' ||UltimoPedido + 1||  'del país ' ||CodPais|| ' con la organización ' ||CodOrgaAle|| ', por el monto de ' || || ', el pedido queda con el estatus ENVIADO, de la vacuna' ||CodVacuAlea|| '' |||| '' |||| );

      --DITRIBUCION

   ELSE --Si No está certificada por la OMS la vacuna (Flujo 2.3.3.4)

      DBMS_OUTPUT.PUT_LINE('La vacuna no está certificada por la OMS. Denegada solicitud del pedido');

      SELECT DBMS_RANDOM.value(1,50) INTO VacunaAgain
      FROM dual;

      --Si se desea selecciona otra vacuna
      IF(VacunaAgain = 1) THEN
         REALIZAR_PEDIDO(CodSumi NUMBER, CodArea NUMBER, NomSumi VARCHAR2, CodCen NUMBER)
      ELSE
         --MODULO DISTRIBUCION
      END IF;

   END IF;
END;


--Escoger un insumo aleatorio
CREATE OR REPLACE FUNCTION INSUMO_ALEATORIO RETURN NUMBER
IS
CodInsu NUMBER;
BEGIN

      SELECT * INTO CodInsu
         FROM (
         SELECT Codigo
         FROM INSUMO
         ORDER BY dbms_random.random)
      WHERE  rownum < 2;

   RETURN CodInsu;

END;