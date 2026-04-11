class ActiveSubscription {
  final int id;
  final String productName;
  final double pricePerDay;
  final String status;

  ActiveSubscription({
    required this.id,
    required this.productName,
    required this.pricePerDay,
    required this.status,
  });

  factory ActiveSubscription.fromJson(Map<String, dynamic> json) {
    return ActiveSubscription(
      id: json['id'],
      productName: json['productName'],
      pricePerDay: (json['pricePerDay'] as num).toDouble(),
      status: json['status'],
    );
  }
}
