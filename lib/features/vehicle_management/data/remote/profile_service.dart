import 'dart:convert';
import 'package:collection/collection.dart';               // 👈 new
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
}
