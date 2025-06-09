import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:movigestion_mobile/core/app_constants.dart';
import 'profile_model.dart';

class ProfileService {
  /// LOGIN / FETCH (sigue usando email+password)
  Future<ProfileModel?> getProfileByEmailAndPassword(String email, String password) async {
    final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.profile}/email/$email/password/$password');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return ProfileModel.fromJson(json.decode(response.body));
      } else {
        print('Failed to fetch profile. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error al realizar la solicitud: $e');
      return null;
    }
  }

  /// TRAER TODOS y luego filtrar por name/lastName
  Future<ProfileModel?> getProfileByNameAndLastName(String name, String lastName) async {
    final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.profile}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        final match = list.firstWhere(
              (p) => p['name'] == name && p['lastName'] == lastName,
          orElse: () => null,
        );
        return match != null ? ProfileModel.fromJson(match) : null;
      } else {
        print('Failed to fetch profiles. Status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error al realizar la solicitud: $e');
      return null;
    }
  }

  /// PUT general: /api/profiles/{id}
  Future<bool> updateProfile(ProfileModel profile) async {
    final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.profile}/${profile.id}');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(profile.toUpdateJson()),
      );
      if (response.statusCode == 200) {
        print('Perfil actualizado exitosamente');
        return true;
      } else {
        print('Error al actualizar perfil. Status: ${response.statusCode}');
        print('Body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error al enviar PUT: $e');
      return false;
    }
  }

  /// PATCH contraseña: /api/profiles/password
  Future<bool> changePassword(
      String email, String oldPassword, String newPassword) async {
    final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.profile}/password');
    try {
      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      );
      if (response.statusCode == 200) {
        print('Contraseña cambiada correctamente');
        return true;
      } else {
        print('Error al cambiar contraseña. Status: ${response.statusCode}');
        print('Body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error en PATCH password: $e');
      return false;
    }
  }
}
