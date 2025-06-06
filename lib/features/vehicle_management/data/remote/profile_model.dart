class ProfileModel {
  final int id;
  final String name;
  final String lastName;
  final String email;
  final String type;

  ProfileModel({
    required this.id,
    required this.name,
    required this.lastName,
    required this.email,
    required this.type,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'],
      name: json['name'],
      lastName: json['lastName'],
      email: json['email'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'lastName': lastName,
      'email': email,
      'type': type,
    };
  }
}
