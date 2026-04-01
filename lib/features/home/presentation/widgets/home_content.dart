import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/home_provider.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/utils/app_responsive.dart';

/// Home screen content widget using ConsumerWidget for Riverpod
class HomeContent extends ConsumerWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeProvider);

    // Initial loading state
    if (homeState.isLoading && homeState.items.isEmpty) {
      return const LoadingIndicator(message: 'Loading items...');
    }

    // Error state (when no items are loaded yet)
    if (homeState.error != null && homeState.items.isEmpty) {
      return ErrorView(
        message: homeState.error!,
        onRetry: () => ref.read(homeProvider.notifier).loadItems(),
      );
    }

    // Empty state
    if (homeState.items.isEmpty) {
      return EmptyState(
        message: 'No items found',
        action: () => ref.read(homeProvider.notifier).loadItems(),
        actionLabel: 'Retry',
      );
    }

    // List with pull-to-refresh
    return RefreshIndicator(
      onRefresh: () => ref.read(homeProvider.notifier).refresh(),
      child: ListView.builder(
        itemCount: homeState.items.length + (homeState.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Loading indicator for pagination
          if (index == homeState.items.length) {
            if (homeState.isLoading) {
              return Padding(
                padding: context.rPaddingAll(16),
                child: const Center(child: CircularProgressIndicator()),
              );
            }
            return const SizedBox.shrink();
          }

          final item = homeState.items[index];

          // Load more when reaching the end
          if (index == homeState.items.length - 2 && homeState.hasMore && !homeState.isLoading) {
            Future.microtask(() => ref.read(homeProvider.notifier).loadMore());
          }

          return Card(
            margin: context.rPaddingSymmetric(h: 16, v: 8),
            child: ListTile(
              leading: CircleAvatar(
                child: Text('${index + 1}'),
              ),
              title: Text(
                item.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: context.rFont(16),
                ),
              ),
              subtitle: Text(
                item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: context.rFont(14)),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to detail page (implement as needed)
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Tapped on ${item.title}')),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

