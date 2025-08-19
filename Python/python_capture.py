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

        # Calcular ruta a carpeta_frames relativa a la carpeta raíz Proyecto-Final
        current_dir = os.path.dirname(os.path.abspath(__file__))
        project_root = os.path.dirname(current_dir)
        self.save_dir = os.path.join(project_root, "carpeta_frames")
        os.makedirs(self.save_dir, exist_ok=True)

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
        
        self.fps = cap.get(cv2.CAP_PROP_FPS)
        self.frame_delay = 1.0 / self.fps if self.fps > 0 else 1.0 / 30
        
        total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        print(f"Video cargado - FPS: {self.fps}, Total frames: {total_frames}")
        
        while self.is_running:
            ret, frame = cap.read()
            
            if not ret:
                print("Video terminado, reiniciando...")
                cap.set(cv2.CAP_PROP_POS_FRAMES, 0)
                continue
            
            height, width = frame.shape[:2]
            if width > 1280:
                scale = 1280 / width
                new_width = int(width * scale)
                new_height = int(height * scale)
                frame = cv2.resize(frame, (new_width, new_height))
            
            self.latest_frame = frame.copy()
            self.frame_buffer.append(frame)
            time.sleep(self.frame_delay)
        
        cap.release()
        print("Captura finalizada")
    
    def get_latest_frame(self):
        """Obtiene el frame más reciente"""
        return self.latest_frame
    
    def capture_current_frame(self, NDV, NDC):
        """Captura el frame actual y lo guarda solo en memoria"""
        if self.latest_frame is not None:
            existing_frames = [
                f for f in self.captured_frames
                if f["numero_de_vuelo"] == NDV and f["numero_de_campo"] == NDC
            ]
            NC = len(existing_frames) + 1
            filename = f"{NDC}_{NDV}_{NC}.jpg"

            frame_data = {
                "frame": self.latest_frame.copy(),
                "numero_de_vuelo": NDV,
                "numero_de_campo": NDC,
                "capture_number": NC,
                "filename": filename
            }

            self.captured_frames.append(frame_data)
            print(f"Frame capturado: {filename}")
            return len(self.captured_frames), NC, filename

        return 0, None, None
    
    def get_captured_frames(self):
        return self.captured_frames
    
    def clear_captured_frames(self):
        count = len(self.captured_frames)
        self.captured_frames.clear()
        print(f"Limpiados {count} frames capturados")
        return count
    
    def process_captured_frames(self):
        """Guarda todos los frames capturados en disco y limpia memoria"""
        if not self.captured_frames:
            return []

        results = []
        for frame_data in self.captured_frames:
            filepath = os.path.join(self.save_dir, frame_data["filename"])
            cv2.imwrite(filepath, frame_data["frame"])  # Guardar en disco

            result = {
                "filename": frame_data["filename"],
                "field": frame_data["numero_de_campo"],
                "flight": frame_data["numero_de_vuelo"],
                "capture": frame_data["numero_de_captura"],
                "frame_shape": frame_data["frame"].shape
            }

            results.append(result)

        processed_count = len(self.captured_frames)
        self.captured_frames.clear()
        print(f"Procesados y guardados {processed_count} frames")
        return results
    
    def get_status(self):
        return {
            "is_running": self.is_running,
            "fps": self.fps,
            "buffer_size": len(self.frame_buffer),
            "captured_count": len(self.captured_frames),
            "has_frame": self.latest_frame is not None,
            "video_path": self.video_path
        }

if __name__ == "__main__":
    video_path = os.path.join(os.path.dirname(__file__), "VideoTest.mp4")
    capturer = VideoCapture(video_path)
    capturer.start_capture()

    try:
        while True:
            time.sleep(1)
            status = capturer.get_status()
            print(f"Estado: {status}")
    except KeyboardInterrupt:
        capturer.stop_capture()
