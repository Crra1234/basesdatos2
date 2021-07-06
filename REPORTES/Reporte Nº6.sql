

CREATE OR REPLACE PROCEDURE REPORTE6(Cur OUT SYS_REFCURSOR, FechaInicio DATE, FechaFin DATE)
IS

BEGIN
---------------------CONSULTA REPORTE 6------------------------------------
OPEN Cur FOR
SELECT  p.Nombre AS "Nombre del Pais",
        FechaInicio AS "Fecha Inicio Vacunacion",
        FechaFin AS "Fecha fin Vacunacion",
        CASE
            WHEN 1 = 1 THEN to_char((SELECT COUNT(DISTINCT i.Paciente)
                                     FROM VACUNACION i
                                     WHERE i.Paciente IN (SELECT h.Codigo
                                                        FROM PACIENTE h, LUGAR a
                                                        WHERE a.Lugar = p.Codigo
                                                        AND h.Lugar = a.Codigo
                                                        AND a.Tipo = 'AREA')
                                     AND i.Periodo.Fecha_inicio BETWEEN FechaInicio AND FechaFin  )/(SELECT COUNT(*)
                                                                               FROM Lugar a, Paciente h
                                                                               WHERE a.Lugar = p.Codigo
                                                                               AND h.Lugar = a.Codigo
                                                                               AND a.Tipo = 'AREA')*100, 'fm9990')
            ELSE '0'
        END AS "% de Vacunados"
FROM LUGAR p
WHERE p.Tipo = 'PAIS';

END;


