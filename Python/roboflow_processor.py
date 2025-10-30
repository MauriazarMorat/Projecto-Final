import os
import json
from roboflow import Roboflow
from PIL import Image, ImageDraw
import base64
from io import BytesIO

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
    
    def annotate_image(self, img_path, prediction):
        """Anotar imagen con las detecciones y retornar en base64"""
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
            
            # Convertir a base64
            buffered = BytesIO()
            image.save(buffered, format="JPEG", quality=85)
            img_base64 = base64.b64encode(buffered.getvalue()).decode()
            
            return img_base64
        except Exception as e:
            print(f"Error anotando imagen: {e}")
            return None
    
    def save_annotated_image(self, img_path, prediction, output_dir, idx):
        """Guardar imagen anotada en disco"""
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
            
            output_path = os.path.join(output_dir, f"annotated_{idx:03d}.jpg")
            image.save(output_path, quality=95)
            
            return output_path
        except Exception as e:
            print(f"Error guardando imagen anotada: {e}")
            return None
    
    def process_batch(self, image_paths, ndc, ndv):
        """
        Procesar un batch completo de imágenes
        
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
        
        # Crear carpeta de salida
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
        print(f"{'='*50}\n")
        
        for idx, img_path in enumerate(image_paths, 1):
            try:
                if not os.path.exists(img_path):
                    print(f"⚠ Imagen no encontrada: {img_path}")
                    continue
                
                print(f"[{idx}/{len(image_paths)}] Procesando: {os.path.basename(img_path)}")
                
                # Hacer predicción
                prediction = self.process_image(img_path)
                
                if prediction is None:
                    print(f"  ✗ Error en predicción")
                    continue
                
                num_detections = len(prediction.get('predictions', []))
                
                # Anotar imagen y obtener base64
                img_base64 = self.annotate_image(img_path, prediction)
                
                # Guardar imagen anotada en disco
                output_path = self.save_annotated_image(img_path, prediction, output_dir, idx)
                
                image_result = {
                    "original_path": img_path,
                    "image_name": os.path.basename(img_path),
                    "image_index": idx,
                    "detections_count": num_detections,
                    "output_path": output_path,
                    "annotated_image_base64": img_base64,
                    "predictions": prediction.get('predictions', [])
                }
                
                results["processed_images"].append(image_result)
                results["total_detections"] += num_detections
                
                # Actualizar resumen por clase
                for pred in prediction.get('predictions', []):
                    class_name = pred.get('class', 'unknown')
                    results["summary"][class_name] = results["summary"].get(class_name, 0) + 1
                
                print(f"  ✓ Detecciones: {num_detections}")
                
            except Exception as e:
                print(f"  ✗ Error: {str(e)}")
                continue
        
        # Guardar resultados en JSON
        json_path = os.path.join(output_dir, "resultados.json")
        with open(json_path, 'w', encoding='utf-8') as f:
            # Guardar sin imágenes base64 para mantener archivo ligero
            results_to_save = results.copy()
            for img in results_to_save["processed_images"]:
                img.pop("annotated_image_base64", None)
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


def process_batch_images(image_paths, ndc, ndv):
    """
    Función principal para procesar un batch de imágenes
    Esta es la función que se llamará desde el servidor WebSocket
    """
    return processor.process_batch(image_paths, ndc, ndv)