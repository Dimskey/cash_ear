class SaleModel {
  final String id;
  final String userId;
  final List<SaleItem> items;
  final double total;
  final double profit;
  final DateTime createdAt;
  final String paymentMethod;

  SaleModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.total,
    required this.profit,
    required this.createdAt,
    required this.paymentMethod,
  });

  factory SaleModel.fromJson(Map<String, dynamic> json) {
    return SaleModel(
      id: json['id'],
      userId: json['userId'],
      items: (json['items'] as List)
          .map((item) => SaleItem.fromJson(item))
          .toList(),
      total: json['total'].toDouble(),
      profit: json['profit'].toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      paymentMethod: json['paymentMethod'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'total': total,
      'profit': profit,
      'createdAt': createdAt.toIso8601String(),
      'paymentMethod': paymentMethod,
    };
  }
}

class SaleItem {
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final double cost;

  SaleItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.cost,
  });

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      productId: json['productId'],
      productName: json['productName'],
      quantity: json['quantity'],
      price: json['price'].toDouble(),
      cost: json['cost'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'price': price,
      'cost': cost,
    };
  }

  double get subtotal => quantity * price;
  double get itemProfit => (price - cost) * quantity;
}