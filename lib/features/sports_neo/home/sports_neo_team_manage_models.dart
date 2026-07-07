import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';

class SportsNeoManagedPlayer {
  const SportsNeoManagedPlayer({
    required this.id,
    required this.name,
    required this.contactNumber,
    required this.email,
    required this.playerType,
    required this.isGuest,
  });

  factory SportsNeoManagedPlayer.fromMap(Map<String, dynamic> map) {
    return SportsNeoManagedPlayer(
      id: map['_id']?.toString() ?? map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Unknown Player',
      contactNumber: map['contactNumber']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      playerType: map['playerType']?.toString() ?? '',
      isGuest: map['isGuest'] == true,
    );
  }

  final String id;
  final String name;
  final String contactNumber;
  final String email;
  final String playerType;
  final bool isGuest;
}

class SportsNeoManagedTeam {
  const SportsNeoManagedTeam({
    required this.id,
    required this.name,
    required this.players,
    required this.createdAt,
  });

  factory SportsNeoManagedTeam.fromMap(Map<String, dynamic> map) {
    final List<dynamic> rawPlayers = (map['players'] as List?) ?? <dynamic>[];
    return SportsNeoManagedTeam(
      id: map['_id']?.toString() ?? map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Untitled Team',
      players: rawPlayers
          .whereType<Map>()
          .map((Map item) => SportsNeoManagedPlayer.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
      createdAt: map['createdAt']?.toString() ?? '',
    );
  }

  final String id;
  final String name;
  final List<SportsNeoManagedPlayer> players;
  final String createdAt;

  int get playerCount => players.length;
  int get appUsersCount => players.where((player) => !player.isGuest).length;
  int get guestPlayersCount => players.where((player) => player.isGuest).length;
}

class SportsNeoPlayerDirectoryItem {
  const SportsNeoPlayerDirectoryItem({
    required this.id,
    required this.name,
    required this.contactNumber,
    required this.email,
    required this.playerType,
  });

  factory SportsNeoPlayerDirectoryItem.fromMap(Map<String, dynamic> map) {
    return SportsNeoPlayerDirectoryItem(
      id: map['id']?.toString() ?? map['_id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Player',
      contactNumber: map['contactNumber']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      playerType: map['playerType']?.toString() ?? '',
    );
  }

  final String id;
  final String name;
  final String contactNumber;
  final String email;
  final String playerType;
}

class SportsNeoTeamManageRepository {
  const SportsNeoTeamManageRepository(this._api);

  final GroundWaleApi _api;

  String get _ownerId {
    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      throw Exception('Session expired. Please login again.');
    }
    return ownerId;
  }

  Future<List<SportsNeoManagedTeam>> listTeams() async {
    final List<Map<String, dynamic>> items = await _api.listTeams(_ownerId);
    return items.map(SportsNeoManagedTeam.fromMap).toList();
  }

  Future<SportsNeoManagedTeam> createTeam(String name) async {
    final Map<String, dynamic> item = await _api.createTeam(_ownerId, <String, dynamic>{
      'name': name,
    });
    return SportsNeoManagedTeam.fromMap(item);
  }

  Future<SportsNeoManagedTeam> getTeam(String teamId) async {
    final Map<String, dynamic> item = await _api.getTeam(_ownerId, teamId);
    return SportsNeoManagedTeam.fromMap(item);
  }

  Future<SportsNeoManagedTeam> updateTeam(String teamId, String name) async {
    final Map<String, dynamic> item = await _api.updateTeam(_ownerId, teamId, <String, dynamic>{
      'name': name,
    });
    return SportsNeoManagedTeam.fromMap(item);
  }

  Future<void> deleteTeam(String teamId) async {
    await _api.deleteTeam(_ownerId, teamId);
  }

  Future<List<SportsNeoPlayerDirectoryItem>> searchPlayers(String query) async {
    final List<Map<String, dynamic>> items = await _api.searchTeamPlayerDirectory(
      _ownerId,
      query: query,
    );
    return items.map(SportsNeoPlayerDirectoryItem.fromMap).toList();
  }

  Future<SportsNeoManagedTeam> addAppUserPlayer({
    required String teamId,
    required String userId,
    required String playerType,
  }) async {
    final Map<String, dynamic> item = await _api.addTeamPlayer(
      _ownerId,
      teamId,
      <String, dynamic>{
        'userId': userId,
        'playerType': playerType,
      },
    );
    return SportsNeoManagedTeam.fromMap(item);
  }

  Future<SportsNeoManagedTeam> addGuestPlayer({
    required String teamId,
    required String name,
    required String contactNumber,
    String email = '',
    String playerType = '',
  }) async {
    final Map<String, dynamic> item = await _api.addTeamPlayer(
      _ownerId,
      teamId,
      <String, dynamic>{
        'name': name,
        'contactNumber': contactNumber,
        'email': email,
        'playerType': playerType,
        'isGuest': true,
      },
    );
    return SportsNeoManagedTeam.fromMap(item);
  }

  Future<SportsNeoManagedTeam> removePlayer({
    required String teamId,
    required String playerId,
  }) async {
    final Map<String, dynamic> item = await _api.removeTeamPlayer(
      _ownerId,
      teamId,
      playerId,
    );
    return SportsNeoManagedTeam.fromMap(item);
  }
}