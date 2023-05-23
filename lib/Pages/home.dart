import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nox_tracker/auth_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:firebase_core/firebase_core.dart';
import '../Components/firebase_options.dart';
import '../main.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late GoogleMapController mapController;

  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(31.7917, 7.0926),
    zoom: 11.0,
  );

  bool _locationPermissionGranted = false;

  Set<Marker> _markers = {};

  List<LatLng> _polylineCoordinates = [];

  PolylinePoints _polylinePoints = PolylinePoints();

  late StreamSubscription<Position> _positionStream;

  LatLng? _destination;

  @override
  void initState() {
    super.initState();
    requestLocationPermission();
  }

  void requestLocationPermission() async {
    final PermissionStatus permissionStatus = await Permission.location.request();
    if (permissionStatus.isGranted) {
      setState(() {
        _locationPermissionGranted = true;
      });
      getCurrentLocation();
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    getCurrentLocation();
  }

  Future<void> getCurrentLocation() async {
    if (_locationPermissionGranted) {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() {
          _initialCameraPosition = CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 11.0,
          );
          _markers = {
            Marker(
              markerId: const MarkerId("user_location"),
              position: LatLng(position.latitude, position.longitude),
            ),
          };
        });
      } catch (e) {
        print(e);
      }
    }
  }

  void updateMarkerPosition(LatLng position) {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId("user_location"),
          position: position,
        ),
      };
    });
  }

  void calculateRoute() async {
    if (_locationPermissionGranted && _destination != null) {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        PolylineResult result = await _polylinePoints.getRouteBetweenCoordinates(
          "AIzaSyD9DZPa_jBp3S-gSLoNjDor5xOlvrAAKT0", // Replace with your Google Maps API Key
          PointLatLng(position.latitude, position.longitude),
          PointLatLng(_destination!.latitude, _destination!.longitude),
          travelMode: TravelMode.driving,
        );

        if (result.status == 'OK') {
          _polylineCoordinates.clear();

          result.points.forEach((PointLatLng point) {
            _polylineCoordinates.add(LatLng(point.latitude, point.longitude));
          });

          mapController.animateCamera(
            CameraUpdate.newLatLngBounds(
              LatLngBounds(
                southwest: _polylineCoordinates.first,
                northeast: _polylineCoordinates.last,
              ),
              100.0,
            ),
          );

          // Add marker for destination
          setState(() {
            _markers.add(
              Marker(
                markerId: const MarkerId("destination"),
                position: _destination!,
              ),
            );
          });
        }
      } catch (e) {
        print(e);
      }
    }
  }

  void startLiveTracking() {
    _positionStream = Geolocator.getPositionStream().listen((Position position) {
      updateMarkerPosition(LatLng(position.latitude, position.longitude));
      // Here you can track the user's live location and perform any necessary actions.
    });
  }

  void stopLiveTracking() {
    _positionStream.cancel();
  }

  //sign out method
  void signOut(){
    if(FirebaseAuth.instance.currentUser != null) {
      FirebaseAuth.instance.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue, // Set the primary color to blue
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Nox tracker'),
              FloatingActionButton.extended(
                onPressed: startLiveTracking,
                label: const Text('Start Tracking'),
                icon: const Icon(Icons.play_arrow),
                elevation: 0, // Remove the elevation
                backgroundColor: Colors.transparent, // Set the background color to transparent
              ),
              SizedBox(width: 8.0),
              IconButton(onPressed: signOut, icon: Icon(Icons.logout),

              ),
            ],
          ),
          elevation: 2,
          automaticallyImplyLeading: false, // Remove the back button from the app bar
        ),
        body: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: _initialCameraPosition,
                    markers: _markers,
                    polylines: {
                      Polyline(
                        polylineId: const PolylineId("route"),
                        color: Colors.blue,
                        width: 3,
                        points: _polylineCoordinates,
                      ),
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    onTap: (LatLng position) {
                      setState(() {
                        _destination = position;
                        _polylineCoordinates.clear();
                        calculateRoute();
                        // Add green marker to the tapped position
                        _markers.add(
                          Marker(
                            markerId: const MarkerId("tapped_location"),
                            position: position,
                            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                          ),
                        );
                      });
                    },
                  ),
                ],
              ),
            ),
            if (_destination != null && _polylineCoordinates.isNotEmpty)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Distance:'),
                    Text(
                      '${_calculateDistance()} km',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _calculateDistance() {
    double totalDistance = 0.0;
    for (int i = 0; i < _polylineCoordinates.length - 1; i++) {
      totalDistance += _coordinateDistance(
        _polylineCoordinates[i].latitude,
        _polylineCoordinates[i].longitude,
        _polylineCoordinates[i + 1].latitude,
        _polylineCoordinates[i + 1].longitude,
      );
    }
    return totalDistance.toStringAsFixed(2);
  }

  double _coordinateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final c = cos(lat1 * p) * cos(lat2 * p) * cos((lon2 - lon1) * p);
    final d = sin(lat1 * p) * sin(lat2 * p) + c;
    final distance = 6371 * acos(d); // 2 * R; R = 6371 km
    return distance;
  }

  @override
  void dispose() {
    _positionStream.cancel();
    super.dispose();
  }
}

