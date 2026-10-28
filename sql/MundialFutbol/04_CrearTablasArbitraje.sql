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


IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = 'arbitraje'
      AND TABLE_NAME = 'DesignacionArbitral'
)
BEGIN
    CREATE TABLE arbitraje.DesignacionArbitral
    (
        id int PRIMARY KEY,
        id_partido int NOT NULL,
        id_arbitro int NOT NULL,
        id_rol_arbitral int NOT NULL,
        estado varchar(30) NOT NULL,
        motivo_descarte varchar(300) NULL,

        CONSTRAINT FK_DesignacionArbitral_Partido
            FOREIGN KEY (id_partido)
            REFERENCES deportivo.Partido(id),

        CONSTRAINT FK_DesignacionArbitral_Arbitro
            FOREIGN KEY (id_arbitro)
            REFERENCES arbitraje.Arbitro(id),

        CONSTRAINT FK_DesignacionArbitral_RolArbitral
            FOREIGN KEY (id_rol_arbitral)
            REFERENCES arbitraje.RolArbitral(id),

        CONSTRAINT UQ_DesignacionArbitral_PartidoArbitro
            UNIQUE (id_partido, id_arbitro)
    );
END;
GO


IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = 'arbitraje'
      AND TABLE_NAME = 'InformePostPartido'
)
BEGIN
    CREATE TABLE arbitraje.InformePostPartido
    (
        id int PRIMARY KEY,
        id_partido int NOT NULL,
        id_arbitro int NOT NULL,
        observaciones varchar(500) NULL,
        calificacion_desempeno float NULL,

        CONSTRAINT FK_InformePostPartido_Partido
            FOREIGN KEY (id_partido)
            REFERENCES deportivo.Partido(id),

        CONSTRAINT FK_InformePostPartido_Arbitro
            FOREIGN KEY (id_arbitro)
            REFERENCES arbitraje.Arbitro(id),

        CONSTRAINT UQ_InformePostPartido_PartidoArbitro
            UNIQUE (id_partido, id_arbitro)
    );
END;
GO


IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = 'arbitraje'
      AND TABLE_NAME = 'SancionArbitral'
)
BEGIN
    CREATE TABLE arbitraje.SancionArbitral
    (
        id int PRIMARY KEY,
        id_arbitro int NOT NULL,
        id_informe int NOT NULL,
        descripcion varchar(300) NOT NULL,
        motivo varchar(300) NOT NULL,
        cantidad_partidos_inhabilitados int NOT NULL,
        estado varchar(30) NOT NULL,

        CONSTRAINT CK_SancionArbitral_Cantidad
            CHECK (cantidad_partidos_inhabilitados > 0),

        CONSTRAINT FK_SancionArbitral_Arbitro
            FOREIGN KEY (id_arbitro)
            REFERENCES arbitraje.Arbitro(id),

        CONSTRAINT FK_SancionArbitral_Informe
            FOREIGN KEY (id_informe)
            REFERENCES arbitraje.InformePostPartido(id)
    );
END;
GO