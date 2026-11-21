import 'dart:convert';

import 'package:yaml/yaml.dart';

/// Vaultite Frontmatter Parser and Serializer.
///
/// Implements Obsidian & Vaultite compatible YAML frontmatter parsing,
/// round-trip property updating, and standard metadata extraction.
class VaultiteFrontmatter {
  static final RegExp frontmatterRegex = RegExp(
    r'^---\r?\n([\s\S]*?)\r?\n---[ \t]*(?:\r?\n|$)',
  );

  /// Splits [markdown] into raw frontmatter YAML and markdown body.
  /// If no frontmatter block is present, returns `({}, markdown)`.
  static (Map<String, dynamic>, String) parse(String markdown) {
    final match = frontmatterRegex.firstMatch(markdown);
    if (match == null) {
      return (<String, dynamic>{}, markdown.trim());
    }

    final rawYaml = match.group(1) ?? '';
    final body = markdown.substring(match.end).trim();

    try {
      final doc = loadYaml(rawYaml);
      if (doc is YamlMap) {
        final map = _convertYamlNode(doc) as Map<String, dynamic>;
        return (map, body);
      } else if (doc is Map) {
        return (Map<String, dynamic>.from(doc), body);
      }
    } catch (_) {
      // Fallback on invalid YAML
    }

    return (<String, dynamic>{}, body);
  }

  /// Converts a [YamlNode] or dynamic YAML object into pure standard Dart primitives.
  static dynamic _convertYamlNode(dynamic node) {
    if (node is YamlMap) {
      final out = <String, dynamic>{};
      for (final entry in node.entries) {
        out[entry.key.toString()] = _convertYamlNode(entry.value);
      }
      return out;
    } else if (node is YamlList) {
      return node.map(_convertYamlNode).toList();
    } else if (node is Map) {
      final out = <String, dynamic>{};
      for (final entry in node.entries) {
        out[entry.key.toString()] = _convertYamlNode(entry.value);
      }
      return out;
    } else if (node is List) {
      return node.map(_convertYamlNode).toList();
    }
    return node;
  }

  /// Extracts standard tags from frontmatter properties (both `tags: [a, b]` and `tags: a, b`).
  static List<String> extractTags(dynamic rawTags) {
    if (rawTags == null) return const [];
    if (rawTags is List) {
      return rawTags
          .map((t) => t.toString().replaceAll('#', '').trim())
          .where((t) => t.isNotEmpty)
          .toList();
    }
    if (rawTags is String) {
      return rawTags
          .split(RegExp(r'[, ]+'))
          .map((t) => t.replaceAll('#', '').trim())
          .where((t) => t.isNotEmpty)
          .toList();
    }
    return const [];
  }

  /// Extracts aliases from frontmatter properties.
  static List<String> extractAliases(dynamic rawAliases) {
    if (rawAliases == null) return const [];
    if (rawAliases is List) {
      return rawAliases
          .map((a) => a.toString().trim())
          .where((a) => a.isNotEmpty)
          .toList();
    }
    if (rawAliases is String) {
      return rawAliases
          .split(RegExp(r'[,]+'))
          .map((a) => a.trim())
          .where((a) => a.isNotEmpty)
          .toList();
    }
    return const [];
  }

  /// Serializes [properties] and [body] into full markdown with standard Obsidian/Vaultite frontmatter.
  static String render(Map<String, dynamic> properties, String body) {
    if (properties.isEmpty) {
      return body.trim();
    }

    final buffer = StringBuffer();
    buffer.writeln('---');

    for (final entry in properties.entries) {
      final key = entry.key;
      final val = entry.value;
      if (val == null) continue;

      if (val is List) {
        if (val.isEmpty) {
          buffer.writeln('$key: []');
        } else {
          buffer.writeln('$key:');
          for (final item in val) {
            buffer.writeln('  - ${_formatYamlValue(item)}');
          }
        }
      } else if (val is Map) {
        if (val.isEmpty) {
          buffer.writeln('$key: {}');
        } else {
          buffer.writeln('$key:');
          for (final sub in val.entries) {
            buffer.writeln('  ${sub.key}: ${_formatYamlValue(sub.value)}');
          }
        }
      } else {
        buffer.writeln('$key: ${_formatYamlValue(val)}');
      }
    }

    buffer.writeln('---');
    if (body.trim().isNotEmpty) {
      buffer.writeln('');
      buffer.writeln(body.trim());
    }
    return buffer.toString();
  }

  static String _formatYamlValue(dynamic val) {
    if (val is bool || val is num) {
      return val.toString();
    }
    final s = val.toString();
    if (s.contains(':') ||
        s.contains('#') ||
        s.contains('[') ||
        s.contains(']') ||
        s.contains('{') ||
        s.contains('}') ||
        s.contains('"') ||
        s.contains('\n')) {
      return jsonEncode(s);
    }
    return s;
  }

  /// Updates or inserts a single property in [markdown], preserving existing content.
  static String setProperty(String markdown, String key, dynamic value) {
    final (props, body) = parse(markdown);
    final updated = Map<String, dynamic>.from(props);
    if (value == null) {
      updated.remove(key);
    } else {
      updated[key] = value;
    }
    return render(updated, body);
  }

  /// Removes a property from [markdown].
  static String removeProperty(String markdown, String key) {
    final (props, body) = parse(markdown);
    if (!props.containsKey(key)) return markdown;
    final updated = Map<String, dynamic>.from(props)..remove(key);
    return render(updated, body);
  }
}
