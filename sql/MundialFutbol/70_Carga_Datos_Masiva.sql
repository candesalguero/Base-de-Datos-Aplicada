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
    MERGE general.Confederacion AS T
    USING (VALUES
        (1, 'CONMEBOL'),
        (2, 'UEFA'),
        (3, 'CONCACAF'),
        (4, 'CAF'),
        (5, 'AFC'),
        (6, 'OFC')
    ) AS S (id, nombre)
    ON T.id = S.id
    WHEN NOT MATCHED THEN INSERT (id, nombre) VALUES (S.id, S.nombre);

    -- 1.2 Países (Participantes + Países de árbitros + Mercados de interés)
    MERGE general.Pais AS T
    USING (VALUES
        (1,  'Argentina',       'AR', 'UTC-3',  1),
        (2,  'Brasil',          'BR', 'UTC-3',  1),
        (3,  'Uruguay',         'UY', 'UTC-3',  1),
        (4,  'Colombia',        'CO', 'UTC-5',  1),
        (5,  'Francia',         'FR', 'UTC+1',  2),
        (6,  'España',          'ES', 'UTC+1',  2),
        (7,  'Alemania',        'DE', 'UTC+1',  2),
        (8,  'Inglaterra',      'GB', 'UTC+0',  2),
        (9,  'Italia',          'IT', 'UTC+1',  2),
        (10, 'Países Bajos',    'NL', 'UTC+1',  2),
        (11, 'Croacia',         'HR', 'UTC+1',  2),
        (12, 'Polonia',         'PL', 'UTC+1',  2),
        (13, 'Estados Unidos',  'US', 'UTC-5',  3),
        (14, 'México',          'MX', 'UTC-6',  3),
        (15, 'Canadá',          'CA', 'UTC-5',  3),
        (16, 'Marruecos',       'MA', 'UTC+1',  4),
        (17, 'Senegal',         'SN', 'UTC+0',  4),
        (18, 'Qatar',           'QA', 'UTC+3',  5),
        (19, 'Japón',           'JP', 'UTC+9',  5),
        (20, 'Corea del Sur',   'KR', 'UTC+9',  5),
        (21, 'Australia',       'AU', 'UTC+10', 5),
        (22, 'Bélgica',         'BE', 'UTC+1',  2),
        (23, 'Suecia',          'SE', 'UTC+1',  2),
        (24, 'Rusia',           'RU', 'UTC+3',  2),
        (25, 'Suiza',           'CH', 'UTC+1',  2),
        (26, 'Hungría',         'HU', 'UTC+1',  2),
        (27, 'Eslovenia',       'SI', 'UTC+1',  2)
    ) AS S (id, nombre, ISO2, huso_horario, id_confederacion)
    ON T.ISO2 = S.ISO2 COLLATE Latin1_General_CS_AI
    WHEN NOT MATCHED THEN
        INSERT (id, nombre, ISO2, huso_horario, id_confederacion)
        VALUES (S.id, S.nombre, S.ISO2, S.huso_horario, S.id_confederacion);

    -- 1.3 Idiomas (ISO639 en minúsculas según ck_iso639)
    MERGE general.Idioma AS T
    USING (VALUES
        ('spa', 'Español'),
        ('eng', 'Inglés'),
        ('por', 'Portugués'),
        ('fra', 'Francés'),
        ('deu', 'Alemán'),
        ('ara', 'Árabe'),
        ('jpn', 'Japonés')
    ) AS S (ISO639, nombre)
    ON T.ISO639 = S.ISO639 COLLATE Latin1_General_CS_AI
    WHEN NOT MATCHED THEN INSERT (ISO639, nombre) VALUES (S.ISO639, S.nombre);

    -- 1.4 Monedas (ISO3 en mayúsculas según ck_iso3)
    MERGE general.Moneda AS T
    USING (VALUES
        (1, 'USD', 'Dólar Estadounidense'),
        (2, 'EUR', 'Euro'),
        (3, 'ARS', 'Peso Argentino'),
        (4, 'MXN', 'Peso Mexicano'),
        (5, 'GBP', 'Libra Esterlina')
    ) AS S (id, cod_iso3, nombre)
    ON T.cod_iso3 = S.cod_iso3 COLLATE Latin1_General_CS_AS
    WHEN NOT MATCHED THEN INSERT (id, cod_iso3, nombre) VALUES (S.id, S.cod_iso3, S.nombre);

    DECLARE @id_usd int = (SELECT id FROM general.Moneda WHERE cod_iso3 = 'USD');
    DECLARE @id_eur int = (SELECT id FROM general.Moneda WHERE cod_iso3 = 'EUR');
    DECLARE @id_ars int = (SELECT id FROM general.Moneda WHERE cod_iso3 = 'ARS');
    DECLARE @id_mxn int = (SELECT id FROM general.Moneda WHERE cod_iso3 = 'MXN');
    DECLARE @id_gbp int = (SELECT id FROM general.Moneda WHERE cod_iso3 = 'GBP');

    -- 1.5 Tipos de Cambio (para reportes de conversión de moneda)
    DECLARE @next_tc_id int = ISNULL((SELECT MAX(id) FROM general.TipoCambio), 0) + 1;

    IF NOT EXISTS (SELECT 1 FROM general.TipoCambio WHERE id_moneda_origen = @id_eur AND id_moneda_destino = @id_usd AND fecha = '2026-11-10')
    BEGIN
        INSERT INTO general.TipoCambio (id, id_moneda_origen, id_moneda_destino, fecha, tipo_cambio)
        VALUES
            (@next_tc_id,     @id_eur, @id_usd, '2026-11-10', 1.095000),
            (@next_tc_id + 1, @id_usd, @id_eur, '2026-11-10', 0.913242),
            (@next_tc_id + 2, @id_usd, @id_ars, '2026-11-10', 1050.000000),
            (@next_tc_id + 3, @id_ars, @id_usd, '2026-11-10', 0.000952),
            (@next_tc_id + 4, @id_eur, @id_ars, '2026-11-10', 1149.750000),
            (@next_tc_id + 5, @id_usd, @id_mxn, '2026-11-10', 19.850000),
            (@next_tc_id + 6, @id_mxn, @id_usd, '2026-11-10', 0.050378),
            (@next_tc_id + 7, @id_gbp, @id_usd, '2026-11-10', 1.285000);
    END;

    -- 1.6 Indicadores Económicos (PBI para priorización de mercados)
    MERGE general.IndicadorEconomico AS T
    USING (
        SELECT p.id AS id_pais, 2025 AS anio, v.pbi, CAST('2026-11-01' AS date) AS fecha_actualizacion
        FROM (VALUES
            ('US', 28780000.00),
            ('DE',  4590000.00),
            ('JP',  4110000.00),
            ('GB',  3500000.00),
            ('FR',  3130000.00),
            ('BR',  2330000.00),
            ('MX',  2010000.00),
            ('ES',  1650000.00),
            ('AR',   640000.00),
            ('QA',   220000.00)
        ) AS v(iso2, pbi)
        INNER JOIN general.Pais p ON p.ISO2 = v.iso2 COLLATE Latin1_General_CS_AI
    ) AS S
    ON T.id_pais = S.id_pais AND T.anio = S.anio
    WHEN NOT MATCHED THEN
        INSERT (anio, id_pais, pbi, fecha_actualizacion)
        VALUES (S.anio, S.id_pais, S.pbi, S.fecha_actualizacion);

    -- 1.7 Fases del Torneo
    MERGE general.Fase AS T
    USING (VALUES
        (1, 'grupos',          1, 0),
        (2, 'octavos',         2, 1),
        (3, 'cuartos',         3, 1),
        (4, 'semifinales',     4, 1),
        (5, 'tercer_puesto',   5, 1),
        (6, 'final',           6, 1)
    ) AS S (id, nombre, orden, es_eliminacion_directa)
    ON T.id = S.id
    WHEN NOT MATCHED THEN
        INSERT (id, nombre, orden, es_eliminacion_directa)
        VALUES (S.id, S.nombre, S.orden, S.es_eliminacion_directa);

    -- 1.8 Sedes (Estadios)
    DECLARE @p_us int = (SELECT id FROM general.Pais WHERE ISO2 = 'US');
    DECLARE @p_mx int = (SELECT id FROM general.Pais WHERE ISO2 = 'MX');
    DECLARE @p_ca int = (SELECT id FROM general.Pais WHERE ISO2 = 'CA');
    DECLARE @p_qa int = (SELECT id FROM general.Pais WHERE ISO2 = 'QA');

    MERGE general.Sede AS T
    USING (VALUES
        (1, @p_us, N'MetLife Stadium',      N'New Jersey',   82500, 'UTC-5'),
        (2, @p_us, N'SoFi Stadium',         N'Los Ángeles',  70240, 'UTC-8'),
        (3, @p_us, N'AT&T Stadium',         N'Dallas',       80000, 'UTC-6'),
        (4, @p_us, N'Hard Rock Stadium',    N'Miami',        65326, 'UTC-5'),
        (5, @p_mx, N'Estadio Azteca',       N'Ciudad México',87523, 'UTC-6'),
        (6, @p_ca, N'BMO Field',            N'Toronto',      45736, 'UTC-5'),
        (7, @p_qa, N'Lusail Stadium',       N'Lusail',       88966, 'UTC+3'),
        (8, @p_qa, N'Al Bayt Stadium',      N'Al Khor',      68895, 'UTC+3')
    ) AS S (id, id_pais, nombre_estadio, ciudad, capacidad, huso_horario)
    ON T.nombre_estadio = S.nombre_estadio
    WHEN NOT MATCHED THEN
        INSERT (id, id_pais, nombre_estadio, ciudad, capacidad, huso_horario)
        VALUES (S.id, S.id_pais, S.nombre_estadio, S.ciudad, S.capacidad, S.huso_horario);

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

    -- Insertar 12 partidos  pensados para probar Prime Time en distintos mercados
    IF NOT EXISTS (SELECT 1 FROM deportivo.Partido WHERE id_seleccion_local = @s_ar AND id_seleccion_visitante = @s_mx)
    BEGIN
        INSERT INTO deportivo.Partido (id_sede, id_fase, id_seleccion_local, id_seleccion_visitante, fecha_hora_local, fecha_hora_utc, goles_local, goles_visitante, asistencia_publico)
        VALUES
            -- Fase de Grupos (fase = 1)
            (@st_sofi,    1, @s_us, @s_nl, '2026-06-12 18:00:00', '2026-06-13 02:00:00', 1, 2, 68500), -- P1: Prime time US/AR
            (@st_azteca,  1, @s_mx, @s_pl, '2026-06-13 19:00:00', '2026-06-14 01:00:00', 2, 1, 86200), -- P2: Prime time MX/US/AR
            (@st_att,     1, @s_ar, @s_pl, '2026-06-14 17:00:00', '2026-06-14 23:00:00', 3, 1, 79100), -- P3: Prime time AR (20hs)
            (@st_miami,   1, @s_ar, @s_mx, '2026-06-18 20:00:00', '2026-06-19 01:00:00', 2, 0, 65000), -- P4: Prime time AR (22hs) y US
            (@st_metlife, 1, @s_es, @s_de, '2026-06-15 15:00:00', '2026-06-15 20:00:00', 2, 2, 81400), -- P5: Prime time ES/DE (21hs)
            (@st_sofi,    1, @s_de, @s_jp, '2026-06-19 12:00:00', '2026-06-19 20:00:00', 1, 2, 67000), -- P6: Prime time DE (21hs)
            (@st_att,     1, @s_br, @s_ma, '2026-06-16 18:00:00', '2026-06-17 00:00:00', 3, 1, 78900), -- P7: Prime time BR (21hs)
            (@st_miami,   1, @s_fr, @s_gb, '2026-06-17 15:00:00', '2026-06-17 20:00:00', 2, 1, 64800), -- P8: Prime time FR (21hs) y GB (20hs)
            -- Cuartos de Final (fase = 3)
            (@st_att,     3, @s_ar, @s_nl, '2026-07-04 18:00:00', '2026-07-05 00:00:00', 3, 2, 80000), -- P9
            (@st_metlife, 3, @s_fr, @s_es, '2026-07-05 15:00:00', '2026-07-05 20:00:00', 2, 1, 82500), -- P10
            -- Semifinal (fase = 4)
            (@st_lusail,  4, @s_ar, @s_br, '2026-07-14 21:00:00', '2026-07-14 18:00:00', 2, 1, 88900), -- P11
            -- Final (fase = 6)
            (@st_metlife, 6, @s_ar, @s_fr, '2026-07-19 16:00:00', '2026-07-19 21:00:00', 3, 3, 82500); -- P12
    END;

    -- Capturar IDs de los partidos cargados
    DECLARE @p_ar_pl int = (SELECT TOP 1 id FROM deportivo.Partido WHERE id_seleccion_local = @s_ar AND id_seleccion_visitante = @s_pl);
    DECLARE @p_ar_mx int = (SELECT TOP 1 id FROM deportivo.Partido WHERE id_seleccion_local = @s_ar AND id_seleccion_visitante = @s_mx);
    DECLARE @p_es_de int = (SELECT TOP 1 id FROM deportivo.Partido WHERE id_seleccion_local = @s_es AND id_seleccion_visitante = @s_de);
    DECLARE @p_br_ma int = (SELECT TOP 1 id FROM deportivo.Partido WHERE id_seleccion_local = @s_br AND id_seleccion_visitante = @s_ma);
    DECLARE @p_fr_gb int = (SELECT TOP 1 id FROM deportivo.Partido WHERE id_seleccion_local = @s_fr AND id_seleccion_visitante = @s_gb);
    DECLARE @p_ar_nl int = (SELECT TOP 1 id FROM deportivo.Partido WHERE id_seleccion_local = @s_ar AND id_seleccion_visitante = @s_nl);
    DECLARE @p_fr_es int = (SELECT TOP 1 id FROM deportivo.Partido WHERE id_seleccion_local = @s_fr AND id_seleccion_visitante = @s_es);
    DECLARE @p_ar_br int = (SELECT TOP 1 id FROM deportivo.Partido WHERE id_seleccion_local = @s_ar AND id_seleccion_visitante = @s_br);
    DECLARE @p_ar_fr int = (SELECT TOP 1 id FROM deportivo.Partido WHERE id_seleccion_local = @s_ar AND id_seleccion_visitante = @s_fr);
    DECLARE @p_mx_pl int = (SELECT TOP 1 id FROM deportivo.Partido WHERE id_seleccion_local = @s_mx AND id_seleccion_visitante = @s_pl);
    DECLARE @p_us_nl int = (SELECT TOP 1 id FROM deportivo.Partido WHERE id_seleccion_local = @s_us AND id_seleccion_visitante = @s_nl);
    DECLARE @p_de_jp int = (SELECT TOP 1 id FROM deportivo.Partido WHERE id_seleccion_local = @s_de AND id_seleccion_visitante = @s_jp);

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
    MERGE arbitraje.RolArbitral AS T
    USING (VALUES
        (1, 'Árbitro Principal'),
        (2, 'Árbitro Asistente 1'),
        (3, 'Árbitro Asistente 2'),
        (4, 'Cuarto Árbitro'),
        (5, 'VAR')
    ) AS S (id, nombre)
    ON T.id = S.id
    WHEN NOT MATCHED THEN INSERT (id, nombre) VALUES (S.id, S.nombre);

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
            (@next_des_id,     @p_ar_fr, @arb_marciniak, 1, 'Confirmada', NULL),
            (@next_des_id + 1, @p_ar_fr, @arb_vincic,    5, 'Confirmada', NULL),
            (@next_des_id + 2, @p_ar_br, @arb_collina,   1, 'Confirmada', NULL),
            (@next_des_id + 3, @p_ar_nl, @arb_webb,      1, 'Confirmada', NULL),
            (@next_des_id + 4, @p_fr_es, @arb_pitana,    1, 'Confirmada', NULL),
            (@next_des_id + 5, @p_es_de, @arb_rizzoli,   1, 'Confirmada', NULL),
            (@next_des_id + 6, @p_br_ma, @arb_elizondo,  1, 'Confirmada', NULL),
            (@next_des_id + 7, @p_ar_pl, @arb_codesal,   1, 'Confirmada', NULL);

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