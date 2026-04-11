import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:milk_delivery_assist/screens/SubscriptionCalendarScreen.dart';
import 'package:milk_delivery_assist/services/subscription_api.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;

  const ProductDetailsScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _quantity = 1;
  bool _isSubscription = false;
  String _frequency = 'Daily';
  
  // New variables for API logic
  bool _isLoadingStatus = true;
  bool _hasExistingSubscription = false;

  @override
  void initState() {
    super.initState();
    _checkActiveSubscription();
  }

  Future<void> _checkActiveSubscription() async {
    try {
      // Logic: Call your Spring Boot API here
      // Example: GET /api/subscriptions/check?userId=XYZ&productId=ABC
      bool isActive = await SubscriptionApi.checkUserSubscription(widget.product.name);
      
      setState(() {
        _hasExistingSubscription = isActive;
        _isLoadingStatus = false;
        // If already subscribed, default the view to Subscription mode
        if (isActive) {
          _isSubscription = true;
          _frequency = 'Daily';
        }
      });
    } catch (e) {
      setState(() => _isLoadingStatus = false);
      debugPrint("Error fetching subscription: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: CachedNetworkImage(
                imageUrl: widget.product.imageUrl,
                fit: BoxFit.cover,
              ),
            ),
            leading: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.85),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              transform: Matrix4.translationValues(0, -20, 0),
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // -------- Title & Price --------
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.product.name,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        '₹${widget.product.price}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Per ${widget.product.unit}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),

                  const SizedBox(height: 24),

                  // -------- Description --------
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description,
                    style: TextStyle(color: Colors.grey[700], height: 1.5),
                  ),

                  const SizedBox(height: 32),

                  // -------- Purchase Type Toggle --------
                  if (widget.product.isSubscriptionAvailable) ...[
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _buildToggle(
                            label: 'One-time',
                            selected: !_isSubscription,
                            onTap: () => setState(() => _isSubscription = false),
                          ),
                          _buildToggle(
                            label: 'Subscribe',
                            selected: _isSubscription,
                            onTap: () => setState(() => _isSubscription = true),
                            selectedColor: AppTheme.primary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // -------- Frequency Logic --------
                  if (_isSubscription) ...[
                    const Text(
                      'Frequency',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    
                    if (_hasExistingSubscription)
                      // If already subscribed: Show read-only status
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade300)
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.orange, size: 20),
                            SizedBox(width: 8),
                            Text("Already Subscribed (Daily)", 
                                 style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    else
                      // If not subscribed: Show selectable options
                      Wrap(
                        spacing: 10,
                        children: ['Daily'].map((freq) {
                          final selected = _frequency == freq;
                          return ChoiceChip(
                            label: Text(freq),
                            selected: selected,
                            onSelected: (_) => setState(() => _frequency = freq),
                            selectedColor: AppTheme.primary.withOpacity(0.15),
                            labelStyle: TextStyle(
                              color: selected ? AppTheme.primary : Colors.black,
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 24),
                  ],

                  // -------- Quantity --------
                  Row(
                    children: [
                      const Text(
                        'Quantity',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                if (_quantity > 1) setState(() => _quantity--);
                              },
                            ),
                            Text(
                              '$_quantity',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => setState(() => _quantity++),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // ---------------- Bottom Sheet ----------------
      bottomSheet: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            )
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Price', style: TextStyle(color: Colors.grey)),
                  Text(
                    '₹${widget.product.price * _quantity}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),

              Expanded(
                child: ElevatedButton(
                  onPressed: (_isLoadingStatus || (_isSubscription && _hasExistingSubscription))
                      ? null // Disable if loading or if already subscribed
                      : () {
                          if (_isSubscription) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SubscriptionCalendarScreen(
                                  subscriptionId: 0,
                                  productName: widget.product.name,
                                  pricePerDay: widget.product.price.toDouble(),
                                ),
                              ),
                            );
                          } else {
                            context.read<AppState>().addToCart(
                                  widget.product,
                                  _quantity,
                                  false,
                                  'One-time',
                                );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Added to Cart'),
                                backgroundColor: AppTheme.success,
                              ),
                            );
                            Navigator.pop(context);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (_isSubscription && _hasExistingSubscription) 
                        ? Colors.grey 
                        : AppTheme.primary,
                  ),
                  child: _isLoadingStatus 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(
                        _isSubscription 
                          ? (_hasExistingSubscription ? 'Already Subscribed' : 'Start Subscription')
                          : 'Add to Cart',
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Helpers ----------------
  Widget _buildToggle({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Color selectedColor = Colors.white,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? selectedColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected 
                ? (selectedColor == Colors.white ? Colors.black : Colors.white) 
                : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}