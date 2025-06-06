import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:movigestion_mobile/core/app_constants.dart';
import 'profile_model.dart';

class ProfileService {
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

  Future<ProfileModel?> getProfileByNameAndLastName(String name, String lastName) async {
    final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.vehicle}');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> vehiclesList = json.decode(response.body);
        // Buscar el objeto que coincida con name y lastName
        final matchingProfile = vehiclesList.firstWhere(
              (vehicle) => vehicle['name'] == name && vehicle['lastName'] == lastName,
          orElse: () => null,
        );

        if (matchingProfile != null) {
          return ProfileModel.fromJson(matchingProfile);
        } else {
          print('No matching profile found.');
          return null;
        }
      } else {
        print('Failed to fetch vehicles. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error al realizar la solicitud: $e');
      return null;
    }
  }

  Future<bool> updateProfileByEmailAndPassword(String email, String password, Map<String, dynamic> updatedData) async {
    final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.profile}/email/$email/password/$password');

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(updatedData),
      );

      if (response.statusCode == 200) {
        print('Perfil actualizado exitosamente');
        return true;
      } else {
        print('Error al actualizar el perfil. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error al realizar la solicitud de actualización: $e');
      return false;
    }
  }
}
