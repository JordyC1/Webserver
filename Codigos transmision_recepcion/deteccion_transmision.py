import os
import cv2
import json
import time
import board
import numpy as np
import paho.mqtt.client as mqtt
from datetime import datetime
from collections import defaultdict
from ultralytics import YOLO
import neopixel_spi as neopixel

# -------------------- CONFIGURACIÓN --------------------
NUM_PIXELS = 16
PIXEL_ORDER = neopixel.GRB
BRIGHTNESS = 1.0
DETECCION_THRESHOLD = 0.4

BROKER_IP = "raspberrypi2.local"
TOPIC_INSECTOS = "deteccion/insectos"
TOPIC_TRAMPAS = "trampas/status"
TRAMPA_ID = 1

MODEL_PATH = "/home/Jordy/proyectofinalyolo/my_model_ncnn_model"
model = YOLO(MODEL_PATH)
labels = model.names

RES_W, RES_H = 3840, 3040
ZOOM_FACTOR = 1.5
CAPTURES_PER_CYCLE = 2
SECONDS_BETWEEN_CAPTURES = 10
CYCLE_INTERVAL = 160

AUDITORIA_DIR = "/home/Jordy/proyectofinalyolo/auditoria"
PENDIENTES_FILE = "/home/Jordy/proyectofinalyolo/pendientes_mqtt.json"
os.makedirs(AUDITORIA_DIR, exist_ok=True)

last_conteo = defaultdict(int)

# -------------------- INICIALIZACIÓN --------------------
spi = board.SPI()
pixels = neopixel.NeoPixel_SPI(spi, NUM_PIXELS, pixel_order=PIXEL_ORDER, auto_write=False)
pixels.brightness = BRIGHTNESS

mqtt_client = mqtt.Client()
conexion_mqtt = False
conexion_establecida = False

# -------------------- MQTT CALLBACKS --------------------
def on_connect(client, userdata, flags, rc):
    global conexion_mqtt, conexion_establecida
    if rc == 0:
        print("✅ Conectado exitosamente al broker MQTT.")
        conexion_mqtt = True
        conexion_establecida = True
    else:
        print(f"❌ Fallo al conectar con el broker. Código: {rc}")
        conexion_mqtt = False

def on_disconnect(client, userdata, rc):
    global conexion_mqtt
    print("⚠️ MQTT desconectado.")
    conexion_mqtt = False

mqtt_client.on_connect = on_connect
mqtt_client.on_disconnect = on_disconnect
mqtt_client.loop_start()

def intentar_conectar_mqtt():
    global conexion_establecida
    conexion_establecida = False
    try:
        mqtt_client.connect(BROKER_IP, 1883, 60)
        for _ in range(30):
            if conexion_establecida:
                return True
            time.sleep(0.1)
        print("⏳ Timeout esperando conexión MQTT.")
        return False
    except Exception as e:
        print(f"❌ Error al conectar MQTT: {e}")
        return False

conexion_mqtt = intentar_conectar_mqtt()

# -------------------- INICIALIZAR CÁMARA --------------------
cap = None

while True:
    if cap is not None:
        cap.release()

    cap = cv2.VideoCapture(0, cv2.CAP_V4L2)
    cap.set(cv2.CAP_PROP_FOURCC, cv2.VideoWriter_fourcc(*"MJPG"))
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, RES_W)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, RES_H)
    cap.set(cv2.CAP_PROP_FPS, 30)
    cap.set(cv2.CAP_PROP_AUTO_EXPOSURE, 1)
    cap.set(cv2.CAP_PROP_EXPOSURE, -5)
    cap.set(cv2.CAP_PROP_BRIGHTNESS, 0.6)
    cap.set(cv2.CAP_PROP_CONTRAST, 0.5)

    if cap.isOpened():
        print("? Cámara detectada correctamente.")
        break  # ✅ salir del bucle y continuar con el código

    print("? Esperando a que se conecte la cámara...")
    pixels.fill((255, 0, 0))  # LED rojo como indicativo de error
    pixels.show()
    time.sleep(5)


# -------------------- FUNCIONES --------------------
def aplicar_zoom(frame):
    h, w, _ = frame.shape
    cx, cy = w // 2, h // 2
    nw, nh = int(w / ZOOM_FACTOR), int(h / ZOOM_FACTOR)
    x1, y1 = cx - nw // 2, cy - nh // 2
    x2, y2 = cx + nw // 2, cy + nh // 2
    return cv2.resize(frame[y1:y2, x1:x2], (w, h), interpolation=cv2.INTER_LINEAR)

def publicar_estado_trampa(hay_trampa_adhesiva):
    estado = {
        "trampa_id": TRAMPA_ID,
        "status": "active",
        "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "trampa_adhesiva": hay_trampa_adhesiva
    }
    publicar_mqtt(TOPIC_TRAMPAS, estado)

def draw_bounding_boxes(frame, results, conteo_actual):
    colors = [
        (164,120,87), (68,148,228), (93,97,209), (178,182,133),
        (88,159,106), (96,202,231), (159,124,168), (169,162,241),
        (98,118,150), (172,176,184)
    ]

    contador_por_clase = defaultdict(int)
    total_insectos = 0

    for box in results.boxes:
        conf = box.conf.item()
        if conf < DETECCION_THRESHOLD:
            continue

        class_id = int(box.cls.item())
        nombre_clase = labels[class_id]
        if nombre_clase == "Trampa adhesiva":
            continue

        contador_por_clase[nombre_clase] += 1
        total_insectos += 1
        numero = contador_por_clase[nombre_clase]
        cantidad_anterior = last_conteo.get(nombre_clase, 0)
        es_nuevo = numero > cantidad_anterior

        label_texto = f"{numero}: {nombre_clase} {conf:.2f}"
        x1, y1, x2, y2 = map(int, box.xyxy[0])
        color = colors[class_id % len(colors)]

        cv2.rectangle(frame, (x1, y1), (x2, y2), color, 2)

        if es_nuevo:
            label = f"NUEVO: {label_texto}"
            font_scale = 0.9
            font_thickness = 2
            font_color = (0, 255, 255)
        else:
            label = label_texto
            font_scale = 0.5
            font_thickness = 1
            font_color = (0, 0, 0)

        label_size, base_line = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, font_scale, font_thickness)
        label_ymin = max(y1, label_size[1] + 10)

        cv2.rectangle(frame,
                      (x1, label_ymin - label_size[1] - 10),
                      (x1 + label_size[0], label_ymin + base_line - 10),
                      color, cv2.FILLED)
        cv2.putText(frame, label, (x1, label_ymin - 7), cv2.FONT_HERSHEY_SIMPLEX,
                    font_scale, font_color, font_thickness)

    texto_total = f"Numero de insectos detectados: {total_insectos}"
    cv2.putText(frame, texto_total, (10, 40), cv2.FONT_HERSHEY_SIMPLEX, 1.9, (0, 255, 255), 3)
    return frame

def capturar_y_analizar():
    global last_conteo
    pixels.fill((255, 255, 255))
    pixels.show()

    hay_trampa_adhesiva = False

    for i in range(CAPTURES_PER_CYCLE):
        for _ in range(5): cap.read(); time.sleep(0.05)
        ret, frame = cap.read()
        if not ret:
            print(f"⚠️ No se pudo capturar el frame {i + 1}")
            continue

        zoomed = aplicar_zoom(frame)
        conteo = defaultdict(int)
        results = model(zoomed, verbose=False)[0]

        for box in results.boxes:
            conf = box.conf.item()
            if conf < DETECCION_THRESHOLD:
                continue
            class_id = int(box.cls.item())
            nombre_clase = labels[class_id]
            if nombre_clase == "Trampa adhesiva":
                hay_trampa_adhesiva = True
                continue
            conteo[nombre_clase] += 1

        frame_annotated = draw_bounding_boxes(zoomed.copy(), results, conteo)
        now = datetime.now()
        timestamp = now.strftime("%Y-%m-%d_%H-%M-%S")
        day_folder = now.strftime("%Y-%m-%d")
        hour_folder = now.strftime("%H")
        ruta_subcarpeta = os.path.join(AUDITORIA_DIR, day_folder, hour_folder)
        os.makedirs(ruta_subcarpeta, exist_ok=True)
        cv2.imwrite(os.path.join(ruta_subcarpeta, f"{timestamp}.jpg"), frame_annotated)

        publicar_resultados(conteo)
        last_conteo = conteo.copy()
        time.sleep(SECONDS_BETWEEN_CAPTURES)

    publicar_estado_trampa(hay_trampa_adhesiva)
    pixels.fill((0, 0, 0))
    pixels.show()

def publicar_resultados(conteo_dict):
    fecha_actual = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    if conteo_dict:
        lista = [{"tipo": k, "count": v} for k, v in conteo_dict.items()]
    else:
        lista = [{"tipo": "Ninguno", "count": 0}]
    payload = {
        "fecha": fecha_actual,
        "trampa_id": TRAMPA_ID,
        "insects_detected": lista
    }
    publicar_mqtt(TOPIC_INSECTOS, payload)

def publicar_mqtt(topic, data):
    global conexion_mqtt
    try:
        if not conexion_mqtt:
            if not intentar_conectar_mqtt():
                raise Exception("No conectado")
        result = mqtt_client.publish(topic, json.dumps(data))
        result.wait_for_publish()
        if result.rc != mqtt.MQTT_ERR_SUCCESS:
            raise Exception("Publicación fallida")
        print(f"📤 Publicado en {topic}:\n{json.dumps(data, indent=2)}")
    except:
        print("⚠️ Guardando en archivo temporal por fallo MQTT")
        guardar_en_pendientes(topic, data)
        conexion_mqtt = False

def guardar_en_pendientes(topic, data):
    try:
        pendientes = []
        if os.path.exists(PENDIENTES_FILE):
            with open(PENDIENTES_FILE, "r") as f:
                pendientes = json.load(f)
        pendientes.append({"topic": topic, "data": data})
        with open(PENDIENTES_FILE, "w") as f:
            json.dump(pendientes, f, indent=2)
    except Exception as e:
        print(f"❌ Error guardando en pendientes: {e}")

def reenviar_pendientes():
    global conexion_mqtt
    if os.path.exists(PENDIENTES_FILE) and conexion_mqtt:
        try:
            with open(PENDIENTES_FILE, "r") as f:
                pendientes = json.load(f)
            for p in pendientes:
                mqtt_client.publish(p["topic"], json.dumps(p["data"]))
                print(f"✅ Reenviado pendiente a {p['topic']}")
            os.remove(PENDIENTES_FILE)
        except Exception as e:
            print(f"❌ Error reenviando pendientes: {e}")

# -------------------- CICLO PRINCIPAL --------------------
try:
    while True:
        capturar_y_analizar()
        reenviar_pendientes()
        time.sleep(CYCLE_INTERVAL)

except KeyboardInterrupt:
    print("\n🛑 Interrumpido por el usuario.")
    pixels.fill((0, 0, 0))
    pixels.show()
    cap.release()
    cv2.destroyAllWindows()
    mqtt_client.loop_stop()
    mqtt_client.disconnect()
