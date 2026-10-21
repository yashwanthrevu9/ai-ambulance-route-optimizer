import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:ui' as ui;
import 'package:geocoding/geocoding.dart';

void main() {
  runApp(const AmbulanceApp());
}

class AmbulanceApp extends StatelessWidget {
  const AmbulanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Ambulance Route Optimizer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
        ),
        useMaterial3: true,
      ),
      home: const EmergencyHomePage(),
    );
  }
}

class EmergencyHomePage extends StatefulWidget {
  const EmergencyHomePage({super.key});

  @override
  State<EmergencyHomePage> createState() => _EmergencyHomePageState();
}

class _EmergencyHomePageState extends State<EmergencyHomePage> {
  final TextEditingController ambulanceController =
      TextEditingController();

  final TextEditingController hospitalController =
      TextEditingController();

  String emergencyLevel = 'Critical';
  Future<void> getHospitals() async {
  final url = Uri.parse('http://10.0.2.2:8000/hospitals');

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final hospitals = data['hospitals'];

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text(
              'Available Hospitals',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ...hospitals.map<Widget>((hospital) {
                      return Card(
                        child: ListTile(
                          leading: Icon(
                            hospital['emergency_available']
                                ? Icons.local_hospital
                                : Icons.warning,
                            color: hospital['emergency_available']
                                ? Colors.green
                                : Colors.red,
                          ),
                          title: Text(
                            hospital['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'Location: ${hospital['location']}\n'
                            'Beds: ${hospital['available_beds']}\n'
                            'ICU: ${hospital['icu_available']}',
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CLOSE'),
              ),
            ],
          );
        },
      );
    }
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Hospital connection error: $e'),
      ),
    );
  }
}
Future<void> makeEmergencyDecision() async {
  final url = Uri.parse('http://10.0.2.2:8000/emergency-decision');

  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'ambulance_location': ambulanceController.text,
        'hospital_location': hospitalController.text,
        'emergency_level': emergencyLevel,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final route = data['recommended_route'];
      final hospital = data['recommended_hospital'];

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text(
              'AI Emergency Decision',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recommended Route',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${route['route']} - '
                  '${route['estimated_time_min']} min',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Distance: ${route['distance_km']} km',
                ),
                Text(
                  'Traffic: ${route['traffic']}',
                ),
                Text(
                  'Route Score: ${route['score']}',
                ),
                const Divider(height: 25),
                const Text(
                  'Recommended Hospital',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  hospital['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Location: ${hospital['location']}',
                ),
                Text(
                  'Beds: ${hospital['available_beds']}',
                ),
                Text(
                  'ICU: ${hospital['icu_available']}',
                ),
                Text(
                  'Distance: ${hospital['distance_km']} km',
                ),
                Text(
                  'Hospital Score: ${hospital['score']}',
                ),
              ],
            ),
            actions: [
  TextButton(
    onPressed: () => Navigator.pop(context),
    child: const Text('CLOSE'),
  ),

  ElevatedButton(
    onPressed: () {
      Navigator.pop(context);

      Navigator.push(
  context,
  MaterialPageRoute(
  builder: (context) => OpenStreetMapPage(
  ambulanceLocation: ambulanceController.text,
  hospitalLocation: hospitalController.text,
),
),
);
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.red,
      foregroundColor: Colors.white,
    ),
    child: const Text(
      'START JOURNEY',
      style: TextStyle(
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
],
          );
        },
      );
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Emergency decision failed: ${response.statusCode}',
          ),
        ),
      );
    }
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Connection error: $e'),
      ),
    );
  }
}
Future<void> selectHospital() async {
  final url = Uri.parse('http://10.0.2.2:8000/select-hospital');

  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'ambulance_location': ambulanceController.text,
        'hospital_location': hospitalController.text,
        'emergency_level': emergencyLevel,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final hospital = data['recommended_hospital'];

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text(
              'AI Recommended Hospital',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            content: hospital == null
                ? const Text('No suitable hospital available.')
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hospital['name'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Location: ${hospital['location']}'),
                      Text(
                        'Available Beds: ${hospital['available_beds']}',
                      ),
                      Text(
                        'ICU Available: ${hospital['icu_available']}',
                      ),
                      Text(
                        'Distance: ${hospital['distance_km']} km',
                      ),
                      Text(
                        'AI Score: ${hospital['score']}',
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Reason: Emergency availability, ICU capacity, '
                        'beds, distance and emergency severity.',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Hospital selection failed: ${response.statusCode}',
          ),
        ),
      );
    }
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Connection error: $e'),
      ),
    );
  }
}
 Future<void> optimizeRoute() async {
  final url = Uri.parse('http://10.0.2.2:8000/optimize-route');

  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'ambulance_location': ambulanceController.text,
        'hospital_location': hospitalController.text,
        'emergency_level': emergencyLevel,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final recommendedRoute = data['recommended_route'];
      final routes = data['available_routes'];

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text(
              'AI Route Analysis',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recommended Route',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${recommendedRoute['route']} '
                      '(${recommendedRoute['estimated_time_min']} min)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 25),
                    const Text(
                      'Available Routes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...routes.map<Widget>((route) {
                      final isRecommended =
                          route['route'] == recommendedRoute['route'];

                      return Card(
                        child: ListTile(
                          leading: Icon(
                            isRecommended
                                ? Icons.check_circle
                                : Icons.route,
                            color: isRecommended
                                ? Colors.green
                                : Colors.red,
                          ),
                          title: Text(
                            route['route'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '${route['distance_km']} km • '
                            '${route['estimated_time_min']} min\n'
                            'Traffic: ${route['traffic']}',
                          ),
                          trailing: Text(
                            '${route['score']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Server error: ${response.statusCode}',
          ),
        ),
      );
    }
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Connection error: $e'),
      ),
    );
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI Ambulance Optimizer',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            const SizedBox(height: 10),

            const Icon(
              Icons.local_hospital,
              size: 80,
              color: Colors.red,
            ),

            const SizedBox(height: 15),

            const Text(
              'Emergency Route Optimizer',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'AI-powered ambulance routing and hospital selection',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 30),

            TextField(
              controller: ambulanceController,
              decoration: InputDecoration(
                labelText: 'Ambulance Location',
                hintText: 'Example: Bhimavaram',
                prefixIcon: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 18),

            TextField(
              controller: hospitalController,
              decoration: InputDecoration(
                labelText: 'Hospital Location',
                hintText: 'Example: Vijayawada',
                prefixIcon: const Icon(
                  Icons.local_hospital,
                  color: Colors.red,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 18),

            DropdownButtonFormField<String>(
              value: emergencyLevel,
              decoration: InputDecoration(
                labelText: 'Emergency Level',
                prefixIcon: const Icon(
                  Icons.warning,
                  color: Colors.orange,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Critical',
                  child: Text('Critical'),
                ),
                DropdownMenuItem(
                  value: 'High',
                  child: Text('High'),
                ),
                DropdownMenuItem(
                  value: 'Medium',
                  child: Text('Medium'),
                ),
                DropdownMenuItem(
                  value: 'Low',
                  child: Text('Low'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  emergencyLevel = value!;
                });
              },
            ),

            const SizedBox(height: 30),

 const SizedBox(height: 30),

SizedBox(
  height: 55,
  child: ElevatedButton.icon(
   onPressed: optimizeRoute,
    icon: const Icon(Icons.route),
    label: const Text(
      'OPTIMIZE ROUTE',
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
      ),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.red,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
),

const SizedBox(height: 20),
const SizedBox(height: 15),

OutlinedButton.icon(
  onPressed: getHospitals,
  icon: const Icon(Icons.local_hospital),
  label: const Text(
    'VIEW AVAILABLE HOSPITALS',
    style: TextStyle(
      fontWeight: FontWeight.bold,
    ),
  ),
  style: OutlinedButton.styleFrom(
    foregroundColor: Colors.red,
    side: const BorderSide(
      color: Colors.red,
    ),
    padding: const EdgeInsets.symmetric(
      vertical: 15,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
),
const SizedBox(height: 15),

ElevatedButton.icon(
  onPressed: selectHospital,
  icon: const Icon(Icons.auto_awesome),
  label: const Text(
    'AI SELECT BEST HOSPITAL',
    style: TextStyle(
      fontWeight: FontWeight.bold,
    ),
  ),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.green,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(
      vertical: 15,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
),
const SizedBox(height: 15),

ElevatedButton.icon(
  onPressed: makeEmergencyDecision,
  icon: const Icon(Icons.psychology),
  label: const Text(
    'AI EMERGENCY DECISION',
    style: TextStyle(
      fontWeight: FontWeight.bold,
    ),
  ),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.deepPurple,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(
      vertical: 15,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
),
       ],
      ),
    ),
  );
}
}
class JourneyTrackingPage extends StatelessWidget {
  final String routeName;
  final String hospitalName;
  final double distance;
  final int eta;

  const JourneyTrackingPage({
    super.key,
    required this.routeName,
    required this.hospitalName,
    required this.distance,
    required this.eta,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ambulance Journey'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Emergency Journey',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selected Route',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      routeName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Distance: $distance km'),
                    Text('Estimated Time: $eta minutes'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Destination Hospital',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hospitalName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),
           TweenAnimationBuilder<double>(
  tween: Tween<double>(
    begin: 0.0,
    end: 1.0,
  ),
  duration: const Duration(seconds: 30),
  builder: (context, value, child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          minHeight: 10,
          borderRadius: BorderRadius.circular(10),
          value: value,
        ),
        const SizedBox(height: 10),
        Text(
          'Journey Progress: ${(value * 100).toInt()}%',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  },
),
const SizedBox(height: 15),

Container(
  width: double.infinity,
  padding: const EdgeInsets.all(15),
  decoration: BoxDecoration(
    color: Colors.green.shade50,
    borderRadius: BorderRadius.circular(12),
  ),
  child: const Row(
    children: [
      Icon(
        Icons.local_shipping,
        color: Colors.green,
        size: 30,
      ),
      SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'JOURNEY IN PROGRESS',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Ambulance is travelling to the selected hospital',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    ],
  ),
),

const SizedBox(height: 25),

            TweenAnimationBuilder<double>(
  tween: Tween<double>(
    begin: 0.0,
    end: 1.0,
  ),
  duration: const Duration(seconds: 30),
  builder: (context, value, child) {
    final arrived = value >= 1.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: arrived
            ? Colors.green.shade50
            : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            arrived
                ? Icons.local_hospital
                : Icons.local_shipping,
            size: 50,
            color: arrived
                ? Colors.green
                : Colors.red,
          ),

          const SizedBox(height: 10),

          Text(
            arrived
                ? 'ARRIVED AT HOSPITAL'
                : 'AMBULANCE EN ROUTE',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: arrived
                  ? Colors.green
                  : Colors.red,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            arrived
                ? 'Patient reached the selected hospital'
                : 'Journey tracking in progress',
            style: const TextStyle(
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  },
),
          ],
        ),
      ),
    );
  }
}
class SimulatedMapPage extends StatelessWidget {
  final String routeName;
  final String hospitalName;

  const SimulatedMapPage({
    super.key,
    required this.routeName,
    required this.hospitalName,
  });

  Offset getAmbulancePosition(double progress, Size size) {
  // Route A points
  final routeA = [
    Offset(30, size.height * 0.65),
    Offset(size.width * 0.30, size.height * 0.50),
    Offset(size.width * 0.50, size.height * 0.60),
    Offset(size.width * 0.70, size.height * 0.35),
    Offset(size.width - 40, size.height * 0.20),
  ];

  // At 50%, simulate a road blockage on Route A
  // and reroute the ambulance through Route C.
  if (progress < 0.5) {
    final routeProgress = progress * 2;
    final scaled = routeProgress * (routeA.length - 1);

    final index = scaled
        .floor()
        .clamp(0, routeA.length - 2);

    final localProgress = scaled - index;

    return Offset.lerp(
      routeA[index],
      routeA[index + 1],
      localProgress,
    )!;
  }

  // Route C rerouting path starts from the
  // ambulance's current position on Route A.
  final reroute = [
    Offset(size.width * 0.50, size.height * 0.60),
    Offset(size.width * 0.45, size.height * 0.25),
    Offset(size.width * 0.70, size.height * 0.30),
    Offset(size.width - 40, size.height * 0.20),
  ];

  final routeProgress = (progress - 0.5) * 2;
  final scaled = routeProgress * (reroute.length - 1);

  final index = scaled
      .floor()
      .clamp(0, reroute.length - 2);

  final localProgress = scaled - index;

  return Offset.lerp(
    reroute[index],
    reroute[index + 1],
    localProgress,
  )!;
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Route Map'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: TweenAnimationBuilder<double>(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ),
        duration: const Duration(seconds: 30),
        builder: (context, progress, child) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(
                constraints.maxWidth,
                constraints.maxHeight,
              );

              final ambulancePosition =
                  getAmbulancePosition(progress, size);

              final arrived = progress >= 1.0;

              return Stack(
                children: [
                  CustomPaint(
                    size: Size.infinite,
                    painter: RoadMapPainter(),
                  ),
                  // Road block marker
if (progress >= 0.5 && progress < 1.0)
  Positioned(
    left: size.width * 0.68,
    top: size.height * 0.30,
    child: Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.block,
        color: Colors.white,
        size: 28,
      ),
    ),
  ),

                  // Hospital
                  Positioned(
                    left: size.width - 80,
                    top: size.height * 0.15,
                    child: const Icon(
                      Icons.local_hospital,
                      size: 45,
                      color: Colors.green,
                    ),
                  ),

                  Positioned(
                    right: 20,
                    top: size.height * 0.23,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        hospitalName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Moving ambulance
                  Positioned(
                    left: ambulancePosition.dx - 22,
                    top: ambulancePosition.dy - 22,
                    child: const Icon(
                      Icons.local_shipping,
                      size: 45,
                      color: Colors.red,
                    ),
                  ),
                  // Dynamic rerouting alert
if (progress >= 0.5 && progress < 0.7)
  Positioned(
    top: size.height * 0.38,
    left: 20,
    right: 20,
    child: Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red,
          width: 2,
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.warning,
            color: Colors.red,
            size: 35,
          ),
          SizedBox(height: 6),
          Text(
            'ROAD BLOCK DETECTED',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Route A is blocked',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'AI REROUTING...',
            style: TextStyle(
              color: Colors.deepPurple,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'New Route: Route C',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  ),
                  // Route details
Positioned(
  top: 20,
  left: 20,
  right: 20,
  child: Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [
        BoxShadow(
          blurRadius: 6,
          color: Colors.black26,
        ),
      ],
    ),
    child:  Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI ROUTE ANALYSIS',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(height: 10),

        Row(
  children: [
    const Icon(
      Icons.circle,
      color: Colors.blue,
      size: 12,
    ),
    const SizedBox(width: 6),
    Expanded(
      child: Text(
        progress < 0.5
            ? 'Route A  •  8.2 km  •  18 min  •  Low Traffic  •  AI SELECTED'
            : progress < 0.7
                ? 'Route A  •  ROAD BLOCKED  •  REROUTING...'
                : 'Route C  •  NEW AI ROUTE  •  9.1 km  •  20 min  •  Medium Traffic',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  ],
),

        SizedBox(height: 7),

        Row(
          children: [
            Icon(Icons.circle, color: Colors.orange, size: 12),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'Route B  •  6.7 km  •  22 min  •  High Traffic',
              ),
            ),
          ],
        ),

        SizedBox(height: 7),

        Row(
          children: [
            Icon(Icons.circle, color: Colors.purple, size: 12),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'Route C  •  9.1 km  •  20 min  •  Medium Traffic',
              ),
            ),
          ],
        ),
      ],
    ),
  ),
),
                  

                  // Journey information
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 8,
                            color: Colors.black26,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children:[
 Text(
  'AMBULANCE JOURNEY STATUS',
  style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.red,
  ),
),
const SizedBox(height: 8),
                            

Text(
  progress >= 0.5
      ? 'Route: Route C (Rerouted)'
      : 'Route: Route A (AI Selected)',
),

Text(
  progress >= 0.5
      ? 'Traffic: Medium'
      : 'Traffic: Low',
),

Text(
  'Journey Progress: ${(progress * 100).toInt()}%',
),

const SizedBox(height: 5),

Text(
  progress >= 0.5
      ? 'Road Blockage: Route A'
      : 'Road Blockage: None',
),

Text(
  progress >= 0.5
      ? 'AI Rerouting: Completed'
      : 'AI Rerouting: Standby',
),

Text(
  arrived
      ? 'Status: Patient reached hospital'
      : progress >= 0.5
          ? 'Status: Ambulance rerouted to Route C'
          : 'Status: Ambulance en route',
),
                        
                            ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class RoadMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 28
      ..style = PaintingStyle.stroke;

    final routeAPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;

    final routeBPaint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke;

    final routeCPaint = Paint()
      ..color = Colors.purple
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke;

    // Route A
    final routeA = ui.Path();

    routeA.moveTo(30, size.height * 0.65);
    routeA.lineTo(size.width * 0.30, size.height * 0.50);
    routeA.lineTo(size.width * 0.50, size.height * 0.60);
    routeA.lineTo(size.width * 0.70, size.height * 0.35);
    routeA.lineTo(size.width - 40, size.height * 0.20);

    // Route B
    final routeB = ui.Path();

    routeB.moveTo(30, size.height * 0.65);
    routeB.lineTo(size.width * 0.35, size.height * 0.75);
    routeB.lineTo(size.width * 0.60, size.height * 0.70);
    routeB.lineTo(size.width * 0.78, size.height * 0.45);
    routeB.lineTo(size.width - 40, size.height * 0.20);

    // Route C
    final routeC = ui.Path();

    routeC.moveTo(30, size.height * 0.65);
    routeC.lineTo(size.width * 0.25, size.height * 0.35);
    routeC.lineTo(size.width * 0.45, size.height * 0.25);
    routeC.lineTo(size.width * 0.70, size.height * 0.30);
    routeC.lineTo(size.width - 40, size.height * 0.20);

    // Draw road backgrounds
    canvas.drawPath(routeA, roadPaint);
    canvas.drawPath(routeB, roadPaint);
    canvas.drawPath(routeC, roadPaint);

    // Draw Route A - Blue
    canvas.drawPath(routeA, routeAPaint);

    // Draw Route B - Orange
    canvas.drawPath(routeB, routeBPaint);

    // Draw Route C - Purple
    canvas.drawPath(routeC, routeCPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}


class OpenStreetMapPage extends StatefulWidget {
  final String ambulanceLocation;
  final String hospitalLocation;

  const OpenStreetMapPage({
    super.key,
    required this.ambulanceLocation,
    required this.hospitalLocation,
  });

  @override
  State<OpenStreetMapPage> createState() => _OpenStreetMapPageState();
}

class _OpenStreetMapPageState extends State<OpenStreetMapPage> {
  List<LatLng> routePoints = [];
  int ambulanceIndex = 0;
  bool loading = true;
  String message = 'Loading driving route...';

  // Test route near Bhimavaram.
 final LatLng start = LatLng(16.5449, 81.5212);
final LatLng destination = LatLng(16.5405, 81.5150);
  @override
  void initState() {
    super.initState();
    fetchRoute();
  }
  
Future<void> moveAmbulance() async {
  while (mounted && ambulanceIndex < routePoints.length - 1) {
    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    if (!mounted) return;

    setState(() {
      ambulanceIndex++;
    });
  }

  if (!mounted) return;

  setState(() {
    message = 'Ambulance reached the hospital!';
    loading = false;
  });

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Journey completed! Patient reached the hospital.',
      ),
      duration: Duration(seconds: 5),
    ),
  );
}


  Future<void> fetchRoute() async {
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson',
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception('Routing service unavailable');
      }

      final data = jsonDecode(response.body);
      final coordinates =
          data['routes'][0]['geometry']['coordinates'] as List;

      final points = coordinates.map((point) {
        return LatLng(
          (point[1] as num).toDouble(),
          (point[0] as num).toDouble(),
        );
      }).toList();

      if (!mounted) return;

      setState(() {
        routePoints = points;
        loading = false;
        message = 'Driving route loaded';
      });
      moveAmbulance();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        loading = false;
        message = 'Could not load route. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ambulance Driving Route'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: start,
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.ambulance_app',
              ),
              if (routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      strokeWidth: 5,
                      color: Colors.blue,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                 Marker(
  point: routePoints.isNotEmpty
      ? routePoints[ambulanceIndex]
      : start,
  width: 45,
  height: 45,
  child: const Icon(
    Icons.emergency,
    color: Colors.red,
    size: 35,
  ),
),
                  Marker(
                    point: destination,
                    width: 45,
                    height: 45,
                    child: const Icon(
                      Icons.local_hospital,
                      color: Colors.green,
                      size: 35,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 12,
            right: 12,
            top: 12,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    if (loading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    if (loading) const SizedBox(width: 12),
                    Expanded(child: Text(message)),
                    if (!loading)
                      IconButton(
                        onPressed: () {
                          setState(() {
                            loading = true;
                            message = 'Loading driving route...';
                          });
                          fetchRoute();
                        },
                        icon: const Icon(Icons.refresh),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
