/*
    Staging para la importación de árbitros desde XML.
*/

USE MundialFutbol;
GO

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = 'integracion'
      AND TABLE_NAME = 'StagingArbitroXML'
)
BEGIN
    CREATE TABLE integracion.StagingArbitroXML
    (
        fila       int IDENTITY(1, 1) NOT NULL PRIMARY KEY,
        nombre     nvarchar(100) NULL,
        apellido   nvarchar(100) NULL,
        pais_iso2  char(2) COLLATE Latin1_General_CS_AI NULL,
        categoria  nvarchar(50) NULL
    );
END;
GO
