class ProfileModel {
  final int id;
  final String name;
  final String lastName;
  final String email;
  final String type;
  final String? phone;         // Puede ser nulo si backend aún no lo envía
  final String? companyName;
  final String? companyRuc;
  final String? profilePhoto;  // URL o base-64

  ProfileModel({
    required this.id,
    required this.name,
    required this.lastName,
    required this.email,
    required this.type,
    this.phone,
    this.companyName,
    this.companyRuc,
    this.profilePhoto,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as int,
      name: json['name'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      type: json['type'] as String,
      phone: json['phone'] as String?,
      companyName: json['companyName'] as String?,
      companyRuc: json['companyRuc'] as String?,
      profilePhoto: json['profilePhoto'] as String?,
    );
  }

  /// Para el PUT general (/api/profiles/{id})
  Map<String, dynamic> toUpdateJson() {
    return {
      'name'        : name,
      'lastName'    : lastName,
      'email'       : email,
      'phone'       : phone ?? '',
      'companyName' : companyName ?? '',
      'companyRuc'  : companyRuc ?? '',
      'profilePhoto': profilePhoto ?? '',
    };
  }

  /// Para el PATCH de contraseña
  Map<String, dynamic> toChangePasswordJson(String oldPassword, String newPassword) {
    return {
      'email'      : email,
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    };
  }
}
