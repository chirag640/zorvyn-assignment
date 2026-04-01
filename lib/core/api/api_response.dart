/// Generic API response wrapper
class ApiResponse<T> {
  ApiResponse.success(this.data) : error = null;
  ApiResponse.error(this.error) : data = null;
  
  final T? data;
  final String? error;
  
  bool get isSuccess => data != null;
  bool get isError => error != null;
}

