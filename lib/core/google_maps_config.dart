// lib/core/google_maps_config.dart
import 'package:google_place/google_place.dart';

/// Clave pública de **Google Maps Platform**
/// (tiene que tener habilitados Maps SDK for Android, Maps SDK for iOS,
/// Maps JavaScript API y Places API para el autocompletado).
const kMapsApiKey = 'AIzaSyA3oXxsisOPBwW1xHV172Y2BCfi7EEiC8k';

/// Instancia global que podrás usar en toda la app
late final GooglePlace googlePlace = GooglePlace(kMapsApiKey);
