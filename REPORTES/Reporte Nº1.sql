
-------------------------Procedimiento reporte Nº1---------------------------------
CREATE OR REPLACE PROCEDURE REPORTE1(Cur OUT SYS_REFCURSOR)
IS
BEGIN

    OPEN Cur FOR
        SELECT  o.Creacion.Fecha_inicio as "Fecha de Creacion", 
                o.Aprobacion.Fecha_inicio as "Fecha de Aprobacion", 
                v.Nombre as "Nombre de la Vacuna", 
                CASE 
                    WHEN o.Aprobacion is NULL THEN 'No esta Aprobada por la OMS'
                    ELSE 'Aprobada por la OMS'
                END "Estatus de la Vacuna",
                v.Fase as "Fase de Vacuna",
                CONCAT(v.Efectividad,'%') as "% de Efectividad",
                CASE 
                    WHEN p.Nombre = 'COVAX' THEN 'Si'
                    ELSE 'No'
                END "¿Se distribuye por mecanismo COVAX?"
        FROM VA_OR o, VACUNA v, ORGANIZACION p
        WHERE o.Vacuna = v.Codigo
        AND o.Organizacion = p.Codigo; 
END;