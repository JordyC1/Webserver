import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/alert_service.dart';
import '../theme/app_theme.dart';

class HistorialAlertasScreen extends StatefulWidget {
  @override
  _HistorialAlertasScreenState createState() => _HistorialAlertasScreenState();
}

class _HistorialAlertasScreenState extends State<HistorialAlertasScreen>
    with SingleTickerProviderStateMixin {
  List<Alerta> alertas = [];
  Map<String, int> estadisticas = {};
  bool _isLoading = true;
  String? _error;
  String lastUpdateTime = "";

  // Filtros
  String _estadoFiltro = 'activa';
  String? _severidadFiltro;
  String? _desdeFechaFiltro;
  int _limiteFiltro = 50;

  // Controladores
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _cargarAlertas();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarAlertas() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await AlertService.obtenerAlertas(
        estado: _estadoFiltro,
        severidad: _severidadFiltro,
        limite: _limiteFiltro,
        desdeFecha: _desdeFechaFiltro,
      );

      setState(() {
        if (response.success) {
          alertas = response.alertas;
          estadisticas = response.estadisticas;
          _error = null;
        } else {
          _error = response.error ?? 'Error desconocido';
          alertas = [];
          estadisticas = {};
        }
        _isLoading = false;
        lastUpdateTime = DateFormat('HH:mm:ss').format(DateTime.now());
      });
    } catch (e) {
      setState(() {
        _error = 'Error de conexión: $e';
        _isLoading = false;
        alertas = [];
        estadisticas = {};
      });
    }
  }

  Future<void> _resolverAlerta(
      Alerta alerta, String estado, String? notas) async {
    if (alerta.id == null) return;

    try {
      final success = await AlertService.resolverAlerta(
        alertaId: alerta.id!,
        estado: estado,
        notas: notas,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alerta marcada como $estado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        _cargarAlertas(); // Recargar lista
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar la alerta'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _mostrarDialogoResolver(Alerta alerta) {
    final TextEditingController notasController = TextEditingController();
    String estadoSeleccionado = 'resuelta';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text(
          'Resolver Alerta',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              alerta.tipo,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: estadoSeleccionado,
              decoration: InputDecoration(
                labelText: 'Estado',
                labelStyle: TextStyle(color: AppTheme.textSecondary),
              ),
              dropdownColor: AppTheme.cardBackground,
              style: TextStyle(color: AppTheme.textPrimary),
              items: [
                DropdownMenuItem(value: 'resuelta', child: Text('Resuelta')),
                DropdownMenuItem(
                    value: 'descartada', child: Text('Descartada')),
              ],
              onChanged: (value) => estadoSeleccionado = value!,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notasController,
              decoration: InputDecoration(
                labelText: 'Notas (opcional)',
                labelStyle: TextStyle(color: AppTheme.textSecondary),
                hintText: 'Describe cómo se resolvió la alerta...',
                hintStyle: TextStyle(color: AppTheme.textSecondary),
              ),
              style: TextStyle(color: AppTheme.textPrimary),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resolverAlerta(
                  alerta, estadoSeleccionado, notasController.text.trim());
            },
            child: Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _aplicarFiltros() {
    _cargarAlertas();
  }

  void _limpiarFiltros() {
    setState(() {
      _estadoFiltro = 'activa';
      _severidadFiltro = null;
      _desdeFechaFiltro = null;
      _limiteFiltro = 50;
      _searchController.clear();
    });
    _cargarAlertas();
  }

  Color _getSeverityColor(String severidad) {
    switch (severidad.toLowerCase()) {
      case 'alta':
        return Colors.red;
      case 'media':
        return Colors.orange;
      case 'baja':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }

  IconData _getSeverityIcon(String severidad) {
    switch (severidad.toLowerCase()) {
      case 'alta':
        return Icons.error;
      case 'media':
        return Icons.warning;
      case 'baja':
        return Icons.info;
      default:
        return Icons.help;
    }
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertaCard(Alerta alerta) {
    final fechaFormateada = alerta.fecha.isNotEmpty
        ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(alerta.fecha))
        : 'Fecha no disponible';

    return Card(
      color: AppTheme.cardBackground,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: _getSeverityColor(alerta.severidad),
          width: 2,
        ),
      ),
      child: ExpansionTile(
        leading: Icon(
          _getSeverityIcon(alerta.severidad),
          color: _getSeverityColor(alerta.severidad),
        ),
        title: Text(
          alerta.tipo,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              alerta.mensaje,
              style: TextStyle(color: AppTheme.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(alerta.severidad).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    alerta.severidad.toUpperCase(),
                    style: TextStyle(
                      color: _getSeverityColor(alerta.severidad),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (alerta.estado != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: alerta.estado == 'activa'
                          ? Colors.green.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      alerta.estado!.toUpperCase(),
                      style: TextStyle(
                        color: alerta.estado == 'activa'
                            ? Colors.green
                            : Colors.grey,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Fecha:', fechaFormateada),
                if (alerta.capturaId != null)
                  _buildDetailRow('Captura ID:', alerta.capturaId.toString()),
                if (alerta.totalInsectos != null)
                  _buildDetailRow(
                      'Total Insectos:', alerta.totalInsectos.toString()),
                if (alerta.fechaResolucion != null)
                  _buildDetailRow(
                    'Fecha Resolución:',
                    DateFormat('dd/MM/yyyy HH:mm')
                        .format(DateTime.parse(alerta.fechaResolucion!)),
                  ),
                if (alerta.notasResolucion != null &&
                    alerta.notasResolucion!.isNotEmpty)
                  _buildDetailRow('Notas:', alerta.notasResolucion!),
                if (alerta.minutosDesdealerta != null)
                  _buildDetailRow(
                    'Tiempo transcurrido:',
                    '${alerta.minutosDesdealerta} minutos',
                  ),
                const SizedBox(height: 16),
                if (alerta.estado == 'activa' && alerta.id != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _mostrarDialogoResolver(alerta),
                        icon: Icon(Icons.check, size: 16),
                        label: Text('Resolver'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text("Historial de Alertas",
            style: TextStyle(color: AppTheme.textPrimary)),
        backgroundColor: AppTheme.cardBackground,
        iconTheme: IconThemeData(color: AppTheme.textPrimary),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.primaryBlue),
            tooltip: "Actualizar",
            onPressed: _cargarAlertas,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar alertas',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: TextStyle(color: AppTheme.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _cargarAlertas,
                        child: Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Gestión de Alertas",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Última actualización: $lastUpdateTime",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        color: AppTheme.cardBackground,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Estadísticas:',
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildStatCard(
                                            'Alta',
                                            estadisticas['alta'] ?? 0,
                                            Colors.red),
                                        _buildStatCard(
                                            'Media',
                                            estadisticas['media'] ?? 0,
                                            Colors.orange),
                                        _buildStatCard(
                                            'Baja',
                                            estadisticas['baja'] ?? 0,
                                            Colors.yellow),
                                        _buildStatCard(
                                            'Total',
                                            estadisticas['total'] ?? 0,
                                            AppTheme.primaryBlue),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Text(
                                    'Filtros:',
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 2,
                                    child: DropdownButtonFormField<String>(
                                      value: _estadoFiltro,
                                      decoration: InputDecoration(
                                        labelText: 'Estado',
                                        labelStyle: TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 12),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 6),
                                        isDense: true,
                                      ),
                                      dropdownColor: AppTheme.cardBackground,
                                      style: TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: 12),
                                      items: [
                                        DropdownMenuItem(
                                            value: 'activa',
                                            child: Text('Activas',
                                                style:
                                                    TextStyle(fontSize: 12))),
                                        DropdownMenuItem(
                                            value: 'resuelta',
                                            child: Text('Resueltas',
                                                style:
                                                    TextStyle(fontSize: 12))),
                                        DropdownMenuItem(
                                            value: 'descartada',
                                            child: Text('Descartadas',
                                                style:
                                                    TextStyle(fontSize: 12))),
                                      ],
                                      onChanged: (value) {
                                        setState(() => _estadoFiltro = value!);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: DropdownButtonFormField<String?>(
                                      value: _severidadFiltro,
                                      decoration: InputDecoration(
                                        labelText: 'Severidad',
                                        labelStyle: TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 12),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 6),
                                        isDense: true,
                                      ),
                                      dropdownColor: AppTheme.cardBackground,
                                      style: TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: 12),
                                      items: [
                                        DropdownMenuItem(
                                            value: null,
                                            child: Text('Todas',
                                                style:
                                                    TextStyle(fontSize: 12))),
                                        DropdownMenuItem(
                                            value: 'alta',
                                            child: Text('Alta',
                                                style:
                                                    TextStyle(fontSize: 12))),
                                        DropdownMenuItem(
                                            value: 'media',
                                            child: Text('Media',
                                                style:
                                                    TextStyle(fontSize: 12))),
                                        DropdownMenuItem(
                                            value: 'baja',
                                            child: Text('Baja',
                                                style:
                                                    TextStyle(fontSize: 12))),
                                      ],
                                      onChanged: (value) {
                                        setState(
                                            () => _severidadFiltro = value);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: _aplicarFiltros,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text('Aplicar',
                                        style: TextStyle(fontSize: 12)),
                                  ),
                                  const SizedBox(width: 4),
                                  TextButton(
                                    onPressed: _limpiarFiltros,
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 6),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text('Limpiar',
                                        style: TextStyle(fontSize: 11)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: alertas.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 64,
                                      color: AppTheme.textSecondary,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      "No se encontraron alertas",
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Intenta ajustar los filtros",
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: alertas.length,
                                itemBuilder: (context, index) {
                                  return _buildAlertaCard(alertas[index]);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
