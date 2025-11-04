import cv2, time

print("Inicializando opencv...")
cap = cv2.VideoCapture(1)
if not cap.isOpened():
    print("❌ No se pudo abrir la cámara.")
    exit()

print("✅ Cámara abierta, esperando primer frame...")

for i in range(20):
    ret, frame = cap.read()
    print(f"Intento {i+1}: ret={ret}")
    if ret:
        print("🎬 Primer frame recibido ✅")
        cv2.imshow("Cámara USB", frame)
        cv2.waitKey(3000)
        break
    time.sleep(0.5)

cap.release()
cv2.destroyAllWindows()
