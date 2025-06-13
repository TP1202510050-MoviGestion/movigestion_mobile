import 'package:movigestion_mobile/features/vehicle_management/data/remote/profile_model.dart';
import 'package:movigestion_mobile/features/vehicle_management/data/remote/profile_service.dart';

class ProfileRepository {
  final ProfileService _svc;

  ProfileRepository({required ProfileService profileService})
      : _svc = profileService;

  /* ---------- Auth ---------- */
  Future<ProfileModel?> login(String email, String password) =>
      _svc.getProfileByEmailAndPassword(email, password);

  /* ---------- Lookup ---------- */
  Future<ProfileModel?> findByNameAndLastName(String n, String ln) =>
      _svc.getProfileByNameAndLastName(n, ln);

  Future<List<ProfileModel>> getAllCarriers() => _svc.getAllCarriers();

  /* ---------- Update ---------- */
  Future<bool> update(ProfileModel p) => _svc.updateProfile(p);

  Future<bool> changePassword(
      String email, String oldPwd, String newPwd) =>
      _svc.changePassword(email, oldPwd, newPwd);
}
