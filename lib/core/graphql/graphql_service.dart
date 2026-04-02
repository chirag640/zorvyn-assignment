import 'package:ferry/ferry.dart';

/// Thin wrapper around ferry [Client] for imperative usage alongside streams.
///
/// In most cases you'll consume [client.request] streams directly in your
/// state management layer; this class is a convenience for one-shot calls.
class FerryService {
  FerryService(this._client);

  final Client _client;

  /// Execute a one-shot request and return the first non-loading response.
  Future<OperationResponse<TData, TVars>> execute<TData, TVars>(
      OperationRequest<TData, TVars> request) {
    return _client.request(request).firstWhere((response) => !response.loading);
  }
}

class FerryException implements Exception {
  FerryException(this.message);
  final String message;

  @override
  String toString() => 'FerryException: $message';
}
