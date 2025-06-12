-- Crear tabla de alertas para el sistema de detección de insectos
CREATE TABLE `alertas` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `tipo` varchar(100) NOT NULL,
  `mensaje` text NOT NULL,
  `fecha` datetime NOT NULL DEFAULT current_timestamp(),
  `severidad` enum('alta','media','baja') NOT NULL,
  `estado` enum('activa','resuelta','descartada') NOT NULL DEFAULT 'activa',
  `captura_id` int(11) DEFAULT NULL,
  `trampa_id` int(11) DEFAULT NULL,
  `fecha_resolucion` datetime DEFAULT NULL,
  `notas_resolucion` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_fecha` (`fecha`),
  KEY `idx_severidad` (`severidad`),
  KEY `idx_estado` (`estado`),
  KEY `idx_tipo` (`tipo`),
  KEY `fk_alertas_captura` (`captura_id`),
  KEY `fk_alertas_trampa` (`trampa_id`),
  CONSTRAINT `fk_alertas_captura` FOREIGN KEY (`captura_id`) REFERENCES `capturas` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_alertas_trampa` FOREIGN KEY (`trampa_id`) REFERENCES `trampas` (`trampa_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Crear índices adicionales para optimizar consultas
CREATE INDEX `idx_fecha_severidad` ON `alertas` (`fecha`, `severidad`);
CREATE INDEX `idx_estado_fecha` ON `alertas` (`estado`, `fecha`);

-- Insertar algunas alertas de ejemplo basadas en los tipos del AlertService
INSERT INTO `alertas` (`tipo`, `mensaje`, `fecha`, `severidad`, `estado`, `captura_id`) VALUES
('Alta cantidad de insectos en la trampa', 'Se detectaron 27 insectos en la última captura se recomienda reemplazar la trampa', '2025-03-29 12:23:32', 'alta', 'resuelta', 3),
('Captura sin detección', 'La última captura (ID 174) no tiene insectos detectados.', '2025-06-10 20:40:16', 'baja', 'activa', 174),
('Sin lecturas recientes', 'No se han registrado lecturas en los últimos 45 minutos', '2025-06-12 16:00:00', 'media', 'activa', NULL);

-- Crear vista para alertas activas con información relacionada
CREATE VIEW `vista_alertas_activas` AS
SELECT 
    a.id,
    a.tipo,
    a.mensaje,
    a.fecha,
    a.severidad,
    a.estado,
    a.captura_id,
    a.trampa_id,
    c.total_insectos,
    c.fecha as fecha_captura,
    t.status as estado_trampa,
    TIMESTAMPDIFF(MINUTE, a.fecha, NOW()) as minutos_desde_alerta
FROM alertas a
LEFT JOIN capturas c ON a.captura_id = c.id
LEFT JOIN trampas t ON a.trampa_id = t.trampa_id
WHERE a.estado = 'activa'
ORDER BY 
    CASE a.severidad 
        WHEN 'alta' THEN 1 
        WHEN 'media' THEN 2 
        WHEN 'baja' THEN 3 
    END,
    a.fecha DESC;

-- Crear procedimiento almacenado para insertar alertas
DELIMITER $$
CREATE PROCEDURE `InsertarAlerta`(
    IN p_tipo VARCHAR(100),
    IN p_mensaje TEXT,
    IN p_severidad ENUM('alta','media','baja'),
    IN p_captura_id INT,
    IN p_trampa_id INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Verificar si ya existe una alerta similar activa reciente (últimas 2 horas)
    IF NOT EXISTS (
        SELECT 1 FROM alertas 
        WHERE tipo = p_tipo 
        AND estado = 'activa' 
        AND fecha > DATE_SUB(NOW(), INTERVAL 2 HOUR)
        AND (captura_id = p_captura_id OR (captura_id IS NULL AND p_captura_id IS NULL))
    ) THEN
        INSERT INTO alertas (tipo, mensaje, severidad, captura_id, trampa_id)
        VALUES (p_tipo, p_mensaje, p_severidad, p_captura_id, p_trampa_id);
    END IF;
    
    COMMIT;
END$$

-- Crear procedimiento para resolver alertas
CREATE PROCEDURE `ResolverAlerta`(
    IN p_alerta_id INT,
    IN p_notas TEXT
)
BEGIN
    UPDATE alertas 
    SET estado = 'resuelta',
        fecha_resolucion = NOW(),
        notas_resolucion = p_notas
    WHERE id = p_alerta_id;
END$$

-- Crear función para obtener alertas por severidad
CREATE FUNCTION `ContarAlertasPorSeveridad`(p_severidad ENUM('alta','media','baja'))
RETURNS INT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE total INT DEFAULT 0;
    
    SELECT COUNT(*) INTO total
    FROM alertas
    WHERE severidad = p_severidad 
    AND estado = 'activa';
    
    RETURN total;
END$$

-- Crear trigger para auto-resolver alertas de "Sin lecturas recientes" cuando lleguen nuevas capturas
CREATE TRIGGER `resolver_alertas_sin_lecturas` 
AFTER INSERT ON `capturas` 
FOR EACH ROW
BEGIN
    UPDATE alertas 
    SET estado = 'resuelta',
        fecha_resolucion = NOW(),
        notas_resolucion = 'Resuelta automáticamente: Nueva captura registrada'
    WHERE tipo = 'Sin lecturas recientes' 
    AND estado = 'activa';
END$$

DELIMITER ;

-- Crear tabla de configuración de alertas para personalizar umbrales
CREATE TABLE `configuracion_alertas` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `parametro` varchar(50) NOT NULL UNIQUE,
  `valor` varchar(100) NOT NULL,
  `descripcion` text,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Insertar configuraciones por defecto
INSERT INTO `configuracion_alertas` (`parametro`, `valor`, `descripcion`) VALUES
('umbral_alta_cantidad', '25', 'Número de insectos que activa alerta de alta cantidad'),
('minutos_sin_lecturas', '45', 'Minutos sin lecturas que activa alerta'),
('minutos_trampa_inactiva', '10', 'Minutos que una trampa puede estar inactiva'),
('auto_resolver_alertas', 'true', 'Resolver automáticamente alertas cuando se cumplan condiciones');