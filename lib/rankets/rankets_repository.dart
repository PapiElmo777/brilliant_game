import '../auth/auth_repository.dart';

class RankedPlayer {
  final String userId, username;
  final String? avatarId;
  final int position, wins;
  final Map<String, int> winsByLevel;
  RankedPlayer.fromJson(Map<String, dynamic> json)
    : userId = json['userId'] as String,
      username = json['username'] as String,
      avatarId = json['avatarId'] as String?,
      position = json['position'] as int,
      wins = json['wins'] as int,
      winsByLevel = Map.unmodifiable(
        (json['winsByLevel'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, value as int),
        ),
      );
}

class RanketsPageData {
  final List<RankedPlayer> entries;
  final RankedPlayer? me;
  final int total, offset;
  RanketsPageData.fromJson(Map<String, dynamic> json)
    : entries = List.unmodifiable(
        (json['entries'] as List).map(
          (entry) => RankedPlayer.fromJson(entry as Map<String, dynamic>),
        ),
      ),
      me = json['me'] == null
          ? null
          : RankedPlayer.fromJson(json['me'] as Map<String, dynamic>),
      total = json['total'] as int,
      offset = json['offset'] as int;
}

abstract interface class RanketsRepository {
  Future<RanketsPageData> list(String token, {int offset = 0});
  void close();
}

class HttpRanketsRepository implements RanketsRepository {
  final HttpAuthRepository _http;
  HttpRanketsRepository({required Uri baseUrl})
    : _http = HttpAuthRepository(baseUrl: baseUrl);
  @override
  Future<RanketsPageData> list(String token, {int offset = 0}) async {
    final json = await _http.sendJson(
      'GET',
      'rankets',
      200,
      token: token,
      query: {'offset': '$offset', 'limit': '25'},
    );
    try {
      return RanketsPageData.fromJson(json!);
    } on Object {
      throw const AuthFailure('SERVER_ERROR');
    }
  }

  @override
  void close() => _http.close();
}
