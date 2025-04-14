import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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

  BusStation({
    required this.id,
    required this.name,
    required this.position,
    required this.status,
  });
}

class BusStationMap extends StatefulWidget {
  @override
  _BusStationMapState createState() => _BusStationMapState();
}

class _BusStationMapState extends State<BusStationMap> {
  final MapController _mapController = MapController();

  // Mock data for bus stations
  List<BusStation> busStations = [
    BusStation(
      id: '1',
      name: 'Bus Stop - Building 68',
      position: LatLng(26.3098367488067, 50.14397403444441),
      status: 1, // Active
    ),
    BusStation(
      id: '2',
      name: 'Bus Stop - Building 59',
      position: LatLng(26.308351035468515, 50.1456451982045),
      status: 0, // Inactive
    ),
    BusStation(
      id: '3',
      name: 'Bus Stop - Building 76',
      position: LatLng(26.30621698062467, 50.147710435437155),
      status: 1, // Active
    ),
  ];

  @override
  void initState() {
    super.initState();
    // In a real app, you would fetch data here
    // fetchBusStations();
  }

  // This simulates fetching data from a database
  Future<void> fetchBusStations() async {
    // In a real app, this would be an API call or database query
    // After fetching, call setState to rebuild with new data
    setState(() {});
  }

  // Function to update a station's status
  void updateStationStatus(String stationId, int newStatus) {
    setState(() {
      for (var i = 0; i < busStations.length; i++) {
        if (busStations[i].id == stationId) {
          busStations[i].status = newStatus;
          break;
        }
      }
    });
  }

  // Custom marker widget based on status
  Widget _buildMarker(BusStation station) {
    return GestureDetector(
      onTap: () {
        // Show some information about the station
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(station.name),
            content:
                Text('Status: ${station.status == 1 ? "Active" : "Inactive"}'),
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
            station.id,
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
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              // For demo, toggle the status of station 2
              updateStationStatus('2', busStations[1].status == 1 ? 0 : 1);
            },
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          center: LatLng(26.30850316046787,
              50.142878441584955), // Center of your map == KFUPM Tower
          zoom: 13.0,
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
