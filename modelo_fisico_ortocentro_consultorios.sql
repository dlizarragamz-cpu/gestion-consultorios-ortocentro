-- =====================================================================
-- Caso: OrtoCentro — Gestión de Consultorios Médicos
-- Modelo físico — Microsoft SQL Server
-- Estructura: medicos / consultorios / horario_base / bloqueos /
--             notificaciones_bloqueo
-- =====================================================================

CREATE DATABASE ortocentro_consultorios;
GO
USE ortocentro_consultorios;
GO

-- ---------------------------------------------------------------------
-- Médicos
-- ---------------------------------------------------------------------
CREATE TABLE medicos (
    id_medico           INT IDENTITY(1,1) PRIMARY KEY,
    cmp                 VARCHAR(15)   NOT NULL UNIQUE,   -- Colegio Médico del Perú
    nombres             NVARCHAR(150) NOT NULL,
    frecuencia_cita_min TINYINT       NOT NULL CHECK (frecuencia_cita_min IN (15,20,25,30)),
    estado              VARCHAR(20)   NOT NULL DEFAULT 'ACTIVO'
);
GO

-- ---------------------------------------------------------------------
-- Consultorios
-- ---------------------------------------------------------------------
CREATE TABLE consultorios (
    id_consultorio  INT IDENTITY(1,1) PRIMARY KEY,
    codigo          VARCHAR(10)   NOT NULL UNIQUE,       -- ej: C-01 ... C-08
    ubicacion       NVARCHAR(100) NULL,
    estado          VARCHAR(20)   NOT NULL DEFAULT 'ACTIVO'
);
GO

-- ---------------------------------------------------------------------
-- Horario base (recurrente, por día de semana)
-- ---------------------------------------------------------------------
CREATE TABLE horario_base (
    id_horario_base INT IDENTITY(1,1) PRIMARY KEY,
    id_consultorio  INT NOT NULL,
    id_medico       INT NOT NULL,
    dia_semana      TINYINT      NOT NULL CHECK (dia_semana BETWEEN 1 AND 7), -- 1=Lunes ... 7=Domingo
    hora_inicio     TIME         NOT NULL,
    hora_fin        TIME         NOT NULL,
    estado          VARCHAR(20)  NOT NULL DEFAULT 'ACTIVO',
    CONSTRAINT fk_horario_consultorio FOREIGN KEY (id_consultorio) REFERENCES consultorios(id_consultorio),
    CONSTRAINT fk_horario_medico      FOREIGN KEY (id_medico)      REFERENCES medicos(id_medico),
    -- Evita que el mismo consultorio, día y hora de inicio se asigne dos veces
    CONSTRAINT uq_consultorio_dia_hora UNIQUE (id_consultorio, dia_semana, hora_inicio),
    CHECK (hora_fin > hora_inicio)
);
GO

-- ---------------------------------------------------------------------
-- Bloqueos (excepciones puntuales sobre el horario base)
-- ---------------------------------------------------------------------
CREATE TABLE bloqueos (
    id_bloqueo          INT IDENTITY(1,1) PRIMARY KEY,
    id_horario_base     INT NOT NULL,
    id_medico           INT NOT NULL,          -- médico titular que no asistirá
    id_medico_sustituto INT NULL,               -- médico que cubre, si aplica
    fecha               DATE          NOT NULL,
    tipo_bloqueo        VARCHAR(10)   NOT NULL CHECK (tipo_bloqueo IN ('COMPLETO','PARCIAL')),
    hora_inicio         TIME          NULL,     -- solo si es PARCIAL
    hora_fin            TIME          NULL,     -- solo si es PARCIAL
    motivo              NVARCHAR(200) NOT NULL,
    estado              VARCHAR(20)   NOT NULL DEFAULT 'REGISTRADO',
    fecha_registro      DATETIME      NOT NULL DEFAULT GETDATE(),
    CONSTRAINT fk_bloqueo_horario   FOREIGN KEY (id_horario_base)     REFERENCES horario_base(id_horario_base),
    CONSTRAINT fk_bloqueo_medico    FOREIGN KEY (id_medico)           REFERENCES medicos(id_medico),
    CONSTRAINT fk_bloqueo_sustituto FOREIGN KEY (id_medico_sustituto) REFERENCES medicos(id_medico)
);
GO

-- ---------------------------------------------------------------------
-- Notificaciones enviadas por cada bloqueo
-- ---------------------------------------------------------------------
CREATE TABLE notificaciones_bloqueo (
    id_notificacion INT IDENTITY(1,1) PRIMARY KEY,
    id_bloqueo      INT NOT NULL,
    destinatarios   NVARCHAR(MAX) NOT NULL,   -- lista de correos, separados por coma
    fecha_envio     DATETIME      NOT NULL DEFAULT GETDATE(),
    estado_envio    VARCHAR(20)   NOT NULL DEFAULT 'ENVIADO',
    CONSTRAINT fk_notificacion_bloqueo FOREIGN KEY (id_bloqueo) REFERENCES bloqueos(id_bloqueo)
);
GO

-- ---------------------------------------------------------------------
-- Datos de referencia mínimos (opcional, para pruebas)
-- ---------------------------------------------------------------------
-- INSERT INTO consultorios (codigo, ubicacion) VALUES ('C-01','Piso 1'), ('C-02','Piso 1');
-- INSERT INTO medicos (cmp, nombres, frecuencia_cita_min) VALUES ('12345','Dr. Juan Pérez',20);
