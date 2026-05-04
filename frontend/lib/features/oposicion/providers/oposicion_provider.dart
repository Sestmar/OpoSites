import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/models/rama_response.dart';
import '../data/oposicion_repository.dart';

final oposicionRepositoryProvider = Provider<OposicionRepository>((ref) =>
    OposicionRepository(dio: ref.watch(dioProvider)));

final ramasProvider = FutureProvider.autoDispose<List<RamaResponse>>(
  (ref) => ref.read(oposicionRepositoryProvider).getRamas(),
);
