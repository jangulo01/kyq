import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_ptt/kyq_ptt.dart';

import 'platform_hands_free.dart';

@immutable
class HandsFreeSettingsState {
  const HandsFreeSettingsState({
    this.mediaButton = true,
    this.bubble = true,
    this.overlayGranted = false,
    this.loaded = false,
  });

  /// Capturar el botón del auricular o del volante.
  final bool mediaButton;

  /// El conductor quiere la burbuja; solo se muestra con [overlayGranted].
  final bool bubble;
  final bool overlayGranted;
  final bool loaded;

  bool get bubbleActive => bubble && overlayGranted;

  HandsFreeSettingsState copyWith({bool? mediaButton, bool? bubble, bool? overlayGranted}) => HandsFreeSettingsState(
    mediaButton: mediaButton ?? this.mediaButton,
    bubble: bubble ?? this.bubble,
    overlayGranted: overlayGranted ?? this.overlayGranted,
    loaded: true,
  );

  @override
  bool operator ==(Object other) =>
      other is HandsFreeSettingsState &&
      other.mediaButton == mediaButton &&
      other.bubble == bubble &&
      other.overlayGranted == overlayGranted &&
      other.loaded == loaded;

  @override
  int get hashCode => Object.hash(mediaButton, bubble, overlayGranted, loaded);
}

/// Preferencias del botón físico y la burbuja (FR-015), aplicadas a [HandsFreePtt].
class HandsFreeSettingsCubit extends Cubit<HandsFreeSettingsState> {
  HandsFreeSettingsCubit({required this._store, required this._overlay, required this._handsFree})
    : super(const HandsFreeSettingsState());

  final HandsFreePrefsStore _store;
  final OverlayPermission _overlay;
  final HandsFreePtt _handsFree;

  Future<void> load() async {
    try {
      final prefs = await _store.load();
      final granted = await _overlay.isGranted();
      _apply(state.copyWith(mediaButton: prefs.mediaButton, bubble: prefs.bubble, overlayGranted: granted));
    } on Object catch (e) {
      debugPrint('Manos libres: $e');
      _apply(state.copyWith());
    }
  }

  /// Al volver a la app: el conductor pudo conceder o quitar el permiso en los ajustes.
  Future<void> refreshPermission() async {
    try {
      _apply(state.copyWith(overlayGranted: await _overlay.isGranted()));
    } on Object catch (e) {
      debugPrint('Manos libres: $e');
    }
  }

  Future<void> setMediaButton(bool on) async {
    _apply(state.copyWith(mediaButton: on));
    await _save();
  }

  /// Activar la burbuja pide el permiso de superposición si falta (FR-014).
  Future<void> setBubble(bool on) async {
    var granted = state.overlayGranted;
    if (on && !granted) {
      try {
        granted = await _overlay.request();
      } on Object catch (e) {
        debugPrint('Manos libres: $e');
      }
    }
    _apply(state.copyWith(bubble: on, overlayGranted: granted));
    await _save();
  }

  Future<void> _save() async {
    try {
      await _store.save((mediaButton: state.mediaButton, bubble: state.bubble));
    } on Object catch (e) {
      debugPrint('Manos libres: $e');
    }
  }

  void _apply(HandsFreeSettingsState s) {
    if (isClosed) return;
    emit(s);
    _handsFree.configure(mediaButton: s.mediaButton, bubble: s.bubbleActive);
  }
}
