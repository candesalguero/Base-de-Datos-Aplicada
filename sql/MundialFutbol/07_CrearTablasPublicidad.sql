/*
    Universidad: Universidad de la Matanza
    Materia: Bases de Datos Aplicada
    Integrantes:
        - Salguero, Candela
        - Ocaranza, Lucila
        - Dimattia Damm, Malena
        - Fuentes, Martina Alejandra

    Objetivo:
    Crear las tablas del esquema publicidad.
*/

USE MundialFutbol;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = 'publicidad'
      AND TABLE_NAME = 'Anunciante'
)
BEGIN
    CREATE TABLE publicidad.Anunciante
    (
        id int IDENTITY(1,1) PRIMARY KEY,
        id_pais_origen int NOT NULL,
        tax_id varchar(30) NOT NULL UNIQUE,
        nombre_empresa varchar(150) NOT NULL,
        fecha_alta datetime2(0) NOT NULL DEFAULT (SYSDATETIME()),
        CONSTRAINT CK_Anunciante_TaxId
            CHECK (LEN(LTRIM(RTRIM(tax_id))) > 0),
        CONSTRAINT CK_Anunciante_Nombre
            CHECK (LEN(LTRIM(RTRIM(nombre_empresa))) > 0),
        CONSTRAINT FK_Anunciante_Pais
            FOREIGN KEY (id_pais_origen)
            REFERENCES general.Pais(id)
    );
END;
GO

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = 'publicidad'
      AND TABLE_NAME = 'Campana'
)
BEGIN
    CREATE TABLE publicidad.Campana
    (
        id int IDENTITY(1,1) PRIMARY KEY,
        id_anunciante int NOT NULL,
        id_moneda int NOT NULL,
        nombre varchar(120) NOT NULL,
        fecha_inicio date NOT NULL,
        fecha_fin date NOT NULL,
        presupuesto decimal(18,2) NOT NULL,
        fecha_alta datetime2(0) NOT NULL DEFAULT (SYSDATETIME()),
        CONSTRAINT CK_Campana_Nombre
            CHECK (LEN(LTRIM(RTRIM(nombre))) > 0),
        CONSTRAINT CK_Campana_Fechas
            CHECK (fecha_fin >= fecha_inicio),
        CONSTRAINT CK_Campana_Presupuesto
            CHECK (presupuesto >= 0),
        CONSTRAINT FK_Campana_Anunciante
            FOREIGN KEY (id_anunciante)
            REFERENCES publicidad.Anunciante(id),
        CONSTRAINT FK_Campana_Moneda
            FOREIGN KEY (id_moneda)
            REFERENCES general.Moneda(id)
    );
END;
GO

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = 'publicidad'
      AND TABLE_NAME = 'Tarifa'
)
BEGIN
    CREATE TABLE publicidad.Tarifa
    (
        id int IDENTITY(1,1) PRIMARY KEY,
        id_moneda int NOT NULL,
        nombre varchar(100) NOT NULL,
        costo_base decimal(18,2) NOT NULL,
        vigente_desde date NOT NULL,
        vigente_hasta date NULL,
        fecha_alta datetime2(0) NOT NULL DEFAULT (SYSDATETIME()),
        CONSTRAINT UQ_Tarifa_MonedaNombreVigencia
            UNIQUE (id_moneda, nombre, vigente_desde),
        CONSTRAINT CK_Tarifa_Nombre
            CHECK (LEN(LTRIM(RTRIM(nombre))) > 0),
        CONSTRAINT CK_Tarifa_Costo
            CHECK (costo_base >= 0),
        CONSTRAINT CK_Tarifa_Vigencia
            CHECK (vigente_hasta IS NULL OR vigente_hasta >= vigente_desde),
        CONSTRAINT FK_Tarifa_Moneda
            FOREIGN KEY (id_moneda)
            REFERENCES general.Moneda(id)
    );
END;
GO

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = 'publicidad'
      AND TABLE_NAME = 'PiezaDeContenido'
)
BEGIN
    CREATE TABLE publicidad.PiezaDeContenido
    (
        id int IDENTITY(1,1) PRIMARY KEY,
        id_campana int NOT NULL,
        id_tarifa int NOT NULL,
        id_idioma char(3) COLLATE Latin1_General_CS_AI NOT NULL,
        titulo varchar(150) NOT NULL,
        descripcion varchar(500) NULL,
        duracion int NOT NULL,
        fecha_alta datetime2(0) NOT NULL DEFAULT (SYSDATETIME()),
        CONSTRAINT UQ_PiezaDeContenido_CampanaTituloIdioma
            UNIQUE (id_campana, titulo, id_idioma),
        CONSTRAINT CK_PiezaDeContenido_Titulo
            CHECK (LEN(LTRIM(RTRIM(titulo))) > 0),
        CONSTRAINT CK_PiezaDeContenido_Duracion
            CHECK (duracion > 0),
        CONSTRAINT FK_PiezaDeContenido_Campana
            FOREIGN KEY (id_campana)
            REFERENCES publicidad.Campana(id),
        CONSTRAINT FK_PiezaDeContenido_Tarifa
            FOREIGN KEY (id_tarifa)
            REFERENCES publicidad.Tarifa(id),
        CONSTRAINT FK_PiezaDeContenido_Idioma
            FOREIGN KEY (id_idioma)
            REFERENCES general.Idioma(ISO639)
    );
END;
GO

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = 'publicidad'
      AND TABLE_NAME = 'EspacioPublicitario'
)
BEGIN
    CREATE TABLE publicidad.EspacioPublicitario
    (
        id int IDENTITY(1,1) PRIMARY KEY,
        ubicacion_panel varchar(30) NOT NULL UNIQUE,
        descripcion varchar(200) NULL,
        CONSTRAINT CK_EspacioPublicitario_Panel
            CHECK (ubicacion_panel IN ('Panel 1', 'Panel 2', 'Panel 3', 'Panel 4'))
    );
END;
GO

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = 'publicidad'
      AND TABLE_NAME = 'ExhibicionPublicitaria'
)
BEGIN
    CREATE TABLE publicidad.ExhibicionPublicitaria
    (
        id int IDENTITY(1,1) PRIMARY KEY,
        id_partido int NOT NULL,
        id_pieza int NOT NULL,
        id_espacio_publicitario int NOT NULL,
        id_moneda int NOT NULL,
        costo_aplicado decimal(18,2) NOT NULL,
        fue_prime_time bit NOT NULL DEFAULT (0),
        estado varchar(20) NOT NULL DEFAULT ('VIGENTE'),
        fecha_hora_registro datetime2(0) NOT NULL DEFAULT (SYSDATETIME()),
        fecha_anulacion datetime2(0) NULL,
        motivo_anulacion varchar(300) NULL,
        CONSTRAINT CK_ExhibicionPublicitaria_Estado
            CHECK (estado IN ('VIGENTE', 'ANULADA')),
        CONSTRAINT CK_ExhibicionPublicitaria_Costo
            CHECK (costo_aplicado >= 0),
        CONSTRAINT CK_ExhibicionPublicitaria_Anulacion
            CHECK (
                (estado = 'VIGENTE'
                    AND fecha_anulacion IS NULL
                    AND motivo_anulacion IS NULL)
                OR
                (estado = 'ANULADA'
                    AND fecha_anulacion IS NOT NULL
                    AND LEN(LTRIM(RTRIM(motivo_anulacion))) > 0)
            ),
        CONSTRAINT FK_ExhibicionPublicitaria_Pieza
            FOREIGN KEY (id_pieza)
            REFERENCES publicidad.PiezaDeContenido(id),
        CONSTRAINT FK_ExhibicionPublicitaria_Espacio
            FOREIGN KEY (id_espacio_publicitario)
            REFERENCES publicidad.EspacioPublicitario(id),
        CONSTRAINT FK_ExhibicionPublicitaria_Partido
            FOREIGN KEY (id_partido)
            REFERENCES deportivo.Partido(id),
        CONSTRAINT FK_ExhibicionPublicitaria_Moneda
            FOREIGN KEY (id_moneda)
            REFERENCES general.Moneda(id)
    );
END;
GO

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = 'publicidad'
      AND TABLE_NAME = 'PiezaDeMercadoDeInteres'
)
BEGIN
    CREATE TABLE publicidad.PiezaDeMercadoDeInteres
    (
        id_pieza int NOT NULL,
        id_pais int NOT NULL,
        fecha_alta datetime2(0) NOT NULL DEFAULT (SYSDATETIME()),
        CONSTRAINT PK_PiezaDeMercadoDeInteres
            PRIMARY KEY (id_pieza, id_pais),
        CONSTRAINT FK_PiezaDeMercadoDeInteres_Pieza
            FOREIGN KEY (id_pieza)
            REFERENCES publicidad.PiezaDeContenido(id),
        CONSTRAINT FK_PiezaDeMercadoDeInteres_Pais
            FOREIGN KEY (id_pais)
            REFERENCES general.Pais(id)
    );
END;
GO

IF NOT EXISTS (
    SELECT *
    FROM publicidad.EspacioPublicitario
    WHERE ubicacion_panel = 'Panel 1'
)
    INSERT INTO publicidad.EspacioPublicitario (ubicacion_panel, descripcion)
    VALUES ('Panel 1', 'Panel perimetral rotativo 1');
GO

IF NOT EXISTS (
    SELECT *
    FROM publicidad.EspacioPublicitario
    WHERE ubicacion_panel = 'Panel 2'
)
    INSERT INTO publicidad.EspacioPublicitario (ubicacion_panel, descripcion)
    VALUES ('Panel 2', 'Panel perimetral rotativo 2');
GO

IF NOT EXISTS (
    SELECT *
    FROM publicidad.EspacioPublicitario
    WHERE ubicacion_panel = 'Panel 3'
)
    INSERT INTO publicidad.EspacioPublicitario (ubicacion_panel, descripcion)
    VALUES ('Panel 3', 'Panel perimetral rotativo 3');
GO

IF NOT EXISTS (
    SELECT *
    FROM publicidad.EspacioPublicitario
    WHERE ubicacion_panel = 'Panel 4'
)
    INSERT INTO publicidad.EspacioPublicitario (ubicacion_panel, descripcion)
    VALUES ('Panel 4', 'Panel perimetral rotativo 4');
GO

IF NOT EXISTS (
    SELECT *
    FROM sys.indexes
    WHERE object_id = (
        SELECT t.object_id
        FROM sys.tables AS t
        INNER JOIN sys.schemas AS s ON s.schema_id = t.schema_id
        WHERE s.name = 'publicidad'
          AND t.name = 'ExhibicionPublicitaria'
    )
      AND name = 'UX_ExhibicionPublicitaria_PartidoEspacio_Vigente'
)
    CREATE UNIQUE INDEX UX_ExhibicionPublicitaria_PartidoEspacio_Vigente
        ON publicidad.ExhibicionPublicitaria (id_partido, id_espacio_publicitario)
        WHERE estado = 'VIGENTE';
GO

IF NOT EXISTS (
    SELECT *
    FROM sys.indexes
    WHERE object_id = (
        SELECT t.object_id
        FROM sys.tables AS t
        INNER JOIN sys.schemas AS s ON s.schema_id = t.schema_id
        WHERE s.name = 'publicidad'
          AND t.name = 'ExhibicionPublicitaria'
    )
      AND name = 'UX_ExhibicionPublicitaria_PartidoPieza_Vigente'
)
    CREATE UNIQUE INDEX UX_ExhibicionPublicitaria_PartidoPieza_Vigente
        ON publicidad.ExhibicionPublicitaria (id_partido, id_pieza)
        WHERE estado = 'VIGENTE';
GO
