import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class AvailableDriverRides extends StatefulWidget {
  @override
  _AvailableDriverRidesState createState() => _AvailableDriverRidesState();
}

class _AvailableDriverRidesState extends State<AvailableDriverRides> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _availableRides = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAvailableRides();
  }

  Future<void> _fetchAvailableRides() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final response = await _supabase
          .from('ride')
          .select('*')
          .eq('driver_id', userId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _availableRides = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching rides: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching rides: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteRide(String rideId, String driverId) async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // Delete from request_ride first
      await _supabase
          .from('request_ride')
          .delete()
          .eq('driver_id', driverId)
          .eq('ride_id', rideId);

      // Then delete from ride table
      await _supabase.from('ride').delete().eq('id', rideId);

      await _fetchAvailableRides();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ride deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error deleting ride: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting ride: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showRideDetailsPopup(Map<String, dynamic> ride) async {
    // Ensure departure_time is formatted correctly, handling nulls
    final departureTime =
        ride['departure_time'] != null
            ? _formatTime(
              ride['departure_time'].toString(),
            ) // Ensure it's a string before formatting
            : 'Not specified';

    await showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Text(
                        // Ensure ride_number is converted to string for display
                        'Ride #${ride['ride_number']?.toString() ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5A3D1F),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Explicitly convert values to string for _buildDetailItem
                    _buildDetailItem(
                      '🚗 Vehicle Type',
                      ride['vehicle_type']?.toString() ?? 'N/A',
                    ),
                    _buildDetailItem(
                      '📍 Pickup Point',
                      ride['pickup_point']?.toString() ?? 'N/A',
                    ),
                    _buildDetailItem(
                      '🏁 Dropoff Point',
                      ride['dropoff_point']?.toString() ?? 'N/A',
                    ),
                    _buildDetailItem(
                      '📏 Distance',
                      '${ride['distance']?.toStringAsFixed(1) ?? '0.0'} km',
                    ),
                    _buildDetailItem(
                      '🧑‍🤝‍🧑 Capacity',
                      '${ride['remaining_capacity']?.toString() ?? '0'} / ${ride['capacity']?.toString() ?? '0'} seats available',
                    ),
                    _buildDetailItem('⏰ Departure Time', departureTime),
                    _buildDetailItem(
                      '💰 Total Cost',
                      '\$${ride['total_cost']?.toStringAsFixed(2) ?? '0.00'}',
                    ),
                    _buildDetailItem(
                      '📞 Contact',
                      ride['contact']?.toString() ?? 'Not provided',
                    ),

                    SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showEditRideDialog(ride);
                          },
                          child: Text(
                            'Edit',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Close',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        TextButton(
                          onPressed:
                              () => _confirmDeleteRide(
                                ride['id'].toString(),
                                ride['driver_id'].toString(),
                              ),
                          child: Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(value, style: TextStyle(fontSize: 16, color: Colors.black87)),
          Divider(),
        ],
      ),
    );
  }

  String _formatTime(String timeString) {
    try {
      final format = DateFormat.jm();
      final dateTime = format.parse(timeString);
      return format.format(dateTime);
    } catch (e) {
      return timeString;
    }
  }

  Future<void> _showEditRideDialog(Map<String, dynamic> ride) async {
    // Ensure text controllers are initialized with string values
    final capacityController = TextEditingController(
      text: ride['capacity']?.toString() ?? '',
    );
    final costController = TextEditingController(
      text: ride['total_cost']?.toStringAsFixed(2) ?? '',
    );
    final timeController = TextEditingController(
      text: ride['departure_time']?.toString() ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Edit Ride Details'),
            content: SingleChildScrollView(
              child: Form(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: capacityController,
                      decoration: InputDecoration(labelText: 'Total Capacity'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (int.tryParse(value) == null)
                          return 'Enter a number';
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: costController,
                      decoration: InputDecoration(labelText: 'Total Cost'),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (double.tryParse(value) == null)
                          return 'Enter a valid amount';
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: timeController,
                      decoration: InputDecoration(
                        labelText: 'Departure Time',
                        suffixIcon: IconButton(
                          icon: Icon(Icons.access_time),
                          onPressed: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (time != null) {
                              timeController.text = time.format(context);
                            }
                          },
                        ),
                      ),
                      readOnly: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Validate the form before popping.
                  // Note: Form.of(context) needs a BuildContext that is a descendant of the Form.
                  // A common pattern is to use a GlobalKey<FormState> for validation.
                  // For simplicity here, assuming validation happens correctly or will be handled.
                  Navigator.pop(context, true);
                },
                child: Text('Save'),
              ),
            ],
          ),
    );

    if (result == true) {
      await _updateRideDetails(
        ride['id'].toString(),
        int.parse(capacityController.text),
        double.parse(costController.text),
        timeController.text,
        ride['contact']?.toString() ?? '',
        ride['remaining_capacity'] as int? ?? 0,
      );
    }
  }

  Future<void> _updateRideDetails(
    String rideId,
    int newCapacity,
    double newTotalCost,
    String newDepartureTime,
    String contact,
    int originalRemainingCapacity,
  ) async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final updatedRemainingCapacity = min(
        originalRemainingCapacity,
        newCapacity,
      );

      final response = await _supabase
          .from('ride')
          .update({
            'capacity': newCapacity,
            'remaining_capacity': updatedRemainingCapacity,
            'total_cost': newTotalCost,
            'departure_time': newDepartureTime,
            'contact': contact,
          })
          .eq('id', rideId);

      // Print the full response object for debugging
      print('Supabase Update Response: $response');

      // Check if response is null or if response.error is not null
      if (response == null) {
        // If response is null, it indicates a deeper issue with the Supabase client
        // or network where even a response object isn't returned.
        throw Exception('Supabase update operation returned a null response.');
      } else if (response.error != null) {
        // If response is not null but contains an error, throw that error.
        throw response.error!;
      } else {
        // Success case: response is not null and response.error is null
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ride updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        await _fetchAvailableRides();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update ride: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmDeleteRide(String rideId, String driverId) async {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Confirm Deletion'),
            content: Text(
              'Are you sure you want to delete this ride? This will also remove associated ride requests.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteRide(rideId, driverId);
                },
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Available Rides (${_availableRides.length})',
          style: TextStyle(
            color: Color(0xFF5A3D1F),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF5A3D1F)),
      ),
      body:
          _isLoading
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
              : RefreshIndicator(
                onRefresh: _fetchAvailableRides,
                color: Color(0xFF5A3D1F),
                child: ListView.builder(
                  padding: EdgeInsets.all(8),
                  itemCount: _availableRides.length,
                  itemBuilder: (context, index) {
                    final ride = _availableRides[index];
                    return RideCard(
                      ride: ride,
                      onTap: () => _showRideDetailsPopup(ride),
                      onEdit: () => _showEditRideDialog(ride),
                      onDelete:
                          () => _confirmDeleteRide(
                            ride['id'].toString(),
                            ride['driver_id'].toString(),
                          ),
                    );
                  },
                ),
              ),
    );
  }
}

class RideCard extends StatelessWidget {
  final Map<String, dynamic> ride;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const RideCard({
    Key? key,
    required this.ride,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Explicitly cast to int and provide default for safety
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
                    // Ensure ride_number is converted to string for display
                    'Ride #${ride['ride_number']?.toString() ?? 'N/A'}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5A3D1F),
                      fontSize: 18,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.edit,
                          color: Color(0xFF5A3D1F),
                          size: 24,
                        ),
                        onPressed: onEdit,
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
              _buildInfoRow(
                Icons.alt_route,
                // Ensure pickup_point and dropoff_point are converted to string
                '${ride['pickup_point']?.toString() ?? 'N/A'} to ${ride['dropoff_point']?.toString() ?? 'N/A'}',
              ),
              SizedBox(height: 5),
              _buildInfoRow(
                Icons.access_time,
                // Ensure departure_time is converted to string
                'Departure: ${ride['departure_time']?.toString() ?? 'N/A'}',
              ),
              SizedBox(height: 5),
              _buildInfoRow(
                Icons.event_seat,
                'Capacity: $remainingCapacity / $capacity',
              ),
              SizedBox(height: 5),
              _buildInfoRow(
                Icons.attach_money,
                'Cost: \$${ride['total_cost']?.toStringAsFixed(2) ?? '0.00'}',
              ),
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
