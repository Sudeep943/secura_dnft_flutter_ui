import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;

void main() {
  const keyB64 = 'U2VjdXJhTG9naW5LZXlBRVMyNTZWYWx1ZTEyMzQ1Njc=';
  const ivB64 = 'U2VjdXJhSW5pdFZlYzEyMw==';
  const cipherText = 'cEWdZBkiqyxOQbh1xeYhrbSeRfIRKLRXZ+qF3Rc3mhIy6AjbobuNNd7YDutSve/8XRXrHtdd4jyEoy72umBG8ApjfYRq7773sMH2yqqOTRL+3t89XtomGyh0KNr4imbTbZ39cegleMT8s4L9O9/45hMGB2FNRwJJjo5fUgvWdupUitXkVfYMtdggULKJzAAy';

  final key = encrypt.Key(base64Decode(keyB64));
  final iv = encrypt.IV(base64Decode(ivB64));
  final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
  final plain = encrypter.decrypt64(cipherText.trim(), iv: iv);
  print(plain);
}
