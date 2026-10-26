/*
    Universidad: Universidad de La Matanza
    Materia: Bases de Datos Aplicada
    Integrantes:
        - Salguero, Candela
        - Ocaranza, Lucila
        - Dimattia Damm, Malena
        - Fuentes, Martina Alejandra

    Objetivo:
    Crear las tablas pertenecientes al esquema arbitraje.
*/

USE MundialFutbol;
GO


IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = 'arbitraje'
      AND TABLE_NAME = 'RolArbitral'
)
BEGIN
    CREATE TABLE arbitraje.RolArbitral
    (
        id      int PRIMARY KEY,
        nombre  varchar(50) NOT NULL
    );
END;
GO


IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = 'arbitraje'
      AND TABLE_NAME = 'Arbitro'
)
BEGIN
    CREATE TABLE arbitraje.Arbitro
    (
        id          int PRIMARY KEY,
        nombre      varchar(100) NOT NULL,
        apellido    varchar(100) NOT NULL,
        categoria   varchar(50) NOT NULL,
        id_pais     int NOT NULL,

        CONSTRAINT FK_Arbitro_Pais
            FOREIGN KEY (id_pais)
            REFERENCES general.Pais(id)
    );
END;
GO


IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = 'arbitraje'
      AND TABLE_NAME = 'ArbitroIdioma'
)
BEGIN
    CREATE TABLE arbitraje.ArbitroIdioma
    (
        id_arbitro   int NOT NULL,
        id_idioma char(3) COLLATE Latin1_General_CS_AI NOT NULL,

        CONSTRAINT PK_ArbitroIdioma
            PRIMARY KEY (id_arbitro, id_idioma),

        CONSTRAINT FK_ArbitroIdioma_Arbitro
            FOREIGN KEY (id_arbitro)
            REFERENCES arbitraje.Arbitro(id),

        CONSTRAINT FK_ArbitroIdioma_Idioma
            FOREIGN KEY (id_idioma)
            REFERENCES general.Idioma(ISO639)
    );
END;
GO