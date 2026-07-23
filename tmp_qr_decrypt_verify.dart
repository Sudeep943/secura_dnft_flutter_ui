import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;

String decryptLikeApi(String value) {
  const keyB64 = 'U2VjdXJhTG9naW5LZXlBRVMyNTZWYWx1ZTEyMzQ1Njc=';
  const ivB64 = 'U2VjdXJhSW5pdFZlYzEyMw==';

  var normalized = value.trim();
  if (normalized.length >= 2 &&
      ((normalized.startsWith('"') && normalized.endsWith('"')) ||
          (normalized.startsWith("'") && normalized.endsWith("'")))) {
    normalized = normalized.substring(1, normalized.length - 1);
  }
  normalized = normalized.replaceAll(' ', '+').replaceAll('\n', '').replaceAll('\r', '');
  final remainder = normalized.length % 4;
  if (remainder == 2) normalized = '$normalized==';
  if (remainder == 3) normalized = '$normalized=';

  final key = encrypt.Key(base64Decode(keyB64.trim()));
  final iv = encrypt.IV(base64Decode(ivB64.trim()));
  final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
  return encrypter.decrypt64(normalized, iv: iv);
}

void main() {
  const cipher = 'cEWdZBkiqyxOQbh1xeYhrbSeRfIRKLRXZ+qF3Rc3mhIy6AjbobuNNd7YDutSve/8XRXrHtdd4jyEoy72umBG8ApjfYRq7773sMH2yqqOTRL+3t89XtomGyh0KNr4imbTbZ39cegleMT8s4L9O9/45hMGB2FNRwJJjo5fUgvWdupUitXkVfYMtdggULKJzAAy';
  final map = {
    'messageCode': 'SUCC_MESSAGE_44',
    'data': {
      'upiPaymentURL': cipher,
      'bankName': cipher,
      'accountHolderName': cipher,
      'plainField': 'INR',
    }
  };

  final data = Map<String, dynamic>.from(map['data'] as Map);
  final out = <String, dynamic>{};
  for (final entry in data.entries) {
    final v = entry.value;
    if (v is String) {
      try {
        out[entry.key] = decryptLikeApi(v);
      } catch (_) {
        out[entry.key] = v;
      }
    } else {
      out[entry.key] = v;
    }
  }
  print(out['upiPaymentURL']);
  print(out['plainField']);
}
