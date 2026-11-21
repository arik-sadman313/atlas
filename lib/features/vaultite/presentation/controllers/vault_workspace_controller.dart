import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/vault_tab.dart';

class VaultWorkspaceState {
  final List<VaultTab> tabs;
  final int activeTabIndex;
  final bool isLeftSidebarVisible;
  final bool isRightInspectorVisible;
  final int activeInspectorTab; // 0: Backlinks, 1: Mentions, 2: Outline, 3: Graph
  final bool isSplitViewActive;
  final int? secondaryTabIndex;

  const VaultWorkspaceState({
    this.tabs = const [],
    this.activeTabIndex = 0,
    this.isLeftSidebarVisible = true,
    this.isRightInspectorVisible = true,
    this.activeInspectorTab = 0,
    this.isSplitViewActive = false,
    this.secondaryTabIndex,
  });

  VaultTab? get activeTab =>
      (tabs.isNotEmpty && activeTabIndex >= 0 && activeTabIndex < tabs.length)
          ? tabs[activeTabIndex]
          : null;

  VaultTab? get secondaryTab {
    if (!isSplitViewActive || secondaryTabIndex == null) return null;
    final idx = secondaryTabIndex!;
    return (idx >= 0 && idx < tabs.length) ? tabs[idx] : null;
  }

  VaultWorkspaceState copyWith({
    List<VaultTab>? tabs,
    int? activeTabIndex,
    bool? isLeftSidebarVisible,
    bool? isRightInspectorVisible,
    int? activeInspectorTab,
    bool? isSplitViewActive,
    int? Function()? secondaryTabIndex,
  }) {
    return VaultWorkspaceState(
      tabs: tabs ?? this.tabs,
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
      isLeftSidebarVisible: isLeftSidebarVisible ?? this.isLeftSidebarVisible,
      isRightInspectorVisible:
          isRightInspectorVisible ?? this.isRightInspectorVisible,
      activeInspectorTab: activeInspectorTab ?? this.activeInspectorTab,
      isSplitViewActive: isSplitViewActive ?? this.isSplitViewActive,
      secondaryTabIndex: secondaryTabIndex != null
          ? secondaryTabIndex()
          : this.secondaryTabIndex,
    );
  }
}

class VaultWorkspaceNotifier extends Notifier<VaultWorkspaceState> {
  @override
  VaultWorkspaceState build() => const VaultWorkspaceState();

  void openNode({
    required String id,
    required String title,
    required String type,
  }) {
    final existingIndex = state.tabs.indexWhere((t) => t.nodeId == id);
    if (existingIndex >= 0) {
      state = state.copyWith(activeTabIndex: existingIndex);
      return;
    }

    final newTab = VaultTab(
      id: 'tab_${DateTime.now().millisecondsSinceEpoch}',
      nodeId: id,
      title: title,
      type: type,
      path: type == 'notebook' ? '$title.notebook' : '$title.md',
    );

    final updatedTabs = [...state.tabs, newTab];
    state = state.copyWith(
      tabs: updatedTabs,
      activeTabIndex: updatedTabs.length - 1,
    );
  }

  void closeTab(int index) {
    if (index < 0 || index >= state.tabs.length) return;
    final updatedTabs = List<VaultTab>.from(state.tabs)..removeAt(index);

    var newActive = state.activeTabIndex;
    if (newActive >= updatedTabs.length) {
      newActive = updatedTabs.length - 1;
    }

    state = state.copyWith(
      tabs: updatedTabs,
      activeTabIndex: newActive,
      secondaryTabIndex: () => null,
      isSplitViewActive: false,
    );
  }

  void selectTab(int index) {
    if (index >= 0 && index < state.tabs.length) {
      state = state.copyWith(activeTabIndex: index);
    }
  }

  void toggleLeftSidebar() {
    state = state.copyWith(isLeftSidebarVisible: !state.isLeftSidebarVisible);
  }

  void toggleRightInspector() {
    state = state.copyWith(
      isRightInspectorVisible: !state.isRightInspectorVisible,
    );
  }

  void setInspectorTab(int tabIndex) {
    state = state.copyWith(
      activeInspectorTab: tabIndex,
      isRightInspectorVisible: true,
    );
  }

  void toggleSplitView() {
    if (state.tabs.length < 2) return;
    if (state.isSplitViewActive) {
      state = state.copyWith(
        isSplitViewActive: false,
        secondaryTabIndex: () => null,
      );
    } else {
      final sec = (state.activeTabIndex == 0) ? 1 : 0;
      state = state.copyWith(
        isSplitViewActive: true,
        secondaryTabIndex: () => sec,
      );
    }
  }

  void updateTabTitle(String nodeId, String newTitle) {
    final updated = state.tabs.map((tab) {
      if (tab.nodeId == nodeId) {
        return tab.copyWith(
          title: newTitle,
          path: tab.isNotebook ? '$newTitle.notebook' : '$newTitle.md',
        );
      }
      return tab;
    }).toList();
    state = state.copyWith(tabs: updated);
  }
}

final vaultWorkspaceProvider =
    NotifierProvider<VaultWorkspaceNotifier, VaultWorkspaceState>(
      VaultWorkspaceNotifier.new,
    );
