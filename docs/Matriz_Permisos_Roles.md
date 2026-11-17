
| Permiso / Objeto | rol_administrador | rol_cargador_resultados | rol_gestor_publicidad | rol_consulta |
|------------------|:-----------------:|:----------------------:|:---------------------:|:------------:|
| SELECT esquemas deportivo/general/arbitraje/publicidad/integracion | ✅ | ✅ (deportivo, general, arbitraje) | ✅ (deportivo, general) | ✅ |
| INSERT/UPDATE/DELETE deportivo.Partido, Gol, Tarjeta, Sustitucion, VentanaCambio, Alineacion*, AltaBajaConvocatoria | ✅ | ✅ | ❌ | ❌ |
| INSERT/UPDATE/DELETE publicidad.* | ✅ | ❌ | ✅ | ❌ |
| INSERT/UPDATE/DELETE general.*, arbitraje.* (ABM) | ✅ | ❌ | ❌ | ❌ |
| EXECUTE SPs deportivo (reportes/carga) | ✅ | ✅ | ❌ | Reportes |
| EXECUTE SPs publicidad | ✅ | ❌ | ✅ | Reporte ocupación |
| CONTROL sobre esquemas | ✅ | ❌ | ❌ | ❌ |
| EXECUTE dbo.usp_Abrir/CerrarClaveCifrado | ✅ | ❌ | ❌ | ❌ |

## Usuarios de prueba
- usr_admin → rol_administrador
- usr_cargador → rol_cargador_resultados
- usr_publicidad → rol_gestor_publicidad
- usr_consulta → rol_consulta

## Scripts de test
- `102_Test_Rol_Administrador.sql`
- `103_Test_Rol_Cargador.sql`
- `104_Test_Rol_GestorPublicidad.sql`
- `105_Test_Rol_Consulta.sql`