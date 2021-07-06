


CREATE OR REPLACE PROCEDURE REPORTE5(Cur OUT SYS_REFCURSOR)
IS

BEGIN
---------------------CONSULTA REPORTE 5------------------------------------
OPEN Cur FOR
SELECT DISTINCT  p.Nombre AS "Nombre del Pais",
       CASE
            WHEN 1 = 1 THEN ( SELECT COUNT(*)
                              FROM Lugar l, Paciente n
                              WHERE l.Lugar = (SELECT Codigo FROM LUGAR WHERE Nombre = p.Nombre)
                              AND n.Lugar = l.Codigo
                              AND l.Tipo = 'AREA')
            ELSE 0
       END AS "Cantidad de Habitantes",
       COUNT(DISTINCT v.Paciente) AS "Cantidad de vacunados", 
       CASE
            WHEN 1 = 1 THEN to_char(((SELECT COUNT(DISTINCT Paciente)
                              FROM VACUNACION
                              WHERE Paciente IN (SELECT h.Codigo
                                                 FROM PACIENTE h, LUGAR a
                                                 WHERE a.Lugar = (SELECT Codigo FROM LUGAR WHERE Nombre = p.Nombre)
                                                 AND h.Lugar = a.Codigo
                                                 AND a.Tipo = 'AREA')
                              AND Vacuna IN (SELECT Codigo
                                             FROM VACUNA 
                                             WHERE Codigo = (SELECT Codigo FROM VACUNA WHERE Nombre = m.Nombre)))/(SELECT COUNT(*)
                                                                         FROM Lugar l, Paciente n
                                                                         WHERE l.Lugar = (SELECT Codigo FROM LUGAR WHERE Nombre = p.Nombre)
                                                                         AND n.Lugar = l.Codigo
                                                                         AND l.Tipo = 'AREA'))*100,'fm9990') || '%'
            ELSE '0'
       END AS "% de Vacunados",
       m.Nombre AS "Tipo de Vacuna de Utilizada"
FROM Lugar a,Lugar p, Paciente h, VACUNACION v, Vacuna m
WHERE a.Lugar = p.Codigo
AND h.Lugar = a.Codigo
AND v.Paciente = h.Codigo
AND v.Vacuna = m.Codigo
AND a.Tipo = 'AREA'
AND p.Tipo = 'PAIS'
GROUP BY p.Nombre,m.Nombre
ORDER BY p.Nombre;

END;



