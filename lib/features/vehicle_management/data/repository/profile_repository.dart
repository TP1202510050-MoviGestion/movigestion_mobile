import 'package:movigestion_mobile/features/vehicle_management/data/remote/profile_service.dart';
import 'package:movigestion_mobile/features/vehicle_management/data/remote/profile_model.dart';

class ProfileRepository {
  final ProfileService profileService;

  ProfileRepository({required this.profileService});

  Future<ProfileModel?> getProfileByEmailAndPassword(String email, String password) async {
    return await profileService.getProfileByEmailAndPassword(email, password);
  }
}
