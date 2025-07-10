import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/charts/insect_indicators_grid.dart';
import '../widgets/charts/insects_summary_card.dart';
import '../models/chart_models.dart';
import '../services/chart_data_service.dart';

class PanelPlagasScreen extends StatefulWidget {
  const PanelPlagasScreen({super.key});

  @override
  _PanelPlagasScreenState createState() => _PanelPlagasScreenState();
}

enum TimeFilter { today, week, month }

class _PanelPlagasScreenState extends State<PanelPlagasScreen> {
  InsectDashboardSummary? insectSummary;
  bool isLoadingIndicators = true;
  String? indicatorsError;
  TimeFilter selectedFilter = TimeFilter.today;

  @override
  void initState() {
    super.initState();
    _loadInsectIndicators();
  }

  Future<void> _loadInsectIndicators() async {
    try {
      setState(() {
        isLoadingIndicators = true;
        indicatorsError = null;
      });

      ChartDataResponse<InsectDashboardSummary> response;
      
      switch (selectedFilter) {
        case TimeFilter.today:
          response = await ChartDataService.fetchInsectIndicators(useCache: false);
          break;
        case TimeFilter.week:
          response = await ChartDataService.fetchInsectIndicators(daysForComparison: 7, useCache: false);
          break;
        case TimeFilter.month:
          response = await ChartDataService.fetchInsectIndicators(daysForComparison: 30, useCache: false);
          break;
      }
      
      if (!response.isSuccess) {
        throw Exception(response.errorMessage);
      }
      final summary = response.data!;

      setState(() {
        insectSummary = summary;
        isLoadingIndicators = false;
      });
    } catch (e) {
      setState(() {
        indicatorsError = e.toString();
        isLoadingIndicators = false;
      });
    }
  }

  void _onFilterChanged(TimeFilter filter) {
    setState(() {
      selectedFilter = filter;
    });
    _loadInsectIndicators();
  }

  String _getFilterLabel(TimeFilter filter) {
    switch (filter) {
      case TimeFilter.today:
        return 'Hoy';
      case TimeFilter.week:
        return 'Última Semana';
      case TimeFilter.month:
        return 'Último Mes';
    }
  }

  String _getCurrentPeriodLabel() {
    switch (selectedFilter) {
      case TimeFilter.today:
        return 'Hoy';
      case TimeFilter.week:
        return 'Esta Semana';
      case TimeFilter.month:
        return 'Este Mes';
    }
  }

  String _getPreviousPeriodLabel() {
    switch (selectedFilter) {
      case TimeFilter.today:
        return 'Ayer';
      case TimeFilter.week:
        return 'Semana Anterior';
      case TimeFilter.month:
        return 'Mes Anterior';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: RefreshIndicator(
        onRefresh: _loadInsectIndicators,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título de la sección
              Text(
                'Panel de Plagas',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Monitoreo y control de indicadores de insectos',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Filtros de tiempo
              _buildTimeFilters(),
              const SizedBox(height: 24),

              // Tarjeta de resumen de insectos
              _buildInsectSummaryCard(),
              const SizedBox(height: 24),

              // Grilla de indicadores de insectos
              Text(
                'Indicadores por Tipo de Insecto',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildInsectIndicatorsGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeFilters() {
    return Card(
      color: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Período de Tiempo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: TimeFilter.values.map((filter) {
                final isSelected = selectedFilter == filter;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ElevatedButton(
                      onPressed: () => _onFilterChanged(filter),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected 
                            ? AppTheme.primaryBlue 
                            : AppTheme.cardBackground,
                        foregroundColor: isSelected 
                            ? Colors.white 
                            : AppTheme.textPrimary,
                        elevation: isSelected ? 2 : 0,
                        side: BorderSide(
                          color: isSelected 
                              ? AppTheme.primaryBlue 
                              : AppTheme.textSecondary.withOpacity(0.3),
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        _getFilterLabel(filter),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsectSummaryCard() {
    if (isLoadingIndicators) {
      return Card(
        color: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppTheme.primaryBlue),
                const SizedBox(height: 16),
                Text(
                  'Cargando resumen...',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    } else if (indicatorsError != null) {
      return Card(
        color: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar datos',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  indicatorsError!,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadInsectIndicators,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                  ),
                  child: Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    } else if (insectSummary == null) {
      return Card(
        color: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, color: AppTheme.textSecondary, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Sin datos disponibles',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return InsectsSummaryCard(
        summary: insectSummary!,
        currentPeriodLabel: _getCurrentPeriodLabel(),
        previousPeriodLabel: _getPreviousPeriodLabel(),
      );
    }
  }

  Widget _buildInsectIndicatorsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determinar número de columnas según el ancho disponible
        int crossAxisCount;
        if (constraints.maxWidth > 1200) {
          crossAxisCount = 4; // Desktop
        } else if (constraints.maxWidth > 800) {
          crossAxisCount = 3; // Tablet
        } else {
          crossAxisCount = 2; // Móvil
        }

        return InsectIndicatorsGrid(
          height: 400,
          crossAxisCount: crossAxisCount,
          showTrends: true,
          currentPeriodLabel: _getCurrentPeriodLabel(),
          previousPeriodLabel: _getPreviousPeriodLabel(),
          onRefresh: _loadInsectIndicators,
          dashboardData: insectSummary,
          isLoading: isLoadingIndicators,
          errorMessage: indicatorsError,
        );
      },
    );
  }
}