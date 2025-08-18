class UserModel {
  final String userId;
  final String displayName;
  final String email;
  final String phone;
  final String photoUrl;
  final int coin;
  final int sessions;
  final String venueId;
  final String venueName;
  final bool hasPlayed;

  UserModel({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.phone,
    required this.photoUrl,
    required this.coin,
    required this.sessions,
    required this.venueId,
    required this.venueName,
    required this.hasPlayed,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data, String userId, String venueId) {
    return UserModel(
      userId: userId,
      displayName: data['displayName'] ?? data['name'] ?? 'Unknown User',
      email: data['email'] ?? 'N/A',
      phone: data['phone'] ?? 'N/A',
      photoUrl: data['photoUrl'] ?? '',
      coin: data['coin'] ?? 0,
      sessions: data['sessions'] ?? 0,
      venueId: venueId,
      venueName: data['venueName'] ?? data['venueId'] ?? 'N/A',
      hasPlayed: data['hasPlayed'] ?? true,
    );
  }
}

class ScanResult {
  final String userId;
  final String venueId;
  final String docId;

  ScanResult({
    required this.userId,
    required this.venueId,
    required this.docId,
  });

  factory ScanResult.fromQRCode(String qrCode) {
    // Normalize the QR code (same logic as dashboard)
    String normalized = qrCode.trim()
        .replaceAll(RegExp(r'[\s\n\r]'), '')
        .replaceAll(RegExp(r'[–—−]'), '-')
        .replaceAll(RegExp(r'[_|/]'), '-');

    final parts = normalized.split('-');
    String userId;
    String venueId;
    String docId;

    if (parts.length >= 2) {
      userId = parts[0];
      venueId = parts.sublist(1).join('-');
      docId = '$userId-$venueId';
    } else {
      throw Exception('Invalid QR code format');
    }

    return ScanResult(
      userId: userId,
      venueId: venueId,
      docId: docId,
    );
  }
}
