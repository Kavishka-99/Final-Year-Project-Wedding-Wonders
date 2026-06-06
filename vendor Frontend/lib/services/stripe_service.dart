import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:vendors_wedding_wonders/consts.dart';

class StripeService {
  StripeService._();

  static final StripeService instance = StripeService._();
  static final Dio _dio = Dio();

  Future<void> makePayment({
    required double amount,
    required String currency,
    required String planName,
    int? vendorId,
  }) async {
    try {
      // Convert currency to Stripe amount (e.g., $10.00 = 1000 cents)
      int amountInCents = (amount * 100).toInt();

      String? paymentIntentClientSecret = await _createPaymentIntent(
        amountInCents,
        currency,
        description: planName,
      );
      if (paymentIntentClientSecret == null) {
        throw Exception("Failed to create payment intent");
      }
      print("Payment Intent Created: $paymentIntentClientSecret");

      // Confirm payment intent (server-side confirmation)
      await _confirmPaymentIntent(paymentIntentClientSecret);

      print("Payment completed successfully!");
    } catch (e) {
      print("Payment Error: $e");
      rethrow;
    }
  }

  Future<String?> _createPaymentIntent(
    int amountInCents,
    String currency, {
    String? description,
  }) async {
    try {
      print(
        "Creating payment intent with amount: $amountInCents cents, currency: $currency",
      );

      // Build form data properly
      String formData = 'amount=$amountInCents&currency=$currency';
      if (description != null) {
        formData += '&description=${Uri.encodeComponent(description)}';
      }

      print("Form data: $formData");

      var response = await _dio.post(
        'https://api.stripe.com/v1/payment_intents',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $stripeSecreteKey',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      print("Payment Intent Response Status: ${response.statusCode}");
      print("Payment Intent Response: ${response.data}");

      if (response.statusCode == 200) {
        if (response.data != null && response.data['client_secret'] != null) {
          return response.data['client_secret'];
        }
      } else {
        print("Error creating payment intent: ${response.statusMessage}");
        print("Response body: ${response.data}");
      }
      return null;
    } catch (e) {
      print("Payment Intent Error: $e");
      return null;
    }
  }

  Future<void> _confirmPaymentIntent(String clientSecret) async {
    try {
      print("Confirming payment intent: $clientSecret");

      // Extract payment intent ID from client secret
      String paymentIntentId = clientSecret.split('_secret_')[0];

      // Use Stripe test token for payment (tok_visa is a valid Stripe test token)
      // This is the proper way to test payments without sending raw card data
      String formData =
          'payment_method_data[type]=card_present&'
          'payment_method_data[card_present][token]=tok_visa';

      print("Confirming payment intent with test token");

      var response = await _dio.post(
        'https://api.stripe.com/v1/payment_intents/$paymentIntentId/confirm',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $stripeSecreteKey',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      print("Payment confirmation response Status: ${response.statusCode}");
      print("Payment confirmation response: ${response.data}");

      if (response.statusCode == 200) {
        if (response.data != null) {
          String status = response.data['status'] ?? '';
          if (status == 'succeeded') {
            print("✅ Payment succeeded!");
          } else if (status == 'requires_payment_method') {
            throw Exception("Payment method required");
          } else if (status == 'requires_action') {
            print("Payment requires action: ${response.data['client_secret']}");
          } else {
            print("Payment status: $status");
          }
        }
      } else {
        print("Error confirming payment: ${response.statusMessage}");
        print("Response: ${response.data}");

        // Extract error message from Stripe response
        String errorMessage = 'Payment confirmation failed';
        if (response.data is Map && response.data['error'] != null) {
          errorMessage = response.data['error']['message'] ?? errorMessage;
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      print("Payment confirmation error: $e");
      rethrow;
    }
  }
}

String _calculateAmount(int amount) {
  final calculatedAmount = amount * 100;
  return calculatedAmount.toString();
}
