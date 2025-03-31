import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'supabase_service.dart';

class GoogleMapPage extends StatefulWidget {
  final Function(LatLng, LatLng) onLocationsSelected;

  const GoogleMapPage({super.key, required this.onLocationsSelected});

  @override
  State<GoogleMapPage> createState() => _GoogleMapPageState();
}

class _GoogleMapPageState extends State<GoogleMapPage> {
  final Completer<GoogleMapController> _controller = Completer();
  final SupabaseService _supabaseService = SupabaseService();

  Set<Marker> _markers = {};
  LatLng? _pickupLocation;
  LatLng? _dropoffLocation;

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  void _setLocation(LatLng location, {required bool isPickup}) {
    setState(() {
      if (isPickup) {
        _pickupLocation = location;
        _markers.add(Marker(
          markerId: MarkerId("pickup"),
          position: location,
          infoWindow: InfoWindow(title: "Pickup Point"),
        ));
      } else {
        _dropoffLocation = location;
        _markers.add(Marker(
          markerId: MarkerId("dropoff"),
          position: location,
          infoWindow: InfoWindow(title: "Dropoff Point"),
        ));
      }
    });
  }

  Future<void> _confirmLocations() async {
    if (_pickupLocation != null && _dropoffLocation != null) {
      try {
        await _supabaseService.saveLocations(_pickupLocation!, _dropoffLocation!);
        widget.onLocationsSelected(_pickupLocation!, _dropoffLocation!);
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving locations: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Select Pickup & Drop-off")),
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: _initialCameraPosition,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        onTap: (LatLng latLng) {
          if (_pickupLocation == null) {
            _setLocation(latLng, isPickup: true);
          } else {
            _setLocation(latLng, isPickup: false);
          }
        },
        markers: _markers,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _confirmLocations,
        label: Text("Confirm Locations"),
        icon: Icon(Icons.check),
      ),
    );
  }
}
