// available_driver_rides.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A StatefulWidget to display available driver rides fetched from Supabase.
class AvailableDriverRides extends StatefulWidget {
  @override
  _AvailableDriverRidesState createState() => _AvailableDriverRidesState();
}

/// The State class for AvailableDriverRides.
class _AvailableDriverRidesState extends State<AvailableDriverRides> {
  // Supabase client instance to interact with the database.
  final _supabase = Supabase.instance.client;
  // List to hold the fetched available rides.
  List<Map<String, dynamic>> _availableRides = [];
  // Boolean flag to indicate if data is currently being loaded.
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Fetch available rides when the widget is initialized.
    _fetchAvailableRides();
  }

  /// Fetches available rides from the 'ride' table in Supabase.
  /// It filters rides by the current driver's ID and orders them by creation time.
  Future<void> _fetchAvailableRides() async {
    try {
      // Get the current authenticated user's ID.
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        // If no user is logged in, stop loading and return.
        setState(() => _isLoading = false);
        return;
      }

      // Perform the Supabase query.
      final response = await _supabase
          .from('ride')
          .select('*') // Select all columns
          .eq('driver_id', userId) // Filter by the current driver's ID
          .order('created_at', ascending: false); // Order by creation time

      // Update the state with the fetched rides and set loading to false.
      setState(() {
        // Ensure the response is cast to the correct list type.
        _availableRides = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      // If an error occurs, set loading to false and show a SnackBar.
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching rides: ${e.toString()}')),
      );
    }
  }

  /// Deletes a ride from the 'ride' table in Supabase.
  /// After deletion, it refetches the available rides to update the UI.
  Future<void> _deleteRide(String rideId) async {
    try {
      // Perform the Supabase delete operation.
      await _supabase.from('ride').delete().eq('id', rideId);
      // Refetch rides to update the list after deletion.
      _fetchAvailableRides();
      // Show a success message.
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ride deleted successfully')));
    } catch (e) {
      // Show an error message if deletion fails.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting ride: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar for the screen, providing a title.
      appBar: AppBar(
        title: Text(
          'My Available Rides',
          style: TextStyle(
            color: Color(0xFF5A3D1F),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(
          color: Color(0xFF5A3D1F),
        ), // Set icon color for back button etc.
      ),
      // Body of the Scaffold, displaying different content based on loading state and ride availability.
      body:
          _isLoading
              ? Center(
                // Show a circular progress indicator while loading.
                child: CircularProgressIndicator(color: Color(0xFF5A3D1F)),
              )
              : _availableRides.isEmpty
              ? Center(
                // Show a message if no rides are available.
                child: Text(
                  'No available rides',
                  style: TextStyle(color: Color(0xFF5A3D1F), fontSize: 18),
                ),
              )
              : ListView.builder(
                // Build a list of ride cards if rides are available.
                padding: EdgeInsets.all(8),
                itemCount: _availableRides.length,
                itemBuilder: (context, index) {
                  final ride = _availableRides[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16),
                      title: Text(
                        // Display ride number or a generic title if not available.
                        'Ride #${ride['ride_number'] ?? 'N/A'}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5A3D1F),
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 8),
                          // Display pickup and dropoff points.
                          Text(
                            '${ride['pickup_point'] ?? 'N/A'} to ${ride['dropoff_point'] ?? 'N/A'}',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          SizedBox(height: 4),
                          // Display departure time.
                          Text(
                            'Departure: ${ride['departure_time'] ?? 'N/A'}',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          SizedBox(height: 4),
                          // Display capacity and total cost.
                          Text(
                            'Capacity: ${ride['capacity'] ?? 'N/A'} | Cost: \$${ride['total_cost'] ?? '0.00'}',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () {
                          // Show a confirmation dialog before deleting.
                          showDialog(
                            context: context,
                            builder: (BuildContext dialogContext) {
                              // Renamed to dialogContext to avoid conflict
                              return AlertDialog(
                                title: Text('Confirm Deletion'),
                                content: Text(
                                  'Are you sure you want to delete this ride?',
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: Color(0xFF5A3D1F),
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.of(
                                        dialogContext,
                                      ).pop(); // Use dialogContext here
                                    },
                                  ),
                                  TextButton(
                                    child: Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    onPressed: () {
                                      _deleteRide(ride['id'].toString());
                                      Navigator.of(
                                        dialogContext,
                                      ).pop(); // Use dialogContext here
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
      // Floating action button for adding new rides.
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement navigation to a screen for adding a new ride.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Add new ride functionality coming soon!')),
          );
        },
        backgroundColor: Color(0xFF5A3D1F),
        child: Icon(Icons.add, color: Colors.white),
        tooltip: 'Add New Ride',
      ),
    );
  }
}
