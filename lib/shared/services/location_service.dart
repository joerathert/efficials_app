import 'package:flutter/foundation.dart';
import '../models/database_models.dart';
import 'repositories/location_repository.dart';
import 'repositories/user_repository.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  LocationService._internal();
  factory LocationService() => _instance;

  final LocationRepository _locationRepository = LocationRepository();
  final UserRepository _userRepository = UserRepository();

  // Get current user ID (for database operations)
  Future<int> _getCurrentUserId() async {
    final user = await _userRepository.getCurrentUser();
    return user?.id ?? 1; // Default to 1 if no user found
  }

  // Get all locations for the current user
  Future<List<Map<String, dynamic>>> getLocations() async {
    // On web, SQLite doesn't work - return empty list for now
    // User can create locations through the + Create new location option
    if (kIsWeb) {
      debugPrint('Web platform detected - SQLite not available, returning empty locations list');
      return [];
    }
    
    try {
      final userId = await _getCurrentUserId();
      final locations = await _locationRepository.getLocationsByUser(userId);
      
      // Convert to the format expected by the UI
      return locations.map((location) => {
        'id': location.id,
        'name': location.name,
        'address': _extractStreetAddress(location.address) ?? location.address,
        'city': _extractCity(location.address) ?? '',
        'state': _extractState(location.address) ?? '',
        'zip': _extractZip(location.address) ?? '',
        'notes': location.notes,
      }).toList();
    } catch (e) {
      debugPrint('Error getting locations: $e');
      return [];
    }
  }

  // Create a new location
  Future<Map<String, dynamic>?> createLocation({
    required String name,
    required String address,
    required String city,
    required String state,
    required String zip,
    String? notes,
  }) async {
    // On web, SQLite doesn't work - simulate location creation
    if (kIsWeb) {
      debugPrint('Web platform detected - simulating location creation for: $name');
      // For demo purposes, always allow creation on web
      final newId = DateTime.now().millisecondsSinceEpoch;
      return {
        'id': newId,
        'name': name,
        'address': address,
        'city': city,
        'state': state,
        'zip': zip,
        'notes': notes,
      };
    }
    
    try {
      final userId = await _getCurrentUserId();
      
      // Check if location already exists
      final exists = await _locationRepository.doesLocationExist(userId, name);
      if (exists) {
        return null; // Location already exists
      }

      // Create full address string
      final fullAddress = '$address, $city, $state $zip';
      
      final location = Location(
        name: name,
        address: fullAddress,
        notes: notes,
        userId: userId,
      );

      final locationId = await _locationRepository.createLocation(location);
      
      return {
        'id': locationId,
        'name': name,
        'address': address,
        'city': city,
        'state': state,
        'zip': zip,
        'notes': notes,
      };
    } catch (e) {
      debugPrint('Error creating location: $e');
      return null;
    }
  }

  // Update an existing location
  Future<Map<String, dynamic>?> updateLocation({
    required int id,
    required String name,
    required String address,
    required String city,
    required String state,
    required String zip,
    String? notes,
  }) async {
    try {
      final userId = await _getCurrentUserId();
      
      // Check if location name already exists (excluding current location)
      final exists = await _locationRepository.doesLocationExist(userId, name, excludeId: id);
      if (exists) {
        return null; // Location name already exists
      }

      // Create full address string
      final fullAddress = '$address, $city, $state $zip';
      
      final location = Location(
        id: id,
        name: name,
        address: fullAddress,
        notes: notes,
        userId: userId,
      );

      await _locationRepository.updateLocation(location);
      
      return {
        'id': id,
        'name': name,
        'address': address,
        'city': city,
        'state': state,
        'zip': zip,
        'notes': notes,
      };
    } catch (e) {
      debugPrint('Error updating location: $e');
      return null;
    }
  }

  // Delete a location
  Future<bool> deleteLocation(int id) async {
    try {
      await _locationRepository.deleteLocation(id);
      return true;
    } catch (e) {
      debugPrint('Error deleting location: $e');
      return false;
    }
  }

  // Get location by ID
  Future<Map<String, dynamic>?> getLocationById(int id) async {
    try {
      final location = await _locationRepository.getLocationById(id);
      if (location == null) return null;
      
      return {
        'id': location.id,
        'name': location.name,
        'address': location.address,
        'city': _extractCity(location.address),
        'state': _extractState(location.address),
        'zip': _extractZip(location.address),
        'notes': location.notes,
      };
    } catch (e) {
      debugPrint('Error getting location by ID: $e');
      return null;
    }
  }

  // Search locations by name
  Future<List<Map<String, dynamic>>> searchLocations(String searchTerm) async {
    try {
      final userId = await _getCurrentUserId();
      final locations = await _locationRepository.searchLocationsByName(userId, searchTerm);
      
      return locations.map((location) => {
        'id': location.id,
        'name': location.name,
        'address': location.address,
        'city': _extractCity(location.address),
        'state': _extractState(location.address),
        'zip': _extractZip(location.address),
        'notes': location.notes,
      }).toList();
    } catch (e) {
      debugPrint('Error searching locations: $e');
      return [];
    }
  }

  // Helper methods to extract address parts
  String? _extractCity(String? fullAddress) {
    if (fullAddress == null) return null;
    final parts = fullAddress.split(',');
    if (parts.length >= 2) {
      return parts[1].trim();
    }
    return null;
  }

  String? _extractState(String? fullAddress) {
    if (fullAddress == null) return null;
    final parts = fullAddress.split(',');
    if (parts.length >= 3) {
      final stateZip = parts[2].trim().split(' ');
      if (stateZip.isNotEmpty) {
        return stateZip[0];
      }
    }
    return null;
  }

  String? _extractZip(String? fullAddress) {
    if (fullAddress == null) return null;
    final parts = fullAddress.split(',');
    if (parts.length >= 3) {
      final stateZip = parts[2].trim().split(' ');
      if (stateZip.length >= 2) {
        return stateZip[1];
      }
    }
    return null;
  }

  // Helper method to extract street address only
  String? _extractStreetAddress(String? fullAddress) {
    if (fullAddress == null) return null;
    final parts = fullAddress.split(',');
    if (parts.isNotEmpty) {
      return parts[0].trim();
    }
    return fullAddress;
  }
}