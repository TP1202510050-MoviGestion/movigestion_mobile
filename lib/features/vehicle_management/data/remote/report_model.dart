class ReportModel {
  final int? id;
  final int userId;
  final String type;
  final String description;
  final String driverName;
  final DateTime createdAt;
  final String photoOrVideo;
  final String status;
  final String location;
  final String vehiclePlate;
  final String companyName;   // ← nuevo
  final String companyRuc;    // ← nuevo

  ReportModel({
    this.id,
    required this.userId,
    required this.type,
    required this.description,
    required this.driverName,
    required this.createdAt,
    required this.photoOrVideo,
    required this.status,
    required this.location,
    required this.vehiclePlate,
    required this.companyName,  // ← requerido
    required this.companyRuc,   // ← requerido
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] as int?,
      userId: json['userId'] as int,
      type: json['type'] as String,
      description: json['description'] as String,
      driverName: json['driverName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      photoOrVideo: json['photoOrVideo'] as String? ?? '',
      status: json['status'] as String? ?? '',
      location: json['location'] as String? ?? '',
      vehiclePlate: json['vehiclePlate'] as String? ?? '',
      companyName: json['companyName'] as String? ?? '',
      companyRuc: json['companyRuc'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'userId'       : userId,
      'type'         : type,
      'description'  : description,
      'driverName'   : driverName,
      'createdAt'    : createdAt.toIso8601String(),
      'photoOrVideo' : photoOrVideo,
      'status'       : status,
      'location'     : location,
      'vehiclePlate' : vehiclePlate,
      'companyName'  : companyName,
      'companyRuc'   : companyRuc,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  ReportModel copyWith({
    int? id,
    int? userId,
    String? type,
    String? description,
    String? driverName,
    DateTime? createdAt,
    String? photoOrVideo,
    String? status,
    String? location,
    String? vehiclePlate,
    String? companyName,
    String? companyRuc,
  }) {
    return ReportModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      description: description ?? this.description,
      driverName: driverName ?? this.driverName,
      createdAt: createdAt ?? this.createdAt,
      photoOrVideo: photoOrVideo ?? this.photoOrVideo,
      status: status ?? this.status,
      location: location ?? this.location,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      companyName: companyName ?? this.companyName,
      companyRuc: companyRuc ?? this.companyRuc,
    );
  }
}
