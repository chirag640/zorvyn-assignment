import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/database/cache_manager.dart';

/// Simple item model for demonstration
class HomeItem {
  const HomeItem({
    required this.id,
    required this.title,
    required this.description,
  });

  final String id;
  final String title;
  final String description;

  factory HomeItem.fromJson(Map<String, dynamic> json) {
    return HomeItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? json['body']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
    };
  }
}

/// Home screen state
class HomeState {
  const HomeState({
    this.items = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.hasMore = true,
    this.currentPage = 1,
  });

  final List<HomeItem> items;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final bool hasMore;
  final int currentPage;

  HomeState copyWith({
    List<HomeItem>? items,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    bool? hasMore,
    int? currentPage,
  }) {
    return HomeState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

/// Home screen state notifier with API integration
class HomeNotifier extends StateNotifier<HomeState> {
  HomeNotifier(this._apiClient, this._cacheManager) : super(const HomeState()) {
    loadItems();
  }

  final ApiClient _apiClient;
  final CacheManager<List> _cacheManager;

  /// Load items from API (or cache if offline)
  Future<void> loadItems({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(isRefreshing: true, error: null);
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
            // Try to load from cache first
      final cachedData = _cacheManager.get('home_items');
      if (cachedData != null && !refresh) {
        final cachedItems = cachedData
            .map((json) => HomeItem.fromJson(json as Map<String, dynamic>))
            .toList();
        state = state.copyWith(
          items: cachedItems,
          isLoading: false,
          isRefreshing: false,
        );
      }
      

      // Fetch from API - using JSONPlaceholder as example
      // Replace with your actual API endpoint
      final response = await _apiClient.get('/posts?_page=1&_limit=10');
      
      final List<HomeItem> items;
      if (response.data is List) {
        items = (response.data as List)
            .map((json) => HomeItem.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        items = [];
      }

            // Cache the results
      await _cacheManager.put(
        'home_items',
        items.map((item) => item.toJson()).toList(),
        ttl: const Duration(hours: 1),
      );
      

      state = state.copyWith(
        items: items,
        isLoading: false,
        isRefreshing: false,
        currentPage: 1,
        hasMore: items.length >= 10,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: e.toString(),
      );
    }
  }

  /// Load more items for pagination
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final nextPage = state.currentPage + 1;
      final response = await _apiClient.get('/posts?_page=$nextPage&_limit=10');
      
      final List<HomeItem> newItems;
      if (response.data is List) {
        newItems = (response.data as List)
            .map((json) => HomeItem.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        newItems = [];
      }

      state = state.copyWith(
        items: [...state.items, ...newItems],
        isLoading: false,
        currentPage: nextPage,
        hasMore: newItems.length >= 10,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh items
  Future<void> refresh() async {
    await loadItems(refresh: true);
  }
}

/// Provider for home screen state
final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final cacheManager = ref.watch(homeCacheManagerProvider);
  return HomeNotifier(apiClient, cacheManager);
});

