import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

class WalletService {
  static FirebaseFunctions? _functions;
  
  static FirebaseFunctions get functions {
    _functions ??= FirebaseFunctions.instanceFor(
      region: 'us-central1',
      // TODO: Configure for locowallet-30799 project
      // This will need to be updated once the functions are deployed
    );
    return _functions!;
  }
  
  static Future<Map<String, dynamic>> createPass({
    required String venueId,
    int? balance,
    String? venueName,
    String? displayName,
  }) async {
    try {
      final createPass = functions.httpsCallable('createPass');
      final result = await createPass.call({
        'venueId': venueId,
        if (balance != null) 'balance': balance,
        if (venueName != null) 'venueName': venueName,
        if (displayName != null) 'displayName': displayName,
      });
      
      return Map<String, dynamic>.from(result.data);
    } catch (error) {
      throw Exception('Failed to create pass: $error');
    }
  }
  
  static Future<void> saveVenuePassConfig({
    required String venueId,
    required Map<String, dynamic> config,
  }) async {
    try {
      final saveConfig = functions.httpsCallable('saveVenuePassConfig');
      await saveConfig.call({
        'venueId': venueId,
        'config': config,
      });
    } catch (error) {
      throw Exception('Failed to save config: $error');
    }
  }
  
  static Future<Map<String, dynamic>?> getVenuePassConfig({
    required String venueId,
  }) async {
    try {
      final getConfig = functions.httpsCallable('getVenuePassConfig');
      final result = await getConfig.call({
        'venueId': venueId,
      });
      
      final data = Map<String, dynamic>.from(result.data);
      return data['config'];
    } catch (error) {
      throw Exception('Failed to get config: $error');
    }
  }
}
