// lib/widgets/pin_input_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class PinInputField extends StatefulWidget {
  final int length;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  final bool obscureText;
  final bool autoFocus;
  final Color activeColor;
  final Color inactiveColor;

  const PinInputField({
    super.key,
    this.length = 4,
    required this.onChanged,
    this.controller,
    this.obscureText = true,
    this.autoFocus = false,
    this.activeColor = Colors.deepOrange,
    this.inactiveColor = Colors.grey,
  });

  @override
  State<PinInputField> createState() => _PinInputFieldState();
}

class _PinInputFieldState extends State<PinInputField> {
  late List<FocusNode> _focusNodes;
  late List<TextEditingController> _textControllers;
  late List<bool> _hasFocus;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(widget.length, (index) => FocusNode());
    _textControllers = List.generate(widget.length, (index) => TextEditingController());
    _hasFocus = List.generate(widget.length, (index) => false);

    // Initialize focus listeners
    for (int i = 0; i < widget.length; i++) {
      _focusNodes[i].addListener(() {
        setState(() {
          _hasFocus[i] = _focusNodes[i].hasFocus;
        });
      });
    }

    if (widget.controller != null) {
      final initialPin = widget.controller!.text;
      for (int i = 0; i < initialPin.length && i < widget.length; i++) {
        _textControllers[i].text = initialPin[i];
      }
    }
  }

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _textControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onKeyboardInput(String value, int index) {
    if (value.isEmpty) {
      // Handle backspace
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
        _textControllers[index - 1].clear();
      }
    } else {
      // Handle digit input
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }
    _emitPin();
  }

  void _emitPin() {
    String currentPin = _textControllers.map((c) => c.text).join();
    widget.onChanged(currentPin);
    if (widget.controller != null) {
      widget.controller!.text = currentPin;
    }
  }

  Color _getBorderColor(int index) {
    if (_hasFocus[index]) {
      return widget.activeColor;
    }
    if (_textControllers[index].text.isNotEmpty) {
      return widget.activeColor.withOpacity(0.7);
    }
    return widget.inactiveColor;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(widget.length, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: _hasFocus[index] ? widget.activeColor.withOpacity(0.05) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getBorderColor(index),
              width: _hasFocus[index] ? 2 : 1.5,
            ),
            boxShadow: _hasFocus[index] 
                ? [
                    BoxShadow(
                      color: widget.activeColor.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: TextField(
            controller: _textControllers[index],
            focusNode: _focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(1),
            ],
            obscureText: widget.obscureText,
            obscuringCharacter: '•',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              counterText: '',
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (value) => _onKeyboardInput(value, index),
            autofocus: widget.autoFocus && index == 0,
            cursorColor: widget.activeColor,
            cursorWidth: 1.5,
          ),
        );
      }),
    );
  }
}