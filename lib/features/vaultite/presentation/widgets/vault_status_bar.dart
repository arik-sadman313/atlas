import 'package:flutter/material.dart';

/// Vaultite Bottom Status Bar.
///
/// Displays document path, word count, character count, token estimate, and sync status.
class VaultStatusBar extends StatelessWidget {
  final String path;
  final int wordCount;
  final int charCount;
  final String kind;
  final bool isSaving;

  const VaultStatusBar({
    super.key,
    required this.path,
    required this.wordCount,
    required this.charCount,
    required this.kind,
    this.isSaving = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final estimatedTokens = (wordCount * 1.33).ceil();

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14161A) : const Color(0xFFF1F5F9),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF282C37) : const Color(0xFFCBD5E1),
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSaving ? Icons.sync : Icons.check_circle_outline,
            size: 11,
            color: isSaving ? Colors.amber : const Color(0xFF10B981),
          ),
          const SizedBox(width: 5),
          Text(
            isSaving ? 'Saving to Vault...' : path,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const Spacer(),
          Text(
            kind,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$wordCount words',
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$charCount characters',
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '~$estimatedTokens tokens',
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }
}
