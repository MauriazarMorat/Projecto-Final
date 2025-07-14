#!/usr/bin/env python3
"""
Ejecutor principal para el sistema de video streaming
"""
import asyncio
import sys
import os
import cv2
from python_server import WebSocketServer
#C:\Users\Mauricio\Documents\GitHub\Projecto-Final\Python\Assets\VideoTest.mp4

def main():
    # Verificar argumentos
    video_path = os.path.join(os.path.dirname(__file__), "VideoTest.mp4")
    # Verificar que el archivo existe
    if not os.path.exists(video_path):
        print(f"Error: El archivo {video_path} no existe")
        sys.exit(1)
    
    print(f"Iniciando servidor con video: {video_path}")

    # Crear y ejecutar servidor
    server = WebSocketServer("VideoTest.mp4")
    print(os.path.abspath(video_path))
    asyncio.run(server.start_server())

if __name__ == "__main__":
    main()