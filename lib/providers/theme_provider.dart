import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import 'storage_provider.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ThemeNotifier(storage);
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final StorageService _storage;

  ThemeNotifier(this._storage)
      : super(_storage.getIsDarkMode() ? ThemeMode.dark : ThemeMode.light);

  void toggleTheme() {
    final newMode =
        state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    state = newMode;
    _storage.setDarkMode(newMode == ThemeMode.dark);
  }

  void setTheme(ThemeMode mode) {
    state = mode;
    _storage.setDarkMode(mode == ThemeMode.dark);
  }
}
