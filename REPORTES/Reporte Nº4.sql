
--------------------------------REPORTE 4-------------------------------------------------

CREATE OR REPLACE PROCEDURE REPORTE4(Cur OUT SYS_REFCURSOR)
IS

BEGIN
     OPEN Cur FOR
        SELECT  p.Nombre AS "Nombre del Pais",
        CASE
            WHEN 1 = 1 THEN (SELECT rtrim(xmlagg(xmlelement(PACIENTE, CASE
                                                                      WHEN h.Grupo_Etario = 'INFANCIA' THEN  ('• ' || COUNT(*) || ' - ' || h.Grupo_Etario || ' (2 - 21 Años) ' || CHR(13) || CHR(10))
                                                                      WHEN h.Grupo_Etario = 'ADULTEZ' THEN  ('• ' || COUNT(*) || ' - ' || h.Grupo_Etario || ' (22 - 61 Años) ' || CHR(13) || CHR(10))
                                                                      ELSE ('• ' || COUNT(*) || ' - ' || h.Grupo_Etario || ' (62 años en adelante) ' || CHR(13) || CHR(10))
                                                                      END)).extract('//text()'), CHR(13) || CHR(10))
                              FROM Lugar a, Paciente h
                              WHERE a.Lugar = p.Codigo
                              AND h.Lugar = a.Codigo
                              AND a.Tipo = 'AREA'
                              GROUP BY h.Grupo_Etario)
            ELSE '0'
        END "Cantidad de Habitantes por Grupo Etario",
        CASE
            WHEN 1 = 1 THEN (SELECT rtrim(xmlagg(xmlelement(PACIENTE, CASE
                                                                      WHEN h.Grupo_Etario = 'INFANCIA' THEN  ('• ' || to_char((COUNT(*)/(SELECT COUNT(*) 
                                                                                                                                         FROM Lugar s, Paciente m
                                                                                                                                         WHERE s.Lugar = 1
                                                                                                                                         AND m.Lugar = s.Codigo
                                                                                                                                         AND s.Tipo = 'AREA'))*100,'fm9990') || '% - ' || h.Grupo_Etario || ' (2 - 21 Años) ' || CHR(13) || CHR(10))
                                                                      WHEN h.Grupo_Etario = 'ADULTEZ' THEN  ('• ' || to_char((COUNT(*)/(SELECT COUNT(*) 
                                                                                                                                         FROM Lugar s, Paciente m
                                                                                                                                         WHERE s.Lugar = 1
                                                                                                                                         AND m.Lugar = s.Codigo
                                                                                                                                         AND s.Tipo = 'AREA'))*100,'fm9990') || '% - ' || h.Grupo_Etario || ' (22 - 61 Años)  ' || CHR(13) || CHR(10))
                                                                      ELSE  ('• ' || to_char((COUNT(*)/(SELECT COUNT(*) 
                                                                                                         FROM Lugar s, Paciente m
                                                                                                         WHERE s.Lugar = 1
                                                                                                         AND m.Lugar = s.Codigo
                                                                                                         AND s.Tipo = 'AREA'))*100,'fm9990') || '% - ' || h.Grupo_Etario || ' (62 años en adelante) ' || CHR(13) || CHR(10))
                                    END)).extract('//text()'), CHR(13) || CHR(10))
                            FROM Lugar a, Paciente h
                            WHERE a.Lugar = p.Codigo
                            AND h.Lugar = a.Codigo
                            AND a.Tipo = 'AREA'
                            GROUP BY h.Grupo_Etario)
            ELSE '0%'
        END "Porcentaje de Habitantes por Grupo Etario"
FROM LUGAR p
WHERE p.Tipo = 'PAIS';
END;
