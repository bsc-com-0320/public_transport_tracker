import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart'; // Required for parsing date/time strings

// Enum to define different sorting criteria for rides.
enum RideSortCriteria {
  shortestDistanceFromPickup, // Sort by shortest distance from user's pickup point
  lowestCost,                 // Sort by the lowest total cost of the ride
  earliestDeparture,          // Sort by the earliest departure time
}

// A class to encapsulate the search and filter options for rides.
class RideFilterOptions {
  final double pickupRadiusKm;  // Radius in kilometers for filtering rides near the user's pickup point.
  final double dropoffRadiusKm; // Radius in kilometers for filtering rides near the user's dropoff point.
  final RideSortCriteria sortCriteria; // The criteria to use for sorting the filtered rides.

  // Constructor for RideFilterOptions with default values.
  const RideFilterOptions({
    this.pickupRadiusKm = 1.0,  // Default pickup radius is 1 km.
    this.dropoffRadiusKm = 1.0, // Default dropoff radius is 1 km.
    this.sortCriteria = RideSortCriteria.shortestDistanceFromPickup, // Default sort by shortest distance.
  });

  // Factory constructor to create options from a map (e.g., for dynamic settings).
  factory RideFilterOptions.fromMap(Map<String, dynamic> map) {
    return RideFilterOptions(
      pickupRadiusKm: (map['pickupRadiusKm'] as num?)?.toDouble() ?? 1.0,
      dropoffRadiusKm: (map['dropoffRadiusKm'] as num?)?.toDouble() ?? 1.0,
      sortCriteria: _parseSortCriteria(map['sortCriteria']),
    );
  }

  // Helper method to parse the string representation of sort criteria to its enum value.
  static RideSortCriteria _parseSortCriteria(dynamic criteria) {
    if (criteria is String) {
      switch (criteria) {
        case 'lowestCost':
          return RideSortCriteria.lowestCost;
        case 'earliestDeparture':
          return RideSortCriteria.earliestDeparture;
        case 'shortestDistanceFromPickup':
          return RideSortCriteria.shortestDistanceFromPickup;
      }
    }
    return RideSortCriteria.shortestDistanceFromPickup; // Default if not found or invalid
  }
}

// A service class responsible for searching and filtering rides.
class RideSearchService {
  // Calculates the distance between two LatLng points using the Haversine formula.
  // Returns the distance in kilometers.
  double calculateDistance(LatLng latLng1, LatLng latLng2) {
    const double earthRadiusKm = 6371.0; // Radius of Earth in kilometers

    final double lat1Rad = _degreesToRadians(latLng1.latitude);
    final double lon1Rad = _degreesToRadians(latLng1.longitude);
    final double lat2Rad = _degreesToRadians(latLng2.latitude);
    final double lon2Rad = _degreesToRadians(latLng2.longitude);

    final double dLat = lat2Rad - lat1Rad;
    final double dLon = lon2Rad - lon1Rad;

    final double a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) * math.pow(math.sin(dLon / 2), 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  // Helper function to convert degrees to radians.
  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  // Searches and filters a list of available rides based on provided criteria.
  //
  // [allRides]: The complete list of rides to search through.
  // [userPickup]: The user's desired pickup location.
  // [userDropoff]: The user's desired dropoff location.
  // [options]: An instance of RideFilterOptions containing filtering and sorting preferences.
  // [bookedRideIds]: A set of ride IDs that are already booked by the user.
  //
  // Returns a filtered and sorted list of rides.
  List<Map<String, dynamic>> searchRides({
    required List<Map<String, dynamic>> allRides,
    required LatLng userPickup,
    required LatLng userDropoff,
    required RideFilterOptions options,
    required Set<String> bookedRideIds, // Pass booked ride IDs for filtering
  }) {
    List<Map<String, dynamic>> filteredRides = [];

    for (var ride in allRides) {
      final String rideId = ride['id']?.toString() ?? '';

      // Check if the ride is already booked by the user
      if (bookedRideIds.contains(rideId)) {
        continue; // Skip if the ride is already booked
      }

      // Check if the ride is not full
      final int totalCapacity = ride['capacity'] is int ? ride['capacity'] : 0;
      final int remainingCapacity = ride['remaining_capacity'] is int
          ? ride['remaining_capacity']
          : totalCapacity;
      if (remainingCapacity <= 0) {
        continue; // Skip if the ride is full
      }

      // Extract ride's pickup and dropoff coordinates
      final LatLng? ridePickupLatLng = _parseLatLng(ride['pickup_lat'], ride['pickup_lng']);
      final LatLng? rideDropoffLatLng = _parseLatLng(ride['dropoff_lat'], ride['dropoff_lng']);

      if (ridePickupLatLng == null || rideDropoffLatLng == null) {
        continue; // Skip if ride coordinates are invalid
      }

      // Calculate distance from user's pickup to ride's pickup
      final double distanceToPickup = calculateDistance(userPickup, ridePickupLatLng);
      // Calculate distance from user's dropoff to ride's dropoff
      final double distanceToDropoff = calculateDistance(userDropoff, rideDropoffLatLng);

      // Apply radius filters
      if (distanceToPickup <= options.pickupRadiusKm &&
          distanceToDropoff <= options.dropoffRadiusKm) {
        // Add calculated distances to the ride map for sorting purposes
        ride['calculated_distance_to_pickup'] = distanceToPickup;
        ride['calculated_distance_to_dropoff'] = distanceToDropoff;
        filteredRides.add(ride);
      }
    }

    // Sort the filtered rides based on the chosen criteria
    filteredRides.sort((a, b) {
      switch (options.sortCriteria) {
        case RideSortCriteria.shortestDistanceFromPickup:
          // Sort by the calculated distance to the user's pickup point
          final double distA = a['calculated_distance_to_pickup'] ?? double.infinity;
          final double distB = b['calculated_distance_to_pickup'] ?? double.infinity;
          return distA.compareTo(distB);
        case RideSortCriteria.lowestCost:
          // Sort by the total cost of the ride
          final double costA = (a['total_cost'] as num?)?.toDouble() ?? double.infinity;
          final double costB = (b['total_cost'] as num?)?.toDouble() ?? double.infinity;
          return costA.compareTo(costB);
        case RideSortCriteria.earliestDeparture:
          // Sort by the departure time (using 'departure_time' column)
          final DateTime timeA = _parseDepartureTime(a['departure_time']); // Changed back to departure_time
          final DateTime timeB = _parseDepartureTime(b['departure_time']); // Changed back to departure_time
          return timeA.compareTo(timeB);
      }
    });

    return filteredRides;
  }

  // Helper to parse latitude and longitude from dynamic values to LatLng.
  LatLng? _parseLatLng(dynamic lat, dynamic lon) {
    if (lat is num && lon is num) {
      return LatLng(lat.toDouble(), lon.toDouble());
    }
    return null;
  }

  // Helper to parse departure time string to DateTime (now more robust for character varying).
  DateTime _parseDepartureTime(String? timeString) {
    if (timeString == null) return DateTime.now();

    // Try parsing as ISO 8601 first (common for database timestamps)
    DateTime? parsedTime = DateTime.tryParse(timeString);
    if (parsedTime != null) return parsedTime;

    // List of common date/time formats to try for 'character varying'
    final List<String> formatsToTry = [
      "yyyy-MM-dd HH:mm:ss.SSSSSSZ", // ISO with microseconds and Z for UTC
      "yyyy-MM-dd HH:mm:ss",       // Standard date and time
      "yyyy-MM-dd HH:mm",          // Date and time without seconds
      "MM/dd/yyyy HH:mm:ss",       // US format with time
      "dd-MM-yyyy HH:mm:ss",       // European format with time
      "MM/dd/yyyy h:mm a",         // US format with 12-hour time and AM/PM
      "dd-MM-yyyy h:mm a",         // European format with 12-hour time and AM/PM
      "HH:mm:ss",                  // Time only (assume today's date)
      "HH:mm",                     // Time only (assume today's date)
      "h:mm a",                    // 12-hour time only (assume today's date)
      "yyyy-MM-dd",                // Date only (assume start of day)
    ];

    for (final format in formatsToTry) {
      try {
        // For time-only formats, combine with today's date
        if (format == "HH:mm:ss" || format == "HH:mm" || format == "h:mm a") {
          final now = DateTime.now();
          final parsedDate = DateFormat(format).parse(timeString);
          return DateTime(now.year, now.month, now.day, parsedDate.hour, parsedDate.minute, parsedDate.second);
        }
        return DateFormat(format).parse(timeString);
      } catch (_) {
        // Continue to the next format if parsing fails
      }
    }

    // If all attempts fail, return current time as a fallback
    return DateTime.now();
  }
}
