import asyncio
import websockets
import cv2
import os
import base64
import json
from python_capture import VideoCapture

class WebSocketServer:
    def __init__(self, video_path, host="localhost", port=8000):
        self.host = host
        self.port = port
        self.video_capture = VideoCapture(video_path)
        print(f"Servidor WebSocket inicializado en ws://{host}:{port}")
    
    async def handle_client(self, websocket):
        client_address = websocket.remote_address
        print(f"Cliente conectado: {client_address}")
        
        try:
            self.video_capture.start_capture()
            frame_task = asyncio.create_task(self.send_frames(websocket))
            
            async for message in websocket:
                await self.handle_command(websocket, message)
        
        except websockets.exceptions.ConnectionClosed:
            print(f"Cliente desconectado: {client_address}")
        except Exception as e:
            print(f"Error con cliente {client_address}: {e}")
        finally:
            if 'frame_task' in locals():
                frame_task.cancel()
    
    async def send_frames(self, websocket):
        try:
            while True:
                frame = self.video_capture.get_latest_frame()
                if frame is not None:
                    _, buffer = cv2.imencode('.jpg', frame, [cv2.IMWRITE_JPEG_QUALITY, 80])
                    frame_base64 = base64.b64encode(buffer.tobytes()).decode('utf-8')
                    await websocket.send(json.dumps({"type": "frame", "data": frame_base64}))
                await asyncio.sleep(1/30)
        except asyncio.CancelledError:
            print("Envío de frames cancelado")
        except Exception as e:
            print(f"Error enviando frames: {e}")
    
    async def handle_command(self, websocket, message):
        try:
            command = json.loads(message)
            command_type = command.get("command")
            
            print(f"DEBUG: Comando recibido: {command_type}")  # Agregado para debug
            
            if command_type == "capture":
                NDV = command.get("NDV", "NDV_default")
                NDC = command.get("NDC", "NDC_default")
                print(f"DEBUG: Capturando con NDV={NDV}, NDC={NDC}")  # Agregado para debug
                
                count, timestamp, filename = self.video_capture.capture_current_frame(NDV, NDC)
                
                print(f"DEBUG: Resultado captura - count={count}, filename={filename}")  # Agregado para debug
                
                await websocket.send(json.dumps({
                    "type": "response",
                    "status": "captured",
                    "count": count,
                    "timestamp": timestamp,
                    "filename": filename
                }))
                print(f"DEBUG: Respuesta enviada al cliente")  # Agregado para debug

            elif command_type == "saveCaptures":
                print(f"DEBUG: Procesando capturas...")  # Agregado para debug
                results = self.video_capture.process_captured_frames()
                if results:
                    await websocket.send(json.dumps({
                        "type": "response",
                        "status": "saved",
                        "message": f"Guardadas {len(results)} capturas",
                        "count": 0,
                        "results": results,
                    }))
                    print(f"DEBUG: {len(results)} capturas guardadas")  # Agregado para debug
                else:
                    await websocket.send(json.dumps({
                        "type": "response",
                        "status": "no_frames",
                        "message": "No hay frames para guardar",
                        "count": 0,
                        "results": []
                    }))
                    print(f"DEBUG: No había frames para guardar")  # Agregado para debug

            elif command_type == "undo":
                if self.video_capture.captured_frames:
                    removed_frame = self.video_capture.captured_frames.pop()
                    count = len(self.video_capture.captured_frames)
                    await websocket.send(json.dumps({
                        "type": "response",
                        "status": "undone",
                        "count": count,
                        "filename": removed_frame["filename"]
                    }))
                    print(f"DEBUG: Frame deshecho, quedan {count}")  # Agregado para debug
                else:
                    await websocket.send(json.dumps({
                        "type": "response",
                        "status": "no_frames",
                        "message": "No hay frames para deshacer"
                    }))
                    print(f"DEBUG: No había frames para deshacer")  # Agregado para debug

            elif command_type == "process":
                await websocket.send(json.dumps({
                    "type": "response",
                    "status": "processed",
                    "message": "Comando process no implementado"
                }))

            elif command_type == "deleteCapture":
                NDV = command.get("NDV", "")
                NDC = command.get("NDC", "")
                filename = command.get("filename", "")
                
                print(f"DEBUG: Eliminando captura - NDC={NDC}, NDV={NDV}, filename={filename}")
                
                flight_key = f"{NDC}_{NDV}"
                if flight_key in self.video_capture.flight_captures and self.video_capture.flight_captures[flight_key] > 0:
                    self.video_capture.flight_captures[flight_key] -= 1
                    self.video_capture.save_flight_captures()
                    
                    await websocket.send(json.dumps({
                        "type": "response",
                        "status": "deleted",
                        "message": f"Captura eliminada: {filename}",
                        "flight_key": flight_key,
                        "new_count": self.video_capture.flight_captures[flight_key]
                    }))
                    print(f"DEBUG: Contador actualizado para {flight_key}: {self.video_capture.flight_captures[flight_key]}")
                else:
                    await websocket.send(json.dumps({
                        "type": "response",
                        "status": "not_found",
                        "message": f"No se encontró el registro para {flight_key}"
                    }))
                    print(f"DEBUG: No se encontró registro para {flight_key}")

            elif command_type == "clear":
                count = self.video_capture.clear_captured_frames()
                await websocket.send(json.dumps({
                    "type": "response",
                    "status": "cleared",
                    "cleared_count": count
                }))
                print(f"DEBUG: {count} frames limpiados")  # Agregado para debug

            elif command_type == "status":
                status = self.video_capture.get_status()
                await websocket.send(json.dumps({
                    "type": "response",
                    "status": "running",
                    "video_status": status
                }))

            elif command_type == "stop":  # CORREGIDO: era command == "stop"
                print("Comando: detener captura")
                self.video_capture.stop_capture()
            
            else:
                print(f"DEBUG: Comando desconocido: {command_type}")  # Agregado para debug
                await websocket.send(json.dumps({
                    "type": "error",
                    "message": f"Comando desconocido: {command_type}"
                }))
        
        except json.JSONDecodeError as e:
            print(f"DEBUG: Error JSON: {e}")  # Agregado para debug
            await websocket.send(json.dumps({"type": "error","message": "Formato JSON inválido"}))
        except Exception as e:
            print(f"DEBUG: Error general: {e}")  # Agregado para debug
            await websocket.send(json.dumps({"type": "error","message": f"Error procesando comando: {str(e)}"}))
    
    async def start_server(self):
        print(f"Iniciando servidor en ws://{self.host}:{self.port}")
        async with websockets.serve(self.handle_client, self.host, self.port):
            print("Servidor iniciado. Presiona Ctrl+C para detener.")
            try:
                await asyncio.Future()
            except asyncio.CancelledError:
                print("\nDeteniendo servidor...")
                self.video_capture.stop_capture()

if __name__ == "__main__":
    video_path = os.path.join(os.path.dirname(__file__), "VideoTest.mp4")
    server = WebSocketServer(video_path)
    asyncio.run(server.start_server())