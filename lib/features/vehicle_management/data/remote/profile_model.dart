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
      id: json['id'],
      name: json['name'],
      lastName: json['lastName'],
      email: json['email'],
      type: json['type'],
      phone: json['phone'],
      companyName: json['companyName'],
      companyRuc: json['companyRuc'],
      profilePhoto: json['profilePhoto'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id'          : id,
      'name'        : name,
      'lastName'    : lastName,
      'email'       : email,
      'type'        : type,
      'phone'       : phone,
      'companyName' : companyName,
      'companyRuc'  : companyRuc,
      'profilePhoto': profilePhoto,
    };
  }
}
