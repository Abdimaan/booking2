import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class LocationService {
  static Future<bool> requestLocationPermission(BuildContext context) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Show popup dialog when location services are disabled
      bool shouldContinue = await _showLocationServiceDialog(context);
      if (!shouldContinue) {
        return false;
      }
      // Check again after user might have enabled location services
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }
    }

    LocationPermission permission = await Geolocator.requestPermission();
    return permission == LocationPermission.whileInUse || 
           permission == LocationPermission.always;
  }

  static Future<Position?> getCurrentLocation(BuildContext context) async {
    try {
      bool hasPermission = await requestLocationPermission(context);
      if (!hasPermission) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  static Future<bool> saveUserLocation(String userId, double latitude, double longitude) async {
    try {
      // Check if location already exists for this user
      final existingLocation = await Supabase.instance.client
          .from('user_locations')
          .select('user_id')
          .eq('user_id', userId)
          .maybeSingle();

      if (existingLocation != null) {
        // Update existing location
        await Supabase.instance.client
            .from('user_locations')
            .update({
              'latitude': latitude,
              'longitude': longitude,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId);
      } else {
        // Insert new location
        await Supabase.instance.client
            .from('user_locations')
            .insert({
              'user_id': userId,
              'latitude': latitude,
              'longitude': longitude,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
      }
      return true;
    } catch (e) {
      print('Error saving location: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getUserLocation(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('user_locations')
          .select('latitude, longitude, updated_at')
          .eq('user_id', userId)
          .maybeSingle();
      
      return response;
    } catch (e) {
      print('Error getting user location: $e');
      return null;
    }
  }

  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  static Future<bool> _showLocationServiceDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Service Disabled'),
          content: const Text(
            'Please enable your location service to continue.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () async {
                Navigator.of(context).pop(true);
                await Geolocator.openLocationSettings();
              },
            ),
          ],
        );
      },
    ) ?? false;
  }
} 