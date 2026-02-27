class PairingRequest {
  final String code;
  final String deviceName;

  PairingRequest({
    required this.code,
    required this.deviceName,
  });

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'deviceName': deviceName,
    };
  }
}

class PairingResponse {
  final String deviceId;
  final String token;

  PairingResponse({
    required this.deviceId,
    required this.token,
  });

  factory PairingResponse.fromJson(Map<String, dynamic> json) {
    return PairingResponse(
      deviceId: json['deviceId'] as String,
      token: json['token'] as String,
    );
  }
}

class PairingCodeResponse {
  final String code;
  final int expiresAt;

  PairingCodeResponse({
    required this.code,
    required this.expiresAt,
  });

  factory PairingCodeResponse.fromJson(Map<String, dynamic> json) {
    return PairingCodeResponse(
      code: json['code'] as String,
      expiresAt: json['expiresAt'] as int,
    );
  }
}
