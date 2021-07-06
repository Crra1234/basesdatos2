
--------------------------------REPORTE 2-------------------------------------------------

CREATE OR REPLACE PROCEDURE REPORTE2(Cur OUT SYS_REFCURSOR)
IS

BEGIN
    --DBMS_OUTPUT.PUT_LINE('A');
     OPEN Cur FOR
        SELECT  p.Nombre AS "Nombre del Pais",
        CASE
            WHEN 1 = 1 THEN (SELECT COUNT(*) AS "Cantidad"
                             FROM Lugar a, Paciente h
                             WHERE a.Lugar = 1
                             AND h.Lugar = a.Codigo
                             AND a.Tipo = 'AREA')
            ELSE 0
        END AS "Cantidad de habitantes",
        CASE 
            WHEN p.Codigo IN (SELECT Codigo FROM PEDIDO) THEN (SELECT rtrim(xmlagg(xmlelement(PEDIDO,'• ' || SUM(l.Cantidad.Cant_real) || ' (' || to_char( (SUM(l.Cantidad.Cant_real)/SUM(l.Cantidad.Cant_necesaria))*100 , 'fm9990') || '%) - ' || Nombre || CHR(13) || CHR(10))).extract('//text()'), CHR(13) || CHR(10))
                                                               FROM PEDIDO l, Vacuna v
                                                               WHERE l.lugar = p.Codigo
                                                               AND l.Vacuna = v.Codigo
                                                               GROUP BY v.Nombre)
            ELSE '0'
        END AS "% y Cantidad de Vacunas por Tipo",
        CASE
            WHEN p.Codigo IN (SELECT DISTINCT Lugar
                            FROM PEDIDO
                            WHERE Organizacion IN (SELECT Codigo FROM ORGANIZACION WHERE Nombre = 'COVAX') ) THEN 'SI'
            ELSE 'NO'
        END AS "¿El Pais forma parte del Mecanismo COVAX?"
        FROM LUGAR p
        WHERE p.Tipo = 'PAIS';
END;

