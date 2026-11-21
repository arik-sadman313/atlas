import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/providers.dart';
import '../../../../core/theme/atlas_colors.dart';

/// Collapsible Obsidian/Vaultite Frontmatter Properties Banner.
///
/// Renders standard YAML properties (`tags`, `aliases`, `kind`, `status`, `created`, `updated`)
/// inline at the top of notes, identical to Vaultite and Obsidian 1.4+.
class VaultPropertiesBanner extends ConsumerStatefulWidget {
  final String nodeId;
  final bool initialExpanded;

  const VaultPropertiesBanner({
    super.key,
    required this.nodeId,
    this.initialExpanded = false,
  });

  @override
  ConsumerState<VaultPropertiesBanner> createState() =>
      _VaultPropertiesBannerState();
}

class _VaultPropertiesBannerState extends ConsumerState<VaultPropertiesBanner> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initialExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final vaultiteIndex = ref.watch(vaultiteIndexProvider);
    final item = vaultiteIndex[widget.nodeId];

    final tags = item?.tags ?? const <String>[];
    final aliases = item?.aliases ?? const <String>[];
    final kindName = item?.kind.name ?? 'note';
    final statusName = item?.status?.name ?? 'seed';
    final createdText = item?.created != null
        ? DateFormat.yMMMd().format(item!.created!)
        : 'Today';
    final updatedText = item?.updated != null
        ? DateFormat.yMMMd().format(item!.updated!)
        : 'Just now';

    final propCount = 4 + (tags.isNotEmpty ? 1 : 0) + (aliases.isNotEmpty ? 1 : 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181B22) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? const Color(0xFF282C37) : const Color(0xFFE2E8F0),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Toggle
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  Icon(
                    _isExpanded ? Icons.expand_more : Icons.chevron_right,
                    size: 16,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Properties $propCount',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  if (!_isExpanded && tags.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final tag in tags.take(3))
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AtlasColors.accentBlue.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '#$tag',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AtlasColors.accentBlue,
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // Expanded Properties Table
          if (_isExpanded) ...[
            const Divider(height: 1, thickness: 0.5),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  _buildPropertyRow(
                    label: 'kind',
                    icon: Icons.category_outlined,
                    valueWidget: _buildBadge(kindName, AtlasColors.accentBlue),
                    isDark: isDark,
                  ),
                  _buildPropertyRow(
                    label: 'status',
                    icon: Icons.flag_outlined,
                    valueWidget: _buildBadge(
                      statusName,
                      const Color(0xFF10B981),
                    ),
                    isDark: isDark,
                  ),
                  if (tags.isNotEmpty)
                    _buildPropertyRow(
                      label: 'tags',
                      icon: Icons.tag,
                      valueWidget: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: tags.map((t) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AtlasColors.accentBlue.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '#$t',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AtlasColors.accentBlue,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      isDark: isDark,
                    ),
                  if (aliases.isNotEmpty)
                    _buildPropertyRow(
                      label: 'aliases',
                      icon: Icons.alternate_email,
                      valueWidget: Text(
                        aliases.join(', '),
                        style: const TextStyle(fontSize: 12),
                      ),
                      isDark: isDark,
                    ),
                  _buildPropertyRow(
                    label: 'created',
                    icon: Icons.calendar_today_outlined,
                    valueWidget: Text(
                      createdText,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    isDark: isDark,
                  ),
                  _buildPropertyRow(
                    label: 'updated',
                    icon: Icons.update,
                    valueWidget: Text(
                      updatedText,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPropertyRow({
    required String label,
    required IconData icon,
    required Widget valueWidget,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 13,
                  color: isDark ? Colors.white38 : Colors.black45,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: valueWidget),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
