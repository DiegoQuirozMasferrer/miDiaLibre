import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_CL', null); // Inicializa formato de fechas para Chile
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Feriados Chile',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'CL'), // Español de Chile
      ],
      theme: ThemeData(
        primarySwatch: Colors.blue,
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

  @override
  void initState() {
    super.initState();
    _cargarFeriados();
  }

  void _cargarFeriados() {
    final jsonData = '''
    {
      "status":"success",
      "data":[
        {"date":"2025-01-01","title":"Año Nuevo","type":"Civil","inalienable":true,"extra":"Civil e Irrenunciable"},
        {"date":"2025-04-18","title":"Viernes Santo","type":"Religioso","inalienable":false,"extra":"Religioso"},
        {"date":"2025-04-19","title":"Sábado Santo","type":"Religioso","inalienable":false,"extra":"Religioso"},
        {"date":"2025-05-01","title":"Día Nacional del Trabajo","type":"Civil","inalienable":true,"extra":"Civil e Irrenunciable"},
        {"date":"2025-05-21","title":"Día de las Glorias Navales","type":"Civil","inalienable":false,"extra":"Civil"},
        {"date":"2025-06-20","title":"Día Nacional de los Pueblos Indígenas","type":"Civil","inalienable":false,"extra":"Civil"},
        {"date":"2025-06-29","title":"San Pedro y San Pablo","type":"Religioso","inalienable":false,"extra":"Religioso"},
        {"date":"2025-07-16","title":"Día de la Virgen del Carmen","type":"Religioso","inalienable":false,"extra":"Religioso"},
        {"date":"2025-08-15","title":"Asunción de la Virgen","type":"Religioso","inalienable":false,"extra":"Religioso"},
        {"date":"2025-09-18","title":"Independencia Nacional","type":"Civil","inalienable":true,"extra":"Civil e Irrenunciable"},
        {"date":"2025-09-19","title":"Día de las Glorias del Ejército","type":"Civil","inalienable":true,"extra":"Civil e Irrenunciable"},
        {"date":"2025-10-12","title":"Encuentro de Dos Mundos","type":"Civil","inalienable":false,"extra":"Civil"},
        {"date":"2025-10-31","title":"Día de las Iglesias Evangélicas y Protestantes","type":"Religioso","inalienable":false,"extra":"Religioso"},
        {"date":"2025-11-01","title":"Día de Todos los Santos","type":"Religioso","inalienable":false,"extra":"Religioso"},
        {"date":"2025-11-16","title":"Elecciones Presidenciales y Parlamentarias","type":"Civil","inalienable":true,"extra":"Civil e Irrenunciable"},
        {"date":"2025-12-08","title":"Inmaculada Concepción","type":"Religioso","inalienable":false,"extra":"Religioso"},
        {"date":"2025-12-25","title":"Navidad","type":"Religioso","inalienable":true,"extra":"Religioso e Irrenunciable"}
      ]
    }
    ''';

    final data = json.decode(jsonData);
    setState(() {
      feriados = data['data'];
      _calcularFeriadoMasCercano();
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Próximo Feriado en Chile'),
      ),
      body: Center(
        child: feriadoMasCercano == null
            ? const CircularProgressIndicator()
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Próximo feriado:',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            Text(
              feriadoMasCercano!['title'],
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              DateFormat('EEEE, d MMMM y', 'es_CL').format(
                  DateTime.parse(feriadoMasCercano!['date'])),
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              'Tipo: ${feriadoMasCercano!['type']}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              feriadoMasCercano!['inalienable']
                  ? 'Irrenunciable'
                  : 'Renunciable',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            Text(
              diasRestantes == 0
                  ? '¡Es hoy!'
                  : 'Faltan $diasRestantes días',
              style: TextStyle(
                fontSize: 20,
                color: diasRestantes == 0 ? Colors.green : Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}