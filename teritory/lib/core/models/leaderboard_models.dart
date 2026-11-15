enum LeaderboardScope {
  global,
  country,
  state,
  district,
  friends,
  clan,
  community,
}

enum LeaderboardPeriod { alltime, month, week }

class LeaderboardEntry {
  final String id;
  final String userId;
  final String userName;
  final String userHandle;
  final String userAvatar;
  final LeaderboardScope scope;
  final LeaderboardPeriod period;
  final int rank;
  final int compositeScore;
  final int totalFlags;
  final int majorFlags;
  final int countriesVisited;
  final int continentsExplored;
  final int completedTrips;
  final int legendaryRallies;
  final int communityContributions;
  final int streakDays;

  const LeaderboardEntry({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userHandle,
    required this.userAvatar,
    this.scope = LeaderboardScope.global,
    this.period = LeaderboardPeriod.alltime,
    required this.rank,
    required this.compositeScore,
    this.totalFlags = 0,
    this.majorFlags = 0,
    this.countriesVisited = 0,
    this.continentsExplored = 0,
    this.completedTrips = 0,
    this.legendaryRallies = 0,
    this.communityContributions = 0,
    this.streakDays = 0,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      id: json['id'] as String? ?? json['userId'] as String? ?? '',
      userId: json['userId'] as String? ?? json['id'] as String? ?? '',
      userName: json['userName'] as String? ?? json['displayName'] as String? ?? 'Traveler',
      userHandle: json['userHandle'] as String? ?? json['handle'] as String? ?? 'traveler',
      userAvatar: json['userAvatar'] as String? ?? json['avatarUrl'] as String? ?? '',
      scope: LeaderboardScope.values.firstWhere(
        (e) => e.name.toLowerCase() == (json['scope'] as String? ?? 'global').toLowerCase(),
        orElse: () => LeaderboardScope.global,
      ),
      period: LeaderboardPeriod.values.firstWhere(
        (e) => e.name.toLowerCase() == (json['period'] as String? ?? 'alltime').toLowerCase(),
        orElse: () => LeaderboardPeriod.alltime,
      ),
      rank: json['rank'] as int? ?? 1,
      compositeScore: json['compositeScore'] as int? ?? json['score'] as int? ?? 0,
      totalFlags: json['totalFlags'] as int? ?? 0,
      majorFlags: json['majorFlags'] as int? ?? 0,
      countriesVisited: json['countriesVisited'] as int? ?? 0,
      continentsExplored: json['continentsExplored'] as int? ?? 0,
      completedTrips: json['completedTrips'] as int? ?? json['completedTripsCount'] as int? ?? 0,
      legendaryRallies: json['legendaryRallies'] as int? ?? json['legendaryRalliesCount'] as int? ?? 0,
      communityContributions:
          json['communityContributions'] as int? ?? 0,
      streakDays: json['streakDays'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'userName': userName,
        'userHandle': userHandle,
        'userAvatar': userAvatar,
        'scope': scope.name,
        'period': period.name,
        'rank': rank,
        'compositeScore': compositeScore,
        'totalFlags': totalFlags,
        'majorFlags': majorFlags,
        'countriesVisited': countriesVisited,
        'continentsExplored': continentsExplored,
        'completedTrips': completedTrips,
        'legendaryRallies': legendaryRallies,
        'communityContributions': communityContributions,
        'streakDays': streakDays,
      };
}
