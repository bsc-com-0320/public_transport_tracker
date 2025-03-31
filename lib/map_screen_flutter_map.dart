import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreenFlutterMap extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select Location')),
      body: FlutterMap(
        options: MapOptions(
          center: LatLng(-15.3875, 28.3228),
          zoom: 13.0,
          onTap: (tapPosition, point) {
            Navigator.pop(context, point);
          },
        ),
        children: [TileLayer(urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png")],
      ),
    );
  }
}
