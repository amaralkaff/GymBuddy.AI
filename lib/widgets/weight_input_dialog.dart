// lib/widgets/weight_input_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WeightInputDialog extends StatefulWidget {
  const WeightInputDialog({super.key});

  @override
  State<WeightInputDialog> createState() => _WeightInputDialogState();
}

class _WeightInputDialogState extends State<WeightInputDialog> {
  final TextEditingController _weightController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter Your Weight'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _weightController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Weight (kg)',
            hintText: 'Enter your weight in kilograms',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your weight';
            }
            final weight = int.tryParse(value);
            if (weight == null || weight < 30 || weight > 200) {
              return 'Please enter a valid weight between 30-200 kg';
            }
            return null;
          },
          autofocus: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, int.parse(_weightController.text));
            }
          },
          child: const Text('Continue'),
        ),
      ],
    );
  }
}