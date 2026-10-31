/*
    Universidad: Universidad Nacional de La Matanza
    Materia: Bases de Datos Aplicada
    Integrantes:
        - Salguero, Candela
        - Ocaranza, Lucila
        - Dimattia Damm, Malena
        - Fuentes, Martina Alejandra

    Fecha: Octubre 2026

    Objetivo:
    Importar partidos desde el archivo matches.csv.

    El procedimiento:
    - carga el archivo en una tabla staging;
    - valida cada registro;
    - transforma los datos;
    - realiza INSERT o UPDATE según corresponda;
    - evita duplicados;
    - registra los errores;
    - genera el LogImportacion correspondiente.
*/

USE MundialFutbol;
GO


CREATE OR ALTER PROCEDURE integracion.usp_ImportarPartidosCSV
    @id_log int,
    @id_fuente int,
    @ruta_archivo nvarchar(1000),
    @nombre_archivo varchar(255)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores nvarchar(2047) = N'';
    DECLARE @sql nvarchar(max);

    DECLARE @insertados int = 0;
    DECLARE @actualizados int = 0;

    DECLARE @fila int = 1;

    DECLARE @next_error_id int;

    SELECT
        @next_error_id = ISNULL(MAX(id), 0) + 1
    FROM integracion.DetalleErrorImportacion;


    /* ============================================================
       VALIDACIONES GENERALES
       ============================================================ */

    SET @ruta_archivo = LTRIM(RTRIM(@ruta_archivo));
    SET @nombre_archivo = LTRIM(RTRIM(@nombre_archivo));


    IF @id_log IS NULL OR @id_log <= 0
        SET @errores +=
            N'- El id del log debe ser mayor a cero.'
            + NCHAR(13) + NCHAR(10);


    IF @id_fuente IS NULL
       OR NOT EXISTS (
            SELECT 1
            FROM integracion.FuenteDatos
            WHERE id = @id_fuente
       )
        SET @errores +=
            N'- La fuente de datos indicada no existe.'
            + NCHAR(13) + NCHAR(10);


    IF @ruta_archivo IS NULL OR @ruta_archivo = ''
        SET @errores +=
            N'- La ruta del archivo es obligatoria.'
            + NCHAR(13) + NCHAR(10);


    IF @nombre_archivo IS NULL OR @nombre_archivo = ''
        SET @errores +=
            N'- El nombre del archivo es obligatorio.'
            + NCHAR(13) + NCHAR(10);


    IF EXISTS (
        SELECT 1
        FROM integracion.LogImportacion
        WHERE id = @id_log
    )
        SET @errores +=
            N'- Ya existe un log con el id indicado.'
            + NCHAR(13) + NCHAR(10);


    IF @errores <> N''
        THROW 50000, @errores, 1;



    /* ============================================================
       TABLA AUXILIAR DE ERRORES
       ============================================================ */

    DECLARE @errores_importacion TABLE
    (
        id int,
        fila int,
        error varchar(500)
    );



    /* ============================================================
       LIMPIAR STAGING
       ============================================================ */

    TRUNCATE TABLE integracion.StagingPartidoCSV;



    /* ============================================================
       CARGAR CSV EN STAGING
       ============================================================

       BULK INSERT exige que la ruta sea un literal.
       Por eso esta es la única parte que necesita SQL dinámico.
       ============================================================ */

    SET @sql =
    N'BULK INSERT integracion.StagingPartidoCSV
      FROM '''
    + REPLACE(@ruta_archivo, '''', '''''')
    + N'''
      WITH
      (
          FORMAT = ''CSV'',
          FIRSTROW = 2,
          FIELDQUOTE = ''"'',
          FIELDTERMINATOR = '','',
          ROWTERMINATOR = ''0x0a'',
          CODEPAGE = ''65001'',
          TABLOCK
      );';


    BEGIN TRY

        EXEC sys.sp_executesql @sql;

    END TRY
    BEGIN CATCH

        INSERT INTO @errores_importacion
        (
            id,
            fila,
            error
        )
        VALUES
        (
            @next_error_id,
            1,
            LEFT(ERROR_MESSAGE(), 500)
        );

        SET @next_error_id = @next_error_id + 1;


        DECLARE @xml_error_carga xml;

        SELECT
            @xml_error_carga =
            (
                SELECT
                    id AS [@id],
                    fila AS [@fila],
                    error AS [text()]
                FROM @errores_importacion
                FOR XML PATH('error'), ROOT('errores')
            );


        EXEC integracion.usp_RegistrarResultadoImportacion
            @id_log = @id_log,
            @id_fuente = @id_fuente,
            @archivo = @nombre_archivo,
            @registros_correctos = 0,
            @errores_xml = @xml_error_carga;


        RETURN;

    END CATCH;



    /* ============================================================
       VARIABLES PARA PROCESAR CADA PARTIDO
       ============================================================ */

    DECLARE @match_id varchar(100);
    DECLARE @stage_name nvarchar(100);

    DECLARE @match_date varchar(50);
    DECLARE @match_time varchar(50);

    DECLARE @stadium_name nvarchar(200);

    DECLARE @home_team_name nvarchar(150);
    DECLARE @away_team_name nvarchar(150);

    DECLARE @home_team_score varchar(20);
    DECLARE @away_team_score varchar(20);


    /* Datos convertidos */

    DECLARE @id_sede int;
    DECLARE @id_fase int;
    DECLARE @fase_normalizada varchar(30);

    DECLARE @id_local int;
    DECLARE @id_visitante int;

    DECLARE @fecha_local datetime;
    DECLARE @fecha_utc datetime;

    DECLARE @goles_local tinyint;
    DECLARE @goles_visitante tinyint;

    DECLARE @huso_horario varchar(50);
    DECLARE @offset_horas int;

    DECLARE @id_partido int;

    DECLARE @error_fila nvarchar(2047);



    /* ============================================================
       CURSOR SOBRE STAGING
       ============================================================ */

    DECLARE cur_partidos CURSOR LOCAL FAST_FORWARD FOR

        SELECT
            match_id,
            stage_name,
            match_date,
            match_time,
            stadium_name,
            home_team_name,
            away_team_name,
            home_team_score,
            away_team_score
        FROM integracion.StagingPartidoCSV;


    OPEN cur_partidos;


    FETCH NEXT FROM cur_partidos INTO
        @match_id,
        @stage_name,
        @match_date,
        @match_time,
        @stadium_name,
        @home_team_name,
        @away_team_name,
        @home_team_score,
        @away_team_score;



    WHILE @@FETCH_STATUS = 0
    BEGIN

        SET @fila = @fila + 1;

        SET @error_fila = N'';

        SET @id_sede = NULL;
        SET @id_fase = NULL;

        SET @id_local = NULL;
        SET @id_visitante = NULL;

        SET @fecha_local = NULL;
        SET @fecha_utc = NULL;

        SET @goles_local = NULL;
        SET @goles_visitante = NULL;

        SET @huso_horario = NULL;
        SET @offset_horas = NULL;

        SET @id_partido = NULL;



        /* ========================================================
           SEDE
           ======================================================== */

        SELECT TOP 1
            @id_sede = id,
            @huso_horario = huso_horario
        FROM general.Sede
        WHERE UPPER(LTRIM(RTRIM(nombre_estadio)))
            = UPPER(LTRIM(RTRIM(@stadium_name)));


        IF @id_sede IS NULL
            SET @error_fila +=
                N'- No existe la sede: '
                + ISNULL(@stadium_name, 'NULL')
                + N'. ';


/* ========================================================
   FASE
   ======================================================== */

SET @fase_normalizada =
    CASE LOWER(LTRIM(RTRIM(@stage_name)))
        WHEN 'group stage'       THEN 'grupos'
        WHEN 'second group stage' THEN 'grupos'
        WHEN 'round of 16'       THEN 'octavos'
        WHEN 'quarter-final'     THEN 'cuartos'
        WHEN 'quarter-finals'    THEN 'cuartos'
        WHEN 'semi-final'        THEN 'semifinales'
        WHEN 'semi-finals'       THEN 'semifinales'
        WHEN 'third-place match' THEN 'tercer puesto'
        WHEN 'final'             THEN 'final'
        ELSE NULL
    END;


IF @fase_normalizada IS NULL
BEGIN

    SET @error_fila +=
        N'- La fase externa no tiene equivalencia: '
        + ISNULL(@stage_name, 'NULL')
        + N'. ';

END
ELSE
BEGIN

    SELECT TOP 1
        @id_fase = id
    FROM general.Fase
    WHERE LOWER(LTRIM(RTRIM(nombre)))
        = LOWER(@fase_normalizada);


    IF @id_fase IS NULL
        SET @error_fila +=
            N'- No existe la fase en la base: '
            + @fase_normalizada
            + N'. ';

END;

        /* ========================================================
           SELECCIÓN LOCAL
           ======================================================== */

        SELECT TOP 1
            @id_local = id
        FROM deportivo.Seleccion
        WHERE UPPER(LTRIM(RTRIM(nombre)))
            = UPPER(LTRIM(RTRIM(@home_team_name)));


        IF @id_local IS NULL
            SET @error_fila +=
                N'- No existe la selección local: '
                + ISNULL(@home_team_name, 'NULL')
                + N'. ';



        /* ========================================================
           SELECCIÓN VISITANTE
           ======================================================== */

        SELECT TOP 1
            @id_visitante = id
        FROM deportivo.Seleccion
        WHERE UPPER(LTRIM(RTRIM(nombre)))
            = UPPER(LTRIM(RTRIM(@away_team_name)));


        IF @id_visitante IS NULL
            SET @error_fila +=
                N'- No existe la selección visitante: '
                + ISNULL(@away_team_name, 'NULL')
                + N'. ';



        /* ========================================================
           FECHA Y HORA
           ======================================================== */

        SET @fecha_local =
            TRY_CONVERT(
                datetime,
                CONCAT(
                    LTRIM(RTRIM(@match_date)),
                    ' ',
                    LTRIM(RTRIM(@match_time))
                )
            );


        IF @fecha_local IS NULL
            SET @error_fila +=
                N'- Fecha u hora inválida. ';



        /* ========================================================
           GOLES
           ======================================================== */

        SET @goles_local =
            TRY_CONVERT(tinyint, @home_team_score);


        SET @goles_visitante =
            TRY_CONVERT(tinyint, @away_team_score);


        IF @goles_local IS NULL
            SET @error_fila +=
                N'- Cantidad de goles local inválida. ';


        IF @goles_visitante IS NULL
            SET @error_fila +=
                N'- Cantidad de goles visitante inválida. ';



        /* ========================================================
           CONVERTIR HORA LOCAL A UTC
           ======================================================== */

        IF @huso_horario IS NOT NULL
        BEGIN

            IF UPPER(@huso_horario) = 'UTC'
                SET @offset_horas = 0;

            ELSE
                SET @offset_horas =
                    TRY_CONVERT(
                        int,
                        REPLACE(
                            UPPER(@huso_horario),
                            'UTC',
                            ''
                        )
                    );


            IF @offset_horas IS NULL
                SET @error_fila +=
                    N'- Huso horario inválido para la sede. ';

            ELSE IF @fecha_local IS NOT NULL
                SET @fecha_utc =
                    DATEADD(
                        HOUR,
                        -@offset_horas,
                        @fecha_local
                    );

        END;



        /* ========================================================
           SI LA FILA TIENE ERRORES
           ======================================================== */

        IF @error_fila <> N''
        BEGIN

            INSERT INTO @errores_importacion
            (
                id,
                fila,
                error
            )
            VALUES
            (
                @next_error_id,
                @fila,
                LEFT(@error_fila, 500)
            );


            SET @next_error_id = @next_error_id + 1;

        END

        ELSE
        BEGIN

            /* ====================================================
               UPSERT
               ==================================================== */

            BEGIN TRY

                /*
                    Buscamos si el partido ya existe.

                    La combinación usada es:
                    - selección local
                    - selección visitante
                    - fecha/hora local
                */

                SELECT TOP 1
                    @id_partido = id
                FROM deportivo.Partido
                WHERE id_seleccion_local = @id_local
                  AND id_seleccion_visitante = @id_visitante
                  AND fecha_hora_local = @fecha_local;



                /* =========================
                   UPDATE
                   ========================= */

                IF @id_partido IS NOT NULL
                BEGIN

                    EXEC deportivo.usp_Partido_Actualizar
                        @id = @id_partido,
                        @id_sede = @id_sede,
                        @id_fase = @id_fase,
                        @id_seleccion_local = @id_local,
                        @id_seleccion_visitante = @id_visitante,
                        @fecha_hora_local = @fecha_local,
                        @fecha_hora_utc = @fecha_utc,
                        @goles_local = @goles_local,
                        @goles_visitante = @goles_visitante,
                        @asistencia_publico = NULL;


                    SET @actualizados =
                        @actualizados + 1;

                END


                /* =========================
                   INSERT
                   ========================= */

                ELSE
                BEGIN

                    DECLARE @nuevo_id_partido int;


                    EXEC deportivo.usp_Partido_Insertar
                        @id_sede = @id_sede,
                        @id_fase = @id_fase,
                        @id_seleccion_local = @id_local,
                        @id_seleccion_visitante = @id_visitante,
                        @fecha_hora_local = @fecha_local,
                        @fecha_hora_utc = @fecha_utc,
                        @goles_local = @goles_local,
                        @goles_visitante = @goles_visitante,
                        @asistencia_publico = NULL,
                        @id_partido = @nuevo_id_partido OUTPUT;


                    SET @insertados =
                        @insertados + 1;

                END;

            END TRY
            BEGIN CATCH

                INSERT INTO @errores_importacion
                (
                    id,
                    fila,
                    error
                )
                VALUES
                (
                    @next_error_id,
                    @fila,
                    LEFT(ERROR_MESSAGE(), 500)
                );


                SET @next_error_id =
                    @next_error_id + 1;

            END CATCH;

        END;



        FETCH NEXT FROM cur_partidos INTO
            @match_id,
            @stage_name,
            @match_date,
            @match_time,
            @stadium_name,
            @home_team_name,
            @away_team_name,
            @home_team_score,
            @away_team_score;

    END;



    CLOSE cur_partidos;
    DEALLOCATE cur_partidos;



    /* ============================================================
       GENERAR XML DE ERRORES
       ============================================================ */

    DECLARE @errores_xml xml;


    IF EXISTS (
        SELECT 1
        FROM @errores_importacion
    )
    BEGIN

        SELECT
            @errores_xml =
            (
                SELECT
                    id AS [@id],
                    fila AS [@fila],
                    error AS [text()]
                FROM @errores_importacion
                ORDER BY fila
                FOR XML PATH('error'), ROOT('errores')
            );

    END;



    /* ============================================================
       REGISTRAR RESULTADO GENERAL
       ============================================================ */

    DECLARE @correctos int =
        @insertados + @actualizados;


    EXEC integracion.usp_RegistrarResultadoImportacion
        @id_log = @id_log,
        @id_fuente = @id_fuente,
        @archivo = @nombre_archivo,
        @registros_correctos = @correctos,
        @errores_xml = @errores_xml;



    /* ============================================================
       RESULTADO PARA EL USUARIO
       ============================================================ */

    SELECT
        @insertados AS insertados,
        @actualizados AS actualizados,
        (
            SELECT COUNT(*)
            FROM @errores_importacion
        ) AS errores;


    SELECT
        fila,
        error
    FROM @errores_importacion
    ORDER BY fila;

END;
GO