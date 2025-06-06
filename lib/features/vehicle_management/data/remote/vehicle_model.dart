class VehicleModel {
  final int id;
  final int userId;
  final String licensePlate;
  final String model;
  final int engine;
  final int fuel;
  final int tires;
  final int electricalSystem;
  final int transmissionTemperature;
  final String driverName;
  final String vehicleImage; // Codificación base64
  final String color;
  final DateTime lastTechnicalInspectionDate;
  final DateTime createdAt;

  VehicleModel({
    required this.id,
    required this.userId,
    required this.licensePlate,
    required this.model,
    required this.engine,
    required this.fuel,
    required this.tires,
    required this.electricalSystem,
    required this.transmissionTemperature,
    required this.driverName,
    required this.vehicleImage,
    required this.color,
    required this.lastTechnicalInspectionDate,
    required this.createdAt,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'],
      userId: json['userId'],
      licensePlate: json['licensePlate'],
      model: json['model'],
      engine: json['engine'],
      fuel: json['fuel'],
      tires: json['tires'],
      electricalSystem: json['electricalSystem'],
      transmissionTemperature: json['transmissionTemperature'],
      driverName: json['driverName'],
      vehicleImage: json['vehicleImage'],
      color: json['color'],
      lastTechnicalInspectionDate: DateTime.parse(json['lastTechnicalInspectionDate']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'licensePlate': licensePlate,
      'model': model,
      'engine': engine,
      'fuel': fuel,
      'tires': tires,
      'electricalSystem': electricalSystem,
      'transmissionTemperature': transmissionTemperature,
      'driverName': driverName,
      'vehicleImage': vehicleImage,
      'color': color,
      'lastTechnicalInspectionDate': lastTechnicalInspectionDate.toIso8601String(),
    };
  }

}
