// edit_profile_page.dart
import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // Constants
  static const _primaryColor = Color(0xFF8B5E3B);
  static const _avatarBackgroundColor = Color(0xFF5A3D1F);
  static const _formPadding = EdgeInsets.all(24.0);
  static const _fieldSpacing = SizedBox(height: 16);
  static const _buttonPadding = EdgeInsets.symmetric(vertical: 16);

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: _formPadding,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildProfileAvatar(),
                  _fieldSpacing,
                  _buildChangePhotoButton(),
                  _fieldSpacing,
                  _buildNameField(),
                  _fieldSpacing,
                  _buildEmailField(),
                  _fieldSpacing,
                  _buildPhoneField(),
                  const SizedBox(height: 24),
                  _buildSaveButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        'Edit Profile',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.save_outlined),
          onPressed: _saveProfile,
          tooltip: 'Save Profile',
        ),
      ],
    );
  }

  Widget _buildProfileAvatar() {
    return CircleAvatar(
      radius: 60,
      backgroundColor: _avatarBackgroundColor,
      child: const Icon(
        Icons.person_outline,
        size: 60,
        color: Colors.white,
      ),
    );
  }

  Widget _buildChangePhotoButton() {
    return TextButton(
      onPressed: _changeProfilePhoto,
      style: TextButton.styleFrom(
        foregroundColor: _primaryColor,
      ),
      child: const Text(
        'Change Profile Photo',
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Full Name',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.person_outline),
      ),
      textCapitalization: TextCapitalization.words,
      validator: (value) => value?.isEmpty ?? true 
          ? 'Please enter your name' 
          : null,
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: const InputDecoration(
        labelText: 'Email Address',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.email_outlined),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value?.isEmpty ?? true) return 'Please enter your email';
        if (!value!.contains('@')) return 'Please enter a valid email';
        return null;
      },
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      decoration: const InputDecoration(
        labelText: 'Phone Number',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.phone_outlined),
      ),
      keyboardType: TextInputType.phone,
      validator: (value) => value?.isEmpty ?? true 
          ? 'Please enter your phone number' 
          : null,
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          padding: _buttonPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: _saveProfile,
        child: const Text(
          'SAVE PROFILE',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _loadProfileData() {
    // In a real app, you would load this from your state management
    setState(() {
      _nameController.text = 'John Doe';
      _emailController.text = 'john.doe@example.com';
      _phoneController.text = '+1234567890';
    });
  }

  void _changeProfilePhoto() {
    // TODO: Implement photo change functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile photo change functionality coming soon!')),
    );
  }

  void _saveProfile() {
    if (_formKey.currentState?.validate() ?? false) {
      // TODO: Implement actual save functionality
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}