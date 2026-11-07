import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart';

/// Custom block embed for Callout boxes.
///
/// Contains customizable [icon] (emoji or icon name), [colorHex] (tint color),
/// and [text] body.
class CalloutBlockEmbed extends CustomBlockEmbed {
  static const String calloutType = 'callout';

  CalloutBlockEmbed(String data) : super(calloutType, data);

  factory CalloutBlockEmbed.fromAttributes({
    required String text,
    String icon = '💡',
    String colorHex = '#6366F1',
  }) {
    final map = <String, dynamic>{
      'text': text,
      'icon': icon,
      'colorHex': colorHex,
    };
    return CalloutBlockEmbed(jsonEncode(map));
  }

  factory CalloutBlockEmbed.fromData(dynamic rawData) {
    if (rawData is Map) {
      if (rawData.containsKey(calloutType)) {
        return CalloutBlockEmbed.fromData(rawData[calloutType]);
      }
      return CalloutBlockEmbed.fromAttributes(
        text: rawData['text'] as String? ?? '',
        icon: rawData['icon'] as String? ?? '💡',
        colorHex: rawData['colorHex'] as String? ?? '#6366F1',
      );
    } else if (rawData is String) {
      try {
        final decoded = jsonDecode(rawData);
        if (decoded is Map || decoded is String) {
          return CalloutBlockEmbed.fromData(decoded);
        }
      } catch (_) {}
      return CalloutBlockEmbed.fromAttributes(text: rawData);
    }
    return CalloutBlockEmbed.fromAttributes(text: '');
  }

  Map<String, dynamic> toMap() {
    try {
      dynamic current = jsonDecode(data);
      if (current is String) {
        try {
          current = jsonDecode(current);
        } catch (_) {}
      }
      if (current is Map) {
        if (current.containsKey(calloutType)) {
          final inner = current[calloutType];
          if (inner is String) {
            try {
              return jsonDecode(inner) as Map<String, dynamic>;
            } catch (_) {}
          } else if (inner is Map) {
            return Map<String, dynamic>.from(inner);
          }
        }
        return Map<String, dynamic>.from(current);
      }
    } catch (_) {}
    return {'text': data, 'icon': '💡', 'colorHex': '#6366F1'};
  }

  String get text => toMap()['text'] as String? ?? '';
  String get icon => toMap()['icon'] as String? ?? '💡';
  String get colorHex => toMap()['colorHex'] as String? ?? '#6366F1';

  CalloutBlockEmbed copyWith({String? text, String? icon, String? colorHex}) {
    return CalloutBlockEmbed.fromAttributes(
      text: text ?? this.text,
      icon: icon ?? this.icon,
      colorHex: colorHex ?? this.colorHex,
    );
  }
}

/// Custom block embed for inline vector ink sketch canvas blocks.
///
/// Contains [inkHash] (CAS content hash of `.atlas_ink` strokes) and [height].
class InkBlockEmbed extends CustomBlockEmbed {
  static const String inkBlockType = 'ink_block';

  InkBlockEmbed(String data) : super(inkBlockType, data);

  factory InkBlockEmbed.fromAttributes({
    required String inkHash,
    double height = 240.0,
    double? width,
  }) {
    final map = <String, dynamic>{'inkHash': inkHash, 'height': height};
    if (width != null) {
      map['width'] = width;
    }
    return InkBlockEmbed(jsonEncode(map));
  }

  factory InkBlockEmbed.fromData(dynamic rawData) {
    if (rawData is Map) {
      if (rawData.containsKey(inkBlockType)) {
        return InkBlockEmbed.fromData(rawData[inkBlockType]);
      }
      return InkBlockEmbed.fromAttributes(
        inkHash: rawData['inkHash'] as String? ?? '',
        height: (rawData['height'] as num?)?.toDouble() ?? 240.0,
        width: (rawData['width'] as num?)?.toDouble(),
      );
    } else if (rawData is String) {
      try {
        final decoded = jsonDecode(rawData);
        if (decoded is Map || decoded is String) {
          return InkBlockEmbed.fromData(decoded);
        }
      } catch (_) {}
      return InkBlockEmbed.fromAttributes(inkHash: rawData);
    }
    return InkBlockEmbed.fromAttributes(inkHash: '');
  }

  Map<String, dynamic> toMap() {
    try {
      dynamic current = jsonDecode(data);
      if (current is String) {
        try {
          current = jsonDecode(current);
        } catch (_) {}
      }
      if (current is Map) {
        if (current.containsKey(inkBlockType)) {
          final inner = current[inkBlockType];
          if (inner is String) {
            try {
              return jsonDecode(inner) as Map<String, dynamic>;
            } catch (_) {}
          } else if (inner is Map) {
            return Map<String, dynamic>.from(inner);
          }
        }
        return Map<String, dynamic>.from(current);
      }
    } catch (_) {}
    return {'inkHash': data, 'height': 240.0};
  }

  String get inkHash => toMap()['inkHash'] as String? ?? '';
  double get height => (toMap()['height'] as num?)?.toDouble() ?? 240.0;
  double? get width => (toMap()['width'] as num?)?.toDouble();

  InkBlockEmbed copyWith({String? inkHash, double? height, double? width}) {
    return InkBlockEmbed.fromAttributes(
      inkHash: inkHash ?? this.inkHash,
      height: height ?? this.height,
      width: width ?? this.width,
    );
  }
}

/// Custom block embed for inline actionable tasks connected to SQLite.
class TaskBlockEmbed extends CustomBlockEmbed {
  static const String taskBlockType = 'task_block';

  TaskBlockEmbed(String data) : super(taskBlockType, data);

  factory TaskBlockEmbed.fromAttributes({
    required String taskId,
    required String title,
    bool isCompleted = false,
    String priority = 'medium',
  }) {
    final map = <String, dynamic>{
      'taskId': taskId,
      'title': title,
      'isCompleted': isCompleted,
      'priority': priority,
    };
    return TaskBlockEmbed(jsonEncode(map));
  }

  factory TaskBlockEmbed.fromData(dynamic rawData) {
    if (rawData is Map) {
      if (rawData.containsKey(taskBlockType)) {
        return TaskBlockEmbed.fromData(rawData[taskBlockType]);
      }
      return TaskBlockEmbed.fromAttributes(
        taskId: rawData['taskId'] as String? ?? '',
        title: rawData['title'] as String? ?? '',
        isCompleted: rawData['isCompleted'] as bool? ?? false,
        priority: rawData['priority'] as String? ?? 'medium',
      );
    } else if (rawData is String) {
      try {
        final decoded = jsonDecode(rawData);
        if (decoded is Map || decoded is String) {
          return TaskBlockEmbed.fromData(decoded);
        }
      } catch (_) {}
      return TaskBlockEmbed.fromAttributes(taskId: rawData, title: rawData);
    }
    return TaskBlockEmbed.fromAttributes(taskId: '', title: '');
  }

  Map<String, dynamic> toMap() {
    try {
      dynamic current = jsonDecode(data);
      if (current is String) {
        try {
          current = jsonDecode(current);
        } catch (_) {}
      }
      if (current is Map) {
        if (current.containsKey(taskBlockType)) {
          final inner = current[taskBlockType];
          if (inner is String) {
            try {
              return jsonDecode(inner) as Map<String, dynamic>;
            } catch (_) {}
          } else if (inner is Map) {
            return Map<String, dynamic>.from(inner);
          }
        }
        return Map<String, dynamic>.from(current);
      }
    } catch (_) {}
    return {
      'taskId': data,
      'title': data,
      'isCompleted': false,
      'priority': 'medium',
    };
  }

  String get taskId => toMap()['taskId'] as String? ?? '';
  String get title => toMap()['title'] as String? ?? '';
  bool get isCompleted => toMap()['isCompleted'] as bool? ?? false;
  String get priority => toMap()['priority'] as String? ?? 'medium';

  TaskBlockEmbed copyWith({
    String? taskId,
    String? title,
    bool? isCompleted,
    String? priority,
  }) {
    return TaskBlockEmbed.fromAttributes(
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
    );
  }
}

/// Custom block embed for dividers.
class DividerBlockEmbed extends CustomBlockEmbed {
  static const String dividerType = 'divider';

  DividerBlockEmbed([String value = 'hr']) : super(dividerType, value);
}
