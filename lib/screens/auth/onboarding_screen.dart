// lib/screens/auth/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym/auth/auth_provider.dart';
import 'package:gym/widgets/pin_input_field.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  
  // New Controllers for Security Question
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();

  String _pin = '';
  String _confirmPin = '';
  String? _errorText;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  void _setPin() async {
    setState(() => _errorText = null);

    // Validation
    if (_pin.length != 4 || _confirmPin.length != 4) {
      setState(() => _errorText = 'PIN must be 4 digits long.');
      return;
    }
    if (_pin != _confirmPin) {
      setState(() => _errorText = 'PINs do not match.');
      return;
    }
    if (_questionController.text.isEmpty || _answerController.text.isEmpty) {
      setState(() => _errorText = 'Please set a security question and answer.');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Pass Security Info to Provider
    bool success = await authProvider.setPin(
      _pin,
      question: _questionController.text,
      answer: _answerController.text,
    );

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Account Secured Successfully!'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() => _errorText = 'Failed to save data. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.deepPurple.shade400, Colors.deepOrange.shade400]),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_outline, size: 50, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Setup Security',
                  style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // --- PIN SECTION ---
                _buildSectionTitle('Create Your PIN'),
                const SizedBox(height: 16),
                PinInputField(
                  length: 4,
                  controller: _pinController,
                  onChanged: (val) => setState(() { _pin = val; _errorText = null; }),
                ),
                const SizedBox(height: 16),
                Text('Confirm PIN', style: GoogleFonts.poppins(color: Colors.grey[600])),
                const SizedBox(height: 8),
                PinInputField(
                  length: 4,
                  controller: _confirmPinController,
                  onChanged: (val) => setState(() { _confirmPin = val; _errorText = null; }),
                ),

                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),

                // --- SECURITY QUESTION SECTION ---
                _buildSectionTitle('Account Recovery'),
                const SizedBox(height: 8),
                Text(
                  'Set a security question in case you forget your PIN.',
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: _questionController,
                  decoration: InputDecoration(
                    labelText: 'Security Question',
                    hintText: "e.g. What was your first pet's name?",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.help_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _answerController,
                  decoration: InputDecoration(
                    labelText: 'Answer',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.vpn_key_outlined),
                  ),
                ),

                // --- ERROR MESSAGE ---
                if (_errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                      _errorText!,
                      style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w500),
                    ),
                  ),

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _setPin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('Complete Setup', style: GoogleFonts.poppins(fontSize: 18, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4, height: 24,
          decoration: BoxDecoration(color: Colors.deepPurple, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
      ],
    );
  }
}