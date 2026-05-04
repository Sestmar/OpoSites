import 'package:dio/dio.dart';

import '../../../core/constants/api_endpoints.dart';
import 'models/rama_response.dart';

class OposicionRepository {
  const OposicionRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<RamaResponse>> getRamas() async {
    final response = await _dio.get<List<dynamic>>(ApiEndpoints.oposiciones);
    return (response.data ?? [])
        .map((e) => RamaResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> selectRama(int ramaId) async {
    await _dio.put<void>(ApiEndpoints.meRama, data: {'ramaId': ramaId});
  }
}
