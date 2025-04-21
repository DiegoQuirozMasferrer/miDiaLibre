import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_CL', null);
  runApp(const FeriadosApp());
}

class FeriadosApp extends StatelessWidget {
  const FeriadosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Feriados Chile',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'CL'),
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0039A6), // Azul chileno
          brightness: Brightness.light,
          primary: const Color(0xFF0039A6),
          secondary: const Color(0xFFD52B1E), // Rojo chileno
          surface: Colors.white,
          background: const Color(0xFFF8F9FA),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0039A6),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFE9ECEF),
          labelStyle: const TextStyle(color: Color(0xFF212529)),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const FeriadosScreen(),
    );
  }
}

class FeriadosScreen extends StatefulWidget {
  const FeriadosScreen({super.key});

  @override
  State<FeriadosScreen> createState() => _FeriadosScreenState();
}

class _FeriadosScreenState extends State<FeriadosScreen> {
  List<dynamic> feriados = [];
  Map<String, dynamic>? feriadoMasCercano;
  int? diasRestantes;
  bool _isLoading = true;
  bool _showAllHolidays = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _cargarFeriados();
  }

  Future<void> _cargarFeriados() async {
    try {
      final jsonString = await rootBundle.loadString('assets/holidays.json');
      final data = json.decode(jsonString);

      if (data['status'] == 'success') {
        setState(() {
          feriados = data['data'];
          _calcularFeriadoMasCercano();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Error al cargar los feriados';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al leer el archivo de feriados: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _calcularFeriadoMasCercano() {
    final now = DateTime.now();
    DateTime? fechaMasCercana;
    Map<String, dynamic>? feriadoCercano;
    int? diasMinimos;

    for (var feriado in feriados) {
      final fechaFeriado = DateTime.parse(feriado['date']);
      final diferencia = fechaFeriado.difference(now).inDays;

      if (diferencia >= 0) {
        if (diasMinimos == null || diferencia < diasMinimos) {
          diasMinimos = diferencia;
          fechaMasCercana = fechaFeriado;
          feriadoCercano = feriado;
        }
      }
    }

    setState(() {
      feriadoMasCercano = feriadoCercano;
      diasRestantes = diasMinimos;
    });
  }

  void _toggleShowAllHolidays() {
    setState(() {
      _showAllHolidays = !_showAllHolidays;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text('Feriados en Chile'),
        actions: [
          IconButton(
            icon: Icon(_showAllHolidays ? Icons.calendar_month : Icons.calendar_today),
            onPressed: _toggleShowAllHolidays,
            tooltip: _showAllHolidays ? 'Mostrar próximo feriado' : 'Mostrar todos los feriados',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage))
          : _showAllHolidays
          ? _buildAllHolidaysList()
          : _buildNextHolidayCard(),
      floatingActionButton: !_showAllHolidays && _errorMessage.isEmpty
          ? FloatingActionButton(
        onPressed: () => setState(() {
          _calcularFeriadoMasCercano();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Información actualizada'),
              backgroundColor: colorScheme.secondary,
              duration: const Duration(seconds: 1),
            ),
          );
        }),
        backgroundColor: colorScheme.secondary,
        child: const Icon(Icons.refresh, color: Colors.white),
        tooltip: 'Actualizar',
      )
          : null,
    );
  }

  Widget _buildNextHolidayCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isToday = diasRestantes == 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'PRÓXIMO FERIADO',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    feriadoMasCercano!['title'],
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_month,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('EEEE, d MMMM y', 'es_CL').format(
                              DateTime.parse(feriadoMasCercano!['date'])),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      Chip(
                        label: Text(feriadoMasCercano!['type']),
                        avatar: Icon(
                          feriadoMasCercano!['type'] == 'Religioso'
                              ? Icons.church
                              : Icons.flag,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                      ),
                      Chip(
                        label: Text(
                            feriadoMasCercano!['inalienable']
                                ? 'Irrenunciable'
                                : 'Renunciable'),
                        avatar: Icon(
                          feriadoMasCercano!['inalienable']
                              ? Icons.lock
                              : Icons.lock_open,
                          size: 18,
                          color: feriadoMasCercano!['inalienable']
                              ? Colors.orange[800]
                              : Colors.green[800],
                        ),
                        backgroundColor: feriadoMasCercano!['inalienable']
                            ? Colors.orange[50]
                            : Colors.green[50],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            decoration: BoxDecoration(
              color: isToday
                  ? const Color(0xFFD52B1E).withOpacity(0.1) // Rojo chileno claro
                  : colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: isToday
                    ? const Color(0xFFD52B1E) // Rojo chileno
                    : colorScheme.primary,
                width: 1.5,
              ),
            ),
            child: Text(
              isToday
                  ? '¡ES HOY! ¡DISFRUTA TU FERIADO!'
                  : 'FALTAN $diasRestantes DÍAS',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isToday
                    ? const Color(0xFFD52B1E) // Rojo chileno
                    : colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _toggleShowAllHolidays,
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.primary,
              side: BorderSide(color: colorScheme.primary),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Icons.list),
            label: const Text('Ver todos los feriados'),
          ),
        ],
      ),
    );
  }

  Widget _buildAllHolidaysList() {
    final now = DateTime.now();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'FERIADOS CHILE 2025',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: feriados.length,
            itemBuilder: (context, index) {
              final feriado = feriados[index];
              final fechaFeriado = DateTime.parse(feriado['date']);
              final diferencia = fechaFeriado.difference(now).inDays;
              final isPast = diferencia < 0;
              final isToday = diferencia == 0;

              return Card(
                color: isToday
                    ? colorScheme.primary.withOpacity(0.05)
                    : isPast
                    ? Colors.grey[50]
                    : Colors.white,
                child: ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isToday
                          ? colorScheme.primary.withOpacity(0.2)
                          : isPast
                          ? Colors.grey[200]
                          : colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        DateFormat('d', 'es_CL').format(fechaFeriado),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isToday
                              ? colorScheme.primary
                              : isPast
                              ? Colors.grey
                              : colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    feriado['title'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isToday
                          ? colorScheme.primary
                          : isPast
                          ? Colors.grey
                          : Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    DateFormat('EEEE, d MMMM', 'es_CL').format(fechaFeriado),
                    style: TextStyle(
                      color: isPast ? Colors.grey[600] : Colors.grey[700],
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!isPast)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isToday
                                ? colorScheme.secondary.withOpacity(0.2)
                                : colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isToday ? 'HOY' : 'En $diferencia días',
                            style: TextStyle(
                              color: isToday
                                  ? colorScheme.secondary
                                  : colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),
                      Icon(
                        feriado['type'] == 'Religioso'
                            ? Icons.church
                            : Icons.flag,
                        size: 16,
                        color: isToday
                            ? colorScheme.secondary
                            : isPast
                            ? Colors.grey
                            : colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}