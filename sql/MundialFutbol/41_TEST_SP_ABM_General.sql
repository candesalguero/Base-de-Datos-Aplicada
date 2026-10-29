/*
    Universidad: Universidad de La Matanza
    Materia: Bases de Datos Aplicada
    Integrantes:
        - Salguero, Candela
        - Ocaranza, Lucila
        - Dimattia Damm, Malena
        - Fuentes, Martina Alejandra

    Objetivo:
    Probar los procedimientos almacenados de ABM del esquema general,
    contemplando casos exitosos y validaciones de error.
*/

USE MundialFutbol;
GO

BEGIN TRANSACTION;

--DATOS AUXILIARES PARA LAS PRUEBAS:
print 'DATOS AUXILIARES';

--Confederacion
IF NOT EXISTS(SELECT 1 FROM general.Confederacion
WHERE id = 9900)
BEGIN
    INSERT INTO general.Confederacion (id, nombre)
    VALUES (9900,'Confederacion Test');
END;

IF NOT EXISTS (SELECT 1 FROM general.Confederacion
WHERE id = 9901 )
BEGIN
    INSERT INTO general.Confederacion (id, nombre)
    VALUES (9901,'Confederacion Test 2');
END;

--Pais
IF NOT EXISTS (SELECT 1 FROM general.Pais
WHERE id=9900)
BEGIN
    INSERT INTO general.Pais (id,nombre,ISO2,huso_horario,id_confederacion)
    VALUES(9900,'Pais Test A','ZZ','UTC-3',9900);
END;

IF NOT EXISTS(SELECT 1 FROM general.Pais
WHERE id= 9901)
BEGIN
    INSERT INTO general.Pais (id,nombre,ISO2,huso_horario,id_confederacion)
    VALUES (9901,'Pais Test B','ZY','UTC-3',9900);
END;
    --Idioma
    IF NOT EXISTS (SELECT 1 FROM general.Idioma
    WHERE ISO639 = 'tst')
    BEGIN
        INSERT INTO general.Idioma (ISO639,nombre)
        VALUES('tst','Idioma Test');
    END;

    IF NOT EXISTS (SELECT 1 FROM general.Idioma
    WHERE ISO639 ='ZZZ')
    BEGIN
        INSERT INTO general.Idioma (ISO639,nombre)
        VALUES('zzz','Idioma Test 2');
    END;

    --Moneda 
    IF NOT EXISTS(SELECT 1 FROM general.Moneda
    WHERE id=9900)
    BEGIN
        INSERT INTO general.Moneda (id,cod_iso3,nombre)
        VALUES(9900,'TST','Moneda Test');
    END;

    IF NOT EXISTS(SELECT 1 FROM general.Moneda
    WHERE id =9901)
    BEGIN
        INSERT INTO general.Moneda(id,cod_iso3,nombre)
        VALUES(9901,'TSS','Moneda Test 2'); /*VER!*/
    END;

    --Fase
    IF NOT EXISTS(SELECT 1 FROM general.Fase
    WHERE id=9900)
    BEGIN
        INSERT INTO general.Fase (id,nombre,orden,es_eliminacion_directa)
        VALUES(9900,'Fase Test',99,0);
    END;

    --Sede 
    IF NOT EXISTS (SELECT 1 FROM general.Sede
    WHERE id=9900)
    BEGIN
        INSERT INTO general.Sede(id,id_pais,nombre_estadio,ciudad,capacidad,huso_horario)
        VALUES(9900,9900,'Estadio Test','Ciudad Test',10000,'UTC-3');
    END;

    --Indicador Economico
    IF NOT EXISTS (SELECT 1 FROM general.IndicadorEconomico
    WHERE id_pais=9900 AND anio=2026)
    BEGIN 
        INSERT INTO general.IndicadorEconomico(anio,id_pais,pbi,fecha_actualizacion)
        VALUES(2026,9900,100000.00,GETDATE());
    END;

--" 1- TESTING TABLA CONFEDERACION"
print '';
print '1. CONFEDERACION - INSERTAR';

BEGIN TRY
    EXEC general.usp_Confederacion_Insertar
    @nombre= 'Confederacion Nueva Test';
    Print 'OK - Confederacion insertada correctamente.';
END TRY

BEGIN CATCH
    PRINT 'ERROR INERPERADO: '+ ERROR_MESSAGE();
END CATCH;

Print '';
print '2-Confederacion - Validaciones';

BEGIN TRY
    EXEC general.usp_Confederacion_Insertar
    @nombre='';
    print'ERROR - El procedimiento deberia haber fallado.';

END TRY

BEGIN CATCH
    PRINT 'OK - Se detectaron las validaciones:';
    Print ERROR_MESSAGE();
END CATCH;

print'';
print '3- Confederacion -Nombre duplicado';

BEGIN TRY
    EXEC general.usp_Confederacion_Insertar
    @nombre = 'Confederacion Test';
    Print 'ERROR - El procedimiento deberia haber fallado.';
END try
Begin catch
    print 'OK- Se detecto el nombre duplicado:';
    print ERROR_MESSAGE();
end catch;

print '';
print '4-Confederacion- Actualizar';

BEGIN TRY
    EXEC general.usp_Confederacion_Actualizar
    @id=9900, @nombre ='Confederacion Actualizada Test';
    print'OK - Confederacion actualizada correctamente';
END TRY

BEGIN CATCH
    print'ERROR INERPERADO: '+ ERROR_MESSAGE();
END CATCH;

Print '';
print'5.Confederacion-Validaciones actualizar';

BEGIN TRY
    EXEC general.usp_Confederacion_Actualizar
    @id=999999, @nombre = '';
    print'ERROR - El procedimeinto deberia haber fallado.';
END TRY

BEGIN CATCH
    Print 'OK - Se detectaron las validaciones:';
    print ERROR_MESSAGE();
END CATCH;

Print'';
print'6.Confederacion-Nombre duplicado al Actualizar';

BEGIN TRY
    EXEC general.usp_Confederacion_Actualizar
    @id= 9900, @nombre= 'Confederacion Test 2';
    print 'Error -El procedimiento deberia haber fallado.';
END TRY

BEGIN CATCH
    PRINT 'OK - Se detecto el nombre duplicado:';
    print ERROR_MESSAGE();
END CATCH;

print'';
print '7.Confederacion- No eliminar con pais asociado';

BEGIN TRY
    EXEC general.usp_Confederacion_Eliminar
    @id=9900;
    print 'ERROR- La confederacion no deberia poder eliminarse.'
END TRY

BEGIN CATCH
    Print 'OK- Se imipio la eliminacion de la confederacion:';
    print ERROR_MESSAGE();
END CATCH;

print '';
print'8.Confederacion -Eliminar';

BEGIN TRY
    EXEC general.usp_Confederacion_Eliminar
    @id=9901;
    print 'OK - Confederacion eliminada correctamente.';
END TRY

BEGIN CATCH
    print 'ERROR INERPERADO: ' + ERROR_MESSAGE();
END CATCH;

print '';
print '9.Confederacion - Validacion eliminar';

BEGIN TRY
    EXEC general.usp_Confederacion_Eliminar
    @id =999999;
    print 'ERROR - El procedimiento deberia haber fallado.';
END TRY

BEGIN CATCH
    Print 'OK - Se detecto la validación:';
    print ERROR_MESSAGE();
END CATCH;

--"2.TESTING TABLA PAIS"
print '';
print '10.Pais -Insertar';

BEGIN TRY
    EXEC general.usp_Pais_Insertar
    @nombre ='Pais Nuevo Test', @h_horario = 'UTC-3',@confederacion=9900, @iso= 'XX';
    print 'OK - Pais insertado correctamente.';
END TRY

BEGIN CATCH
    Print 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;

Print'';
print'11.Pais -Validaciones';

BEGIN TRY
    EXEC general.usp_Pais_Insertar
    @nombre='', @h_horario='', @confederacion=999999, @iso = '';
    print 'ERROR -El procedimiento deberia haber fallado.';
END TRY

BEGIN CATCH
    Print 'OK - Se detectaron las validaciones: ';
    print ERROR_MESSAGE();
END CATCH;

Print '';
print '12.Pais - ISO invalido';

BEGIN TRY
    EXEC general.usp_Pais_Insertar
    @nombre ='Pais ISO Invalido', @h_horario='UTC-3',@confederacion=9900,@iso ='xx';
    print 'ERROR - El procedimiento deberia haber fallado.';
END TRY

BEGIN CATCH
    Print 'OK - Se detectó el ISO invalido: ';
    print ERROR_MESSAGE();
END CATCH;

Print '';
print '13.Pais -Nombre duplicado';

BEGIN TRY 
    EXEC general.usp_Pais_Insertar
    @nombre = 'Pais Test A', @h_horario ='UTC-3',@confederacion =9900,@iso='XY';
    print 'ERROR -El procedimeinto deberia haber fallado.';
END TRY

BEGIN CATCH
    PRINT 'OK - Se detectó el nombre duplicado: ';
    print ERROR_MESSAGE();
END CATCH;

Print '';
print'14.Pais -Actualizar';

BEGIN TRY
    EXEC general.usp_Pais_Actualizar
    @id = 9901, @nombre= 'Pais Test B Actualizado',@h_horario= 'UTC-3',@confederacion= 9900, @iso='ZY';
    print 'OK - Pais actualizado correctamente.';
END TRY

BEGIN CATCH
    PRINT 'ERROR Inesperado: '+ ERROR_MESSAGE();
END CATCH;

Print'';
print'15.Pais -Validaciones Actualizar';

BEGIN TRY
    EXEC general.usp_Pais_Actualizar
    @id=999999, @nombre= '',@h_horario='',@confederacion= 999999, @iso='';
    print 'ERROR - El procedimiento deberia haber fallado.';
END TRY

BEGIN CATCH
    Print'OK - Se detectaron las validaciones: ';
    print ERROR_MESSAGE();
END CATCH;

PRINT '';
PRINT'16.Pais - ISO Invalido al actualizar';

BEGIN TRY
    EXEC general.usp_Pais_Actualizar
    @id=9901,@nombre='Pais Test B',@h_horario='UTC-3',@confederacion=9900,@iso='xx';
    print 'ERROR - El procedimiento deberia haber fallado.';
END TRY

BEGIN CATCH
    PRINT 'OK- Se detectó el ISO invalido: ';
    print ERROR_MESSAGE();
END CATCH;

--3. TESTING TABLA IDIOMA
print '';
print '17.Idioma - Insertar';

BEGIN TRY
    EXEC general.usp_Idioma_Insertar
    @nombre='Idioma Nuevo Test', @iso6 = 'nwt';
    print'OK - Idioma insertado correctamente.';
END TRY

BEGIN CATCH
    Print 'ERROR INESPERADO: '+ ERROR_MESSAGE();
END CATCH;

PRINT '';
PRINT'18.Idioma - Validaciones';

BEGIN TRY 
    EXEC general.usp_Idioma_Insertar
    @nombre='',@iso6='ABC';
    print 'ERROR - El procedimiento deberia haber fallado.';
END TRY

BEGIN CATCH
    Print 'OK -Se detectaron las validaciones : ';
    print ERROR_MESSAGE();
END CATCH;

PRINT '';
PRINT'19.Idioma - Duplicado';

BEGIN TRY
    EXEC general.usp_Idioma_Insertar
    @nombre ='Idioma Test',@iso6='tst';
    print 'ERROR - El procedimiento deberia haber fallado.';
END TRY

BEGIN CATCH
    PRINT 'OK - Se detectó el idioma duplicado: ';
    print ERROR_MESSAGE();
END CATCH;

PRINT '';
PRINT'20.Idioma -Actualizar';

BEGIN TRY
    EXEC general.usp_Idioma_Actualizar
    @iso639='tst', @nombre='Idioma Test Actualizado';
    print 'OK - Idioma actualizado correctamente.';
END TRY

BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;

PRINT '';
PRINT'21.Idioma - Validaciones Actualizar';

BEGIN TRY
    EXEC general.usp_Idioma_Actualizar
    @iso639='xxx',@nombre ='';
    print 'ERROR - El procedimeinto deberia haber fallado.';
END TRY

BEGIN CATCH
    Print 'OK - Se detectaron las validaciones: ';
    print ERROR_MESSAGE();
END CATCH;

PRINT '';
PRINT'22.Idioma - Eliminar';

BEGIN TRY
    EXEC general.usp_Idioma_Eliminar
    @iso639='zzz';
    print 'OK - Idioma eliminado correctamente.';
END TRY

BEGIN CATCH
    Print 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;

--"4.TESTING TABLA MONEDA"

Print '';
print '23.Moneda -Insertar';

BEGIN TRY
    EXEC general.usp_Moneda_Insertar
    @iso3= 'NEW', @nombre= 'Moneda Nueva Test';
    print 'OK - Moneda insertada correctamente';
END TRY

BEGIN CATCH
    PRINT 'ERROR INESPERADO: '+ ERROR_MESSAGE();
END CATCH;

PRINT '';
PRINT'24.Moneda - Validaciones';

BEGIN TRY
    EXEC general.usp_Moneda_Insertar
    @iso3 = 'xx',@nombre= '';
    print 'ERROR - El procedimiento deberia haber fallado.';
END TRY

BEGIN CATCH
    PRINT 'OK - Se detectaron las validaciones: ';
    print ERROR_MESSAGE();
END CATCH;

Print'';
print'25.Moneda - Duplicado';

BEGIN TRY
    EXEC general.usp_Moneda_Insertar
    @iso3 = 'TST',@nombre='Moneda Test';
    print 'ERROR - El procedimeinto deberia haber fallado.';
END TRY

BEGIN CATCH
    PRINT 'OK - Se detectó la moneda duplicada: ';
    print ERROR_MESSAGE();
END CATCH;

PRINT'';
PRINT'26.Moneda - Actualizar';

BEGIN TRY
    EXEC general.usp_Moneda_Actualizar
    @id=9901, @iso3='TS2',@nombre = 'Moneda Test 2 Actualizada';
    print 'OK - Moneda actualizada correctamente.';
END TRY

BEGIN CATCH
    PRINT 'ERROR INESPERADO: '+ ERROR_MESSAGE();
END CATCH;

PRINT '';
PRINT'27.Moneda - Validaciones Actualiar';

BEGIN TRY
    EXEC general.usp_Moneda_Actualizar
    @id=999999, @iso3 ='',@nombre='';
    print 'ERROR - El procedimeinto deberia haber fallado.';
END TRY

BEGIN CATCH
    Print 'OK - Se detectaron las validaciones';
    print ERROR_MESSAGE();
END CATCH;

--"5. TESTING TABLA FASE"
print '';
print'28. FASE -Insertar';

BEGIN TRY
    EXEC general.usp_Fase_Insertar
    @nombre='octavos';
    print 'OK - Fase insertada correctamente.';
END TRY

BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;

    PRINT '';
    PRINT'29.Fase - Validaciones';

    BEGIN TRY
        EXEC general.usp_Fase_Insertar
        @nombre= 'Fase Invalida';
        print 'ERROR - El procedimiento deberia haber fallado.';
    END TRY

    BEGIN CATCH
        Print 'OK - Se detecto la fase invalida';
        print ERROR_MESSAGE();
    END CATCH;

    PRINT '';
    PRINT '30.Fase - Duplicado';

    BEGIN TRY 
        EXEC general.usp_Fase_Insertar
        @nombre='Fase Test';
        print 'ERROR - El procedimeinto deberia haber fallado.';
    END TRY

    BEGIN CATCH
        PRINT 'OK - Se detectó la fase duplicada: ';
        print ERROR_MESSAGE();
    END CATCH;

    PRINT '';
    PRINT'31. Fase - Actualizar';

    BEGIN TRY
        EXEC general.usp_Fase_Actualizar
        @id=9900, @nombre='final';
        print 'OK - Fase actualizada correctamente.';
    END TRY

    BEGIN CATCH
        Print 'ERROR INESPERADO: '+ ERROR_MESSAGE();
    END CATCH;

    PRINT '';
    PRINT '32. Fase - Validaciones Actualizar';

    BEGIN TRY 
        EXEC general.usp_Fase_Actualizar
        @id=999999, @nombre='';
        print 'ERROR - El procedimeinto deberia haber fallado.';
    END TRY

    BEGIN CATCH
        Print 'OK - Se detectaron las validaciones: ';
        print ERROR_MESSAGE();
    END CATCH;

    ---"6.TESTING TABLA SEDE"
    PRINT'';
    PRINT'33.Sede - Insertar';

    BEGIN TRY
        EXEC general.usp_Sede_Insertar
        @id_pais =9900,@nombre ='Estadio Nuevo Test',@ciudad ='Ciudad Nueva Test',@capacidad = 20000,@huso_horario='UTC-3';
        Print 'OK - Sede insertado correctamente.';
    END TRY

    BEGIN CATCH
        PRINT 'ERROR INESPERADO: '+ ERROR_MESSAGE();
    END CATCH;

    PRINT'';
    PRINT '34. Sede - Validaciones';

    BEGIN TRY
    EXEC general.usp_Sede_Insertar
    @id_pais=999999, @nombre='', @ciudad='', @capacidad=0,@huso_horario='';
    print 'ERROR - El procedimiento deberia haber fallado.';
    END TRY

    BEGIN CATCH
    Print 'OK - Se detectaron las validaciones: ';
    print ERROR_MESSAGE();
    END CATCH;

    PRINT '';
    PRINT'35. Sede - Estadio duplicado';

    BEGIN TRY 
        EXEC general.usp_Sede_Insertar
        @id_pais =9900,@nombre='Estadio Test',@ciudad= 'Ciudad Test',@capacidad= 10000,@huso_horario='UTC-3';
        PRINT 'ERROR - El procedimiento deberia haber fallado.';
    END TRY

    BEGIN CATCH
        PRINT 'OK -Se detectó el estadio duplicado:';
        print ERROR_MESSAGE();
    END CATCH;

    PRINT'';
    PRINT'36.Sede - Actualizar';

    BEGIN TRY
    EXEC general.usp_Sede_Actualizar
    @id=9900, @id_pais=9900, @nombre='Estadio Test Actualizado',
    @ciudad='Ciudad Test Actualizada',@capacidad=15000,@huso_horario='UTC-3';
    PRINT 'OK - Sede actualizada correctamente.';
    END TRY
    
    BEGIN CATCH
        Print 'ERROR INESPERADO: '+ ERROR_MESSAGE();
    END CATCH;

    PRINT '';
    PRINT'37. Sede - Validaciones Actualizar';

    BEGIN TRY 
        EXEC general.usp_Sede_Actualizar
        @id =999999, @id_pais=999999, @nombre='',@ciudad='', @capacidad=0, @huso_horario='';
        print 'ERROR - El procedimeinto deberia haber fallado.';
    END TRY

    BEGIN CATCH
        Print 'OK - Se detectaron las validaciones: ';
        print ERROR_MESSAGE();
    END CATCH;

    --"7.TESTING TABLA INDICADOR ECONOMICO"

    PRINT '';
    PRINT'38.IndicadorEconomico - Insertar';

    BEGIN TRY 
        EXEC general.usp_IndicadorEconomico_Insertar
        @anio=2025, @id_pais=9900, @pbi=250000.00;
        print 'OK - Indicador economico insertado correctamente.';
    END TRY

    BEGIN CATCH
        PRINT'ERROR INESPERADO: '+ ERROR_MESSAGE();
    END CATCH;

    PRINT'';
    PRINT'39. Indicador economico - Validaciones';

    BEGIN TRY 
        EXEC general.usp_IndicadorEconomico_Insertar
        @anio=NULL,@id_pais =999999, @pbi=0;
        print 'ERROR - El procedimiento deberia haber fallado';
    END TRY

    BEGIN CATCH
        PRINT 'OK - Se detectaron las validaciones: ';
        print ERROR_MESSAGE();
    END CATCH;

    PRINT '';
    PRINT'40.Indicador Economico - Duplicado';

    BEGIN TRY 
        EXEC general.usp_IndicadorEconomico_Insertar
        @anio=2026, @id_pais = 9900, @pbi=300000.00;
        print'ERROR - El procedimiento deberia haber fallado.';
    END TRY

    BEGIN CATCH
        PRINT 'OK - Se detectó el indicador duplicado:'
        print ERROR_MESSAGE();
    END CATCH;

    PRINT'';
    PRINT'41. Indicador Economico - Actualizar';

    BEGIN TRY
        EXEC general.usp_IndicadorEconomico_Actualizar
        @anio=2026, @id_pais=9900, @pbi=350000.00;
        print'OK - Indicador Economico actualizado correctamente.';
    END TRY

    BEGIN CATCH
        PRINT'ERROR INESPERADO: '+ ERROR_MESSAGE();
    END CATCH;

    print'';
    print'42.Indicador economico - Validaciones Actualizar';

    BEGIN TRY 
        EXEC general.usp_IndicadorEconomico_Actualizar
        @anio=NULL, @id_pais=999999, @pbi=0;
        print 'ERROR - El procedimiento deberia haber fallado.';
    END TRY

    BEGIN CATCH
        PRINT 'OK - Se detectaron las validaciones : ';
        print ERROR_MESSAGE();
    END CATCH;

    PRINT'';
    PRINT'43.Indicador economico - Validar año';

    BEGIN TRY 
        EXEC general.usp_IndicadorEconomico_Actualizar
        @anio=1800, @id_pais=9900, @pbi=350000.00;
        print 'ERROR - El procedimiento deberia haber fallado.';
    END TRY

    BEGIN CATCH
    PRINT 'OK - Se detectó el año invalido: ';
    print ERROR_MESSAGE();
    END CATCH;

    --ELIMINACIONES

    print '';
    print'44. Sede - Eliminar';

    BEGIN TRY 
        EXEC general.usp_Sede_Eliminar
        @id=9900;
        print'OK - Sede eliminada correctamente.';
    END TRY

    BEGIN CATCH
        PRINT'ERROR INESPERADO: '+ ERROR_MESSAGE();
    END CATCH;

    PRINT'';
   
    PRINT'45.Pais - No eliminar con indicadir';

    BEGIN TRY 
        EXEC general.usp_Pais_Eliminar
        @id=9900;
        print'ERROR - El pais no deberia eliminarse.';
    END TRY

    BEGIN CATCH
        PRINT'OK - Se impidió eliminar el pais: ';
        print ERROR_MESSAGE();
    END CATCH;

    PRINT '';
    PRINT'46.Indicador economico - Eliminar';

    BEGIN TRY 
        EXEC general.usp_IndicadorEconomico_Eliminar
        @anio=2026, @id_pais=9900;
        print'OK - Indicador economico eliminar correctamente';
    END TRY

    BEGIN CATCH
        PRINT 'ERROR INESPERADO: '+ ERROR_MESSAGE();
    END CATCH;

    
    PRINT '';
    PRINT'47. Pais - Eliminar';

    BEGIN TRY 
        EXEC general.usp_Pais_Eliminar
        @id=9901;
        print'OK - Pais eliminado correctamente.';
    END TRY

    BEGIN CATCH
        PRINT 'ERROR INESPERADO : '+ ERROR_MESSAGE();
    END CATCH;

    PRINT '';
    PRINT'48. Pais - Validacion Eliminar';

    BEGIN TRY 
        EXEC general.usp_Pais_Eliminar
        @id=999999;
        print'ERROR - El procedimiento deberia haber fallado.';
    END TRY 

    BEGIN CATCH 
        PRINT'OK - Se detectó la validación : ';
        print ERROR_MESSAGE();
    END CATCH;

    PRINT '';
    PRINT'49. Confederacion - Eliminar';

    BEGIN TRY 
        EXEC general.usp_Confederacion_Eliminar
        @id=9900;
        print 'OK - Confederacion  eliminada correctamente.';
    END TRY

    BEGIN CATCH 
        PRINT'ERROR INESPERADO: '+ ERROR_MESSAGE();
    END CATCH;

    print '';
    print'50. Moneda - Eliminar';

    BEGIN TRY 
        EXEC general.usp_Moneda_Eliminar
        @id=9900;
        print 'OK - Moneda eliminada correctamente.';
    END TRY

    BEGIN CATCH
            Print'ERROR INESPERADO: '+ ERROR_MESSAGE();
    END CATCH;

    PRINT'';
    PRINT'51. Moneda - Validacion eliminar';

    BEGIN TRY 
        EXEC general.usp_Moneda_Eliminar
        @id=999999;
        print 'ERROR - El procedimiento deberia haber fallado.';
    END TRY

    BEGIN CATCH
        Print 'OK - Se detetctó la validación: ';
        print ERROR_MESSAGE();
    END CATCH;

    PRINT '';
    PRINT'52. Fase - Eliminar';

    BEGIN TRY 
        EXEC general.usp_Fase_Eliminar
        @id=9900;
        print'OK - Fase eliminada correctamente.';
    END TRY

    BEGIN CATCH 
        Print'ERROR INESPERADO: '+ ERROR_MESSAGE();
    END CATCH;

    PRINT '';
    PRINT'53. Fase - Validacion Eliminar';

    BEGIN TRY 
        EXEC general.usp_Fase_Eliminar
        @id=999999;
        print 'Error - El procedimiento deberia haber fallado.';
    END TRY 

    BEGIN CATCH
        print'OK - Se detectó la validación: ';
        PRINT ERROR_MESSAGE();
    END CATCH;

    IF @@TRANCOUNT > 0 
        ROLLBACK TRANSACTION;

   PRINT '';
   PRINT 'PRUEBAS FINALIZADAS - DATOS REVERTIDOS';
   GO