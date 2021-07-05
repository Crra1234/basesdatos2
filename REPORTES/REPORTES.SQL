--1.- Reporte de diferentes tipos de vacuna (Parametrizado por Nombre de la vacuna y/o fecha de aprobación):
--Se debe contar con un reporte que indique a nivel mundial las diferentes vacunas COVID-19 que están descubriéndose, así como aquellas
--que han sido aprobadas por la OMS y si forma parte de la distribución a través del mecanismo COVAX

DECLARE 
    Cor SYS_REFCURSOR;
BEGIN 
    --REPORTE1(Cor,null,null); 
    --REPORTE1(Cor,null,'04-SEP-2021'); 
    -- REPORTE1(Cor,'Pfizer',null); 
    --REPORTE1(Cor,'Pfizer','04-SEP-2021'); 
END;

CREATE OR REPLACE PROCEDURE REPORTE1(Cur OUT SYS_REFCURSOR, NomVac VARCHAR2,  FechaAprobacion DATE)
IS
BEGIN
    IF(NomVac IS NULL AND FechaAprobacion IS NULL) THEN
        ----------------- APARTADO A: LOS 2 PARAMETROS SON OPCIONALES-------------------
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
            
    ELSIF(NomVac IS NULL AND FechaAprobacion IS NOT NULL) THEN
    ----------------- APARTADO B: NomVac es Opcional y FechaAprobacion no es Opcional-------------------
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
            AND o.Organizacion = p.Codigo
            AND TO_CHAR(o.Aprobacion.Fecha_inicio,'DD/MM/YYYY') = TO_CHAR(FechaAprobacion,'DD/MM/YYYY');
    
    ELSIF(NomVac IS NOT NULL AND FechaAprobacion IS NULL) THEN
    ----------------- APARTADO C: NomVac no es Opcional y FechaAprobacion es Opcional-------------------
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
            AND o.Organizacion = p.Codigo
            AND v.Nombre = NomVac;
    
    ELSE
        ----------------- APARTADO D: LOS 2 PARAMETROS NO SON OPCIONALES-------------------
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
            AND o.Organizacion = p.Codigo
            AND v.Nombre = NomVac
            AND TO_CHAR(o.Aprobacion.Fecha_inicio,'DD/MM/YYYY') = TO_CHAR(FechaAprobacion,'DD/MM/YYYY');
    END IF;
END;



--2.- Reporte de cantidad y porcentaje de vacunas por tipo a disposición de los diferentes países del mundo (Parametrizado por
--Nombre del País y/o tipo de vacuna y/o fecha de inicio adquisición y/o fecha de fin adquisición):
--Es importante contar con un reporte que indique el porcentaje de vacunas por tipo que poseen los diversos países del mundo a una
--determinada fecha.



--3.- Reporte de países que forman parte del mecanismo COVAX y aportes monetarios realizados (Parametrizado Nombre de País y/o
--estatus):
--Los diferentes países del mundo que forman parte del mecanismo COVAX deben realizar un pago de forma anticipada para poder obtener las
--vacunas, para ello se requieren los siguientes datos.



--4.- Reporte de cantidad de habitantes de los diferentes países por grupo etario (Parametrizado por Nombre del País, Porcentaje de
--habitantes por grupo etario):
--Una de las estrategias de vacunación corresponde a un plan que establezca los diferentes grupos etarios que tendrán prioridad en la
--vacunación, es por eso que se requiere un reporte que indique por país esta distribución de grupos



--5.- Cantidad y porcentaje de población vacunada en los diferentes países del mundo (Parametrizado por Nombre del país y/o % de
--vacunados y/o tipo de la vacuna utilizada)
--Es de vital importancia conocer de manera cuantitativa el porcentaje de población vacunada y el tipo de vacuna utilizada para la inmunización.



--6.- Porcentaje total de vacunados por los países del mundo (Parametrizado por: Nombre del país y/o Porcentaje total de vacunados
--y/o fecha de inicio y/o fecha de fin)
--Cada país debe contar con un reporte que le indique el porcentaje total de personas vacunas entre una fecha de inicio y fin



--7.- Reporte con centros de vacunación dispuestos por los diferentes países del mundo (Parametrizado Nombre del país)
--La inmunización se puede realizar en diferentes centros de vacunación dispuestos en la logística de la aplicación de la vacuna, se desea
--contar con un reporte en donde identifique la cantidad de vacunados por grupo etario en los diferentes centros de vacunación