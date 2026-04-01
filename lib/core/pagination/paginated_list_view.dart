import 'package:flutter/material.dart';

import 'pagination_controller.dart';

/// A list view with built-in pagination support
class PaginatedListView<T> extends StatefulWidget {
  const PaginatedListView({
    super.key,
    required this.controller,
    required this.itemBuilder,
    this.separatorBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.loadingBuilder,
    this.loadingMoreBuilder,
    this.padding,
    this.physics,
  });

  final PaginationController<T> controller;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget Function(BuildContext context, int index)? separatorBuilder;
  final Widget Function(BuildContext context)? emptyBuilder;
  final Widget Function(BuildContext context, String? error)? errorBuilder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context)? loadingMoreBuilder;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // Load first page if not already loaded
    if (widget.controller.status == PaginationStatus.initial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.controller.loadFirstPage();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom && widget.controller.hasMorePages) {
      widget.controller.loadNextPage();
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    return currentScroll >= (maxScroll * 0.9); // Trigger at 90%
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        final status = widget.controller.status;

        // Loading state (first page)
        if (status == PaginationStatus.loading) {
          return widget.loadingBuilder?.call(context) ??
              const Center(child: CircularProgressIndicator());
        }

        // Empty state
        if (status == PaginationStatus.empty) {
          return widget.emptyBuilder?.call(context) ??
              const Center(child: Text('No items found'));
        }

        // Error state (first page)
        if (status == PaginationStatus.failure &&
            widget.controller.items.isEmpty) {
          return widget.errorBuilder
                  ?.call(context, widget.controller.errorMessage) ??
              _buildDefaultError();
        }

        // Success state
        final items = widget.controller.items;
        return RefreshIndicator(
          onRefresh: widget.controller.refresh,
          child: ListView.separated(
            controller: _scrollController,
            padding: widget.padding,
            physics: widget.physics,
            itemCount: items.length + (widget.controller.hasMorePages ? 1 : 0),
            separatorBuilder: (context, index) {
              return widget.separatorBuilder?.call(context, index) ??
                  const SizedBox.shrink();
            },
            itemBuilder: (context, index) {
              // Loading more indicator
              if (index >= items.length) {
                if (status == PaginationStatus.failure) {
                  return _buildLoadMoreError();
                }
                return widget.loadingMoreBuilder?.call(context) ??
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
              }

              // Regular item
              return widget.itemBuilder(context, items[index], index);
            },
          ),
        );
      },
    );
  }

  Widget _buildDefaultError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            widget.controller.errorMessage ?? 'Failed to load data',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: widget.controller.retry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreError() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(height: 8),
          Text(
            'Failed to load more',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: widget.controller.retry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

