import cv2
import os
import time
import threading
from collections import deque
from datetime import datetime

class VideoCapture:
    def __init__(self, video_path, buffer_size=30):
        self.video_path = os.path.join(os.path.dirname(__file__), "VideoTest.mp4")
        self.buffer_size = buffer_size
        
        # Buffer para frames
        self.frame_buffer = deque(maxlen=buffer_size)
        self.latest_frame = None
        self.captured_frames = []
        
        # Control de threads
        self.is_running = False
        self.capture_thread = None
        
        # Información del video
        self.fps = 30
        self.frame_delay = 1.0 / 30
        
    def start_capture(self):
        """Inicia la captura de video en un hilo separado"""
        if not self.is_running:
            self.is_running = True
            self.capture_thread = threading.Thread(target=self._capture_loop, daemon=True)
            self.capture_thread.start()
            print(f"Captura iniciada: {self.video_path}")
        
    def stop_capture(self):
        """Detiene la captura de video"""
        self.is_running = False
        if self.capture_thread:
            self.capture_thread.join()
        print("Captura detenida")
    
    def _capture_loop(self):
        """Loop principal de captura (ejecuta en hilo separado)"""
        cap = cv2.VideoCapture(self.video_path)
        
        if not cap.isOpened():
            print(f"Error: No se pudo abrir el video {self.video_path}")
            self.is_running = False
            return
        
        # Obtener FPS del video
        self.fps = cap.get(cv2.CAP_PROP_FPS)
        self.frame_delay = 1.0 / self.fps if self.fps > 0 else 1.0 / 30
        
        total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        print(f"Video cargado - FPS: {self.fps}, Total frames: {total_frames}")
        
        while self.is_running:
            ret, frame = cap.read()
            
            if not ret:
                # Video terminó, reiniciar desde el principio
                print("Video terminado, reiniciando...")
                cap.set(cv2.CAP_PROP_POS_FRAMES, 0)
                continue
            
            # Redimensionar si es muy grande (opcional)
            height, width = frame.shape[:2]
            if width > 1280:
                scale = 1280 / width
                new_width = int(width * scale)
                new_height = int(height * scale)
                frame = cv2.resize(frame, (new_width, new_height))
            
            # Actualizar buffer
            self.latest_frame = frame.copy()
            self.frame_buffer.append(frame)
            
            # Esperar según el FPS del video
            time.sleep(self.frame_delay)
        
        cap.release()
        print("Captura finalizada")
    
    def get_latest_frame(self):
        """Obtiene el frame más reciente"""
        return self.latest_frame
    
    def capture_current_frame(self):
        """Captura el frame actual para procesamiento posterior"""
        if self.latest_frame is not None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S_%f")
            frame_data = {
                "frame": self.latest_frame.copy(),
                "timestamp": timestamp
            }
            self.captured_frames.append(frame_data)
            print(f"Frame capturado: {timestamp}")
            return len(self.captured_frames), timestamp
        return 0, None
    
    def get_captured_frames(self):
        """Obtiene todos los frames capturados"""
        return self.captured_frames
    
    def clear_captured_frames(self):
        """Limpia todos los frames capturados"""
        count = len(self.captured_frames)
        self.captured_frames.clear()
        print(f"Limpiados {count} frames capturados")
        return count
    
    def process_captured_frames(self):
        """Procesa todos los frames capturados y los guarda"""
        if not self.captured_frames:
            return []
        
        results = []
        save_dir = os.path.join(os.path.dirname(__file__), "captured_frames")
        os.makedirs(save_dir, exist_ok=True)
    
        for frame_data in self.captured_frames:
            filename = f"captured_frame_{frame_data['timestamp']}.jpg"
            filepath = os.path.join(save_dir, filename)

            cv2.imwrite(filepath, frame_data["frame"])
            
            # Simular resultado de procesamiento
            # Aquí iría tu código de PyTorch
            result = {
                "filename": filename,
                "timestamp": frame_data["timestamp"],
                "prediction": "simulado_resultado",
                "confidence": 0.95,
                "frame_shape": frame_data["frame"].shape
            }
            results.append(result)
        
        # Limpiar frames después de procesar
        processed_count = len(self.captured_frames)
        self.captured_frames.clear()
        
        print(f"Procesados {processed_count} frames")
        return results
    
    def get_status(self):
        """Obtiene el estado actual del capturador"""
        return {
            "is_running": self.is_running,
            "fps": self.fps,
            "buffer_size": len(self.frame_buffer),
            "captured_count": len(self.captured_frames),
            "has_frame": self.latest_frame is not None,
            "video_path": self.video_path
        }

# Ejemplo de uso
if __name__ == "__main__":
    # Cambiar por la ruta de tu video
    video_path = os.path.join(os.path.dirname(__file__), "VideoTest.mp4")
    # Crear capturador
    capturer = VideoCapture(video_path)
    
    # Iniciar captura
    capturer.start_capture()
    
    try:
        # Mantener el programa corriendo
        while True:
            time.sleep(1)
            status = capturer.get_status()
            print(f"Estado: {status}")
    except KeyboardInterrupt:
        print("\nDeteniendo...")
        capturer.stop_capture()