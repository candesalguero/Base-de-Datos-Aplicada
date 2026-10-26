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
    Crear las claves foraneas del esquema publicidad una vez que las tablas
    de los esquemas general y deportivo se encuentren creadas.

*/

USE MundialFutbol;
GO

IF OBJECT_ID(N'general.Pais', N'U') IS NULL
    PRINT N'AVISO: no existe general.Pais; se omite la FK Anunciante -> Pais.';
ELSE IF OBJECT_ID(N'publicidad.Anunciante', N'U') IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Anunciante_Pais')
    ALTER TABLE publicidad.Anunciante WITH CHECK
        ADD CONSTRAINT FK_Anunciante_Pais
        FOREIGN KEY (id_pais_origen) REFERENCES general.Pais (id);
GO

IF OBJECT_ID(N'general.Moneda', N'U') IS NULL
    PRINT N'AVISO: no existe general.Moneda; se omite la FK Campana -> Moneda.';
ELSE IF OBJECT_ID(N'publicidad.Campana', N'U') IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Campana_Moneda')
    ALTER TABLE publicidad.Campana WITH CHECK
        ADD CONSTRAINT FK_Campana_Moneda
        FOREIGN KEY (id_moneda) REFERENCES general.Moneda (id);
GO

IF OBJECT_ID(N'general.Moneda', N'U') IS NULL
    PRINT N'AVISO: no existe general.Moneda; se omite la FK Tarifa -> Moneda.';
ELSE IF OBJECT_ID(N'publicidad.Tarifa', N'U') IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Tarifa_Moneda')
    ALTER TABLE publicidad.Tarifa WITH CHECK
        ADD CONSTRAINT FK_Tarifa_Moneda
        FOREIGN KEY (id_moneda) REFERENCES general.Moneda (id);
GO

IF OBJECT_ID(N'general.Idioma', N'U') IS NULL
    PRINT N'AVISO: no existe general.Idioma; se omite la FK PiezaDeContenido -> Idioma.';
ELSE IF OBJECT_ID(N'publicidad.PiezaDeContenido', N'U') IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_PiezaDeContenido_Idioma')
    ALTER TABLE publicidad.PiezaDeContenido WITH CHECK
        ADD CONSTRAINT FK_PiezaDeContenido_Idioma
        FOREIGN KEY (id_idioma) REFERENCES general.Idioma (ISO639);
GO

IF OBJECT_ID(N'deportivo.Partido', N'U') IS NULL
    PRINT N'AVISO: no existe deportivo.Partido; se omite la FK ExhibicionPublicitaria -> Partido.';
ELSE IF OBJECT_ID(N'publicidad.ExhibicionPublicitaria', N'U') IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ExhibicionPublicitaria_Partido')
    ALTER TABLE publicidad.ExhibicionPublicitaria WITH CHECK
        ADD CONSTRAINT FK_ExhibicionPublicitaria_Partido
        FOREIGN KEY (id_partido) REFERENCES deportivo.Partido (id);
GO

IF OBJECT_ID(N'general.Moneda', N'U') IS NULL
    PRINT N'AVISO: no existe general.Moneda; se omite la FK ExhibicionPublicitaria -> Moneda.';
ELSE IF OBJECT_ID(N'publicidad.ExhibicionPublicitaria', N'U') IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ExhibicionPublicitaria_Moneda')
    ALTER TABLE publicidad.ExhibicionPublicitaria WITH CHECK
        ADD CONSTRAINT FK_ExhibicionPublicitaria_Moneda
        FOREIGN KEY (id_moneda) REFERENCES general.Moneda (id);
GO

IF OBJECT_ID(N'general.Pais', N'U') IS NULL
    PRINT N'AVISO: no existe general.Pais; se omite la FK PiezaDeMercadoDeInteres -> Pais.';
ELSE IF OBJECT_ID(N'publicidad.PiezaDeMercadoDeInteres', N'U') IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_PiezaDeMercadoDeInteres_Pais')
    ALTER TABLE publicidad.PiezaDeMercadoDeInteres WITH CHECK
        ADD CONSTRAINT FK_PiezaDeMercadoDeInteres_Pais
        FOREIGN KEY (id_pais) REFERENCES general.Pais (id);
GO
