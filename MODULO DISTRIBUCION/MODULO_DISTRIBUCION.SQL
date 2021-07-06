CREATE OR REPLACE PROCEDURE DISTRIBUCION(CodArea NUMBER, CodCen NUMBER, NomSumi VARCHAR2) 
IS
CodSumi NUMBER;
BEGIN

   IF(VERIFICACION_SUMINISTRO(NomSumi) = 'VACUNA') THEN
      
      SELECT Codigo INTO CodSumi 
      FROM Vacuna 
      WHERE Nombre = NomSumi;
      
      DBMS_OUTPUT.PUT_LINE('es vacuna');

      IF (DISPONIBILIDAD(CodArea, CodSumi,1) = 1) THEN           --El país tiene suministros disponibles
         --------------(Flujo 3.4 al 3.8)
        DBMS_OUTPUT.PUT_LINE('Hay disponibilidad');
        DISTRIBUCION_CENTRO(CodArea, CodCen, CodSumi, 'VACUNA');
      ELSE                                                     --El país no suministros disponibles
         --------------(Flujo 4.1 al 4.3)
         -- Se verifica si hay pedidos pendiente 'EN PROCESO'
         DBMS_OUTPUT.PUT_LINE('No hay disponibilidad');
         IF (PEDIDOS_PENDIENTE(CodArea, CodSumi,1) = 0) THEN
            DBMS_OUTPUT.PUT_LINE('Llama al modulo de pago');
            --Llama al modulo de pago (Flujo 4.2.3.2)
         ELSE
            DBMS_OUTPUT.PUT_LINE('Llama al modulo de pedido');

            REALIZAR_PEDIDO(CodSumi, CodArea, NomSumi, CodCen);
            --Llama al modulo de pepido (Flujo 4.3.2)
         END IF;

      END IF;

   ELSE

      SELECT Codigo INTO CodSumi
      FROM INSUMO 
      WHERE Nombre = NomSumi;
      
      DBMS_OUTPUT.PUT_LINE('es insumo');

      IF (DISPONIBILIDAD(CodArea, CodSumi,0) = 1) THEN           --El país tiene suministros disponibles
         --------------(Flujo 3.4 al 3.8)
         DBMS_OUTPUT.PUT_LINE('Hay disponibilidad');
         DISTRIBUCION_CENTRO(CodArea, CodCen, CodSumi, 'INSUMO');
         
      ELSE                                                     --El país no suministros disponibles
      --------------(Flujo 4.1 al 4.3)
      -- Se verifica si hay pedidos pendiente 'EN PROCESO'
      DBMS_OUTPUT.PUT_LINE('No hay disponibilidad');
         IF (PEDIDOS_PENDIENTE(CodArea, CodSumi,1) = 0) THEN
            DBMS_OUTPUT.PUT_LINE('Llama al modulo de pago');
            --Llama al modulo de pago (Flujo 4.2.3.2)
         ELSE
            DBMS_OUTPUT.PUT_LINE('Llama al modulo de pedido');
            --Llama al modulo de pepido (Flujo 4.3.2)
         END IF;

      END IF;

   END IF;
END;

--
CREATE OR REPLACE FUNCTION VERIFICACION_SUMINISTRO(NomSumi VARCHAR2) RETURN VARCHAR2
IS
TipoSumi VARCHAR2(50);
BEGIN

   SELECT
      CASE
         WHEN NomSumi = ANY(SELECT Nombre FROM Vacuna) THEN 'VACUNA' 
      ELSE 'INSUMO'                                                  
      END Clasificacion
   INTO TipoSumi
   FROM Dual;

   RETURN TipoSumi;
END;



CREATE OR REPLACE FUNCTION DISPONIBILIDAD(CodArea NUMBER, CodSumi NUMBER, TipoSumi NUMBER) RETURN NUMBER 
IS
Disponible NUMBER;
BEGIN

   IF(TipoSumi = 1) THEN                                          --ES UNA VACUNA
      SELECT
         CASE
            WHEN  0 < ANY (SELECT pe.Cantidad.Cant_real 
                  FROM PEDIDO pe 
                  WHERE pe.Estatus = 'ENVIADO'
                  AND pe.Vacuna = CodSumi
                  AND pe.Lugar = (SELECT p.Codigo
                                    FROM LUGAR p INNER JOIN LUGAR a ON p.Codigo = a.Lugar
                                    WHERE a.Codigo = CodArea 
                                    AND p.Tipo= 'PAIS'
                                    AND a.Tipo= 'AREA')) THEN 1 
         ELSE 0
         END Clasificacion
      INTO Disponible
      FROM Dual;
   
   ELSE                                                           --ES UNA INSUMO

      SELECT
      CASE
         WHEN  0 < ANY (SELECT pe.Cantidad.Cant_real 
               FROM PEDIDO pe 
               WHERE pe.Estatus = 'ENVIADO'
               AND pe.Insumo = CodSumi
               AND pe.Lugar = (SELECT p.Codigo
                                 FROM LUGAR p INNER JOIN LUGAR a ON p.Codigo = a.Lugar
                                 WHERE a.Codigo = CodArea 
                                 AND p.Tipo= 'PAIS'
                                 AND a.Tipo= 'AREA')) THEN 1 
         ELSE 0
      END Clasificacion
      INTO Disponible
      FROM Dual;
   END IF;

   RETURN Disponible;
END;


CREATE OR REPLACE FUNCTION PEDIDOS_PENDIENTE(CodArea NUMBER, CodSumi NUMBER, TipoSumi NUMBER) RETURN NUMBER 
IS
Pendiente NUMBER;
BEGIN

   IF(TipoSumi = 1) THEN                                          --ES UNA VACUNA
      SELECT
         CASE
            WHEN  'EN PROCESO' = ANY (SELECT pe.Estatus 
                  FROM PEDIDO pe 
                  WHERE pe.Vacuna = CodSumi
                  AND pe.Lugar = (SELECT p.Codigo
                                    FROM LUGAR p INNER JOIN LUGAR a ON p.Codigo = a.Lugar
                                    WHERE a.Codigo = CodArea 
                                    AND p.Tipo= 'PAIS'
                                    AND a.Tipo= 'AREA')) THEN 0 
         ELSE 1
         END Clasificacion
      INTO Pendiente
      FROM Dual;
   
   ELSE                                                           --ES UNA INSUMO

      SELECT
      CASE
         WHEN  'EN PROCESO' = ANY (SELECT pe.Cantidad.Cant_real 
               FROM PEDIDO pe 
               WHERE pe.Insumo = CodSumi
               AND pe.Lugar = (SELECT p.Codigo
                                 FROM LUGAR p INNER JOIN LUGAR a ON p.Codigo = a.Lugar
                                 WHERE a.Codigo = CodArea 
                                 AND p.Tipo= 'PAIS'
                                 AND a.Tipo= 'AREA')) THEN 0 
         ELSE 1
      END Clasificacion
      INTO Pendiente
      FROM Dual;
   END IF;

   RETURN Pendiente;
END;


CREATE OR REPLACE PROCEDURE DISTRIBUCION_CENTRO(CodArea NUMBER, CodCentro NUMBER, CodSumi NUMBER, TipoSumi VARCHAR2)
IS

   Cantidad_Real NUMBER;
   Cantidad_Necesaria NUMBER;
   CantidadDemanda NUMBER;
   CodigoPedido NUMBER;

BEGIN

   IF (TipoSumi = 'VACUNA') THEN

      SELECT *
      INTO Cantidad_Real, CodigoPedido
         FROM( SELECT pe.Cantidad.Cant_real, pe.Codigo 
                  FROM PEDIDO pe 
                  WHERE pe.Estatus = 'ENVIADO'
                  AND pe.Vacuna = CodSumi
                  AND pe.Cantidad.Cant_real <> 0
                  AND pe.Lugar = (SELECT p.Codigo
                                    FROM LUGAR p INNER JOIN LUGAR a ON p.Codigo = a.Lugar
                                    WHERE a.Codigo = CodArea 
                                    AND p.Tipo= 'PAIS'
                                    AND a.Tipo= 'AREA')
               ORDER BY dbms_random.random)
      WHERE rownum < 2;

      

      SELECT d.Cantidad.Cant_necesaria INTO Cantidad_Necesaria
      FROM DOSIS d
      WHERE d.Centro=CodCentro
      AND d.Vacuna = CodSumi; 

      CantidadDemanda:= Cantidad_Real - Cantidad_Necesaria; 
      
      -- Se actualiza el pedido del país sobre el suministro
      UPDATE PEDIDO pe
      SET pe.Cantidad.Cant_real = CantidadDemanda
      WHERE Codigo = CodigoPedido; 

      UPDATE DOSIS d
      SET d.Cantidad.Cant_real =  d.Cantidad.Cant_real + Cantidad_Necesaria ,d.Cantidad.Cant_necesaria = 0
      WHERE d.Centro=CodCentro
      AND d.Vacuna = CodSumi;                                                                                 

   ELSE

      SELECT *
      INTO Cantidad_Real, CodigoPedido
         FROM( SELECT pe.Cantidad.Cant_real, pe.Codigo 
                  FROM PEDIDO pe 
                  WHERE pe.Estatus = 'ENVIADO'
                  AND pe.Insumo = CodSumi
                  AND pe.Cantidad.Cant_real != 0
                  AND pe.Lugar = (SELECT p.Codigo
                                    FROM LUGAR p INNER JOIN LUGAR a ON p.Codigo = a.Lugar
                                    WHERE a.Codigo = CodArea 
                                    AND p.Tipo= 'PAIS'
                                    AND a.Tipo= 'AREA')
               ORDER BY dbms_random.random)
      WHERE rownum < 2;

      SELECT i.Cantidad.Cant_necesaria INTO Cantidad_Necesaria                                     -- Lo que se distribuye al centro de vacunación
      FROM INVENTARIO i
      WHERE i.Centro=CodCentro
      AND i.Insumo = CodSumi; 

      CantidadDemanda:= Cantidad_Real - Cantidad_Necesaria; 
      
      -- Se actualiza el pedido del país sobre el suministro
      UPDATE PEDIDO pe
      SET pe.Cantidad.Cant_real = CantidadDemanda
      WHERE Codigo = CodigoPedido; 

      UPDATE INVENTARIO i
      SET i.Cantidad.Cant_real =  i.Cantidad.Cant_real + Cantidad_Necesaria , i.Cantidad.Cant_necesaria = 0
      WHERE i.Centro=CodCentro
      AND i.Insumo = CodSumi;    
   END IF;

END;

UPDATE PEDIDO p SET p.Monto_Total = 500, p.Estatus = 'EN PROCESO' WHERE p.Codigo = 2;

SELECT * FROM PEDIDO;

DELETE FROM PEDIDO;
