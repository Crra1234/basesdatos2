-------------------------------- Seleccion del área y centro del país --(Flujo 1 Y 2)
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