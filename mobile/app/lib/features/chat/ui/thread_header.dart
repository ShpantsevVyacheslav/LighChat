import 'package:flutter/material.dart';

/// Thread header styled to match `ChatHeader` (chat screen).
///
/// Supports the same search-mode UI to keep UX consistent.
class ThreadHeader extends StatelessWidget {
  const ThreadHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onClose,
    required this.searchActive,
    required this.onSearchTap,
    this.searchController,
    this.searchFocusNode,
    this.onSearchClose,
  });

  final String title;
  final String subtitle;
  final VoidCallback onClose;

  final bool searchActive;
  final VoidCallback onSearchTap;
  final TextEditingController? searchController;
  final FocusNode? searchFocusNode;
  final VoidCallback? onSearchClose;

  @override
  Widget build(BuildContext context) {
    final fg = Colors.white.withValues(alpha: 0.96);

    if (searchActive &&
        searchController != null &&
        searchFocusNode != null &&
        onSearchClose != null) {
      return Container(
        padding: const EdgeInsets.fromLTRB(8, 7, 10, 7),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.28),
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withValues(alpha: 0.10),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Назад',
              onPressed: onSearchClose,
              color: fg,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: searchController!,
                builder: (context, _) {
                  final q = searchController!.text;
                  return TextField(
                    controller: searchController,
                    focusNode: searchFocusNode,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(
                      color: fg,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    cursorColor: fg,
                    decoration: InputDecoration(
                      hintText: 'Поиск в обсуждении…',
                      hintStyle: TextStyle(color: fg.withValues(alpha: 0.50)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      isDense: true,
                      suffixIcon: q.isNotEmpty
                          ? IconButton(
                              tooltip: 'Очистить',
                              onPressed: () => searchController!.clear(),
                              icon: Icon(
                                Icons.close_rounded,
                                color: fg.withValues(alpha: 0.7),
                                size: 19,
                              ),
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    Widget iconButton({
      required IconData icon,
      required VoidCallback onTap,
      required String tooltip,
    }) {
      return Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: IconButton(
            tooltip: tooltip,
            onPressed: onTap,
            iconSize: 18,
            color: fg,
            padding: EdgeInsets.zero,
            icon: Icon(icon),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 7, 10, 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.10),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Закрыть',
            onPressed: onClose,
            color: fg,
            icon: const Icon(Icons.close_rounded),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: fg.withValues(alpha: 0.70),
                  ),
                ),
              ],
            ),
          ),
          iconButton(
            tooltip: 'Поиск',
            onTap: onSearchTap,
            icon: Icons.search_rounded,
          ),
        ],
      ),
    );
  }
}

