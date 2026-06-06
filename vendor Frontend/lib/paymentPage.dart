import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vendors_wedding_wonders/services/stripe_service.dart';

class PaymentPage extends StatefulWidget {
  final String planName;
  final double price;
  final int vendorId;

  const PaymentPage({
    super.key,
    required this.planName,
    required this.price,
    required this.vendorId,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _isLoading = false;

  Future<void> _handlePayment() async {
    setState(() => _isLoading = true);
    try {
      // Process payment using Stripe
      await StripeService.instance.makePayment(
        amount: widget.price,
        currency: 'LKR',
        planName: widget.planName,
        vendorId: widget.vendorId,
      );

      // Save subscription in backend after successful payment
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/stripe/save-subscription'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'vendor_id': widget.vendorId,
          'plan_name': widget.planName,
          'price': widget.price,
          'currency': 'LKR',
        }),
      );

      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Subscription ${widget.planName} activated!'),
              backgroundColor: Colors.green,
            ),
          );
          // Go back to previous screen
          Navigator.pop(context);
        } else {
          throw Exception('Failed to save subscription');
        }
      }
    } catch (e) {
      print('Payment Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pay for ${widget.planName}'),
        backgroundColor: Colors.redAccent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.planName,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            Text(
              'LKR ${widget.price.toStringAsFixed(2)}',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.redAccent),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _handlePayment,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.payment),
              label: Text(_isLoading ? 'Processing...' : 'Pay Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your payment is secured by Stripe',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
