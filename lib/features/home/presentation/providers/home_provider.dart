import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

import '../../../../core/providers/app_providers.dart';
import '../../../../core/database/cache_manager.dart';
import '../../../../core/supabase/supabase_service.dart';

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
      description:
          json['description']?.toString() ?? json['body']?.toString() ?? '',
    );
  }

  factory HomeItem.fromSupabase(Map<String, dynamic> json) {
    final occurredAt = (json['occurred_at'] as String?)?.trim() ?? '';
    final note = (json['note'] as String?)?.trim();
    final category = (json['category'] as String?)?.trim();

    return HomeItem(
      id: json['id']?.toString() ?? '',
      title: (category == null || category.isEmpty) ? 'Transaction' : category,
      description: (note == null || note.isEmpty)
          ? _occurredAtDescription(occurredAt)
          : note,
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

String _occurredAtDescription(String rawValue) {
  final parsed = DateTime.tryParse(rawValue);
  if (parsed == null) {
    return 'Synced from Supabase';
  }

  final day = parsed.day.toString().padLeft(2, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  return 'Recorded on $day/$month/${parsed.year}';
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
  HomeNotifier(this._supabaseClient, this._cacheManager)
      : super(const HomeState()) {
    loadItems();
  }

  static const int _pageSize = 10;

  final SupabaseClient? _supabaseClient;
  final CacheManager<List> _cacheManager;

  Future<SupabaseClient> _requireSupabaseClient() async {
    final client = _supabaseClient ?? SupabaseService.client;
    if (client != null) {
      return client;
    }

    await SupabaseService.initialize();
    final recovered = SupabaseService.client;
    if (recovered != null) {
      return recovered;
    }

    throw Exception(
      SupabaseService.initializationError ??
          'Supabase is unavailable. Complete startup setup and retry.',
    );
  }

  Future<List<HomeItem>> _fetchPage(int page) async {
    final supabase = await _requireSupabaseClient();
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      return const <HomeItem>[];
    }

    final start = (page - 1) * _pageSize;
    final end = start + _pageSize - 1;

    final response = await supabase
        .from('finance_transactions')
        .select('id,category,note,occurred_at')
        .eq('user_id', userId)
        .order('occurred_at', ascending: false)
        .range(start, end);

    if (response is! List) {
      return const <HomeItem>[];
    }

    return response
        .whereType<Map<String, dynamic>>()
        .map(HomeItem.fromSupabase)
        .toList(growable: false);
  }

  /// Load items from API (or cache if offline)
  Future<void> loadItems({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(isRefreshing: true, error: null);
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      // Try to load from cache first.
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

      final items = await _fetchPage(1);

      // Cache the results.
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
        hasMore: items.length >= _pageSize,
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
      final newItems = await _fetchPage(nextPage);

      state = state.copyWith(
        items: [...state.items, ...newItems],
        isLoading: false,
        currentPage: nextPage,
        hasMore: newItems.length >= _pageSize,
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
  final supabaseClient = ref.watch(supabaseClientProvider);
  final cacheManager = ref.watch(homeCacheManagerProvider);
  return HomeNotifier(supabaseClient, cacheManager);
});
