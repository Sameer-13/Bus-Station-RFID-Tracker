import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bus Station Status Map',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: BusStationMap(),
    );
  }
}

class BusStation {
  final String id;
  final String name;
  final LatLng position;
  int status; // 0 = inactive (red), 1 = active (green)
  String cardId; // Card ID from the scanned data

  BusStation({
    required this.id,
    required this.name,
    required this.position,
    required this.status,
    this.cardId = '',
  });
}

class BusStationMap extends StatefulWidget {
  @override
  _BusStationMapState createState() => _BusStationMapState();
}

class _BusStationMapState extends State<BusStationMap> {
  final MapController _mapController = MapController();
  Timer? _refreshTimer;
  bool _isLoading = false;
  String _errorMessage = '';

  // Bus stations with fixed positions
  List<BusStation> busStations = [
    BusStation(
      id: 'bus_station_1',
      name: 'Bus Stop - Building 68',
      position: LatLng(26.3098367488067, 50.14397403444441),
      status: 0, // Will be updated from Firebase
    ),
    BusStation(
      id: 'bus_station_2',
      name: 'Bus Stop - Building 59',
      position: LatLng(26.308351035468515, 50.1456451982045),
      status: 0, // Will be updated from Firebase
    ),
    BusStation(
      id: 'bus_station_3',
      name: 'Bus Stop - Building 76',
      position: LatLng(26.30621698062467, 50.147710435437155),
      status: 0, // Will be updated from Firebase
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Start fetching data immediately
    fetchBusStationStatus();

    // Set up timer to refresh every second
    _refreshTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      fetchBusStationStatus();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // Fetch bus station status from Firebase
  Future<void> fetchBusStationStatus() async {
    if (_isLoading) return; // Prevent overlapping requests

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://rfid-scan-demo-default-rtdb.europe-west1.firebasedatabase.app/scans.json'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data != null) {
          // The data comes directly under /scans node
          final scans = data as Map<String, dynamic>;

          setState(() {
            for (var station in busStations) {
              if (scans.containsKey(station.id)) {
                station.status = scans[station.id]['status'] ?? 0;
                station.cardId = scans[station.id]['card_id'] ?? '';
              }
            }
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to load data: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Custom marker widget based on status
  Widget _buildMarker(BusStation station) {
    return GestureDetector(
      onTap: () {
        // Show detailed information about the station
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(station.name),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status: ${station.status == 1 ? "Active" : "Inactive"}'),
                if (station.cardId.isNotEmpty)
                  Text('Card ID: ${station.cardId}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ],
          ),
        );
      },
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: station.status == 1 ? Colors.green : Colors.red,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 3,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            station.id.split('_').last, // Show only the number
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bus Station Status'),
        actions: [
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: fetchBusStationStatus,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center:
                  LatLng(26.30850316046787, 50.142878441584955), // KFUPM Tower
              zoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              MarkerLayer(
                markers: busStations
                    .map((station) => Marker(
                          point: station.position,
                          width: 30,
                          height: 30,
                          child: _buildMarker(station),
                        ))
                    .toList(),
              ),
            ],
          ),
          if (_errorMessage.isNotEmpty)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.my_location),
        onPressed: () {
          // Center map to show all stations
          if (busStations.isNotEmpty) {
            _fitAllMarkers();
          }
        },
      ),
    );
  }

  void _fitAllMarkers() {
    if (busStations.isEmpty) return;

    double minLat = 90.0;
    double maxLat = -90.0;
    double minLng = 180.0;
    double maxLng = -180.0;

    for (var station in busStations) {
      if (station.position.latitude < minLat)
        minLat = station.position.latitude;
      if (station.position.latitude > maxLat)
        maxLat = station.position.latitude;
      if (station.position.longitude < minLng)
        minLng = station.position.longitude;
      if (station.position.longitude > maxLng)
        maxLng = station.position.longitude;
    }

    // Add some padding
    final latPadding = (maxLat - minLat) * 0.1;
    final lngPadding = (maxLng - minLng) * 0.1;

    _mapController.fitBounds(
      LatLngBounds(
        LatLng(minLat - latPadding, minLng - lngPadding),
        LatLng(maxLat + latPadding, maxLng + lngPadding),
      ),
      options: FitBoundsOptions(padding: EdgeInsets.all(50.0)),
    );
  }
}
