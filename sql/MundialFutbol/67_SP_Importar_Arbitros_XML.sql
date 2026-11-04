/*
    Importación acumulativa de árbitros desde XML.
    La clave lógica usada para el upsert es país + nombre + apellido.
*/

USE MundialFutbol;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE integracion.usp_ImportarArbitrosXML
    @id_log int,
    @id_fuente int,
    @ruta_archivo nvarchar(1000),
    @nombre_archivo varchar(255)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores nvarchar(2047) = N'';
    DECLARE @sql nvarchar(max);
    DECLARE @documento xml;
    DECLARE @insertados int = 0;
    DECLARE @actualizados int = 0;
    DECLARE @next_error_id int;

    DECLARE @errores_importacion TABLE
    (
        id int NOT NULL,
        fila int NOT NULL,
        error varchar(500) NOT NULL
    );

    SELECT @next_error_id = ISNULL(MAX(id), 0) + 1
    FROM integracion.DetalleErrorImportacion;

    SET @ruta_archivo = LTRIM(RTRIM(@ruta_archivo));
    SET @nombre_archivo = LTRIM(RTRIM(@nombre_archivo));

    IF @id_log IS NULL OR @id_log <= 0
        SET @errores += N'- El id del log debe ser mayor a cero.' + NCHAR(13) + NCHAR(10);
    IF @id_fuente IS NULL OR NOT EXISTS (
        SELECT 1 FROM integracion.FuenteDatos WHERE id = @id_fuente
    )
        SET @errores += N'- La fuente de datos indicada no existe.' + NCHAR(13) + NCHAR(10);
    IF @ruta_archivo IS NULL OR @ruta_archivo = ''
        SET @errores += N'- La ruta del archivo es obligatoria.' + NCHAR(13) + NCHAR(10);
    IF @nombre_archivo IS NULL OR @nombre_archivo = ''
        SET @errores += N'- El nombre del archivo es obligatorio.' + NCHAR(13) + NCHAR(10);
    IF EXISTS (SELECT 1 FROM integracion.LogImportacion WHERE id = @id_log)
        SET @errores += N'- Ya existe un log con el id indicado.' + NCHAR(13) + NCHAR(10);

    IF @errores <> N''
        THROW 50000, @errores, 1;

    TRUNCATE TABLE integracion.StagingArbitroXML;

    BEGIN TRY
        SET @sql =
            N'SELECT BulkColumn
              FROM OPENROWSET(BULK '''
            + REPLACE(@ruta_archivo, '''', '''''')
            + N''', SINGLE_BLOB) AS archivo;';

        DECLARE @contenido TABLE (contenido varbinary(max));
        INSERT INTO @contenido EXEC sys.sp_executesql @sql;
        SELECT @documento = TRY_CONVERT(xml, contenido)
        FROM @contenido;

        IF @documento IS NULL
        BEGIN
            INSERT INTO @errores_importacion (id, fila, error)
            VALUES (@next_error_id, 1, 'El archivo no contiene XML bien formado.');
            SET @next_error_id += 1;
        END
        ELSE
        BEGIN
            INSERT INTO integracion.StagingArbitroXML
                (nombre, apellido, pais_iso2, categoria)
            SELECT
                NULLIF(LTRIM(RTRIM(T.N.value('(nombre[1])[1]', 'nvarchar(100)'))), ''),
                NULLIF(LTRIM(RTRIM(T.N.value('(apellido[1])[1]', 'nvarchar(100)'))), ''),
                NULLIF(UPPER(LTRIM(RTRIM(T.N.value('(pais_iso2[1])[1]', 'varchar(2)')))), ''),
                NULLIF(LTRIM(RTRIM(T.N.value('(categoria[1])[1]', 'nvarchar(50)'))), '')
            FROM @documento.nodes('/arbitros/arbitro') AS T(N);

            IF NOT EXISTS (SELECT 1 FROM integracion.StagingArbitroXML)
            BEGIN
                INSERT INTO @errores_importacion (id, fila, error)
                VALUES (@next_error_id, 1, 'El XML no contiene elementos <arbitro>.');
                SET @next_error_id += 1;
            END
        END
    END TRY
    BEGIN CATCH
        INSERT INTO @errores_importacion (id, fila, error)
        VALUES (@next_error_id, 1, LEFT(ERROR_MESSAGE(), 500));
        SET @next_error_id += 1;
    END CATCH;

    /* Validaciones set-based: todas las causas de una fila se acumulan. */
    INSERT INTO @errores_importacion (id, fila, error)
    SELECT
        @next_error_id + ROW_NUMBER() OVER (ORDER BY s.fila) - 1,
        s.fila,
        LEFT(CONCAT(
            CASE WHEN s.nombre IS NULL THEN '- El nombre es obligatorio. ' ELSE '' END,
            CASE WHEN s.apellido IS NULL THEN '- El apellido es obligatorio. ' ELSE '' END,
            CASE WHEN s.categoria IS NULL THEN '- La categoría es obligatoria. ' ELSE '' END,
            CASE WHEN s.pais_iso2 IS NULL OR s.pais_iso2 NOT LIKE '[A-Z][A-Z]'
                 THEN '- El ISO2 del país es inválido. ' ELSE '' END,
            CASE WHEN s.pais_iso2 IS NOT NULL AND p.id IS NULL
                 THEN '- No existe un país con el ISO2 indicado. ' ELSE '' END,
            CASE WHEN d.fila IS NOT NULL
                 THEN '- La clave lógica está repetida dentro del XML. ' ELSE '' END
        ), 500)
    FROM integracion.StagingArbitroXML AS s
    LEFT JOIN general.Pais AS p
        ON p.ISO2 = s.pais_iso2 COLLATE Latin1_General_CS_AI
    OUTER APPLY (
        SELECT TOP (1) s2.fila
        FROM integracion.StagingArbitroXML AS s2
        WHERE s2.fila < s.fila
          AND UPPER(LTRIM(RTRIM(s2.nombre))) = UPPER(LTRIM(RTRIM(s.nombre)))
          AND UPPER(LTRIM(RTRIM(s2.apellido))) = UPPER(LTRIM(RTRIM(s.apellido)))
          AND s2.pais_iso2 = s.pais_iso2
    ) AS d
    WHERE s.nombre IS NULL
       OR s.apellido IS NULL
       OR s.categoria IS NULL
       OR s.pais_iso2 IS NULL
       OR s.pais_iso2 NOT LIKE '[A-Z][A-Z]'
       OR (s.pais_iso2 IS NOT NULL AND p.id IS NULL)
       OR d.fila IS NOT NULL;

    SELECT @next_error_id = ISNULL(MAX(id), @next_error_id - 1) + 1
    FROM @errores_importacion;

    DECLARE @arbitros_validos TABLE
    (
        fila int NOT NULL PRIMARY KEY,
        nombre nvarchar(100) NOT NULL,
        apellido nvarchar(100) NOT NULL,
        categoria nvarchar(50) NOT NULL,
        id_pais int NOT NULL,
        id_arbitro int NULL,
        nuevo_id int NULL
    );

    INSERT INTO @arbitros_validos
    (
        fila,
        nombre,
        apellido,
        categoria,
        id_pais,
        id_arbitro
    )
    SELECT
        s.fila,
        s.nombre,
        s.apellido,
        s.categoria,
        p.id,
        existente.id
    FROM integracion.StagingArbitroXML AS s
    INNER JOIN general.Pais AS p
        ON p.ISO2 = s.pais_iso2 COLLATE Latin1_General_CS_AI
    OUTER APPLY
    (
        SELECT TOP (1)
            a.id
        FROM arbitraje.Arbitro AS a
        WHERE a.id_pais = p.id
          AND UPPER(LTRIM(RTRIM(a.nombre))) = UPPER(LTRIM(RTRIM(s.nombre)))
          AND UPPER(LTRIM(RTRIM(a.apellido))) = UPPER(LTRIM(RTRIM(s.apellido)))
        ORDER BY a.id
    ) AS existente
    WHERE s.nombre IS NOT NULL
      AND s.apellido IS NOT NULL
      AND s.categoria IS NOT NULL
      AND s.pais_iso2 LIKE '[A-Z][A-Z]'
      AND NOT EXISTS
      (
          SELECT 1
          FROM @errores_importacion AS e
          WHERE e.fila = s.fila
      );

    SELECT @next_error_id = ISNULL(MAX(id), @next_error_id - 1) + 1
    FROM @errores_importacion;

    BEGIN TRY
        UPDATE arbitraje.Arbitro
        SET nombre = v.nombre,
            apellido = v.apellido,
            categoria = v.categoria,
            id_pais = v.id_pais
        FROM arbitraje.Arbitro AS a
        INNER JOIN @arbitros_validos AS v
            ON v.id_arbitro = a.id;

        SET @actualizados = @@ROWCOUNT;

        DECLARE @max_id_arbitro int;

        SELECT @max_id_arbitro = ISNULL(MAX(id), 0)
        FROM arbitraje.Arbitro;

        UPDATE v
        SET nuevo_id = @max_id_arbitro + numerados.numero
        FROM @arbitros_validos AS v
        INNER JOIN
        (
            SELECT
                fila,
                ROW_NUMBER() OVER (ORDER BY fila) AS numero
            FROM @arbitros_validos
            WHERE id_arbitro IS NULL
        ) AS numerados
            ON numerados.fila = v.fila;

        INSERT INTO arbitraje.Arbitro
        (
            id,
            nombre,
            apellido,
            categoria,
            id_pais
        )
        SELECT
            nuevo_id,
            nombre,
            apellido,
            categoria,
            id_pais
        FROM @arbitros_validos
        WHERE id_arbitro IS NULL;

        SET @insertados = @@ROWCOUNT;
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
    END CATCH;

    DECLARE @errores_xml xml = NULL;
    IF EXISTS (SELECT 1 FROM @errores_importacion)
    BEGIN
        SELECT @errores_xml = (
            SELECT id AS [@id], fila AS [@fila], error AS [text()]
            FROM @errores_importacion
            ORDER BY fila, id
            FOR XML PATH('error'), ROOT('errores')
        );
    END;

    DECLARE @registros_correctos int = @insertados + @actualizados;

    EXEC integracion.usp_RegistrarResultadoImportacion
        @id_log = @id_log,
        @id_fuente = @id_fuente,
        @archivo = @nombre_archivo,
        @registros_correctos = @registros_correctos,
        @errores_xml = @errores_xml;

    SELECT @insertados AS insertados,
           @actualizados AS actualizados,
           (SELECT COUNT(*) FROM @errores_importacion) AS errores;

    SELECT fila, error
    FROM @errores_importacion
    ORDER BY fila, id;
END;
GO
