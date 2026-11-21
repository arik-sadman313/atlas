import 'package:flutter/material.dart';

class AtlasNavigationItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;

  const AtlasNavigationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
  });
}

const atlasNavigationItems = [
  AtlasNavigationItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
    route: '/dashboard',
  ),
  AtlasNavigationItem(
    label: 'Notebooks',
    icon: Icons.draw_outlined,
    selectedIcon: Icons.draw_rounded,
    route: '/notebooks',
  ),
  AtlasNavigationItem(
    label: 'Documents & Vault',
    icon: Icons.folder_special_outlined,
    selectedIcon: Icons.folder_special,
    route: '/documents',
  ),
  AtlasNavigationItem(
    label: 'Tasks',
    icon: Icons.check_circle_outline,
    selectedIcon: Icons.check_circle,
    route: '/tasks',
  ),
  AtlasNavigationItem(
    label: 'Calendar',
    icon: Icons.calendar_today_outlined,
    selectedIcon: Icons.calendar_today,
    route: '/calendar',
  ),
  AtlasNavigationItem(
    label: 'Graph',
    icon: Icons.hub_outlined,
    selectedIcon: Icons.hub,
    route: '/graph',
  ),
  AtlasNavigationItem(
    label: 'Search',
    icon: Icons.search_outlined,
    selectedIcon: Icons.search,
    route: '/search',
  ),
  AtlasNavigationItem(
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    route: '/settings',
  ),
];
