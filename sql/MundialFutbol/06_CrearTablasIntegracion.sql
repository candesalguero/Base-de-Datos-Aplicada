/*
    Universidad: Universidad de La Matanza
    Materia: Bases de Datos Aplicada
    Integrantes:
        - Salguero, Candela
        - Ocaranza, Lucila
        - Dimattia Damm, Malena
        - Fuentes, Martina Alejandra

    Objetivo:
    Crear las tablas pertenecientes al esquema integracion.
*/

USE MundialFutbol;
GO


IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = 'integracion'
      AND TABLE_NAME = 'FuenteDatos'
)
BEGIN
    CREATE TABLE integracion.FuenteDatos
    (
        id      int PRIMARY KEY,
        nombre  varchar(100) NOT NULL,
        tipo    varchar(30) NOT NULL,
        url     varchar(500) NULL
    );
END;
GO


IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = 'integracion'
      AND TABLE_NAME = 'LogImportacion'
)
BEGIN
    CREATE TABLE integracion.LogImportacion
    (
        id          int PRIMARY KEY,
        id_fuente   int NOT NULL,
        fecha       datetime NOT NULL,
        archivo     varchar(255) NOT NULL,
        resultado   varchar(100) NOT NULL,

        CONSTRAINT FK_LogImportacion_FuenteDatos
            FOREIGN KEY (id_fuente)
            REFERENCES integracion.FuenteDatos(id)
    );
END;
GO


IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = 'integracion'
      AND TABLE_NAME = 'DetalleErrorImportacion'
)
BEGIN
    CREATE TABLE integracion.DetalleErrorImportacion
    (
        id                   int PRIMARY KEY,
        id_log_importacion   int NOT NULL,
        fila                 int NOT NULL,
        error                varchar(500) NOT NULL,

        CONSTRAINT FK_DetalleErrorImportacion_LogImportacion
            FOREIGN KEY (id_log_importacion)
            REFERENCES integracion.LogImportacion(id),

        CONSTRAINT CK_DetalleErrorImportacion_Fila
            CHECK (fila > 0)
    );
END;
GO