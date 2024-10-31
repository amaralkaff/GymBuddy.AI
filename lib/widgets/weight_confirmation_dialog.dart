// lib/widgets/weight_confirmation_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workout_ai/models/weight_manager.dart';

class WeightConfirmationDialog extends StatefulWidget {
  final int currentWeight;

  const WeightConfirmationDialog({
    super.key,
    required this.currentWeight,
  });

  @override
  State<WeightConfirmationDialog> createState() => _WeightConfirmationDialogState();
}

class _WeightConfirmationDialogState extends State<WeightConfirmationDialog> {
  late TextEditingController _weightController;
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

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

  Future<void> _submitWeight() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final weight = int.parse(_weightController.text);
      context.read<WeightManager>().updateWeight(weight);
      
      if (!mounted) return;
      Navigator.of(context).pop(weight);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating weight: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
              enabled: !_isSubmitting,
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
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitWeight,
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Confirm'),
        ),
      ],
    );
  }
}