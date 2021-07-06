
------------------------------------REPORTE Nº3----------------------------------------------
CREATE OR REPLACE PROCEDURE REPORTE3(Cur OUT SYS_REFCURSOR)
IS
BEGIN
---------------------CONSULTA REPORTE 3------------------------------------
OPEN Cur FOR
SELECT p.Nombre AS "Pais",a.Codigo AS "Nº Pedido",
       CASE
            WHEN 1 = 1 THEN TO_CHAR((SELECT MAX(m.Periodo.Fecha_Inicio)
                             FROM PAGO m
                             WHERE m.Pedido = a.Codigo),'DD/MM/YYYY')
            ELSE 'NO'
       END "Fecha Pago",
       CASE
            WHEN 1 = 1 THEN TO_CHAR(((SELECT SUM(Monto)
                                      FROM PAGO
                                      WHERE Pedido = a.Codigo)/(SELECT Monto_Total
                                                                FROM PEDIDO
                                                                WHERE Codigo = a.Codigo))*100,'fm9990') || '%'
            ELSE '0%'
       END "Porcentaje Pagado",
       CASE
            WHEN 1 = 1 THEN TO_CHAR((SELECT SUM(Monto)
                                     FROM PAGO
                                     WHERE Pedido = a.Codigo),'L99999999.99')
            ELSE '$0'
       END "Monto Pagado",
       CASE
            WHEN 1 = 1 THEN  (SELECT TO_CHAR(((s.Monto_Total - SUM(k.Monto))/ s.Monto_Total)*100,'fm9990') || '%'
                              FROM PAGO k, PEDIDO s
                              WHERE k.Pedido = a.Codigo
                              AND k.Pedido = s.Codigo
                              GROUP BY s.Monto_Total)
            ELSE '0%'
       END "Porcentaje Pago Restante",
       CASE
            WHEN 1 = 1 THEN  (SELECT TO_CHAR(s.Monto_Total - SUM(k.Monto),'L99999999.99') 
                              FROM PAGO k, PEDIDO s
                              WHERE k.Pedido = a.Codigo
                              AND k.Pedido = s.Codigo
                              GROUP BY s.Monto_Total)
            ELSE '0%'
       END "Pago Restante",
       a.Financia || '%' AS "Distribucion porcentual de vacunas que el país puede disponer",
       CASE
            WHEN 1 = 1 THEN  (SELECT DISTINCT  rtrim(xmlagg(xmlelement(PEDIDO,TO_CHAR((SUM(c.Cantidad.Cant_real)/SUM(c.Cantidad.Cant_necesaria))*100,'fm9990') || '%' || ' - ' || w.Nombre || CHR(13) || CHR(10))).extract('//text()'), CHR(13) || CHR(10))
                              FROM PEDIDO c, LUGAR d, Vacuna w
                              WHERE c.Lugar = d.Codigo
                              AND c.Vacuna = w.Codigo
                              AND d.Tipo = 'PAIS'
                              AND d.Codigo = (SELECT Codigo FROM LUGAR WHERE Nombre = p.Nombre)
                              GROUP BY w.Nombre)
            ELSE '0%'
       END "Distribucion de los diferentes tipos de vacunas a incluir",
       CASE
            WHEN p.Nombre IN (SELECT o.Nombre
                             FROM EXCLUSION b INNER JOIN LUGAR o ON b.Lugar = o.Codigo
                             WHERE o.Tipo = 'PAIS') THEN  (SELECT Descripcion
                                                           FROM RESTRICCION_LOCAL
                                                           WHERE Codigo = (SELECT u.Restriccion
                                                                           FROM EXCLUSION u
                                                                           WHERE u.Lugar = (SELECT Codigo FROM LUGAR WHERE Nombre = p.Nombre)
                                                                           AND u.Periodo.Fecha_fin IS NULL ))
            ELSE 'N/A'
       END "Restricciones locales del Pais",
       TO_CHAR(a.Periodo.Fecha_Fin,'DD/MM/YYYY') AS "Fecha Estimada de Envio de Lotes",
       a.Estatus AS "Estatus"
FROM PEDIDO a INNER JOIN LUGAR p ON a.Lugar = p.Codigo 
WHERE a.Organizacion IN (SELECT Codigo FROM ORGANIZACION WHERE Nombre = 'COVAX')
AND p.Tipo = 'PAIS'
GROUP BY p.Nombre,a.Codigo,a.Financia,a.Periodo.Fecha_Fin,a.Estatus
ORDER BY p.Nombre;

END;

