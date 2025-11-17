import os
import json
from roboflow import Roboflow
from PIL import Image, ImageDraw
import base64
from io import BytesIO
import concurrent.futures
import threading

# ============================================
# VARIABLES DE CONFIGURACIÓN - CAMBIAR AQUÍ
# ============================================
API_KEY = "0vEenW14yhfXARC4RpkR"
WORKSPACE_ID = "proyecto-final-amle6"
PROJECT_ID = "aeroscan-1d3ch"
MODEL_VERSION = 1  
CONFIDENCE_THRESHOLD = 0.6  

current_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.dirname(current_dir)
OUTPUT_FOLDER = os.path.join(project_root, "carpeta_frames/after")
# ============================================

class RoboflowProcessor:
    """Clase para manejar el procesamiento con Roboflow"""
    
    def __init__(self):
        self.model = None
        self.initialized = False
    
    def initialize(self):
        """Inicializar el modelo de Roboflow"""
        if not self.initialized:
            try:
                print("🤖 Inicializando modelo de Roboflow...")
                rf = Roboflow(api_key=API_KEY)
                project = rf.workspace(WORKSPACE_ID).project(PROJECT_ID)
                self.model = project.version(MODEL_VERSION).model
                self.initialized = True
                print(f"✓ Modelo cargado: {PROJECT_ID} v{MODEL_VERSION}")
                return True
            except Exception as e:
                print(f"✗ Error inicializando Roboflow: {e}")
                self.initialized = False
                return False
        return True
    
    def process_image(self, img_path):
        """Procesar una imagen con el modelo"""
        try:
            if not self.initialized:
                if not self.initialize():
                    return None
            
            prediction = self.model.predict(img_path, confidence=CONFIDENCE_THRESHOLD).json()
            return prediction
        except Exception as e:
            print(f"Error procesando imagen {img_path}: {e}")
            return None
    
    def annotate_image(self, img_path, prediction, output_path=None):
        """Anotar imagen con las detecciones y retornar en base64, opcionalmente guardar a disco"""
        try:
            image = Image.open(img_path)
            draw = ImageDraw.Draw(image)
            
            colors = ['red', 'blue', 'green', 'yellow', 'purple', 'orange']
            
            for i, pred in enumerate(prediction.get('predictions', [])):
                x = pred['x']
                y = pred['y']
                width = pred['width']
                height = pred['height']
                
                left = x - width / 2
                top = y - height / 2
                right = x + width / 2
                bottom = y + height / 2
                
                color = colors[i % len(colors)]
                draw.rectangle([left, top, right, bottom], outline=color, width=3)
                
                label = f"{pred.get('class', 'objeto')} {pred.get('confidence', 0):.2f}"
                draw.text((left, top - 20), label, fill=color)
            
            # Guardar a disco si se proporciona output_path
            if output_path:
                image.save(output_path, format="JPEG", quality=90)
            
            # Convertir a base64
            buffered = BytesIO()
            image.save(buffered, format="JPEG", quality=85)
            img_base64 = base64.b64encode(buffered.getvalue()).decode()
            
            return img_base64
        except Exception as e:
            print(f"Error anotando imagen: {e}")
            return None
    
    def process_batch(self, image_paths, ndc, ndv):
        """
        Procesar un batch completo de imágenes con procesamiento concurrente
        
        Args:
            image_paths: Lista de rutas de las imágenes
            ndc: Número NDC
            ndv: Número NDV
        
        Returns:
            dict: Resultados del procesamiento
        """
        if not self.initialize():
            return {
                "status": "error",
                "message": "No se pudo inicializar el modelo de Roboflow"
            }
        
        # Crear carpeta de salida base para after y carpeta agregada por batch
        os.makedirs(OUTPUT_FOLDER, exist_ok=True)
        output_dir = os.path.join(OUTPUT_FOLDER, f"NDC_{ndc}_NDV_{ndv}")
        os.makedirs(output_dir, exist_ok=True)
        
        results = {
            "status": "success",
            "ndc": ndc,
            "ndv": ndv,
            "total_images": len(image_paths),
            "processed_images": [],
            "total_detections": 0,
            "summary": {}
        }
        
        print(f"\n{'='*50}")
        print(f"Procesando Batch: NDC {ndc} - NDV {ndv}")
        print(f"Total de imágenes: {len(image_paths)}")
        print(f"Usando procesamiento concurrente (max 4 workers)...")
        print(f"{'='*50}\n")
        
        processed_count = [0]  # Mutable counter for thread safety
        lock = threading.Lock()
        
        def process_single_image(args):
            """Procesar una imagen individual"""
            idx, img_path = args
            try:
                if not os.path.exists(img_path):
                    print(f"⚠ [{idx}] Imagen no encontrada: {img_path}")
                    return None
                
                # Hacer predicción (sin esperar a que la imagen se guarde)
                prediction = self.process_image(img_path)
                
                if prediction is None:
                    print(f"✗ [{idx}] Error en predicción")
                    return None
                
                num_detections = len(prediction.get('predictions', []))
                
                # Crear nombre para la imagen anotada y carpeta por imagen
                base_name = os.path.basename(img_path)
                name_without_ext = os.path.splitext(base_name)[0]

                # Carpeta por imagen: carpeta_frames/after/NDC_x_NDV_y_NC_z/
                per_image_dir = os.path.join(OUTPUT_FOLDER, name_without_ext)
                os.makedirs(per_image_dir, exist_ok=True)

                # Nombre del archivo dentro de la carpeta (usar el mismo nombre que la carpeta + .jpg)
                annotated_filename = f"{name_without_ext}.jpg"
                annotated_path = os.path.join(per_image_dir, annotated_filename)

                # Anotar imagen y guardar a disco
                img_base64 = self.annotate_image(img_path, prediction, output_path=annotated_path)

                # Guardar un resultados por imagen dentro de su carpeta
                try:
                    per_image_results = {
                        "image": annotated_filename,
                        "original_path": img_path,
                        "detections_count": num_detections,
                        "predictions": prediction.get('predictions', [])
                    }
                    resultados_path = os.path.join(per_image_dir, 'resultados.json')
                    with open(resultados_path, 'w', encoding='utf-8') as rf:
                        json.dump(per_image_results, rf, indent=2, ensure_ascii=False)
                except Exception as e:
                    print(f"Error guardando resultados por imagen: {e}")

                image_result = {
                    "original_path": img_path,
                    "image_name": os.path.basename(img_path),
                    "annotated_image_name": annotated_filename,
                    "annotated_image_path": annotated_path,
                    "image_index": idx,
                    "detections_count": num_detections,
                    "annotated_image_base64": img_base64,
                    "predictions": prediction.get('predictions', [])
                }
                
                with lock:
                    processed_count[0] += 1
                    print(f"✓ [{processed_count[0]}/{len(image_paths)}] {os.path.basename(img_path)} - {num_detections} detecciones")
                
                return image_result
            except Exception as e:
                print(f"✗ [{idx}] Error: {str(e)}")
                return None
        
        # Procesar imágenes en paralelo (4 workers por defecto)
        with concurrent.futures.ThreadPoolExecutor(max_workers=4) as executor:
            futures = [
                executor.submit(process_single_image, (idx, img_path))
                for idx, img_path in enumerate(image_paths, 1)
            ]
            
            for future in concurrent.futures.as_completed(futures):
                image_result = future.result()
                if image_result:
                    results["processed_images"].append(image_result)
                    results["total_detections"] += image_result["detections_count"]
                    
                    # Actualizar resumen por clase
                    for pred in image_result.get("predictions", []):
                        class_name = pred.get('class', 'unknown')
                        results["summary"][class_name] = results["summary"].get(class_name, 0) + 1
        
        # Guardar resultados en JSON (sin imágenes base64 para mantener archivo ligero)
        json_path = os.path.join(output_dir, "resultados.json")
        results_to_save = results.copy()
        for img in results_to_save["processed_images"]:
            img.pop("annotated_image_base64", None)
        
        with open(json_path, 'w', encoding='utf-8') as f:
            json.dump(results_to_save, f, indent=2, ensure_ascii=False)
        
        print(f"\n{'='*50}")
        print(f"✓ Procesamiento completado!")
        print(f"  - Imágenes procesadas: {len(results['processed_images'])}")
        print(f"  - Total detecciones: {results['total_detections']}")
        print(f"  - Resultados en: {output_dir}")
        print(f"{'='*50}\n")
        
        return results


# Instancia global del procesador
processor = RoboflowProcessor()

# Inicializar modelo en background al importar el módulo para acelerar el primer procesamiento
try:
    init_thread = threading.Thread(target=processor.initialize, daemon=True)
    init_thread.start()
except Exception as e:
    print(f"Advertencia: No se pudo iniciar inicialización en background: {e}")


def process_batch_images(image_paths, ndc, ndv):
    """
    Función principal para procesar un batch de imágenes
    Esta es la función que se llamará desde el servidor WebSocket
    """
    return processor.process_batch(image_paths, ndc, ndv)