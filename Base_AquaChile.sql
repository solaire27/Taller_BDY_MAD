-- =============================================================================
-- 1. LIMPIEZA DEL ESQUEMA (DROP TABLES)
-- =============================================================================
DROP TABLE Detalle_Competencias CASCADE CONSTRAINTS;
DROP TABLE Entrevista CASCADE CONSTRAINTS;
DROP TABLE Sede CASCADE CONSTRAINTS;
DROP TABLE Ciudad CASCADE CONSTRAINTS;
DROP TABLE Region CASCADE CONSTRAINTS;
DROP TABLE Pais CASCADE CONSTRAINTS;
DROP TABLE Cargos CASCADE CONSTRAINTS;
DROP TABLE Familia_Cargo CASCADE CONSTRAINTS;
DROP TABLE Candidatos CASCADE CONSTRAINTS;
DROP TABLE Decision CASCADE CONSTRAINTS;
DROP TABLE Estado CASCADE CONSTRAINTS;
DROP TABLE Psicologo CASCADE CONSTRAINTS;

-- =============================================================================
-- 2. CREACIÓN DE TABLAS (DDL)
-- =============================================================================
CREATE TABLE Candidatos 
    ( 
     Id              NUMBER  NOT NULL , 
     Nombre          VARCHAR2 (100)  NOT NULL , 
     Link_CV         VARCHAR2 (200)  NOT NULL , 
     Link_formulario VARCHAR2 (200)  NOT NULL , 
     Rut             VARCHAR2 (13)  NOT NULL , 
     Correo          VARCHAR2 (200)  NOT NULL , 
     Telefono        VARCHAR2 (13)  NOT NULL , 
     Direccion       VARCHAR2 (200)  NOT NULL 
    ) 
    LOGGING;

ALTER TABLE Candidatos ADD CONSTRAINT Candidatos_PK PRIMARY KEY ( Id ) ;

CREATE TABLE Cargos 
    ( 
     ID               NUMBER  NOT NULL , 
     Nombre_Cargo     VARCHAR2 (50)  NOT NULL , 
     Familia_Cargo_ID NUMBER  NOT NULL 
    ) 
    LOGGING;

ALTER TABLE Cargos ADD CONSTRAINT Cargos_PK PRIMARY KEY ( ID ) ;

CREATE TABLE Ciudad 
    ( 
     ID        NUMBER  NOT NULL , 
     Ciudad    VARCHAR2 (100)  NOT NULL , 
     Region_ID NUMBER  NOT NULL 
    ) 
    LOGGING;

ALTER TABLE Ciudad ADD CONSTRAINT Ciudad_PK PRIMARY KEY ( ID ) ;

CREATE TABLE Decision 
    ( 
     ID        NUMBER  NOT NULL , 
     Resultado VARCHAR2 (20)  NOT NULL 
    ) 
    LOGGING;

ALTER TABLE Decision ADD CONSTRAINT Decision_PK PRIMARY KEY ( ID ) ;

CREATE TABLE Detalle_Competencias 
    ( 
     ID                 NUMBER  NOT NULL , 
     Entrevista_ID      NUMBER  NOT NULL , 
     Nombre_Competencia VARCHAR2 (50)  NOT NULL , 
     Puntaje_IA         NUMBER , 
     Comentario_Copilot VARCHAR2 (500) 
    ) 
    LOGGING;

ALTER TABLE Detalle_Competencias ADD CONSTRAINT Detalle_Competencias_PK PRIMARY KEY ( ID ) ;

CREATE TABLE Entrevista 
    ( 
     ID              NUMBER  NOT NULL , 
     Fecha           TIMESTAMP , 
     Candidatos_Id   NUMBER  NOT NULL , 
     Estado_ID       NUMBER  NOT NULL , 
     Cargos_ID       NUMBER  NOT NULL , 
     Decision_ID     NUMBER , 
     Psicologo_Id    NUMBER , 
     Link_Informe    VARCHAR2 (200) , 
     Link_Pauta      VARCHAR2 (200) , 
     Link_Entrevista VARCHAR2 (200) , 
     Sede_ID         NUMBER  NOT NULL 
    ) 
    LOGGING;

ALTER TABLE Entrevista ADD CONSTRAINT Entrevista_PK PRIMARY KEY ( ID ) ;

CREATE TABLE Estado 
    ( 
     ID          NUMBER  NOT NULL , 
     Tipo_Estado VARCHAR2 (20)  NOT NULL 
    ) 
    LOGGING;

ALTER TABLE Estado ADD CONSTRAINT Estado_PK PRIMARY KEY ( ID ) ;

CREATE TABLE Familia_Cargo 
    ( 
     ID             NUMBER  NOT NULL , 
     Nombre_familia VARCHAR2 (50)  NOT NULL 
    ) 
    LOGGING;

ALTER TABLE Familia_Cargo ADD CONSTRAINT Familia_Cargo_PK PRIMARY KEY ( ID ) ;

CREATE TABLE Pais 
    ( 
     ID          NUMBER  NOT NULL , 
     Nombre_Pais VARCHAR2 (100)  NOT NULL 
    ) 
    LOGGING;

ALTER TABLE Pais ADD CONSTRAINT Pais_PK PRIMARY KEY ( ID ) ;

CREATE TABLE Psicologo 
    ( 
     Id     NUMBER  NOT NULL , 
     Nombre VARCHAR2 (100)  NOT NULL , 
     Rut    VARCHAR2 (13)  NOT NULL , 
     Correo VARCHAR2 (100)  NOT NULL 
    ) 
    LOGGING;

ALTER TABLE Psicologo ADD CONSTRAINT Psicologo_PK PRIMARY KEY ( Id ) ;

CREATE TABLE Region 
    ( 
     ID            NUMBER  NOT NULL , 
     Nombre_Región VARCHAR2 (100)  NOT NULL , 
     Pais_ID       NUMBER  NOT NULL 
    ) 
    LOGGING;

ALTER TABLE Region ADD CONSTRAINT Region_PK PRIMARY KEY ( ID ) ;

CREATE TABLE Sede 
    ( 
     ID            NUMBER  NOT NULL , 
     Nombre_Sede   VARCHAR2 (50)  NOT NULL , 
     Contacto_sede VARCHAR2 (14)  NOT NULL , 
     Ciudad_ID     NUMBER  NOT NULL 
    ) 
    LOGGING;

ALTER TABLE Sede ADD CONSTRAINT Sede_PK PRIMARY KEY ( ID ) ;

-- =============================================================================
-- 3. CREACIÓN DE LLAVES FORÁNEAS (CONSTRAINTS)
-- =============================================================================
ALTER TABLE Cargos ADD CONSTRAINT Cargos_Familia_Cargo_FK FOREIGN KEY (Familia_Cargo_ID) REFERENCES Familia_Cargo (ID) NOT DEFERRABLE;
ALTER TABLE Ciudad ADD CONSTRAINT Ciudad_Region_FK FOREIGN KEY (Region_ID) REFERENCES Region (ID) NOT DEFERRABLE;
ALTER TABLE Detalle_Competencias ADD CONSTRAINT Detalle_Competencias_Entrevista_FK FOREIGN KEY (Entrevista_ID) REFERENCES Entrevista (ID) NOT DEFERRABLE;
ALTER TABLE Entrevista ADD CONSTRAINT Entrevista_Candidatos_FK FOREIGN KEY (Candidatos_Id) REFERENCES Candidatos (Id) NOT DEFERRABLE;
ALTER TABLE Entrevista ADD CONSTRAINT Entrevista_Cargos_FK FOREIGN KEY (Cargos_ID) REFERENCES Cargos (ID) NOT DEFERRABLE;
ALTER TABLE Entrevista ADD CONSTRAINT Entrevista_Decision_FK FOREIGN KEY (Decision_ID) REFERENCES Decision (ID) NOT DEFERRABLE;
ALTER TABLE Entrevista ADD CONSTRAINT Entrevista_Estado_FK FOREIGN KEY (Estado_ID) REFERENCES Estado (ID) NOT DEFERRABLE;
ALTER TABLE Entrevista ADD CONSTRAINT Entrevista_Psicologo_FK FOREIGN KEY (Psicologo_Id) REFERENCES Psicologo (Id) NOT DEFERRABLE;
ALTER TABLE Entrevista ADD CONSTRAINT Entrevista_Sede_FK FOREIGN KEY (Sede_ID) REFERENCES Sede (ID) NOT DEFERRABLE;
ALTER TABLE Region ADD CONSTRAINT Region_Pais_FK FOREIGN KEY (Pais_ID) REFERENCES Pais (ID) NOT DEFERRABLE;
ALTER TABLE Sede ADD CONSTRAINT Sede_Ciudad_FK FOREIGN KEY (Ciudad_ID) REFERENCES Ciudad (ID) NOT DEFERRABLE;

-- =============================================================================
-- 4. INSERCIÓN DE DATOS (DML)
-- =============================================================================

-- Tablas maestras de Estado y Decisión
INSERT INTO Estado (ID, Tipo_Estado) VALUES (1, 'Solicitado');
INSERT INTO Estado (ID, Tipo_Estado) VALUES (2, 'En Evaluación');
INSERT INTO Estado (ID, Tipo_Estado) VALUES (3, 'Completado');

INSERT INTO Decision (ID, Resultado) VALUES (1, 'Seleccionado');
INSERT INTO Decision (ID, Resultado) VALUES (2, 'No Seleccionado');
INSERT INTO Decision (ID, Resultado) VALUES (3, 'Pendiente');

-- Tablas de Cargos
INSERT INTO Familia_Cargo (ID, Nombre_familia) VALUES (1, 'Producción Agua Mar');
INSERT INTO Familia_Cargo (ID, Nombre_familia) VALUES (2, 'Planta de Procesos');
INSERT INTO Familia_Cargo (ID, Nombre_familia) VALUES (3, 'Administración');

INSERT INTO Cargos (ID, Nombre_Cargo, Familia_Cargo_ID) VALUES (1, 'Jefe de Centro', 1);
INSERT INTO Cargos (ID, Nombre_Cargo, Familia_Cargo_ID) VALUES (2, 'Asistente de Centro', 1);
INSERT INTO Cargos (ID, Nombre_Cargo, Familia_Cargo_ID) VALUES (3, 'Operario Fileteo', 2);
INSERT INTO Cargos (ID, Nombre_Cargo, Familia_Cargo_ID) VALUES (4, 'Analista Reclutamiento', 3);

-- Tablas de Ubicación Geográfica
INSERT INTO Pais (ID, Nombre_Pais) VALUES (1, 'Chile');

INSERT INTO Region (ID, Nombre_Región, Pais_ID) VALUES (1, 'Los Lagos', 1);
INSERT INTO Region (ID, Nombre_Región, Pais_ID) VALUES (2, 'Aysén', 1);

INSERT INTO Ciudad (ID, Ciudad, Region_ID) VALUES (1, 'Puerto Varas', 1);
INSERT INTO Ciudad (ID, Ciudad, Region_ID) VALUES (2, 'Puerto Montt', 1);
INSERT INTO Ciudad (ID, Ciudad, Region_ID) VALUES (3, 'Quellón', 1);

INSERT INTO Sede (ID, Nombre_Sede, Contacto_sede, Ciudad_ID) VALUES (1, 'Oficina Central RRHH', '+56912345678', 1);
INSERT INTO Sede (ID, Nombre_Sede, Contacto_sede, Ciudad_ID) VALUES (2, 'Planta Chinquihue', '+56987654321', 2);
INSERT INTO Sede (ID, Nombre_Sede, Contacto_sede, Ciudad_ID) VALUES (3, 'Base Quellón', '+56911223344', 3);

-- Tabla Psicólogos
INSERT INTO Psicologo (Id, Nombre, Rut, Correo) VALUES (1, 'Valentina Soto', '15234567-8', 'vsoto@salmonera.cl');
INSERT INTO Psicologo (Id, Nombre, Rut, Correo) VALUES (2, 'Felipe Mansilla', '16789012-3', 'fmansilla@salmonera.cl');

-- Tabla Candidatos
INSERT INTO Candidatos (Id, Nombre, Link_CV, Link_formulario, Rut, Correo, Telefono, Direccion) 
VALUES (1, 'Carlos Alvarado', 'onedrive.com/cv_alvarado.pdf', 'forms.office.com/r/resp1', '17123456-9', 'calvarado@mail.com', '987654321', 'Calle Sur 123');

INSERT INTO Candidatos (Id, Nombre, Link_CV, Link_formulario, Rut, Correo, Telefono, Direccion) 
VALUES (2, 'Daniela Cárdenas', 'onedrive.com/cv_cardenas.pdf', 'forms.office.com/r/resp2', '18234567-0', 'dcardenas@mail.com', '912345678', 'Av. Central 456');

INSERT INTO Candidatos (Id, Nombre, Link_CV, Link_formulario, Rut, Correo, Telefono, Direccion) 
VALUES (3, 'Matías Oyarzo', 'onedrive.com/cv_oyarzo.pdf', 'forms.office.com/r/resp3', '19345678-1', 'moyarzo@mail.com', '998877665', 'Pasaje Norte 789');

-- Tabla Entrevistas
INSERT INTO Entrevista (ID, Fecha, Candidatos_Id, Estado_ID, Cargos_ID, Decision_ID, Psicologo_Id, Link_Informe, Link_Pauta, Link_Entrevista, Sede_ID) 
VALUES (1, TO_TIMESTAMP('2026-09-01 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), 1, 3, 1, 1, 1, 'sharepoint.com/informe_alvarado.xlsx', 'sharepoint.com/pauta_alvarado.docx', 'stream.com/rec_alvarado.mp4', 1);

INSERT INTO Entrevista (ID, Fecha, Candidatos_Id, Estado_ID, Cargos_ID, Decision_ID, Psicologo_Id, Link_Informe, Link_Pauta, Link_Entrevista, Sede_ID) 
VALUES (2, TO_TIMESTAMP('2026-09-06 15:30:00', 'YYYY-MM-DD HH24:MI:SS'), 2, 2, 3, NULL, 2, NULL, 'sharepoint.com/pauta_cardenas.docx', 'stream.com/rec_cardenas.mp4', 2);

INSERT INTO Entrevista (ID, Fecha, Candidatos_Id, Estado_ID, Cargos_ID, Decision_ID, Psicologo_Id, Link_Informe, Link_Pauta, Link_Entrevista, Sede_ID) 
VALUES (3, TO_TIMESTAMP('2026-09-03 11:15:00', 'YYYY-MM-DD HH24:MI:SS'), 3, 3, 2, 2, 1, 'sharepoint.com/informe_oyarzo.xlsx', 'sharepoint.com/pauta_oyarzo.docx', 'stream.com/rec_oyarzo.mp4', 3);

-- =============================================================================
-- TABLA DETALLE COMPETENCIAS (Limpiada y ajustada para el promedio PL/SQL)
-- =============================================================================

-- ENTREVISTA 1: Carlos Alvarado (Cargo: Jefe de Centro) - 3 atributos
INSERT INTO Detalle_Competencias (ID, Entrevista_ID, Nombre_Competencia, Puntaje_IA, Comentario_Copilot) 
VALUES (1, 1, 'Liderazgo de Equipos', 85, 'Fuerte capacidad para dirigir equipos en turnos de 14x14.');
INSERT INTO Detalle_Competencias (ID, Entrevista_ID, Nombre_Competencia, Puntaje_IA, Comentario_Copilot) 
VALUES (2, 1, 'Gestión de Crisis', 80, 'Manejo adecuado en mortalidades masivas.');
INSERT INTO Detalle_Competencias (ID, Entrevista_ID, Nombre_Competencia, Puntaje_IA, Comentario_Copilot) 
VALUES (3, 1, 'Orientación a Resultados', 90, 'Alto enfoque en optimización del factor de conversión.');

-- ENTREVISTA 2: Daniela Cárdenas (Cargo: Operario Fileteo) - 3 atributos
INSERT INTO Detalle_Competencias (ID, Entrevista_ID, Nombre_Competencia, Puntaje_IA, Comentario_Copilot) 
VALUES (4, 2, 'Trabajo bajo presión', 70, 'Mantiene el ritmo, pero reporta fatiga.');
INSERT INTO Detalle_Competencias (ID, Entrevista_ID, Nombre_Competencia, Puntaje_IA, Comentario_Copilot) 
VALUES (5, 2, 'Motricidad Fina', 95, 'Excelente remoción de espinas sin dañar filete.');
INSERT INTO Detalle_Competencias (ID, Entrevista_ID, Nombre_Competencia, Puntaje_IA, Comentario_Copilot) 
VALUES (6, 2, 'Higiene y Bioseguridad', 98, 'Apego estricto a protocolos de inocuidad.');

-- ENTREVISTA 3: Matías Oyarzo (Cargo: Asistente de Centro) - 2 atributos (Para gatillar la excepción)
INSERT INTO Detalle_Competencias (ID, Entrevista_ID, Nombre_Competencia, Puntaje_IA, Comentario_Copilot) 
VALUES (7, 3, 'Liderazgo de Equipos', 60, 'Muestra alta dependencia jerárquica.');
INSERT INTO Detalle_Competencias (ID, Entrevista_ID, Nombre_Competencia, Puntaje_IA, Comentario_Copilot) 
VALUES (8, 3, 'Gestión de Crisis', 65, 'Dificultad en decisiones rápidas ante bloom de algas.');

COMMIT;