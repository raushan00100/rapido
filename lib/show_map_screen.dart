import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class ShowMapScreen extends StatefulWidget {
  final String startAddress;
  final String endAddress;

  const ShowMapScreen({
    super.key,
    required this.startAddress,
    required this.endAddress,
  });

  @override
  State<ShowMapScreen> createState() => _ShowMapScreenState();
}

class _ShowMapScreenState extends State<ShowMapScreen> {
  static const platform = MethodChannel("com.example.rapido/rapido");
  String _batteryLevel = 'Unknown battery level.';

  Future<void> _getBatteryLevel() async {
    String batteryLevel;
    try {
      final int result = await platform.invokeMethod('getBatteryLevel');
      batteryLevel = 'Battery level: $result%.';

      // Show toast based on battery level
      if (result < 15) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please charge your phone'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking successful'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on PlatformException catch (e) {
      batteryLevel = "Failed to get battery level: '${e.message}'.";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(batteryLevel),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _batteryLevel = batteryLevel;
    });
  }

  GoogleMapController? mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polyline = {};
  LatLng? startLatLng;
  LatLng? endLatLng;
  String? _error;
  double? _distanceInKm;
  double? _fare;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    try {
      final startLocations = await locationFromAddress(widget.startAddress);
      final endLocations = await locationFromAddress(widget.endAddress);

      if (startLocations.isEmpty || endLocations.isEmpty) {
        setState(() {
          _error = "Couldn't geocode one or both addresses.";
        });
        return;
      }

      startLatLng = LatLng(
        startLocations.first.latitude,
        startLocations.first.longitude,
      );
      endLatLng = LatLng(
        endLocations.first.latitude,
        endLocations.first.longitude,
      );

      _distanceInKm =
          Geolocator.distanceBetween(
            startLatLng!.latitude,
            startLatLng!.longitude,
            endLatLng!.latitude,
            endLatLng!.longitude,
          ) /
              1000;

      _fare = _distanceInKm! * 2;

      _markers = {
        Marker(
          markerId: const MarkerId("start"),
          position: startLatLng!,
          infoWindow: const InfoWindow(title: "Start"),
        ),
        Marker(
          markerId: const MarkerId("end"),
          position: endLatLng!,
          infoWindow: const InfoWindow(title: "Drop"),
        ),
      };

      _polyline = {
        Polyline(
          polylineId: const PolylineId("route"),
          points: [startLatLng!, endLatLng!],
          color: Colors.black,
          width: 4,
        ),
      };

      if (!mounted) return;
      setState(() {});

      WidgetsBinding.instance.addPostFrameCallback((_) => _fitCamera());
    } catch (e) {
      setState(() {
        _error = "Geocoding failed: $e";
      });
    }
  }

  void _fitCamera() {
    if (mapController == null || startLatLng == null || endLatLng == null)
      return;

    if (startLatLng == endLatLng) {
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: startLatLng!, zoom: 15),
        ),
      );
      return;
    }

    final swLat = startLatLng!.latitude < endLatLng!.latitude
        ? startLatLng!.latitude
        : endLatLng!.latitude;
    final swLng = startLatLng!.longitude < endLatLng!.longitude
        ? startLatLng!.longitude
        : endLatLng!.longitude;
    final neLat = startLatLng!.latitude > endLatLng!.latitude
        ? startLatLng!.latitude
        : endLatLng!.latitude;
    final neLng = startLatLng!.longitude > endLatLng!.longitude
        ? startLatLng!.longitude
        : endLatLng!.longitude;

    final bounds = LatLngBounds(
      southwest: LatLng(swLat, swLng),
      northeast: LatLng(neLat, neLng),
    );

    mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
  }

  @override
  Widget build(BuildContext context) {
    final isReady = startLatLng != null && endLatLng != null && _error == null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Center(
          child: Text("Map View", style: TextStyle(color: Colors.white)),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _error != null
                ? Center(
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            )
                : !isReady
                ? const Center(child: CircularProgressIndicator())
                : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: startLatLng!,
                zoom: 10,
              ),
              onMapCreated: (controller) {
                mapController = controller;
                WidgetsBinding.instance.addPostFrameCallback(
                      (_) => _fitCamera(),
                );
              },
              markers: _markers,
              polylines: _polyline,
              myLocationEnabled: false,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      _distanceInKm != null
                          ? "Distance: ${_distanceInKm!.toStringAsFixed(2)} km"
                          : "Calculating distance...",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  _rideOption(
                    icon: Icons.motorcycle,
                    title: "Bike",
                    subTitle: "Quick Bike rides\n2 mins away • Drop 11:37 am",
                    price: _fare != null
                        ? "₹${_fare!.toStringAsFixed(2)}"
                        : "₹143",
                    isFastest: true,
                  ),
                  _rideOption(
                    icon: Icons.auto_fix_high,
                    title: "Auto",
                    subTitle: "2 mins • Drop 11:41 am",
                    price: _fare != null
                        ? "₹${(_fare! * 1.2).toStringAsFixed(2)}"
                        : "₹199",
                  ),
                  _rideOption(
                    icon: Icons.local_taxi,
                    title: "Cab Economy",
                    subTitle: "2 mins • Drop 11:41 am",
                    price: _fare != null
                        ? "₹${(_fare! * 1.5).toStringAsFixed(2)}"
                        : "₹343",
                  ),
                  _rideOption(
                    icon: Icons.local_taxi,
                    title: "Cab Premium",
                    subTitle: "5 mins • Drop 11:44 am",
                    price: _fare != null
                        ? "₹${(_fare! * 1.8).toStringAsFixed(2)}"
                        : "₹421",
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 44.0),
                      child: Column(
                        children: [
                          Text(
                            _batteryLevel,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _getBatteryLevel,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.yellow[700],
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                "Get Battery Level",
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rideOption({
    required IconData icon,
    required String title,
    required String subTitle,
    required String price,
    bool isFastest = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Icon(icon, size: 40, color: Colors.amber),
      title: Row(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          if (isFastest)
            Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                "FASTEST",
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(subTitle, style: const TextStyle(fontSize: 12)),
      trailing: Text(
        price,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}