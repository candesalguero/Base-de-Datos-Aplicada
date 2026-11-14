# Universidad: Universidad Nacional de La Matanza
# Materia: Bases de Datos Aplicada
# Integrantes:
#     - Salguero, Candela
#     - Ocaranza, Lucila
#     - Dimattia Damm, Malena
#     - Fuentes, Martina Alejandra

# Fecha: Noviembre 2026

# Objetivo: Obtener tipos de cambio desde la API de Frankfurter
# para las monedas cargadas en general.Moneda y almacenarlos en la base de datos mediante el
# procedimiento de integración correspondiente.
#
# La información obtenida de la API se utiliza para
# actualizar o registrar los tipos de cambio en general.TipoCambio, manteniendo la fecha y el valor
# de cada cotización.
# --------------------------------------------------
# INSTRUCCIONES DE EJECUCIÓN
# --------------------------------------------------
# Este archivo debe ejecutarse con Python 3.13 o superior.
#
# Requisitos:
# - Tener instalada la librería requests.
# - Tener instalada la librería pyodbc.
# - Tener SQL Server en ejecución.
# - Tener creada la base de datos MundialFutbol.
#
# Ejecutar desde una terminal ubicada en esta carpeta:
#
#     py -3.13 75_API_Frankfurter.py
#
# El script se conecta a la base MundialFutbol, consulta
# la API de Frankfurter y carga los tipos de cambio obtenidos.
# --------------------------------------------------
import pyodbc
import requests
import json

# --------------------------------------------------
# 1. Conexión con SQL Server
# --------------------------------------------------

conexion = pyodbc.connect(
    "DRIVER={ODBC Driver 18 for SQL Server};"
    "SERVER=localhost;"
    "DATABASE=MundialFutbol;"
    "Trusted_Connection=yes;"
    "TrustServerCertificate=yes;"
)

cursor = conexion.cursor()

# --------------------------------------------------
# 2. Obtener monedas cargadas en la base
# --------------------------------------------------

cursor.execute("""
    SELECT id, cod_iso3, nombre
    FROM general.Moneda
""")

monedas = cursor.fetchall()

print("Monedas cargadas en SQL Server:")

for moneda in monedas:
    print(moneda.id, moneda.cod_iso3, moneda.nombre)

# --------------------------------------------------
# 3. Consultar tipos de cambio en Frankfurter
# --------------------------------------------------

conversiones = []

for moneda_origen in monedas:
    for moneda_destino in monedas:

        if moneda_origen.cod_iso3 != moneda_destino.cod_iso3:
            conversiones.append(
                (
                    moneda_origen.cod_iso3,
                    moneda_destino.cod_iso3
                )
            )

datos_importacion = []

for moneda_origen, moneda_destino in conversiones:

    url = (
        f"https://api.frankfurter.dev/v2/"
        f"rate/{moneda_origen.lower()}/{moneda_destino.lower()}"
    )

    respuesta = requests.get(url)

    print(
        "\n",
        moneda_origen,
        "->",
        moneda_destino,
        "| Estado API:",
        respuesta.status_code
    )

    datos = respuesta.json()

    print(json.dumps(datos, indent=4))

    if respuesta.status_code == 200:
        print(
            "Fecha:",
            datos["date"],
            "| Cotización:",
            datos["rate"]
        )

        datos_importacion.append({
            "moneda_origen": datos["base"],
            "moneda_destino": datos["quote"],
            "fecha": datos["date"],
            "tipo_cambio": datos["rate"]
        })
        
print("\nDatos preparados para importar:")

for dato in datos_importacion:
    print(dato)

json_importacion = json.dumps(datos_importacion)

print("\nJSON enviado al procedimiento SQL:")
print(json_importacion)

cursor.execute(
    "EXEC integracion.usp_ImportarTipoCambioAPI @datos = ?, @archivo = ?",
    json_importacion,
    "Frankfurter_API_TiposCambio"
)

resultado = cursor.fetchall()

conexion.commit()

print("\nResultado de la importación:")

for fila in resultado:
    print(fila)

conexion.close()
