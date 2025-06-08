// my_rides_page.dart (or include in main.dart)
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class MyRidesPage extends StatefulWidget {
  const MyRidesPage({Key? key}) : super(key: key);

  @override
  State<MyRidesPage> createState() => _MyRidesPageState();
}

class _MyRidesPageState extends State<MyRidesPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> myRides = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyRides();
  }

  Future<void> _loadMyRides() async {
    setState(() => isLoading = true);
    try {
      // Assuming 'driver_id' is the column that links rides to a driver
      // You'll need to get the current authenticated user's ID
      final User? currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not logged in.')),
          );
        }
        setState(() => isLoading = false);
        return;
      }

      // Fetch rides where 'driver_id' matches the current user's ID
      final response = await supabase
          .from('rides') // Assuming you have a 'rides' table for driver's own rides
          .select('''
            id,
            origin,
            destination,
            departure_time,
            fare,
            available_seats,
            status // e.g., 'active', 'completed', 'cancelled'
          ''')
          .eq('driver_id', currentUser.id) // Filter by driver_id
          .order('departure_time', ascending: false);

      setState(() {
        myRides = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading my rides: $e')));
      }
    }
  }

  Future<void> _editRide(Map<String, dynamic> ride) async {
    // Navigate to a new page or show a dialog to edit the ride details
    // For simplicity, let's show a dialog for now
    await showDialog(
      context: context,
      builder: (context) => EditRideDialog(ride: ride),
    );
    // Reload rides after potential edit
    _loadMyRides();
  }

  Future<void> _deleteRide(String rideId) async {
    try {
      setState(() => isLoading = true);
      await supabase.from('rides').delete().eq('id', rideId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride deleted successfully')),
        );
      }
      await _loadMyRides();
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete ride: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF5A3D1F)));
    }

    if (myRides.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No rides posted yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Post your first ride to earn!',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to the "Add Ride" page
                Navigator.pushNamed(context, '/driver-ride');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5A3D1F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child:
                  const Text('Post New Ride', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMyRides,
      color: const Color(0xFF5A3D1F),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: myRides.length,
        itemBuilder: (context, index) {
          final ride = myRides[index];
          return _buildMyRideCard(ride);
        },
      ),
    );
  }

  Widget _buildMyRideCard(Map<String, dynamic> ride) {
    final departureTime = ride['departure_time'] != null
        ? DateTime.parse(ride['departure_time'])
        : null;
    final formattedDeparture = departureTime != null
        ? DateFormat('MMM d, h:mm a').format(departureTime)
        : 'Not specified';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ride ID: ${ride['id']?.toString().substring(0, 8) ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(ride['status'] ?? 'active'),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    (ride['status'] ?? 'active').toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.place, 'From:', ride['origin'] ?? 'N/A'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.place, 'To:', ride['destination'] ?? 'N/A'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.access_time, 'Departure:', formattedDeparture),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.money, 'Fare:', 'K${ride['fare']?.toStringAsFixed(2) ?? '0.00'}'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.people, 'Available Seats:', ride['available_seats']?.toString() ?? 'N/A'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _editRide(ride),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF5A3D1F),
                    side: const BorderSide(color: Color(0xFF5A3D1F)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _showDeleteRideDialog(ride['id']),
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF5A3D1F), size: 18),
        const SizedBox(width: 8),
        Text(
          '$label ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Color(0xFF5A3D1F)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blueGrey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Future<void> _showDeleteRideDialog(String rideId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Delete Ride',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5A3D1F),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Are you sure you want to delete this ride? This action cannot be undone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Color(0xFF5A3D1F)),
                        ),
                      ),
                      child: Text(
                        'No',
                        style: TextStyle(
                          color: Color(0xFF5A3D1F),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _deleteRide(rideId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: const Text(
                        'Yes, Delete',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Dialog for editing a ride
class EditRideDialog extends StatefulWidget {
  final Map<String, dynamic> ride;

  const EditRideDialog({Key? key, required this.ride}) : super(key: key);

  @override
  State<EditRideDialog> createState() => _EditRideDialogState();
}

class _EditRideDialogState extends State<EditRideDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _originController;
  late TextEditingController _destinationController;
  late TextEditingController _fareController;
  late TextEditingController _availableSeatsController;
  DateTime? _selectedDepartureTime;

  @override
  void initState() {
    super.initState();
    _originController = TextEditingController(text: widget.ride['origin']);
    _destinationController = TextEditingController(text: widget.ride['destination']);
    _fareController = TextEditingController(text: widget.ride['fare']?.toString());
    _availableSeatsController = TextEditingController(text: widget.ride['available_seats']?.toString());
    if (widget.ride['departure_time'] != null) {
      _selectedDepartureTime = DateTime.parse(widget.ride['departure_time']);
    }
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _fareController.dispose();
    _availableSeatsController.dispose();
    super.dispose();
  }

  Future<void> _pickDepartureDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDepartureTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5A3D1F), // header background color
              onPrimary: Colors.white, // header text color
              onSurface: Color(0xFF5A3D1F), // body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF5A3D1F), // button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDepartureTime ?? DateTime.now()),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF5A3D1F), // header background color
                onPrimary: Colors.white, // header text color
                onSurface: Color(0xFF5A3D1F), // body text color
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF5A3D1F), // button text color
                ),
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDepartureTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _updateRide() async {
    if (_formKey.currentState!.validate()) {
      try {
        final SupabaseClient supabase = Supabase.instance.client;
        final updatedData = {
          'origin': _originController.text,
          'destination': _destinationController.text,
          'fare': double.parse(_fareController.text),
          'available_seats': int.parse(_availableSeatsController.text),
          'departure_time': _selectedDepartureTime?.toIso8601String(),
        };

        await supabase
            .from('rides')
            .update(updatedData)
            .eq('id', widget.ride['id']);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ride updated successfully!')),
          );
          Navigator.pop(context); // Close the dialog
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating ride: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Edit Ride Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5A3D1F),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _originController,
                  decoration: _inputDecoration('Origin', Icons.my_location),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter origin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _destinationController,
                  decoration: _inputDecoration('Destination', Icons.location_on),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter destination';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _pickDepartureDateTime,
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: _inputDecoration(
                        'Departure Time',
                        Icons.calendar_today,
                        suffixIcon: Icon(Icons.arrow_drop_down, color: Color(0xFF5A3D1F)),
                      ).copyWith(
                        hintText: _selectedDepartureTime == null
                            ? 'Select date and time'
                            : DateFormat('MMM d, yyyy h:mm a').format(_selectedDepartureTime!),
                      ),
                      validator: (value) {
                        if (_selectedDepartureTime == null) {
                          return 'Please select departure time';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _fareController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('Fare', Icons.money),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter fare';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _availableSeatsController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('Available Seats', Icons.event_seat),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter available seats';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFF5A3D1F)),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Color(0xFF5A3D1F),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _updateRide,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5A3D1F),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text(
                        'Update Ride',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
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

  InputDecoration _inputDecoration(String label, IconData icon, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF5A3D1F)),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF5A3D1F)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF5A3D1F), width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[400]!),
      ),
      floatingLabelStyle: const TextStyle(color: Color(0xFF5A3D1F)),
      labelStyle: TextStyle(color: Colors.grey[600]),
    );
  }
}