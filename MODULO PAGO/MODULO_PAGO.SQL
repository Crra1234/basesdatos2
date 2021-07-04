----------------------PROCEDIMIENTO PRINCIPAL DE PAGO
CREATE OR REPLACE PROCEDURE PAGO_SUMINISTRO(CodPedi NUMBER, CodCen NUMBER, CodArea NUMBER, NomSumi VARCHAR2(50), MonTotal NUMBER, FechaInicioPedido DATE, FechaFinalPedido DATE)
IS
BEGIN
   IF (VERIFICACION_FECHA(CodPedi, FechaFinalPedido) = 1) THEN --(Flujo 1)

      IF (VERIFICACION_PAGO(CodPedi, MonTotal) = 1) THEN --(Flujo 1.2)

         --DISTRIBUCION(CodArea, CodCen, NomSumi)  (Flujo 1.2.1 y Flujo 1.3.3.2)

      ELSE --(Flujo 1.3)
         
         IF() THEN --(Flujo 1.3.2)

            PAGAR_PEDIDO(CodPedi, MonTotal);

         ELSE --(Flujo 1.3.3)

            -- Se le cancelará el pedido al país solicitante. (Flujo 1.3.3.1)
            --NOTA: ACTUALIZAR LAS FECHAS. EN ESTE CASO LA FECHA FINAL DE PEDIDO PASA A SER LA ACTUAL QUE SE CANCELÓ EL PEDIDO
            UPDATE PEDIDO
            SET Estatus = 'CANCELADO'
            WHERE Codigo = CodPedi; 
            END IF;

            --Se inicia el módulo de distribución. (Flujo 1.3.3.2)

      END IF;
   ELSE --(Flujo 2)

      

   END IF;
END;


-- Verificar si ha cumplido con la fecha establecida para el pago (Flujo 1 y 2)
-- Se verifica si la fecha actual es la fecha final del pedido que corresponde la fecha que culmina el pedido, es decir que no hay más posibilidad de abonar.
CREATE OR REPLACE FUNCTION VERIFICACION_FECHA(CodPedi Number, FechaFinalPedido Date) RETURN NUMBER
IS
BEGIN
   IF(FechaFinalPedido = --Fecha_distribucion) THEN
      RETURN 1;
   ELSE
      RETURN 0;
END;


-- Si el pedido se ha abonado completamente el pago  (Flujo 1.2 y 1.3)
--
CREATE OR REPLACE PROCEDURE VERIFICACION_PAGO(CodPedi NUMBER, MonTotal NUMBER)
IS
MontoAcumulado NUMBER 
BEGIN
   SELECT SUM(Monto) INTO MontoAcumulado
   FROM PAGO 
   WHERE Pedido = CodPedi;

   IF (MontoAcumulado = MonTotal) THEN
      RETURN 1;
   ELSE
      RETURN 0;
   END IF;
END;


-- Se actualiza los datos de la información sobre el pago de los pedidos del país. (Flujo 1.3.2.1)
CREATE OR REPLACE PROCEDURE PAGAR_PEDIDO(CodPedi, MonTotal)
IS
MontoAcumulado NUMBER;
PagoPendiente NUMBER;
BEGIN
   SELECT SUM(Monto) INTO MontoAcumulado
   FROM PAGO 
   WHERE Pedido = CodPedi;

   --NOTA: ACTUALIZAR LAS FECHAS. EN ESTE CASO CADA VEZ QUE SE HACE UN PAGO, LA FECHA INICIAL DE PAGO PASA A SER LA ACTUAL
   UPDATE PAGO
   SET Monto = MonTotal - MontoAcumulado;
   WHERE Pedido = CodPedi; 
   END IF;

   --Se establece la confirmación de la distribución del pedido. (Flujo 1.3.2.2)
   --NOTA: ACTUALIZAR LAS FECHAS. EN ESTE CASO LA FECHA FINAL DE PEDIDO PASA A SER LA ACTUAL QUE SE REALIZO EL PAGO COMPLETO
   UPDATE PEDIDO
   SET Estatus = 'ENVIADO'
   WHERE Codigo = CodPedi; 
   END IF;

END;