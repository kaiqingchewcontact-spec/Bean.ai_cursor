import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/bean.dart';
import '../models/brew.dart';
import '../models/tasting_note.dart';
import '../models/user_profile.dart';
import '../models/roaster.dart';

class StorageService {
  static const String _beansBox = 'beans';
  static const String _brewsBox = 'brews';
  static const String _tastingNotesBox = 'tasting_notes';
  static const String _userBox = 'user';
  static const String _subscriptionsBox = 'subscriptions';
  static const String _settingsBox = 'settings';

  late Box<String> _beans;
  late Box<String> _brews;
  late Box<String> _tastingNotes;
  late Box<String> _user;
  late Box<String> _subscriptions;
  late Box<String> _settings;

  Future<void> init() async {
    await Hive.initFlutter();
    _beans = await Hive.openBox<String>(_beansBox);
    _brews = await Hive.openBox<String>(_brewsBox);
    _tastingNotes = await Hive.openBox<String>(_tastingNotesBox);
    _user = await Hive.openBox<String>(_userBox);
    _subscriptions = await Hive.openBox<String>(_subscriptionsBox);
    _settings = await Hive.openBox<String>(_settingsBox);
  }

  // Beans
  Future<void> saveBean(Bean bean) async {
    await _beans.put(bean.id, jsonEncode(bean.toJson()));
  }

  Future<void> deleteBean(String id) async {
    await _beans.delete(id);
  }

  List<Bean> getAllBeans() {
    return _beans.values
        .map((json) => Bean.fromJson(jsonDecode(json) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.addedDate.compareTo(a.addedDate));
  }

  Bean? getBean(String id) {
    final json = _beans.get(id);
    if (json == null) return null;
    return Bean.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  List<Bean> getActiveBeans() {
    return getAllBeans().where((b) => !b.isArchived).toList();
  }

  List<Bean> getFavoriteBeans() {
    return getAllBeans().where((b) => b.isFavorite).toList();
  }

  // Brews
  Future<void> saveBrew(Brew brew) async {
    await _brews.put(brew.id, jsonEncode(brew.toJson()));
  }

  Future<void> deleteBrew(String id) async {
    await _brews.delete(id);
  }

  List<Brew> getAllBrews() {
    return _brews.values
        .map((json) => Brew.fromJson(jsonDecode(json) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.brewDate.compareTo(a.brewDate));
  }

  List<Brew> getBrewsForBean(String beanId) {
    return getAllBrews().where((b) => b.beanId == beanId).toList();
  }

  Brew? getBrew(String id) {
    final json = _brews.get(id);
    if (json == null) return null;
    return Brew.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  // Tasting Notes
  Future<void> saveTastingNote(TastingNote note) async {
    await _tastingNotes.put(note.id, jsonEncode(note.toJson()));
  }

  Future<void> deleteTastingNote(String id) async {
    await _tastingNotes.delete(id);
  }

  List<TastingNote> getAllTastingNotes() {
    return _tastingNotes.values
        .map((json) =>
            TastingNote.fromJson(jsonDecode(json) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<TastingNote> getTastingNotesForBean(String beanId) {
    return getAllTastingNotes().where((n) => n.beanId == beanId).toList();
  }

  // User Profile
  Future<void> saveUserProfile(UserProfile profile) async {
    await _user.put('profile', jsonEncode(profile.toJson()));
  }

  UserProfile? getUserProfile() {
    final json = _user.get('profile');
    if (json == null) return null;
    return UserProfile.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  // Subscriptions
  Future<void> saveSubscription(Subscription sub) async {
    await _subscriptions.put(sub.id, jsonEncode(sub.toJson()));
  }

  Future<void> deleteSubscription(String id) async {
    await _subscriptions.delete(id);
  }

  List<Subscription> getAllSubscriptions() {
    return _subscriptions.values
        .map((json) =>
            Subscription.fromJson(jsonDecode(json) as Map<String, dynamic>))
        .toList();
  }

  // Settings
  Future<void> setSetting(String key, String value) async {
    await _settings.put(key, value);
  }

  String? getSetting(String key) => _settings.get(key);

  bool get isOnboardingComplete =>
      getSetting('onboarding_complete') == 'true';

  Future<void> setOnboardingComplete() async {
    await setSetting('onboarding_complete', 'true');
  }

  Future<void> clearOnboardingFlag() async {
    await _settings.delete('onboarding_complete');
  }

  Future<void> clearAll() async {
    await _beans.clear();
    await _brews.clear();
    await _tastingNotes.clear();
    await _subscriptions.clear();
  }
}
