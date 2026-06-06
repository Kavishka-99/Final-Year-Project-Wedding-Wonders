import 'package:flutter/material.dart';
import 'package:vendors_wedding_wonders/paymentPage.dart';

class PricingPlanScreen extends StatelessWidget {
  const PricingPlanScreen({super.key, required int vendorId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Plans'),
        backgroundColor: Colors.redAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              buildAnimatedPlanCard(
                context,
                planName: 'Basic',
                price: 'LKR 0 / month',
                features: ['Limited Listings', 'Basic Support', 'No Promotion'],
                color: Colors.grey.shade200,
                isMostPopular: false,
                delay: 0,
              ),
              buildAnimatedPlanCard(
                context,
                planName: 'Standard',
                price: 'LKR 999 / month',
                features: [
                  'Standard Listings',
                  'Email Support',
                  'Moderate Promotion',
                ],
                color: Colors.blue.shade100,
                isMostPopular: true,
                delay: 200,
              ),
              buildAnimatedPlanCard(
                context,
                planName: 'Premium',
                price: 'LKR 1999 / month',
                features: [
                  'Unlimited Listings',
                  'Priority Support',
                  'Full Promotion',
                ],
                color: Colors.amber.shade100,
                isMostPopular: false,
                delay: 400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildAnimatedPlanCard(
    BuildContext context, {
    required String planName,
    required String price,
    required List<String> features,
    required Color color,
    required bool isMostPopular,
    required int delay,
  }) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.9, end: 1.0),
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 280,
            child: Card(
              color: color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      planName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(price, style: const TextStyle(fontSize: 18)),
                    const Divider(),
                    ...features
                        .map(
                          (feature) => Row(
                            children: [
                              const Icon(
                                Icons.check,
                                size: 18,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(feature)),
                            ],
                          ),
                        )
                        .toList(),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => PaymentPage(
                                    planName: planName,
                                    price: double.parse(
                                      price.replaceAll(RegExp(r'[^\d.]'), ''),
                                    ), // extract numeric
                                    vendorId:
                                        1, // Replace with actual logged-in vendor ID
                                  ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                        ),
                        child: const Text('Choose Plan'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isMostPopular)
            Positioned(
              top: -10,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'MOST POPULAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
