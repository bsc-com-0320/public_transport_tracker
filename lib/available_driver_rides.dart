// available_driver_rides.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // For formatting time

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
    if (!mounted) {
      print('[_fetchAvailableRides] Widget not mounted, returning.');
      return; // Ensure widget is still in the tree before updating state
    }
    setState(() {
      _isLoading = true; // Set loading to true before fetching
    });
    try {
      // Get the current authenticated user's ID.
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        // If no user is logged in, stop loading and return.
        print('[_fetchAvailableRides] User not logged in.');
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      // Perform the Supabase query.
      final response = await _supabase
          .from('ride')
          .select('*') // Select all columns
          .eq('driver_id', userId) // Filter by the current driver's ID
          .order('created_at', ascending: false); // Order by creation time

      // Update the state with the fetched rides and set loading to false.
      if (mounted) {
        setState(() {
          // Ensure the response is cast to the correct list type.
          _availableRides = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
          print('[_fetchAvailableRides] Rides fetched successfully: ${_availableRides.length}');
        });
      }
    } catch (e) {
      // If an error occurs, set loading to false and show a SnackBar.
      print('[_fetchAvailableRides] Error fetching rides: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching rides: ${e.toString()}')),
        );
      }
    }
  }

  /// Deletes a ride from the 'ride' table in Supabase and related entries from 'request_ride'.
  /// After deletion, it refetches the available rides to update the UI.
  Future<void> _deleteRide(String rideId, String driverId) async {
    if (!mounted) {
      print('[_deleteRide] Widget not mounted, returning.');
      return; // Ensure widget is still in the tree
    }
    setState(() {
      _isLoading = true; // Show loading indicator during deletion
    });
    try {
      print('[_deleteRide] Attempting to delete rideId: $rideId, driverId: $driverId');
      // 1. Delete from 'request_ride' table where driver_id matches
      await _supabase
          .from('request_ride')
          .delete()
          .eq('driver_id', driverId)
          .eq('ride_id', rideId); // Ensure specific ride request is deleted
      print('[_deleteRide] Deleted from request_ride.');

      // 2. Delete from 'ride' table
      await _supabase.from('ride').delete().eq('id', rideId);
      print('[_deleteRide] Deleted from ride table.');

      await _fetchAvailableRides(); // Refetch rides to update the list after deletion.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Ride and associated requests deleted successfully')),
        );
      }
    } catch (e) {
      print('[_deleteRide] Error deleting ride: $e');
      if (mounted) {
        setState(() {
          _isLoading = false; // Hide loading indicator on error
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting ride: ${e.toString()}')),
        );
      }
    }
  }

  /// Shows a detailed popup for a selected ride, allowing editing and deletion.
  Future<void> _showRideDetailsPopup(Map<String, dynamic> ride) async {
    // Initialize controllers with current ride data
    TextEditingController capacityController =
        TextEditingController(text: ride['capacity']?.toString() ?? '');
    TextEditingController remainingCapacityController =
        TextEditingController(text: ride['remaining_capacity']?.toString() ?? '');
    TextEditingController totalCostController =
        TextEditingController(text: ride['total_cost']?.toStringAsFixed(2) ?? '');
    TextEditingController departureTimeController =
        TextEditingController(text: ride['departure_time'] ?? '');
    TextEditingController contactController =
        TextEditingController(text: ride['contact'] ?? '');

    // Note: selectedTime is primarily for the time picker in the edit dialog.
    // For display, we use departureTimeController.text.
    TimeOfDay? selectedTime = _parseTimeOfDay(ride['departure_time']);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: EdgeInsets.zero,
          contentPadding: EdgeInsets.zero,
          insetPadding: EdgeInsets.all(16),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image section
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    image: ride['image_url'] != null
                        ? DecorationImage(
                            image: NetworkImage(ride['image_url']),
                            fit: BoxFit.cover,
                            onError: (exception, stackTrace) {
                              print('Error loading image: $exception');
                            },
                          )
                        : null,
                  ),
                  child: ride['image_url'] == null
                      ? Center(
                          child: Icon(Icons.image_not_supported,
                              size: 60, color: Colors.grey[400]),
                        )
                      : null,
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ride #${ride['ride_number'] ?? 'N/A'}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: Color(0xFF5A3D1F),
                        ),
                      ),
                      SizedBox(height: 10),
                      _buildDetailRow(Icons.location_on, 'Pickup Point:',
                          ride['pickup_point'] ?? 'N/A'),
                      _buildDetailRow(Icons.location_on, 'Dropoff Point:',
                          ride['dropoff_point'] ?? 'N/A'),
                      _buildDetailRow(Icons.directions, 'Distance:',
                          '${ride['distance']?.toStringAsFixed(1) ?? '0.0'} km'),
                      _buildDetailRow(Icons.access_time, 'Departure Time:',
                          departureTimeController.text),
                      _buildDetailRow(Icons.event_seat, 'Capacity:',
                          '${remainingCapacityController.text} / ${capacityController.text}'), // Display remaining/total capacity
                      _buildDetailRow(Icons.attach_money, 'Total Cost:',
                          '\$${totalCostController.text}'),
                      _buildDetailRow(Icons.directions_car, 'Vehicle Type:',
                          ride['vehicle_type'] ?? 'N/A'),
                      _buildDetailRow(
                          Icons.phone, 'Contact:', contactController.text),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(dialogContext)
                                  .pop(); // Close details popup
                              _showEditRideDialog(ride); // Open edit dialog
                            },
                            icon: Icon(Icons.edit, color: Colors.white),
                            label: Text('Edit Ride',
                                style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF5A3D1F),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(dialogContext)
                                  .pop(); // Close details popup
                              _confirmDeleteRide(ride['id'].toString(),
                                  ride['driver_id'].toString());
                            },
                            icon: Icon(Icons.delete, color: Colors.white),
                            label: Text('Delete Ride',
                                style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: Text('Close',
                              style: TextStyle(color: Color(0xFF5A3D1F))),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Helper to parse a time string into TimeOfDay.
  TimeOfDay? _parseTimeOfDay(String? timeString) {
    if (timeString == null || timeString.isEmpty) return null;
    try {
      // Assuming timeString is in a format like "10:30 AM" or "10:30 PM"
      final format = DateFormat.jm();
      final dateTime = format.parse(timeString);
      return TimeOfDay.fromDateTime(dateTime);
    } catch (e) {
      print('Error parsing time string "$timeString": $e');
      return null;
    }
  }

  /// Helper to build a single detail row in the popup.
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[700], size: 20),
          SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF5A3D1F),
              fontSize: 15,
            ),
          ),
          SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[800], fontSize: 15),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  /// Shows a dialog to edit ride details.
  Future<void> _showEditRideDialog(Map<String, dynamic> ride) async {
    final _editFormKey = GlobalKey<FormState>();
    TextEditingController editCapacityController =
        TextEditingController(text: ride['capacity']?.toString() ?? '');
    // Note: remaining_capacity is typically derived, not directly editable by driver in this context.
    // If it were, you'd add a controller for it here.
    TextEditingController editTotalCostController =
        TextEditingController(text: ride['total_cost']?.toStringAsFixed(2) ?? '');
    TextEditingController editDepartureTimeController =
        TextEditingController(text: ride['departure_time'] ?? '');
    TextEditingController editContactController =
        TextEditingController(text: ride['contact']?.toString() ?? ''); // Ensure it's string

    TimeOfDay? currentSelectedTime = _parseTimeOfDay(ride['departure_time']);

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Edit Ride Details',
            style: TextStyle(color: Color(0xFF5A3D1F), fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _editFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildEditInputField(
                    context,
                    Icons.event_seat,
                    'Capacity',
                    editCapacityController,
                    TextInputType.number,
                    (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      final parsedValue = int.tryParse(value);
                      if (parsedValue == null || parsedValue <= 0)
                        return 'Enter a valid number (>0)';
                      return null;
                    },
                  ),
                  _buildEditInputField(
                    context,
                    Icons.attach_money,
                    'Total Cost',
                    editTotalCostController,
                    TextInputType.numberWithOptions(decimal: true),
                    (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      final parsedValue = double.tryParse(value);
                      if (parsedValue == null || parsedValue <= 0)
                        return 'Enter a valid cost (>0)';
                      return null;
                    },
                  ),
                  GestureDetector(
                    onTap: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: currentSelectedTime ?? TimeOfDay.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: Color(0xFF5A3D1F),
                                onPrimary: Colors.white,
                                onSurface: Color(0xFF5A3D1F),
                              ),
                              textButtonTheme: TextButtonThemeData(
                                style: TextButton.styleFrom(
                                  foregroundColor: Color(0xFF5A3D1F),
                                ),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        // Use the setState from StatefulBuilder to update the dialog's UI
                        if (mounted) { // Ensure the parent widget is still mounted
                           setState(() {
                              currentSelectedTime = picked;
                              editDepartureTimeController.text = picked.format(dialogContext); // Use dialogContext
                           });
                        }
                      }
                    },
                    child: AbsorbPointer(
                      child: _buildEditInputField(
                        context,
                        Icons.access_time,
                        'Departure Time',
                        editDepartureTimeController,
                        TextInputType.datetime,
                        (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          return null;
                        },
                        readOnly: true,
                      ),
                    ),
                  ),
                  _buildEditInputField(
                    context,
                    Icons.phone,
                    'Contact',
                    editContactController,
                    TextInputType.phone,
                    (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      if (!RegExp(r'^[0-9]+$').hasMatch(value))
                        return 'Numbers only';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancel', style: TextStyle(color: Color(0xFF5A3D1F))),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_editFormKey.currentState!.validate()) {
                  Navigator.of(dialogContext).pop(); // Close edit dialog
                  // Pass the original remaining_capacity if it's not being edited
                  final originalRemainingCapacity = ride['remaining_capacity'] as int? ?? ride['capacity'] as int? ?? 0;
                  await _updateRideDetails(
                    ride['id'].toString(),
                    int.parse(editCapacityController.text),
                    double.parse(editTotalCostController.text),
                    editDepartureTimeController.text,
                    editContactController.text,
                    originalRemainingCapacity, // Pass original remaining capacity
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF5A3D1F),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  /// Helper to build an input field for the edit dialog.
  Widget _buildEditInputField(
    BuildContext context,
    IconData icon,
    String label,
    TextEditingController controller,
    TextInputType keyboardType,
    String? Function(String?)? validator, {
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Color(0xFF5A3D1F)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Color(0xFF5A3D1F)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Color(0xFF5A3D1F), width: 2),
          ),
          labelStyle: TextStyle(color: Color(0xFF5A3D1F)),
        ),
        validator: validator,
      ),
    );
  }

  /// Updates ride details in the Supabase 'ride' table.
  Future<void> _updateRideDetails(
    String rideId,
    int newCapacity,
    double newTotalCost,
    String newDepartureTime,
    String newContact,
    int originalRemainingCapacity, // Added original remaining capacity
  ) async {
    if (!mounted) {
      print('[_updateRideDetails] Widget not mounted, returning.');
      return; // Ensure widget is still in the tree
    }
    setState(() {
      _isLoading = true; // Show loading indicator
    });
    try {
      // Calculate new remaining capacity based on new total capacity
      // If new capacity is less than original remaining, adjust remaining capacity
      // Otherwise, keep original remaining capacity relative to new total capacity
      int updatedRemainingCapacity = originalRemainingCapacity;
      if (newCapacity < originalRemainingCapacity) {
        updatedRemainingCapacity = newCapacity; // Remaining cannot exceed new total capacity
      }

      await _supabase.from('ride').update({
        'capacity': newCapacity,
        'remaining_capacity': updatedRemainingCapacity, // Update remaining capacity
        'total_cost': newTotalCost,
        'departure_time': newDepartureTime,
        'contact': newContact,
      }).eq('id', rideId);
      print('[_updateRideDetails] Ride updated successfully in Supabase.');

      await _fetchAvailableRides(); // Refetch rides to update UI
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ride details updated successfully!')),
        );
      }
    } catch (e) {
      print('[_updateRideDetails] Error updating ride: $e');
      if (mounted) {
        setState(() {
          _isLoading = false; // Hide loading indicator on error
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating ride: ${e.toString()}')),
        );
      }
    }
  }

  /// Shows a confirmation dialog before deleting a ride.
  Future<void> _confirmDeleteRide(String rideId, String driverId) async {
    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Confirm Deletion',
              style: TextStyle(color: Color(0xFF5A3D1F))),
          content: Text(
            'Are you sure you want to delete this ride? This will also remove associated ride requests.',
            style: TextStyle(color: Colors.grey[700]),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Color(0xFF5A3D1F))),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _deleteRide(rideId, driverId);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Total Available (${_availableRides.length})', // Display total rides
          style: TextStyle(
            color: Color(0xFF5A3D1F),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Color(0xFF5A3D1F)),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: Color(0xFF5A3D1F)),
            )
          : _availableRides.isEmpty
              ? Center(
                  child: Text(
                    'No available rides',
                    style: TextStyle(color: Color(0xFF5A3D1F), fontSize: 18),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(8),
                  itemCount: _availableRides.length,
                  itemBuilder: (context, index) {
                    final ride = _availableRides[index];
                    return RideCard(
                      ride: ride,
                      onTap: () => _showRideDetailsPopup(ride),
                      onEdit: () => _showEditRideDialog(ride), // Added onEdit callback
                      onDelete: () => _confirmDeleteRide(
                          ride['id'].toString(), ride['driver_id'].toString()),
                    );
                  },
                ),
    );
  }
}

/// A custom widget to display a single ride in a stylish card format.
class RideCard extends StatelessWidget {
  final Map<String, dynamic> ride;
  final VoidCallback onTap;
  final VoidCallback onEdit; // New callback for edit
  final VoidCallback onDelete;

  const RideCard({
    Key? key,
    required this.ride,
    required this.onTap,
    required this.onEdit, // Required for the new edit button
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final int capacity = ride['capacity'] as int? ?? 0;
    final int remainingCapacity = ride['remaining_capacity'] as int? ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 5,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ride #${ride['ride_number'] ?? 'N/A'}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5A3D1F),
                      fontSize: 18,
                    ),
                  ),
                  Row(
                    // Group edit and delete buttons
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.edit,
                          color: Color(0xFF5A3D1F),
                          size: 24,
                        ),
                        onPressed: onEdit, // Call the new onEdit callback
                        tooltip: 'Edit Ride',
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete,
                          color: Colors.redAccent,
                          size: 24,
                        ),
                        onPressed: onDelete,
                        tooltip: 'Delete Ride',
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 10),
              _buildInfoRow(Icons.alt_route,
                  '${ride['pickup_point'] ?? 'N/A'} to ${ride['dropoff_point'] ?? 'N/A'}'),
              SizedBox(height: 5),
              _buildInfoRow(
                  Icons.access_time, 'Departure: ${ride['departure_time'] ?? 'N/A'}'),
              SizedBox(height: 5),
              _buildInfoRow(Icons.event_seat,
                  'Capacity: $remainingCapacity / $capacity'), // Display remaining/total
              SizedBox(height: 5),
              _buildInfoRow(Icons.attach_money,
                  'Cost: \$${ride['total_cost']?.toStringAsFixed(2) ?? '0.00'}'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
