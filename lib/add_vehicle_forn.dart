import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

/// A StatefulWidget that handles the form and logic for adding a new vehicle.
class AddVehicleForm extends StatefulWidget {
  /// The Supabase client instance for database operations.
  final SupabaseClient supabase;

  /// Callback function to be executed when a vehicle is successfully added.
  final Function() onVehicleAdded;

  /// Callback function to update the selected image in the parent widget.
  final Function(File?) onImageSelected;

  /// The currently selected image file, passed from the parent.
  final File? selectedImage;

  const AddVehicleForm({
    Key? key,
    required this.supabase,
    required this.onVehicleAdded,
    required this.onImageSelected,
    this.selectedImage,
  }) : super(key: key);

  @override
  _AddVehicleFormState createState() => _AddVehicleFormState();
}

class _AddVehicleFormState extends State<AddVehicleForm> {
  // Text editing controllers for vehicle details.
  final TextEditingController _numberPlateController = TextEditingController();
  final TextEditingController _vehicleCapacityController =
      TextEditingController();

  // Global key for form validation.
  final _formKey = GlobalKey<FormState>();

  // State variable to manage loading indicator.
  bool _isLoading = false;

  // List of available vehicle types for the dropdown.
  final List<String> _vehicleTypes = [
    'Bus',
    'Coster',
    'Minibus',
    'Taxi',
    'Van',
  ];

  // Currently selected vehicle type from the dropdown.
  String? _selectedVehicleType;

  // Local state for the selected image, kept in sync with parent via callback.
  File? _localSelectedImage;

  @override
  void initState() {
    super.initState();
    // Initialize local image state with the image passed from the parent.
    _localSelectedImage = widget.selectedImage;
  }

  @override
  void didUpdateWidget(covariant AddVehicleForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update local image state if the image in the parent changes.
    if (widget.selectedImage != oldWidget.selectedImage) {
      setState(() {
        _localSelectedImage = widget.selectedImage;
      });
    }
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks.
    _numberPlateController.dispose();
    _vehicleCapacityController.dispose();
    super.dispose();
  }

  /// Handles picking an image from the gallery.
  /// Updates the local image state and notifies the parent widget.
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _localSelectedImage = File(pickedFile.path);
      });
      // Notify the parent widget about the selected image.
      widget.onImageSelected(_localSelectedImage);
    }
  }

  /// Uploads the vehicle data to Supabase.
  /// Validates the form, uploads image (if any), and inserts vehicle details.
  Future<void> _uploadVehicleData() async {
    // Validate the form fields.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true; // Show loading indicator.
    });

    try {
      String? imageUrl;
      // Upload image to Supabase storage if selected.
      if (_localSelectedImage != null) {
        final filePath =
            'vehicles/${DateTime.now().millisecondsSinceEpoch}.jpg';
        await widget.supabase.storage
            .from('vehicle_images')
            .upload(filePath, _localSelectedImage!);
        imageUrl = widget.supabase.storage
            .from('vehicle_images')
            .getPublicUrl(filePath);
      }

      // Insert vehicle data into the 'vehicle' table in Supabase.
      await widget.supabase.from('vehicle').insert({
        'number_plate': _numberPlateController.text,
        'vehicle_type': _selectedVehicleType,
        'capacity': int.parse(_vehicleCapacityController.text),
        'created_at': DateTime.now().toIso8601String(),
        'image_url': imageUrl, // Store the image URL.
      });

      if (!mounted) return;
      // Show success message.
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Vehicle added successfully!')));
      _clearForm(); // Clear the form fields.
      widget.onVehicleAdded(); // Notify the parent that the vehicle was added.
    } catch (e) {
      if (!mounted) return;
      // Show error message if upload fails.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding vehicle: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator.
      });
    }
  }

  /// Clears all the form fields and resets the selected image.
  void _clearForm() {
    _numberPlateController.clear();
    _vehicleCapacityController.clear();
    setState(() {
      _selectedVehicleType = null;
      _localSelectedImage = null;
    });
    // Notify the parent to clear its selected image state.
    widget.onImageSelected(null);
  }

  /// Helper widget to build a common input text field.
  Widget _buildInputField(
    BuildContext context,
    IconData icon,
    String label,
    TextEditingController controller,
    TextInputType keyboardType,
    String? Function(String?)? validator, {
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Color(0xFF5A3D1F), // Theme color
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Color(0xFF5A3D1F)), // Theme color
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
            hintText: 'Enter $label',
            hintStyle: TextStyle(color: Colors.grey[500]),
          ),
          validator: validator,
        ),
        SizedBox(height: 15),
      ],
    );
  }

  /// Helper widget to build a common dropdown field.
  Widget _buildDropdownField(
    String label,
    String? selectedValue,
    ValueChanged<String?> onChanged, {
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Color(0xFF5A3D1F), // Theme color
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedValue,
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.directions_car,
              color: Color(0xFF5A3D1F),
            ), // Theme color
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
          ),
          hint: Text(
            'Select Vehicle Type',
            style: TextStyle(color: Colors.grey[500]),
          ),
          items:
              _vehicleTypes.map((String type) {
                return DropdownMenuItem<String>(value: type, child: Text(type));
              }).toList(),
          onChanged: onChanged,
          validator: validator,
        ),
        SizedBox(height: 15),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Center(
          // Show loading indicator when data is being uploaded.
          child: CircularProgressIndicator(
            color: Color(0xFF5A3D1F),
          ), // Theme color
        )
        : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section to add/change vehicle photos.
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (_localSelectedImage != null)
                      // Display selected image if available.
                      Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: FileImage(_localSelectedImage!),
                            fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      )
                    else
                      // Display add photo icon if no image is selected.
                      Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Color(
                            0xFF8B5E3B,
                          ).withOpacity(0.1), // Theme color
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Icon(
                          Icons.add_a_photo,
                          color: Color(0xFF5A3D1F), // Theme color
                          size: 40,
                        ),
                      ),
                    SizedBox(height: 10),
                    Text(
                      _localSelectedImage != null
                          ? "Change Photo"
                          : "Add Photos",
                      style: TextStyle(
                        color: Color(0xFF5A3D1F), // Theme color
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            // Form for vehicle details.
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Input field for Number Plate.
                  _buildInputField(
                    context,
                    Icons.numbers,
                    "Number Plate",
                    _numberPlateController,
                    TextInputType.text,
                    (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter number plate';
                      }
                      return null;
                    },
                  ),
                  // Dropdown for Vehicle Type.
                  _buildDropdownField(
                    "Vehicle Type",
                    _selectedVehicleType,
                    (String? newValue) {
                      setState(() {
                        _selectedVehicleType = newValue;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select vehicle type';
                      }
                      return null;
                    },
                  ),
                  // Input field for Capacity.
                  _buildInputField(
                    context,
                    Icons.people,
                    "Capacity",
                    _vehicleCapacityController,
                    TextInputType.number,
                    (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter capacity';
                      }
                      if (int.tryParse(value) == null ||
                          int.parse(value) <= 0) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  // Button to add the vehicle.
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _uploadVehicleData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF5A3D1F), // Theme color
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                      ),
                      child:
                          _isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text(
                                "Add Vehicle",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
  }
}
