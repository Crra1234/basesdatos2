CREATE OR REPLACE PROCEDURE REALIZAR_PEDIDO(CodSumi NUMBER, CodArea NUMBER, NomSumi VARCHAR2)
IS
DistriCovax NUMBER(38,0);
ParteCovax NUMBER(38,0);
CodPais NUMBER;
Financiamiento NUMBER;
RestriccionLocal VARCHAR(100);
UltimoPedido NUMBER;
CodOrgaCovax NUMBER;
CodOrgaAle NUMBER;
CodVacuAlea NUMBER;
CantAleVacu NUMBER(38,0);
BEGIN

   --Obtener el código del país
   SELECT p.Codigo INTO CodPais
   FROM LUGAR p INNER JOIN LUGAR a ON p.Codigo = a.Lugar
   WHERE a.Codigo = CodArea 
   AND p.Tipo= 'PAIS'
   AND a.Tipo= 'AREA';
   

   IF(VERIFICACION_SUMINISTRO(NomSumi) = 'VACUNA') THEN --Si se pidió vacuna (Flujo 2)

      DBMS_OUTPUT.PUT_LINE('Se pidió Vacunas');

      --Random para saber si quiere la distribución del COVAX
      SELECT DBMS_RANDOM.value(0,1) INTO DistriCovax
      FROM dual;

      --Si el país desea usar la distribución COVAX (Flujo 2.3.2)
      IF(DistriCovax = 1) THEN

         DBMS_OUTPUT.PUT_LINE('El país desea la distribución del COVAX');
         IF (PERTENENCIA_COVAX(CodPais)=1) THEN -- Si pertenece al COVAX (Flujo 2.3.2.2)

            IF (VERIFICAR_FINANCIAMIENTO(CodPais) = 1) THEN --Si el país está completamente financiado 2.3.2.3.2.4.3

               UltimoPedido:=ULTIMO_PEDIDO;
               CodOrgaCovax:=CODIGO_COVAX;

               INSERT INTO PEDIDO VALUES(UltimoPedido + 1, CodPais, CodOrgaCovax, ,'ENVIADO', NULL, CodSumi, , ,Financiamiento); --Se confirma la orden de compra de las dosis de las vacunas para distribuirse. (Flujo 2.3.2.3.2.4.3.3)
               DBMS_OUTPUT.PUT_LINE('Se registra el pedido ' ||UltimoPedido + 1||  'del país ' ||CodPais|| ' con la organización ' ||CodOrgaCovax|| ', por el monto de ' || || ', el pedido queda con el estatus ENVIADO, de la vacuna' ||CodSumi|| '' |||| '' |||| );
               DBMS_OUTPUT.PUT_LINE('Se inicia el modulo de distribucion');

            ELSE

               --  Se cancela la inscripción al COVAX (Flujo 2.3.2.3.3.1)

            END IF;   

         ELSE -- No pertenece al COVAX (Flujo 2.3.2.3)

            --Random para saber si el país quire ser parte del COVAX
            SELECT DBMS_RANDOM.value(0,1) INTO ParteCovax
            FROM dual;

            IF(ParteCovax = 1) THEN --Si desea ser parte del mecanismo COVAX (Flujo 2.3.2.3.2)

               DBMS_OUTPUT.PUT_LINE('El país desea ser parte del COVAX');
               Financiamiento:= ASIGNAR_FINANCIAMIENTO;
               DBMS_OUTPUT.PUT_LINE('El país tendrá un finaciamiento de: ' || Financiamiento || '%');

               --Se obtiene el país tiene restricción local
               RestriccionLocal:= VERIFICAR_RESTRICCIONES(CodPais);

               IF(Financiamiento = 100) THEN --Si el país está completamente financiado (Flujo 2.3.2.3.2.4.3)

                  --Se selecciona la cantidad de vacunas que se van a comprar en base a la población. (Flujo 2.3.2.3.2.4.3.2)

                  UltimoPedido:=ULTIMO_PEDIDO;
                  CodOrgaCovax:=CODIGO_COVAX;

                  INSERT INTO PEDIDO VALUES(UltimoPedido + 1, CodPais, CodOrgaCovax, ,'ENVIADO', NULL, CodSumi, , ,Financiamiento); --Se confirma la orden de compra de las dosis de las vacunas para distribuirse. (Flujo 2.3.2.3.2.4.3.3)
                  DBMS_OUTPUT.PUT_LINE('Se registra el pedido ' ||UltimoPedido + 1||  'del país ' ||CodPais|| ' con la organización ' ||CodOrgaCovax|| ', por el monto de ' || || ', el pedido queda con el estatus ENVIADO, de la vacuna' ||CodSumi|| '' |||| '' |||| );

               ELSE

                  --  Se cancela la inscripción al COVAX (Flujo 2.3.2.3.3.1)

               END IF;

            ELSE --No desea ser parte del mecanismo COVAX (Flujo 2.3.2.3.3)

               --  Se cancela la inscripción al COVAX (Flujo 2.3.2.3.3.1)

            END IF;

         END IF;

      --El pais no desea usar la distribución COVAX (Flujo 2.3.3)
      ELSE

         CodOrgaAle:= ORGANIZACION_ALEATORIA; --Se selecciona aleatoriamente una organización para realizar el pedido (Flujo 2.3.3.1)
         CodVacuAlea:=VACUNA_ALEATORIA; --Se selecciona aleatoriamente la vacuna a comprar para el pedido. (Flujo 2.3.3.2) 
         
         IF(VERIFICACION_OMS(CodVacuAlea) = 1) THEN --Si la vacuna está certificada por la OMS (Flujo 2.3.3.3)

            SELECT DBMS_RANDOM.value(50,60) INTO CantAleVacu --.Se selecciona la cantidad (50-60) de vacunas que se van a comprar (Flujo 2.3.3.3.1)
            FROM dual;

            UltimoPedido:=ULTIMO_PEDIDO;

            INSERT INTO PEDIDO VALUES(UltimoPedido + 1, CodPais, CodOrgaAle, ,'EN PROCESO', NULL, CodVacuAlea, ,Cantidad(CantAleVacu,0) ,0); --Se confirma la orden de compra de las dosis de las vacunas para distribuirse. (Flujo 2.3.2.3.2.4.3.3)
            DBMS_OUTPUT.PUT_LINE('Se registra el pedido ' ||UltimoPedido + 1||  'del país ' ||CodPais|| ' con la organización ' ||CodOrgaAle|| ', por el monto de ' || || ', el pedido queda con el estatus ENVIADO, de la vacuna' ||CodVacuAlea|| '' |||| '' |||| );

            --Se va para el paso (Flujo 2.2.1)

         ELSE --Si No está certificada por la OMS la vacuna (Flujo 2.3.3.4)

            DBMS_OUTPUT.PUT_LINE('La vacuna no está certificada por la OMS. Denegada solicitud del pedido');

         END IF;

      END IF;
   
   ELSE --Si no se pidió vacunas

      DBMS_OUTPUT.PUT_LINE('Se pidió insumos');

      PEDIDOS_INSUMO(CodArea NUMBER, CodSumi NUMBER, 0, TipoSumi);

   END IF;

END;


CREATE OR REPLACE FUNCTION PERTENENCIA_COVAX(CodPais NUMBER) RETURN NUMBER
IS
Pertenece NUMBER;
BEGIN
   SELECT
         CASE
            WHEN  'COVAX' = ANY (SELECT o.Nombre 
                  FROM ORGANIZACION o
                  WHERE o.Codigo = (SELECT pe.Organizacion
                                    FROM PEDIDO pe
                                    WHERE pe.Lugar = CodPais)) THEN 1
         ELSE 0
         END Clasificacion
   INTO Pertenece
   FROM Dual;

   RETURN Pertenece;
   
END;

--Se verifica si el país esta finaciado completamente
CREATE OR REPLACE FUNCTION VERIFICAR_FINANCIAMIENTO(CodPais) RETURN INTEGER
IS
UltimoPedido NUMBER;
PorceFinan NUMBER;
BEGIN

   --Ultimo pedido hecho por el país
   SELECT MAX(Codigo) INTO UltimoPedido
   FROM PEDIDO
   WHERE Lugar = CodPais;

   --Verifica con el ultimo pedido del pais el porcentaje de financiamiento
   SELECT Financia INTO PorceFinan
   FROM PEDIDO 
   WHERE Codigo = UltimoPedido;

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

--Verifica que restricciones tiene el pais
CREATE OR REPLACE FUNCTION VERIFICAR_RESTRICCIONES(CodPais) RETURN VARCHAR
IS
RestLocal VARCHAR2(100);
BEGIN
   
   SELECT r.Descripccion
   INTO RestLocal
   FROM RESTRICCION_LOCAL r
   WHERE r.Codigo = (SELECT e.Restriccion
                     FROM EXCLUSION e
                     WHERE e.Lugar = CodPais
                     AND e.Fecha_Fecha_fin IS NULL);

   RETURN RestLocal;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN NULL;

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

CREATE OR REPLACE PROCEDURE PEDIDOS_INSUMO(CodArea NUMBER, CodSumi NUMBER, TipoSumi NUMBER, CodPais NUMBER)
IS
BEGIN

   IF (PEDIDOS_PENDIENTE(CodAreA, CodSumi, TipoSumi) = 0) THEN --Si el país tiene una orden de compra de insumos (Flujo 3.2.2)

   ELSE -- Si No el país tiene una orden de compra de insumos (Flujo 3.2.3)
      
      CREACION_PEDIDO_INSUMO;

   END IF;

END;

CREATE OR REPLACE PROCEDURE CREACION_PEDIDO_INSUMO
IS

BEGIN
   
END;