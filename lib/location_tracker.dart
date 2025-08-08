import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'location_service.dart';

class LocationTracker {
  StreamSubscription<Position>? _locationStreamSubscription;
  String? _currentUserId;
  bool _isTracking = false;

  void startTracking(String userId) {
    if (_isTracking) return;

    _currentUserId = userId;
    _isTracking = true;

    _locationStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10, // Updates when user moves more than 20 meters
          ),
        ).listen((Position position) async {
          await _handleLocationUpdate(position);
        });
  }

  Future<void> _handleLocationUpdate(Position position) async {
    if (_currentUserId == null) return;

    try {
      // Get current saved location
      final currentLocation = await LocationService.getUserLocation(
        _currentUserId!,
      );

      if (currentLocation != null) {
        double savedLat = currentLocation['latitude'] as double;
        double savedLng = currentLocation['longitude'] as double;

        // Calculate distance moved
        double distance = LocationService.calculateDistance(
          savedLat,
          savedLng,
          position.latitude,
          position.longitude,
        );

        // Only update if moved more than 20 meters
        if (distance >= 10) {
          await LocationService.saveUserLocation(
            _currentUserId!,
            position.latitude,
            position.longitude,
          );
          print(
            'Location updated: ${position.latitude}, ${position.longitude}',
          );
        }
      } else {
        // First time tracking, save initial location
        await LocationService.saveUserLocation(
          _currentUserId!,
          position.latitude,
          position.longitude,
        );
        print(
          'Initial location saved: ${position.latitude}, ${position.longitude}',
        );
      }
    } catch (e) {
      print('Error handling location update: $e');
    }
  }

  void stopTracking() {
    _locationStreamSubscription?.cancel();
    _locationStreamSubscription = null;
    _currentUserId = null;
    _isTracking = false;
  }

  bool get isTracking => _isTracking;
}
