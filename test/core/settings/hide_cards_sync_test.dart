import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:groo_damda_app/core/settings/hide_cards_repository.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/core/storage/prefs_provider.dart';

/// 서버를 흉내 내는 저장소. `fetch` 가 무엇을 주느냐가 이 테스트의 축이다.
class _FakeRepo implements HideCardsRepository {
  _FakeRepo({this.server, this.fetchThrows = false});

  /// `null` = 아직 한 번도 안 올림. 빈 목록과 뜻이 다르다.
  List<String>? server;
  bool fetchThrows;
  final List<Set<String>> pushed = [];

  @override
  Future<List<String>?> fetch() async {
    if (fetchThrows) throw Exception('네트워크 실패');
    return server;
  }

  @override
  Future<void> put(Set<String> cards, {bool silent = true}) async =>
      pushed.add({...cards});
}

ProviderContainer _container(_FakeRepo repo) {
  final container = ProviderContainer(
    overrides: [hideCardsRepositoryProvider.overrideWith((ref) async => repo)],
  );
  addTearDown(container.dispose);
  return container;
}

/// 금액 가리기를 계정 단위로 맞출 때, 틀리면 **가려 뒀던 금액이 드러나는** 규칙들.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const me = 'hong';
  const other = 'kim';

  test('서버가 null 이면 내려받지 않고 로컬을 올린다 — 첫 배포에 금액이 드러나면 안 된다', () async {
    SharedPreferences.setMockInitialValues({
      PrefsKeys.hideCards: ['asset.netWorth'],
      PrefsKeys.hideCardsOwner: me,
    });
    final repo = _FakeRepo(server: null);
    final c = _container(repo);
    await c.read(settingsProvider.future);

    await c.read(settingsProvider.notifier).syncHideCardsFromServer(me);

    // null 을 빈 목록으로 받아 덮었다면 여기서 가림이 풀린다.
    expect(c.read(settingsProvider).value!.hideCards, {'asset.netWorth'});
    expect(repo.pushed.single, {'asset.netWorth'});
  });

  test('서버가 빈 목록이면 그대로 따른다 — 사용자가 다 푼 상태다', () async {
    SharedPreferences.setMockInitialValues({
      PrefsKeys.hideCards: ['asset.netWorth'],
      PrefsKeys.hideCardsOwner: me,
    });
    final repo = _FakeRepo(server: <String>[]);
    final c = _container(repo);
    await c.read(settingsProvider.future);

    await c.read(settingsProvider.notifier).syncHideCardsFromServer(me);

    expect(c.read(settingsProvider).value!.hideCards, isEmpty);
    // 받은 값을 되쏘면 부르자마자 PUT 이 나가는 왕복이 생긴다.
    expect(repo.pushed, isEmpty);
  });

  test('서버 값을 내려받아 로컬을 덮는다 — 웹에서 가린 게 앱에도 보인다', () async {
    SharedPreferences.setMockInitialValues({PrefsKeys.hideCardsOwner: me});
    final repo = _FakeRepo(server: ['ledger.txList', 'kind.expense']);
    final c = _container(repo);
    await c.read(settingsProvider.future);

    await c.read(settingsProvider.notifier).syncHideCardsFromServer(me);

    expect(c.read(settingsProvider).value!.hideCards, {
      'ledger.txList',
      'kind.expense',
    });
  });

  test('모르는 카드 키는 버린다 — 남겨 두면 영영 못 지우는 유령이 된다', () async {
    SharedPreferences.setMockInitialValues({PrefsKeys.hideCardsOwner: me});
    final repo = _FakeRepo(server: ['ledger.txList', 'was.removed']);
    final c = _container(repo);
    await c.read(settingsProvider.future);

    await c.read(settingsProvider.notifier).syncHideCardsFromServer(me);

    expect(c.read(settingsProvider).value!.hideCards, {'ledger.txList'});
  });

  test('남이 쓰던 기기면 로컬을 올리지 않는다 — 남의 가림 설정이 내 계정에 붙는다', () async {
    SharedPreferences.setMockInitialValues({
      PrefsKeys.hideCards: ['asset.netWorth'],
      PrefsKeys.hideCardsOwner: other,
    });
    final repo = _FakeRepo(server: null);
    final c = _container(repo);
    await c.read(settingsProvider.future);

    await c.read(settingsProvider.notifier).syncHideCardsFromServer(me);

    expect(repo.pushed.single, isEmpty);
    expect(c.read(settingsProvider).value!.hideCards, isEmpty);
  });

  test('주인 표식이 없으면 올리지 않는다 — 누구 것인지 모르는 캐시다', () async {
    SharedPreferences.setMockInitialValues({
      PrefsKeys.hideCards: ['asset.netWorth'],
    });
    final repo = _FakeRepo(server: null);
    final c = _container(repo);
    await c.read(settingsProvider.future);

    await c.read(settingsProvider.notifier).syncHideCardsFromServer(me);

    expect(repo.pushed.single, isEmpty);
  });

  test('서버를 못 읽으면 로컬을 그대로 둔다 — 여기서 비우면 금액이 드러난다', () async {
    SharedPreferences.setMockInitialValues({
      PrefsKeys.hideCards: ['asset.netWorth'],
      PrefsKeys.hideCardsOwner: me,
    });
    final repo = _FakeRepo(fetchThrows: true);
    final c = _container(repo);
    await c.read(settingsProvider.future);

    await c.read(settingsProvider.notifier).syncHideCardsFromServer(me);

    expect(c.read(settingsProvider).value!.hideCards, {'asset.netWorth'});
    expect(repo.pushed, isEmpty);
  });

  test('저장하면 서버로 올라간다', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = _FakeRepo(server: <String>[]);
    final c = _container(repo);
    await c.read(settingsProvider.future);

    await c.read(settingsProvider.notifier).setHideCards({'stats.trend'});
    await Future<void>.delayed(Duration.zero); // 올리기는 비동기다

    expect(repo.pushed.single, {'stats.trend'});
  });
}
