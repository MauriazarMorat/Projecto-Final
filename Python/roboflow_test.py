#!/usr/bin/env python3
# roboflow_test.py
# Ejecuta una predicción sobre ImageTest.jpg usando roboflow_processor.py

import os
import sys
import json
from datetime import datetime

# Importar la clase desde tu módulo existente
# Asegúrate de que roboflow_processor.py esté en el mismo directorio
try:
    from roboflow_processor import RoboflowProcessor
except Exception as e:
    print("Error importando roboflow_processor:", e)
    sys.exit(1)

def main(image_filename="ImageTest.jpg"):
    cwd = os.path.dirname(os.path.abspath(__file__))
    img_path = os.path.join(cwd, image_filename)

    if not os.path.exists(img_path):
        print(f"Error: no existe la imagen '{image_filename}' en {cwd}")
        sys.exit(1)

    # Crear instancia del procesador
    processor = RoboflowProcessor()

    print("Inicializando modelo...")
    if not processor.initialize():
        print("No se pudo inicializar el modelo Roboflow. Revisa la API key y conexión a internet.")
        sys.exit(1)

    print(f"Procesando imagen: {img_path}")
    prediction = processor.process_image(img_path)

    if prediction is None:
        print("La predicción devolvió None (hubo un error).")
        sys.exit(1)

    # Guardar imagen anotada en una carpeta clara para este test
    output_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "carpeta_frames", "after", "Test_run")
    os.makedirs(output_dir, exist_ok=True)

    timestamp = datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")
    # Guardar anotada con índice 1 (single image)
    output_path = processor.save_annotated_image(img_path, prediction, output_dir, 1)

    # Preparar resultado legible
    result = {
        "status": "success",
        "image": os.path.basename(img_path),
        "image_path": img_path,
        "annotated_image_path": output_path,
        "num_detections": len(prediction.get("predictions", [])),
        "predictions": prediction.get("predictions", []),
        "timestamp_utc": timestamp
    }

    # Imprimir JSON formateado en stdout
    print(json.dumps(result, indent=2, ensure_ascii=False))

    # También guardamos un archivo JSON con los resultados
    json_out_path = os.path.join(output_dir, f"result_{timestamp}.json")
    try:
        with open(json_out_path, "w", encoding="utf-8") as jf:
            json.dump(result, jf, indent=2, ensure_ascii=False)
        print(f"Resultados guardados en: {json_out_path}")
    except Exception as e:
        print(f"No se pudo guardar el JSON de resultados: {e}")

if __name__ == "__main__":
    # Permite pasar el nombre de la imagen por línea de comandos
    if len(sys.argv) > 1:
        image_name = sys.argv[1]
    else:
        image_name = "ImageTest.jpg"
    main(image_name)
