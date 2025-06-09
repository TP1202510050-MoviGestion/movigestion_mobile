import 'package:movigestion_mobile/features/vehicle_management/data/remote/profile_service.dart';
import 'package:movigestion_mobile/features/vehicle_management/data/remote/profile_model.dart';

class ProfileRepository {
  final ProfileService profileService;

  ProfileRepository({required this.profileService});

  Future<ProfileModel?> login(String email, String password) {
    return profileService.getProfileByEmailAndPassword(email, password);
  }

  Future<ProfileModel?> findByNameAndLastName(String name, String lastName) {
    return profileService.getProfileByNameAndLastName(name, lastName);
  }

  Future<bool> update(ProfileModel profile) {
    return profileService.updateProfile(profile);
  }

  Future<bool> changePassword(
      String email,
      String oldPassword,
      String newPassword,
      ) {
    return profileService.changePassword(email, oldPassword, newPassword);
  }
}
