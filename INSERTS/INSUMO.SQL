INSERT INTO INSUMO VALUES (1, 'Alcomex', 'Alcohol');
INSERT INTO INSUMO VALUES (2, 'Isopropyl','Alcohol');
INSERT INTO INSUMO VALUES (3, 'Medispo', 'Guantes');
INSERT INTO INSUMO VALUES (4, 'Nuzone', 'Guantes');
INSERT INTO INSUMO VALUES (5, 'Peta-taft', 'Guantes');
INSERT INTO INSUMO VALUES (6, 'Alve', 'Algodon');
INSERT INTO INSUMO VALUES (7, 'Medispo', 'Algodon');
INSERT INTO INSUMO VALUES (8, 'Algodon hidrofilo', 'Algodon');
INSERT INTO INSUMO VALUES (9, 'Sterille Latex', 'Guantes');
INSERT INTO INSUMO VALUES (10, 'Twinrix', 'Jeringa');
INSERT INTO INSUMO VALUES (11, 'BD Ultra-Fine', 'Jeringa');
INSERT INTO INSUMO VALUES (12, 'Clexane', 'Jeringa');
INSERT INTO INSUMO VALUES (13, 'Masglo', 'Alcohol');
INSERT INTO INSUMO VALUES (14, 'Alcohol Isopropílico', 'Alcohol');
INSERT INTO INSUMO VALUES (15, 'Clenox', 'Jeringa');


CREATE TABLE INVENTARIO(
   Centro NUMBER NOT NULL;
   Insumo NUMBER NOT NULL;
   Cantidad Existencia;
   CONSTRAINT FK_Centro FOREIGN KEY (Centro) REFERENCES CENTRO_VACUNACION(Codigoo),
   CONSTRAINT FK_Insumo FOREIGN KEY (Insumo) REFERENCES INSUMO(Codigo)
);