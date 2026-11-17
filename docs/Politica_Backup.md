# Política de Respaldo (Backup)

## 1. Objetivo
Garantizar la disponibilidad y recuperabilidad de la base `MundialFutbol`, considerando el mayor volumen de escritura durante los días de partido.

## 2. RPO y RTO
- **RPO (Recovery Point Objective):**
  - Días de partido: 15 minutos.
  - Días sin partido: 30 minutos.
- **RTO (Recovery Time Objective):** 2 horas (restauración completa desde el último backup full + diferenciales + logs).

## 3. Estrategia de backups

| Tipo | Frecuencia (día de partido) | Frecuencia (día sin partido) | Retención |
|------|----------------------------|------------------------------|-----------|
| Full | Diario (02:00 UTC) | Diario (02:00 UTC) | 4 semanas (diarios) + 3 meses (mensual) |
| Differential | Cada 1 hora | Cada 4 horas | 7 días |
| Transaction Log | Cada 15 minutos | Cada 30 minutos | 7 días |

## 4. Justificación
Durante los días de partido el volumen de escritura (goles, tarjetas, cambios, resultados) es mucho mayor, por lo que se reduce el intervalo de backup de log y se aumenta la frecuencia de diferenciales para acotar la pérdida de datos (RPO).

## 5. Comandos de ejemplo
```sql
-- Full
BACKUP DATABASE MundialFutbol TO DISK = 'D:\Backups\MundialFutbol_Full.bak'
    WITH INIT, COMPRESSION, CHECKSUM;

-- Differential
BACKUP DATABASE MundialFutbol TO DISK = 'D:\Backups\MundialFutbol_Diff.bak'
    WITH DIFFERENTIAL, COMPRESSION, CHECKSUM;

-- Log
BACKUP LOG MundialFutbol TO DISK = 'D:\Backups\MundialFutbol_Log.trn'
    WITH COMPRESSION, CHECKSUM;
```

## 6. Procedimiento de restauración
1. Restaurar el último backup full (`WITH NORECOVERY`).
2. Restaurar el último differential (`WITH NORECOVERY`).
3. Restaurar los backups de log en orden cronológico (`WITH RECOVERY` en el último).
4. Verificar integridad con `DBCC CHECKDB`.

## 7. Responsabilidades
- El DBA ejecuta y monitorea los backups.
- Se valida semanalmente la restauración en un entorno de prueba.