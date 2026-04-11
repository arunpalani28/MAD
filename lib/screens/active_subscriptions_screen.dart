import 'package:flutter/material.dart';
import 'package:milk_delivery_assist/models/ActiveSubscription.dart';
import 'package:milk_delivery_assist/screens/SubscriptionCalendarScreen.dart';
import 'package:milk_delivery_assist/services/subscription_api.dart';

class ActiveSubscriptionsScreen extends StatefulWidget {
  const ActiveSubscriptionsScreen({super.key});

  @override
  State<ActiveSubscriptionsScreen> createState() =>
      _ActiveSubscriptionsScreenState();
}

class _ActiveSubscriptionsScreenState
    extends State<ActiveSubscriptionsScreen> {
  bool _isLoading = true;
  List<ActiveSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _fetchSubscriptions();
  }

  Future<void> _fetchSubscriptions() async {
    final data = await SubscriptionApi.fetchActiveSubscriptions();

    setState(() {
      _subscriptions = data ?? [];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Active Subscriptions",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade700,
         elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context), 
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20)
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _subscriptions.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _subscriptions.length,
                  itemBuilder: (_, index) {
                    final sub = _subscriptions[index];
                    return _buildSubscriptionCard(sub);
                  },
                ),
    );
  }

  // ---------------- UI ----------------

  Widget _buildSubscriptionCard(ActiveSubscription sub) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          sub.productName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("₹ ${sub.pricePerDay.toStringAsFixed(2)} / day"),
              const SizedBox(height: 4),
              Text("Status: ${sub.status}",
                  style: const TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SubscriptionCalendarScreen(
                subscriptionId: sub.id,
                productName: sub.productName,
                pricePerDay: sub.pricePerDay,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.subscriptions,
              size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            "No Active Subscriptions",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Start a subscription to manage deliveries",
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
