import 'package:groo_damda_app/core/settings/hide_cards_repository.dart';

/// 금액 가리기 서버 저장을 흉내 낸다 — 저장은 서버가 받아야 로컬에 반영되므로(실패하면 로컬 그대로),
/// 화면 시험이 가림을 걸 때는 성공하는 저장소를 꽂는다.
class OkHideCardsRepository implements HideCardsRepository {
  @override
  Future<List<String>?> fetch() async => <String>[];

  @override
  Future<void> put(Set<String> cards, {bool silent = true}) async {}
}
