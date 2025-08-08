import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocationService {
  static Future<bool> requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.requestPermission();
    return permission == LocationPermission.whileInUse || 
           permission == LocationPermission.always;
  }

  static Future<Position?> getCurrentLocation() async {
    try {
      bool hasPermission = await requestLocationPermission();
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
} 