class ReportModel {
  final int? id;
  final int userId;
  final String type;
  final String description;
  final String driverName;
  final DateTime createdAt;

  ReportModel({
    this.id,
    required this.userId,
    required this.type,
    required this.description,
    required this.driverName,
    required this.createdAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'],
      userId: json['userId'],
      type: json['type'],
      description: json['description'],
      driverName: json['driverName'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'description': description,
      'driverName': driverName,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
