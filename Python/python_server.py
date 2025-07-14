import asyncio
import websockets
import cv2
import os
import base64
import json
from python_capture import VideoCapture
import functools

class WebSocketServer:
    def __init__(self, video_path, host="localhost", port=8000):
        self.host = host
        self.port = port
        
        # Crear capturador de video
        self.video_capture = VideoCapture(video_path)
        
        print(f"Servidor WebSocket inicializado en ws://{host}:{port}")
    
    async def handle_client(self, websocket):
        """Maneja cada cliente conectado"""
        client_address = websocket.remote_address
        print(f"Cliente conectado: {client_address}")
        
        try:
            # Iniciar captura de video
            self.video_capture.start_capture()
            
            # Iniciar envío de frames
            frame_task = asyncio.create_task(self.send_frames(websocket))
            
            # Escuchar comandos del cliente
            async for message in websocket:
                await self.handle_command(websocket, message)
        
        except websockets.exceptions.ConnectionClosed:
            print(f"Cliente desconectado: {client_address}")
        except Exception as e:
            print(f"Error con cliente {client_address}: {e}")
        finally:
            # Cancelar envío de frames
            if 'frame_task' in locals():
                frame_task.cancel()
    
    async def send_frames(self, websocket):
        """Envía frames de video continuamente"""
        try:
            while True:
                frame = self.video_capture.get_latest_frame()
                
                if frame is not None:
                    # Convertir frame a JPEG
                    _, buffer = cv2.imencode('.jpg', frame, 
                                          [cv2.IMWRITE_JPEG_QUALITY, 80])
                    
                    # Convertir a base64
                    frame_base64 = base64.b64encode(buffer.tobytes()).decode('utf-8')
                    
                    # Enviar frame
                    await websocket.send(json.dumps({
                        "type": "frame",
                        "data": frame_base64
                    }))
                
                # Enviar a 30 FPS
                await asyncio.sleep(1/30)
        
        except asyncio.CancelledError:
            print("Envío de frames cancelado")
        except Exception as e:
            print(f"Error enviando frames: {e}")
    
    async def handle_command(self, websocket, message):
        """Maneja comandos recibidos del cliente"""
        try:
            command = json.loads(message)
            command_type = command.get("command")
            
            if command_type == "capture":
                # Capturar frame actual
                count, timestamp = self.video_capture.capture_current_frame()
                
                await websocket.send(json.dumps({
                    "type": "response",
                    "status": "captured",
                    "count": count,
                    "timestamp": timestamp
                }))
            
            elif command_type == "process":
                # Procesar frames capturados
                results = self.video_capture.process_captured_frames()
                
                if results:
                    await websocket.send(json.dumps({
                        "type": "response",
                        "status": "processed",
                        "results": results
                    }))
                else:
                    await websocket.send(json.dumps({
                        "type": "response",
                        "status": "no_frames"
                    }))
            
            elif command_type == "clear":
                # Limpiar frames capturados
                count = self.video_capture.clear_captured_frames()
                
                await websocket.send(json.dumps({
                    "type": "response",
                    "status": "cleared",
                    "cleared_count": count
                }))
            
            elif command_type == "status":
                # Enviar estado del sistema
                status = self.video_capture.get_status()
                
                await websocket.send(json.dumps({
                    "type": "response",
                    "status": "running",
                    "video_status": status
                }))
            elif command == "stop":
                print("Comando: detener captura")
                self.video_capture.stop_capture()
            
            else:
                # Comando desconocido
                await websocket.send(json.dumps({
                    "type": "error",
                    "message": f"Comando desconocido: {command_type}"
                }))
        
        except json.JSONDecodeError:
            await websocket.send(json.dumps({
                "type": "error",
                "message": "Formato JSON inválido"
            }))
        except Exception as e:
            await websocket.send(json.dumps({
                "type": "error",
                "message": f"Error procesando comando: {str(e)}"
            }))
    
    async def start_server(self):
        """Inicia el servidor WebSocket"""
        print(f"Iniciando servidor en ws://{self.host}:{self.port}")


        async with websockets.serve(self.handle_client, self.host, self.port):
            print("Servidor iniciado. Presiona Ctrl+C para detener.")
            try:
                await asyncio.Future()  # Ejecuta el servidor indefinidamente
            except asyncio.CancelledError:
                print("\nDeteniendo servidor...")
                self.video_capture.stop_capture()

# Ejecutar servidor
if __name__ == "__main__":
    # CAMBIAR POR LA RUTA DE TU VIDEO
    video_path = os.path.join(os.path.dirname(__file__), "VideoTest.mp4")
    
    # Crear y ejecutar servidor
    server = WebSocketServer(video_path)
    asyncio.run(server.start_server())