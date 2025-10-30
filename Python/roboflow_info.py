# test_roboflow.py
from roboflow import Roboflow

API_KEY = "0vEenW14yhfXARC4RpkR"
WORKSPACE_ID = "proyecto-final-amle6"
PROJECT_ID = "aeroscan-1d3ch"
MODEL_VERSION = 1

print("🤖 Probando conexión con AeroScan...")
rf = Roboflow(api_key=API_KEY)
project = rf.workspace(WORKSPACE_ID).project(PROJECT_ID)
model = project.version(MODEL_VERSION).model

print(f"✅ Modelo cargado exitosamente!")
print(f"   Proyecto: {PROJECT_ID}")
print(f"   Versión: {MODEL_VERSION}")
print("\n🎯 Listo para procesar imágenes!")