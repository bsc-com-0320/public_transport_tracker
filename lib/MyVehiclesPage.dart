// my_vehicles_page.dart (or include in main.dart)
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyVehiclesPage extends StatefulWidget {
  const MyVehiclesPage({Key? key}) : super(key: key);

  @override
  State<MyVehiclesPage> createState() => _MyVehiclesPageState();
}

class _MyVehiclesPageState extends State<MyVehiclesPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> myVehicles = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyVehicles();
  }

  Future<void> _loadMyVehicles() async {
    setState(() => isLoading = true);
    try {
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

      // Fetch vehicles where 'driver_id' matches the current user's ID
      final response = await supabase
          .from('vehicles') // Assuming you have a 'vehicles' table
          .select('''
            id,
            make,
            model,
            year,
            license_plate,
            color,
            vehicle_type,
            capacity,
            is_active // e.g., true/false
          ''')
          .eq('driver_id', currentUser.id); // Filter by driver_id

      setState(() {
        myVehicles = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading vehicles: $e')));
      }
    }
  }

  Future<void> _addVehicle() async {
    await showDialog(
      context: context,
      builder: (context) => const AddEditVehicleDialog(),
    );
    _loadMyVehicles(); // Reload vehicles after adding
  }

  Future<void> _editVehicle(Map<String, dynamic> vehicle) async {
    await showDialog(
      context: context,
      builder: (context) => AddEditVehicleDialog(vehicle: vehicle),
    );
    _loadMyVehicles(); // Reload vehicles after editing
  }

  Future<void> _deleteVehicle(String vehicleId) async {
    try {
      setState(() => isLoading = true);
      await supabase.from('vehicles').delete().eq('id', vehicleId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle deleted successfully')),
        );
      }
      await _loadMyVehicles();
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete vehicle: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF5A3D1F)));
    }

    if (myVehicles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car_filled, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No vehicles registered yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your vehicle to start driving!',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addVehicle,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5A3D1F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child:
                  const Text('Add New Vehicle', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMyVehicles,
      color: const Color(0xFF5A3D1F),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: myVehicles.length,
        itemBuilder: (context, index) {
          final vehicle = myVehicles[index];
          return _buildVehicleCard(vehicle);
        },
      ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
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
                  '${vehicle['make'] ?? 'N/A'} ${vehicle['model'] ?? 'N/A'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5A3D1F),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: vehicle['is_active'] == true ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    (vehicle['is_active'] == true ? 'ACTIVE' : 'INACTIVE'),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(color: Colors.grey[300]),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.confirmation_num, 'License Plate:', vehicle['license_plate'] ?? 'N/A'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.color_lens, 'Color:', vehicle['color'] ?? 'N/A'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.category, 'Type:', vehicle['vehicle_type'] ?? 'N/A'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.event, 'Year:', vehicle['year']?.toString() ?? 'N/A'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.airline_seat_legroom_extra, 'Capacity:', vehicle['capacity']?.toString() ?? 'N/A'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _editVehicle(vehicle),
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
                  onPressed: () => _showDeleteVehicleDialog(vehicle['id']),
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

  Future<void> _showDeleteVehicleDialog(String vehicleId) async {
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
                const Text(
                  'Delete Vehicle',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5A3D1F),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Are you sure you want to delete this vehicle?',
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFF5A3D1F)),
                        ),
                      ),
                      child: const Text(
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
                        _deleteVehicle(vehicleId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
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

// Dialog for adding or editing a vehicle
class AddEditVehicleDialog extends StatefulWidget {
  final Map<String, dynamic>? vehicle; // Nullable for add, non-null for edit

  const AddEditVehicleDialog({Key? key, this.vehicle}) : super(key: key);

  @override
  State<AddEditVehicleDialog> createState() => _AddEditVehicleDialogState();
}

class _AddEditVehicleDialogState extends State<AddEditVehicleDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _makeController;
  late TextEditingController _modelController;
  late TextEditingController _yearController;
  late TextEditingController _licensePlateController;
  late TextEditingController _colorController;
  late TextEditingController _capacityController;
  String? _selectedVehicleType;
  bool _isActive = true;

  final List<String> _vehicleTypes = ['Sedan', 'SUV', 'Hatchback', 'Van', 'Motorcycle'];

  @override
  void initState() {
    super.initState();
    _makeController = TextEditingController(text: widget.vehicle?['make']);
    _modelController = TextEditingController(text: widget.vehicle?['model']);
    _yearController = TextEditingController(text: widget.vehicle?['year']?.toString());
    _licensePlateController = TextEditingController(text: widget.vehicle?['license_plate']);
    _colorController = TextEditingController(text: widget.vehicle?['color']);
    _capacityController = TextEditingController(text: widget.vehicle?['capacity']?.toString());
    _selectedVehicleType = widget.vehicle?['vehicle_type'];
    _isActive = widget.vehicle?['is_active'] ?? true;
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _licensePlateController.dispose();
    _colorController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _saveVehicle() async {
    if (_formKey.currentState!.validate()) {
      try {
        final SupabaseClient supabase = Supabase.instance.client;
        final User? currentUser = supabase.auth.currentUser;

        if (currentUser == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User not logged in. Cannot save vehicle.')),
            );
          }
          return;
        }

        final vehicleData = {
          'driver_id': currentUser.id,
          'make': _makeController.text,
          'model': _modelController.text,
          'year': int.tryParse(_yearController.text),
          'license_plate': _licensePlateController.text,
          'color': _colorController.text,
          'vehicle_type': _selectedVehicleType,
          'capacity': int.tryParse(_capacityController.text),
          'is_active': _isActive,
        };

        if (widget.vehicle == null) {
          // Add new vehicle
          await supabase.from('vehicles').insert(vehicleData);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Vehicle added successfully!')),
            );
          }
        } else {
          // Update existing vehicle
          await supabase
              .from('vehicles')
              .update(vehicleData)
              .eq('id', widget.vehicle!['id']);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Vehicle updated successfully!')),
            );
          }
        }
        if (mounted) {
          Navigator.pop(context); // Close the dialog
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving vehicle: $e')),
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
                Text(
                  widget.vehicle == null ? 'Add New Vehicle' : 'Edit Vehicle Details',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5A3D1F),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _makeController,
                  decoration: _inputDecoration('Make', Icons.car_rental),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter vehicle make';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _modelController,
                  decoration: _inputDecoration('Model', Icons.branding_watermark),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter vehicle model';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _yearController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('Year', Icons.date_range),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter year';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid year';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _licensePlateController,
                  decoration: _inputDecoration('License Plate', Icons.credit_card),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter license plate';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _colorController,
                  decoration: _inputDecoration('Color', Icons.palette),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter color';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedVehicleType,
                  decoration: _inputDecoration('Vehicle Type', Icons.directions_car),
                  items: _vehicleTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedVehicleType = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select vehicle type';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _capacityController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('Capacity (Seats)', Icons.people),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter capacity';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text(
                    'Active',
                    style: TextStyle(
                      color: Color(0xFF5A3D1F),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  value: _isActive,
                  onChanged: (bool value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                  activeColor: const Color(0xFF5A3D1F),
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
                      onPressed: _saveVehicle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5A3D1F),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text(
                        widget.vehicle == null ? 'Add Vehicle' : 'Update Vehicle',
                        style: const TextStyle(
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

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF5A3D1F)),
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