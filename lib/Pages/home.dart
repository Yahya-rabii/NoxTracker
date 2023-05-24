import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:nox_tracker/Pages/login.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late GoogleMapController mapController;

  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(31.7917, 7.0926),
    zoom: 2.0,
  );

  bool _locationPermissionGranted = false;
  bool _isLoading = false;
  String _errorMessage = '';

  Set<Marker> _markers = {};
  final List<LatLng> _polylineCoordinates = [];
  final PolylinePoints _polylinePoints = PolylinePoints();
  LatLng? _destination;

  TravelMode _selectedTravelMode = TravelMode
      .driving; // Set the initial selected travel mode
  final List<TravelMode> _travelModes = [
    TravelMode.driving,
    TravelMode.walking,
    TravelMode.bicycling,
    TravelMode.transit,
  ];

  String _distance = '';
  String _duration = '';

  @override
  void initState() {
    super.initState();
    requestLocationPermission();
  }

  void requestLocationPermission() async {


    final permissionStatus = await Geolocator.checkPermission();

    if (permissionStatus == LocationPermission.denied) {
      final requestResult = await Geolocator.requestPermission();
      if (requestResult == LocationPermission.denied ||
          requestResult == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'Location permission denied.';
        });
      } else {
        setState(() {
          _locationPermissionGranted = true;
        });
        getCurrentLocation();
      }
    } else if (permissionStatus == LocationPermission.always ||
        permissionStatus == LocationPermission.whileInUse) {
      setState(() {
        _locationPermissionGranted = true;
      });
      getCurrentLocation();
    }

  }

  void getCurrentLocation() async {
    if (_locationPermissionGranted) {
      setState(() {
        _isLoading = true;
      });

      try {
        final position = await Geolocator.getCurrentPosition(
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
        setState(() {
        });
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  void calculateRoute(TravelMode travelMode) async {
    if (_locationPermissionGranted && _destination != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        final result = await _polylinePoints.getRouteBetweenCoordinates(
          "AIzaSyD9DZPa_jBp3S-gSLoNjDor5xOlvrAAKT0", // Replace with your own API key
          PointLatLng(position.latitude, position.longitude),
          PointLatLng(_destination!.latitude, _destination!.longitude),
          travelMode: travelMode,
        );

        if (result.status == 'OK') {
          _polylineCoordinates.clear();

          result.points.forEach((point) {
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

          setState(() {
            _markers.removeWhere((marker) =>
            marker.markerId.value == "destination");
            _markers.add(
              Marker(
                markerId: const MarkerId("destination"),
                position: _destination!,
              ),
            );

            // Calculate distance and duration
            double distance = 0;
            int duration = 0;
            for (var i = 0; i < result.points.length - 1; i++) {
              distance += _coordinateDistance(
                result.points[i].latitude,
                result.points[i].longitude,
                result.points[i + 1].latitude,
                result.points[i + 1].longitude,
              )!;
              duration += _calculateDuration(
                result.points[i].latitude,
                result.points[i].longitude,
                result.points[i + 1].latitude,
                result.points[i + 1].longitude,
                travelMode,
              );
            }

            // Use the distance and duration values as needed
            _distance = '${distance.toStringAsFixed(2)} meters';
            _duration = '$duration seconds';
          });
        }
      } catch (e) {
        setState(() {
        });
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  double? _coordinateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  int _calculateDuration(lat1, lon1, lat2, lon2, TravelMode mode) {
    // Calculate duration based on travel mode
    // Implement your own logic here to determine the duration
    // For example, you can assume a fixed speed for each travel mode
    // and calculate the time based on the distance between two points

    // Example implementation:
    double distance = _coordinateDistance(lat1, lon1, lat2, lon2)!;
    double speed;
    switch (mode) {
      case TravelMode.driving:
        speed = 30.0; // Assume driving speed of 30 km/h
        break;
      case TravelMode.walking:
        speed = 5.0; // Assume walking speed of 5 km/h
        break;
      case TravelMode.bicycling:
        speed = 15.0; // Assume bicycling speed of 15 km/h
        break;
      case TravelMode.transit:
        speed = 25.0; // Assume transit speed of 25 km/h
        break;
    }

    int duration = (distance / speed * 60.0 * 60.0).round();
    return duration;
  }

  void startLiveTracking() {
    Geolocator.getPositionStream().listen((position) {
      updateMarkerPosition(LatLng(position.latitude, position.longitude));
      // Calculate distance and duration based on the updated position
      if (_polylineCoordinates.isNotEmpty) {
        double distance = 0;
        int duration = 0;
        for (var i = 0; i < _polylineCoordinates.length - 1; i++) {
          distance += _coordinateDistance(
            _polylineCoordinates[i].latitude,
            _polylineCoordinates[i].longitude,
            _polylineCoordinates[i + 1].latitude,
            _polylineCoordinates[i + 1].longitude,
          )!;
          duration += _calculateDuration(
            _polylineCoordinates[i].latitude,
            _polylineCoordinates[i].longitude,
            _polylineCoordinates[i + 1].latitude,
            _polylineCoordinates[i + 1].longitude,
            _selectedTravelMode,
          );
        }
        setState(() {
          _distance = '${distance.toStringAsFixed(2)} meters';
          _duration = '$duration seconds';
        });
      }
    });
  }


  void updateMarkerPosition(LatLng newPosition) {
    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value == "current_location");
      _markers.add(
        Marker(
          markerId: const MarkerId("current_location"),
          position: newPosition,
        ),
      );
    });
  }

  void stopLiveTracking() {
    // Stop the position stream subscription
    Geolocator.getPositionStream().listen((position) {}).cancel();
  }


  // Sign out method
  void signOut(BuildContext context) async {
    if (FirebaseAuth.instance.currentUser != null) {
    await FirebaseAuth.instance.signOut();
    //Navigate back to the login page
    Navigator.pushAndRemoveUntil(
        context, MaterialPageRoute(builder: (context) => LoginPage()), (Route<dynamic> route) => false);
    }
  }


  @override
  void dispose() {
    stopLiveTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Nox tracker'),
          elevation: 2,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              onPressed: () => signOut(context),
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  GoogleMap(
                    onMapCreated: (controller) => mapController = controller,
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
                    onTap: (position) {
                      setState(() {
                        _destination = position;
                        calculateRoute(_selectedTravelMode);
                        _markers.removeWhere((marker) => marker.markerId.value == "tapped_location");
                        _markers.add(
                          Marker(
                            markerId: const MarkerId("tapped_location"),
                            position: position,
                            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                          ),
                        );
                      });
                    },
                  ),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator()),
                  if (_errorMessage.isNotEmpty)
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.green),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 100,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButton<TravelMode>(
                    value: _selectedTravelMode,
                    items: _travelModes.map((mode) {
                      return DropdownMenuItem<TravelMode>(
                        value: mode,
                        child: Row(
                          children: [
                            Icon(_getTravelModeIcon(mode)),
                            const SizedBox(width: 8),
                            Text(mode.toString().split('.').last),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedTravelMode = value!;
                        calculateRoute(_selectedTravelMode);
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Text('Distance: $_distance'),
                  Text('Duration: $_duration'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: ElevatedButton(
                onPressed: () => startLiveTracking(),
                child: const Text('Start Live Tracking'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }


  IconData _getTravelModeIcon(TravelMode travelMode) {
    switch (travelMode) {
      case TravelMode.driving:
        return Icons.directions_car;
      case TravelMode.walking:
        return Icons.directions_walk;
      case TravelMode.bicycling:
        return Icons.directions_bike;
      case TravelMode.transit:
        return Icons.directions_transit;
    }
  }


}