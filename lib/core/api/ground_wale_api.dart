import 'package:dio/dio.dart';

import 'api_config.dart';

class GroundWaleApi {
  GroundWaleApi._()
    : _dio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
          headers: <String, String>{'Content-Type': 'application/json'},
        ),
      );

  static final GroundWaleApi instance = GroundWaleApi._();

  final Dio _dio;

  Exception _mapError(Object error) {
    if (error is DioException) {
      final dynamic data = error.response?.data;
      final String message = data is Map<String, dynamic>
          ? data['message']?.toString() ?? error.message ?? 'Request failed'
          : error.message ?? 'Request failed';
      return Exception(message);
    }

    return Exception(error.toString());
  }

  Future<Map<String, dynamic>> sendLoginOtp({
    required String contactNumber,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/auth/send-login-otp',
        data: <String, dynamic>{'contactNumber': contactNumber},
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> sendRegisterOtp({
    required String contactNumber,
    String ownerName = 'Ground Owner',
    String email = '',
    String? role,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/auth/send-register-otp',
        data: <String, dynamic>{
          'contactNumber': contactNumber,
          'ownerName': ownerName,
          'email': email,
          if (role != null && role.isNotEmpty) 'role': role,
        },
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> sendOtp({required String contactNumber}) {
    return sendLoginOtp(contactNumber: contactNumber);
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String contactNumber,
    required String otp,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/auth/verify-otp',
        data: <String, dynamic>{'contactNumber': contactNumber, 'otp': otp},
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> loginWithEmail({required String email}) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/auth/login-with-email',
        data: <String, dynamic>{'email': email},
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> loginWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/auth/login-with-password',
        data: <String, dynamic>{'email': email, 'password': password},
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> googleLogin({
    required String email,
    String ownerName = 'Sports Neo User',
    String role = 'player',
  }) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/auth/google-login',
        data: <String, dynamic>{
          'email': email,
          'ownerName': ownerName,
          'role': role,
        },
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> requestPasswordReset({
    required String email,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/auth/request-password-reset',
        data: <String, dynamic>{'email': email},
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/auth/verify-password-reset-otp',
        data: <String, dynamic>{'email': email, 'otp': otp},
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> updatePasswordWithOtp({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/auth/update-password-with-otp',
        data: <String, dynamic>{
          'email': email,
          'password': password,
          'confirmPassword': confirmPassword,
        },
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post<dynamic>('/auth/logout');
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> getOwnerProfile(String ownerId) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/owners/$ownerId/profile',
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> updateOwnerProfile(
    String ownerId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final Response<dynamic> response = await _dio.patch<dynamic>(
        '/owners/$ownerId/profile',
        data: payload,
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> getNotificationPreferences(
    String ownerId,
  ) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/owners/$ownerId/notification-preferences',
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> updateNotificationPreferences(
    String ownerId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final Response<dynamic> response = await _dio.patch<dynamic>(
        '/owners/$ownerId/notification-preferences',
        data: payload,
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> getBankAccount(String ownerId) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/owners/$ownerId/bank-account',
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> updateBankAccount(
    String ownerId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final Response<dynamic> response = await _dio.put<dynamic>(
        '/owners/$ownerId/bank-account',
        data: payload,
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<List<Map<String, dynamic>>> listTeams(String ownerId) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/owners/$ownerId/teams',
      );
      return (response.data as List<dynamic>)
          .map((dynamic item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> createTeam(
    String ownerId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/owners/$ownerId/teams',
        data: payload,
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> getTeam(String ownerId, String teamId) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/owners/$ownerId/teams/$teamId',
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> updateTeam(
    String ownerId,
    String teamId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final Response<dynamic> response = await _dio.patch<dynamic>(
        '/owners/$ownerId/teams/$teamId',
        data: payload,
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<void> deleteTeam(String ownerId, String teamId) async {
    try {
      await _dio.delete<dynamic>('/owners/$ownerId/teams/$teamId');
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<List<Map<String, dynamic>>> searchTeamPlayerDirectory(
    String ownerId, {
    String? query,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/owners/$ownerId/teams/player-directory',
        queryParameters: query == null || query.trim().isEmpty
            ? null
            : <String, dynamic>{'query': query.trim()},
      );
      return (response.data as List<dynamic>)
          .map((dynamic item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> addTeamPlayer(
    String ownerId,
    String teamId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/owners/$ownerId/teams/$teamId/players',
        data: payload,
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> removeTeamPlayer(
    String ownerId,
    String teamId,
    String playerId,
  ) async {
    try {
      final Response<dynamic> response = await _dio.delete<dynamic>(
        '/owners/$ownerId/teams/$teamId/players/$playerId',
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<List<Map<String, dynamic>>> listNotifications(String ownerId) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/owners/$ownerId/notifications',
      );
      return (response.data as List<dynamic>)
          .map((dynamic item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> markNotificationRead(
    String ownerId,
    String notificationId,
  ) async {
    try {
      final Response<dynamic> response = await _dio.patch<dynamic>(
        '/owners/$ownerId/notifications/$notificationId/read',
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> getDashboard(String ownerId) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/owners/$ownerId/dashboard',
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> getBoxCricketDashboard(String ownerId) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/owners/$ownerId/box-cricket-dashboard',
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> createGround(
    Map<String, dynamic> payload,
  ) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/grounds',
        data: payload,
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<List<Map<String, dynamic>>> listGrounds({String? ownerId}) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/grounds',
        queryParameters: ownerId == null
            ? null
            : <String, dynamic>{'ownerId': ownerId},
      );
      return (response.data as List<dynamic>)
          .map((dynamic item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<String?> ensureGroundIdForOwner(String ownerId) async {
    final List<Map<String, dynamic>> grounds = await listGrounds(
      ownerId: ownerId,
    );
    if (grounds.isEmpty) {
      return null;
    }

    return grounds.first['_id']?.toString() ?? grounds.first['id']?.toString();
  }

  Future<Map<String, dynamic>> getGround(String groundId) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/grounds/$groundId',
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> updateGround(
    String groundId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final Response<dynamic> response = await _dio.patch<dynamic>(
        '/grounds/$groundId',
        data: payload,
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> updateFacilities(
    String groundId,
    List<String> facilities,
  ) async {
    try {
      final Response<dynamic> response = await _dio.patch<dynamic>(
        '/grounds/$groundId/facilities',
        data: <String, dynamic>{'facilities': facilities},
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> updateOwnershipVerification(
    String groundId,
    String ownershipProof,
  ) async {
    try {
      final Response<dynamic> response = await _dio.patch<dynamic>(
        '/grounds/$groundId/ownership-verification',
        data: <String, dynamic>{'ownershipProof': ownershipProof},
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> submitGroundForReview(String groundId) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/grounds/$groundId/submit-review',
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> getReviewStatus(String groundId) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/grounds/$groundId/review-status',
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<List<Map<String, dynamic>>> listSlots(
    String groundId, {
    String? status,
    String? date,
    String? from,
    String? to,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/grounds/$groundId/slots',
        queryParameters: <String, dynamic>{
          if (status != null && status.isNotEmpty) 'status': status,
          if (date != null && date.isNotEmpty) 'date': date,
          if (from != null && from.isNotEmpty) 'from': from,
          if (to != null && to.isNotEmpty) 'to': to,
        },
      );
      return (response.data as List<dynamic>)
          .map((dynamic item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> createSlot(
    String groundId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/grounds/$groundId/slots',
        data: payload,
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> updateSlot(
    String slotId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final Response<dynamic> response = await _dio.patch<dynamic>(
        '/slots/$slotId',
        data: payload,
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> blockSlot(
    String slotId,
    String blockedReason,
  ) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/slots/$slotId/block',
        data: <String, dynamic>{'blockedReason': blockedReason},
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<void> deleteSlot(String slotId) async {
    try {
      await _dio.delete<dynamic>('/slots/$slotId');
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<List<Map<String, dynamic>>> listBookings(
    String groundId, {
    String? status,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/grounds/$groundId/bookings',
        queryParameters: status == null
            ? null
            : <String, dynamic>{'status': status},
      );
      return (response.data as List<dynamic>)
          .map((dynamic item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> createBooking(
    String groundId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/grounds/$groundId/bookings',
        data: payload,
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> getBookingSummary(
    String groundId, {
    String? status,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/grounds/$groundId/bookings/summary',
        queryParameters: status == null
            ? null
            : <String, dynamic>{'status': status},
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> getBookingDetails(String bookingId) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/bookings/$bookingId',
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> acceptBooking(String bookingId) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/bookings/$bookingId/accept',
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> rejectBooking(
    String bookingId, {
    String reason = 'Not Available',
  }) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/bookings/$bookingId/reject',
        data: <String, dynamic>{'reason': reason},
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> collectCodPayment(String bookingId) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/bookings/$bookingId/cod/collect',
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> getWallet(String groundId) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/grounds/$groundId/wallet',
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<List<Map<String, dynamic>>> getTransactions(
    String groundId, {
    String? type,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/grounds/$groundId/wallet/transactions',
        queryParameters: type == null ? null : <String, dynamic>{'type': type},
      );
      return (response.data as List<dynamic>)
          .map((dynamic item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> withdraw(
    String groundId,
    double amount, {
    String subtitle = 'Manual payout request',
  }) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/grounds/$groundId/wallet/withdraw',
        data: <String, dynamic>{'amount': amount, 'subtitle': subtitle},
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> getEarningsReport(
    String groundId, {
    String? from,
    String? to,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/grounds/$groundId/reports/earnings',
        queryParameters: <String, dynamic>{
          if (from case final String fromValue) 'from': fromValue,
          if (to case final String toValue) 'to': toValue,
        },
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> createSupportTicket(
    Map<String, dynamic> payload,
  ) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/support/tickets',
        data: payload,
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> getTerms() async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/policies/terms',
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> getPrivacy() async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/policies/privacy',
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> getAcademyDashboard(
    String ownerId, {
    String? batchId,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/academy/$ownerId/dashboard',
        queryParameters: <String, dynamic>{
          if (batchId != null && batchId.isNotEmpty) 'batchId': batchId,
        },
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> listAcademyStudents(
    String ownerId, {
    String? status,
    String? batchId,
    String? search,
    int? page,
    int? limit,
  }) async {
    try {
      final Map<String, dynamic> queryParameters = <String, dynamic>{
        if (status != null && status.isNotEmpty) 'status': status,
        if (batchId != null && batchId.isNotEmpty) 'batchId': batchId,
        if (search != null && search.isNotEmpty) 'search': search,
      };
      if (page != null) {
        queryParameters['page'] = page;
      }
      if (limit != null) {
        queryParameters['limit'] = limit;
      }

      final Response<dynamic> response = await _dio.get<dynamic>(
        '/academy/$ownerId/students',
        queryParameters: queryParameters,
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> createAcademyStudent(
    String ownerId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/academy/$ownerId/students',
        data: payload,
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> getAcademyStudent(
    String ownerId,
    String studentId,
  ) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/academy/$ownerId/students/$studentId',
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> updateAcademyStudent(
    String ownerId,
    String studentId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final Response<dynamic> response = await _dio.patch<dynamic>(
        '/academy/$ownerId/students/$studentId',
        data: payload,
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<void> deleteAcademyStudent(String ownerId, String studentId) async {
    try {
      await _dio.delete<dynamic>('/academy/$ownerId/students/$studentId');
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<List<Map<String, dynamic>>> listAcademyBatches(
    String ownerId, {
    String? status,
    String? search,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/academy/$ownerId/batches',
        queryParameters: <String, dynamic>{
          if (status != null && status.isNotEmpty) 'status': status,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      final dynamic data = response.data;
      final List<dynamic> items;
      if (data is List<dynamic>) {
        items = data;
      } else if (data is Map) {
        final Map<String, dynamic> map = Map<String, dynamic>.from(data);
        final dynamic nested = map['items'] ?? map['data'] ?? map['batches'];
        if (nested is List<dynamic>) {
          items = nested;
        } else {
          items = <dynamic>[];
        }
      } else {
        items = <dynamic>[];
      }

      return items
          .whereType<Map>()
          .map((Map item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> createAcademyBatch(
    String ownerId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/academy/$ownerId/batches',
        data: payload,
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> getAcademyBatch(
    String ownerId,
    String batchId,
  ) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/academy/$ownerId/batches/$batchId',
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> updateAcademyBatch(
    String ownerId,
    String batchId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final Response<dynamic> response = await _dio.patch<dynamic>(
        '/academy/$ownerId/batches/$batchId',
        data: payload,
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<void> deleteAcademyBatch(String ownerId, String batchId) async {
    try {
      await _dio.delete<dynamic>('/academy/$ownerId/batches/$batchId');
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<List<Map<String, dynamic>>> listAcademyAttendance(
    String ownerId, {
    String? batchId,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/academy/$ownerId/attendance',
        queryParameters: <String, dynamic>{
          if (batchId != null && batchId.isNotEmpty) 'batchId': batchId,
          if (dateFrom != null && dateFrom.isNotEmpty) 'dateFrom': dateFrom,
          if (dateTo != null && dateTo.isNotEmpty) 'dateTo': dateTo,
        },
      );
      return (response.data as List<dynamic>)
          .map((dynamic item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> markAcademyAttendance(
    String ownerId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/academy/$ownerId/attendance',
        data: payload,
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<List<Map<String, dynamic>>> listAcademyFees(
    String ownerId, {
    String? studentId,
    String? status,
    String? monthKey,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/academy/$ownerId/fees',
        queryParameters: <String, dynamic>{
          if (studentId != null && studentId.isNotEmpty) 'studentId': studentId,
          if (status != null && status.isNotEmpty) 'status': status,
          if (monthKey != null && monthKey.isNotEmpty) 'monthKey': monthKey,
        },
      );
      return (response.data as List<dynamic>)
          .map((dynamic item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> createAcademyFee(
    String ownerId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/academy/$ownerId/fees',
        data: payload,
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> updateAcademyFee(
    String ownerId,
    String feeId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final Response<dynamic> response = await _dio.patch<dynamic>(
        '/academy/$ownerId/fees/$feeId',
        data: payload,
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> sendAcademyFeeReminder(
    String ownerId,
    String feeId,
  ) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/academy/$ownerId/fees/$feeId/reminder',
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<List<Map<String, dynamic>>> listAcademyAnnouncements(
    String ownerId, {
    String? audience,
    String? batchId,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/academy/$ownerId/announcements',
        queryParameters: <String, dynamic>{
          if (audience != null && audience.isNotEmpty) 'audience': audience,
          if (batchId != null && batchId.isNotEmpty) 'batchId': batchId,
        },
      );
      return (response.data as List<dynamic>)
          .map((dynamic item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> createAcademyAnnouncement(
    String ownerId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/academy/$ownerId/announcements',
        data: payload,
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> getAcademyAnnouncement(
    String ownerId,
    String announcementId,
  ) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/academy/$ownerId/announcements/$announcementId',
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> updateAcademyAnnouncement(
    String ownerId,
    String announcementId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final Response<dynamic> response = await _dio.patch<dynamic>(
        '/academy/$ownerId/announcements/$announcementId',
        data: payload,
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<void> deleteAcademyAnnouncement(
    String ownerId,
    String announcementId,
  ) async {
    try {
      await _dio.delete<dynamic>(
        '/academy/$ownerId/announcements/$announcementId',
      );
    } catch (error) {
      throw _mapError(error);
    }
  }
}
