import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:groo_damda_app/core/network/dio_provider.dart';
import 'package:groo_damda_app/features/settings/data/reauth_repository.dart';

final reauthRepositoryProvider = FutureProvider<ReauthRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return ReauthRepository(dio);
});
