class CustomError implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  CustomError(this.message, {this.code, this.originalError});

  @override
  String toString() {
    if (code != null) {
      return 'CustomError [$code]: $message';
    }
    return 'CustomError: $message';
  }
}