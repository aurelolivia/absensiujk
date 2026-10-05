import 'package:dio/dio.dart';

import 'dio_client.dart';

class ApiServices {
  final Dio dio;

  ApiServices() : dio = createDioClient();

  Future<Response> login({
    required String email,
    required String password,
  }) async {
    final response = await dio.post(
      '/api/login',
      data: {'email': email, 'password': password},
    );

    return response;
  }

  Future<Response> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await dio.post(
      '/api/register',
      data: {'name': name, 'email': email, 'password': password},
    );

    return response;
  }

  Future<Response> checkIn({
    required String token,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    final response = await dio.post(
      '/api/absen/check-in',
      data: {
        'check_in_lat': latitude.toString(),
        'check_in_lng': longitude.toString(),
        'check_in_address': address,
        'status': 'masuk',
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response;
  }

  Future<Response> checkOut({
    required String token,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    final response = await dio.post(
      '/api/absen/check-out',
      data: {
        'check_out_lat': latitude.toString(),
        'check_out_lng': longitude.toString(),
        'check_out_location': '$latitude, $longitude',
        'check_out_address': address,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response;
  }

  Future<Response> getHistory({
    required String token,
    required String start,
    required String end,
  }) async {
    final response = await dio.get(
      '/api/absen/history',
      queryParameters: {'start': start, 'end': end},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response;
  }

  Future<Response> getProfile({required String token}) async {
    final response = await dio.get(
      '/api/profile',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response;
  }

  Future<Response> updateProfile({
    required String token,
    required String name,
    required String email,
  }) async {
    final response = await dio.put(
      '/api/profile',
      data: {'name': name, 'email': email},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response;
  }

  Future<Response> deleteAttendance({
    required String token,
    required int id,
  }) async {
    final response = await dio.delete(
      '/api/absen/$id',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response;
  }

  Future<Response> izinSakit({
    required String token,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    final response = await dio.post(
      '/api/absen/check-in',
      data: {
        'check_in_lat': latitude.toString(),
        'check_in_lng': longitude.toString(),
        'check_in_address': address,
        'status': 'izin',
        'alasan_izin': 'izin sakit',
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response;
  }
}
