class ShipmentModel {
  final int id;
  final int userId;
  final String destiny;
  final String description;
  final DateTime createdAt;
  final String status;
  final String driverName;

  ShipmentModel({
    required this.id,
    required this.userId,
    required this.destiny,
    required this.description,
    required this.createdAt,
    required this.status,
    required this.driverName,
  });

  factory ShipmentModel.fromJson(Map<String, dynamic> json) {
    return ShipmentModel(
      id: json['id'],
      userId: json['userId'],
      destiny: json['destiny'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      status: json['status'],
      driverName: json['driverName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'destiny': destiny,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'driverName': driverName,
    };
  }
}
