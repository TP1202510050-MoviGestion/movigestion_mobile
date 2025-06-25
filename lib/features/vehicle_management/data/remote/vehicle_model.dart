// lib/features/vehicle_management/data/remote/vehicle_model.dart

/*────────────────────────────  Clases auxiliares (siguen disponibles) ────────────────────────────*/
class Location {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  Location({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  factory Location.fromJson(Map<String, dynamic> json) => Location(
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    timestamp: DateTime.parse(json['timestamp'] as String),
  );

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'timestamp': timestamp.toIso8601String(),
  };
}

class Speed {
  final double kmh;
  final DateTime timestamp;

  Speed({
    required this.kmh,
    required this.timestamp,
  });

  factory Speed.fromJson(Map<String, dynamic> json) => Speed(
    kmh: (json['kmh'] as num).toDouble(),
    timestamp: DateTime.parse(json['timestamp'] as String),
  );

  Map<String, dynamic> toJson() => {
    'kmh': kmh,
    'timestamp': timestamp.toIso8601String(),
  };
}

/*────────────────────────────  Modelo principal ────────────────────────────*/
class VehicleModel {
  /*────────  Identidad y datos básicos ────────*/
  final int? id;
  final String licensePlate;
  final String brand;
  final String model;
  final int year;
  final String color;
  final int seatingCapacity;
  final DateTime lastTechnicalInspectionDate;

  /*────────  Sensores / estado ────────*/
  final String gpsSensorId;
  final String speedSensorId;
  final String status;
  final String driverName;
  final String companyName;
  final String companyRuc;
  final int?    assignedDriverId;
  final DateTime? assignedAt;

  /*────────  Multimedia y fechas ────────*/
  final String vehicleImage;
  final String documentSoat;
  final String documentVehicleOwnershipCard;
  final DateTime? dateToGoTheWorkshop;

  /*────────  Telemetría *reciente* (nuevos campos) ────────*/
  final double?    lastTemperature;
  final double?    lastHumidity;
  final double?    lastLatitude;
  final double?    lastLongitude;
  final double?    lastAltitudeMeters;
  final double?    lastKmh;
  final DateTime?  lastTelemetryTimestamp;

  /*────────  Versiones antiguas (opcional) ────────*/
  final Location? lastLocation;   // sigue disponible si tu UI lo usa
  final Speed?    lastSpeed;

  VehicleModel({
    /* básicos */
    this.id,
    required this.licensePlate,
    required this.brand,
    required this.model,
    required this.year,
    required this.color,
    required this.seatingCapacity,
    required this.lastTechnicalInspectionDate,
    /* sensores / estado */
    required this.gpsSensorId,
    required this.speedSensorId,
    required this.status,
    required this.driverName,
    required this.companyName,
    required this.companyRuc,
    this.assignedDriverId,
    this.assignedAt,
    /* multimedia */
    required this.vehicleImage,
    required this.documentSoat,
    required this.documentVehicleOwnershipCard,
    this.dateToGoTheWorkshop,
    /* telemetría nueva */
    this.lastTemperature,
    this.lastHumidity,
    this.lastLatitude,
    this.lastLongitude,
    this.lastAltitudeMeters,
    this.lastKmh,
    this.lastTelemetryTimestamp,
    /* telemetría antigua */
    this.lastLocation,
    this.lastSpeed,
  });

  /*────────────────────────────  copyWith  ────────────────────────────*/
  VehicleModel copyWith({
    int?       id,
    String?    licensePlate,
    String?    brand,
    String?    model,
    int?       year,
    String?    color,
    int?       seatingCapacity,
    DateTime?  lastTechnicalInspectionDate,
    String?    gpsSensorId,
    String?    speedSensorId,
    String?    status,
    String?    driverName,
    String?    companyName,
    String?    companyRuc,
    int?       assignedDriverId,
    DateTime?  assignedAt,
    String?    vehicleImage,
    String?    documentSoat,
    String?    documentVehicleOwnershipCard,
    DateTime?  dateToGoTheWorkshop,
    /* telemetría nueva */
    double?    lastTemperature,
    double?    lastHumidity,
    double?    lastLatitude,
    double?    lastLongitude,
    double?    lastAltitudeMeters,
    double?    lastKmh,
    DateTime?  lastTelemetryTimestamp,
    /* telemetría antigua */
    Location?  lastLocation,
    Speed?     lastSpeed,
  }) {
    return VehicleModel(
      id:                          id                          ?? this.id,
      licensePlate:                licensePlate                ?? this.licensePlate,
      brand:                       brand                       ?? this.brand,
      model:                       model                       ?? this.model,
      year:                        year                        ?? this.year,
      color:                       color                       ?? this.color,
      seatingCapacity:             seatingCapacity             ?? this.seatingCapacity,
      lastTechnicalInspectionDate: lastTechnicalInspectionDate ?? this.lastTechnicalInspectionDate,
      gpsSensorId:                 gpsSensorId                 ?? this.gpsSensorId,
      speedSensorId:               speedSensorId               ?? this.speedSensorId,
      status:                      status                      ?? this.status,
      driverName:                  driverName                  ?? this.driverName,
      companyName:                 companyName                 ?? this.companyName,
      companyRuc:                  companyRuc                  ?? this.companyRuc,
      assignedDriverId:            assignedDriverId            ?? this.assignedDriverId,
      assignedAt:                  assignedAt                  ?? this.assignedAt,
      vehicleImage:                vehicleImage                ?? this.vehicleImage,
      documentSoat:                documentSoat                ?? this.documentSoat,
      documentVehicleOwnershipCard:documentVehicleOwnershipCard?? this.documentVehicleOwnershipCard,
      dateToGoTheWorkshop:         dateToGoTheWorkshop         ?? this.dateToGoTheWorkshop,
      /* telemetría nueva */
      lastTemperature:             lastTemperature             ?? this.lastTemperature,
      lastHumidity:                lastHumidity                ?? this.lastHumidity,
      lastLatitude:                lastLatitude                ?? this.lastLatitude,
      lastLongitude:               lastLongitude               ?? this.lastLongitude,
      lastAltitudeMeters:          lastAltitudeMeters          ?? this.lastAltitudeMeters,
      lastKmh:                     lastKmh                     ?? this.lastKmh,
      lastTelemetryTimestamp:      lastTelemetryTimestamp      ?? this.lastTelemetryTimestamp,
      /* telemetría antigua */
      lastLocation:                lastLocation                ?? this.lastLocation,
      lastSpeed:                   lastSpeed                   ?? this.lastSpeed,
    );
  }

  /*────────────────────────────  deserialización  ────────────────────────────*/
  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] as int?,
      licensePlate: json['licensePlate'] as String,
      brand: json['brand'] as String,
      model: json['model'] as String,
      year: json['year'] as int,
      color: json['color'] as String,
      seatingCapacity: json['seatingCapacity'] as int,
      lastTechnicalInspectionDate:
      DateTime.parse(json['lastTechnicalInspectionDate'] as String),
      gpsSensorId: json['gpsSensorId'] as String,
      speedSensorId: json['speedSensorId'] as String,
      status: json['status'] as String,
      driverName: json['driverName'] as String,
      companyName: json['companyName'] as String? ?? '',
      companyRuc:  json['companyRuc']  as String? ?? '',
      assignedDriverId: json['assignedDriverId'] as int?,
      assignedAt: json['assignedAt'] != null
          ? DateTime.parse(json['assignedAt'] as String)
          : null,
      vehicleImage: json['vehicleImage'] as String,
      documentSoat: json['documentSoat'] as String,
      documentVehicleOwnershipCard:
      json['documentVehicleOwnershipCard'] as String,
      dateToGoTheWorkshop: json['dateToGoTheWorkshop'] != null
          ? DateTime.parse(json['dateToGoTheWorkshop'] as String)
          : null,
      /* telemetría nueva */
      lastTemperature:      json['lastTemperature']      != null ? (json['lastTemperature']      as num).toDouble() : null,
      lastHumidity:         json['lastHumidity']         != null ? (json['lastHumidity']         as num).toDouble() : null,
      lastLatitude:         json['lastLatitude']         != null ? (json['lastLatitude']         as num).toDouble() : null,
      lastLongitude:        json['lastLongitude']        != null ? (json['lastLongitude']        as num).toDouble() : null,
      lastAltitudeMeters:   json['lastAltitudeMeters']   != null ? (json['lastAltitudeMeters']   as num).toDouble() : null,
      lastKmh:              json['lastKmh']              != null ? (json['lastKmh']              as num).toDouble() : null,
      lastTelemetryTimestamp: json['lastTelemetryTimestamp'] != null
          ? DateTime.parse(json['lastTelemetryTimestamp'] as String)
          : null,
      /* opcional: si el backend sigue enviando objetos anidados */
      lastLocation: json['lastLocation'] != null
          ? Location.fromJson(json['lastLocation'] as Map<String, dynamic>)
          : null,
      lastSpeed: json['lastSpeed'] != null
          ? Speed.fromJson(json['lastSpeed'] as Map<String, dynamic>)
          : null,
    );
  }

  /*────────────────────────────  serialización  ────────────────────────────*/
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'licensePlate': licensePlate,
      'brand': brand,
      'model': model,
      'year': year,
      'color': color,
      'seatingCapacity': seatingCapacity,
      'lastTechnicalInspectionDate':
      lastTechnicalInspectionDate.toIso8601String(),
      'gpsSensorId': gpsSensorId,
      'speedSensorId': speedSensorId,
      'status': status,
      'driverName': driverName,
      'companyName': companyName,
      'companyRuc': companyRuc,
      'assignedDriverId': assignedDriverId,
      'assignedAt': assignedAt?.toIso8601String(),
      'vehicleImage': vehicleImage,
      'documentSoat': documentSoat,
      'documentVehicleOwnershipCard': documentVehicleOwnershipCard,
      'dateToGoTheWorkshop': dateToGoTheWorkshop?.toIso8601String(),
      /* telemetría nueva */
      'lastTemperature':      lastTemperature,
      'lastHumidity':         lastHumidity,
      'lastLatitude':         lastLatitude,
      'lastLongitude':        lastLongitude,
      'lastAltitudeMeters':   lastAltitudeMeters,
      'lastKmh':              lastKmh,
      'lastTelemetryTimestamp': lastTelemetryTimestamp?.toIso8601String(),
      /* telemetría antigua (si la sigues usando) */
      'lastLocation': lastLocation?.toJson(),
      'lastSpeed':    lastSpeed?.toJson(),
    };
    if (id != null) map['id'] = id;
    return map;
  }
}
