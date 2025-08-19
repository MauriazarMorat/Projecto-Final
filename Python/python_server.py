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
            
            if command_type == "capture":
                NDV = command.get("NDV", "NDV_default")
                NDC = command.get("NDC", "NDC_default")
                count, timestamp, filename = self.video_capture.capture_current_frame(NDV, NDC)
                
                await websocket.send(json.dumps({
                    "type": "response",
                    "status": "captured",
                    "count": count,
                    "timestamp": timestamp,
                    "filename": filename
                }))

            elif command_type == "saveCaptures":
                results = self.video_capture.process_captured_frames()
                if results:
                    await websocket.send(json.dumps({
                        "type": "response",
                        "status": "saved",
                        "message": "Capturas guardadas"
                    }))
                else:
                    await websocket.send(json.dumps({
                        "type": "response",
                        "status": "no_frames",
                        "message": "No hay frames para guardar"
                    }))
            elif command_type == "undo":
                if self.video_capture.captured_frames:
                    removed_frame = self.video_capture.captured_frames.pop()  # Quita la última captura
                    count = len(self.video_capture.captured_frames)
                    await websocket.send(json.dumps({
                        "type": "response",
                        "status": "undone",
                        "count": count,
                        "filename": removed_frame["filename"],
                        "capture": removed_frame["numero_de_captura"]
                    }))
                else:
                    await websocket.send(json.dumps({
                        "type": "response",
                        "status": "no_frames",
                        "message": "No hay frames para deshacer"
                    }))
            elif command_type == "list_captures":
                captures = []
                for frame in self.video_capture.captured_frames:
                    captures.appen({
                        "flight": frame["flight"],
                        "field": frame["field"],
                        "capture": frame["capture"],
                        "filename": frame["filename"]
                    })
                await websocket.send(json.dumps({
                    "type": "captures_list",
                    "captures": captures
                }))

            elif command_type == "process":
                await websocket.send(json.dumps({
                    "type": "response",
                    "status": "processed",
                    "message": "Comando process no implementado"
                }))

            elif command_type == "clear":
                count = self.video_capture.clear_captured_frames()
                await websocket.send(json.dumps({
                    "type": "response",
                    "status": "cleared",
                    "cleared_count": count
                }))

            elif command_type == "status":
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
                await websocket.send(json.dumps({
                    "type": "error",
                    "message": f"Comando desconocido: {command_type}"
                }))
                
        
        except json.JSONDecodeError:
            await websocket.send(json.dumps({"type": "error","message": "Formato JSON inválido"}))
        except Exception as e:
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
