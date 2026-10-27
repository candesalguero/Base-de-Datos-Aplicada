/*
    Universidad: Universidad de La Matanza
    Materia: Bases de Datos Aplicada
    Integrantes:
        - Salguero, Candela
        - Ocaranza, Lucila
        - Dimattia Damm, Malena
        - Fuentes, Martina Alejandra

    Objetivo:
    Crear las tablas pertencientes al esquema general
*/


USE MundialFutbol
GO

IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA='general'
AND TABLE_NAME='Confederacion')
BEGIN
    CREATE TABLE general.Confederacion(
        id int PRIMARY KEY,
        nombre varchar(100) not null
    )

END
GO

IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA='general'
AND TABLE_NAME='Pais')
BEGIN
    CREATE TABLE general.Pais (
        id int PRIMARY KEY,
        nombre varchar(100) not null,
        ISO2 char(2) COLLATE Latin1_General_CS_AI not null,
        huso_horario varchar(50) not null,
        id_confederacion int not null,
        CONSTRAINT fk_pais FOREIGN KEY (id_confederacion) REFERENCES general.Confederacion (id),
        CONSTRAINT ck_iso CHECK(ISO2 like '[A-Z][A-Z]') 
    )
END
GO

IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA='general'
AND TABLE_NAME='Idioma')
BEGIN
    CREATE TABLE general.Idioma(
        ISO639 char(3) COLLATE Latin1_General_CS_AI PRIMARY KEY,
        nombre varchar(50) not null,
        CONSTRAINT ck_iso639 CHECK(ISO639 like '[a-z][a-z][a-z]')
    )
END
GO

IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA='general'
AND TABLE_NAME='Moneda')
BEGIN
    CREATE TABLE general.Moneda(
        id int PRIMARY KEY ,
        cod_iso3 char(3) COLLATE Latin1_General_CS_AS not null,
        nombre varchar(30),
        CONSTRAINT ck_iso3 CHECK(cod_iso3 like'[A-Z][A-Z][A-Z]')
    )

END
GO

IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA='general'
AND TABLE_NAME='Fase')
BEGIN
    CREATE TABLE general.Fase(
        id int PRIMARY KEY,
        nombre varchar(30),
        orden int ,
        es_eliminacion_directa bit,
        CONSTRAINT ck_orden CHECK(orden>0)
    )
END
GO

IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA='general'
AND TABLE_NAME='Sede')
BEGIN
    CREATE TABLE general.Sede(
        id int PRIMARY KEY ,
        id_pais int not null,
        nombre_estadio nvarchar(50),
        ciudad nvarchar(50),
        capacidad int,
        huso_horario varchar(50) not null,
        CONSTRAINT fk_idpais FOREIGN KEY (id_pais) REFERENCES general.Pais(id)
    )
END
GO

IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA='general'
AND TABLE_NAME='IndicadorEconomico')
BEGIN
    CREATE TABLE general.IndicadorEconomico(
        anio smallint not null,
        id_pais int not null,
        pbi decimal(18,2) not null,
        fecha_actualizacion date not null,

         CONSTRAINT PK_IndicadorEconomico
        PRIMARY KEY (id_pais, anio),

    CONSTRAINT FK_IndicadorEconomico_Pais
        FOREIGN KEY (id_pais)
        REFERENCES general.Pais(id)
    )
END
GO
