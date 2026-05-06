import 'package:flutter/material.dart';

class PaginationBar extends StatelessWidget {
  const PaginationBar({
    super.key,
    required this.page,
    required this.totalPages,
    required this.totalFixtures,
    required this.loading,
    required this.onPageChange,
  });

  final int page;
  final int totalPages;
  final int totalFixtures;
  final bool loading;
  final ValueChanged<int> onPageChange;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: page > 0 ? () => onPageChange(page - 1) : null,
          ),
          Row(
            children: [
              Text('Page ${page + 1} of $totalPages  ($totalFixtures)'),
              if (loading) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: page < totalPages - 1
                ? () => onPageChange(page + 1)
                : null,
          ),
        ],
      ),
    );
  }
}
