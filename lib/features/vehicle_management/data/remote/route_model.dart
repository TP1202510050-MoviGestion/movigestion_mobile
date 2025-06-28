// lib/features/vehicle_management/data/remote/route_model.dart
import 'dart:convert';

class Waypoint {
  final int    order;
  final String name;
  final double latitude;
  final double longitude;

  Waypoint({
    required this.order,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  Waypoint copyWith({
    int? order,
    String? name,
    double? latitude,
    double? longitude,
  }) {
    return Waypoint(
      order: order ?? this.order,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  factory Waypoint.fromJson(Map<String, dynamic> j) => Waypoint(
    order     : j['order']     as int,
    name      : j['name']      as String,
    latitude  : (j['latitude']  as num).toDouble(),
    longitude : (j['longitude'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'order'    : order,
    'name'     : name,
    'latitude' : latitude,
    'longitude': longitude,
  };
}

class RouteModel {
  final int?    id;
  final String  type;
  final String  customer;
  final String  nameRoute;
  final String  status;
  final String  shift;

  final int?    driverId;
  final String? driverName;
  final int?    vehicleId;
  final String? vehiclePlate;

  final DateTime? departureTime;
  final DateTime? arrivalTime;

  final List<Waypoint> waypoints;

  final double? lastLatitude;
  final double? lastLongitude;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  final String companyName;
  final String companyRuc;

  RouteModel({
    this.id,
    required this.type,
    required this.customer,
    required this.nameRoute,
    required this.status,
    required this.shift,
    this.driverId,
    this.driverName,
    this.vehicleId,
    this.vehiclePlate,
    this.departureTime,
    this.arrivalTime,
    required this.waypoints,
    this.lastLatitude,
    this.lastLongitude,
    this.createdAt,
    this.updatedAt,
    required this.companyName,
    required this.companyRuc,
  });

  /* ------------------------------------------------------------------ */
  /*                               copyWith                             */
  /* ------------------------------------------------------------------ */
  RouteModel copyWith({
    int?       id,
    String?    type,
    String?    customer,
    String?    nameRoute,
    String?    status,
    String?    shift,
    int?       driverId,
    String?    driverName,
    int?       vehicleId,
    String?    vehiclePlate,
    DateTime?  departureTime,
    DateTime?  arrivalTime,
    List<Waypoint>? waypoints,
    double?    lastLatitude,
    double?    lastLongitude,
    DateTime?  createdAt,
    DateTime?  updatedAt,
    String?    companyName,
    String?    companyRuc,
  }) {
    return RouteModel(
      id            : id            ?? this.id,
      type          : type          ?? this.type,
      customer      : customer      ?? this.customer,
      nameRoute     : nameRoute     ?? this.nameRoute,
      status        : status        ?? this.status,
      shift         : shift         ?? this.shift,
      driverId      : driverId      ?? this.driverId,
      driverName    : driverName    ?? this.driverName,
      vehicleId     : vehicleId     ?? this.vehicleId,
      vehiclePlate  : vehiclePlate  ?? this.vehiclePlate,
      departureTime : departureTime ?? this.departureTime,
      arrivalTime   : arrivalTime   ?? this.arrivalTime,
      waypoints     : waypoints     ?? this.waypoints,
      lastLatitude  : lastLatitude  ?? this.lastLatitude,
      lastLongitude : lastLongitude ?? this.lastLongitude,
      createdAt     : createdAt     ?? this.createdAt,
      updatedAt     : updatedAt     ?? this.updatedAt,
      companyName   : companyName   ?? this.companyName,
      companyRuc    : companyRuc    ?? this.companyRuc,
    );
  }
  /* ------------------------------------------------------------------ */

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    // Waypoints puede venir como List<dynamic> o String JSON
    List<Waypoint> parseWaypoints(dynamic raw) {
      if (raw == null) return [];
      final dynamic data = raw is String ? jsonDecode(raw) : raw;
      if (data is List) {
        return data
            .map((e) => Waypoint.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    }

    return RouteModel(
      id           : json['id'] as int?,
      type         : json['type'] as String,
      customer     : json['customer'] as String,
      nameRoute    : json['nameRoute'] as String,
      status       : json['status'] as String,
      shift        : json['shift'] as String,
      driverId     : json['driverId'] as int?,
      driverName   : json['driverName'] as String?,
      vehicleId    : json['vehicleId'] as int?,
      vehiclePlate : json['vehiclePlate'] as String?,
      departureTime: json['departureTime'] != null
          ? DateTime.parse(json['departureTime'] as String)
          : null,
      arrivalTime  : json['arrivalTime'] != null
          ? DateTime.parse(json['arrivalTime'] as String)
          : null,
      waypoints    : parseWaypoints(json['waypoints']),
      lastLatitude : (json['lastLatitude'] as num?)?.toDouble(),
      lastLongitude: (json['lastLongitude'] as num?)?.toDouble(),
      createdAt    : json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt    : json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      companyName  : json['companyName'] as String? ?? '',
      companyRuc   : json['companyRuc'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'type'         : type,
    'customer'     : customer,
    'nameRoute'    : nameRoute,
    'status'       : status,
    'shift'        : shift,
    'driverId'     : driverId,
    'driverName'   : driverName,
    'vehicleId'    : vehicleId,
    'vehiclePlate' : vehiclePlate,
    'departureTime': departureTime?.toIso8601String(),
    'arrivalTime'  : arrivalTime?.toIso8601String(),
    'waypoints'    : json.encode(waypoints.map((w) => w.toJson()).toList()),
    'lastLatitude' : lastLatitude,
    'lastLongitude': lastLongitude,
    'createdAt'    : createdAt?.toIso8601String(),
    'updatedAt'    : updatedAt?.toIso8601String(),
    'companyName'  : companyName,
    'companyRuc'   : companyRuc,
  };
}
