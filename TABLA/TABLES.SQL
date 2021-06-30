

CREATE TABLE LUGAR(
    Codigo NUMBER PRIMARY KEY,
    Nombre VARCHAR2(20) NOT NULL,
    Tipo VARCHAR2(10) NOT NULL,
    Bandera BLOB, 
    Lugar NUMBER,
    CONSTRAINT FK_Lugar FOREIGN KEY (Lugar) REFERENCES LUGAR(Codigo),
    CONSTRAINT P_Tipo CHECK (Tipo IN ('CONTINENTE','PAIS','ESTADO','AREA'))
);

CREATE TABLE PACIENTE (
    Codigo NUMBER PRIMARY KEY,
    Cedula NUMBER NOT NULL,
    Primer_Nombre VARCHAR2(20) NOT NULL,
    Segundo_Nombre VARCHAR2(20),
    Primer_Apellido VARCHAR2(20) NOT NULL,
    Segundo_Apellido VARCHAR2(20),
    Fecha_Nacimiento DATE NOT NULL ,
    Grupo_Etario VARCHAR2(8) NOT NULL,
    Lugar NUMBER,
    CONSTRAINT CH_Grupo_Etario CHECK (Grupo_Etario IN ('JOVEN','ADULTO','ANCIANO')),
    CONSTRAINT FK_Paciente_Lugar FOREIGN KEY (Lugar) REFERENCES LUGAR(Codigo)
 );


CREATE TABLE CENTRO_VACUNACION (
    Codigo NUMBER PRIMARY KEY,
    Nombre VARCHAR2(80) NOT NULL,
    Capacidad NUMBER NOT NULL,
    Colapsado VARCHAR2(1) NOT NULL,
    Lugar NUMBER NOT NULL,
    CONSTRAINT FK_Centro_Lugar FOREIGN KEY (Lugar) REFERENCES LUGAR(Codigo),
    CONSTRAINT Check_Colapsado CHECK (Colapsado IN ('S','N'))
);

CREATE TABLE VACUNA (
    Codigo NUMBER PRIMARY KEY,
    Nombre VARCHAR2(20) NOT NULL,
    Efectividad NUMBER NOT NULL,
    Fase VARCHAR2(40) NOT NULL,
    Temperatura VARCHAR2(20) NOT NULL,
    Instrucciones_Especiales VARCHAR2(100) NOT NULL
);


CREATE TABLE VIRUS(
    Codigo NUMBER PRIMARY KEY,
    Nombre VARCHAR2(20) NOT NULL,
    Descripcion VARCHAR2(100)
);

CREATE TABLE INSUMO(
    Codigo NUMBER PRIMARY KEY,
    Nombre VARCHAR2(50) NOT NULL,
    Tipo VARCHAR2(20) NOT NULL,
    CONSTRAINT Check_Tipo_Insumo CHECK (Tipo IN ('Guantes','Jeringas', 'Alcohol', 'Algodon'))
);

CREATE TABLE DOSIS (
    Centro NUMBER NOT NULL,
    Vacuna NUMBER NOT NULL,
    Cantidad Existencia,
    CONSTRAINT PK_Centro_Vacunacion PRIMARY KEY (Centro,Vacuna),
    CONSTRAINT FK_Centro_Vacunacion FOREIGN KEY (Centro) REFERENCES CENTRO_VACUNACION(Codigo),
    CONSTRAINT FK_Dosis_Vacuna FOREIGN KEY (Vacuna) REFERENCES VACUNA (Codigo)
);

CREATE TABLE INVENTARIO(
    Centro NUMBER NOT NULL,
    Insumo NUMBER NOT NULL,
    Cantidad Existencia,
    CONSTRAINT PK_Inventario PRIMARY KEY (Centro,Insumo),
    CONSTRAINT FK_Inventario_Centro_Vacunacion FOREIGN KEY (Centro) REFERENCES CENTRO_VACUNACION(Codigo),
    CONSTRAINT FK_Insumo FOREIGN KEY (Insumo) REFERENCES INSUMO (Codigo)
);

CREATE TABLE VARIANTE(
   Codigo NUMBER NOT NULL,
   Nombre VARCHAR2(20) NOT NULL,
   Descripcion VARCHAR2(100) NOT NULL,
   Virus NUMBER NOT NULL,
   CONSTRAINT PK_Virus PRIMARY KEY (Codigo,Virus),
   CONSTRAINT FK_Variante_Virus FOREIGN KEY (Virus) REFERENCES VIRUS(Codigo)
);

CREATE TABLE BROTE (
    Virus NUMBER NOT NULL,
    Lugar NUMBER NOT NULL,
    Periodo FECHA,  
    CONSTRAINT PK_Brote PRIMARY KEY (Virus,Lugar),
    CONSTRAINT FK_Virus FOREIGN KEY (Virus) REFERENCES VIRUS(Codigo),
    CONSTRAINT FK_Brote_Lugar FOREIGN KEY (Lugar) REFERENCES LUGAR(Codigo)
);


CREATE TABLE RESTRICCION_LOCAL(
    Codigo NUMBER PRIMARY KEY,
    Descripcion VARCHAR2(100) NOT NULL
);


CREATE TABLE EXCLUSION(
    Restriccion NUMBER NOT NULL,
    Lugar NUMBER NOT NULL,
    Periodo Fecha,
    CONSTRAINT PK_Exclusion PRIMARY KEY (Restriccion,Lugar),
    CONSTRAINT FK_Restriccion FOREIGN KEY (Restriccion) REFERENCES RESTRICCION_LOCAL(Codigo),
    CONSTRAINT FK_Excusion_Lugar FOREIGN KEY (Lugar) REFERENCES LUGAR(Codigo)
);


CREATE TABLE INFECCION (
    Virus NUMBER NOT NULL,
    Lugar NUMBER NOT NULL,
    Paciente NUMBER NOT NULL,
    Periodo Fecha,
    CONSTRAINT PK_Infeccion PRIMARY KEY (Virus,Lugar,Paciente),
    CONSTRAINT FK_Infeccion_Virus FOREIGN KEY (Virus) REFERENCES VIRUS(Codigo),
    CONSTRAINT FK_Infeccion_Lugar FOREIGN KEY (Lugar) REFERENCES LUGAR(Codigo),
    CONSTRAINT FK_Paciente FOREIGN KEY (Paciente) REFERENCES PACIENTE(Codigo)
);

CREATE TABLE VACUNACION (
    Vacuna NUMBER NOT NULL,
    Centro NUMBER NOT NULL,
    Paciente NUMBER NOT NULL,
    Periodo FECHA,
    CONSTRAINT PK_Vacunacion PRIMARY KEY (Vacuna,Centro,Paciente),
    CONSTRAINT FK_Dosis FOREIGN KEY (Vacuna,Centro) REFERENCES DOSIS(Vacuna,Centro),
    CONSTRAINT FK_Vacunacion_Paciente FOREIGN KEY (Paciente) REFERENCES PACIENTE(Codigo)
);

CREATE TABLE EFECTO_SECUNDARIO(
    Codigo NUMBER PRIMARY KEY,
    Nombre VARCHAR2(20) NOT NULL,
    Descripcion VARCHAR2(100)
);

CREATE TABLE REGISTRO_REACCION(
    Vacuna NUMBER NOT NULL,
    Centro NUMBER NOT NULL,
    Paciente NUMBER NOT NULL,
    Efecto NUMBER NOT NULL,
    Periodo FECHA,
    CONSTRAINT PK_Registro_Reaccion PRIMARY KEY (Vacuna,Centro,Paciente,Efecto),
    CONSTRAINT FK_Vacunacion FOREIGN KEY (Vacuna,Centro,Paciente) REFERENCES VACUNACION(Vacuna,Centro,Paciente),
    CONSTRAINT FK_Efecto FOREIGN KEY (Efecto) REFERENCES EFECTO_SECUNDARIO(Codigo)
);

CREATE TABLE PRUEBA(
    Efecto NUMBER NOT NULL,
    Vacuna NUMBER NOT NULL,
    CONSTRAINT PK_Prueba PRIMARY KEY (Efecto,Vacuna),
    CONSTRAINT FK_Prueba_Vacuna FOREIGN KEY (Vacuna) REFERENCES VACUNA(Codigo),
    CONSTRAINT FK_Prueba_Efecto FOREIGN KEY (Efecto) REFERENCES EFECTO_SECUNDARIO(Codigo)
);

CREATE TABLE ORGANIZACION(
    Codigo NUMBER PRIMARY KEY,
    Nombre VARCHAR2(20) NOT NULL,
    Tipo VARCHAR2(20) NOT NULL,
    CONSTRAINT Check_Tipo_Organizacion CHECK (Tipo IN ('Privada','Publica'))
);

CREATE TABLE VA_OR(
    Vacuna NUMBER NOT NULL,
    Organizacion NUMBER NOT NULL,
    Creacion FECHA,
    Aprobacion FECHA,
    CONSTRAINT PK_VA_OR PRIMARY KEY (Vacuna,Organizacion),
    CONSTRAINT FK_VAOR_Vacuna FOREIGN KEY (Vacuna) REFERENCES VACUNA(Codigo),
    CONSTRAINT FK_Organizacion FOREIGN KEY (Organizacion) REFERENCES ORGANIZACION(Codigo)
);

CREATE TABLE SEDE(
    Organizacion NUMBER NOT NULL,
    Lugar NUMBER NOT NULL,
    CONSTRAINT PK_Sede PRIMARY KEY (Organizacion,Lugar),
    CONSTRAINT FK_Sede_Organizacion FOREIGN KEY (Organizacion) REFERENCES ORGANIZACION(Codigo),
    CONSTRAINT FK_Sede_Lugar FOREIGN KEY (Lugar) REFERENCES LUGAR(Codigo)
);

CREATE TABLE PEDIDO(
    Lugar NUMBER NOT NULL,
    Organizacion NUMBER NOT NULL,
    Monto_Total NUMBER NOT NULL,
    Estatus VARCHAR2(20) NOT NULL,
    Insumo NUMBER,
    Vacuna NUMBER,
    Periodo FECHA,
    Cantidad Existencia,
    CONSTRAINT PK_Pedido PRIMARY KEY (Organizacion,Lugar),
    CONSTRAINT FK_Pedido_Organizacion FOREIGN KEY (Organizacion) REFERENCES ORGANIZACION(Codigo),
    CONSTRAINT FK_Pedido_Lugar FOREIGN KEY (Lugar) REFERENCES LUGAR(Codigo),
    CONSTRAINT FK_Pedido_Insumo FOREIGN KEY (Insumo) REFERENCES INSUMO(Codigo),
    CONSTRAINT FK_Pedido_Vacuna FOREIGN KEY (Vacuna) REFERENCES VACUNA(Codigo),
    CONSTRAINT Check_Pedido CHECK ((Insumo IS NOT NULL AND Vacuna IS NULL) OR (Vacuna IS NOT NULL AND Insumo IS NULL)),
    CONSTRAINT Check_Estatus CHECK (Estatus in ('EN PROCESO','ENVIADO','CANCELADO'))
);

CREATE TABLE PAGO(
    Lugar NUMBER NOT NULL,
    Organizacion NUMBER NOT NULL,
    Codigo NUMBER NOT NULL,
    Periodo FECHA,
    Monto NUMBER NOT NULL,
    CONSTRAINT PK_Pago PRIMARY KEY (Lugar,Organizacion,Codigo),
    CONSTRAINT FK_Pago_Lugar FOREIGN KEY (Lugar) REFERENCES LUGAR(Codigo),
    CONSTRAINT FK_Pago_Organizacion FOREIGN KEY (Organizacion) REFERENCES ORGANIZACION(Codigo)
);
