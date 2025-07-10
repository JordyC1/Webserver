import 'package:flutter/material.dart';
import '../services/indicator_config_service.dart';
import '../theme/app_theme.dart';
import '../models/chart_models.dart';

class IndicatorSettingsScreen extends StatefulWidget {
  const IndicatorSettingsScreen({super.key});

  @override
  State<IndicatorSettingsScreen> createState() => _IndicatorSettingsScreenState();
}

class _IndicatorSettingsScreenState extends State<IndicatorSettingsScreen> {
  Map<String, int> thresholds = {};
  List<String> insectTypes = [];
  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;
  String? successMessage;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  /// Carga la configuración actual de umbrales
  Future<void> _loadCurrentSettings() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final loadedThresholds = await IndicatorConfigService.loadThresholds();
      final loadedTypes = await IndicatorConfigService.getConfiguredInsectTypes();

      setState(() {
        thresholds = Map.from(loadedThresholds);
        insectTypes = List.from(loadedTypes);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error al cargar configuración: $e';
        isLoading = false;
      });
    }
  }

  /// Guarda la configuración de umbrales
  Future<void> _saveSettings() async {
    try {
      setState(() {
        isSaving = true;
        errorMessage = null;
        successMessage = null;
      });

      final success = await IndicatorConfigService.saveThresholds(thresholds);
      
      setState(() {
        isSaving = false;
        if (success) {
          successMessage = 'Configuración guardada exitosamente';
        } else {
          errorMessage = 'Error al guardar la configuración';
        }
      });

      // Limpiar mensaje después de 3 segundos
      if (success) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              successMessage = null;
            });
          }
        });
      }
    } catch (e) {
      setState(() {
        isSaving = false;
        errorMessage = 'Error al guardar configuración: $e';
      });
    }
  }

  /// Construye un slider para configurar el umbral de un tipo de insecto
  Widget _buildThresholdSlider(String insectType, int currentValue) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  insectType.toUpperCase(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$currentValue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppTheme.primaryBlue,
                inactiveTrackColor: AppTheme.primaryBlue.withOpacity(0.3),
                thumbColor: AppTheme.primaryBlue,
                overlayColor: AppTheme.primaryBlue.withOpacity(0.2),
                valueIndicatorColor: AppTheme.primaryBlue,
              ),
              child: Slider(
                value: currentValue.toDouble(),
                min: 1,
                max: 200,
                divisions: 199,
                label: currentValue.toString(),
                onChanged: (value) {
                  setState(() {
                    thresholds[insectType] = value.round();
                  });
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mínimo: 1',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  'Máximo: 200',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Construye una tarjeta de vista previa para un tipo de insecto
  Widget _buildPreviewCard(String insectType) {
    final threshold = thresholds[insectType] ?? 50;
    final alertLevel = IndicatorConfigService.calculateAlertLevel(threshold - 10, threshold);
    final warningLevel = IndicatorConfigService.calculateAlertLevel(threshold + 10, threshold);
    final criticalLevel = IndicatorConfigService.calculateAlertLevel(threshold * 2, threshold);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vista Previa - ${insectType.toUpperCase()}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildAlertPreview('Normal', alertLevel, threshold - 10),
            const SizedBox(height: 8),
            _buildAlertPreview('Advertencia', warningLevel, threshold + 10),
            const SizedBox(height: 8),
            _buildAlertPreview('Crítico', criticalLevel, threshold * 2),
          ],
        ),
      ),
    );
  }

  /// Construye una vista previa de nivel de alerta
  Widget _buildAlertPreview(String label, AlertLevel level, int count) {
    return Row(
      children: [
        Icon(
          level.icon,
          color: level.color,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: $count insectos',
          style: TextStyle(
            color: level.color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Resetea todos los umbrales a valores por defecto
  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Reset'),
        content: const Text(
          '¿Está seguro de que desea resetear todos los umbrales a los valores por defecto?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await IndicatorConfigService.resetToDefaults();
      if (success) {
        await _loadCurrentSettings();
        setState(() {
          successMessage = 'Umbrales reseteados a valores por defecto';
        });
      } else {
        setState(() {
          errorMessage = 'Error al resetear umbrales';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Configuración de Umbrales',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppTheme.primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCurrentSettings,
            tooltip: 'Recargar configuración',
          ),
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: _resetToDefaults,
            tooltip: 'Resetear a valores por defecto',
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                // Mensajes de estado
                if (errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.red.withOpacity(0.1),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              errorMessage = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                if (successMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.green.withOpacity(0.1),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            successMessage!,
                            style: const TextStyle(color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Lista de configuraciones
                Expanded(
                  child: ListView.builder(
                    itemCount: insectTypes.length,
                    itemBuilder: (context, index) {
                      final insectType = insectTypes[index];
                      final threshold = thresholds[insectType] ?? 50;
                      
                      return Column(
                        children: [
                          _buildThresholdSlider(insectType, threshold),
                          _buildPreviewCard(insectType),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isSaving ? null : _saveSettings,
        backgroundColor: AppTheme.primaryBlue,
        icon: isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.save, color: Colors.white),
        label: Text(
          isSaving ? 'Guardando...' : 'Guardar Configuración',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}