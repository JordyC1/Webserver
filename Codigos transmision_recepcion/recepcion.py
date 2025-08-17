import paho.mqtt.client as mqtt
import mysql.connector
import json
import time

# Configuración de MySQL
db = mysql.connector.connect(
    host="localhost",
    user="admin",
    password="7008",
    database="insectosDB"
)
cursor = db.cursor()

# ---------------- FUNCIONES BASE DE DATOS ----------------
def existe_captura(fecha):
    cursor.execute("SELECT id FROM capturas WHERE fecha = %s", (fecha,))
    return cursor.fetchone()

def insertar_captura(fecha, trampa_id):
    cursor.execute("INSERT INTO capturas (fecha, trampa_id) VALUES (%s, %s)", (fecha, trampa_id))
    db.commit()
    return cursor.lastrowid

def insertar_detecciones(captura_id, insectos):
    for insecto in insectos:
        cursor.execute(
            "INSERT INTO detecciones (captura_id, tipo, cantidad) VALUES (%s, %s, %s)",
            (captura_id, insecto["tipo"], insecto["count"])
        )
    db.commit()

def insertar_estado_trampa(trampa_id, status, timestamp, trampa_adhesiva=None):
    cursor.execute(
        "INSERT INTO trampas (trampa_id, status, timestamp, trampa_adhesiva) "
        "VALUES (%s, %s, %s, %s) "
        "ON DUPLICATE KEY UPDATE status = VALUES(status), timestamp = VALUES(timestamp), trampa_adhesiva = VALUES(trampa_adhesiva)",
        (trampa_id, status, timestamp, trampa_adhesiva)
    )
    db.commit()

# ---------------- FUNCIONES MQTT ----------------
def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print("✅ Conectado al broker MQTT")
        client.subscribe("deteccion/insectos")
        client.subscribe("trampas/status")
    else:
        print(f"❌ Error de conexión MQTT: {rc}")

def on_disconnect(client, userdata, rc):
    print("⚠️ Cliente MQTT desconectado del broker.")

def on_message_insectos(client, userdata, msg):
    try:
        payload = json.loads(msg.payload.decode())
        fecha = payload["fecha"]
        insectos = payload["insects_detected"]
        trampa_id = payload["trampa_id"]  # NUEVO

        captura_id = existe_captura(fecha)
        if not captura_id:
            captura_id = insertar_captura(fecha, trampa_id)
        else:
            captura_id = captura_id[0]

        insertar_detecciones(captura_id, insectos)
        print("📥 Datos de insectos guardados en MySQL:", payload)
    except Exception as e:
        print("❌ Error al procesar mensaje de insectos:", e)

def on_message_trampas(client, userdata, msg):
    try:
        payload = json.loads(msg.payload.decode())
        trampa_id = payload["trampa_id"]
        status = payload["status"]
        timestamp = payload["timestamp"]
        trampa_adhesiva = payload.get("trampa_adhesiva", None)

        insertar_estado_trampa(trampa_id, status, timestamp, trampa_adhesiva)
        print("📥 Estado de trampa actualizado en MySQL:", payload)
    except Exception as e:
        print("❌ Error al procesar mensaje de trampa:", e)

# ---------------- CONFIGURAR CLIENTE MQTT ----------------
client = mqtt.Client()
client.on_connect = on_connect
client.on_disconnect = on_disconnect
client.message_callback_add("deteccion/insectos", on_message_insectos)
client.message_callback_add("trampas/status", on_message_trampas)

client.connect("localhost", 1883, 60)
client.loop_start()

# ---------------- RECONEXION MANUAL ----------------
try:
    while True:
        if not client.is_connected():
            print("🔄 Reintentando conexión con el broker...")
            try:
                client.reconnect()
            except Exception as e:
                print(f"❌ Error al reconectar: {e}")
        time.sleep(5)

except KeyboardInterrupt:
    print("\n🛑 Script interrumpido por el usuario.")
    client.loop_stop()
    client.disconnect()
    db.close()
