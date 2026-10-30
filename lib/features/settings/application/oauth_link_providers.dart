import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:groo_damda_app/core/network/dio_provider.dart';
import 'package:groo_damda_app/features/settings/data/oauth_link_repository.dart';

final oauthLinkRepositoryProvider = FutureProvider<OAuthLinkRepository>((
  ref,
) async {
  final dio = await ref.watch(dioProvider.future);
  return OAuthLinkRepository(dio);
});

/// 연동 상태 목록 — 계정 화면을 떠나면 버리고, 들어올 때 다시 받는다.
final oauthProvidersProvider =
    FutureProvider.autoDispose<List<OAuthProviderInfo>>((ref) async {
      final repo = await ref.watch(oauthLinkRepositoryProvider.future);
      return repo.providers();
    });
