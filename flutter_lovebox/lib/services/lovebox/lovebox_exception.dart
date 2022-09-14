class LoveBoxException implements Exception {
  String message;

  LoveBoxException(this.message);

  @override
  String toString() {
    return 'LoveBoxException{message: $message}';
  }
}
