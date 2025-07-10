import 'package:flutter/material.dart';
import '../../models/chart_models.dart';
import '../../services/chart_data_service.dart';
import 'insect_indicator_card.dart';
import 'chart_loading_widget.dart';
import 'chart_error_widget.dart';

/// Widget principal de indicadores de insectos en formato de grilla
class InsectIndicatorsGrid extends StatefulWidget {
  final double height;
  final int crossAxisCount;
  final bool showTrends;
  final String? currentPeriodLabel;
  final String? previousPeriodLabel;
  final VoidCallback? onRefresh;
  final InsectDashboardSummary? dashboardData;
  final bool isLoading;
  final String? errorMessage;

  const InsectIndicatorsGrid({
    super.key,
    required this.height,
    this.crossAxisCount = 2,
    this.showTrends = true,
    this.currentPeriodLabel,
    this.previousPeriodLabel,
    this.onRefresh,
    this.dashboardData,
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  State<InsectIndicatorsGrid> createState() => _InsectIndicatorsGridState();
}

class _InsectIndicatorsGridState extends State<InsectIndicatorsGrid>
    with TickerProviderStateMixin {
  // Animaciones para entrada escalonada
  late AnimationController _staggerController;
  final List<Animation<double>> _cardAnimations = [];

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _setupAnimations();
  }

  @override
  void didUpdateWidget(InsectIndicatorsGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dashboardData != widget.dashboardData) {
      _setupAnimations();
    }
  }

  void _setupAnimations() {
    if (widget.dashboardData != null && widget.dashboardData!.indicadores.isNotEmpty) {
      _setupStaggeredAnimations(widget.dashboardData!.indicadores.length);
      _staggerController.reset();
      _staggerController.forward();
    }
  }
  
  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  /// Configura las animaciones escalonadas para las tarjetas
  void _setupStaggeredAnimations(int itemCount) {
    _cardAnimations.clear();
    
    for (int i = 0; i < itemCount; i++) {
      final start = (i * 0.1).clamp(0.0, 1.0);
      final end = (start + 0.3).clamp(0.0, 1.0);
      
      _cardAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _staggerController,
            curve: Interval(start, end, curve: Curves.easeOutBack),
          ),
        ),
      );
    }
  }

  /// Refresca los datos llamando al callback del widget padre
  Future<void> _refreshData() async {
    if (widget.onRefresh != null) {
      widget.onRefresh!();
    }
  }

  /// Construye una tarjeta de indicador individual con animación
  Widget _buildIndicatorCard(InsectIndicatorData indicator, int index) {
    if (index >= _cardAnimations.length) {
      // Fallback sin animación si no hay animación configurada
      return InsectIndicatorCard(
        indicator: indicator,
        showTrend: widget.showTrends,
        isLoading: false,
        currentPeriodLabel: widget.currentPeriodLabel,
        previousPeriodLabel: widget.previousPeriodLabel,
        onTap: () {
          debugPrint('Tapped on ${indicator.tipoInsecto}');
        },
      );
    }
    
    return AnimatedBuilder(
      animation: _cardAnimations[index],
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _cardAnimations[index].value)),
          child: Opacity(
            opacity: _cardAnimations[index].value,
            child: InsectIndicatorCard(
              indicator: indicator,
              showTrend: widget.showTrends,
              isLoading: false,
              currentPeriodLabel: widget.currentPeriodLabel,
              previousPeriodLabel: widget.previousPeriodLabel,
              onTap: () {
                debugPrint('Tapped on ${indicator.tipoInsecto}');
              },
            ),
          ),
        );
      },
    );
  }

  /// Construye la grilla de carga con animaciones
  Widget _buildLoadingGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: 4, // Mostrar 4 placeholders
      itemBuilder: (context, index) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 300 + (index * 100)),
          curve: Curves.easeInOut,
          child: const ChartLoadingWidget(),
        );
      },
    );
  }

  /// Construye el estado de error
  Widget _buildErrorState() {
    return ChartErrorWidget(
      message: widget.errorMessage ?? 'Error desconocido',
      onRetry: _refreshData,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (widget.isLoading) {
      content = _buildLoadingGrid();
    } else if (widget.errorMessage != null) {
      content = _buildErrorState();
    } else if (widget.dashboardData == null || widget.dashboardData!.indicadores.isEmpty) {
      content = const Center(
        child: Text(
          'No hay datos de indicadores disponibles',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    } else {
      content = GridView.builder(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        itemCount: widget.dashboardData!.indicadores.length,
        itemBuilder: (context, index) {
          return _buildIndicatorCard(widget.dashboardData!.indicadores[index], index);
        },
      );
    }

    return SizedBox(
      height: widget.height,
      child: Column(
        children: [
          // Header con título y botón de refresh
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Indicadores de Insectos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.onRefresh != null)
                IconButton(
                  onPressed: widget.isLoading ? null : _refreshData,
                  icon: Icon(
                    Icons.refresh,
                    color: widget.isLoading ? Colors.grey : null,
                  ),
                  tooltip: 'Actualizar indicadores',
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Contenido principal
          Expanded(
            child: content,
          ),
        ],
      ),
    );
  }
}