import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  MapboxMap? mapboxMapController;
  StreamSubscription? userPositionStream;

  @override
  void initState() {
    super.initState();
    _checkLocation();
  }

  @override
  void dispose() {
    userPositionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MapWidget(onMapCreated: _onMapCreated, styleUri: MapboxStyles.DARK),
    );
  }

  // setup my location
  void _onMapCreated(MapboxMap controller) async {
    setState(() {
      mapboxMapController = controller;
    });
    // this for display my location on map
    mapboxMapController?.location.updateSettings(
      LocationComponentSettings(
        enabled: true, // show my location
        pulsingEnabled: true,
      ),
    );
    // this code use to show marker on map with location coordinates and zoom in
    final pointAnnotationManager =
        await mapboxMapController?.annotations.createPointAnnotationManager();
    final Uint8List imageData = await _loadMarkerImage();
    PointAnnotationOptions pointAnnotationOptions = PointAnnotationOptions(

      image: imageData,
      iconSize: 0.6,
      geometry: Point(
        coordinates: Position(
          30.85759095848311,
          31.048402567684832,
        ), // this location in kafer elshek, egypt
      ),
    );
    pointAnnotationManager?.create(pointAnnotationOptions);
    print("Marker created at ${pointAnnotationOptions.geometry.coordinates}");
  }

  // setup position tracking
  Future<void> _checkLocation() async {
    bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    geo.LocationPermission permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
    }
    if (permission == geo.LocationPermission.deniedForever) {
      return Future.error("Location permission denied forever");
    }
    if (permission == geo.LocationPermission.whileInUse ||
        permission == geo.LocationPermission.always) {
      geo.Position position = await geo.Geolocator.getCurrentPosition();
      if (kDebugMode) {
        print("this is position $position");
      }
    }
    // use to get stream of location and distance filter
    geo.LocationSettings locationSettings = geo.LocationSettings(
      accuracy: geo.LocationAccuracy.high,
      distanceFilter: 100,
    );
    userPositionStream?.cancel();
    userPositionStream = geo.Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((geo.Position position) {
      if (position != null && mapboxMapController != null) {
        mapboxMapController?.setCamera(
          CameraOptions(
            zoom: 17,
            center: Point(
              coordinates: Position(position.longitude, position.latitude),
            ),
          ),
        );
      }
    });
  }

  // load marker image
  Future<Uint8List> _loadMarkerImage() async {
    var byteData = await rootBundle.load('assets/icons/marker.png');
    var pngBytes = byteData.buffer.asUint8List();
    return pngBytes;
  }
}
