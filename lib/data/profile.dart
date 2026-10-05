import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/sfx.dart';

/// Names and app preferences.
class Profile {
  const Profile({this.name = '', this.catName = 'Mochi', this.sound = true});

  /// The user's first name; empty until they set it.
  final String name;
  final String catName;
  final bool sound;

  Profile copyWith({String? name, String? catName, bool? sound}) => Profile(
    name: name ?? this.name,
    catName: catName ?? this.catName,
    sound: sound ?? this.sound,
  );

  Map<String, Object?> toJson() => {
    'name': name,
    'catName': catName,
    'sound': sound,
  };

  factory Profile.fromJson(Map<String, Object?> j) => Profile(
    name: j['name'] as String? ?? '',
    catName: j['catName'] as String? ?? 'Mochi',
    sound: j['sound'] as bool? ?? true,
  );
}

final profileProvider = NotifierProvider<ProfileNotifier, Profile>(
  ProfileNotifier.new,
);

class ProfileNotifier extends Notifier<Profile> {
  static const _key = 'avelo.profile.v1';

  @override
  Profile build() {
    _load();
    return const Profile();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      state = Profile.fromJson(jsonDecode(raw) as Map<String, Object?>);
      SfxPlayer.instance.enabled = state.sound;
    }
  }

  Future<void> update(Profile p) async {
    state = p;
    SfxPlayer.instance.enabled = p.sound;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(p.toJson()));
  }
}
