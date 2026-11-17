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
        Entrega 8 - Cifrado de datos sensibles (jugadores, cuerpos tecnicos y arbitros).
        Se usa cifrado a nivel de celda con clave simetrica protegida por certificado.
        Los datos en texto plano se migran, se cifran y luego se anulan, por lo que
        las consultas directas sobre las columnas originales dejan de mostrarlos.
*/
USE MundialFutbol;
GO

SET NOCOUNT ON;
GO

-- ============================================================
-- 1. INFRAESTRUCTURA CRIPTOGRAFICA
-- ============================================================

-- Master key de la base (si no existe)
IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE symmetric_key_id = 101)
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'MundialFutbol_2026_Seguridad!';
GO

-- Certificado
IF NOT EXISTS (SELECT 1 FROM sys.certificates WHERE name = 'Cert_MundialFutbol')
    CREATE CERTIFICATE Cert_MundialFutbol
        WITH SUBJECT = 'Certificado de cifrado MundialFutbol';
GO

-- Clave simetrica
IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name = 'SK_MundialFutbol')
    CREATE SYMMETRIC KEY SK_MundialFutbol
        WITH ALGORITHM = AES_256
        ENCRYPTION BY CERTIFICATE Cert_MundialFutbol;
GO

-- ============================================================
-- 2. COLUMNAS CIFRADAS
-- ============================================================

-- deportivo.Jugador
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='deportivo' AND TABLE_NAME='Jugador' AND COLUMN_NAME='nombre_enc')
    ALTER TABLE deportivo.Jugador ADD nombre_enc varbinary(max) NULL;
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='deportivo' AND TABLE_NAME='Jugador' AND COLUMN_NAME='apellido_enc')
    ALTER TABLE deportivo.Jugador ADD apellido_enc varbinary(max) NULL;
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='deportivo' AND TABLE_NAME='Jugador' AND COLUMN_NAME='fecha_nacimiento_enc')
    ALTER TABLE deportivo.Jugador ADD fecha_nacimiento_enc varbinary(max) NULL;
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='deportivo' AND TABLE_NAME='Jugador' AND COLUMN_NAME='documento_identidad_enc')
    ALTER TABLE deportivo.Jugador ADD documento_identidad_enc varbinary(max) NULL;
GO

-- deportivo.MiembroCuerpoTecnico
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='deportivo' AND TABLE_NAME='MiembroCuerpoTecnico' AND COLUMN_NAME='nombre_enc')
    ALTER TABLE deportivo.MiembroCuerpoTecnico ADD nombre_enc varbinary(max) NULL;
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='deportivo' AND TABLE_NAME='MiembroCuerpoTecnico' AND COLUMN_NAME='apellido_enc')
    ALTER TABLE deportivo.MiembroCuerpoTecnico ADD apellido_enc varbinary(max) NULL;
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='deportivo' AND TABLE_NAME='MiembroCuerpoTecnico' AND COLUMN_NAME='fecha_nacimiento_enc')
    ALTER TABLE deportivo.MiembroCuerpoTecnico ADD fecha_nacimiento_enc varbinary(max) NULL;
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='deportivo' AND TABLE_NAME='MiembroCuerpoTecnico' AND COLUMN_NAME='documento_identidad_enc')
    ALTER TABLE deportivo.MiembroCuerpoTecnico ADD documento_identidad_enc varbinary(max) NULL;
GO

-- arbitraje.Arbitro
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='arbitraje' AND TABLE_NAME='Arbitro' AND COLUMN_NAME='nombre_enc')
    ALTER TABLE arbitraje.Arbitro ADD nombre_enc varbinary(max) NULL;
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='arbitraje' AND TABLE_NAME='Arbitro' AND COLUMN_NAME='apellido_enc')
    ALTER TABLE arbitraje.Arbitro ADD apellido_enc varbinary(max) NULL;
GO

-- Permitir NULL en columnas de texto plano (para poder anularlas)
ALTER TABLE deportivo.Jugador ALTER COLUMN nombre nvarchar(50) NULL;
ALTER TABLE deportivo.Jugador ALTER COLUMN apellido nvarchar(50) NULL;
ALTER TABLE deportivo.Jugador ALTER COLUMN fecha_nacimiento date NULL;
ALTER TABLE deportivo.Jugador ALTER COLUMN documento_identidad varchar(30) NULL;
ALTER TABLE deportivo.MiembroCuerpoTecnico ALTER COLUMN nombre nvarchar(50) NULL;
ALTER TABLE deportivo.MiembroCuerpoTecnico ALTER COLUMN apellido nvarchar(50) NULL;
ALTER TABLE deportivo.MiembroCuerpoTecnico ALTER COLUMN documento_identidad varchar(30) NULL;
ALTER TABLE arbitraje.Arbitro ALTER COLUMN nombre varchar(100) NULL;
ALTER TABLE arbitraje.Arbitro ALTER COLUMN apellido varchar(100) NULL;
GO

-- ============================================================
-- 3. MIGRACION DE DATOS EXISTENTES
-- ============================================================

OPEN SYMMETRIC KEY SK_MundialFutbol
    DECRYPTION BY CERTIFICATE Cert_MundialFutbol;
GO

UPDATE deportivo.Jugador
SET nombre_enc = EncryptByKey(Key_GUID('SK_MundialFutbol'), CONVERT(varbinary(max), nombre)),
    apellido_enc = EncryptByKey(Key_GUID('SK_MundialFutbol'), CONVERT(varbinary(max), apellido)),
    fecha_nacimiento_enc = EncryptByKey(Key_GUID('SK_MundialFutbol'), CONVERT(varbinary(max), CONVERT(varchar(10), fecha_nacimiento, 120))),
    documento_identidad_enc = EncryptByKey(Key_GUID('SK_MundialFutbol'), CONVERT(varbinary(max), documento_identidad))
WHERE nombre IS NOT NULL OR apellido IS NOT NULL;
GO

UPDATE deportivo.MiembroCuerpoTecnico
SET nombre_enc = EncryptByKey(Key_GUID('SK_MundialFutbol'), CONVERT(varbinary(max), nombre)),
    apellido_enc = EncryptByKey(Key_GUID('SK_MundialFutbol'), CONVERT(varbinary(max), apellido)),
    fecha_nacimiento_enc = EncryptByKey(Key_GUID('SK_MundialFutbol'), CONVERT(varbinary(max), CONVERT(varchar(10), fecha_nacimiento, 120))),
    documento_identidad_enc = EncryptByKey(Key_GUID('SK_MundialFutbol'), CONVERT(varbinary(max), documento_identidad))
WHERE nombre IS NOT NULL OR apellido IS NOT NULL;
GO

UPDATE arbitraje.Arbitro
SET nombre_enc = EncryptByKey(Key_GUID('SK_MundialFutbol'), CONVERT(varbinary(max), nombre)),
    apellido_enc = EncryptByKey(Key_GUID('SK_MundialFutbol'), CONVERT(varbinary(max), apellido))
WHERE nombre IS NOT NULL OR apellido IS NOT NULL;
GO

-- Anular texto plano
UPDATE deportivo.Jugador
SET nombre = NULL, apellido = NULL, fecha_nacimiento = NULL, documento_identidad = NULL
WHERE nombre_enc IS NOT NULL;
GO
UPDATE deportivo.MiembroCuerpoTecnico
SET nombre = NULL, apellido = NULL, fecha_nacimiento = NULL, documento_identidad = NULL
WHERE nombre_enc IS NOT NULL;
GO
UPDATE arbitraje.Arbitro
SET nombre = NULL, apellido = NULL
WHERE nombre_enc IS NOT NULL;
GO

IF EXISTS (SELECT 1 FROM sys.openkeys WHERE key_name = 'SK_MundialFutbol')
    CLOSE SYMMETRIC KEY SK_MundialFutbol;
GO

-- ============================================================
-- 4. TRIGGERS PARA CIFRAR AUTOMATICAMENTE NUEVOS DATOS
-- ============================================================

CREATE OR ALTER TRIGGER deportivo.trg_Jugador_Cifrado
ON deportivo.Jugador
WITH EXECUTE AS OWNER
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted) RETURN;

    OPEN SYMMETRIC KEY SK_MundialFutbol
        DECRYPTION BY CERTIFICATE Cert_MundialFutbol;

    UPDATE j
    SET nombre_enc = CASE WHEN i.nombre IS NOT NULL
                          THEN EncryptByKey(Key_GUID('SK_MundialFutbol'), CONVERT(varbinary(max), i.nombre))
                          ELSE j.nombre_enc END,
        apellido_enc = CASE WHEN i.apellido IS NOT NULL
                            THEN EncryptByKey(Key_GUID('SK_MundialFutbol'), CONVERT(varbinary(max), i.apellido))
                            ELSE j.apellido_enc END,
        fecha_nacimiento_enc = CASE WHEN i.fecha_nacimiento IS NOT NULL
                                   THEN EncryptByKey(Key_GUID('SK_MundialFutbol'), CONVERT(varbinary(max), CONVERT(varchar(10), i.fecha_nacimiento, 120)))
                                   ELSE j.fecha_nacimiento_enc END,
        documento_identidad_enc = CASE WHEN i.documento_identidad IS NOT NULL
                                      THEN EncryptByKey(Key_GUID('SK_MundialFutbol'), CONVERT(varbinary(max), i.documento_identidad))
                                      ELSE j.documento_identidad_enc END,
        nombre = NULL,
        apellido = NULL,
        fecha_nacimiento = NULL,
        documento_identidad = NULL
    FROM deportivo.Jugador j
    INNER JOIN inserted i ON i.id = j.id
    WHERE i.nombre IS NOT NULL OR i.apellido IS NOT NULL
       OR i.fecha_nacimiento IS NOT NULL OR i.documento_identidad IS NOT NULL;

    CLOSE SYMMETRIC KEY SK_MundialFutbol;
END
GO

CREATE OR ALTER TRIGGER deportivo.trg_MiembroCuerpoTecnico_Cifrado
ON deportivo.MiembroCuerpoTecnico
WITH EXECUTE AS OWNER
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted) RETURN;

    OPEN SYMMETRIC KEY SK_MundialFutbol
        DECRYPTION BY CERTIFICATE Cert_MundialFutbol;

    UPDATE m
    SET nombre_enc = CASE WHEN i.nombre IS NOT NULL
                          THEN EncryptByKey(Key_GUID('SK_MundialFutbol'), CONVERT(varbinary(max), i.nombre))
                          ELSE m.nombre_enc END,
        apellido_enc = CASE WHEN i.apellido IS NOT NULL
                            THEN EncryptByKey(Key_GUID('SK_MundialFutbol'), CONVERT(varbinary(max), i.apellido))
                            ELSE m.apellido_enc END,
        fecha_nacimiento_enc = CASE WHEN i.fecha_nacimiento IS NOT NULL
                                   THEN EncryptByKey(Key_GUID('SK_MundialFutbol'), CONVERT(varbinary(max), CONVERT(varchar(10), i.fecha_nacimiento, 120)))
                                   ELSE m.fecha_nacimiento_enc END,
        documento_identidad_enc = CASE WHEN i.documento_identidad IS NOT NULL
                                      THEN EncryptByKey(Key_GUID('SK_MundialFutbol'), CONVERT(varbinary(max), i.documento_identidad))
                                      ELSE m.documento_identidad_enc END,
        nombre = NULL,
        apellido = NULL,
        fecha_nacimiento = NULL,
        documento_identidad = NULL
    FROM deportivo.MiembroCuerpoTecnico m
    INNER JOIN inserted i ON i.id = m.id
    WHERE i.nombre IS NOT NULL OR i.apellido IS NOT NULL
       OR i.fecha_nacimiento IS NOT NULL OR i.documento_identidad IS NOT NULL;

    CLOSE SYMMETRIC KEY SK_MundialFutbol;
END
GO

CREATE OR ALTER TRIGGER arbitraje.trg_Arbitro_Cifrado
ON arbitraje.Arbitro
WITH EXECUTE AS OWNER
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted) RETURN;

    OPEN SYMMETRIC KEY SK_MundialFutbol
        DECRYPTION BY CERTIFICATE Cert_MundialFutbol;

    UPDATE a
    SET nombre_enc = CASE WHEN i.nombre IS NOT NULL
                          THEN EncryptByKey(Key_GUID('SK_MundialFutbol'), CONVERT(varbinary(max), i.nombre))
                          ELSE a.nombre_enc END,
        apellido_enc = CASE WHEN i.apellido IS NOT NULL
                            THEN EncryptByKey(Key_GUID('SK_MundialFutbol'), CONVERT(varbinary(max), i.apellido))
                            ELSE a.apellido_enc END,
        nombre = NULL,
        apellido = NULL
    FROM arbitraje.Arbitro a
    INNER JOIN inserted i ON i.id = a.id
    WHERE i.nombre IS NOT NULL OR i.apellido IS NOT NULL;

    CLOSE SYMMETRIC KEY SK_MundialFutbol;
END
GO

-- ============================================================
-- 5. VISTAS DESCIFRADAS (para consultas autorizadas)
-- ============================================================

CREATE OR ALTER VIEW deportivo.vw_JugadorDescifrado
AS
SELECT
    id,
    id_pais_nacimiento,
    CONVERT(nvarchar(50), DecryptByKey(nombre_enc)) AS nombre,
    CONVERT(nvarchar(50), DecryptByKey(apellido_enc)) AS apellido,
    CONVERT(date, DecryptByKey(fecha_nacimiento_enc)) AS fecha_nacimiento,
    CONVERT(varchar(30), DecryptByKey(documento_identidad_enc)) AS documento_identidad
FROM deportivo.Jugador;
GO

CREATE OR ALTER VIEW deportivo.vw_MiembroCuerpoTecnicoDescifrado
AS
SELECT
    id,
    id_seleccion,
    id_rol_cuerpo_tecnico,
    CONVERT(nvarchar(50), DecryptByKey(nombre_enc)) AS nombre,
    CONVERT(nvarchar(50), DecryptByKey(apellido_enc)) AS apellido,
    CONVERT(date, DecryptByKey(fecha_nacimiento_enc)) AS fecha_nacimiento,
    CONVERT(varchar(30), DecryptByKey(documento_identidad_enc)) AS documento_identidad
FROM deportivo.MiembroCuerpoTecnico;
GO

CREATE OR ALTER VIEW arbitraje.vw_ArbitroDescifrado
AS
SELECT
    id,
    categoria,
    id_pais,
    CONVERT(varchar(100), DecryptByKey(nombre_enc)) AS nombre,
    CONVERT(varchar(100), DecryptByKey(apellido_enc)) AS apellido
FROM arbitraje.Arbitro;
GO

-- ============================================================
-- 6. SPs AUXILIARES PARA ABRIR/CERRAR LA CLAVE
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.usp_AbrirClaveCifrado
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM sys.openkeys WHERE key_name = 'SK_MundialFutbol')
        OPEN SYMMETRIC KEY SK_MundialFutbol DECRYPTION BY CERTIFICATE Cert_MundialFutbol;
END
GO

CREATE OR ALTER PROCEDURE dbo.usp_CerrarClaveCifrado
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM sys.openkeys WHERE key_name = 'SK_MundialFutbol')
        CLOSE SYMMETRIC KEY SK_MundialFutbol;
END
GO

PRINT 'OK - Cifrado configurado.';
GO