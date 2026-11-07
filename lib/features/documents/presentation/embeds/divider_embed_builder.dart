import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../../core/theme/atlas_colors.dart';
import '../../../../core/theme/atlas_spacing.dart';
import '../../domain/models/document_embed_models.dart';

/// Embed builder for rendering styled horizontal dividers in Flutter Quill.
class DividerEmbedBuilder extends EmbedBuilder {
  const DividerEmbedBuilder();

  @override
  String get key => DividerBlockEmbed.dividerType;

  @override
  bool get expanded => true;

  @override
  String toPlainText(Embed node) => '\n---\n';

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AtlasSpacing.md),
      child: Divider(
        color: isDark ? AtlasColors.darkBorder : AtlasColors.lightBorder,
        thickness: 1.0,
        height: 1.0,
      ),
    );
  }
}
