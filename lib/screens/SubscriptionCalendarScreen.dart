import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:milk_delivery_assist/screens/main_wrapper.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:milk_delivery_assist/services/subscription_api.dart';

class SubscriptionCalendarScreen extends StatefulWidget {
  final String productName;
  final int subscriptionId;
  final double pricePerDay;

  const SubscriptionCalendarScreen({
    super.key,
    required this.productName,
    this.subscriptionId = 0,
    this.pricePerDay = 24,
  });

  @override
  State<SubscriptionCalendarScreen> createState() => _SubscriptionCalendarScreenState();
}

class _SubscriptionCalendarScreenState extends State<SubscriptionCalendarScreen> {
  // --- Brand Colors ---
  final Color primaryBlue = const Color(0xFF2D62ED);
  final Color accentBlue = const Color(0xFFE3F2FD);
  final Color successGreen = const Color(0xFF4CAF50);
  final Color errorRed = const Color(0xFFE53935);
  final Color surfaceColor = const Color(0xFFF5F7F9);

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<DateTime> bookedDays = [];
  List<DateTime> cancelledDays = [];
  Map<String, int> productQuantity = {};

  DateTime subscriptionStart = DateTime.now();
  DateTime subscriptionEnd = DateTime.now().add(const Duration(days: 30));

  bool _isLoading = true;
  bool _isProcessing = false;
  int _activeSubscriptionId = 0;

  @override
  void initState() {
    super.initState();
    _activeSubscriptionId = widget.subscriptionId;
    if (_activeSubscriptionId == 0) {
      _setupDefaultMonthlySubscription();
    } else {
      _fetchCalendarData();
    }
  }

  // ---------------- LOGIC METHODS ----------------

  void _setupDefaultMonthlySubscription() {
    final now = DateTime.now();
    subscriptionStart = DateTime(now.year, now.month, now.day);
    subscriptionEnd = subscriptionStart.add(const Duration(days: 30));
    bookedDays = List.generate(31, (i) => subscriptionStart.add(Duration(days: i)));
    _focusedDay = subscriptionStart;
    _selectedDay = _getInitialSelectedDay();
    setState(() => _isLoading = false);
  }

  DateTime? _getInitialSelectedDay() {
    DateTime day = DateTime.now().add(const Duration(days: 1));
    while (!day.isAfter(subscriptionEnd)) {
      if (_canEdit(day)) return day;
      day = day.add(const Duration(days: 1));
    }
    return null;
  }

  Future<void> _fetchCalendarData() async {
    final response = await SubscriptionApi.fetchCalendar(_activeSubscriptionId);
    if (response == null) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() {
      subscriptionStart = response.startDate;
      subscriptionEnd = response.endDate;
      bookedDays.clear();
      cancelledDays.clear();
      productQuantity.clear();

      for (var day in response.days) {
        final date = day.dateTime;
        final key = DateFormat('yyyy-MM-dd').format(date);
        if (day.status.toUpperCase() == "BOOKED") bookedDays.add(date);
        if (day.status.toUpperCase() == "CANCELLED") cancelledDays.add(date);
        if (day.quantity > 1) productQuantity[key] = day.quantity;
      }
      _focusedDay = subscriptionStart;
      _isLoading = false;
    });
  }

  bool _canEdit(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (day.isBefore(today) || isSameDay(day, today)) return false;
    if (isSameDay(day, today.add(const Duration(days: 1))) && now.hour >= 17) return false;
    return true;
  }

  void _toggleBooking(DateTime day) async {
    if (!_canEdit(day)) return;
    final key = DateFormat('yyyy-MM-dd').format(day);
    if (_activeSubscriptionId != 0) {
      final success = await SubscriptionApi.updateDay(_activeSubscriptionId, key, "BOOKED", 1, widget.productName, widget.pricePerDay);
      if (!success) return;
    }
    setState(() {
      bookedDays.add(day);
      cancelledDays.removeWhere((d) => isSameDay(d, day));
    });
  }

  void _toggleCancel(DateTime day) async {
    if (!_canEdit(day)) return;
    final key = DateFormat('yyyy-MM-dd').format(day);
    if (_activeSubscriptionId != 0) {
      final success = await SubscriptionApi.updateDay(_activeSubscriptionId, key, "CANCELLED", 1, widget.productName, widget.pricePerDay);
      if (!success) return;
    }
    setState(() {
      cancelledDays.add(day);
      bookedDays.removeWhere((d) => isSameDay(d, day));
      productQuantity.remove(key);
    });
  }

  void _addProductQuantity(DateTime day) async {
    final key = DateFormat('yyyy-MM-dd').format(day);
    int current = productQuantity[key] ?? 1;
    final controller = TextEditingController(text: "$current");
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Update Quantity"),
        content: TextField(
          controller: controller, 
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Bottles"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, shape: const StadiumBorder()),
            child: const Text("Save"),
            onPressed: () async {
              int val = int.tryParse(controller.text) ?? 1;
              if (_activeSubscriptionId != 0) {
                await SubscriptionApi.updateDay(_activeSubscriptionId, key, "BOOKED", val, widget.productName, widget.pricePerDay);
              }
              setState(() {
                if (val <= 1) productQuantity.remove(key);
                else productQuantity[key] = val;
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // --- Confirmation Popup ---
  void _showConfirmDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Confirm Subscription"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Product: ${widget.productName}"),
              const SizedBox(height: 8),
              Text("Total Amount: ₹${totalAmount.toStringAsFixed(2)}"),
              const SizedBox(height: 12),
              const Text("Do you want to activate this delivery plan?"),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Edit")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
              onPressed: () {
                Navigator.pop(context);
                _createSubscription();
              },
              child: const Text("Activate Now"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createSubscription() async {
    setState(() => _isProcessing = true);

    final List<Map<String, dynamic>> daysPayload = bookedDays.map((day) {
      final key = DateFormat('yyyy-MM-dd').format(day);
      return {"date": key, "status": "BOOKED", "quantity": productQuantity[key] ?? 1};
    }).toList();

    final dynamic response = await SubscriptionApi.createSubscription(
      startDate: subscriptionStart,
      endDate: subscriptionEnd,
      productName: widget.productName,
      pricePerDay: widget.pricePerDay,
      days: daysPayload,
    );

    setState(() => _isProcessing = false);

    // Handling response: {"subscriptionId": 53}
     if (response != null) {
      _activeSubscriptionId = response;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Subscription Started!"), backgroundColor: Colors.green),
      );
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const MainWrapper()), // Replace with your Home class name
  
);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error activating plan"), backgroundColor: Colors.red),
      );
    }
  }

  double get totalAmount {
    double total = bookedDays.length * widget.pricePerDay;
    productQuantity.forEach((key, qty) {
      if (qty > 1) total += (qty - 1) * widget.pricePerDay;
    });
    return total;
  }

  // ---------------- UI BUILDER ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        title: Column(
          children: [
            Text(widget.productName, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18)),
            const Text("Monthly Plan", style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context), 
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20)
        ),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
      ),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator(color: primaryBlue)) 
          : Column(
              children: [
                _buildHeaderStats(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildCalendarCard(),
                        const SizedBox(height: 20),
                        if (_selectedDay != null) _buildActionPanel(_selectedDay!),
                        const SizedBox(height: 24),
                        _buildPriceSummary(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
                if (_activeSubscriptionId == 0) _buildStickyCreateButton(),
              ],
            ),
    );
  }

  Widget _buildHeaderStats() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Row(
        children: [
          _statCard("Deliveries", bookedDays.length.toString(), successGreen, Icons.local_shipping),
          const SizedBox(width: 12),
          _statCard("Cancelled", cancelledDays.length.toString(), errorRed, Icons.block),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color bgColor, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor, 
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: TableCalendar(
        firstDay: subscriptionStart,
        lastDay: subscriptionEnd,
        focusedDay: _focusedDay,
        selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
        onDaySelected: (s, f) => setState(() { _selectedDay = s; _focusedDay = f; }),
        headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) => _calendarCell(day),
          todayBuilder: (context, day, focusedDay) => _calendarCell(day, isToday: true),
          selectedBuilder: (context, day, focusedDay) => _calendarCell(day, isSelected: true),
        ),
      ),
    );
  }

  Widget _calendarCell(DateTime day, {bool isToday = false, bool isSelected = false}) {
    final isBooked = bookedDays.any((d) => isSameDay(d, day));
    final isCancelled = cancelledDays.any((d) => isSameDay(d, day));
    final qty = productQuantity[DateFormat('yyyy-MM-dd').format(day)] ?? 1;

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isSelected ? accentBlue : Colors.transparent,
        border: isSelected ? Border.all(color: primaryBlue, width: 2) : (isToday ? Border.all(color: primaryBlue.withOpacity(0.2)) : null),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isBooked) Icon(Icons.water_drop_rounded, color: successGreen.withOpacity(0.12), size: 30),
          Text('${day.day}', style: TextStyle(fontWeight: (isBooked || isCancelled) ? FontWeight.bold : FontWeight.normal, color: isBooked ? successGreen : (isCancelled ? errorRed : Colors.black87))),
          if (qty > 1 && isBooked)
            Positioned(bottom: 4, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)),
              child: Text('x$qty', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
            )),
        ],
      ),
    );
  }

  Widget _buildActionPanel(DateTime day) {
    bool canEdit = _canEdit(day);
    bool isBooked = bookedDays.any((d) => isSameDay(d, day));
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.withOpacity(0.1))),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(DateFormat('EEEE, dd MMM').format(day), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              if (isBooked) const Icon(Icons.check_circle, color: Colors.green, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          if (canEdit) Row(
            children: [
              Expanded(child: ElevatedButton.icon(
                onPressed: () => isBooked ? _toggleCancel(day) : _toggleBooking(day),
                icon: Icon(isBooked ? Icons.close : Icons.add, color: Colors.white, size: 18),
                label: Text(isBooked ? "Cancel" : "Deliver"),
                style: ElevatedButton.styleFrom(backgroundColor: isBooked ? errorRed : successGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              )),
              if (isBooked) ...[
                const SizedBox(width: 10),
                Expanded(child: OutlinedButton.icon(
                  onPressed: () => _addProductQuantity(day),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text("Qty"),
                  style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                )),
              ]
            ],
          ) else const Text("Window closed", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildPriceSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primaryBlue, const Color(0xFF1A46C7)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Total Bill Estimate", style: TextStyle(color: Colors.white, fontSize: 16)),
          Text("₹${totalAmount.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildStickyCreateButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
      color: Colors.white,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _showConfirmDialog,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.black87, minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        child: _isProcessing ? const CircularProgressIndicator(color: Colors.white) : const Text("ACTIVATE SUBSCRIPTION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}