import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/charts/insect_indicators_grid.dart';
import '../widgets/charts/insects_summary_card.dart';
import '../widgets/charts/weekly_trend_by_type_chart.dart';
import '../models/chart_models.dart';
import '../services/chart_data_service.dart';
import '../widgets/charts/plaga_alert_card.dart';


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
  List<AlertaPlaga> alertasPlaga = [];
  bool isLoadingAlertas = true;

  void _mostrarDialogoModificarUmbral() {
  String tipoSeleccionado = 'Cucaracha';
  String periodoSeleccionado = 'hoy';
  TextEditingController umbralController = TextEditingController();

  showDialog(
  context: context,
  builder: (context) {
    String tipoSeleccionado = 'Cucaracha';
    String periodoSeleccionado = 'hoy';
    TextEditingController umbralController = TextEditingController();

    return StatefulBuilder(
      builder: (context, setStateDialog) {
        return AlertDialog(
          title: const Text('Modificar Umbral por Tipo y Período'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Selector de tipo de insecto
              DropdownButton<String>(
                value: tipoSeleccionado,
                isExpanded: true,
                items: ['Cucaracha', 'Mosca', 'Hormiga', 'Polilla', 'Lasioderma']
                    .map((tipo) => DropdownMenuItem(value: tipo, child: Text(tipo)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setStateDialog(() {
                      tipoSeleccionado = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 12),

              // Selector de período
              DropdownButton<String>(
                value: periodoSeleccionado,
                isExpanded: true,
                items: ['hoy', 'semana', 'mes']
                    .map((periodo) => DropdownMenuItem(
                          value: periodo,
                          child: Text(periodo[0].toUpperCase() + periodo.substring(1)),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setStateDialog(() {
                      periodoSeleccionado = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 12),

              TextField(
                controller: umbralController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nuevo umbral',
                  hintText: 'Ej: 10',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final input = umbralController.text.trim();
                final nuevo = int.tryParse(input);

                if (nuevo == null || nuevo < 1) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ingresa un número válido mayor o igual a 1')),
                  );
                  return;
                }

                await ChartDataService.actualizarUmbral(
                  tipoSeleccionado,
                  periodoSeleccionado,
                  nuevo,
                );

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Umbral actualizado correctamente')),
                );
                _loadInsectIndicators();
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  },
);
}

  Future<void> _loadAlertasPlaga() async {
    try {
      final lista = await ChartDataService.fetchAlertasPosiblesPlagas();
      setState(() {
        alertasPlaga = lista;
        isLoadingAlertas = false;
      });
    } catch (e) {
      setState(() {
        alertasPlaga = [];
        isLoadingAlertas = false;
      });
    }
  }


  @override
  void initState() {
    super.initState();
    _loadInsectIndicators();
    _loadAlertasPlaga();
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

              // Alertas activas de plaga
            if (isLoadingAlertas)
            ...[
              const SizedBox(height: 16),
              Card(
                color: AppTheme.cardBackground,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Container(
                  height: 150,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ]
          else if (alertasPlaga.isNotEmpty)
            ...[
              const Text(
                'Alertas de Posibles Plagas',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Card(
                color: AppTheme.cardBackground,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 280),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Scrollbar(
                    thumbVisibility: true,
                    thickness: 6,
                    radius: const Radius.circular(8),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: alertasPlaga.length,
                      itemBuilder: (context, index) {
                        final alerta = alertasPlaga[index];
                        return PlagaAlertCard(
                          mensaje: alerta.mensaje,
                          severidad: alerta.severidad,
                          fecha: alerta.fecha,
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ]
          else
            ...[
              const SizedBox(height: 16),
              Card(
                color: AppTheme.cardBackground,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: const Text(
                    'No hay alertas de plaga activas por el momento.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
              // Gráfico de tendencia semanal por tipo
              _buildWeeklyTrendChart(),
              const SizedBox(height: 24),

              // Grilla de indicadores de insectos
           Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Indicadores por Tipo de Insecto',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _mostrarDialogoModificarUmbral,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Editar Umbral',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            _buildInsectIndicatorsGrid(),
            ],
          ),
        ),
      ),
    );
  }

    String _getPeriodoFiltro() {
      switch (selectedFilter) {
        case TimeFilter.today:
          return 'hoy';
        case TimeFilter.week:
          return 'semana';
        case TimeFilter.month:
          return 'mes';
      }
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

  Widget _buildWeeklyTrendChart() {
    return WeeklyTrendByTypeChart(
      days: _getFilteredDays(),
      height: 350,
      showLegend: true,
    );
  }

  int _getFilteredDays() {
    switch (selectedFilter) {
      case TimeFilter.today:
        return 1; // Mostrar últimas 24 horas
      case TimeFilter.week:
        return 7;
      case TimeFilter.month:
        return 30;
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