/*
    Universidad: Universidad de La Matanza
    Materia: Bases de Datos Aplicada
    Integrantes:
        - Salguero, Candela
        - Ocaranza, Lucila
        - Dimattia Damm, Malena
        - Fuentes, Martina Alejandra

    Fecha: Octubre 2026

    Objetivo:
    Crear las tablas pertenecientes al esquema deportivo.
*/

USE MundialFutbol;
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'deportivo' AND TABLE_NAME = 'Seleccion')
BEGIN
    CREATE TABLE deportivo.Seleccion (
        id int IDENTITY(1,1) PRIMARY KEY,
        id_pais int NOT NULL,
        nombre varchar(60) NOT NULL,
        grupo char(1) NOT NULL,
        CONSTRAINT CK_Seleccion_Grupo CHECK (grupo BETWEEN 'A' AND 'H'),
        CONSTRAINT FK_Seleccion_Pais FOREIGN KEY (id_pais) REFERENCES general.Pais(id)
    );
END;
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'deportivo' AND TABLE_NAME = 'Jugador')
BEGIN
    CREATE TABLE deportivo.Jugador (
        id int IDENTITY(1,1) PRIMARY KEY,
        id_pais_nacimiento int NOT NULL,
        nombre NVARCHAR(50) NOT NULL,
        apellido NVARCHAR(50) NOT NULL,
        fecha_nacimiento date NOT NULL,
        documento_identidad varchar(30) NOT NULL UNIQUE,
        CONSTRAINT FK_Jugador_Pais FOREIGN KEY (id_pais_nacimiento) REFERENCES general.Pais(id)
    );
END;
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'deportivo' AND TABLE_NAME = 'Convocatoria')
BEGIN
    CREATE TABLE deportivo.Convocatoria (
        id int IDENTITY(1,1) PRIMARY KEY,
        id_jugador int NOT NULL,
        id_seleccion int NOT NULL,
        dorsal tinyint NOT NULL,
        posicion_habitual varchar(25) NOT NULL,
        club_origen varchar(60) NOT NULL,
        CONSTRAINT UQ_Convocatoria_SeleccionDorsal UNIQUE (id_seleccion, dorsal),
        CONSTRAINT CK_Convocatoria_Dorsal CHECK (dorsal BETWEEN 1 AND 99),
        CONSTRAINT FK_Convocatoria_Jugador FOREIGN KEY (id_jugador) REFERENCES deportivo.Jugador(id),
        CONSTRAINT FK_Convocatoria_Seleccion FOREIGN KEY (id_seleccion) REFERENCES deportivo.Seleccion(id),
        CONSTRAINT CK_Convocatoria_PosicionHabitual CHECK (
            posicion_habitual IN ('Arquero', 'Defensor', 'Mediocampista', 'Delantero')
        )
    );
END;
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'deportivo' AND TABLE_NAME = 'AltaBajaConvocatoria')
BEGIN
    CREATE TABLE deportivo.AltaBajaConvocatoria (
        id int IDENTITY(1,1) PRIMARY KEY,
        id_convocatoria_sale int NOT NULL,
        id_jugador_entra int NOT NULL,
        fecha_hora datetime NOT NULL DEFAULT (SYSDATETIME()),
        motivo varchar(200) NOT NULL,
        CONSTRAINT FK_AltaBaja_ConvocatoriaSale FOREIGN KEY (id_convocatoria_sale) REFERENCES deportivo.Convocatoria(id),
        CONSTRAINT FK_AltaBaja_JugadorEntra FOREIGN KEY (id_jugador_entra) REFERENCES deportivo.Jugador(id)
    );
END;
GO

IF NOT EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA = 'deportivo' AND TABLE_NAME = 'RolCuerpoTecnico'
)
BEGIN
    CREATE TABLE deportivo.RolCuerpoTecnico (
        id int IDENTITY(1,1) PRIMARY KEY,
        descripcion_rol varchar(40) NOT NULL
    );
END;
GO

IF NOT EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA = 'deportivo' AND TABLE_NAME = 'MiembroCuerpoTecnico'
)
BEGIN
    CREATE TABLE deportivo.MiembroCuerpoTecnico (
        id int IDENTITY(1,1) PRIMARY KEY,
        id_seleccion int NOT NULL,
        id_rol_cuerpo_tecnico int NOT NULL,
        nombre nvarchar(50) NOT NULL,
        apellido nvarchar(50) NOT NULL,
        fecha_nacimiento date NULL,
        documento_identidad varchar(30) NOT NULL,
        
        CONSTRAINT FK_CuerpoTecnico_Seleccion 
            FOREIGN KEY (id_seleccion) REFERENCES deportivo.Seleccion(id),

        CONSTRAINT FK_CuerpoTecnico_Rol 
            FOREIGN KEY (id_rol_cuerpo_tecnico) REFERENCES deportivo.RolCuerpoTecnico(id)
    );
END;
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'deportivo' AND TABLE_NAME = 'Partido')
BEGIN
    CREATE TABLE deportivo.Partido (
        id int IDENTITY(1,1) PRIMARY KEY,
        id_sede int NOT NULL,
        id_fase int NOT NULL,
        id_seleccion_local int NOT NULL,
        id_seleccion_visitante int NOT NULL,
        fecha_hora_local datetime NOT NULL,
        fecha_hora_utc datetime NOT NULL,
        goles_local tinyint NULL,
        goles_visitante tinyint NULL,
        asistencia_publico int NULL,
        CONSTRAINT CK_Partido_EquiposDistintos CHECK (id_seleccion_local <> id_seleccion_visitante),
        CONSTRAINT FK_Partido_Sede FOREIGN KEY (id_sede) REFERENCES general.Sede(id),
        CONSTRAINT FK_Partido_Fase FOREIGN KEY (id_fase) REFERENCES general.Fase(id),
        CONSTRAINT FK_Partido_Local FOREIGN KEY (id_seleccion_local) REFERENCES deportivo.Seleccion(id),
        CONSTRAINT FK_Partido_Visitante FOREIGN KEY (id_seleccion_visitante) REFERENCES deportivo.Seleccion(id)
    );
END;
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'deportivo' AND TABLE_NAME = 'EsquemaTactico')
BEGIN
    CREATE TABLE deportivo.EsquemaTactico (
        id int IDENTITY(1,1) PRIMARY KEY,
        denominacion varchar(10) NOT NULL UNIQUE
    );
END;
GO

--en el der fueron modeladas como debiles, en la practica implicaria muchos joins y para evitar la propagación masiva de claves compuestas a la tabla Sustitucion
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'deportivo' AND TABLE_NAME = 'VentanaCambio')
BEGIN
    CREATE TABLE deportivo.VentanaCambio (
        id int IDENTITY(1,1) PRIMARY KEY,
        id_partido int NOT NULL,
        id_seleccion int NOT NULL,
        numero_ventana tinyint NOT NULL, -- 1, 2, 3 (o 4 en tiempo suplementario)
        minuto tinyint NOT NULL,
        periodo char(3) NOT NULL, -- '1T', '2T', '1TS', '2TS', 'ET' (Entretiempos no consumen ventana)
        CONSTRAINT UQ_VentanaCambio_PartidoSeleccionVentana UNIQUE (id_partido, id_seleccion, numero_ventana),
        CONSTRAINT FK_VentanaCambio_Partido FOREIGN KEY (id_partido) REFERENCES deportivo.Partido(id),
        CONSTRAINT FK_VentanaCambio_Seleccion FOREIGN KEY (id_seleccion) REFERENCES deportivo.Seleccion(id),
        CONSTRAINT CK_VentanaCambio_Periodo CHECK (periodo IN ('1T', '2T', '1TS', '2TS', 'ET')),
        CONSTRAINT CK_VentanaCambio_NumeroVentana CHECK (numero_ventana BETWEEN 1 AND 4)
    );
END;
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'deportivo' AND TABLE_NAME = 'Sustitucion')
BEGIN
    CREATE TABLE deportivo.Sustitucion (
        id int IDENTITY(1,1) PRIMARY KEY,
        id_ventana int NOT NULL,
        id_convocatoria_sale int NOT NULL,
        id_convocatoria_entra int NOT NULL,
        motivo_cambio varchar(50) NOT NULL, -- 'Táctico', 'Lesión', 'Precaución'
        CONSTRAINT CK_Sustitucion_Motivo CHECK (motivo_cambio IN ('Táctico', 'Lesión', 'Precaución')),
        CONSTRAINT FK_Sustitucion_Ventana FOREIGN KEY (id_ventana) REFERENCES deportivo.VentanaCambio(id),
        CONSTRAINT FK_Sustitucion_Sale FOREIGN KEY (id_convocatoria_sale) REFERENCES deportivo.Convocatoria(id),
        CONSTRAINT FK_Sustitucion_Entra FOREIGN KEY (id_convocatoria_entra) REFERENCES deportivo.Convocatoria(id)
    );
END;
GO
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'deportivo' AND TABLE_NAME = 'AlineacionPartido')
BEGIN
    CREATE TABLE deportivo.AlineacionPartido (
        id int IDENTITY(1,1) PRIMARY KEY,
        id_partido int NOT NULL,
        id_seleccion int NOT NULL,
        id_esquema int NOT NULL,
        CONSTRAINT UQ_Alineacion_PartidoSeleccion UNIQUE (id_partido, id_seleccion),
        CONSTRAINT FK_Alineacion_Partido FOREIGN KEY (id_partido) REFERENCES deportivo.Partido(id),
        CONSTRAINT FK_Alineacion_Seleccion FOREIGN KEY (id_seleccion) REFERENCES deportivo.Seleccion(id),
        CONSTRAINT FK_Alineacion_Esquema FOREIGN KEY (id_esquema) REFERENCES deportivo.EsquemaTactico(id)
    );
END;
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'deportivo' AND TABLE_NAME = 'AlineacionJugador')
BEGIN
    CREATE TABLE deportivo.AlineacionJugador (
        id_alineacion int NOT NULL,
        id_convocatoria int NOT NULL,
        es_titular bit NOT NULL,
        posicion_tactica_especifica varchar(25) NULL,
        CONSTRAINT PK_AlineacionJugador PRIMARY KEY (id_alineacion, id_convocatoria),
        CONSTRAINT FK_AlineacionJugador_Alineacion FOREIGN KEY (id_alineacion) REFERENCES deportivo.AlineacionPartido(id),
        CONSTRAINT FK_AlineacionJugador_Convocatoria FOREIGN KEY (id_convocatoria) REFERENCES deportivo.Convocatoria(id)
    );
END;
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'deportivo' AND TABLE_NAME = 'Gol')
BEGIN
    CREATE TABLE deportivo.Gol (
    id_gol INT IDENTITY(1,1) PRIMARY KEY,
    id_partido INT NOT NULL,
    id_convocatoria_autor INT NOT NULL,
    id_convocatoria_asistencia INT NULL, --puede ser NULL si es gol directo
    minuto TINYINT NOT NULL,
    minuto_adicional TINYINT NULL,
    periodo CHAR(3) NOT NULL, 
    es_en_contra BIT NOT NULL DEFAULT (0), -- cambie el tipo varchar por bit para que ocupe menos
    es_penal BIT NOT NULL DEFAULT (0),

    CONSTRAINT FK_Gol_Partido FOREIGN KEY (id_partido) 
        REFERENCES deportivo.Partido(id),
    CONSTRAINT FK_Gol_Autor FOREIGN KEY (id_convocatoria_autor) 
        REFERENCES deportivo.Convocatoria(id),
    CONSTRAINT FK_Gol_Asistencia FOREIGN KEY (id_convocatoria_asistencia) 
        REFERENCES deportivo.Convocatoria(id),
    CONSTRAINT CK_Gol_Periodo CHECK (periodo IN ('1T', '2T', '1TS', '2TS'))
);
END;
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'deportivo' AND TABLE_NAME = 'Tarjeta')
BEGIN
    CREATE TABLE deportivo.Tarjeta (
        id int IDENTITY(1,1) PRIMARY KEY,
        id_partido int NOT NULL,
        id_convocatoria int NULL,                -- NULL si la tarjeta fue para el cuerpo técnico
        id_miembro_cuerpo_tecnico int NULL,       -- NULL si la tarjeta fue para un jugador
        minuto tinyint NOT NULL,
        minuto_adicional tinyint NULL,
        periodo char(3) NOT NULL,
        color varchar(10) NOT NULL,
        es_roja_directa bit NOT NULL DEFAULT (0),
        motivo varchar(100) NOT NULL,
        id_tarjeta_origen int NULL,               -- Auto-referencia para encadenar 2da amarilla con 1ra amarilla

        CONSTRAINT CK_Tarjeta_Color 
            CHECK (color IN ('Amarilla', 'Roja')),

        CONSTRAINT CK_Tarjeta_Periodo 
            CHECK (periodo IN ('1T', '2T', '1TS', '2TS')),

        -- Restricción de exclusión mutua: O la tarjeta es para un convocado O es para el cuerpo técnico
        CONSTRAINT CK_Tarjeta_SujetoValido CHECK (
            (id_convocatoria IS NOT NULL AND id_miembro_cuerpo_tecnico IS NULL) OR
            (id_convocatoria IS NULL AND id_miembro_cuerpo_tecnico IS NOT NULL)
        ),

        CONSTRAINT FK_Tarjeta_Partido 
            FOREIGN KEY (id_partido) REFERENCES deportivo.Partido(id),

        CONSTRAINT FK_Tarjeta_Convocatoria 
            FOREIGN KEY (id_convocatoria) REFERENCES deportivo.Convocatoria(id),

        CONSTRAINT FK_Tarjeta_CuerpoTecnico 
            FOREIGN KEY (id_miembro_cuerpo_tecnico) REFERENCES deportivo.MiembroCuerpoTecnico(id),

        CONSTRAINT CK_Tarjeta_Minuto 
            CHECK (minuto BETWEEN 1 AND 120),

        CONSTRAINT CK_Tarjeta_MinutoAdicional 
            CHECK (minuto_adicional IS NULL OR minuto_adicional > 0)
    );
END;
GO

IF NOT EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA = 'deportivo' AND TABLE_NAME = 'Sancion'
)
BEGIN
    CREATE TABLE deportivo.Sancion (
        id int IDENTITY(1,1) PRIMARY KEY,
        id_convocatoria int NULL,                 -- Relación con Jugador
        id_miembro_cuerpo_tecnico int NULL,        -- Relación con Cuerpo Técnico
        id_partido_origen int NOT NULL,            -- Partido donde ocurrió el hecho/acumulación
        id_tarjeta int NULL,                       -- Opcional (NULL si fue por acumulación o tribunal)
        cantidad_partidos_sancion tinyint NOT NULL,
        motivo varchar(100) NOT NULL,
        estado varchar(20) NOT NULL DEFAULT ('Pendiente'),

        CONSTRAINT CK_Sancion_Estado 
            CHECK (estado IN ('Pendiente', 'En Cumplimiento', 'Cumplida')),

        CONSTRAINT CK_Sancion_Cantidad 
            CHECK (cantidad_partidos_sancion > 0),

        -- Restricción de Exclusión Mutua: O se sanciona a un convocado O a uno del cuerpo técnico
        CONSTRAINT CK_Sancion_SujetoValido CHECK (
            (id_convocatoria IS NOT NULL AND id_miembro_cuerpo_tecnico IS NULL) OR
            (id_convocatoria IS NULL AND id_miembro_cuerpo_tecnico IS NOT NULL)
        ),

        CONSTRAINT FK_Sancion_Convocatoria 
            FOREIGN KEY (id_convocatoria) REFERENCES deportivo.Convocatoria(id),

        CONSTRAINT FK_Sancion_CuerpoTecnico 
            FOREIGN KEY (id_miembro_cuerpo_tecnico) REFERENCES deportivo.MiembroCuerpoTecnico(id),

        CONSTRAINT FK_Sancion_PartidoOrigen 
            FOREIGN KEY (id_partido_origen) REFERENCES deportivo.Partido(id),

        CONSTRAINT FK_Sancion_Tarjeta 
            FOREIGN KEY (id_tarjeta) REFERENCES deportivo.Tarjeta(id)
    );
END;
GO