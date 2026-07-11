class ApiException implements Exception {
  ApiException(this.message, {this.code, this.status});

  final String message;
  final String? code;
  final int? status;

  bool get isNetwork =>
      status == null || status == 0 || code == 'network_error';

  @override
  String toString() => message;
}
