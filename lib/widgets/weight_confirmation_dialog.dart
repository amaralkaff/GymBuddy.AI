// lib/widgets/weight_confirmation_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WeightConfirmationDialog extends StatefulWidget {
  final int currentWeight;

  const WeightConfirmationDialog({
    Key? key,
    required this.currentWeight,
  }) : super(key: key);

  @override
  State<WeightConfirmationDialog> createState() => _WeightConfirmationDialogState();
}

class _WeightConfirmationDialogState extends State<WeightConfirmationDialog> {
  late TextEditingController _weightController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(text: widget.currentWeight.toString());
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirm Your Current Weight'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please confirm or update your current weight:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your weight';
                }
                final weight = int.tryParse(value);
                if (weight == null || weight < 30 || weight > 200) {
                  return 'Please enter a valid weight (30-200 kg)';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(int.parse(_weightController.text));
            }
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}