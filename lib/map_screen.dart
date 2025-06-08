import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _selectedLocation;
  final MapController _mapController = MapController();

  void _onMapTap(LatLng point) {
    setState(() {
      _selectedLocation = point;
    });
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Select Location")),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          center: LatLng(-13.2543, 34.3015), // Center on Malawi
          zoom: 7.0, // Adjust zoom to show only Malawi
          maxBounds: LatLngBounds(
            LatLng(-17.1299, 32.6730), // Southern boundary
            LatLng(-9.2306, 35.9221),  // Northern boundary
          ),
          onTap: (tapPosition, point) => _onMapTap(point),
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
          ),
          if (_selectedLocation != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: _selectedLocation!,
                  width: 40,
                  height: 40,
                  builder: (ctx) => Icon(Icons.location_pin, color: Colors.red, size: 40),
                ),
              ],
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.check),
        onPressed: () {
          if (_selectedLocation != null) {
            Navigator.pop(context, _selectedLocation);
          }
        },
      ),
    );
  }
}
