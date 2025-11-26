// lib/screens/forgot_pin_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import 'package:gym/auth/auth_provider.dart';

class ForgotPinScreen extends StatefulWidget {
  const ForgotPinScreen({super.key});

  @override
  State<ForgotPinScreen> createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends State<ForgotPinScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  String? _securityQuestion;
  bool _isLoading = true;
  bool _isVerified = false; // Tracks if they answered correctly

  @override
  void initState() {
    super.initState();
    _loadSecurityQuestion();
  }

  Future<void> _loadSecurityQuestion() async {
    final provider = Provider.of<AuthProvider>(context, listen: false);
    final question = await provider.getSecurityQuestion();
    setState(() {
      _securityQuestion = question;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset PIN')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: _isVerified ? _buildResetForm() : _buildVerifyForm(),
            ),
    );
  }

  // Form 1: Answer the security question
  Widget _buildVerifyForm() {
    if (_securityQuestion == null) {
      return const Center(child: Text("No security question was set. You cannot reset your PIN."));
    }

    return FormBuilder(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Security Question:", style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(_securityQuestion!, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          FormBuilderTextField(
            name: 'answer',
            decoration: const InputDecoration(
              labelText: 'Your Answer',
              border: OutlineInputBorder(),
            ),
            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState?.saveAndValidate() ?? false) {
                  final answer = _formKey.currentState!.value['answer'];
                  final isValid = await Provider.of<AuthProvider>(context, listen: false).recoverAccount(answer);
                  
                  if (isValid) {
                    setState(() {
                      _isVerified = true; // Switch to Reset Mode
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Incorrect answer.')),
                    );
                  }
                }
              },
              child: const Text("Verify Answer"),
            ),
          ),
        ],
      ),
    );
  }

  // Form 2: Create new PIN (shown after verification)
  Widget _buildResetForm() {
    final resetKey = GlobalKey<FormBuilderState>();
    
    return FormBuilder(
      key: resetKey,
      child: Column(
        children: [
          const Icon(Icons.lock_reset, size: 60, color: Colors.green),
          const SizedBox(height: 16),
          const Text("Identity Verified. Set your new PIN.", style: TextStyle(fontSize: 18)),
          const SizedBox(height: 24),
          FormBuilderTextField(
            name: 'new_pin',
            decoration: const InputDecoration(
              labelText: 'New 4-Digit PIN',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            validator: (val) {
              if (val == null || val.length != 4) return 'Enter 4 digits';
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () async {
                if (resetKey.currentState?.saveAndValidate() ?? false) {
                  final newPin = resetKey.currentState!.value['new_pin'];
                  
                  // We update the PIN, keeping existing security questions
                  await Provider.of<AuthProvider>(context, listen: false).setPin(
                    newPin,
                    // We don't update the Q/A here, just the PIN
                  );
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PIN Reset Successfully!')),
                    );
                    Navigator.pop(context); // Go back to login
                  }
                }
              },
              child: const Text("Save New PIN"),
            ),
          ),
        ],
      ),
    );
  }
}