import 'dart:convert';
import 'package:collection/collection.dart';               // 👈 new
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:movigestion_mobile/core/app_constants.dart';
import 'profile_model.dart';

class ProfileService {
  /* ------------------------------------------------------------------ */
  /*                          ///  GET-BY-EMAIL                         */
  /* ------------------------------------------------------------------ */
  Future<ProfileModel?> getProfileByEmailAndPassword(
      String email, String password) async {
    final url = Uri.parse(
        '${AppConstants.baseUrl}${AppConstants.profile}/email/$email/password/$password');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return ProfileModel.fromJson(json.decode(response.body));
      }
      print('[ProfileSvc] status ${response.statusCode}: ${response.body}');
      return null;
    } catch (e) {
      print('[ProfileSvc] error getProfileByEmailAndPassword: $e');
      return null;
    }
  }

  /* ------------------------------------------------------------------ */
  /*                       ///  GET BY NAME + LASTNAME                   */
  /* ------------------------------------------------------------------ */
  Future<ProfileModel?> getProfileByNameAndLastName(
      String name, String lastName) async {
    final list = await _getAllProfiles();
    return list.firstWhereOrNull(
          (p) =>
      p.name.toLowerCase().trim() == name.toLowerCase().trim() &&
          p.lastName.toLowerCase().trim() == lastName.toLowerCase().trim(),
    );
  }

  /* ------------------------------------------------------------------ */
  /*                       ///  GET ALL CARRIERS (TRANSPORTISTAS)        */
  /* ------------------------------------------------------------------ */
  Future<List<ProfileModel>> getAllCarriers() async {
    final list = await _getAllProfiles();
    return list.where((p) => p.type == 'Transportista').toList();
  }

  /* ------------------------------------------------------------------ */
  /*                           ///  UPDATE PROFILE                      */
  /* ------------------------------------------------------------------ */
  Future<bool> updateProfile(ProfileModel profile) async {
    final url =
    Uri.parse('${AppConstants.baseUrl}${AppConstants.profile}/${profile.id}');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(profile.toUpdateJson()),
      );
      final ok = response.statusCode == 200;
      if (!ok) {
        print('[ProfileSvc] update failed (${response.statusCode}) → ${response.body}');
      }
      return ok;
    } catch (e) {
      print('[ProfileSvc] updateProfile error: $e');
      return false;
    }
  }

  /* ------------------------------------------------------------------ */
  /*                           ///  CHANGE PASSWORD                     */
  /* ------------------------------------------------------------------ */
  Future<bool> changePassword(
      String email, String oldPassword, String newPassword) async {
    final url =
    Uri.parse('${AppConstants.baseUrl}${AppConstants.profile}/password');
    try {
      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email'      : email,
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      );
      final ok = response.statusCode == 200;
      if (!ok) {
        print('[ProfileSvc] changePwd failed (${response.statusCode}) → ${response.body}');
      }
      return ok;
    } catch (e) {
      print('[ProfileSvc] changePassword error: $e');
      return false;
    }
  }

  /* ================================================================== */
  /*                          PRIVATE HELPERS                           */
  /* ================================================================== */
  Future<List<ProfileModel>> _getAllProfiles() async {
    final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.profile}');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> raw = json.decode(response.body);
      return raw
          .map((e) => ProfileModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(
        '[ProfileSvc] getAllProfiles failed (${response.statusCode})');
  }


  Future<ProfileModel?> getProfileByFullName(String fullName) async {
    try {
      final res = await http.get(Uri.parse('${AppConstants.baseUrl}${AppConstants.profile}'));
      if (res.statusCode == 200) {
        final decodedBody = utf8.decode(res.bodyBytes);
        final list = jsonDecode(decodedBody) as List;

        // Normalizamos el nombre completo que buscamos para una comparación insensible
        final normalizedTargetName = fullName.trim().toLowerCase();

        for (final profileJson in list) {
          final profile = ProfileModel.fromJson(profileJson as Map<String, dynamic>);

          // Construimos y normalizamos el nombre completo del perfil actual
          final currentFullName = '${profile.name} ${profile.lastName}'.trim().toLowerCase();

          // Si encontramos una coincidencia exacta, devolvemos el perfil
          if (currentFullName == normalizedTargetName) {
            return profile;
          }
        }
      }
    } catch (e) {
      // Manejar el error si es necesario, por ahora lo dejamos silencioso
      debugPrint('Error en getProfileByFullName: $e');
    }
    // Si no se encuentra ninguna coincidencia después de recorrer la lista, devolvemos null
    return null;
  }



}
