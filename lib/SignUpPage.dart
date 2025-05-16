import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MalawiSignUpPage extends StatefulWidget {
  const MalawiSignUpPage({Key? key}) : super(key: key);

  @override
  _MalawiSignUpPageState createState() => _MalawiSignUpPageState();
}

class _MalawiSignUpPageState extends State<MalawiSignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _businessNameController = TextEditingController();

  bool _isLoading = false;
  bool _otpSent = false;
  bool _isDriver = false;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _phoneController.text = '+265 ';
  }

  String _formatPhoneNumber(String input) {
    final digitsOnly = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length == 12 && digitsOnly.startsWith('265')) {
      return '+$digitsOnly';
    } else if (digitsOnly.length == 9) {
      return '+265$digitsOnly';
    }
    return input;
  }

  bool _isValidMalawiNumber(String phone) {
    if (!phone.startsWith('+265') || phone.length != 13) return false;
    final prefix = phone.substring(4, 6); // Get first two digits after +265
    return prefix == '88' || prefix == '99'; // TNM (88) or Airtel (99)
  }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final formattedPhone = _formatPhoneNumber(_phoneController.text);

      if (!_isValidMalawiNumber(formattedPhone)) {
        throw AuthException(
          'Please enter a valid TNM (88) or Airtel (99) number',
        );
      }

      // This now returns void, so we don't try to use the response
      await _supabase.auth.signInWithOtp(phone: formattedPhone);

      // If we get here, OTP was sent successfully
      setState(() {
        _otpSent = true;
        _phoneController.text = formattedPhone;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('OTP sent successfully!')));
    } on AuthException catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred. Please try again.')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _completeSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final formattedPhone = _formatPhoneNumber(_phoneController.text);

      // Verify OTP first
      final authResponse = await _supabase.auth.verifyOTP(
        phone: formattedPhone,
        token: _otpController.text.trim(),
        type: OtpType.sms,
      );

      if (authResponse.user != null) {
        // Set password for future logins - don't try to use the void result
        await _supabase.auth.updateUser(
          UserAttributes(password: _passwordController.text.trim()),
        );

        // Prepare profile data
        final profileData = {
          'user_id': authResponse.user!.id,
          'address': _addressController.text.trim(),
        };

        // Add role-specific fields
        if (_isDriver) {
          profileData['business_name'] = _businessNameController.text.trim();
          await _supabase.from('driver_profiles').upsert(profileData);
        } else {
          profileData['full_name'] = _nameController.text.trim();
          await _supabase.from('passenger_profiles').upsert(profileData);
        }

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } on AuthException catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildDriverFields() {
    if (!_isDriver) return const SizedBox();

    return Column(
      children: [
        const SizedBox(height: 20),
        TextFormField(
          controller: _businessNameController,
          decoration: InputDecoration(
            labelText: 'Business Name',
            prefixIcon: Icon(Icons.business, color: Color(0xFF5A3D1F)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator:
              (value) =>
                  _isDriver && value!.isEmpty ? 'Required for drivers' : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Center(
                child: Icon(
                  Icons.directions_car,
                  size: 80,
                  color: Color(0xFF5A3D1F),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5A3D1F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select account type and enter your details',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Passenger'),
                      selected: !_isDriver,
                      onSelected: (selected) {
                        setState(() => _isDriver = !selected);
                      },
                      selectedColor: const Color(0xFF5A3D1F),
                      labelStyle: TextStyle(
                        color: !_isDriver ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Driver'),
                      selected: _isDriver,
                      onSelected: (selected) {
                        setState(() => _isDriver = selected);
                      },
                      selectedColor: const Color(0xFF5A3D1F),
                      labelStyle: TextStyle(
                        color: _isDriver ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person, color: Color(0xFF5A3D1F)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Malawi Phone Number',
                  prefixIcon: Icon(Icons.phone, color: Color(0xFF5A3D1F)),
                  hintText:
                      '+265 88 609 1096 (TNM) or +265 99 659 0401 (Airtel)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';

                  final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');

                  if (value.startsWith('+265')) {
                    if (digitsOnly.length != 12)
                      return 'Enter 9 digits after +265';
                  } else if (digitsOnly.length != 9) {
                    return 'Enter 9-digit Malawi number';
                  }

                  final phoneDigits =
                      digitsOnly.startsWith('265')
                          ? digitsOnly.substring(3)
                          : digitsOnly;

                  if (!phoneDigits.startsWith('88') &&
                      !phoneDigits.startsWith('99')) {
                    return 'Only TNM (88) or Airtel (99) numbers supported';
                  }

                  return null;
                },
                onChanged: (value) {
                  if (!value.startsWith('+265') && value.isNotEmpty) {
                    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
                    if (digits.length <= 9) {
                      _phoneController.text = '+265 $digits';
                      _phoneController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _phoneController.text.length),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: _isDriver ? 'Business Address' : 'Home Address',
                  prefixIcon: Icon(Icons.location_on, color: Color(0xFF5A3D1F)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),

              _buildDriverFields(),

              if (!_otpSent) ...[
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Create Password',
                    prefixIcon: Icon(Icons.lock, color: Color(0xFF5A3D1F)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (value.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5A3D1F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        _isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text(
                              'Send Verification Code',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 30),
                Text(
                  'Verify Phone Number',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5A3D1F),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Enter the 6-digit code sent to ${_phoneController.text}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Verification Code',
                    prefixIcon: Icon(Icons.sms, color: Color(0xFF5A3D1F)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (value.length != 6) return 'Enter 6-digit code';
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _completeSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5A3D1F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        _isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text(
                              'Complete Sign Up',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => setState(() => _otpSent = false),
                  child: Text(
                    'Change Phone Number',
                    style: TextStyle(color: Color(0xFF5A3D1F)),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? "),
                  TextButton(
                    onPressed:
                        () => Navigator.pushReplacementNamed(context, '/login'),
                    child: Text(
                      'Sign In',
                      style: TextStyle(
                        color: Color(0xFF5A3D1F),
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
    );
  }
}
