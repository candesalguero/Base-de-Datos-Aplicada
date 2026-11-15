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
        ('jpn', 'Japonés')
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

    -- 2.3 Selecciones (12 selecciones distribuidas en grupos A a F)
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
        ('BR', 'Brasil',         'G')
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
        ('Polonia',        N'Michał',    N'Probierz',    '1972-09-24', 'DT-PL-001')
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
        ('Polonia', 'PL', N'Robert',     N'Lewandowski', '1988-08-21', 'JUG-PL-09',  9, 'Delantero',     'FC Barcelona');

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
        ('CN', 'CN-9137020016','Hisense Group')
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

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT 'ERROR CRÍTICO DURANTE LA CARGA MASIVA:';
    PRINT ERROR_MESSAGE();
    THROW;
END CATCH;
GO