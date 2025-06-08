import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  Map<String, dynamic>? _userProfile;
  bool _isDriver = false;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _deleteEmailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _businessNameController.dispose();
    _deleteEmailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        // Check user type first
        final userData = await _supabase
            .from('profiles')
            .select('user_type')
            .eq('user_id', user.id)
            .single();
            
        _isDriver = userData['user_type'] == 'driver';
        
        final tableName = _isDriver ? 'driver_profiles' : 'passenger_profiles';
        final response = await _supabase
            .from(tableName)
            .select()
            .eq('user_id', user.id)
            .single();

        setState(() {
          _userProfile = response;
          if (_isDriver) {
            _businessNameController.text = response['business_name'] ?? '';
          } else {
            _nameController.text = response['full_name'] ?? '';
          }
          _emailController.text = user.email ?? '';
          _phoneController.text = response['phone'] ?? '';
          _addressController.text = response['address'] ?? '';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final tableName = _isDriver ? 'driver_profiles' : 'passenger_profiles';
        final profileData = {
          'user_id': user.id,
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        if (_isDriver) {
          profileData['business_name'] = _businessNameController.text.trim();
        } else {
          profileData['full_name'] = _nameController.text.trim();
        }

        await _supabase.from(tableName).upsert(profileData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

Future<void> _initiateAccountDeletion() async {
  final user = _supabase.auth.currentUser;
  if (user == null) return;

  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text(
        "Delete Account",
        style: TextStyle(
          color: Color(0xFF5A3D1F),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "To delete your account, please enter your email address. "
            "We'll send a verification link to confirm the deletion.",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _deleteEmailController,
            decoration: InputDecoration(
              labelText: 'Email Address',
              prefixIcon: const Icon(Icons.email, color: Color(0xFF5A3D1F)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Required';
              if (value != user.email) return 'Email does not match';
              return null;
            },
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            "Cancel",
            style: TextStyle(color: Color(0xFF5A3D1F)),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5A3D1F),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () async {
            if (_deleteEmailController.text != user.email) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter your registered email'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            Navigator.pop(context);
            await _sendDeletionVerification();
          },
          child: const Text(
            "Continue",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
  );
}

Future<void> _sendDeletionVerification() async {
  setState(() => _isLoading = true);
  try {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          "Verify Deletion",
          style: TextStyle(color: Color(0xFF5A3D1F)),
        ),
        content: const Text(
          "We've sent a verification link to your email. "
          "Please click the link to confirm account deletion.",
          style: TextStyle(color: Colors.grey),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Color(0xFF5A3D1F)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _confirmAccountDeletion();
            },
            child: const Text(
              "I've Verified",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error sending verification: $e'),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    setState(() => _isLoading = false);
  }
}

Future<void> _confirmAccountDeletion() async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text(
        "Confirm Deletion",
        style: TextStyle(color: Colors.red),
      ),
      content: const Text(
        "This will permanently delete your account and all associated data. "
        "This action cannot be undone. Are you sure?",
        style: TextStyle(color: Colors.grey),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            "Cancel",
            style: TextStyle(color: Color(0xFF5A3D1F)),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () async {
            Navigator.pop(context);
            await _deleteAccount();
          },
          child: const Text(
            "Delete Account",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
  );
}
  Future<void> _deleteAccount() async {
    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Delete from profiles table first
      await _supabase.from('profiles').delete().eq('user_id', user.id);

      // Delete from the appropriate profile table
      final tableName = _isDriver ? 'driver_profiles' : 'passenger_profiles';
      await _supabase.from(tableName).delete().eq('user_id', user.id);

      // Delete the auth user
      await _supabase.auth.admin.deleteUser(user.id);

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushNamedAndRemoveUntil(
          context, '/login', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting account: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF5A3D1F)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Profile',
          style: TextStyle(
            color: Color(0xFF5A3D1F),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading && _userProfile == null
          ? Center(child: CircularProgressIndicator(color: Color(0xFF5A3D1F)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Profile Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Color(0xFF5A3D1F).withOpacity(0.1),
                          child: Icon(
                            _isDriver ? Icons.directions_car : Icons.person,
                            size: 40,
                            color: Color(0xFF5A3D1F),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isDriver
                                    ? _businessNameController.text.isNotEmpty
                                        ? _businessNameController.text
                                        : 'No Business Name'
                                    : _nameController.text.isNotEmpty
                                        ? _nameController.text
                                        : 'No Name',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF5A3D1F),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _emailController.text,
                                style: TextStyle(
                                  color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${_isDriver ? 'Driver' : 'Passenger'} since ${DateFormat('MMM yyyy').format(DateTime.parse(_supabase.auth.currentUser?.createdAt ?? DateTime.now().toString()))}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Profile Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildFormSection('Personal Information', [
                          if (!_isDriver)
                            _buildTextFormField(
                              controller: _nameController,
                              label: 'Full Name',
                              icon: Icons.person,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your name';
                                }
                                return null;
                              },
                            ),
                          if (_isDriver)
                            _buildTextFormField(
                              controller: _businessNameController,
                              label: 'Business Name',
                              icon: Icons.business,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter business name';
                                }
                                return null;
                              },
                            ),
                          _buildTextFormField(
                            controller: _emailController,
                            label: 'Email',
                            icon: Icons.email,
                            enabled: false,
                          ),
                          _buildTextFormField(
                            controller: _phoneController,
                            label: 'Phone Number',
                            icon: Icons.phone,
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter phone number';
                              }
                              return null;
                            },
                          ),
                          _buildTextFormField(
                            controller: _addressController,
                            label: _isDriver ? 'Business Address' : 'Home Address',
                            icon: Icons.location_on,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter address';
                              }
                              return null;
                            },
                          ),
                        ]),
                        const SizedBox(height: 24),

                        // Account Settings
                        _buildFormSection('Account Settings', [
                          _buildSettingOption(
                            icon: Icons.notifications,
                            title: 'Notifications',
                            onTap: () {},
                          ),
                          _buildSettingOption(
                            icon: Icons.lock,
                            title: 'Change Password',
                            onTap: () {
                              Navigator.pushNamed(
                                  context, '/forgot-password');
                            },
                          ),
                          if (_isDriver)
                            _buildSettingOption(
                              icon: Icons.payment,
                              title: 'Payment Methods',
                              onTap: () {},
                            ),
                          _buildSettingOption(
                            icon: Icons.help,
                            title: 'Help & Support',
                            onTap: () {},
                          ),
                          _buildSettingOption(
                            icon: Icons.delete,
                            title: 'Delete Account',
                            color: Colors.red,
                            onTap: _initiateAccountDeletion,
                          ),
                        ]),
                        const SizedBox(height: 32),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _updateProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5A3D1F),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Logout Button
                        TextButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: Text(
                                    "Logout",
                                    style: TextStyle(
                                      color: Color(0xFF5A3D1F),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: Text(
                                    "Are you sure you want to logout?",
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: Text("Cancel",
                                          style: TextStyle(
                                              color: Color(0xFF5A3D1F))),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFF5A3D1F),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      onPressed: () async {
                                        Navigator.of(context).pop();
                                        await _supabase.auth.signOut();
                                        Navigator.pushNamedAndRemoveUntil(
                                            context, '/login', (route) => false);
                                      },
                                      child: Text("Logout",
                                          style:
                                              TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: Text(
                            'Logout',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFormSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5A3D1F),
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Color(0xFF5A3D1F)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey[100],
        ),
      ),
    );
  }

  Widget _buildSettingOption({
    required IconData icon,
    required String title,
    Color? color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color ?? Color(0xFF5A3D1F)),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? Color(0xFF5A3D1F),
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: color ?? Color(0xFF5A3D1F)),
      onTap: onTap,
    );
  }
}