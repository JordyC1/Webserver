# Sistema de Alertas - Documentación Completa

## Índice
1. [Resumen General](#resumen-general)
2. [Estructura de Base de Datos](#estructura-de-base-de-datos)
3. [Endpoints PHP](#endpoints-php)
4. [Servicio Flutter (AlertService)](#servicio-flutter-alertservice)
5. [Interfaz de Usuario](#interfaz-de-usuario)
6. [Flujo de Datos](#flujo-de-datos)
7. [Casos de Uso](#casos-de-uso)
8. [Configuración y Despliegue](#configuración-y-despliegue)

---

## Resumen General

El sistema de alertas permite detectar, registrar, visualizar y gestionar alertas relacionadas con la detección de insectos en tiempo real. El sistema está compuesto por:

- **Base de datos MySQL** para persistencia
- **3 endpoints PHP** para API REST
- **Servicio Flutter** para lógica de negocio
- **Pantalla de historial** para gestión de alertas

---

## Estructura de Base de Datos

### Tabla `alertas`

```sql
CREATE TABLE alertas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tipo VARCHAR(100) NOT NULL,
    mensaje TEXT NOT NULL,
    fecha DATETIME NOT NULL,
    severidad ENUM('alta', 'media', 'baja') NOT NULL,
    estado ENUM('activa', 'resuelta', 'descartada') DEFAULT 'activa',
    captura_id INT NULL,
    trampa_id INT NULL,
    fecha_resolucion DATETIME NULL,
    notas_resolucion TEXT NULL,
    FOREIGN KEY (captura_id) REFERENCES capturas(id),
    FOREIGN KEY (trampa_id) REFERENCES trampas(id)
);
```

### Campos Explicados

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | INT | Identificador único de la alerta |
| `tipo` | VARCHAR(100) | Tipo de alerta (ej: "deteccion_alta", "trampa_inactiva") |
| `mensaje` | TEXT | Descripción detallada de la alerta |
| `fecha` | DATETIME | Fecha y hora de creación de la alerta |
| `severidad` | ENUM | Nivel de importancia: alta, media, baja |
| `estado` | ENUM | Estado actual: activa, resuelta, descartada |
| `captura_id` | INT | ID de captura relacionada (opcional) |
| `trampa_id` | INT | ID de trampa relacionada (opcional) |
| `fecha_resolucion` | DATETIME | Fecha de resolución (solo si estado != activa) |
| `notas_resolucion` | TEXT | Notas del usuario al resolver (opcional) |

---

## Endpoints PHP

### 1. `registrar_alerta.php`

**Propósito**: Crear nuevas alertas en el sistema

**Método**: POST  
**Content-Type**: application/json

#### Request Body
```json
{
    "tipo": "deteccion_alta",
    "mensaje": "Detección de alta cantidad de insectos",
    "severidad": "alta",
    "captura_id": 123,
    "trampa_id": 1
}
```

#### Response Success
```json
{
    "success": true,
    "message": "Alerta registrada exitosamente",
    "alerta_id": 45
}
```

#### Validaciones
- Campos requeridos: `tipo`, `mensaje`, `severidad`
- Severidad debe ser: "alta", "media", "baja"
- Previene duplicados (alertas similares en 5 minutos)

---

### 2. `get_alertas.php`

**Propósito**: Obtener listado de alertas con filtros

**Método**: GET

#### Parámetros Query
| Parámetro | Tipo | Default | Descripción |
|-----------|------|---------|-------------|
| `estado` | string | "activa" | Estado de alertas a obtener |
| `severidad` | string | null | Filtrar por severidad específica |
| `limite` | int | 50 | Máximo número de alertas |
| `desde_fecha` | string | null | Fecha mínima (YYYY-MM-DD) |

#### Ejemplo Request
```
GET /get_alertas.php?estado=activa&severidad=alta&limite=20
```

#### Response Success
```json
{
    "success": true,
    "alertas": [
        {
            "id": 29,
            "tipo": "deteccion_alta",
            "mensaje": "Detección de alta cantidad de insectos",
            "fecha": "2025-01-12 10:30:00",
            "severidad": "alta",
            "estado": "activa",
            "captura_id": 123,
            "trampa_id": 1,
            "fecha_resolucion": null,
            "notas_resolucion": null,
            "fecha_captura": "2025-01-12 10:25:00",
            "minutos_desde_alerta": 45,
            "total_insectos": 25
        }
    ],
    "total_encontradas": 15,
    "total_mostradas": 15,
    "estadisticas": {
        "alta": 5,
        "media": 8,
        "baja": 2,
        "total": 15
    },
    "filtros_aplicados": {
        "estado": "activa",
        "severidad": "alta",
        "limite": 20,
        "desde_fecha": null
    }
}
```

---

### 3. `resolver_alerta.php`

**Propósito**: Cambiar estado de una alerta existente

**Método**: POST  
**Content-Type**: application/json

#### Request Body
```json
{
    "alerta_id": 29,
    "estado": "resuelta",
    "notas": "Problema solucionado mediante limpieza de trampa"
}
```

#### Response Success
```json
{
    "success": true,
    "message": "Alerta actualizada exitosamente",
    "alerta_id": 29,
    "estado_anterior": "activa",
    "estado_nuevo": "resuelta"
}
```

#### Comportamiento por Estado
- **"resuelta"/"descartada"**: Establece `fecha_resolucion = NOW()` y guarda `notas_resolucion`
- **"activa"**: Limpia `fecha_resolucion = NULL` y `notas_resolucion = NULL`

---

## Servicio Flutter (AlertService)

### Ubicación
`lib/services/alert_service.dart`

### Clases Principales

#### `Alerta`
```dart
class Alerta {
  final int? id;
  final String tipo;
  final String mensaje;
  final DateTime fecha;
  final String severidad;
  final String estado;
  final int? capturaId;
  final int? trampaId;
  final DateTime? fechaResolucion;
  final String? notasResolucion;
  final int? totalInsectos;
  final DateTime? fechaCaptura;
  final String? estadoTrampa;
  final int? minutosDesdealerta;
}
```

#### `AlertaResponse`
```dart
class AlertaResponse {
  final bool success;
  final List<Alerta> alertas;
  final int totalEncontradas;
  final Map<String, int> estadisticas;
  final String? error;
}
```

### Métodos Principales

#### `verificarAlertas()`
- Verifica condiciones de alerta en capturas recientes
- Registra automáticamente nuevas alertas
- Retorna lista de alertas activas

#### `obtenerAlertas()`
```dart
Future<AlertaResponse> obtenerAlertas({
  String estado = 'activa',
  String? severidad,
  int limite = 50,
  DateTime? desdeFecha,
})
```

#### `resolverAlerta()`
```dart
Future<bool> resolverAlerta(int alertaId, String estado, {String? notas})
```

#### `_registrarAlerta()` (privado)
- Registra nuevas alertas en base de datos
- Previene duplicados
- Maneja errores de conexión

---

## Interfaz de Usuario

### Pantalla: Historial de Alertas
**Ubicación**: `lib/views/historial_alertas_screen.dart`

#### Componentes Principales

1. **Estadísticas Compactas**
   - Contadores por severidad (Alta, Media, Baja, Total)
   - Solo alertas activas
   - Layout horizontal

2. **Filtros en Línea**
   - Estado: Dropdown (Activa, Resuelta, Descartada)
   - Severidad: Dropdown (Todas, Alta, Media, Baja)
   - Botones: Aplicar, Limpiar

3. **Lista de Alertas**
   - Cards expandibles
   - Información detallada
   - Acciones contextuales

#### Funcionalidades

- **Filtrado**: Por estado, severidad y límite
- **Resolución**: Diálogo para resolver/descartar alertas
- **Expansión**: Ver detalles completos de cada alerta
- **Actualización**: Refresh automático tras acciones

#### Estados de Alerta

| Estado | Color | Descripción |
|--------|-------|-------------|
| Activa | Rojo | Requiere atención |
| Resuelta | Verde | Problema solucionado |
| Descartada | Gris | Falsa alarma o irrelevante |

#### Severidades

| Severidad | Color | Icono |
|-----------|-------|-------|
| Alta | Rojo | `Icons.warning` |
| Media | Naranja | `Icons.info` |
| Baja | Azul | `Icons.info_outline` |

---

## Flujo de Datos

### 1. Detección Automática
```
Captura Nueva → AlertService.verificarAlertas() → 
Evaluación de Condiciones → Registro en BD → 
Notificación en Dashboard
```

### 2. Consulta de Historial
```
Usuario abre Historial → obtenerAlertas() → 
get_alertas.php → Consulta BD → 
Response con alertas y estadísticas → 
Renderizado en UI
```

### 3. Resolución de Alerta
```
Usuario selecciona "Resolver" → Diálogo de confirmación → 
resolverAlerta() → resolver_alerta.php → 
Update en BD → Refresh de lista
```

---

## Casos de Uso

### Caso 1: Detección Alta de Insectos
1. Sistema detecta >20 insectos en una captura
2. Se crea alerta automática con severidad "alta"
3. Aparece en dashboard y historial
4. Usuario investiga y resuelve con notas

### Caso 2: Trampa Inactiva
1. Sistema detecta que trampa no ha capturado en 24h
2. Se crea alerta con severidad "media"
3. Usuario verifica trampa físicamente
4. Descarta alerta si es mantenimiento programado

### Caso 3: Revisión de Historial
1. Usuario accede a "Historial de Alertas"
2. Filtra por alertas resueltas del último mes
3. Revisa patrones y tendencias
4. Genera reportes para análisis

---

## Configuración y Despliegue

### Requisitos del Servidor
- **PHP**: 7.4 o superior
- **MySQL**: 5.7 o superior
- **Apache**: Con mod_rewrite habilitado
- **CORS**: Headers configurados correctamente

### Configuración de Base de Datos
```sql
-- Crear tabla de alertas
CREATE TABLE alertas (
    -- [estructura completa arriba]
);

-- Índices recomendados
CREATE INDEX idx_alertas_estado ON alertas(estado);
CREATE INDEX idx_alertas_fecha ON alertas(fecha);
CREATE INDEX idx_alertas_severidad ON alertas(severidad);
CREATE INDEX idx_alertas_trampa ON alertas(trampa_id);
```

### Variables de Configuración PHP
```php
// En cada endpoint
$servername = "localhost";
$username = "admin";
$password = "7008";
$database = "insectosDB";
```

### Configuración Flutter
```dart
// En alert_service.dart
static const String baseUrl = 'http://raspberrypi2.local';
```

### Headers CORS Configurados
```php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
```

---

## Navegación en la App

### Menú Lateral Actualizado
```dart
// lib/widgets/side_menu.dart
// Índice 4: "Historial de Alertas" con Icons.history
```

### Pantalla Principal
```dart
// lib/views/main_screen.dart
// Páginas reordenadas:
// 0: Dashboard, 1: Capturas, 2: Trampas, 3: Configuración
// 4: Historial Alertas, 5: Exportar, 6: Auditorías
```

---

## Mantenimiento y Monitoreo

### Logs Recomendados
- Errores de conexión a BD
- Alertas duplicadas prevenidas
- Tiempo de respuesta de endpoints
- Fallos en resolución de alertas

### Limpieza de Datos
```sql
-- Limpiar alertas muy antiguas (opcional)
DELETE FROM alertas 
WHERE estado IN ('resuelta', 'descartada') 
AND fecha_resolucion < DATE_SUB(NOW(), INTERVAL 6 MONTH);
```

### Backup Recomendado
- Backup diario de tabla `alertas`
- Retención de 30 días mínimo
- Backup antes de actualizaciones

---

## Troubleshooting

### Error 405 Method Not Allowed
- **Causa**: Peticiones OPTIONS no manejadas
- **Solución**: Verificar headers CORS y manejo de OPTIONS

### Alertas Duplicadas
- **Causa**: Fallo en validación de duplicados
- **Solución**: Revisar lógica de 5 minutos en registrar_alerta.php

### Estadísticas Incorrectas
- **Causa**: Inconsistencia entre alertas y estadísticas
- **Solución**: Verificar consulta SQL en get_alertas.php

### UI No Actualiza
- **Causa**: Estado no se refresca tras acciones
- **Solución**: Verificar llamadas a _cargarAlertas() tras resolver

---

*Documentación actualizada: Enero 2025*
*Versión del sistema: 1.0* 