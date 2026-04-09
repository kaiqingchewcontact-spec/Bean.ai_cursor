import 'package:flutter/material.dart';

import '../models/bean.dart';
import '../models/brew.dart';
import '../models/tasting_note.dart';
import '../models/user_profile.dart';
import '../models/roaster.dart';
import '../services/storage_service.dart';
import '../services/ai_service.dart';
import '../config/constants.dart';

class AppState extends ChangeNotifier {
  final StorageService _storage;
  final AiService _aiService;

  List<Bean> _beans = [];
  List<Brew> _brews = [];
  List<TastingNote> _tastingNotes = [];
  List<Subscription> _subscriptions = [];
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _error;

  AppState({
    required StorageService storage,
    required AiService aiService,
  })  : _storage = storage,
        _aiService = aiService;

  // Getters
  List<Bean> get beans => _beans;
  List<Bean> get activeBeans => _beans.where((b) => !b.isArchived).toList();
  List<Bean> get favoriteBeans => _beans.where((b) => b.isFavorite).toList();
  List<Bean> get freshBeans => activeBeans
      .where((b) =>
          b.freshnessLevel == FreshnessLevel.peak ||
          b.freshnessLevel == FreshnessLevel.fresh)
      .toList();
  List<Bean> get agingBeans => activeBeans
      .where((b) =>
          b.freshnessLevel == FreshnessLevel.aging ||
          b.freshnessLevel == FreshnessLevel.stale)
      .toList();

  List<Brew> get brews => _brews;
  List<Brew> get recentBrews => _brews.take(10).toList();
  List<TastingNote> get tastingNotes => _tastingNotes;
  List<Subscription> get subscriptions => _subscriptions;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isPremium => _userProfile?.isPremium ?? false;
  AiService get aiService => _aiService;

  int get totalBrewsThisWeek {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return _brews.where((b) => b.brewDate.isAfter(weekAgo)).length;
  }

  double get averageRating {
    if (_brews.isEmpty) return 0;
    final rated = _brews.where((b) => b.rating > 0);
    if (rated.isEmpty) return 0;
    return rated.map((b) => b.rating).reduce((a, b) => a + b) / rated.length;
  }

  bool canAddBean() {
    if (isPremium) return true;
    return _beans.length < AppConstants.freeBeansLimit;
  }

  bool canLogBrew() {
    if (isPremium) return true;
    return _brews.length < AppConstants.freeBrewLogsLimit;
  }

  // Initialization
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _beans = _storage.getAllBeans();
      _brews = _storage.getAllBrews();
      _tastingNotes = _storage.getAllTastingNotes();
      _subscriptions = _storage.getAllSubscriptions();
      _userProfile = _storage.getUserProfile();
      _error = null;
    } catch (e) {
      _error = 'Failed to load data: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Bean operations
  Future<void> addBean(Bean bean) async {
    await _storage.saveBean(bean);
    _beans = _storage.getAllBeans();
    notifyListeners();
  }

  Future<void> updateBean(Bean bean) async {
    await _storage.saveBean(bean);
    _beans = _storage.getAllBeans();
    notifyListeners();
  }

  Future<void> deleteBean(String id) async {
    await _storage.deleteBean(id);
    _beans = _storage.getAllBeans();
    notifyListeners();
  }

  Future<void> toggleFavorite(String beanId) async {
    final bean = _beans.firstWhere((b) => b.id == beanId);
    await updateBean(bean.copyWith(isFavorite: !bean.isFavorite));
  }

  Future<void> archiveBean(String beanId) async {
    final bean = _beans.firstWhere((b) => b.id == beanId);
    await updateBean(bean.copyWith(isArchived: !bean.isArchived));
  }

  // Brew operations
  Future<void> addBrew(Brew brew) async {
    await _storage.saveBrew(brew);
    _brews = _storage.getAllBrews();

    final beanIndex = _beans.indexWhere((b) => b.id == brew.beanId);
    if (beanIndex >= 0) {
      final bean = _beans[beanIndex];
      await updateBean(bean.copyWith(brewCount: bean.brewCount + 1));
    }

    notifyListeners();
  }

  Future<void> updateBrew(Brew brew) async {
    await _storage.saveBrew(brew);
    _brews = _storage.getAllBrews();
    notifyListeners();
  }

  Future<void> deleteBrew(String id) async {
    await _storage.deleteBrew(id);
    _brews = _storage.getAllBrews();
    notifyListeners();
  }

  List<Brew> getBrewsForBean(String beanId) {
    return _brews.where((b) => b.beanId == beanId).toList();
  }

  // Tasting Note operations
  Future<void> addTastingNote(TastingNote note) async {
    await _storage.saveTastingNote(note);
    _tastingNotes = _storage.getAllTastingNotes();
    notifyListeners();
  }

  Future<void> deleteTastingNote(String id) async {
    await _storage.deleteTastingNote(id);
    _tastingNotes = _storage.getAllTastingNotes();
    notifyListeners();
  }

  // User Profile
  Future<void> updateProfile(UserProfile profile) async {
    await _storage.saveUserProfile(profile);
    _userProfile = profile;
    notifyListeners();
  }

  Future<void> updateEquipment(UserEquipment equipment) async {
    if (_userProfile != null) {
      await updateProfile(_userProfile!.copyWith(equipment: equipment));
    }
  }

  Future<void> updatePreferences(UserPreferences preferences) async {
    if (_userProfile != null) {
      await updateProfile(_userProfile!.copyWith(preferences: preferences));
    }
  }

  // Subscription operations
  Future<void> addSubscription(Subscription sub) async {
    await _storage.saveSubscription(sub);
    _subscriptions = _storage.getAllSubscriptions();
    notifyListeners();
  }

  Future<void> deleteSubscription(String id) async {
    await _storage.deleteSubscription(id);
    _subscriptions = _storage.getAllSubscriptions();
    notifyListeners();
  }

  // AI operations
  Future<Map<String, dynamic>> getBrewRecipe(Bean bean, String method) async {
    return _aiService.generateBrewRecipe(
      bean: bean,
      method: method,
      grinder: _userProfile?.equipment.grinder,
      preferences: {
        'flavor_preferences': _userProfile?.preferences.flavorPreferences,
      },
    );
  }

  Future<Map<String, dynamic>> getBrewFeedback(Brew brew, double rating) async {
    final bean = _beans.firstWhere((b) => b.id == brew.beanId);
    return _aiService.analyzeBrewFeedback(
      brew: brew,
      bean: bean,
      rating: rating,
    );
  }

  Future<Map<String, dynamic>> getPalateInsights() async {
    return _aiService.generatePalateInsights(
      notes: _tastingNotes,
      beans: _beans,
      brews: _brews,
    );
  }

  Bean? getBeanById(String id) {
    try {
      return _beans.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }
}
