CREATE OR REPLACE PROCEDURE PAGO_SUMINISTRO(CodPedi NUMBER)
IS
FechaAct DATE;
PagarPedido NUMBER(38,0);
CodPais Number;
CodOrg NUMBER;
MonTotal NUMBER;
FechaInicioPedido DATE;
FechaFinalPedido DATE;
AbonarPedi NUMBER(38,0);
NombrePedido VARCHAR(50);
BEGIN

   --Consulta para traerme todo lo necesario de pedido.
    SELECT pe.Lugar, pe.Organizacion, pe.Monto_Total, pe.Periodo.Fecha_inicio, pe.Periodo.Fecha_fin, pe.Nombre 
    INTO CodPais, CodOrg, MonTotal, FechaInicioPedido, FechaFinalPedido, NombrePedido
    FROM PEDIDO pe
    WHERE pe.Codigo = CodPedi;

   FechaAct:= GENERAR_FECHA(FechaFinalPedido);
   DBMS_OUTPUT.PUT_LINE(FechaAct);

   IF (VERIFICACION_FECHA(FechaFinalPedido, FechaAct) = 1) THEN --(Flujo 1)
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('La fecha actual es: ' || FechaAct || ' y la fecha final para pagar el pedido es: ' || FechaFinalPedido);
        DBMS_OUTPUT.PUT_LINE('Se ha cumplido la fecha para pagar el pedido');

       IF (VERIFICACION_PAGO(CodPedi, MonTotal) = 1) THEN --(Flujo 1.2)
            DBMS_OUTPUT.PUT_LINE('');
            DBMS_OUTPUT.PUT_LINE('Se ha abonado completamente el pago');
          --DISTRIBUCION  (Flujo 1.2.1 y Flujo 1.3.3.2)

       ELSE --(Flujo 1.3)
            DBMS_OUTPUT.PUT_LINE('');
            DBMS_OUTPUT.PUT_LINE('No se ha abonado completamente el pago');
            
           SELECT DBMS_RANDOM.value(0,1) INTO PagarPedido
           FROM dual;
        
            IF(PagarPedido = 1) THEN --(Flujo 1.3.2)
                DBMS_OUTPUT.PUT_LINE('');
                DBMS_OUTPUT.PUT_LINE('Se pagará el restante del monto total');
                PAGAR_PEDIDO(CodPedi, MonTotal, FechaAct, CodPais, CodOrg);
                
                DBMS_OUTPUT.PUT_LINE('El pedido: ' || CodPedi || ') ' || NombrePedido || ' de monto total ' || MonTotal || ' se ha pagado completamente su estatus pasa a ser: ENVIADO');
            ELSE --(Flujo 1.3.3)

             -- Se le cancelará el pedido al país solicitante. (Flujo 1.3.3.1)
             --NOTA: ACTUALIZAR LAS FECHAS. EN ESTE CASO LA FECHA FINAL DE PEDIDO PASA A SER LA ACTUAL QUE SE CANCELÓ EL PEDIDO
             UPDATE PEDIDO
             SET Estatus = 'CANCELADO'
             WHERE Codigo = CodPedi; 
             DBMS_OUTPUT.PUT_LINE('El pedido: ' || CodPedi || ') ' || NombrePedido || ' de monto total ' || MonTotal || ' no pagará el monto restante del pedido, su estatus pasa a ser: CANCELADO');
            END IF;

             --Se inicia el módulo de distribución. (Flujo 1.3.3.2)
        END IF;
      
   ELSE --(Flujo 2)
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('La fecha actual es: ' || FechaAct || ' y la fecha final para pagar el pedido es: ' || FechaFinalPedido);
        DBMS_OUTPUT.PUT_LINE('No se ha cumplido la fecha para pagar el pedido');

        --Aleatorio para se va a abonar para el total del pedido 
        SELECT DBMS_RANDOM.value(0,1) INTO AbonarPedi
        FROM dual;

        IF (AbonarPedi = 1) THEN
            
            ABONARPEDIDO(CodPedi, MonTotal, FechaAct, CodPais, CodOrg);
            DBMS_OUTPUT.PUT_LINE('');
            DBMS_OUTPUT.PUT_LINE('Ha abonado');

        ELSE
            DBMS_OUTPUT.PUT_LINE('');
            DBMS_OUTPUT.PUT_LINE('No va a abonar');
            --DISTRIBUCION (Flujo 2.3.2)
        END IF;

   END IF;
END;


-- Se actualiza los datos de la información sobre el pago de los pedidos del país. (Flujo 1.3.2.1)
CREATE OR REPLACE PROCEDURE PAGAR_PEDIDO(CodPedi NUMBER, MonTotal NUMBER, FechaAct DATE, CodPais NUMBER, CodOrg NUMBER)
IS
MontoAcumulado NUMBER;
MontoActualizado NUMBER;
CodPago NUMBER;
BEGIN
   SELECT SUM(Monto) INTO MontoAcumulado
   FROM PAGO 
   WHERE Pedido = CodPedi;

   MontoActualizado:= MonTotal - MontoAcumulado;
   DBMS_OUTPUT.PUT_LINE('El restante por pagar del monto total es: ' || MontoActualizado);

   --NOTA: ACTUALIZAR LAS FECHAS. EN ESTE CASO CADA VEZ QUE SE HACE UN PAGO, LA FECHA INICIAL DE PAGO PASA A SER LA ACTUAL
   --Hacer insert

   SELECT MAX(Codigo) INTO CodPago
   FROM  PAGO
   WHERE Pedido = CodPedi;

   INSERT INTO PAGO VALUES (CodPago + 1, CodPedi, CodPais, CodOrg, Fecha(FechaAct,NULL), MontoActualizado);
   DBMS_OUTPUT.PUT_LINE('El pago: ' || CodPago + 1 || ') Del pedido: ' ||CodPedi|| ')  se pagó la diferencia del monto total del pedido' || MontoActualizado || ' con la fecha de ' || FechaAct);

   --Se establece la confirmación de la distribución del pedido. (Flujo 1.3.2.2)
   --NOTA: ACTUALIZAR LAS FECHAS. EN ESTE CASO LA FECHA FINAL DE PEDIDO PASA A SER LA ACTUAL QUE SE REALIZO EL PAGO COMPLETO
   UPDATE PEDIDO
   SET Estatus = 'ENVIADO'
   WHERE Codigo = CodPedi; 

END;

-- Si el pedido se ha abonado completamente el pago  (Flujo 1.2 y 1.3)
--
CREATE OR REPLACE FUNCTION VERIFICACION_PAGO(CodPedi NUMBER, MonTotal NUMBER) RETURN NUMBER
IS
MontoAcumulado NUMBER; 
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


-- Verificar si ha cumplido con la fecha establecida para el pago (Flujo 1 y 2)
-- Se verifica si la fecha actual es la fecha final del pedido que corresponde la fecha que culmina el pedido, es decir que no hay más posibilidad de abonar.
CREATE OR REPLACE FUNCTION VERIFICACION_FECHA(FechaFinalPedido Date, FechaAct Date) RETURN NUMBER
IS
FechaActual DATE;
Aleatorio NUMBER;
BEGIN

   IF(FechaFinalPedido <= FechaAct) THEN
      RETURN 1;
   ELSE
      RETURN 0;
   END IF;
END;


----GENERAR_FECHA retornará una fecha que estará entre el intervalo puesto o la FechaFinalPedido
CREATE OR REPLACE FUNCTION GENERAR_FECHA(FechaFinalPedido DATE) RETURN DATE
IS
FechaActual DATE;
Aleatorio NUMBER(38,0);
DiasAleatorios NUMBER(38,0);
BEGIN

   --Si es 1 se generará y retornará una fecha aleatoria por dias aleatorios que se sumarán al sysdate. Si es 0 retornará la fecha final del pedido
   SELECT DBMS_RANDOM.value(0,1) INTO Aleatorio
   FROM dual;

   IF (Aleatorio = 0) THEN
        RETURN FechaFinalPedido;
   ELSE
        SELECT DBMS_RANDOM.value(5,50) INTO DiasAleatorios
        FROM dual;
        
        FechaActual:= SYSDATE + DiasAleatorios;
        
        RETURN FechaActual;
      
    END IF;
END;

--ABONARPEDIDO Se realiza el abono del pago que falta por pagar del monto total. (Flujo 2.2.1)
CREATE OR REPLACE PROCEDURE ABONARPEDIDO(CodPedi NUMBER, MonTotal NUMBER, FechaAct DATE, CodPais NUMBER, CodOrg NUMBER)
IS
PorcAbonar NUMBER(38,0);
MontoAcumulado NUMBER;
MontoActualizado NUMBER;
CodPago NUMBER;
BEGIN
    
    --VERIFICA CUANTO TIENE PAGADO
    SELECT SUM(Monto) INTO MontoAcumulado
    FROM PAGO 
    WHERE Pedido = CodPedi;
    
    --VERIFICA EL CODIGO DEL ULTIMO PAGO QUE SE HIZO
    SELECT MAX(Codigo) INTO CodPago
    FROM  PAGO
    WHERE Pedido = CodPedi;
    
    --Se genera un numero aleatorio para abonar parte del pedido el cual: 1-25%; 2-50%; 3-75%; 4-100%
    SELECT DBMS_RANDOM.value(1,4) INTO PorcAbonar
    FROM dual;

    IF (PorcAbonar = 1) THEN --25%

        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('Abonar 25%');
        MontoActualizado:= (MonTotal - MontoAcumulado)*0.25;
        --Se inserta el abono al monto total a pagar
        INSERT INTO PAGO VALUES (CodPago + 1, CodPedi, CodPais, CodOrg, Fecha(FechaAct,NULL), MontoActualizado);
        DBMS_OUTPUT.PUT_LINE('El pago: ' || CodPago + 1 || ') Del pedido: ' ||CodPedi|| ')  se abonó del monto total del pedido' || MontoActualizado || ' con la fecha de ' || FechaAct);

    ELSIF (PorcAbonar = 2) THEN --50%

        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('Abonar 50%');
        MontoActualizado:= (MonTotal - MontoAcumulado)*0.50;
        --Se inserta el abono al monto total a pagar
        INSERT INTO PAGO VALUES (CodPago + 1, CodPedi, CodPais, CodOrg, Fecha(FechaAct,NULL), MontoActualizado);
        DBMS_OUTPUT.PUT_LINE('El pago: ' || CodPago + 1 || ') Del pedido: ' ||CodPedi|| ')  se abonó del monto total del pedido' || MontoActualizado || ' con la fecha de ' || FechaAct);

    ELSIF (PorcAbonar = 3) THEN --75%

        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('Abonar 75%');
        MontoActualizado:= (MonTotal - MontoAcumulado)*0.75;
        --Se inserta el abono al monto total a pagar
        INSERT INTO PAGO VALUES (CodPago + 1, CodPedi, CodPais, CodOrg, Fecha(FechaAct,NULL), MontoActualizado);
        DBMS_OUTPUT.PUT_LINE('El pago: ' || CodPago + 1 || ') Del pedido: ' ||CodPedi|| ')  se abonó del monto total del pedido' || MontoActualizado || ' con la fecha de ' || FechaAct);

    ELSE --100%

        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('Abonar 100%');
        MontoActualizado:= MonTotal - MontoAcumulado;
        --Se inserta el abono al monto total a pagar
        INSERT INTO PAGO VALUES (CodPago + 1, CodPedi, CodPais, CodOrg, Fecha(FechaAct,NULL), MontoActualizado);
        DBMS_OUTPUT.PUT_LINE('El pago: ' || CodPago + 1 || ') Del pedido: ' ||CodPedi|| ')  se pagó la diferencia del monto total del pedido' || MontoActualizado || ' con la fecha de ' || FechaAct);

        --Se establece la confirmación de la distribución del pedido. (Flujo 1.3.2.2)
        UPDATE PEDIDO
        SET Estatus = 'ENVIADO'
        WHERE Codigo = CodPedi; 

        DBMS_OUTPUT.PUT_LINE('El pedido: ' || CodPedi || ') ' || NombrePedido || ' de monto total ' || MonTotal || ' se ha pagado completamente su estatus pasa a ser: ENVIADO');
    END IF;
    
END;


EXECUTE PAGO_SUMINISTRO(5);

SELECT p.Pedido,p.Lugar,p.Organizacion,p.Codigo,p.Periodo.Fecha_inicio,p.Periodo.Fecha_fin,p.Monto FROM PAGO p;

SELECT * FROM PEDIDO;

DELETE FROM PEDIDO;
DELETE FROM PAGO;