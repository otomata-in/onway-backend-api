import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import '../models/teritory_models.dart';

class TeritoryDataService extends ChangeNotifier {
  static final TeritoryDataService instance = TeritoryDataService._internal();
  TeritoryDataService._internal();

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  late CurrentUserProfile _currentUser;
  List<FlagItem> _userFlags = [];
  List<FriendFlag> _friendFlags = [];
  List<MajorWonder> _majorWonders = [];
  List<TravelTribe> _travelTribes = [];

  CurrentUserProfile get currentUser => _currentUser;
  List<FlagItem> get userFlags => List.unmodifiable(_userFlags);
  List<FriendFlag> get friendFlags => List.unmodifiable(_friendFlags);
  List<MajorWonder> get majorWonders => List.unmodifiable(_majorWonders);
  List<TravelTribe> get travelTribes => List.unmodifiable(_travelTribes);

  // Filtered queries
  List<FlagItem> get majorFlags =>
      _userFlags.where((f) => f.isMajorFlag).toList();

  Future<void> initialize() async {
    if (_isLoaded) return;
    try {
      final jsonString =
          await rootBundle.loadString('assets/data/teritory_data.json');
      final data = json.decode(jsonString) as Map<String, dynamic>;

      _currentUser = CurrentUserProfile.fromJson(
          data['currentUser'] as Map<String, dynamic>);

      _userFlags = (data['userFlags'] as List<dynamic>? ?? [])
          .map((f) => FlagItem.fromJson(f as Map<String, dynamic>))
          .toList();

      _friendFlags = (data['friendFlags'] as List<dynamic>? ?? [])
          .map((f) => FriendFlag.fromJson(f as Map<String, dynamic>))
          .toList();

      _majorWonders = (data['majorWonders'] as List<dynamic>? ?? [])
          .map((w) => MajorWonder.fromJson(w as Map<String, dynamic>))
          .toList();

      _travelTribes = (data['travelTribes'] as List<dynamic>? ?? [])
          .map((t) => TravelTribe.fromJson(t as Map<String, dynamic>))
          .toList();

      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading Teritory data: $e');
    }
  }

  void addFlag({
    required String placeName,
    required String city,
    required String country,
    required LatLng coordinates,
    required bool isMajorFlag,
    required String category,
    required String notes,
    String? photoUrl,
  }) {
    final newFlag = FlagItem(
      id: 'f_user_${DateTime.now().millisecondsSinceEpoch}',
      placeName: placeName,
      city: city,
      country: country,
      countryCode: country.length >= 2
          ? country.substring(0, 2).toUpperCase()
          : 'GL',
      continent: 'Asia',
      latitude: coordinates.latitude,
      longitude: coordinates.longitude,
      isMajorFlag: isMajorFlag,
      category: category,
      flaggedDate: 'Just now',
      notes: notes,
      photoUrl: photoUrl ??
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80',
      kudos: 1,
    );

    _userFlags.insert(0, newFlag);

    // Update user stats
    final updatedStats = _currentUser.stats.copyWith(
      totalFlags: _currentUser.stats.totalFlags + 1,
      majorFlags: isMajorFlag
          ? _currentUser.stats.majorFlags + 1
          : _currentUser.stats.majorFlags,
    );

    _currentUser = _currentUser.copyWith(
      stats: updatedStats,
      xp: _currentUser.xp + (isMajorFlag ? 150 : 50),
    );

    notifyListeners();
  }
}
