------------------------ TDA FECHA ------------------------

Create or Replace TYPE Fecha as Object (
   Fecha_inicio Date,
   Fecha_fin Date,
   Static Function Validacion_fecha(Fecha_i Date,Fecha_f Date) return Varchar2
);

Create or Replace Type Body Fecha as
   Static Function Validacion_fecha(Fecha_i Date,Fecha_f Date) return Varchar2
   IS
   BEGIN
      If (Fecha_i < Fecha_f) then
         return 'Fecha valida';
      Else
         RAISE_APPLICATION_ERROR(-20002,'Periodo de tiempo invalido');
      End If;
   END;
END;

------------------------ TDA EXISTENCIA ------------------------

Create or Replace TYPE Existencia as Object (
   Cant_real NUMBER,
   Cant_necesaria NUMBER,
   Static Function get_Porcentaje return NUMBER,
   Static Function get_Restante return NUMBER
);

Create or Replace Type Body Existencia as
   Static Function get_Porcentaje return NUMBER
   IS
   BEGIN
      porcentaje:= (Cant_real * 100) / Cant_necesaria;
      return porcentaje;
   END;
END;

Create or Replace Type Body Existencia as
   Static Function get_Restante return NUMBER
   IS
   BEGIN
      restante:= (Cant_necesaria - Cant_real);
      return restante;
   END;
END;

------------------------ TDA UBICACION ------------------------
Create or Replace TYPE Ubicacion as Object (
   Localizacion NUMBER,
   Mapa BLOB,
   Static Function get_Direccion return VARCHAR2,
   Static Function get_Mapa return BLOB
);
