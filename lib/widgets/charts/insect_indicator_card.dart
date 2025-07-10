import 'package:flutter/material.dart';
import '../../models/chart_models.dart';
import '../../theme/app_theme.dart';

/// Widget de tarjeta individual para mostrar un indicador de insecto
/// FASE 6: Con animaciones y efectos visuales para alertas críticas
class InsectIndicatorCard extends StatefulWidget {
  final InsectIndicatorData indicator;
  final bool showTrend;
  final VoidCallback? onTap;
  final String? currentPeriodLabel;
  final String? previousPeriodLabel;
  final bool isLoading;

  const InsectIndicatorCard({
    super.key,
    required this.indicator,
    this.showTrend = true,
    this.onTap,
    this.isLoading = false,
    this.currentPeriodLabel,
    this.previousPeriodLabel,
  });

  @override
  State<InsectIndicatorCard> createState() => _InsectIndicatorCardState();
}

class _InsectIndicatorCardState extends State<InsectIndicatorCard>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late AnimationController _loadingController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _loadingAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animación de pulso para alertas críticas
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Animación de escala para entrada
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    ));
    
    // Animación de carga
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _loadingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _loadingController,
      curve: Curves.easeInOut,
    ));
    
    // Iniciar animaciones
    _scaleController.forward();
    
    if (widget.isLoading) {
      _loadingController.repeat();
    }
    
    _checkCriticalAlert();
  }
  
  @override
  void didUpdateWidget(InsectIndicatorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _loadingController.repeat();
      } else {
        _loadingController.stop();
      }
    }
    
    if (widget.indicator.nivelAlerta.nivel != oldWidget.indicator.nivelAlerta.nivel) {
      _checkCriticalAlert();
    }
  }
  
  void _checkCriticalAlert() {
    if (widget.indicator.nivelAlerta.nivel == 'critical') {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  /// Construye el header de la tarjeta con el tipo de insecto
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            widget.indicator.tipoInsecto.toUpperCase(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (widget.indicator.tieneAlertaActiva) _buildAlertBadge(),
      ],
    );
  }

  /// Construye el valor principal (cantidad de hoy)
  Widget _buildMainValue() {
    if (widget.isLoading) {
      return _buildLoadingValue();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.indicator.cantidadHoy.toString(),
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: widget.indicator.colorTipo,
          ),
        ),
        Text(
          'detectados ${widget.currentPeriodLabel?.toLowerCase() ?? 'hoy'}',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
  
  /// Widget de carga animado
  Widget _buildLoadingValue() {
    return AnimatedBuilder(
      animation: _loadingAnimation,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80 * _loadingAnimation.value,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 100 * _loadingAnimation.value,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Construye el indicador de tendencia
  Widget _buildTrendIndicator() {
    if (!widget.showTrend || widget.isLoading) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.indicator.colorTendencia.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.indicator.colorTendencia.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.indicator.iconoTendencia,
            size: 16,
            color: widget.indicator.colorTendencia,
          ),
          const SizedBox(width: 4),
          Text(
            widget.indicator.porcentajeCambioFormateado,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: widget.indicator.colorTendencia,
            ),
          ),
        ],
      ),
    );
  }

  /// Construye el badge de alerta
  Widget _buildAlertBadge() {
    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: widget.indicator.nivelAlerta.color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.indicator.nivelAlerta.icon,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 2),
          Text(
            widget.indicator.nivelAlerta.nivel.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
    
    // Añadir efecto de pulso para alertas críticas
    if (widget.indicator.nivelAlerta.nivel == 'critical') {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_pulseAnimation.value * 0.1),
            child: badge,
          );
        },
      );
    }
    
    return badge;
  }

  /// Obtiene el color del borde de la tarjeta basado en el nivel de alerta
  Color _getCardBorderColor() {
    if (widget.indicator.tieneAlertaActiva) {
      return widget.indicator.nivelAlerta.color;
    }
    return AppTheme.textSecondary.withOpacity(0.3);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        Widget card = Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getCardBorderColor(),
                  width: widget.indicator.tieneAlertaActiva ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header con tipo de insecto y badge de alerta
                    _buildHeader(),
                    const SizedBox(height: 12),
                    
                    // Valor principal
                    _buildMainValue(),
                    const Spacer(),
                    
                    // Información adicional en la parte inferior
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Cantidad de ayer
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.previousPeriodLabel ?? 'Ayer'}: ${widget.indicator.cantidadAyer}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            Text(
                              'Umbral: ${widget.indicator.umbralAlerta}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        
                        // Indicador de tendencia
                        _buildTrendIndicator(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        
        // Añadir efecto de pulso para alertas críticas
        if (widget.indicator.nivelAlerta.nivel == 'critical') {
          return AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: card,
              );
            },
          );
        }
        
        return card;
      },
    );
  }
}