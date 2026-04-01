import 'package:flutter/material.dart';

/// State for pagination
enum PaginationStatus {
  initial,
  loading,
  loadingMore,
  success,
  failure,
  empty,
}

/// Pagination controller for managing paginated lists
class PaginationController<T> extends ChangeNotifier {
  PaginationController({
    required this.fetchPage,
    this.itemsPerPage = 20,
  });

  /// Function to fetch a page of data
  final Future<List<T>> Function(int page) fetchPage;

  /// Items per page
  final int itemsPerPage;

  // State
  PaginationStatus _status = PaginationStatus.initial;
  List<T> _items = [];
  int _currentPage = 1;
  bool _hasMorePages = true;
  String? _errorMessage;

  // Getters
  PaginationStatus get status => _status;
  List<T> get items => List.unmodifiable(_items);
  int get currentPage => _currentPage;
  bool get hasMorePages => _hasMorePages;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == PaginationStatus.loading;
  bool get isLoadingMore => _status == PaginationStatus.loadingMore;
  bool get hasError => _status == PaginationStatus.failure;
  bool get isEmpty => _status == PaginationStatus.empty;

  /// Load first page
  Future<void> loadFirstPage() async {
    if (_status == PaginationStatus.loading) return;

    _status = PaginationStatus.loading;
    _items.clear();
    _currentPage = 1;
    _hasMorePages = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newItems = await fetchPage(_currentPage);

      if (newItems.isEmpty) {
        _status = PaginationStatus.empty;
      } else {
        _items = newItems;
        _status = PaginationStatus.success;
        _hasMorePages = newItems.length >= itemsPerPage;
      }
    } catch (e) {
      _status = PaginationStatus.failure;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  /// Load next page
  Future<void> loadNextPage() async {
    if (!_hasMorePages || _status == PaginationStatus.loadingMore) {
      return;
    }

    _status = PaginationStatus.loadingMore;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final newItems = await fetchPage(nextPage);

      _items.addAll(newItems);
      _currentPage = nextPage;
      _hasMorePages = newItems.length >= itemsPerPage;
      _status = PaginationStatus.success;
    } catch (e) {
      _status = PaginationStatus.failure;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  /// Refresh (reload first page)
  Future<void> refresh() async {
    await loadFirstPage();
  }

  /// Retry after error
  Future<void> retry() async {
    if (_items.isEmpty) {
      await loadFirstPage();
    } else {
      await loadNextPage();
    }
  }

  /// Reset controller
  void reset() {
    _status = PaginationStatus.initial;
    _items.clear();
    _currentPage = 1;
    _hasMorePages = true;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    reset();
    super.dispose();
  }
}

