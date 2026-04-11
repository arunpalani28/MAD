import 'package:flutter/material.dart';
import 'package:milk_delivery_assist/screens/active_subscriptions_screen.dart';
import 'package:milk_delivery_assist/screens/cart_screen.dart';
import 'package:milk_delivery_assist/screens/email_login_widget.dart';
import 'package:milk_delivery_assist/screens/home_screen.dart';
import 'package:milk_delivery_assist/screens/profile_screen.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    final cartCount = context.watch<AppState>().cart.length;

    if (user == null) return const EmailLoginWidget();

    final screens = [
      const HomeScreen(),
      // const SubscriptionCalendarScreen(
      //   subscriptionId:0,
      //   productName: "Milk",
      //   pricePerDay: 24.0,
      // ),
      const ActiveSubscriptionsScreen(),
      const CartScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.white,
        elevation: 10,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Colors.blue),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month, color: Colors.blue),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Stack(
              children: [
                const Icon(Icons.shopping_cart_outlined),
                if (cartCount > 0)
                  Positioned(
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '$cartCount',
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            selectedIcon: Stack(
              children: [
                const Icon(Icons.shopping_cart, color: Colors.blue),
                if (cartCount > 0)
                  Positioned(
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '$cartCount',
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Cart',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Colors.blue),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
