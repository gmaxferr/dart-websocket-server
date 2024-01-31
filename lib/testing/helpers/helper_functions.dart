import 'dart:math';

String generateRandomString({int length = 10}) {
  const String characters =
      "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
  final Random random = Random();
  String randomString = '';

  for (int i = 0; i < length; i++) {
    int randomIndex = random.nextInt(characters.length);
    randomString += characters[randomIndex];
  }

  return randomString;
}
