/*
    Universidad: Universidad Nacional de La Matanza
    Materia: Bases de Datos Aplicada
    Integrantes:
        - Salguero, Candela
        - Ocaranza, Lucila
        - Dimattia Damm, Malena
        - Fuentes, Martina Alejandra

    Fecha: Noviembre 2026

    Objetivo:
        Entrega 7 - Script de poblamiento integral de datos representativos
        para alimentar todos los reportes del sistema MundialFutbol.
        Respeta árbitros y partidos previamente importados.
        Incluye complemento para cumplir mínimos: 16 selecciones con 23 convocados
        cada una y anunciantes con campañas de al menos 6 países.
*/

USE MundialFutbol;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

   
    PRINT '  1. POBLAMIENTO DE CATÁLOGOS BASE (ESQUEMA GENERAL)';

    -- 1.1 Confederaciones
    -- Se insertan solamente las faltantes y se generan IDs a partir del máximo actual.
    DECLARE @confederaciones TABLE
    (
        nombre varchar(100) PRIMARY KEY
    );

    INSERT INTO @confederaciones (nombre)
    VALUES
        ('CONMEBOL'),
        ('UEFA'),
        ('CONCACAF'),
        ('CAF'),
        ('AFC'),
        ('OFC');

    DECLARE @max_id_confederacion int = ISNULL((SELECT MAX(id) FROM general.Confederacion), 0);

    ;WITH Faltantes AS
    (
        SELECT
            c.nombre,
            ROW_NUMBER() OVER (ORDER BY c.nombre) AS nro
        FROM @confederaciones c
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM general.Confederacion existente
            WHERE UPPER(LTRIM(RTRIM(existente.nombre))) = UPPER(LTRIM(RTRIM(c.nombre)))
        )
    )
    INSERT INTO general.Confederacion (id, nombre)
    SELECT
        @max_id_confederacion + CAST(nro AS int),
        nombre
    FROM Faltantes;


    -- 1.2 Países (Participantes + Países de árbitros + Mercados de interés)
    -- La clave lógica utilizada para evitar duplicados es ISO2.
    DECLARE @paises TABLE
    (
        nombre varchar(100),
        ISO2 char(2),
        huso_horario varchar(50),
        confederacion varchar(100)
    );

    INSERT INTO @paises (nombre, ISO2, huso_horario, confederacion)
    VALUES
        ('Argentina',       'AR', 'UTC-3',  'CONMEBOL'),
        ('Brasil',          'BR', 'UTC-3',  'CONMEBOL'),
        ('Uruguay',         'UY', 'UTC-3',  'CONMEBOL'),
        ('Colombia',        'CO', 'UTC-5',  'CONMEBOL'),
        ('Francia',         'FR', 'UTC+1',  'UEFA'),
        ('España',          'ES', 'UTC+1',  'UEFA'),
        ('Alemania',        'DE', 'UTC+1',  'UEFA'),
        ('Inglaterra',      'GB', 'UTC+0',  'UEFA'),
        ('Italia',          'IT', 'UTC+1',  'UEFA'),
        ('Países Bajos',    'NL', 'UTC+1',  'UEFA'),
        ('Croacia',         'HR', 'UTC+1',  'UEFA'),
        ('Polonia',         'PL', 'UTC+1',  'UEFA'),
        ('Estados Unidos',  'US', 'UTC-5',  'CONCACAF'),
        ('México',          'MX', 'UTC-6',  'CONCACAF'),
        ('Canadá',          'CA', 'UTC-5',  'CONCACAF'),
        ('Marruecos',       'MA', 'UTC+1',  'CAF'),
        ('Senegal',         'SN', 'UTC+0',  'CAF'),
        ('Qatar',           'QA', 'UTC+3',  'AFC'),
        ('Japón',           'JP', 'UTC+9',  'AFC'),
        ('Corea del Sur',   'KR', 'UTC+9',  'AFC'),
        ('Australia',       'AU', 'UTC+10', 'AFC'),
        ('China',           'CN', 'UTC+8',  'AFC'),
        ('Bélgica',         'BE', 'UTC+1',  'UEFA'),
        ('Suecia',          'SE', 'UTC+1',  'UEFA'),
        ('Rusia',           'RU', 'UTC+3',  'UEFA'),
        ('Suiza',           'CH', 'UTC+1',  'UEFA'),
        ('Hungría',         'HU', 'UTC+1',  'UEFA'),
        ('Eslovenia',       'SI', 'UTC+1',  'UEFA');

    DECLARE @max_id_pais int = ISNULL((SELECT MAX(id) FROM general.Pais), 0);

    ;WITH Faltantes AS
    (
        SELECT
            p.nombre,
            p.ISO2,
            p.huso_horario,
            c.id AS id_confederacion,
            ROW_NUMBER() OVER (ORDER BY p.ISO2) AS nro
        FROM @paises p
        INNER JOIN general.Confederacion c
            ON UPPER(LTRIM(RTRIM(c.nombre))) = UPPER(LTRIM(RTRIM(p.confederacion)))
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM general.Pais existente
            WHERE existente.ISO2 = p.ISO2 COLLATE Latin1_General_CS_AI
        )
    )
    INSERT INTO general.Pais
    (
        id,
        nombre,
        ISO2,
        huso_horario,
        id_confederacion
    )
    SELECT
        @max_id_pais + CAST(nro AS int),
        nombre,
        ISO2,
        huso_horario,
        id_confederacion
    FROM Faltantes;


    -- 1.3 Idiomas (ISO639 en minúsculas según ck_iso639)
    INSERT INTO general.Idioma (ISO639, nombre)
    SELECT v.ISO639, v.nombre
    FROM (VALUES
        ('spa', 'Español'),
        ('eng', 'Inglés'),
        ('por', 'Portugués'),
        ('fra', 'Francés'),
        ('deu', 'Alemán'),
        ('ara', 'Árabe'),
        ('jpn', 'Japonés'),
        ('zho', 'Chino')
    ) AS v(ISO639, nombre)
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM general.Idioma i
        WHERE i.ISO639 = v.ISO639 COLLATE Latin1_General_CS_AI
    );


    -- 1.4 Monedas (ISO3 en mayúsculas según ck_iso3)
    DECLARE @monedas TABLE
    (
        cod_iso3 char(3),
        nombre varchar(100)
    );

    INSERT INTO @monedas (cod_iso3, nombre)
    VALUES
        ('USD', 'Dólar Estadounidense'),
        ('EUR', 'Euro'),
        ('ARS', 'Peso Argentino'),
        ('MXN', 'Peso Mexicano'),
        ('GBP', 'Libra Esterlina');

    DECLARE @max_id_moneda int = ISNULL((SELECT MAX(id) FROM general.Moneda), 0);

    ;WITH Faltantes AS
    (
        SELECT
            m.cod_iso3,
            m.nombre,
            ROW_NUMBER() OVER (ORDER BY m.cod_iso3) AS nro
        FROM @monedas m
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM general.Moneda existente
            WHERE existente.cod_iso3 = m.cod_iso3 COLLATE Latin1_General_CS_AS
        )
    )
    INSERT INTO general.Moneda (id, cod_iso3, nombre)
    SELECT
        @max_id_moneda + CAST(nro AS int),
        cod_iso3,
        nombre
    FROM Faltantes;

    DECLARE @id_usd int = (SELECT id FROM general.Moneda WHERE cod_iso3 = 'USD');
    DECLARE @id_eur int = (SELECT id FROM general.Moneda WHERE cod_iso3 = 'EUR');
    DECLARE @id_ars int = (SELECT id FROM general.Moneda WHERE cod_iso3 = 'ARS');
    DECLARE @id_mxn int = (SELECT id FROM general.Moneda WHERE cod_iso3 = 'MXN');
    DECLARE @id_gbp int = (SELECT id FROM general.Moneda WHERE cod_iso3 = 'GBP');


    -- 1.7 Fases del Torneo
    -- Se utilizan los nombres definidos por el modelo y luego se recuperan sus IDs reales.
    DECLARE @fases TABLE
    (
        nombre varchar(30),
        orden tinyint,
        es_eliminacion_directa bit
    );

    INSERT INTO @fases (nombre, orden, es_eliminacion_directa)
    VALUES
        ('grupos',        1, 0),
        ('dieciseisavos', 2, 1),
        ('octavos',       3, 1),
        ('cuartos',       4, 1),
        ('semifinales',   5, 1),
        ('tercer puesto', 6, 1),
        ('final',         7, 1);

    DECLARE @max_id_fase int = ISNULL((SELECT MAX(id) FROM general.Fase), 0);

    ;WITH Faltantes AS
    (
        SELECT
            f.nombre,
            f.orden,
            f.es_eliminacion_directa,
            ROW_NUMBER() OVER (ORDER BY f.orden) AS nro
        FROM @fases f
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM general.Fase existente
            WHERE LOWER(LTRIM(RTRIM(existente.nombre))) = LOWER(LTRIM(RTRIM(f.nombre)))
        )
    )
    INSERT INTO general.Fase (id, nombre, orden, es_eliminacion_directa)
    SELECT
        @max_id_fase + CAST(nro AS int),
        nombre,
        orden,
        es_eliminacion_directa
    FROM Faltantes;

    DECLARE @fase_grupos int =
        (SELECT TOP 1 id FROM general.Fase WHERE LOWER(LTRIM(RTRIM(nombre))) = 'grupos');
    DECLARE @fase_cuartos int =
        (SELECT TOP 1 id FROM general.Fase WHERE LOWER(LTRIM(RTRIM(nombre))) = 'cuartos');
    DECLARE @fase_semifinales int =
        (SELECT TOP 1 id FROM general.Fase WHERE LOWER(LTRIM(RTRIM(nombre))) = 'semifinales');
    DECLARE @fase_final int =
        (SELECT TOP 1 id FROM general.Fase WHERE LOWER(LTRIM(RTRIM(nombre))) = 'final');


    -- 1.8 Sedes (Estadios)
    DECLARE @sedes TABLE
    (
        pais_iso2 char(2),
        nombre_estadio nvarchar(50),
        ciudad nvarchar(50),
        capacidad int,
        huso_horario varchar(50)
    );

    INSERT INTO @sedes (pais_iso2, nombre_estadio, ciudad, capacidad, huso_horario)
    VALUES
        ('US', N'MetLife Stadium',   N'New Jersey',    82500, 'UTC-5'),
        ('US', N'SoFi Stadium',      N'Los Ángeles',   70240, 'UTC-8'),
        ('US', N'AT&T Stadium',      N'Dallas',        80000, 'UTC-6'),
        ('US', N'Hard Rock Stadium', N'Miami',         65326, 'UTC-5'),
        ('MX', N'Estadio Azteca',    N'Ciudad México', 87523, 'UTC-6'),
        ('CA', N'BMO Field',         N'Toronto',       45736, 'UTC-5'),
        ('QA', N'Lusail Stadium',    N'Lusail',        88966, 'UTC+3'),
        ('QA', N'Al Bayt Stadium',   N'Al Khor',       68895, 'UTC+3');

    DECLARE @max_id_sede int = ISNULL((SELECT MAX(id) FROM general.Sede), 0);

    ;WITH Faltantes AS
    (
        SELECT
            p.id AS id_pais,
            s.nombre_estadio,
            s.ciudad,
            s.capacidad,
            s.huso_horario,
            ROW_NUMBER() OVER (ORDER BY s.nombre_estadio) AS nro
        FROM @sedes s
        INNER JOIN general.Pais p
            ON p.ISO2 = s.pais_iso2 COLLATE Latin1_General_CS_AI
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM general.Sede existente
            WHERE UPPER(LTRIM(RTRIM(existente.nombre_estadio))) = UPPER(LTRIM(RTRIM(s.nombre_estadio)))
        )
    )
    INSERT INTO general.Sede
    (
        id,
        id_pais,
        nombre_estadio,
        ciudad,
        capacidad,
        huso_horario
    )
    SELECT
        @max_id_sede + CAST(nro AS int),
        id_pais,
        nombre_estadio,
        ciudad,
        capacidad,
        huso_horario
    FROM Faltantes;

    PRINT 'OK - Esquema general poblado.';

  
    PRINT '  2. POBLAMIENTO DE SELECCIONES, CUERPO TÉCNICO Y JUGADORES (DEPORTIVO)';

    -- 2.1 Esquemas Tácticos
    INSERT INTO deportivo.EsquemaTactico (denominacion)
    SELECT v.denom
    FROM (VALUES ('4-3-3'), ('4-2-3-1'), ('4-4-2'), ('3-5-2')) AS v(denom)
    WHERE NOT EXISTS (SELECT 1 FROM deportivo.EsquemaTactico WHERE denominacion = v.denom);

    -- 2.2 Roles Cuerpo Técnico
    INSERT INTO deportivo.RolCuerpoTecnico (descripcion_rol)
    SELECT v.rol
    FROM (VALUES ('Director Técnico'), ('Asistente Técnico'), ('Preparador Físico')) AS v(rol)
    WHERE NOT EXISTS (SELECT 1 FROM deportivo.RolCuerpoTecnico WHERE descripcion_rol = v.rol);

    -- 2.3 Selecciones (16 selecciones distribuidas en grupos A a G)
    INSERT INTO deportivo.Seleccion (id_pais, nombre, grupo)
    SELECT p.id, s.nombre, s.grupo
    FROM (VALUES
        ('US', 'Estados Unidos', 'A'),
        ('NL', 'Países Bajos',   'A'),
        ('GB', 'Inglaterra',     'B'),
        ('AR', 'Argentina',      'C'),
        ('MX', 'México',         'C'),
        ('PL', 'Polonia',        'C'),
        ('FR', 'Francia',        'D'),
        ('ES', 'España',         'E'),
        ('DE', 'Alemania',       'E'),
        ('JP', 'Japón',          'E'),
        ('MA', 'Marruecos',      'F'),
        ('BR', 'Brasil',         'G'),
        ('UY', 'Uruguay',        'G'),
        ('HR', 'Croacia',        'B'),
        ('KR', 'Corea del Sur',  'A'),
        ('SN', 'Senegal',        'F')
    ) AS s(iso2, nombre, grupo)
    INNER JOIN general.Pais p ON p.ISO2 = s.iso2 COLLATE Latin1_General_CS_AI
    WHERE NOT EXISTS (SELECT 1 FROM deportivo.Seleccion WHERE nombre = s.nombre);

    -- 2.4 Directores Técnicos por Selección
    DECLARE @id_rol_dt int = (SELECT TOP 1 id FROM deportivo.RolCuerpoTecnico WHERE descripcion_rol = 'Director Técnico');

    INSERT INTO deportivo.MiembroCuerpoTecnico (id_seleccion, id_rol_cuerpo_tecnico, nombre, apellido, fecha_nacimiento, documento_identidad)
    SELECT sel.id, @id_rol_dt, dt.nombre, dt.apellido, dt.fnac, dt.doc
    FROM (VALUES
        ('Argentina',      N'Lionel',    N'Scaloni',     '1978-05-16', 'DT-AR-001'),
        ('Francia',        N'Didier',    N'Deschamps',   '1968-10-15', 'DT-FR-001'),
        ('Brasil',         N'Dorival',   N'Júnior',      '1962-04-25', 'DT-BR-001'),
        ('España',         N'Luis',      N'de la Fuente','1961-06-21', 'DT-ES-001'),
        ('Inglaterra',     N'Thomas',    N'Tuchel',      '1973-08-29', 'DT-GB-001'),
        ('Alemania',       N'Julian',    N'Nagelsmann',  '1987-07-23', 'DT-DE-001'),
        ('Países Bajos',   N'Ronald',    N'Koeman',      '1963-03-21', 'DT-NL-001'),
        ('Marruecos',      N'Walid',     N'Regragui',    '1975-09-23', 'DT-MA-001'),
        ('Estados Unidos', N'Mauricio',  N'Pochettino',  '1972-03-02', 'DT-US-001'),
        ('México',         N'Javier',    N'Aguirre',     '1958-12-01', 'DT-MX-001'),
        ('Japón',          N'Hajime',    N'Moriyasu',    '1968-08-23', 'DT-JP-001'),
        ('Polonia',        N'Michał',    N'Probierz',    '1972-09-24', 'DT-PL-001'),
        ('Uruguay',        N'Marcelo',   N'Bielsa',      '1955-07-21', 'DT-UY-001'),
        ('Croacia',        N'Zlatko',    N'Dalić',       '1966-10-26', 'DT-HR-001'),
        ('Corea del Sur',  N'Hong',      N'Myung-bo',    '1969-02-12', 'DT-KR-001'),
        ('Senegal',        N'Pape',      N'Thiaw',       '1981-08-14', 'DT-SN-001')
    ) AS dt(sel_nombre, nombre, apellido, fnac, doc)
    INNER JOIN deportivo.Seleccion sel ON sel.nombre = dt.sel_nombre
    WHERE NOT EXISTS (SELECT 1 FROM deportivo.MiembroCuerpoTecnico WHERE documento_identidad = dt.doc);

    -- 2.5 Jugadores y Convocatorias (Plantel base representativo para reportes de goles y tarjetas)
    DECLARE @jugadores TABLE (
        sel_nombre varchar(60),
        iso2 char(2),
        nombre nvarchar(50),
        apellido nvarchar(50),
        fnac date,
        doc varchar(30),
        dorsal tinyint,
        pos varchar(25),
        club varchar(60)
    );

    INSERT INTO @jugadores VALUES
        -- Argentina
        ('Argentina', 'AR', N'Emiliano', N'Martínez',    '1992-09-02', 'JUG-AR-23', 23, 'Arquero',       'Aston Villa'),
        ('Argentina', 'AR', N'Cristian', N'Romero',      '1998-04-27', 'JUG-AR-13', 13, 'Defensor',      'Tottenham'),
        ('Argentina', 'AR', N'Nicolás',  N'Otamendi',    '1988-02-12', 'JUG-AR-19', 19, 'Defensor',      'Benfica'),
        ('Argentina', 'AR', N'Rodrigo',  N'De Paul',     '1994-05-24', 'JUG-AR-07',  7, 'Mediocampista', 'Atlético Madrid'),
        ('Argentina', 'AR', N'Alexis',   N'Mac Allister','1998-12-24', 'JUG-AR-20', 20, 'Mediocampista', 'Liverpool'),
        ('Argentina', 'AR', N'Enzo',     N'Fernández',   '2001-01-17', 'JUG-AR-24', 24, 'Mediocampista', 'Chelsea'),
        ('Argentina', 'AR', N'Lionel',   N'Messi',       '1987-06-24', 'JUG-AR-10', 10, 'Delantero',     'Inter Miami'),
        ('Argentina', 'AR', N'Julián',   N'Álvarez',     '2000-01-31', 'JUG-AR-09',  9, 'Delantero',     'Atlético Madrid'),
        ('Argentina', 'AR', N'Lautaro',  N'Martínez',    '1997-08-22', 'JUG-AR-22', 22, 'Delantero',     'Inter Milan'),
        -- Francia
        ('Francia', 'FR', N'Mike',       N'Maignan',     '1995-07-03', 'JUG-FR-16', 16, 'Arquero',       'AC Milan'),
        ('Francia', 'FR', N'William',    N'Saliba',      '2001-03-24', 'JUG-FR-17', 17, 'Defensor',      'Arsenal'),
        ('Francia', 'FR', N'Theo',       N'Hernández',   '1997-10-06', 'JUG-FR-22', 22, 'Defensor',      'AC Milan'),
        ('Francia', 'FR', N'Aurélien',   N'Tchouaméni',  '2000-01-27', 'JUG-FR-08',  8, 'Mediocampista', 'Real Madrid'),
        ('Francia', 'FR', N'Antoine',    N'Griezmann',   '1991-03-21', 'JUG-FR-07',  7, 'Mediocampista', 'Atlético Madrid'),
        ('Francia', 'FR', N'Kylian',     N'Mbappé',      '1998-12-20', 'JUG-FR-10', 10, 'Delantero',     'Real Madrid'),
        ('Francia', 'FR', N'Ousmane',    N'Dembélé',     '1997-05-15', 'JUG-FR-11', 11, 'Delantero',     'PSG'),
        -- Brasil
        ('Brasil', 'BR', N'Alisson',     N'Becker',      '1992-10-02', 'JUG-BR-01',  1, 'Arquero',       'Liverpool'),
        ('Brasil', 'BR', N'Éder',        N'Militão',     '1998-01-18', 'JUG-BR-03',  3, 'Defensor',      'Real Madrid'),
        ('Brasil', 'BR', N'Bruno',       N'Guimarães',   '1997-11-16', 'JUG-BR-05',  5, 'Mediocampista', 'Newcastle'),
        ('Brasil', 'BR', N'Vinícius',    N'Júnior',      '2000-07-12', 'JUG-BR-07',  7, 'Delantero',     'Real Madrid'),
        ('Brasil', 'BR', N'Rodrygo',     N'Goes',        '2001-01-09', 'JUG-BR-10', 10, 'Delantero',     'Real Madrid'),
        ('Brasil', 'BR', N'Raphinha',    N'Belloli',     '1996-12-14', 'JUG-BR-11', 11, 'Delantero',     'FC Barcelona'),
        -- España
        ('España', 'ES', N'Unai',        N'Simón',       '1997-06-11', 'JUG-ES-23', 23, 'Arquero',       'Athletic Club'),
        ('España', 'ES', N'Dani',        N'Carvajal',    '1992-01-11', 'JUG-ES-02',  2, 'Defensor',      'Real Madrid'),
        ('España', 'ES', N'Rodri',       N'Hernández',   '1996-06-22', 'JUG-ES-16', 16, 'Mediocampista', 'Manchester City'),
        ('España', 'ES', N'Dani',        N'Olmo',        '1998-05-07', 'JUG-ES-10', 10, 'Mediocampista', 'FC Barcelona'),
        ('España', 'ES', N'Lamine',      N'Yamal',       '2007-07-13', 'JUG-ES-19', 19, 'Delantero',     'FC Barcelona'),
        ('España', 'ES', N'Nico',        N'Williams',    '2002-07-12', 'JUG-ES-17', 17, 'Delantero',     'Athletic Club'),
        -- Inglaterra
        ('Inglaterra', 'GB', N'Jordan',  N'Pickford',    '1994-03-07', 'JUG-GB-01',  1, 'Arquero',       'Everton'),
        ('Inglaterra', 'GB', N'John',    N'Stones',      '1994-05-28', 'JUG-GB-05',  5, 'Defensor',      'Manchester City'),
        ('Inglaterra', 'GB', N'Jude',    N'Bellingham',  '2003-06-29', 'JUG-GB-10', 10, 'Mediocampista', 'Real Madrid'),
        ('Inglaterra', 'GB', N'Bukayo',  N'Saka',        '2001-09-05', 'JUG-GB-07',  7, 'Delantero',     'Arsenal'),
        ('Inglaterra', 'GB', N'Harry',   N'Kane',        '1993-07-28', 'JUG-GB-09',  9, 'Delantero',     'Bayern Múnich'),
        -- Alemania
        ('Alemania', 'DE', N'Manuel',    N'Neuer',       '1986-03-27', 'JUG-DE-01',  1, 'Arquero',       'Bayern Múnich'),
        ('Alemania', 'DE', N'Antonio',   N'Rüdiger',     '1993-03-03', 'JUG-DE-02',  2, 'Defensor',      'Real Madrid'),
        ('Alemania', 'DE', N'Jamal',     N'Musiala',     '2003-02-26', 'JUG-DE-10', 10, 'Mediocampista', 'Bayern Múnich'),
        ('Alemania', 'DE', N'Florian',   N'Wirtz',       '2003-05-03', 'JUG-DE-17', 17, 'Mediocampista', 'Bayer Leverkusen'),
        ('Alemania', 'DE', N'Kai',       N'Havertz',     '1999-06-11', 'JUG-DE-07',  7, 'Delantero',     'Arsenal'),
        -- Países Bajos
        ('Países Bajos', 'NL', N'Virgil',N'van Dijk',    '1991-07-08', 'JUG-NL-04',  4, 'Defensor',      'Liverpool'),
        ('Países Bajos', 'NL', N'Cody',  N'Gakpo',       '1999-05-07', 'JUG-NL-08',  8, 'Delantero',     'Liverpool'),
        ('Países Bajos', 'NL', N'Memphis',N'Depay',      '1994-02-13', 'JUG-NL-10', 10, 'Delantero',     'Corinthians'),
        -- Marruecos
        ('Marruecos', 'MA', N'Achraf',   N'Hakimi',      '1998-11-04', 'JUG-MA-02',  2, 'Defensor',      'PSG'),
        ('Marruecos', 'MA', N'Brahim',   N'Díaz',        '1999-08-03', 'JUG-MA-10', 10, 'Mediocampista', 'Real Madrid'),
        ('Marruecos', 'MA', N'Youssef',  N'En-Nesyri',   '1997-06-01', 'JUG-MA-19', 19, 'Delantero',     'Fenerbahçe'),
        -- Estados Unidos
        ('Estados Unidos', 'US', N'Christian', N'Pulisic','1998-09-18','JUG-US-10', 10, 'Delantero',     'AC Milan'),
        ('Estados Unidos', 'US', N'Weston',    N'McKennie','1998-08-28','JUG-US-08', 8, 'Mediocampista', 'Juventus'),
        -- México
        ('México', 'MX', N'Edson',       N'Álvarez',     '1997-10-24', 'JUG-MX-04',  4, 'Mediocampista', 'West Ham'),
        ('México', 'MX', N'Santiago',    N'Giménez',     '2001-04-18', 'JUG-MX-09',  9, 'Delantero',     'AC Milan'),
        -- Japón
        ('Japón', 'JP', N'Takefusa',     N'Kubo',        '2001-06-04', 'JUG-JP-20', 20, 'Mediocampista', 'Real Sociedad'),
        ('Japón', 'JP', N'Kaoru',        N'Mitoma',      '1997-05-20', 'JUG-JP-07',  7, 'Delantero',     'Brighton'),
        -- Polonia
        ('Polonia', 'PL', N'Robert',     N'Lewandowski', '1988-08-21', 'JUG-PL-09',  9, 'Delantero',     'FC Barcelona'),

        -- Argentina (complemento hasta 23 convocados)
        ('Argentina', 'AR', N'Franco', N'Armani', '1986-10-16', 'JUG-AR-01', 1, 'Arquero', 'River Plate'),
        ('Argentina', 'AR', N'Gerónimo', N'Rulli', '1992-05-20', 'JUG-AR-12', 12, 'Arquero', 'Villarreal'),
        ('Argentina', 'AR', N'Juan', N'Foyth', '1998-01-12', 'JUG-AR-02', 2, 'Defensor', 'Villarreal'),
        ('Argentina', 'AR', N'Nicolás', N'Tagliafico', '1992-08-31', 'JUG-AR-03', 3, 'Defensor', 'Olympique de Lyon'),
        ('Argentina', 'AR', N'Gonzalo', N'Montiel', '1997-01-01', 'JUG-AR-04', 4, 'Defensor', 'Sevilla'),
        ('Argentina', 'AR', N'Lisandro', N'Martínez', '1998-01-18', 'JUG-AR-25', 25, 'Defensor', 'Manchester United'),
        ('Argentina', 'AR', N'Nahuel', N'Molina', '1998-04-06', 'JUG-AR-26', 26, 'Defensor', 'Atlético Madrid'),
        ('Argentina', 'AR', N'Marcos', N'Acuña', '1991-10-28', 'JUG-AR-08', 8, 'Defensor', 'Sevilla'),
        ('Argentina', 'AR', N'Leandro', N'Paredes', '1994-06-29', 'JUG-AR-05', 5, 'Mediocampista', 'Juventus'),
        ('Argentina', 'AR', N'Exequiel', N'Palacios', '1998-10-05', 'JUG-AR-14', 14, 'Mediocampista', 'Bayer Leverkusen'),
        ('Argentina', 'AR', N'Alejandro', N'Gómez', '1988-02-15', 'JUG-AR-17', 17, 'Mediocampista', 'Sevilla'),
        ('Argentina', 'AR', N'Ángel', N'Di María', '1988-02-14', 'JUG-AR-11', 11, 'Delantero', 'Juventus'),
        ('Argentina', 'AR', N'Paulo', N'Dybala', '1993-11-15', 'JUG-AR-21', 21, 'Delantero', 'AS Roma'),
        ('Argentina', 'AR', N'Ángel', N'Correa', '1995-03-09', 'JUG-AR-15', 15, 'Delantero', 'Atlético Madrid'),
        -- Francia (complemento hasta 23 convocados)
        ('Francia', 'FR', N'Hugo', N'Lloris', '1986-12-26', 'JUG-FR-01', 1, 'Arquero', 'Tottenham'),
        ('Francia', 'FR', N'Steve', N'Mandanda', '1985-03-28', 'JUG-FR-23', 23, 'Arquero', 'Stade Rennais'),
        ('Francia', 'FR', N'Benjamin', N'Pavard', '1996-03-28', 'JUG-FR-02', 2, 'Defensor', 'Bayern Múnich'),
        ('Francia', 'FR', N'Jules', N'Koundé', '1998-11-12', 'JUG-FR-05', 5, 'Defensor', 'FC Barcelona'),
        ('Francia', 'FR', N'Raphaël', N'Varane', '1993-04-25', 'JUG-FR-04', 4, 'Defensor', 'Manchester United'),
        ('Francia', 'FR', N'Lucas', N'Hernández', '1996-02-14', 'JUG-FR-21', 21, 'Defensor', 'Bayern Múnich'),
        ('Francia', 'FR', N'Dayot', N'Upamecano', '1998-10-27', 'JUG-FR-18', 18, 'Defensor', 'Bayern Múnich'),
        ('Francia', 'FR', N'Ibrahima', N'Konaté', '1999-05-25', 'JUG-FR-24', 24, 'Defensor', 'Liverpool'),
        ('Francia', 'FR', N'Eduardo', N'Camavinga', '2002-11-10', 'JUG-FR-06', 6, 'Mediocampista', 'Real Madrid'),
        ('Francia', 'FR', N'Adrien', N'Rabiot', '1995-04-03', 'JUG-FR-14', 14, 'Mediocampista', 'Juventus'),
        ('Francia', 'FR', N'Jordan', N'Veretout', '1993-03-01', 'JUG-FR-25', 25, 'Mediocampista', 'Olympique de Marsella'),
        ('Francia', 'FR', N'N''Golo', N'Kanté', '1991-03-29', 'JUG-FR-13', 13, 'Mediocampista', 'Chelsea'),
        ('Francia', 'FR', N'Olivier', N'Giroud', '1986-09-30', 'JUG-FR-09', 9, 'Delantero', 'AC Milan'),
        ('Francia', 'FR', N'Kingsley', N'Coman', '1996-06-13', 'JUG-FR-20', 20, 'Delantero', 'Bayern Múnich'),
        ('Francia', 'FR', N'Randal', N'Kolo Muani', '1998-12-05', 'JUG-FR-12', 12, 'Delantero', 'Eintracht Frankfurt'),
        ('Francia', 'FR', N'Marcus', N'Thuram', '1997-08-06', 'JUG-FR-15', 15, 'Delantero', 'Borussia Mönchengladbach'),
        -- Brasil (complemento hasta 23 convocados)
        ('Brasil', 'BR', N'Ederson', N'Moraes', '1993-08-17', 'JUG-BR-23', 23, 'Arquero', 'Manchester City'),
        ('Brasil', 'BR', N'Weverton', N'Pereira', '1987-12-13', 'JUG-BR-12', 12, 'Arquero', 'Palmeiras'),
        ('Brasil', 'BR', N'Danilo', N'Luiz da Silva', '1991-07-15', 'JUG-BR-02', 2, 'Defensor', 'Juventus'),
        ('Brasil', 'BR', N'Alex', N'Sandro', '1991-01-26', 'JUG-BR-06', 6, 'Defensor', 'Juventus'),
        ('Brasil', 'BR', N'Marquinhos', N'Corrêa', '1994-05-14', 'JUG-BR-04', 4, 'Defensor', 'PSG'),
        ('Brasil', 'BR', N'Thiago', N'Silva', '1984-09-22', 'JUG-BR-13', 13, 'Defensor', 'Chelsea'),
        ('Brasil', 'BR', N'Gleison', N'Bremer', '1997-03-18', 'JUG-BR-14', 14, 'Defensor', 'Juventus'),
        ('Brasil', 'BR', N'Casemiro', N'Henrique', '1992-02-23', 'JUG-BR-18', 18, 'Mediocampista', 'Manchester United'),
        ('Brasil', 'BR', N'Fabinho', N'Tavares', '1993-10-23', 'JUG-BR-17', 17, 'Mediocampista', 'Liverpool'),
        ('Brasil', 'BR', N'Lucas', N'Paquetá', '1997-08-27', 'JUG-BR-08', 8, 'Mediocampista', 'Olympique de Lyon'),
        ('Brasil', 'BR', N'Fred', N'Rodrigues', '1993-03-05', 'JUG-BR-15', 15, 'Mediocampista', 'Manchester United'),
        ('Brasil', 'BR', N'Neymar', N'Júnior', '1992-02-05', 'JUG-BR-20', 20, 'Delantero', 'PSG'),
        ('Brasil', 'BR', N'Richarlison', N'de Andrade', '1997-05-10', 'JUG-BR-09', 9, 'Delantero', 'Tottenham'),
        ('Brasil', 'BR', N'Antony', N'Santos', '2000-02-24', 'JUG-BR-19', 19, 'Delantero', 'Manchester United'),
        ('Brasil', 'BR', N'Gabriel', N'Jesus', '1997-04-03', 'JUG-BR-21', 21, 'Delantero', 'Arsenal'),
        ('Brasil', 'BR', N'Gabriel', N'Martinelli', '2001-06-18', 'JUG-BR-22', 22, 'Delantero', 'Arsenal'),
        ('Brasil', 'BR', N'Pedro', N'Guilherme', '1997-06-20', 'JUG-BR-24', 24, 'Delantero', 'Flamengo'),
        -- España (complemento hasta 23 convocados)
        ('España', 'ES', N'David', N'Raya', '1995-09-15', 'JUG-ES-13', 13, 'Arquero', 'Brentford'),
        ('España', 'ES', N'Robert', N'Sánchez', '1997-11-18', 'JUG-ES-01', 1, 'Arquero', 'Brighton'),
        ('España', 'ES', N'César', N'Azpilicueta', '1989-08-28', 'JUG-ES-03', 3, 'Defensor', 'Chelsea'),
        ('España', 'ES', N'Eric', N'García', '2001-01-09', 'JUG-ES-04', 4, 'Defensor', 'FC Barcelona'),
        ('España', 'ES', N'Pau', N'Torres', '1997-01-16', 'JUG-ES-14', 14, 'Defensor', 'Villarreal'),
        ('España', 'ES', N'Jordi', N'Alba', '1989-03-21', 'JUG-ES-18', 18, 'Defensor', 'FC Barcelona'),
        ('España', 'ES', N'Aymeric', N'Laporte', '1994-05-27', 'JUG-ES-24', 24, 'Defensor', 'Manchester City'),
        ('España', 'ES', N'José', N'Gayà', '1995-05-25', 'JUG-ES-22', 22, 'Defensor', 'Valencia'),
        ('España', 'ES', N'Sergio', N'Busquets', '1988-07-16', 'JUG-ES-05', 5, 'Mediocampista', 'FC Barcelona'),
        ('España', 'ES', N'Pedri', N'González', '2002-11-25', 'JUG-ES-20', 20, 'Mediocampista', 'FC Barcelona'),
        ('España', 'ES', N'Gavi', N'Páez', '2004-08-05', 'JUG-ES-09', 9, 'Mediocampista', 'FC Barcelona'),
        ('España', 'ES', N'Koke', N'Resurrección', '1992-01-08', 'JUG-ES-08', 8, 'Mediocampista', 'Atlético Madrid'),
        ('España', 'ES', N'Carlos', N'Soler', '1997-01-02', 'JUG-ES-11', 11, 'Mediocampista', 'PSG'),
        ('España', 'ES', N'Álvaro', N'Morata', '1992-10-23', 'JUG-ES-07', 7, 'Delantero', 'Atlético Madrid'),
        ('España', 'ES', N'Ferran', N'Torres', '2000-02-29', 'JUG-ES-21', 21, 'Delantero', 'FC Barcelona'),
        ('España', 'ES', N'Marco', N'Asensio', '1996-01-21', 'JUG-ES-15', 15, 'Delantero', 'Real Madrid'),
        ('España', 'ES', N'Ansu', N'Fati', '2002-10-31', 'JUG-ES-25', 25, 'Delantero', 'FC Barcelona'),
        -- Inglaterra (complemento hasta 23 convocados)
        ('Inglaterra', 'GB', N'Aaron', N'Ramsdale', '1998-05-14', 'JUG-GB-13', 13, 'Arquero', 'Arsenal'),
        ('Inglaterra', 'GB', N'Nick', N'Pope', '1992-04-19', 'JUG-GB-22', 22, 'Arquero', 'Newcastle'),
        ('Inglaterra', 'GB', N'Kyle', N'Walker', '1990-05-28', 'JUG-GB-02', 2, 'Defensor', 'Manchester City'),
        ('Inglaterra', 'GB', N'Luke', N'Shaw', '1995-07-12', 'JUG-GB-03', 3, 'Defensor', 'Manchester United'),
        ('Inglaterra', 'GB', N'Harry', N'Maguire', '1993-03-05', 'JUG-GB-06', 6, 'Defensor', 'Manchester United'),
        ('Inglaterra', 'GB', N'Kieran', N'Trippier', '1990-09-19', 'JUG-GB-12', 12, 'Defensor', 'Newcastle'),
        ('Inglaterra', 'GB', N'Eric', N'Dier', '1994-01-15', 'JUG-GB-14', 14, 'Defensor', 'Tottenham'),
        ('Inglaterra', 'GB', N'Conor', N'Coady', '1993-02-25', 'JUG-GB-15', 15, 'Defensor', 'Wolverhampton'),
        ('Inglaterra', 'GB', N'Declan', N'Rice', '1999-01-14', 'JUG-GB-04', 4, 'Mediocampista', 'West Ham'),
        ('Inglaterra', 'GB', N'Jordan', N'Henderson', '1990-06-17', 'JUG-GB-08', 8, 'Mediocampista', 'Liverpool'),
        ('Inglaterra', 'GB', N'Kalvin', N'Phillips', '1995-12-02', 'JUG-GB-17', 17, 'Mediocampista', 'Manchester City'),
        ('Inglaterra', 'GB', N'Mason', N'Mount', '1999-01-10', 'JUG-GB-19', 19, 'Mediocampista', 'Chelsea'),
        ('Inglaterra', 'GB', N'Phil', N'Foden', '2000-05-28', 'JUG-GB-20', 20, 'Mediocampista', 'Manchester City'),
        ('Inglaterra', 'GB', N'James', N'Maddison', '1996-11-23', 'JUG-GB-18', 18, 'Mediocampista', 'Leicester City'),
        ('Inglaterra', 'GB', N'Marcus', N'Rashford', '1997-10-31', 'JUG-GB-11', 11, 'Delantero', 'Manchester United'),
        ('Inglaterra', 'GB', N'Raheem', N'Sterling', '1994-12-08', 'JUG-GB-24', 24, 'Delantero', 'Chelsea'),
        ('Inglaterra', 'GB', N'Jack', N'Grealish', '1995-09-10', 'JUG-GB-21', 21, 'Delantero', 'Manchester City'),
        ('Inglaterra', 'GB', N'Callum', N'Wilson', '1992-02-27', 'JUG-GB-25', 25, 'Delantero', 'Newcastle'),
        -- Alemania (complemento hasta 23 convocados)
        ('Alemania', 'DE', N'Marc-André', N'ter Stegen', '1992-04-30', 'JUG-DE-22', 22, 'Arquero', 'FC Barcelona'),
        ('Alemania', 'DE', N'Kevin', N'Trapp', '1990-07-08', 'JUG-DE-12', 12, 'Arquero', 'Eintracht Frankfurt'),
        ('Alemania', 'DE', N'Niklas', N'Süle', '1995-09-03', 'JUG-DE-15', 15, 'Defensor', 'Borussia Dortmund'),
        ('Alemania', 'DE', N'Matthias', N'Ginter', '1994-01-19', 'JUG-DE-04', 4, 'Defensor', 'SC Friburgo'),
        ('Alemania', 'DE', N'Nico', N'Schlotterbeck', '1999-12-01', 'JUG-DE-23', 23, 'Defensor', 'Borussia Dortmund'),
        ('Alemania', 'DE', N'David', N'Raum', '1998-04-22', 'JUG-DE-03', 3, 'Defensor', 'RB Leipzig'),
        ('Alemania', 'DE', N'Thilo', N'Kehrer', '1996-09-21', 'JUG-DE-05', 5, 'Defensor', 'West Ham'),
        ('Alemania', 'DE', N'Lukas', N'Klostermann', '1996-06-03', 'JUG-DE-16', 16, 'Defensor', 'RB Leipzig'),
        ('Alemania', 'DE', N'Joshua', N'Kimmich', '1995-02-08', 'JUG-DE-06', 6, 'Mediocampista', 'Bayern Múnich'),
        ('Alemania', 'DE', N'İlkay', N'Gündoğan', '1990-10-24', 'JUG-DE-21', 21, 'Mediocampista', 'Manchester City'),
        ('Alemania', 'DE', N'Leon', N'Goretzka', '1995-02-06', 'JUG-DE-08', 8, 'Mediocampista', 'Bayern Múnich'),
        ('Alemania', 'DE', N'Jonas', N'Hofmann', '1992-07-14', 'JUG-DE-18', 18, 'Mediocampista', 'Borussia Mönchengladbach'),
        ('Alemania', 'DE', N'Julian', N'Brandt', '1996-05-02', 'JUG-DE-14', 14, 'Mediocampista', 'Borussia Dortmund'),
        ('Alemania', 'DE', N'Thomas', N'Müller', '1989-09-13', 'JUG-DE-13', 13, 'Delantero', 'Bayern Múnich'),
        ('Alemania', 'DE', N'Serge', N'Gnabry', '1995-07-14', 'JUG-DE-20', 20, 'Delantero', 'Bayern Múnich'),
        ('Alemania', 'DE', N'Leroy', N'Sané', '1996-01-11', 'JUG-DE-19', 19, 'Delantero', 'Bayern Múnich'),
        ('Alemania', 'DE', N'Niclas', N'Füllkrug', '1993-02-09', 'JUG-DE-09', 9, 'Delantero', 'Werder Bremen'),
        ('Alemania', 'DE', N'Karim', N'Adeyemi', '2002-01-18', 'JUG-DE-11', 11, 'Delantero', 'Borussia Dortmund'),
        -- Países Bajos (complemento hasta 23 convocados)
        ('Países Bajos', 'NL', N'Andries', N'Noppert', '1994-04-07', 'JUG-NL-01', 1, 'Arquero', 'SC Heerenveen'),
        ('Países Bajos', 'NL', N'Justin', N'Bijlow', '1998-01-22', 'JUG-NL-13', 13, 'Arquero', 'Feyenoord'),
        ('Países Bajos', 'NL', N'Remko', N'Pasveer', '1983-11-08', 'JUG-NL-16', 16, 'Arquero', 'Ajax'),
        ('Países Bajos', 'NL', N'Denzel', N'Dumfries', '1996-04-18', 'JUG-NL-22', 22, 'Defensor', 'Inter Milan'),
        ('Países Bajos', 'NL', N'Matthijs', N'de Ligt', '1999-08-12', 'JUG-NL-03', 3, 'Defensor', 'Bayern Múnich'),
        ('Países Bajos', 'NL', N'Nathan', N'Aké', '1995-02-18', 'JUG-NL-05', 5, 'Defensor', 'Manchester City'),
        ('Países Bajos', 'NL', N'Jurriën', N'Timber', '2001-06-17', 'JUG-NL-02', 2, 'Defensor', 'Ajax'),
        ('Países Bajos', 'NL', N'Daley', N'Blind', '1990-03-09', 'JUG-NL-17', 17, 'Defensor', 'Ajax'),
        ('Países Bajos', 'NL', N'Stefan', N'de Vrij', '1992-02-05', 'JUG-NL-06', 6, 'Defensor', 'Inter Milan'),
        ('Países Bajos', 'NL', N'Tyrell', N'Malacia', '1999-08-17', 'JUG-NL-25', 25, 'Defensor', 'Manchester United'),
        ('Países Bajos', 'NL', N'Frenkie', N'de Jong', '1997-05-12', 'JUG-NL-21', 21, 'Mediocampista', 'FC Barcelona'),
        ('Países Bajos', 'NL', N'Marten', N'de Roon', '1991-03-29', 'JUG-NL-15', 15, 'Mediocampista', 'Atalanta'),
        ('Países Bajos', 'NL', N'Davy', N'Klaassen', '1993-02-21', 'JUG-NL-07', 7, 'Mediocampista', 'Ajax'),
        ('Países Bajos', 'NL', N'Steven', N'Berghuis', '1991-12-19', 'JUG-NL-23', 23, 'Mediocampista', 'Ajax'),
        ('Países Bajos', 'NL', N'Teun', N'Koopmeiners', '1998-02-28', 'JUG-NL-14', 14, 'Mediocampista', 'Atalanta'),
        ('Países Bajos', 'NL', N'Steven', N'Bergwijn', '1997-10-08', 'JUG-NL-20', 20, 'Delantero', 'Tottenham'),
        ('Países Bajos', 'NL', N'Wout', N'Weghorst', '1992-08-07', 'JUG-NL-09', 9, 'Delantero', 'Beşiktaş'),
        ('Países Bajos', 'NL', N'Luuk', N'de Jong', '1990-08-27', 'JUG-NL-19', 19, 'Delantero', 'PSV Eindhoven'),
        ('Países Bajos', 'NL', N'Jeremie', N'Frimpong', '2000-12-10', 'JUG-NL-12', 12, 'Delantero', 'Bayer Leverkusen'),
        ('Países Bajos', 'NL', N'Noa', N'Lang', '1999-06-17', 'JUG-NL-11', 11, 'Delantero', 'Club Brugge'),
        -- Marruecos (complemento hasta 23 convocados)
        ('Marruecos', 'MA', N'Yassine', N'Bounou', '1991-04-05', 'JUG-MA-01', 1, 'Arquero', 'Sevilla'),
        ('Marruecos', 'MA', N'Munir', N'Mohamedi', '1989-05-10', 'JUG-MA-12', 12, 'Arquero', 'Hatayspor'),
        ('Marruecos', 'MA', N'Ahmed Reda', N'Tagnaouti', '1996-04-05', 'JUG-MA-22', 22, 'Arquero', 'Wydad Casablanca'),
        ('Marruecos', 'MA', N'Noussair', N'Mazraoui', '1997-11-14', 'JUG-MA-03', 3, 'Defensor', 'Bayern Múnich'),
        ('Marruecos', 'MA', N'Nayef', N'Aguerd', '1996-03-30', 'JUG-MA-05', 5, 'Defensor', 'West Ham'),
        ('Marruecos', 'MA', N'Romain', N'Saïss', '1990-03-26', 'JUG-MA-06', 6, 'Defensor', 'Wolverhampton'),
        ('Marruecos', 'MA', N'Jawad', N'El Yamiq', '1992-02-29', 'JUG-MA-18', 18, 'Defensor', 'Real Valladolid'),
        ('Marruecos', 'MA', N'Yahya', N'Attiat-Allah', '1995-03-02', 'JUG-MA-25', 25, 'Defensor', 'Wydad Casablanca'),
        ('Marruecos', 'MA', N'Achraf', N'Dari', '1999-05-06', 'JUG-MA-16', 16, 'Defensor', 'Stade Brestois'),
        ('Marruecos', 'MA', N'Sofyan', N'Amrabat', '1996-08-21', 'JUG-MA-04', 4, 'Mediocampista', 'Fiorentina'),
        ('Marruecos', 'MA', N'Azzedine', N'Ounahi', '2000-04-19', 'JUG-MA-08', 8, 'Mediocampista', 'Angers'),
        ('Marruecos', 'MA', N'Selim', N'Amallah', '1996-11-15', 'JUG-MA-15', 15, 'Mediocampista', 'Standard Lieja'),
        ('Marruecos', 'MA', N'Abdelhamid', N'Sabiri', '1996-11-28', 'JUG-MA-14', 14, 'Mediocampista', 'Sampdoria'),
        ('Marruecos', 'MA', N'Hakim', N'Ziyech', '1993-03-19', 'JUG-MA-07', 7, 'Mediocampista', 'Chelsea'),
        ('Marruecos', 'MA', N'Sofiane', N'Boufal', '1993-09-17', 'JUG-MA-17', 17, 'Delantero', 'Angers'),
        ('Marruecos', 'MA', N'Zakaria', N'Aboukhlal', '2000-02-18', 'JUG-MA-13', 13, 'Delantero', 'Toulouse'),
        ('Marruecos', 'MA', N'Abde', N'Ezzalzouli', '2001-12-17', 'JUG-MA-21', 21, 'Delantero', 'Osasuna'),
        ('Marruecos', 'MA', N'Walid', N'Cheddira', '1998-01-22', 'JUG-MA-09', 9, 'Delantero', 'Bari'),
        ('Marruecos', 'MA', N'Ayoub', N'El Kaabi', '1993-06-25', 'JUG-MA-20', 20, 'Delantero', 'Wydad Casablanca'),
        ('Marruecos', 'MA', N'Anass', N'Zaroury', '2000-11-07', 'JUG-MA-11', 11, 'Delantero', 'Burnley'),
        -- Estados Unidos (complemento hasta 23 convocados)
        ('Estados Unidos', 'US', N'Matt', N'Turner', '1994-06-24', 'JUG-US-01', 1, 'Arquero', 'Arsenal'),
        ('Estados Unidos', 'US', N'Ethan', N'Horvath', '1995-06-09', 'JUG-US-12', 12, 'Arquero', 'Nottingham Forest'),
        ('Estados Unidos', 'US', N'Sean', N'Johnson', '1989-05-31', 'JUG-US-24', 24, 'Arquero', 'Toronto FC'),
        ('Estados Unidos', 'US', N'Sergiño', N'Dest', '2000-11-03', 'JUG-US-02', 2, 'Defensor', 'FC Barcelona'),
        ('Estados Unidos', 'US', N'Antonee', N'Robinson', '1997-08-08', 'JUG-US-05', 5, 'Defensor', 'Fulham'),
        ('Estados Unidos', 'US', N'Tim', N'Ream', '1987-10-05', 'JUG-US-13', 13, 'Defensor', 'Fulham'),
        ('Estados Unidos', 'US', N'Cameron', N'Carter-Vickers', '1997-12-31', 'JUG-US-20', 20, 'Defensor', 'Celtic'),
        ('Estados Unidos', 'US', N'Walker', N'Zimmerman', '1993-05-19', 'JUG-US-03', 3, 'Defensor', 'Nashville SC'),
        ('Estados Unidos', 'US', N'Shaq', N'Moore', '1996-11-02', 'JUG-US-15', 15, 'Defensor', 'Nashville SC'),
        ('Estados Unidos', 'US', N'DeAndre', N'Yedlin', '1993-07-09', 'JUG-US-22', 22, 'Defensor', 'FC Cincinnati'),
        ('Estados Unidos', 'US', N'Joe', N'Scally', '2002-12-31', 'JUG-US-25', 25, 'Defensor', 'Borussia Mönchengladbach'),
        ('Estados Unidos', 'US', N'Tyler', N'Adams', '1999-02-14', 'JUG-US-04', 4, 'Mediocampista', 'Leeds United'),
        ('Estados Unidos', 'US', N'Yunus', N'Musah', '2002-11-29', 'JUG-US-06', 6, 'Mediocampista', 'Valencia'),
        ('Estados Unidos', 'US', N'Brenden', N'Aaronson', '2000-10-22', 'JUG-US-11', 11, 'Mediocampista', 'Leeds United'),
        ('Estados Unidos', 'US', N'Luca', N'de la Torre', '1998-05-23', 'JUG-US-14', 14, 'Mediocampista', 'Celta de Vigo'),
        ('Estados Unidos', 'US', N'Kellyn', N'Acosta', '1995-07-24', 'JUG-US-23', 23, 'Mediocampista', 'Los Angeles FC'),
        ('Estados Unidos', 'US', N'Cristian', N'Roldan', '1995-06-03', 'JUG-US-16', 16, 'Mediocampista', 'Seattle Sounders'),
        ('Estados Unidos', 'US', N'Giovanni', N'Reyna', '2002-11-13', 'JUG-US-07', 7, 'Delantero', 'Borussia Dortmund'),
        ('Estados Unidos', 'US', N'Timothy', N'Weah', '2000-02-22', 'JUG-US-21', 21, 'Delantero', 'Lille'),
        ('Estados Unidos', 'US', N'Josh', N'Sargent', '2000-02-20', 'JUG-US-09', 9, 'Delantero', 'Norwich City'),
        ('Estados Unidos', 'US', N'Haji', N'Wright', '1998-03-27', 'JUG-US-18', 18, 'Delantero', 'Antalyaspor'),
        -- México (complemento hasta 23 convocados)
        ('México', 'MX', N'Guillermo', N'Ochoa', '1985-07-13', 'JUG-MX-13', 13, 'Arquero', 'Club América'),
        ('México', 'MX', N'Alfredo', N'Talavera', '1982-09-18', 'JUG-MX-01', 1, 'Arquero', 'Pumas UNAM'),
        ('México', 'MX', N'Rodolfo', N'Cota', '1987-07-03', 'JUG-MX-12', 12, 'Arquero', 'Club León'),
        ('México', 'MX', N'Jorge', N'Sánchez', '1997-12-10', 'JUG-MX-02', 2, 'Defensor', 'Ajax'),
        ('México', 'MX', N'César', N'Montes', '1997-02-24', 'JUG-MX-03', 3, 'Defensor', 'Espanyol'),
        ('México', 'MX', N'Héctor', N'Moreno', '1988-01-17', 'JUG-MX-15', 15, 'Defensor', 'Monterrey'),
        ('México', 'MX', N'Johan', N'Vásquez', '1998-10-22', 'JUG-MX-05', 5, 'Defensor', 'Genoa'),
        ('México', 'MX', N'Jesús', N'Gallardo', '1994-08-15', 'JUG-MX-23', 23, 'Defensor', 'Monterrey'),
        ('México', 'MX', N'Kevin', N'Álvarez', '1999-01-15', 'JUG-MX-26', 26, 'Defensor', 'Pachuca'),
        ('México', 'MX', N'Luis', N'Chávez', '1996-01-15', 'JUG-MX-24', 24, 'Mediocampista', 'Pachuca'),
        ('México', 'MX', N'Héctor', N'Herrera', '1990-04-19', 'JUG-MX-16', 16, 'Mediocampista', 'Atlético Madrid'),
        ('México', 'MX', N'Orbelín', N'Pineda', '1996-03-24', 'JUG-MX-17', 17, 'Mediocampista', 'AEK Atenas'),
        ('México', 'MX', N'Luis', N'Romo', '1995-06-05', 'JUG-MX-07', 7, 'Mediocampista', 'Monterrey'),
        ('México', 'MX', N'Erick', N'Gutiérrez', '1995-06-15', 'JUG-MX-18', 18, 'Mediocampista', 'PSV Eindhoven'),
        ('México', 'MX', N'Carlos', N'Rodríguez', '1997-01-03', 'JUG-MX-06', 6, 'Mediocampista', 'Cruz Azul'),
        ('México', 'MX', N'Roberto', N'Alvarado', '1998-09-07', 'JUG-MX-25', 25, 'Mediocampista', 'Chivas'),
        ('México', 'MX', N'Hirving', N'Lozano', '1995-07-30', 'JUG-MX-22', 22, 'Delantero', 'Napoli'),
        ('México', 'MX', N'Raúl', N'Jiménez', '1991-05-05', 'JUG-MX-19', 19, 'Delantero', 'Wolverhampton'),
        ('México', 'MX', N'Alexis', N'Vega', '1997-11-25', 'JUG-MX-10', 10, 'Delantero', 'Chivas'),
        ('México', 'MX', N'Henry', N'Martín', '1992-11-18', 'JUG-MX-20', 20, 'Delantero', 'Club América'),
        ('México', 'MX', N'Uriel', N'Antuna', '1997-08-21', 'JUG-MX-21', 21, 'Delantero', 'Cruz Azul'),
        -- Japón (complemento hasta 23 convocados)
        ('Japón', 'JP', N'Shuichi', N'Gonda', '1989-03-03', 'JUG-JP-12', 12, 'Arquero', 'Shimizu S-Pulse'),
        ('Japón', 'JP', N'Daniel', N'Schmidt', '1992-02-03', 'JUG-JP-01', 1, 'Arquero', 'Sint-Truiden'),
        ('Japón', 'JP', N'Eiji', N'Kawashima', '1983-03-20', 'JUG-JP-23', 23, 'Arquero', 'Strasbourg'),
        ('Japón', 'JP', N'Maya', N'Yoshida', '1988-08-24', 'JUG-JP-03', 3, 'Defensor', 'Schalke 04'),
        ('Japón', 'JP', N'Takehiro', N'Tomiyasu', '1998-11-05', 'JUG-JP-22', 22, 'Defensor', 'Arsenal'),
        ('Japón', 'JP', N'Hiroki', N'Sakai', '1990-04-12', 'JUG-JP-19', 19, 'Defensor', 'Urawa Reds'),
        ('Japón', 'JP', N'Ko', N'Itakura', '1997-01-27', 'JUG-JP-04', 4, 'Defensor', 'Borussia Mönchengladbach'),
        ('Japón', 'JP', N'Yuto', N'Nagatomo', '1986-09-12', 'JUG-JP-05', 5, 'Defensor', 'FC Tokyo'),
        ('Japón', 'JP', N'Miki', N'Yamane', '1993-12-22', 'JUG-JP-02', 2, 'Defensor', 'Kawasaki Frontale'),
        ('Japón', 'JP', N'Hiroki', N'Ito', '1999-05-12', 'JUG-JP-21', 21, 'Defensor', 'VfB Stuttgart'),
        ('Japón', 'JP', N'Shogo', N'Taniguchi', '1991-07-15', 'JUG-JP-16', 16, 'Defensor', 'Kawasaki Frontale'),
        ('Japón', 'JP', N'Wataru', N'Endo', '1993-02-09', 'JUG-JP-06', 6, 'Mediocampista', 'VfB Stuttgart'),
        ('Japón', 'JP', N'Hidemasa', N'Morita', '1995-05-10', 'JUG-JP-13', 13, 'Mediocampista', 'Sporting CP'),
        ('Japón', 'JP', N'Ao', N'Tanaka', '1998-09-10', 'JUG-JP-17', 17, 'Mediocampista', 'Fortuna Düsseldorf'),
        ('Japón', 'JP', N'Daichi', N'Kamada', '1996-08-05', 'JUG-JP-15', 15, 'Mediocampista', 'Eintracht Frankfurt'),
        ('Japón', 'JP', N'Takumi', N'Minamino', '1995-01-16', 'JUG-JP-10', 10, 'Mediocampista', 'AS Monaco'),
        ('Japón', 'JP', N'Takuma', N'Asano', '1994-11-10', 'JUG-JP-18', 18, 'Delantero', 'VfL Bochum'),
        ('Japón', 'JP', N'Daizen', N'Maeda', '1997-10-20', 'JUG-JP-25', 25, 'Delantero', 'Celtic'),
        ('Japón', 'JP', N'Ayase', N'Ueda', '1998-08-28', 'JUG-JP-09', 9, 'Delantero', 'Cercle Brugge'),
        ('Japón', 'JP', N'Ritsu', N'Doan', '1998-06-16', 'JUG-JP-08', 8, 'Delantero', 'SC Friburgo'),
        ('Japón', 'JP', N'Junya', N'Ito', '1993-03-09', 'JUG-JP-14', 14, 'Delantero', 'Stade de Reims'),
        -- Polonia (complemento hasta 23 convocados)
        ('Polonia', 'PL', N'Wojciech', N'Szczęsny', '1990-04-18', 'JUG-PL-01', 1, 'Arquero', 'Juventus'),
        ('Polonia', 'PL', N'Łukasz', N'Skorupski', '1991-05-05', 'JUG-PL-12', 12, 'Arquero', 'Bologna'),
        ('Polonia', 'PL', N'Bartłomiej', N'Drągowski', '1997-08-19', 'JUG-PL-22', 22, 'Arquero', 'Spezia'),
        ('Polonia', 'PL', N'Jan', N'Bednarek', '1996-04-12', 'JUG-PL-05', 5, 'Defensor', 'Southampton'),
        ('Polonia', 'PL', N'Kamil', N'Glik', '1988-02-03', 'JUG-PL-15', 15, 'Defensor', 'Benevento'),
        ('Polonia', 'PL', N'Matty', N'Cash', '1997-08-07', 'JUG-PL-02', 2, 'Defensor', 'Aston Villa'),
        ('Polonia', 'PL', N'Jakub', N'Kiwior', '2000-02-15', 'JUG-PL-14', 14, 'Defensor', 'Spezia'),
        ('Polonia', 'PL', N'Artur', N'Jędrzejczyk', '1987-11-04', 'JUG-PL-03', 3, 'Defensor', 'Legia Varsovia'),
        ('Polonia', 'PL', N'Bartosz', N'Bereszyński', '1992-07-12', 'JUG-PL-18', 18, 'Defensor', 'Sampdoria'),
        ('Polonia', 'PL', N'Nicola', N'Zalewski', '2002-01-23', 'JUG-PL-21', 21, 'Defensor', 'AS Roma'),
        ('Polonia', 'PL', N'Piotr', N'Zieliński', '1994-05-20', 'JUG-PL-20', 20, 'Mediocampista', 'Napoli'),
        ('Polonia', 'PL', N'Sebastian', N'Szymański', '1999-05-10', 'JUG-PL-25', 25, 'Mediocampista', 'Feyenoord'),
        ('Polonia', 'PL', N'Grzegorz', N'Krychowiak', '1990-01-29', 'JUG-PL-10', 10, 'Mediocampista', 'Al-Shabab'),
        ('Polonia', 'PL', N'Jakub', N'Moder', '1999-04-07', 'JUG-PL-08', 8, 'Mediocampista', 'Brighton'),
        ('Polonia', 'PL', N'Szymon', N'Żurkowski', '1997-09-25', 'JUG-PL-06', 6, 'Mediocampista', 'Empoli'),
        ('Polonia', 'PL', N'Mateusz', N'Klich', '1990-06-13', 'JUG-PL-16', 16, 'Mediocampista', 'Leeds United'),
        ('Polonia', 'PL', N'Damian', N'Szymański', '1995-06-16', 'JUG-PL-13', 13, 'Mediocampista', 'AEK Atenas'),
        ('Polonia', 'PL', N'Przemysław', N'Frankowski', '1995-04-12', 'JUG-PL-26', 26, 'Mediocampista', 'Lens'),
        ('Polonia', 'PL', N'Krzysztof', N'Piątek', '1995-07-01', 'JUG-PL-11', 11, 'Delantero', 'Salernitana'),
        ('Polonia', 'PL', N'Arkadiusz', N'Milik', '1994-02-28', 'JUG-PL-07', 7, 'Delantero', 'Juventus'),
        ('Polonia', 'PL', N'Karol', N'Świderski', '1997-01-23', 'JUG-PL-19', 19, 'Delantero', 'Charlotte FC'),
        ('Polonia', 'PL', N'Kamil', N'Grosicki', '1988-06-08', 'JUG-PL-24', 24, 'Delantero', 'Pogoń Szczecin'),
        -- Uruguay (complemento hasta 23 convocados)
        ('Uruguay', 'UY', N'Sergio', N'Rochet', '1993-03-23', 'JUG-UY-01', 1, 'Arquero', 'Nacional'),
        ('Uruguay', 'UY', N'Fernando', N'Muslera', '1986-06-16', 'JUG-UY-23', 23, 'Arquero', 'Galatasaray'),
        ('Uruguay', 'UY', N'Sebastián', N'Sosa', '1986-08-19', 'JUG-UY-12', 12, 'Arquero', 'Independiente'),
        ('Uruguay', 'UY', N'José María', N'Giménez', '1995-01-20', 'JUG-UY-02', 2, 'Defensor', 'Atlético Madrid'),
        ('Uruguay', 'UY', N'Diego', N'Godín', '1986-02-16', 'JUG-UY-03', 3, 'Defensor', 'Vélez Sarsfield'),
        ('Uruguay', 'UY', N'Ronald', N'Araújo', '1999-03-07', 'JUG-UY-04', 4, 'Defensor', 'FC Barcelona'),
        ('Uruguay', 'UY', N'Mathías', N'Olivera', '1997-10-31', 'JUG-UY-16', 16, 'Defensor', 'Napoli'),
        ('Uruguay', 'UY', N'Matías', N'Viña', '1997-11-09', 'JUG-UY-17', 17, 'Defensor', 'Palmeiras'),
        ('Uruguay', 'UY', N'Guillermo', N'Varela', '1993-03-24', 'JUG-UY-13', 13, 'Defensor', 'Flamengo'),
        ('Uruguay', 'UY', N'Martín', N'Cáceres', '1987-04-07', 'JUG-UY-22', 22, 'Defensor', 'Fiorentina'),
        ('Uruguay', 'UY', N'Federico', N'Valverde', '1998-07-22', 'JUG-UY-15', 15, 'Mediocampista', 'Real Madrid'),
        ('Uruguay', 'UY', N'Rodrigo', N'Bentancur', '1997-06-25', 'JUG-UY-06', 6, 'Mediocampista', 'Tottenham'),
        ('Uruguay', 'UY', N'Matías', N'Vecino', '1991-08-24', 'JUG-UY-05', 5, 'Mediocampista', 'Lazio'),
        ('Uruguay', 'UY', N'Nahitan', N'Nández', '1995-12-28', 'JUG-UY-08', 8, 'Mediocampista', 'Cagliari'),
        ('Uruguay', 'UY', N'Manuel', N'Ugarte', '2001-04-11', 'JUG-UY-18', 18, 'Mediocampista', 'Sporting CP'),
        ('Uruguay', 'UY', N'Lucas', N'Torreira', '1996-02-11', 'JUG-UY-11', 11, 'Mediocampista', 'Fiorentina'),
        ('Uruguay', 'UY', N'Giorgian', N'De Arrascaeta', '1994-06-01', 'JUG-UY-10', 10, 'Mediocampista', 'Flamengo'),
        ('Uruguay', 'UY', N'Nicolás', N'De la Cruz', '1997-06-01', 'JUG-UY-14', 14, 'Mediocampista', 'River Plate'),
        ('Uruguay', 'UY', N'Edinson', N'Cavani', '1987-02-14', 'JUG-UY-21', 21, 'Delantero', 'Valencia'),
        ('Uruguay', 'UY', N'Luis', N'Suárez', '1987-01-24', 'JUG-UY-09', 9, 'Delantero', 'Nacional'),
        ('Uruguay', 'UY', N'Darwin', N'Núñez', '1999-06-24', 'JUG-UY-07', 7, 'Delantero', 'Liverpool'),
        ('Uruguay', 'UY', N'Facundo', N'Pellistri', '2001-12-20', 'JUG-UY-19', 19, 'Delantero', 'Manchester United'),
        ('Uruguay', 'UY', N'Maximiliano', N'Gómez', '1996-08-14', 'JUG-UY-24', 24, 'Delantero', 'Trabzonspor'),
        -- Croacia (complemento hasta 23 convocados)
        ('Croacia', 'HR', N'Dominik', N'Livaković', '1995-01-09', 'JUG-HR-01', 1, 'Arquero', 'Dinamo Zagreb'),
        ('Croacia', 'HR', N'Ivica', N'Ivušić', '1995-02-01', 'JUG-HR-12', 12, 'Arquero', 'NK Osijek'),
        ('Croacia', 'HR', N'Nediljko', N'Labrović', '1999-10-10', 'JUG-HR-23', 23, 'Arquero', 'HNK Rijeka'),
        ('Croacia', 'HR', N'Josip', N'Juranović', '1995-08-16', 'JUG-HR-22', 22, 'Defensor', 'Celtic'),
        ('Croacia', 'HR', N'Josip', N'Stanišić', '2000-04-02', 'JUG-HR-02', 2, 'Defensor', 'Bayern Múnich'),
        ('Croacia', 'HR', N'Borna', N'Sosa', '1998-01-21', 'JUG-HR-19', 19, 'Defensor', 'VfB Stuttgart'),
        ('Croacia', 'HR', N'Joško', N'Gvardiol', '2002-01-23', 'JUG-HR-20', 20, 'Defensor', 'RB Leipzig'),
        ('Croacia', 'HR', N'Dejan', N'Lovren', '1989-07-05', 'JUG-HR-06', 6, 'Defensor', 'Zenit'),
        ('Croacia', 'HR', N'Domagoj', N'Vida', '1989-04-29', 'JUG-HR-21', 21, 'Defensor', 'AEK Atenas'),
        ('Croacia', 'HR', N'Martin', N'Erlić', '1998-01-24', 'JUG-HR-03', 3, 'Defensor', 'Sassuolo'),
        ('Croacia', 'HR', N'Marcelo', N'Brozović', '1992-11-16', 'JUG-HR-11', 11, 'Mediocampista', 'Inter Milan'),
        ('Croacia', 'HR', N'Luka', N'Modrić', '1985-09-09', 'JUG-HR-10', 10, 'Mediocampista', 'Real Madrid'),
        ('Croacia', 'HR', N'Mateo', N'Kovačić', '1994-05-06', 'JUG-HR-08', 8, 'Mediocampista', 'Chelsea'),
        ('Croacia', 'HR', N'Mario', N'Pašalić', '1995-02-09', 'JUG-HR-15', 15, 'Mediocampista', 'Atalanta'),
        ('Croacia', 'HR', N'Lovro', N'Majer', '1998-01-10', 'JUG-HR-07', 7, 'Mediocampista', 'Stade Rennais'),
        ('Croacia', 'HR', N'Nikola', N'Vlašić', '1997-10-04', 'JUG-HR-16', 16, 'Mediocampista', 'West Ham'),
        ('Croacia', 'HR', N'Luka', N'Sučić', '2002-09-08', 'JUG-HR-14', 14, 'Mediocampista', 'Red Bull Salzburgo'),
        ('Croacia', 'HR', N'Kristijan', N'Jakić', '1997-05-14', 'JUG-HR-05', 5, 'Mediocampista', 'Eintracht Frankfurt'),
        ('Croacia', 'HR', N'Ivan', N'Perišić', '1989-02-02', 'JUG-HR-04', 4, 'Delantero', 'Tottenham'),
        ('Croacia', 'HR', N'Andrej', N'Kramarić', '1991-06-19', 'JUG-HR-09', 9, 'Delantero', 'Hoffenheim'),
        ('Croacia', 'HR', N'Bruno', N'Petković', '1994-09-16', 'JUG-HR-13', 13, 'Delantero', 'Dinamo Zagreb'),
        ('Croacia', 'HR', N'Marko', N'Livaja', '1993-08-26', 'JUG-HR-17', 17, 'Delantero', 'Hajduk Split'),
        ('Croacia', 'HR', N'Mislav', N'Oršić', '1992-12-29', 'JUG-HR-18', 18, 'Delantero', 'Trabzonspor'),
        -- Corea del Sur (complemento hasta 23 convocados)
        ('Corea del Sur', 'KR', N'Seung-gyu', N'Kim', '1990-09-30', 'JUG-KR-01', 1, 'Arquero', 'Al-Shabab'),
        ('Corea del Sur', 'KR', N'Hyeon-woo', N'Jo', '1991-09-25', 'JUG-KR-21', 21, 'Arquero', 'Ulsan HD'),
        ('Corea del Sur', 'KR', N'Bum-keun', N'Song', '1997-10-15', 'JUG-KR-23', 23, 'Arquero', 'Jeonbuk Hyundai'),
        ('Corea del Sur', 'KR', N'Min-jae', N'Kim', '1996-11-15', 'JUG-KR-04', 4, 'Defensor', 'Napoli'),
        ('Corea del Sur', 'KR', N'Young-gwon', N'Kim', '1990-02-27', 'JUG-KR-19', 19, 'Defensor', 'Ulsan HD'),
        ('Corea del Sur', 'KR', N'Moon-hwan', N'Kim', '1995-08-01', 'JUG-KR-13', 13, 'Defensor', 'Jeonbuk Hyundai'),
        ('Corea del Sur', 'KR', N'Jin-su', N'Kim', '1992-06-13', 'JUG-KR-03', 3, 'Defensor', 'Jeonbuk Hyundai'),
        ('Corea del Sur', 'KR', N'Jong-gyu', N'Yoon', '1998-03-20', 'JUG-KR-22', 22, 'Defensor', 'FC Seoul'),
        ('Corea del Sur', 'KR', N'Kyung-won', N'Kwon', '1992-01-31', 'JUG-KR-20', 20, 'Defensor', 'Gamba Osaka'),
        ('Corea del Sur', 'KR', N'Yu-min', N'Cho', '1996-11-17', 'JUG-KR-02', 2, 'Defensor', 'Sharjah'),
        ('Corea del Sur', 'KR', N'In-beom', N'Hwang', '1996-09-20', 'JUG-KR-06', 6, 'Mediocampista', 'Olympiacos'),
        ('Corea del Sur', 'KR', N'Woo-young', N'Jung', '1989-12-14', 'JUG-KR-05', 5, 'Mediocampista', 'Al-Sadd'),
        ('Corea del Sur', 'KR', N'Jun-ho', N'Son', '1992-05-12', 'JUG-KR-25', 25, 'Mediocampista', 'Shandong Taishan'),
        ('Corea del Sur', 'KR', N'Chang-hoon', N'Kwon', '1994-06-30', 'JUG-KR-17', 17, 'Mediocampista', 'Gimcheon Sangmu'),
        ('Corea del Sur', 'KR', N'Jae-sung', N'Lee', '1992-08-10', 'JUG-KR-10', 10, 'Mediocampista', 'Mainz 05'),
        ('Corea del Sur', 'KR', N'Kang-in', N'Lee', '2001-02-19', 'JUG-KR-18', 18, 'Mediocampista', 'Mallorca'),
        ('Corea del Sur', 'KR', N'Seung-ho', N'Paik', '1997-03-17', 'JUG-KR-08', 8, 'Mediocampista', 'Jeonbuk Hyundai'),
        ('Corea del Sur', 'KR', N'Sang-ho', N'Na', '1996-08-12', 'JUG-KR-14', 14, 'Mediocampista', 'FC Seoul'),
        ('Corea del Sur', 'KR', N'Heung-min', N'Son', '1992-07-08', 'JUG-KR-07', 7, 'Delantero', 'Tottenham'),
        ('Corea del Sur', 'KR', N'Hee-chan', N'Hwang', '1996-01-26', 'JUG-KR-11', 11, 'Delantero', 'Wolverhampton'),
        ('Corea del Sur', 'KR', N'Gue-sung', N'Cho', '1998-01-25', 'JUG-KR-09', 9, 'Delantero', 'Jeonbuk Hyundai'),
        ('Corea del Sur', 'KR', N'Ui-jo', N'Hwang', '1992-08-28', 'JUG-KR-16', 16, 'Delantero', 'Olympiacos'),
        ('Corea del Sur', 'KR', N'Min-kyu', N'Song', '1999-09-12', 'JUG-KR-15', 15, 'Delantero', 'Jeonbuk Hyundai'),
        -- Senegal (complemento hasta 23 convocados)
        ('Senegal', 'SN', N'Édouard', N'Mendy', '1992-03-01', 'JUG-SN-16', 16, 'Arquero', 'Chelsea'),
        ('Senegal', 'SN', N'Seny', N'Dieng', '1994-11-23', 'JUG-SN-01', 1, 'Arquero', 'Queens Park Rangers'),
        ('Senegal', 'SN', N'Alfred', N'Gomis', '1993-09-05', 'JUG-SN-23', 23, 'Arquero', 'Stade Rennais'),
        ('Senegal', 'SN', N'Kalidou', N'Koulibaly', '1991-06-20', 'JUG-SN-03', 3, 'Defensor', 'Chelsea'),
        ('Senegal', 'SN', N'Abdou', N'Diallo', '1996-05-04', 'JUG-SN-22', 22, 'Defensor', 'RB Leipzig'),
        ('Senegal', 'SN', N'Youssouf', N'Sabaly', '1993-03-05', 'JUG-SN-14', 14, 'Defensor', 'Real Betis'),
        ('Senegal', 'SN', N'Formose', N'Mendy', '2001-01-02', 'JUG-SN-04', 4, 'Defensor', 'Amiens'),
        ('Senegal', 'SN', N'Pape Abou', N'Cissé', '1995-09-14', 'JUG-SN-02', 2, 'Defensor', 'Olympiacos'),
        ('Senegal', 'SN', N'Ismail', N'Jakobs', '1999-08-17', 'JUG-SN-24', 24, 'Defensor', 'AS Monaco'),
        ('Senegal', 'SN', N'Fodé', N'Ballo-Touré', '1997-01-03', 'JUG-SN-26', 26, 'Defensor', 'AC Milan'),
        ('Senegal', 'SN', N'Idrissa', N'Gueye', '1989-09-26', 'JUG-SN-05', 5, 'Mediocampista', 'Everton'),
        ('Senegal', 'SN', N'Cheikhou', N'Kouyaté', '1989-12-21', 'JUG-SN-08', 8, 'Mediocampista', 'Nottingham Forest'),
        ('Senegal', 'SN', N'Pape', N'Gueye', '1999-06-24', 'JUG-SN-17', 17, 'Mediocampista', 'Olympique de Marsella'),
        ('Senegal', 'SN', N'Pape Matar', N'Sarr', '2002-09-14', 'JUG-SN-21', 21, 'Mediocampista', 'Metz'),
        ('Senegal', 'SN', N'Nampalys', N'Mendy', '1992-06-23', 'JUG-SN-06', 6, 'Mediocampista', 'Leicester City'),
        ('Senegal', 'SN', N'Krépin', N'Diatta', '1999-02-25', 'JUG-SN-15', 15, 'Mediocampista', 'AS Monaco'),
        ('Senegal', 'SN', N'Moustapha', N'Name', '1995-04-05', 'JUG-SN-12', 12, 'Mediocampista', 'Paços de Ferreira'),
        ('Senegal', 'SN', N'Iliman', N'Ndiaye', '2000-03-06', 'JUG-SN-13', 13, 'Mediocampista', 'Olympique de Marsella'),
        ('Senegal', 'SN', N'Sadio', N'Mané', '1992-04-10', 'JUG-SN-10', 10, 'Delantero', 'Bayern Múnich'),
        ('Senegal', 'SN', N'Ismaïla', N'Sarr', '1998-02-25', 'JUG-SN-18', 18, 'Delantero', 'Watford'),
        ('Senegal', 'SN', N'Boulaye', N'Dia', '1996-11-16', 'JUG-SN-09', 9, 'Delantero', 'Salernitana'),
        ('Senegal', 'SN', N'Nicolas', N'Jackson', '2001-06-20', 'JUG-SN-25', 25, 'Delantero', 'Villarreal'),
        ('Senegal', 'SN', N'Bamba', N'Dieng', '2000-03-23', 'JUG-SN-19', 19, 'Delantero', 'Olympique de Marsella');

    INSERT INTO deportivo.Jugador (id_pais_nacimiento, nombre, apellido, fecha_nacimiento, documento_identidad)
    SELECT p.id, j.nombre, j.apellido, j.fnac, j.doc
    FROM @jugadores j
    INNER JOIN general.Pais p ON p.ISO2 = j.iso2 COLLATE Latin1_General_CS_AI
    WHERE NOT EXISTS (SELECT 1 FROM deportivo.Jugador WHERE documento_identidad = j.doc);

    INSERT INTO deportivo.Convocatoria (id_jugador, id_seleccion, dorsal, posicion_habitual, club_origen)
    SELECT jug.id, sel.id, j.dorsal, j.pos, j.club
    FROM @jugadores j
    INNER JOIN deportivo.Jugador jug ON jug.documento_identidad = j.doc
    INNER JOIN deportivo.Seleccion sel ON sel.nombre = j.sel_nombre
    WHERE NOT EXISTS (
        SELECT 1 FROM deportivo.Convocatoria c
        WHERE c.id_seleccion = sel.id AND (c.id_jugador = jug.id OR c.dorsal = j.dorsal)
    );

    PRINT 'OK - Selecciones, cuerpos técnicos y convocatorias cargados.';

    
    PRINT '  3. PARTIDOS, GOLES, TARJETAS Y SANCIONES (ESQUEMA DEPORTIVO)';
    

    -- Variables de selecciones
    DECLARE @s_ar int = (SELECT id FROM deportivo.Seleccion WHERE nombre = 'Argentina');
    DECLARE @s_fr int = (SELECT id FROM deportivo.Seleccion WHERE nombre = 'Francia');
    DECLARE @s_br int = (SELECT id FROM deportivo.Seleccion WHERE nombre = 'Brasil');
    DECLARE @s_es int = (SELECT id FROM deportivo.Seleccion WHERE nombre = 'España');
    DECLARE @s_gb int = (SELECT id FROM deportivo.Seleccion WHERE nombre = 'Inglaterra');
    DECLARE @s_de int = (SELECT id FROM deportivo.Seleccion WHERE nombre = 'Alemania');
    DECLARE @s_nl int = (SELECT id FROM deportivo.Seleccion WHERE nombre = 'Países Bajos');
    DECLARE @s_ma int = (SELECT id FROM deportivo.Seleccion WHERE nombre = 'Marruecos');
    DECLARE @s_us int = (SELECT id FROM deportivo.Seleccion WHERE nombre = 'Estados Unidos');
    DECLARE @s_mx int = (SELECT id FROM deportivo.Seleccion WHERE nombre = 'México');
    DECLARE @s_jp int = (SELECT id FROM deportivo.Seleccion WHERE nombre = 'Japón');
    DECLARE @s_pl int = (SELECT id FROM deportivo.Seleccion WHERE nombre = 'Polonia');

    -- Variables de sedes
    DECLARE @st_metlife int = (SELECT TOP 1 id FROM general.Sede WHERE nombre_estadio LIKE '%MetLife%');
    DECLARE @st_sofi    int = (SELECT TOP 1 id FROM general.Sede WHERE nombre_estadio LIKE '%SoFi%');
    DECLARE @st_att     int = (SELECT TOP 1 id FROM general.Sede WHERE nombre_estadio LIKE '%AT&T%');
    DECLARE @st_miami   int = (SELECT TOP 1 id FROM general.Sede WHERE nombre_estadio LIKE '%Hard Rock%');
    DECLARE @st_azteca  int = (SELECT TOP 1 id FROM general.Sede WHERE nombre_estadio LIKE '%Azteca%');
    DECLARE @st_lusail  int = (SELECT TOP 1 id FROM general.Sede WHERE nombre_estadio LIKE '%Lusail%');

    -- Insertar 12 partidos pensados para probar Prime Time en distintos mercados.
    -- Cada partido se controla individualmente por selecciones y fecha/hora local.
    INSERT INTO deportivo.Partido
    (
        id_sede,
        id_fase,
        id_seleccion_local,
        id_seleccion_visitante,
        fecha_hora_local,
        fecha_hora_utc,
        goles_local,
        goles_visitante,
        asistencia_publico
    )
    SELECT
        v.id_sede,
        v.id_fase,
        v.id_local,
        v.id_visitante,
        v.fecha_local,
        v.fecha_utc,
        v.goles_local,
        v.goles_visitante,
        v.asistencia
    FROM (VALUES
        (@st_sofi,    @fase_grupos,       @s_us, @s_nl, CONVERT(datetime, '2026-06-12 18:00:00'), CONVERT(datetime, '2026-06-13 02:00:00'), 1, 2, 68500),
        (@st_azteca,  @fase_grupos,       @s_mx, @s_pl, CONVERT(datetime, '2026-06-13 19:00:00'), CONVERT(datetime, '2026-06-14 01:00:00'), 2, 1, 86200),
        (@st_att,     @fase_grupos,       @s_ar, @s_pl, CONVERT(datetime, '2026-06-14 17:00:00'), CONVERT(datetime, '2026-06-14 23:00:00'), 3, 1, 79100),
        (@st_miami,   @fase_grupos,       @s_ar, @s_mx, CONVERT(datetime, '2026-06-18 20:00:00'), CONVERT(datetime, '2026-06-19 01:00:00'), 2, 0, 65000),
        (@st_metlife, @fase_grupos,       @s_es, @s_de, CONVERT(datetime, '2026-06-15 15:00:00'), CONVERT(datetime, '2026-06-15 20:00:00'), 2, 2, 81400),
        (@st_sofi,    @fase_grupos,       @s_de, @s_jp, CONVERT(datetime, '2026-06-19 12:00:00'), CONVERT(datetime, '2026-06-19 20:00:00'), 1, 2, 67000),
        (@st_att,     @fase_grupos,       @s_br, @s_ma, CONVERT(datetime, '2026-06-16 18:00:00'), CONVERT(datetime, '2026-06-17 00:00:00'), 3, 1, 78900),
        (@st_miami,   @fase_grupos,       @s_fr, @s_gb, CONVERT(datetime, '2026-06-17 15:00:00'), CONVERT(datetime, '2026-06-17 20:00:00'), 2, 1, 64800),
        (@st_att,     @fase_cuartos,      @s_ar, @s_nl, CONVERT(datetime, '2026-07-04 18:00:00'), CONVERT(datetime, '2026-07-05 00:00:00'), 3, 2, 80000),
        (@st_metlife, @fase_cuartos,      @s_fr, @s_es, CONVERT(datetime, '2026-07-05 15:00:00'), CONVERT(datetime, '2026-07-05 20:00:00'), 2, 1, 82500),
        (@st_lusail,  @fase_semifinales,  @s_ar, @s_br, CONVERT(datetime, '2026-07-14 21:00:00'), CONVERT(datetime, '2026-07-14 18:00:00'), 2, 1, 88900),
        (@st_metlife, @fase_final,         @s_ar, @s_fr, CONVERT(datetime, '2026-07-19 16:00:00'), CONVERT(datetime, '2026-07-19 21:00:00'), 3, 3, 82500)
    ) AS v
    (
        id_sede,
        id_fase,
        id_local,
        id_visitante,
        fecha_local,
        fecha_utc,
        goles_local,
        goles_visitante,
        asistencia
    )
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM deportivo.Partido p
        WHERE p.id_seleccion_local = v.id_local
          AND p.id_seleccion_visitante = v.id_visitante
          AND p.fecha_hora_local = v.fecha_local
    );

    -- Capturar los IDs de los partidos específicos de esta carga.
    -- Se incluye la fecha para no tomar por error un partido histórico importado anteriormente.
    DECLARE @p_ar_pl int =
        (SELECT TOP 1 id FROM deportivo.Partido WHERE id_seleccion_local = @s_ar AND id_seleccion_visitante = @s_pl AND fecha_hora_local = '2026-06-14 17:00:00');
    DECLARE @p_ar_mx int =
        (SELECT TOP 1 id FROM deportivo.Partido WHERE id_seleccion_local = @s_ar AND id_seleccion_visitante = @s_mx AND fecha_hora_local = '2026-06-18 20:00:00');
    DECLARE @p_es_de int =
        (SELECT TOP 1 id FROM deportivo.Partido WHERE id_seleccion_local = @s_es AND id_seleccion_visitante = @s_de AND fecha_hora_local = '2026-06-15 15:00:00');
    DECLARE @p_br_ma int =
        (SELECT TOP 1 id FROM deportivo.Partido WHERE id_seleccion_local = @s_br AND id_seleccion_visitante = @s_ma AND fecha_hora_local = '2026-06-16 18:00:00');
    DECLARE @p_fr_gb int =
        (SELECT TOP 1 id FROM deportivo.Partido WHERE id_seleccion_local = @s_fr AND id_seleccion_visitante = @s_gb AND fecha_hora_local = '2026-06-17 15:00:00');
    DECLARE @p_ar_nl int =
        (SELECT TOP 1 id FROM deportivo.Partido WHERE id_seleccion_local = @s_ar AND id_seleccion_visitante = @s_nl AND fecha_hora_local = '2026-07-04 18:00:00');
    DECLARE @p_fr_es int =
        (SELECT TOP 1 id FROM deportivo.Partido WHERE id_seleccion_local = @s_fr AND id_seleccion_visitante = @s_es AND fecha_hora_local = '2026-07-05 15:00:00');
    DECLARE @p_ar_br int =
        (SELECT TOP 1 id FROM deportivo.Partido WHERE id_seleccion_local = @s_ar AND id_seleccion_visitante = @s_br AND fecha_hora_local = '2026-07-14 21:00:00');
    DECLARE @p_ar_fr int =
        (SELECT TOP 1 id FROM deportivo.Partido WHERE id_seleccion_local = @s_ar AND id_seleccion_visitante = @s_fr AND fecha_hora_local = '2026-07-19 16:00:00');
    DECLARE @p_mx_pl int =
        (SELECT TOP 1 id FROM deportivo.Partido WHERE id_seleccion_local = @s_mx AND id_seleccion_visitante = @s_pl AND fecha_hora_local = '2026-06-13 19:00:00');
    DECLARE @p_us_nl int =
        (SELECT TOP 1 id FROM deportivo.Partido WHERE id_seleccion_local = @s_us AND id_seleccion_visitante = @s_nl AND fecha_hora_local = '2026-06-12 18:00:00');
    DECLARE @p_de_jp int =
        (SELECT TOP 1 id FROM deportivo.Partido WHERE id_seleccion_local = @s_de AND id_seleccion_visitante = @s_jp AND fecha_hora_local = '2026-06-19 12:00:00');

    -- Helper inline para obtener id_convocatoria por documento
    DECLARE @c_messi   int = (SELECT c.id FROM deportivo.Convocatoria c JOIN deportivo.Jugador j ON c.id_jugador = j.id WHERE j.documento_identidad = 'JUG-AR-10');
    DECLARE @c_julian  int = (SELECT c.id FROM deportivo.Convocatoria c JOIN deportivo.Jugador j ON c.id_jugador = j.id WHERE j.documento_identidad = 'JUG-AR-09');
    DECLARE @c_lautaro int = (SELECT c.id FROM deportivo.Convocatoria c JOIN deportivo.Jugador j ON c.id_jugador = j.id WHERE j.documento_identidad = 'JUG-AR-22');
    DECLARE @c_depaul  int = (SELECT c.id FROM deportivo.Convocatoria c JOIN deportivo.Jugador j ON c.id_jugador = j.id WHERE j.documento_identidad = 'JUG-AR-07');
    DECLARE @c_cuti    int = (SELECT c.id FROM deportivo.Convocatoria c JOIN deportivo.Jugador j ON c.id_jugador = j.id WHERE j.documento_identidad = 'JUG-AR-13');
    DECLARE @c_otam    int = (SELECT c.id FROM deportivo.Convocatoria c JOIN deportivo.Jugador j ON c.id_jugador = j.id WHERE j.documento_identidad = 'JUG-AR-19');

    DECLARE @c_mbappe  int = (SELECT c.id FROM deportivo.Convocatoria c JOIN deportivo.Jugador j ON c.id_jugador = j.id WHERE j.documento_identidad = 'JUG-FR-10');
    DECLARE @c_griez   int = (SELECT c.id FROM deportivo.Convocatoria c JOIN deportivo.Jugador j ON c.id_jugador = j.id WHERE j.documento_identidad = 'JUG-FR-07');
    DECLARE @c_dembele int = (SELECT c.id FROM deportivo.Convocatoria c JOIN deportivo.Jugador j ON c.id_jugador = j.id WHERE j.documento_identidad = 'JUG-FR-11');
    DECLARE @c_tchoua  int = (SELECT c.id FROM deportivo.Convocatoria c JOIN deportivo.Jugador j ON c.id_jugador = j.id WHERE j.documento_identidad = 'JUG-FR-08');

    DECLARE @c_vini    int = (SELECT c.id FROM deportivo.Convocatoria c JOIN deportivo.Jugador j ON c.id_jugador = j.id WHERE j.documento_identidad = 'JUG-BR-07');
    DECLARE @c_rodrygo int = (SELECT c.id FROM deportivo.Convocatoria c JOIN deportivo.Jugador j ON c.id_jugador = j.id WHERE j.documento_identidad = 'JUG-BR-10');
    DECLARE @c_raphi   int = (SELECT c.id FROM deportivo.Convocatoria c JOIN deportivo.Jugador j ON c.id_jugador = j.id WHERE j.documento_identidad = 'JUG-BR-11');

    DECLARE @c_yamal   int = (SELECT c.id FROM deportivo.Convocatoria c JOIN deportivo.Jugador j ON c.id_jugador = j.id WHERE j.documento_identidad = 'JUG-ES-19');
    DECLARE @c_olmo    int = (SELECT c.id FROM deportivo.Convocatoria c JOIN deportivo.Jugador j ON c.id_jugador = j.id WHERE j.documento_identidad = 'JUG-ES-10');
    DECLARE @c_rodri   int = (SELECT c.id FROM deportivo.Convocatoria c JOIN deportivo.Jugador j ON c.id_jugador = j.id WHERE j.documento_identidad = 'JUG-ES-16');

    DECLARE @c_kane    int = (SELECT c.id FROM deportivo.Convocatoria c JOIN deportivo.Jugador j ON c.id_jugador = j.id WHERE j.documento_identidad = 'JUG-GB-09');
    DECLARE @c_belling int = (SELECT c.id FROM deportivo.Convocatoria c JOIN deportivo.Jugador j ON c.id_jugador = j.id WHERE j.documento_identidad = 'JUG-GB-10');

    DECLARE @c_musiala int = (SELECT c.id FROM deportivo.Convocatoria c JOIN deportivo.Jugador j ON c.id_jugador = j.id WHERE j.documento_identidad = 'JUG-DE-10');
    DECLARE @c_wirtz   int = (SELECT c.id FROM deportivo.Convocatoria c JOIN deportivo.Jugador j ON c.id_jugador = j.id WHERE j.documento_identidad = 'JUG-DE-17');
    DECLARE @c_rudiger int = (SELECT c.id FROM deportivo.Convocatoria c JOIN deportivo.Jugador j ON c.id_jugador = j.id WHERE j.documento_identidad = 'JUG-DE-02');

    DECLARE @c_gakpo   int = (SELECT c.id FROM deportivo.Convocatoria c JOIN deportivo.Jugador j ON c.id_jugador = j.id WHERE j.documento_identidad = 'JUG-NL-08');
    DECLARE @c_vandijk int = (SELECT c.id FROM deportivo.Convocatoria c JOIN deportivo.Jugador j ON c.id_jugador = j.id WHERE j.documento_identidad = 'JUG-NL-04');
    DECLARE @c_hakimi  int = (SELECT c.id FROM deportivo.Convocatoria c JOIN deportivo.Jugador j ON c.id_jugador = j.id WHERE j.documento_identidad = 'JUG-MA-02');
    DECLARE @c_pulisic int = (SELECT c.id FROM deportivo.Convocatoria c JOIN deportivo.Jugador j ON c.id_jugador = j.id WHERE j.documento_identidad = 'JUG-US-10');
    DECLARE @c_gimenez int = (SELECT c.id FROM deportivo.Convocatoria c JOIN deportivo.Jugador j ON c.id_jugador = j.id WHERE j.documento_identidad = 'JUG-MX-09');
    DECLARE @c_mitoma  int = (SELECT c.id FROM deportivo.Convocatoria c JOIN deportivo.Jugador j ON c.id_jugador = j.id WHERE j.documento_identidad = 'JUG-JP-07');
    DECLARE @c_lewa    int = (SELECT c.id FROM deportivo.Convocatoria c JOIN deportivo.Jugador j ON c.id_jugador = j.id WHERE j.documento_identidad = 'JUG-PL-09');

    -- 3.1 Carga de Goles 
    IF NOT EXISTS (SELECT 1 FROM deportivo.Gol WHERE id_partido = @p_ar_pl)
    BEGIN
        INSERT INTO deportivo.Gol (id_partido, id_convocatoria_autor, id_convocatoria_asistencia, minuto, minuto_adicional, periodo, es_en_contra, es_penal)
        VALUES
            -- Argentina 3 - 1 Polonia
            (@p_ar_pl, @c_messi,   @c_depaul, 18, NULL, '1T', 0, 1),
            (@p_ar_pl, @c_julian,  @c_messi,  54, NULL, '2T', 0, 0),
            (@p_ar_pl, @c_lautaro, @c_messi,  82, NULL, '2T', 0, 0),
            (@p_ar_pl, @c_lewa,    NULL,      88, NULL, '2T', 0, 1),
            -- Argentina 2 - 0 México
            (@p_ar_mx, @c_messi,   @c_depaul, 64, NULL, '2T', 0, 0),
            (@p_ar_mx, @c_julian,  @c_messi,  87, NULL, '2T', 0, 0),
            -- España 2 - 2 Alemania
            (@p_es_de, @c_yamal,   @c_olmo,   21, NULL, '1T', 0, 0),
            (@p_es_de, @c_musiala, @c_wirtz,  39, NULL, '1T', 0, 0),
            (@p_es_de, @c_olmo,    @c_yamal,  67, NULL, '2T', 0, 0),
            (@p_es_de, @c_wirtz,   @c_musiala,89, NULL, '2T', 0, 0),
            -- Brasil 3 - 1 Marruecos
            (@p_br_ma, @c_vini,    @c_rodrygo,14, NULL, '1T', 0, 0),
            (@p_br_ma, @c_vini,    @c_raphi,  48, NULL, '2T', 0, 0),
            (@p_br_ma, @c_rodrygo, @c_vini,   73, NULL, '2T', 0, 0),
            (@p_br_ma, @c_hakimi,  NULL,      81, NULL, '2T', 0, 0),
            -- Francia 2 - 1 Inglaterra
            (@p_fr_gb, @c_mbappe,  @c_griez,  27, NULL, '1T', 0, 0),
            (@p_fr_gb, @c_kane,    @c_belling,52, NULL, '2T', 0, 1),
            (@p_fr_gb, @c_mbappe,  @c_dembele,78, NULL, '2T', 0, 0),
            -- Argentina 3 - 2 Países Bajos (Cuartos)
            (@p_ar_nl, @c_messi,   NULL,      35, NULL, '1T', 0, 1),
            (@p_ar_nl, @c_julian,  @c_messi,  61, NULL, '2T', 0, 0),
            (@p_ar_nl, @c_gakpo,   NULL,      74, NULL, '2T', 0, 0),
            (@p_ar_nl, @c_gakpo,   NULL,      90, 4,    '2T', 0, 0),
            (@p_ar_nl, @c_lautaro, @c_messi, 112, NULL, '2TS',0, 0),
            -- Francia 2 - 1 España (Cuartos)
            (@p_fr_es, @c_yamal,   @c_rodri,  19, NULL, '1T', 0, 0),
            (@p_fr_es, @c_mbappe,  @c_griez,  44, NULL, '1T', 0, 1),
            (@p_fr_es, @c_griez,   @c_mbappe, 83, NULL, '2T', 0, 0),
            -- Argentina 2 - 1 Brasil (Semifinal)
            (@p_ar_br, @c_messi,   @c_julian, 31, NULL, '1T', 0, 0),
            (@p_ar_br, @c_vini,    @c_raphi,  58, NULL, '2T', 0, 0),
            (@p_ar_br, @c_julian,  @c_messi,  85, NULL, '2T', 0, 0),
            -- Argentina 3 - 3 Francia (Final)
            (@p_ar_fr, @c_messi,   NULL,      23, NULL, '1T', 0, 1),
            (@p_ar_fr, @c_julian,  @c_depaul, 36, NULL, '1T', 0, 0),
            (@p_ar_fr, @c_mbappe,  NULL,      80, NULL, '2T', 0, 1),
            (@p_ar_fr, @c_mbappe,  @c_dembele,81, NULL, '2T', 0, 0),
            (@p_ar_fr, @c_messi,   @c_lautaro,108,NULL, '2TS',0, 0),
            (@p_ar_fr, @c_mbappe,  NULL,     118, NULL, '2TS',0, 1),
            -- Otros partidos de grupos
            (@p_mx_pl, @c_gimenez, NULL,      30, NULL, '1T', 0, 0),
            (@p_mx_pl, @c_gimenez, NULL,      69, NULL, '2T', 0, 0),
            (@p_mx_pl, @c_lewa,    NULL,      77, NULL, '2T', 0, 0),
            (@p_us_nl, @c_pulisic, NULL,      15, NULL, '1T', 0, 0),
            (@p_us_nl, @c_gakpo,   NULL,      50, NULL, '2T', 0, 0),
            (@p_de_jp, @c_mitoma,  NULL,      75, NULL, '2T', 0, 0);
    END;

    -- 3.2 Carga de Tarjetas y Sanciones 
    IF NOT EXISTS (SELECT 1 FROM deportivo.Tarjeta WHERE id_partido = @p_ar_nl)
    BEGIN
        -- Amarillas varias por selección
        INSERT INTO deportivo.Tarjeta (id_partido, id_convocatoria, minuto, periodo, color, es_roja_directa, motivo)
        VALUES
            (@p_ar_pl, @c_cuti,    41, '1T', 'Amarilla', 0, 'Juego brusco'),
            (@p_ar_mx, @c_depaul,  55, '2T', 'Amarilla', 0, 'Falta táctica'),
            (@p_ar_nl, @c_cuti,    45, '1T', 'Amarilla', 0, 'Protestar fallos arbitrales'), -- 2da acumulada -> sanción
            (@p_ar_nl, @c_otam,    76, '2T', 'Amarilla', 0, 'Sujetar al adversario'),
            (@p_ar_nl, @c_vandijk, 88, '2T', 'Amarilla', 0, 'Conducta antideportiva'),
            (@p_fr_gb, @c_tchoua,  33, '1T', 'Amarilla', 0, 'Entrada tardía'),
            (@p_fr_es, @c_tchoua,  62, '2T', 'Amarilla', 0, 'Falta reiterada'), -- 2da acumulada -> sanción
            (@p_es_de, @c_rodri,   29, '1T', 'Amarilla', 0, 'Cortar avance prometedor'),
            (@p_es_de, @c_rudiger, 64, '2T', 'Amarilla', 0, 'Juego brusco'),
            (@p_br_ma, @c_hakimi,  51, '2T', 'Amarilla', 0, 'Falta táctica'),
            (@p_ar_br, @c_vini,    71, '2T', 'Amarilla', 0, 'Simulación');

        -- Doble amarilla en un mismo partido (ejemplo encadenado con id_tarjeta_origen)
        INSERT INTO deportivo.Tarjeta (id_partido, id_convocatoria, minuto, periodo, color, es_roja_directa, motivo)
        VALUES (@p_ar_br, @c_rodrygo, 40, '1T', 'Amarilla', 0, 'Falta temeraria');
        DECLARE @id_tarj_1 int = SCOPE_IDENTITY();

        INSERT INTO deportivo.Tarjeta (id_partido, id_convocatoria, minuto, periodo, color, es_roja_directa, motivo, id_tarjeta_origen)
        VALUES (@p_ar_br, @c_rodrygo, 82, '2T', 'Roja', 0, 'Doble amonestación', @id_tarj_1);
        DECLARE @id_tarj_doble int = SCOPE_IDENTITY();

        -- Roja directa
        INSERT INTO deportivo.Tarjeta (id_partido, id_convocatoria, minuto, periodo, color, es_roja_directa, motivo)
        VALUES (@p_es_de, @c_rudiger, 87, '2T', 'Roja', 1, 'Conducta violenta');
        DECLARE @id_tarj_roja int = SCOPE_IDENTITY();

        -- Sanciones correspondientes (Pendientes y Cumplidas)
        INSERT INTO deportivo.Sancion (id_convocatoria, id_partido_origen, id_tarjeta, cantidad_partidos_sancion, motivo, estado)
        VALUES
            (@c_cuti,    @p_ar_nl, NULL,           1, 'Acumulación de 2 tarjetas amarillas', 'Cumplida'),
            (@c_tchoua,  @p_fr_es, NULL,           1, 'Acumulación de 2 tarjetas amarillas', 'Pendiente'),
            (@c_rodrygo, @p_ar_br, @id_tarj_doble, 1, 'Expulsión por doble amonestación',    'Pendiente'),
            (@c_rudiger, @p_es_de, @id_tarj_roja,  2, 'Expulsión por roja directa',          'Pendiente');
    END;

    PRINT 'OK - Partidos, goles, tarjetas y sanciones cargados.';

    
    PRINT '  4. DESIGNACIONES ARBITRALES E INFORMES (ESQUEMA ARBITRAJE)';
    

    -- 4.1 Roles Arbitrales
    DECLARE @roles_arbitrales TABLE
    (
        nombre varchar(60)
    );

    INSERT INTO @roles_arbitrales (nombre)
    VALUES
        ('Árbitro Principal'),
        ('Árbitro Asistente 1'),
        ('Árbitro Asistente 2'),
        ('Cuarto Árbitro'),
        ('VAR');

    DECLARE @max_id_rol_arbitral int = ISNULL((SELECT MAX(id) FROM arbitraje.RolArbitral), 0);

    ;WITH Faltantes AS
    (
        SELECT
            r.nombre,
            ROW_NUMBER() OVER (ORDER BY r.nombre) AS nro
        FROM @roles_arbitrales r
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM arbitraje.RolArbitral existente
            WHERE UPPER(LTRIM(RTRIM(existente.nombre))) = UPPER(LTRIM(RTRIM(r.nombre)))
        )
    )
    INSERT INTO arbitraje.RolArbitral (id, nombre)
    SELECT
        @max_id_rol_arbitral + CAST(nro AS int),
        nombre
    FROM Faltantes;

    DECLARE @rol_arbitro_principal int =
        (SELECT TOP 1 id FROM arbitraje.RolArbitral WHERE nombre = 'Árbitro Principal');
    DECLARE @rol_var int =
        (SELECT TOP 1 id FROM arbitraje.RolArbitral WHERE nombre = 'VAR');

    -- 4.2 Designaciones usando los árbitros cargados
    DECLARE @arb_marciniak int = (SELECT TOP 1 id FROM arbitraje.Arbitro WHERE apellido LIKE '%Marciniak%');
    DECLARE @arb_pitana    int = (SELECT TOP 1 id FROM arbitraje.Arbitro WHERE apellido LIKE '%Pitana%');
    DECLARE @arb_elizondo  int = (SELECT TOP 1 id FROM arbitraje.Arbitro WHERE apellido LIKE '%Elizondo%');
    DECLARE @arb_collina   int = (SELECT TOP 1 id FROM arbitraje.Arbitro WHERE apellido LIKE '%Collina%');
    DECLARE @arb_webb      int = (SELECT TOP 1 id FROM arbitraje.Arbitro WHERE apellido LIKE '%Webb%');
    DECLARE @arb_rizzoli   int = (SELECT TOP 1 id FROM arbitraje.Arbitro WHERE apellido LIKE '%Rizzoli%');
    DECLARE @arb_vincic    int = (SELECT TOP 1 id FROM arbitraje.Arbitro WHERE apellido LIKE '%Vinčić%' OR apellido LIKE '%Vincic%');
    DECLARE @arb_codesal   int = (SELECT TOP 1 id FROM arbitraje.Arbitro WHERE apellido LIKE '%Codesal%');

    DECLARE @next_des_id int = ISNULL((SELECT MAX(id) FROM arbitraje.DesignacionArbitral), 0) + 1;

    IF @arb_marciniak IS NOT NULL AND NOT EXISTS (SELECT 1 FROM arbitraje.DesignacionArbitral WHERE id_partido = @p_ar_fr)
    BEGIN
        INSERT INTO arbitraje.DesignacionArbitral (id, id_partido, id_arbitro, id_rol_arbitral, estado, motivo_descarte)
        VALUES
            (@next_des_id,     @p_ar_fr, @arb_marciniak, @rol_arbitro_principal, 'Confirmada', NULL),
            (@next_des_id + 1, @p_ar_fr, @arb_vincic,    @rol_var, 'Confirmada', NULL),
            (@next_des_id + 2, @p_ar_br, @arb_collina,   @rol_arbitro_principal, 'Confirmada', NULL),
            (@next_des_id + 3, @p_ar_nl, @arb_webb,      @rol_arbitro_principal, 'Confirmada', NULL),
            (@next_des_id + 4, @p_fr_es, @arb_pitana,    @rol_arbitro_principal, 'Confirmada', NULL),
            (@next_des_id + 5, @p_es_de, @arb_rizzoli,   @rol_arbitro_principal, 'Confirmada', NULL),
            (@next_des_id + 6, @p_br_ma, @arb_elizondo,  @rol_arbitro_principal, 'Confirmada', NULL),
            (@next_des_id + 7, @p_ar_pl, @arb_codesal,   @rol_arbitro_principal, 'Confirmada', NULL);

        DECLARE @next_inf_id int = ISNULL((SELECT MAX(id) FROM arbitraje.InformePostPartido), 0) + 1;

        INSERT INTO arbitraje.InformePostPartido (id, id_partido, id_arbitro, observaciones, calificacion_desempeno)
        VALUES
            (@next_inf_id,     @p_ar_fr, @arb_marciniak, 'Excelente control disciplinario en final con alargue.', 9.6),
            (@next_inf_id + 1, @p_ar_br, @arb_collina,   'Correcta aplicación de doble amarilla.',              9.4),
            (@next_inf_id + 2, @p_es_de, @arb_rizzoli,   'Expulsión directa bien sancionada a los 87 minutos.',   9.1);
    END;

    PRINT 'OK - Designaciones e informes arbitrales cargados.';

    
    PRINT '  5. ANUNCIANTES, CAMPAÑAS, PIEZAS Y EXHIBICIONES (ESQUEMA PUBLICIDAD)';
   

    -- 5.1 Anunciantes
    INSERT INTO publicidad.Anunciante (id_pais_origen, tax_id, nombre_empresa)
    SELECT p.id, a.tax_id, a.nombre
    FROM (VALUES
        ('DE', 'DE-811145234', 'Adidas AG'),
        ('US', 'US-58-0628465','The Coca-Cola Company'),
        ('US', 'US-26-0267673','Visa Inc.'),
        ('QA', 'QA-100459821', 'Qatar Airways Group'),
        ('KR', 'KR-101-81-0914','Hyundai Motor Company'),
        ('CN', 'CN-9137020016','Hisense Group'),
        ('JP', 'JP-1180301018771','Toyota Motor Corporation'),
        ('BR', 'BR-33000167000101','Petrobras')
    ) AS a(iso2, tax_id, nombre)
    INNER JOIN general.Pais p ON p.ISO2 = a.iso2 COLLATE Latin1_General_CS_AI
    WHERE NOT EXISTS (SELECT 1 FROM publicidad.Anunciante WHERE tax_id = a.tax_id);

    DECLARE @an_adidas  int = (SELECT id FROM publicidad.Anunciante WHERE tax_id = 'DE-811145234');
    DECLARE @an_coca    int = (SELECT id FROM publicidad.Anunciante WHERE tax_id = 'US-58-0628465');
    DECLARE @an_visa    int = (SELECT id FROM publicidad.Anunciante WHERE tax_id = 'US-26-0267673');
    DECLARE @an_qatar   int = (SELECT id FROM publicidad.Anunciante WHERE tax_id = 'QA-100459821');
    DECLARE @an_hyundai int = (SELECT id FROM publicidad.Anunciante WHERE tax_id = 'KR-101-81-0914');

    -- 5.2 Tarifas en distintas monedas (USD, EUR, ARS)
    IF NOT EXISTS (SELECT 1 FROM publicidad.Tarifa WHERE nombre = 'Tarifa Grupos Estándar USD')
    BEGIN
        INSERT INTO publicidad.Tarifa (id_moneda, nombre, costo_base, vigente_desde, vigente_hasta)
        VALUES
            (@id_usd, 'Tarifa Grupos Estándar USD',     25000.00, '2026-06-01', '2026-07-31'),
            (@id_usd, 'Tarifa Eliminación Prime USD',   55000.00, '2026-06-01', '2026-07-31'),
            (@id_eur, 'Tarifa Europea Prime EUR',       48000.00, '2026-06-01', '2026-07-31'),
            (@id_ars, 'Tarifa Regional Latam ARS',   22000000.00, '2026-06-01', '2026-07-31');
    END;

    DECLARE @t_usd_std   int = (SELECT TOP 1 id FROM publicidad.Tarifa WHERE nombre = 'Tarifa Grupos Estándar USD');
    DECLARE @t_usd_prime int = (SELECT TOP 1 id FROM publicidad.Tarifa WHERE nombre = 'Tarifa Eliminación Prime USD');
    DECLARE @t_eur_prime int = (SELECT TOP 1 id FROM publicidad.Tarifa WHERE nombre = 'Tarifa Europea Prime EUR');
    DECLARE @t_ars_latam int = (SELECT TOP 1 id FROM publicidad.Tarifa WHERE nombre = 'Tarifa Regional Latam ARS');

    -- 5.3 Campañas
    IF NOT EXISTS (SELECT 1 FROM publicidad.Campana WHERE nombre = 'Adidas Impossible Is Nothing 2026')
    BEGIN
        INSERT INTO publicidad.Campana (id_anunciante, id_moneda, nombre, fecha_inicio, fecha_fin, presupuesto)
        VALUES
            (@an_adidas,  @id_eur, 'Adidas Impossible Is Nothing 2026', '2026-06-01', '2026-07-25',  850000.00),
            (@an_coca,    @id_usd, 'Coca-Cola Believing Is Magic 2026', '2026-06-01', '2026-07-25', 1200000.00),
            (@an_visa,    @id_usd, 'Visa Everywhere You Want To Be',    '2026-06-01', '2026-07-25',  950000.00),
            (@an_qatar,   @id_usd, 'Qatar Airways Fly Better Cup',      '2026-06-01', '2026-07-25',  780000.00),
            (@an_hyundai, @id_ars, 'Hyundai Goal of the Century Latam', '2026-06-01', '2026-07-25', 450000000.00);
    END;

    DECLARE @camp_adidas  int = (SELECT TOP 1 id FROM publicidad.Campana WHERE nombre = 'Adidas Impossible Is Nothing 2026');
    DECLARE @camp_coca    int = (SELECT TOP 1 id FROM publicidad.Campana WHERE nombre = 'Coca-Cola Believing Is Magic 2026');
    DECLARE @camp_visa    int = (SELECT TOP 1 id FROM publicidad.Campana WHERE nombre = 'Visa Everywhere You Want To Be');
    DECLARE @camp_qatar   int = (SELECT TOP 1 id FROM publicidad.Campana WHERE nombre = 'Qatar Airways Fly Better Cup');
    DECLARE @camp_hyundai int = (SELECT TOP 1 id FROM publicidad.Campana WHERE nombre = 'Hyundai Goal of the Century Latam');

    -- 5.4 Piezas de Contenido
    IF NOT EXISTS (SELECT 1 FROM publicidad.PiezaDeContenido WHERE titulo = 'Spot Botines Predator 2026')
    BEGIN
        INSERT INTO publicidad.PiezaDeContenido (id_campana, id_tarifa, id_idioma, titulo, descripcion, duracion)
        VALUES
            (@camp_adidas,  @t_eur_prime, 'deu', 'Spot Botines Predator 2026',      'Banner LED animado lanzamiento botines', 30),
            (@camp_coca,    @t_usd_prime, 'eng', 'Coca-Cola Fan Zone Global',       'Activación hinchas en estadio',         20),
            (@camp_visa,    @t_usd_std,   'eng', 'Visa Contactless Stadium',        'Pagos sin contacto en sedes',           15),
            (@camp_qatar,   @t_usd_prime, 'ara', 'Qatar Airways Connecting Fans',   'Rutas internacionales al Mundial',      25),
            (@camp_hyundai, @t_ars_latam, 'spa', 'Hyundai Movilidad Eléctrica',     'Campaña regional Sudamérica',           20);
    END;

    DECLARE @pz_adidas  int = (SELECT TOP 1 id FROM publicidad.PiezaDeContenido WHERE titulo = 'Spot Botines Predator 2026');
    DECLARE @pz_coca    int = (SELECT TOP 1 id FROM publicidad.PiezaDeContenido WHERE titulo = 'Coca-Cola Fan Zone Global');
    DECLARE @pz_visa    int = (SELECT TOP 1 id FROM publicidad.PiezaDeContenido WHERE titulo = 'Visa Contactless Stadium');
    DECLARE @pz_qatar   int = (SELECT TOP 1 id FROM publicidad.PiezaDeContenido WHERE titulo = 'Qatar Airways Connecting Fans');
    DECLARE @pz_hyundai int = (SELECT TOP 1 id FROM publicidad.PiezaDeContenido WHERE titulo = 'Hyundai Movilidad Eléctrica');

    -- 5.5 Mercados de Interés por Pieza (para Matriz de Prime Time)
    INSERT INTO publicidad.PiezaDeMercadoDeInteres (id_pieza, id_pais)
    SELECT m.id_pieza, p.id
    FROM (VALUES
        (@pz_adidas,  'DE'), (@pz_adidas,  'ES'), (@pz_adidas,  'FR'), (@pz_adidas,  'AR'),
        (@pz_coca,    'US'), (@pz_coca,    'AR'), (@pz_coca,    'BR'), (@pz_coca,    'MX'),
        (@pz_visa,    'US'), (@pz_visa,    'GB'), (@pz_visa,    'JP'),
        (@pz_qatar,   'QA'), (@pz_qatar,   'GB'), (@pz_qatar,   'FR'),
        (@pz_hyundai, 'AR'), (@pz_hyundai, 'BR'), (@pz_hyundai, 'MX'), (@pz_hyundai, 'KR')
    ) AS m(id_pieza, iso2)
    INNER JOIN general.Pais p ON p.ISO2 = m.iso2 COLLATE Latin1_General_CS_AI
    WHERE NOT EXISTS (
        SELECT 1 FROM publicidad.PiezaDeMercadoDeInteres pm
        WHERE pm.id_pieza = m.id_pieza AND pm.id_pais = p.id
    );

    -- 5.6 Exhibiciones Publicitarias (Paneles 1 a 4 en los partidos)
    DECLARE @pan1 int = (SELECT id FROM publicidad.EspacioPublicitario WHERE ubicacion_panel = 'Panel 1');
    DECLARE @pan2 int = (SELECT id FROM publicidad.EspacioPublicitario WHERE ubicacion_panel = 'Panel 2');
    DECLARE @pan3 int = (SELECT id FROM publicidad.EspacioPublicitario WHERE ubicacion_panel = 'Panel 3');
    DECLARE @pan4 int = (SELECT id FROM publicidad.EspacioPublicitario WHERE ubicacion_panel = 'Panel 4');

    IF NOT EXISTS (SELECT 1 FROM publicidad.ExhibicionPublicitaria WHERE id_partido = @p_ar_fr)
    BEGIN
        INSERT INTO publicidad.ExhibicionPublicitaria
            (id_partido, id_pieza, id_espacio_publicitario, id_moneda, costo_aplicado, fue_prime_time, estado, fecha_anulacion, motivo_anulacion)
        VALUES
            -- Final: Argentina vs Francia (4/4 paneles ocupados = 100% ocupación)
            (@p_ar_fr, @pz_adidas,  @pan1, @id_eur,    62400.00, 1, 'VIGENTE', NULL, NULL),
            (@p_ar_fr, @pz_coca,    @pan2, @id_usd,    71500.00, 1, 'VIGENTE', NULL, NULL),
            (@p_ar_fr, @pz_visa,    @pan3, @id_usd,    45000.00, 1, 'VIGENTE', NULL, NULL),
            (@p_ar_fr, @pz_hyundai, @pan4, @id_ars, 28600000.00, 1, 'VIGENTE', NULL, NULL),

            -- Semifinal: Argentina vs Brasil (4/4 paneles ocupados)
            (@p_ar_br, @pz_coca,    @pan1, @id_usd,    65000.00, 1, 'VIGENTE', NULL, NULL),
            (@p_ar_br, @pz_hyundai, @pan2, @id_ars, 26400000.00, 1, 'VIGENTE', NULL, NULL),
            (@p_ar_br, @pz_qatar,   @pan3, @id_usd,    58000.00, 1, 'VIGENTE', NULL, NULL),
            (@p_ar_br, @pz_adidas,  @pan4, @id_eur,    52000.00, 0, 'VIGENTE', NULL, NULL),

            -- Cuartos: Argentina vs Países Bajos (3/4 paneles ocupados = 75% ocupación)
            (@p_ar_nl, @pz_hyundai, @pan1, @id_ars, 24000000.00, 1, 'VIGENTE', NULL, NULL),
            (@p_ar_nl, @pz_visa,    @pan2, @id_usd,    32000.00, 1, 'VIGENTE', NULL, NULL),
            (@p_ar_nl, @pz_adidas,  @pan3, @id_eur,    48000.00, 0, 'VIGENTE', NULL, NULL),

            -- Cuartos: Francia vs España (3/4 paneles ocupados)
            (@p_fr_es, @pz_adidas,  @pan1, @id_eur,    57600.00, 1, 'VIGENTE', NULL, NULL),
            (@p_fr_es, @pz_qatar,   @pan2, @id_usd,    55000.00, 1, 'VIGENTE', NULL, NULL),
            (@p_fr_es, @pz_coca,    @pan3, @id_usd,    50000.00, 0, 'VIGENTE', NULL, NULL),

            -- Grupos: Argentina vs México (4/4 paneles ocupados)
            (@p_ar_mx, @pz_coca,    @pan1, @id_usd,    35000.00, 1, 'VIGENTE', NULL, NULL),
            (@p_ar_mx, @pz_hyundai, @pan2, @id_ars, 22000000.00, 1, 'VIGENTE', NULL, NULL),
            (@p_ar_mx, @pz_visa,    @pan3, @id_usd,    28000.00, 1, 'VIGENTE', NULL, NULL),
            (@p_ar_mx, @pz_qatar,   @pan4, @id_usd,    30000.00, 0, 'VIGENTE', NULL, NULL),

            -- Grupos: España vs Alemania (2/4 paneles vigentes + 1 anulada para probar filtro estado = VIGENTE)
            (@p_es_de, @pz_adidas,  @pan1, @id_eur,    54000.00, 1, 'VIGENTE', NULL, NULL),
            (@p_es_de, @pz_visa,    @pan2, @id_usd,    25000.00, 0, 'VIGENTE', NULL, NULL),
            (@p_es_de, @pz_coca,    @pan3, @id_usd,    25000.00, 0, 'ANULADA', SYSDATETIME(), 'Cambio de pauta comercial del anunciante'),

            -- Grupos: Brasil vs Marruecos (2/4 paneles ocupados)
            (@p_br_ma, @pz_qatar,   @pan1, @id_usd,    32000.00, 1, 'VIGENTE', NULL, NULL),
            (@p_br_ma, @pz_hyundai, @pan2, @id_ars, 22000000.00, 1, 'VIGENTE', NULL, NULL),

            -- Grupos: Estados Unidos vs Países Bajos (2/4 paneles ocupados)
            (@p_us_nl, @pz_visa,    @pan1, @id_usd,    30000.00, 1, 'VIGENTE', NULL, NULL),
            (@p_us_nl, @pz_coca,    @pan2, @id_usd,    30000.00, 1, 'VIGENTE', NULL, NULL);
    END;

    PRINT 'OK - Ecosistema publicitario y exhibiciones cargados.';

    -- 5.7 Anunciantes adicionales y campañas para cubrir al menos 6 países de origen
    --     Países con campaña: DE, US, QA, KR (previos) + CN, JP, BR (nuevos) = 7
    DECLARE @an_hisense int = (SELECT id FROM publicidad.Anunciante WHERE tax_id = 'CN-9137020016');
    DECLARE @an_toyota  int = (SELECT id FROM publicidad.Anunciante WHERE tax_id = 'JP-1180301018771');
    DECLARE @an_petro   int = (SELECT id FROM publicidad.Anunciante WHERE tax_id = 'BR-33000167000101');

    IF NOT EXISTS (SELECT 1 FROM publicidad.Campana WHERE nombre = 'Hisense Official Sponsor 2026')
    BEGIN
        INSERT INTO publicidad.Campana (id_anunciante, id_moneda, nombre, fecha_inicio, fecha_fin, presupuesto)
        VALUES
            (@an_hisense, @id_usd, 'Hisense Official Sponsor 2026',   '2026-06-01', '2026-07-25', 520000.00),
            (@an_toyota,  @id_usd, 'Toyota Start Your Impossible',    '2026-06-01', '2026-07-25', 610000.00),
            (@an_petro,   @id_usd, 'Petrobras Energia da Torcida',    '2026-06-01', '2026-07-25', 340000.00);
    END;

    DECLARE @camp_hisense int = (SELECT TOP 1 id FROM publicidad.Campana WHERE nombre = 'Hisense Official Sponsor 2026');
    DECLARE @camp_toyota  int = (SELECT TOP 1 id FROM publicidad.Campana WHERE nombre = 'Toyota Start Your Impossible');
    DECLARE @camp_petro   int = (SELECT TOP 1 id FROM publicidad.Campana WHERE nombre = 'Petrobras Energia da Torcida');

    IF NOT EXISTS (SELECT 1 FROM publicidad.PiezaDeContenido WHERE titulo = 'Hisense Smart TV Fan Edition')
    BEGIN
        INSERT INTO publicidad.PiezaDeContenido (id_campana, id_tarifa, id_idioma, titulo, descripcion, duracion)
        VALUES
            (@camp_hisense, @t_usd_std,   'zho', 'Hisense Smart TV Fan Edition',  'Panel LED televisores oficiales del torneo', 20),
            (@camp_toyota,  @t_usd_prime, 'jpn', 'Toyota Movilidad Mundial',      'Spot de movilidad sustentable',               25),
            (@camp_petro,   @t_usd_std,   'por', 'Petrobras Energia da Torcida',  'Campaña energía y hinchada en Sudamérica',    20);
    END;

    DECLARE @pz_hisense int = (SELECT TOP 1 id FROM publicidad.PiezaDeContenido WHERE titulo = 'Hisense Smart TV Fan Edition');
    DECLARE @pz_toyota  int = (SELECT TOP 1 id FROM publicidad.PiezaDeContenido WHERE titulo = 'Toyota Movilidad Mundial');
    DECLARE @pz_petro   int = (SELECT TOP 1 id FROM publicidad.PiezaDeContenido WHERE titulo = 'Petrobras Energia da Torcida');

    INSERT INTO publicidad.PiezaDeMercadoDeInteres (id_pieza, id_pais)
    SELECT m.id_pieza, p.id
    FROM (VALUES
        (@pz_hisense, 'CN'), (@pz_hisense, 'MX'), (@pz_hisense, 'US'), (@pz_hisense, 'ES'),
        (@pz_toyota,  'JP'), (@pz_toyota,  'US'), (@pz_toyota,  'AU'), (@pz_toyota,  'MX'),
        (@pz_petro,   'BR'), (@pz_petro,   'AR'), (@pz_petro,   'UY'), (@pz_petro,   'CO')
    ) AS m(id_pieza, iso2)
    INNER JOIN general.Pais p ON p.ISO2 = m.iso2 COLLATE Latin1_General_CS_AI
    WHERE NOT EXISTS (
        SELECT 1 FROM publicidad.PiezaDeMercadoDeInteres pm
        WHERE pm.id_pieza = m.id_pieza AND pm.id_pais = p.id
    );

    -- Exhibiciones adicionales con las piezas nuevas (partidos de grupos con paneles libres)
    IF NOT EXISTS (SELECT 1 FROM publicidad.ExhibicionPublicitaria WHERE id_pieza IN (@pz_hisense, @pz_toyota, @pz_petro))
    BEGIN
        INSERT INTO publicidad.ExhibicionPublicitaria
            (id_partido, id_pieza, id_espacio_publicitario, id_moneda, costo_aplicado, fue_prime_time, estado, fecha_anulacion, motivo_anulacion)
        VALUES
            (@p_mx_pl, @pz_hisense, @pan1, @id_usd, 25000.00, 1, 'VIGENTE', NULL, NULL),
            (@p_mx_pl, @pz_toyota,  @pan2, @id_usd, 27500.00, 1, 'VIGENTE', NULL, NULL),
            (@p_mx_pl, @pz_coca,    @pan3, @id_usd, 25000.00, 1, 'VIGENTE', NULL, NULL),
            (@p_mx_pl, @pz_petro,   @pan4, @id_usd, 25000.00, 0, 'VIGENTE', NULL, NULL),

            (@p_de_jp, @pz_toyota,  @pan1, @id_usd, 25000.00, 0, 'VIGENTE', NULL, NULL),
            (@p_de_jp, @pz_hisense, @pan2, @id_usd, 25000.00, 0, 'VIGENTE', NULL, NULL),

            (@p_us_nl, @pz_toyota,  @pan3, @id_usd, 25000.00, 1, 'VIGENTE', NULL, NULL),
            (@p_us_nl, @pz_petro,   @pan4, @id_usd, 25000.00, 1, 'VIGENTE', NULL, NULL),

            (@p_fr_gb, @pz_hisense, @pan1, @id_usd, 25000.00, 0, 'VIGENTE', NULL, NULL),
            (@p_fr_gb, @pz_petro,   @pan2, @id_usd, 25000.00, 0, 'VIGENTE', NULL, NULL);
    END;

    PRINT 'OK - Anunciantes, campañas y exhibiciones adicionales cargados.';

    COMMIT TRANSACTION;

    
    PRINT '  CARGA MASIVA COMPLETADA Y PERSISTIDA EXITOSAMENTE (COMMIT)';
   

    -- Resumen rápido de conteo por tabla clave
    SELECT 'general.Pais'                  AS Tabla, COUNT(*) AS Registros FROM general.Pais UNION ALL
    SELECT 'general.Sede',                           COUNT(*) FROM general.Sede UNION ALL
    SELECT 'general.TipoCambio',                     COUNT(*) FROM general.TipoCambio UNION ALL
    SELECT 'deportivo.Seleccion',                    COUNT(*) FROM deportivo.Seleccion UNION ALL
    SELECT 'deportivo.Jugador',                      COUNT(*) FROM deportivo.Jugador UNION ALL
    SELECT 'deportivo.Partido',                      COUNT(*) FROM deportivo.Partido UNION ALL
    SELECT 'deportivo.Gol',                          COUNT(*) FROM deportivo.Gol UNION ALL
    SELECT 'deportivo.Tarjeta',                      COUNT(*) FROM deportivo.Tarjeta UNION ALL
    SELECT 'deportivo.Sancion',                      COUNT(*) FROM deportivo.Sancion UNION ALL
    SELECT 'arbitraje.Arbitro',                      COUNT(*) FROM arbitraje.Arbitro UNION ALL
    SELECT 'arbitraje.DesignacionArbitral',          COUNT(*) FROM arbitraje.DesignacionArbitral UNION ALL
    SELECT 'publicidad.Anunciante',                  COUNT(*) FROM publicidad.Anunciante UNION ALL
    SELECT 'publicidad.ExhibicionPublicitaria',      COUNT(*) FROM publicidad.ExhibicionPublicitaria;

    -- Verificación de mínimos del juego de datos (convocados >= 23 por selección, >= 16 selecciones, >= 6 países de anunciantes)
    SELECT
        sel.nombre AS Seleccion,
        COUNT(c.id) AS Convocados,
        CASE WHEN COUNT(c.id) >= 23 THEN 'OK' ELSE 'FALTAN' END AS Estado
    FROM deportivo.Seleccion sel
    LEFT JOIN deportivo.Convocatoria c ON c.id_seleccion = sel.id
    GROUP BY sel.nombre
    ORDER BY sel.nombre;

    SELECT
        (SELECT COUNT(*) FROM deportivo.Seleccion)                                   AS Selecciones,
        (SELECT COUNT(DISTINCT a.id_pais_origen)
           FROM publicidad.Anunciante a
           INNER JOIN publicidad.Campana ca ON ca.id_anunciante = a.id)              AS PaisesAnunciantesConCampana,
        (SELECT COUNT(DISTINCT huso_horario) FROM general.Sede)                      AS HusosHorariosSedes;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT 'ERROR CRÍTICO DURANTE LA CARGA MASIVA:';
    PRINT ERROR_MESSAGE();
    THROW;
END CATCH;
GO