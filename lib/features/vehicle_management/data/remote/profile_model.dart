class ProfileModel {
  final int id;
  final String name;
  final String lastName;
  final String email;
  final String type;               // «Administrador», «Transportista», …
  final String? phone;
  final String? companyName;
  final String? companyRuc;
  final String? profilePhoto;      // URL o Base-64

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

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
    id          : json['id']        as int,
    name        : json['name']      as String,
    lastName    : json['lastName']  as String,
    email       : json['email']     as String,
    type        : json['type']      as String,
    phone       : json['phone']         as String?,
    companyName : json['companyName']  as String?,
    companyRuc  : json['companyRuc']   as String?,
    profilePhoto: json['profilePhoto'] as String?,
  );

  /* PUT general */
  Map<String, dynamic> toUpdateJson() => {
    'name'        : name,
    'lastName'    : lastName,
    'email'       : email,
    'phone'       : phone?.trim()        ?? '',
    'companyName' : companyName?.trim()  ?? '',
    'companyRuc'  : companyRuc?.trim()   ?? '',
    'profilePhoto': profilePhoto ?? '',
  };

  /* PATCH contraseña */
  Map<String, dynamic> toChangePasswordJson(
      String oldPassword, String newPassword) =>
      {
        'email'      : email,
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      };
}
