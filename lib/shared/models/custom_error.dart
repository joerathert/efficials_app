class CustomError implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? context;
  final DateTime timestamp;

  CustomError(
    this.message, {
    this.code,
    this.originalError,
    this.stackTrace,
    this.context,
  }) : timestamp = DateTime.now();

  @override
  String toString() {
    if (code != null) {
      return 'CustomError [$code]: $message';
    }
    return 'CustomError: $message';
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'code': code,
      'timestamp': timestamp.toIso8601String(),
      'context': context,
      'originalError': originalError?.toString(),
      'stackTrace': stackTrace?.toString(),
    };
  }

  static void logError(CustomError error, {String? category}) {
    // Simple fallback logging - users can manually log errors if needed
    print('CustomError [${error.code ?? 'UNKNOWN'}]: ${error.message}');
    if (error.context != null) {
      print('Context: ${error.context}');
    }
    if (error.originalError != null) {
      print('Original Error: ${error.originalError}');
    }
  }
}