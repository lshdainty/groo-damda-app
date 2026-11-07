import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// 앱 이름
  ///
  /// In ko, this message translates to:
  /// **'그루 담다'**
  String get appTitle;

  /// No description provided for @actionSave.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get actionSave;

  /// No description provided for @actionCancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get actionCancel;

  /// No description provided for @actionDelete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get actionDelete;

  /// No description provided for @actionEdit.
  ///
  /// In ko, this message translates to:
  /// **'수정'**
  String get actionEdit;

  /// No description provided for @actionCreate.
  ///
  /// In ko, this message translates to:
  /// **'생성'**
  String get actionCreate;

  /// No description provided for @actionConfirm.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get actionConfirm;

  /// No description provided for @actionClose.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get actionClose;

  /// No description provided for @actionRetry.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get actionRetry;

  /// 보던 내용이 있는 채 다시 받기에 실패했을 때 공용 critical 스낵바 — [다시 시도] 없음, 한 문장(I-wrap-b2b 2-1)
  ///
  /// In ko, this message translates to:
  /// **'새로 고치지 못했어요.'**
  String get queryRefreshFailed;

  /// 참조 데이터(카테고리 · 계좌 …)를 값 없이 받지 못했을 때 공용 critical 스낵바 + [다시 시도] — 웹 common query.referenceFailed
  ///
  /// In ko, this message translates to:
  /// **'일부 정보를 불러오지 못했어요.'**
  String get queryReferenceFailed;

  /// 저장 응답을 읽지 못했을 때(PARSE — 서버는 처리했다) 폼 맨 위 Callout. 실패라 하지 않는다, 웹과 같은 글
  ///
  /// In ko, this message translates to:
  /// **'저장됐는지 확인하지 못했어요. 목록에서 확인해주세요.'**
  String get saveUnconfirmed;

  /// 카드 결제 응답을 읽지 못했을 때 결제 폼 맨 위 Callout, 웹과 같은 글
  ///
  /// In ko, this message translates to:
  /// **'결제됐는지 확인하지 못했어요. 청구 내역에서 확인해주세요.'**
  String get payUnconfirmed;

  /// 시세 폴링이 받아 둔 값이 있는 채 실패했을 때 섹션 Callout 본문(제목 stocksFailPrice) — 웹과 같은 글
  ///
  /// In ko, this message translates to:
  /// **'보이는 값은 마지막으로 받은 시세예요.'**
  String get stocksStaleLastPrice;

  /// 투자 평가 시세를 못 받아 서버 잔액으로 그린 자리의 Callout 본문 — 웹과 같은 글
  ///
  /// In ko, this message translates to:
  /// **'보이는 값은 시세가 아닌 마지막 잔액이에요.'**
  String get stocksStaleLastBalance;

  /// 증권 연결 화면 나가기 확인창 본문(키를 친 화면) — 금액 가리기는 hideAmountsDiscardBody("고른") 그대로
  ///
  /// In ko, this message translates to:
  /// **'작성한 내용이 사라져요.'**
  String get securitiesLeaveBody;

  /// 이용 해지 응답을 읽지 못했거나 받지 못했을 때(PARSE · NO_RESPONSE) — 웹과 같은 글
  ///
  /// In ko, this message translates to:
  /// **'해지됐는지 확인하지 못했어요. 앱을 다시 열어 확인해주세요.'**
  String get withdrawUnconfirmed;

  /// 스낵바 — 저장 · 추가 쓰기의 응답을 읽지 못했거나 받지 못했을 때(PARSE · NO_RESPONSE). 한 문장(목록은 저절로 다시 받는다), [다시 시도] 없음 — 웹과 같은 글
  ///
  /// In ko, this message translates to:
  /// **'저장됐는지 확인하지 못했어요.'**
  String get unconfirmedSave;

  /// 스낵바 — 삭제 응답을 읽지 못했거나 받지 못했을 때. 한 문장, [다시 시도] 없음 — 웹과 같은 글
  ///
  /// In ko, this message translates to:
  /// **'삭제됐는지 확인하지 못했어요.'**
  String get unconfirmedDelete;

  /// No description provided for @unconfirmedDisconnect.
  ///
  /// In ko, this message translates to:
  /// **'해제됐는지 확인하지 못했어요.'**
  String get unconfirmedDisconnect;

  /// 스낵바 — 그 밖 쓰기(기기 로그아웃 · 캘린더 나가기 · 모두 받음 등)의 응답을 못 받았을 때. 한 문장, [다시 시도] 없음 — 웹과 같은 글
  ///
  /// In ko, this message translates to:
  /// **'처리됐는지 확인하지 못했어요.'**
  String get unconfirmedProcess;

  /// 스낵바 — 누르는 순간 바뀌는 값(고정 · 표시 · 스위치)의 응답을 못 받았을 때. 되돌리지 않고 서버 값을 다시 받는다 — 웹과 같은 글
  ///
  /// In ko, this message translates to:
  /// **'바뀌었는지 확인하지 못했어요.'**
  String get unconfirmedToggle;

  /// 증권 키 등록 응답을 못 받았을 때 — 연결 상태를 다시 받는다, 웹과 같은 글
  ///
  /// In ko, this message translates to:
  /// **'연결됐는지 확인하지 못했어요.'**
  String get unconfirmedConnect;

  /// No description provided for @actionApply.
  ///
  /// In ko, this message translates to:
  /// **'적용'**
  String get actionApply;

  /// No description provided for @actionReset.
  ///
  /// In ko, this message translates to:
  /// **'초기화'**
  String get actionReset;

  /// No description provided for @actionSearch.
  ///
  /// In ko, this message translates to:
  /// **'검색'**
  String get actionSearch;

  /// No description provided for @actionLoading.
  ///
  /// In ko, this message translates to:
  /// **'로딩 중...'**
  String get actionLoading;

  /// No description provided for @actionDone.
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get actionDone;

  /// No description provided for @actionBack.
  ///
  /// In ko, this message translates to:
  /// **'뒤로'**
  String get actionBack;

  /// No description provided for @actionNext.
  ///
  /// In ko, this message translates to:
  /// **'다음'**
  String get actionNext;

  /// No description provided for @pickDate.
  ///
  /// In ko, this message translates to:
  /// **'날짜 선택'**
  String get pickDate;

  /// No description provided for @pickTime.
  ///
  /// In ko, this message translates to:
  /// **'시간 선택'**
  String get pickTime;

  /// No description provided for @searchResultsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과가 없어요'**
  String get searchResultsEmpty;

  /// No description provided for @unlockTitle.
  ///
  /// In ko, this message translates to:
  /// **'금액 보기 인증'**
  String get unlockTitle;

  /// No description provided for @unlockBody.
  ///
  /// In ko, this message translates to:
  /// **'금액을 다시 보려면 비밀번호로 본인 확인이 필요해요.'**
  String get unlockBody;

  /// No description provided for @unlockBiometricReason.
  ///
  /// In ko, this message translates to:
  /// **'금액을 다시 보려면 본인 확인이 필요해요.'**
  String get unlockBiometricReason;

  /// No description provided for @unlockPasswordLabel.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호'**
  String get unlockPasswordLabel;

  /// No description provided for @unlockMismatch.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호가 일치하지 않아요.'**
  String get unlockMismatch;

  /// No description provided for @appLockTitle.
  ///
  /// In ko, this message translates to:
  /// **'앱 잠금'**
  String get appLockTitle;

  /// No description provided for @appLockRowDesc.
  ///
  /// In ko, this message translates to:
  /// **'앱을 열 때 Face ID·지문으로 본인 확인을 해요.'**
  String get appLockRowDesc;

  /// No description provided for @appLockLockedDesc.
  ///
  /// In ko, this message translates to:
  /// **'잠금을 해제하려면 본인 확인이 필요해요.'**
  String get appLockLockedDesc;

  /// No description provided for @appLockUnlockAction.
  ///
  /// In ko, this message translates to:
  /// **'잠금 해제'**
  String get appLockUnlockAction;

  /// No description provided for @appLockPromptReason.
  ///
  /// In ko, this message translates to:
  /// **'앱을 열려면 본인 확인이 필요해요.'**
  String get appLockPromptReason;

  /// No description provided for @appLockUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'이 기기에서는 생체인증이나 화면 잠금을 사용할 수 없어요.'**
  String get appLockUnavailable;

  /// No description provided for @stateNoData.
  ///
  /// In ko, this message translates to:
  /// **'데이터가 없습니다'**
  String get stateNoData;

  /// No description provided for @stateError.
  ///
  /// In ko, this message translates to:
  /// **'오류가 발생했습니다'**
  String get stateError;

  /// No description provided for @stateEmpty.
  ///
  /// In ko, this message translates to:
  /// **'표시할 항목이 없어요'**
  String get stateEmpty;

  /// 이름 길이 상한 안내 — 계좌 별칭·저축목표·프리셋·참여자가 공유한다
  ///
  /// In ko, this message translates to:
  /// **'이름은 {max}자 이내로 입력해주세요.'**
  String nameTooLong(int max);

  /// No description provided for @languageKorean.
  ///
  /// In ko, this message translates to:
  /// **'한국어'**
  String get languageKorean;

  /// No description provided for @languageEnglish.
  ///
  /// In ko, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSystem.
  ///
  /// In ko, this message translates to:
  /// **'시스템'**
  String get languageSystem;

  /// No description provided for @settingsLanguage.
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get settingsLanguage;

  /// No description provided for @navDashboard.
  ///
  /// In ko, this message translates to:
  /// **'대시보드'**
  String get navDashboard;

  /// No description provided for @navTodo.
  ///
  /// In ko, this message translates to:
  /// **'할 일'**
  String get navTodo;

  /// No description provided for @navCalendar.
  ///
  /// In ko, this message translates to:
  /// **'캘린더'**
  String get navCalendar;

  /// No description provided for @navMemo.
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get navMemo;

  /// No description provided for @navTimer.
  ///
  /// In ko, this message translates to:
  /// **'타이머'**
  String get navTimer;

  /// No description provided for @navExpense.
  ///
  /// In ko, this message translates to:
  /// **'가계부'**
  String get navExpense;

  /// No description provided for @navAsset.
  ///
  /// In ko, this message translates to:
  /// **'자산'**
  String get navAsset;

  /// No description provided for @navDutchPay.
  ///
  /// In ko, this message translates to:
  /// **'더치페이'**
  String get navDutchPay;

  /// No description provided for @navPostit.
  ///
  /// In ko, this message translates to:
  /// **'포스트잇'**
  String get navPostit;

  /// No description provided for @navGroup.
  ///
  /// In ko, this message translates to:
  /// **'그룹'**
  String get navGroup;

  /// No description provided for @navSettings.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get navSettings;

  /// No description provided for @navMore.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get navMore;

  /// No description provided for @navMenu.
  ///
  /// In ko, this message translates to:
  /// **'메뉴'**
  String get navMenu;

  /// No description provided for @navHome.
  ///
  /// In ko, this message translates to:
  /// **'홈'**
  String get navHome;

  /// No description provided for @navStats.
  ///
  /// In ko, this message translates to:
  /// **'통계'**
  String get navStats;

  /// No description provided for @navSearch.
  ///
  /// In ko, this message translates to:
  /// **'검색'**
  String get navSearch;

  /// No description provided for @navNotifications.
  ///
  /// In ko, this message translates to:
  /// **'알림'**
  String get navNotifications;

  /// No description provided for @navBudget.
  ///
  /// In ko, this message translates to:
  /// **'예산'**
  String get navBudget;

  /// No description provided for @navRecurring.
  ///
  /// In ko, this message translates to:
  /// **'반복 거래 관리'**
  String get navRecurring;

  /// No description provided for @navCategories.
  ///
  /// In ko, this message translates to:
  /// **'카테고리'**
  String get navCategories;

  /// No description provided for @navPresets.
  ///
  /// In ko, this message translates to:
  /// **'프리셋'**
  String get navPresets;

  /// No description provided for @navCards.
  ///
  /// In ko, this message translates to:
  /// **'카드 관리'**
  String get navCards;

  /// No description provided for @navSavingGoals.
  ///
  /// In ko, this message translates to:
  /// **'저축 목표'**
  String get navSavingGoals;

  /// No description provided for @navExport.
  ///
  /// In ko, this message translates to:
  /// **'내보내기'**
  String get navExport;

  /// No description provided for @navLogout.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get navLogout;

  /// No description provided for @navChangePassword.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 변경'**
  String get navChangePassword;

  /// No description provided for @notiTitle.
  ///
  /// In ko, this message translates to:
  /// **'알림'**
  String get notiTitle;

  /// No description provided for @notiEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 알림이 없어요'**
  String get notiEmpty;

  /// No description provided for @notiMarkAllRead.
  ///
  /// In ko, this message translates to:
  /// **'모두 읽음'**
  String get notiMarkAllRead;

  /// 알림 목록 머리 줄 — 서버가 센 안 읽은 수(천 단위 쉼표 포함)
  ///
  /// In ko, this message translates to:
  /// **'읽지 않은 알림 {count}개'**
  String notiUnreadHead(String count);

  /// No description provided for @notiLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'알림을 불러오지 못했어요'**
  String get notiLoadFailed;

  /// No description provided for @notiLoadFailedDesc.
  ///
  /// In ko, this message translates to:
  /// **'잠시 뒤 다시 시도해주세요.'**
  String get notiLoadFailedDesc;

  /// No description provided for @notiDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'알림을 삭제하지 못했어요.'**
  String get notiDeleteFailed;

  /// No description provided for @notiUnreadMark.
  ///
  /// In ko, this message translates to:
  /// **'안 읽음'**
  String get notiUnreadMark;

  /// No description provided for @notiMarkReadFailed.
  ///
  /// In ko, this message translates to:
  /// **'알림을 읽음으로 바꾸지 못했어요.'**
  String get notiMarkReadFailed;

  /// No description provided for @notiMarkAllFailed.
  ///
  /// In ko, this message translates to:
  /// **'알림을 모두 읽음으로 바꾸지 못했어요.'**
  String get notiMarkAllFailed;

  /// No description provided for @notiPrefsSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'알림 설정을 저장하지 못했어요.'**
  String get notiPrefsSaveFailed;

  /// No description provided for @notiSettingsLoadFailedDesc.
  ///
  /// In ko, this message translates to:
  /// **'잠시 뒤 다시 시도해주세요.'**
  String get notiSettingsLoadFailedDesc;

  /// No description provided for @notiThresholdLabel.
  ///
  /// In ko, this message translates to:
  /// **'경고로 표시할 사용률'**
  String get notiThresholdLabel;

  /// No description provided for @notiThresholdDesc.
  ///
  /// In ko, this message translates to:
  /// **'이 값을 넘으면 경고로 표시되고 알림을 받아요. 100%를 넘으면 초과 알림이 따로 와요.'**
  String get notiThresholdDesc;

  /// 알림 줄 끝 ⋮ 버튼의 이름 — 메뉴 시트의 이름이기도 하다
  ///
  /// In ko, this message translates to:
  /// **'{title} 더보기'**
  String notiMore(String title);

  /// No description provided for @notiDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'알림 삭제'**
  String get notiDeleteTitle;

  /// No description provided for @notiDeleteDescription.
  ///
  /// In ko, this message translates to:
  /// **'삭제한 알림은 되돌릴 수 없어요.'**
  String get notiDeleteDescription;

  /// No description provided for @notiTypeEventReminder.
  ///
  /// In ko, this message translates to:
  /// **'일정 알림'**
  String get notiTypeEventReminder;

  /// No description provided for @notiTypeBudgetAlert.
  ///
  /// In ko, this message translates to:
  /// **'예산 알림'**
  String get notiTypeBudgetAlert;

  /// No description provided for @notiTypeTodoReminder.
  ///
  /// In ko, this message translates to:
  /// **'할 일 알림'**
  String get notiTypeTodoReminder;

  /// No description provided for @notiTypeSystem.
  ///
  /// In ko, this message translates to:
  /// **'시스템 알림'**
  String get notiTypeSystem;

  /// No description provided for @notiConnectionLost.
  ///
  /// In ko, this message translates to:
  /// **'알림 연결이 끊어졌어요'**
  String get notiConnectionLost;

  /// No description provided for @notiConnectionRestored.
  ///
  /// In ko, this message translates to:
  /// **'알림 연결이 다시 이어졌어요'**
  String get notiConnectionRestored;

  /// No description provided for @notiNew.
  ///
  /// In ko, this message translates to:
  /// **'새 알림'**
  String get notiNew;

  /// No description provided for @assetTitle.
  ///
  /// In ko, this message translates to:
  /// **'자산 관리'**
  String get assetTitle;

  /// No description provided for @assetSummaryTotalBalance.
  ///
  /// In ko, this message translates to:
  /// **'총 자산'**
  String get assetSummaryTotalBalance;

  /// No description provided for @assetEmpty.
  ///
  /// In ko, this message translates to:
  /// **'등록된 자산이 없습니다'**
  String get assetEmpty;

  /// No description provided for @assetCreateFirst.
  ///
  /// In ko, this message translates to:
  /// **'첫 번째 자산을 등록해보세요'**
  String get assetCreateFirst;

  /// No description provided for @assetAdd.
  ///
  /// In ko, this message translates to:
  /// **'자산 추가'**
  String get assetAdd;

  /// No description provided for @assetEdit.
  ///
  /// In ko, this message translates to:
  /// **'자산 수정'**
  String get assetEdit;

  /// No description provided for @assetTransferAdd.
  ///
  /// In ko, this message translates to:
  /// **'이체 추가'**
  String get assetTransferAdd;

  /// No description provided for @assetTransferEmpty.
  ///
  /// In ko, this message translates to:
  /// **'이체 내역이 없습니다'**
  String get assetTransferEmpty;

  /// No description provided for @assetFee.
  ///
  /// In ko, this message translates to:
  /// **'수수료'**
  String get assetFee;

  /// No description provided for @assetTypeBankAccount.
  ///
  /// In ko, this message translates to:
  /// **'입출금'**
  String get assetTypeBankAccount;

  /// No description provided for @assetTypeSavings.
  ///
  /// In ko, this message translates to:
  /// **'예적금'**
  String get assetTypeSavings;

  /// No description provided for @assetTypeCash.
  ///
  /// In ko, this message translates to:
  /// **'현금'**
  String get assetTypeCash;

  /// No description provided for @assetTypeCreditCard.
  ///
  /// In ko, this message translates to:
  /// **'신용카드'**
  String get assetTypeCreditCard;

  /// No description provided for @assetTypeCheckCard.
  ///
  /// In ko, this message translates to:
  /// **'체크카드'**
  String get assetTypeCheckCard;

  /// No description provided for @assetTypeInvestment.
  ///
  /// In ko, this message translates to:
  /// **'투자'**
  String get assetTypeInvestment;

  /// No description provided for @assetTypeLoan.
  ///
  /// In ko, this message translates to:
  /// **'대출'**
  String get assetTypeLoan;

  /// No description provided for @assetGroupAccount.
  ///
  /// In ko, this message translates to:
  /// **'계좌 · 예금'**
  String get assetGroupAccount;

  /// No description provided for @assetGroupCard.
  ///
  /// In ko, this message translates to:
  /// **'카드'**
  String get assetGroupCard;

  /// No description provided for @assetGroupInvestment.
  ///
  /// In ko, this message translates to:
  /// **'투자'**
  String get assetGroupInvestment;

  /// No description provided for @assetGroupDebt.
  ///
  /// In ko, this message translates to:
  /// **'대출'**
  String get assetGroupDebt;

  /// No description provided for @assetCatAccount.
  ///
  /// In ko, this message translates to:
  /// **'계좌'**
  String get assetCatAccount;

  /// No description provided for @assetSubtypeInstallment.
  ///
  /// In ko, this message translates to:
  /// **'적금'**
  String get assetSubtypeInstallment;

  /// No description provided for @assetSubtypeDeposit.
  ///
  /// In ko, this message translates to:
  /// **'예금'**
  String get assetSubtypeDeposit;

  /// No description provided for @assetSubtypeOverdraft.
  ///
  /// In ko, this message translates to:
  /// **'마이너스 통장'**
  String get assetSubtypeOverdraft;

  /// No description provided for @assetLoadError.
  ///
  /// In ko, this message translates to:
  /// **'자산을 불러오지 못했습니다'**
  String get assetLoadError;

  /// No description provided for @assetEmptyState.
  ///
  /// In ko, this message translates to:
  /// **'아직 등록된 자산이 없어요'**
  String get assetEmptyState;

  /// No description provided for @assetEmptyHint.
  ///
  /// In ko, this message translates to:
  /// **'설정 → 계좌 · 카드 관리에서 추가할 수 있어요.'**
  String get assetEmptyHint;

  /// No description provided for @assetSummaryColAccounts.
  ///
  /// In ko, this message translates to:
  /// **'계좌·예금'**
  String get assetSummaryColAccounts;

  /// No description provided for @assetSummaryColCards.
  ///
  /// In ko, this message translates to:
  /// **'카드값'**
  String get assetSummaryColCards;

  /// No description provided for @assetTotalNetWorth.
  ///
  /// In ko, this message translates to:
  /// **'총 순자산'**
  String get assetTotalNetWorth;

  /// No description provided for @assetVsLastMonth.
  ///
  /// In ko, this message translates to:
  /// **'지난달 대비'**
  String get assetVsLastMonth;

  /// No description provided for @assetGroupEmpty.
  ///
  /// In ko, this message translates to:
  /// **'등록된 항목이 없어요.'**
  String get assetGroupEmpty;

  /// No description provided for @assetPaymentDayInfo.
  ///
  /// In ko, this message translates to:
  /// **'{day}일 결제'**
  String assetPaymentDayInfo(int day);

  /// No description provided for @assetExcludedFromTotal.
  ///
  /// In ko, this message translates to:
  /// **'총액 제외'**
  String get assetExcludedFromTotal;

  /// No description provided for @assetAmountHiddenBadge.
  ///
  /// In ko, this message translates to:
  /// **'금액 숨김'**
  String get assetAmountHiddenBadge;

  /// No description provided for @assetHideThisAmount.
  ///
  /// In ko, this message translates to:
  /// **'금액 가리기'**
  String get assetHideThisAmount;

  /// No description provided for @assetHideThisAmountDesc.
  ///
  /// In ko, this message translates to:
  /// **'이 자산의 금액만 가려요. 합계는 그대로 보여요.'**
  String get assetHideThisAmountDesc;

  /// No description provided for @assetManageTitle.
  ///
  /// In ko, this message translates to:
  /// **'계좌 · 카드 관리'**
  String get assetManageTitle;

  /// No description provided for @assetManageAdd.
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get assetManageAdd;

  /// No description provided for @assetManageEmptyHint.
  ///
  /// In ko, this message translates to:
  /// **'[추가]를 눌러 첫 계좌나 카드를 등록해보세요.'**
  String get assetManageEmptyHint;

  /// No description provided for @assetManageLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'계좌·카드를 불러오지 못했어요'**
  String get assetManageLoadFailed;

  /// No description provided for @assetHoldingsCount.
  ///
  /// In ko, this message translates to:
  /// **'보유 {count}종목'**
  String assetHoldingsCount(int count);

  /// No description provided for @assetIncludeInTotal.
  ///
  /// In ko, this message translates to:
  /// **'전체 자산 합계에 포함'**
  String get assetIncludeInTotal;

  /// No description provided for @assetIncludeInTotalDesc.
  ///
  /// In ko, this message translates to:
  /// **'순자산 · 총자산 계산에 반영돼요.'**
  String get assetIncludeInTotalDesc;

  /// No description provided for @assetTrendLoadError.
  ///
  /// In ko, this message translates to:
  /// **'추이를 불러오지 못했어요'**
  String get assetTrendLoadError;

  /// No description provided for @assetTrendEmpty.
  ///
  /// In ko, this message translates to:
  /// **'추이 데이터가 없어요.'**
  String get assetTrendEmpty;

  /// No description provided for @assetNetWorth.
  ///
  /// In ko, this message translates to:
  /// **'순자산'**
  String get assetNetWorth;

  /// No description provided for @assetCardLimitName.
  ///
  /// In ko, this message translates to:
  /// **'{name} 한도'**
  String assetCardLimitName(String name);

  /// No description provided for @assetChartNetWorthName.
  ///
  /// In ko, this message translates to:
  /// **'최근 12개월 순자산 추이 — 이번 달 {amount}'**
  String assetChartNetWorthName(String amount);

  /// No description provided for @assetChartTableMonth.
  ///
  /// In ko, this message translates to:
  /// **'달'**
  String get assetChartTableMonth;

  /// No description provided for @assetChartTableWeek.
  ///
  /// In ko, this message translates to:
  /// **'주'**
  String get assetChartTableWeek;

  /// No description provided for @assetTxLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'내역을 불러오지 못했어요'**
  String get assetTxLoadFailed;

  /// 투자 자산 상세 거래 기록 구역을 처음 받지 못했을 때 Result Section 제목 — 웹 query.failedNamed(name: trade.recordName)
  ///
  /// In ko, this message translates to:
  /// **'거래 기록 정보를 불러오지 못했어요'**
  String get assetTradesLoadFailed;

  /// No description provided for @assetMonthTx.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 내역'**
  String get assetMonthTx;

  /// No description provided for @assetHoldingLinkedPending.
  ///
  /// In ko, this message translates to:
  /// **'시세 연동 대기'**
  String get assetHoldingLinkedPending;

  /// No description provided for @assetPeriodAria.
  ///
  /// In ko, this message translates to:
  /// **'추이 기간'**
  String get assetPeriodAria;

  /// No description provided for @assetLoadFailedSummary.
  ///
  /// In ko, this message translates to:
  /// **'순자산을 불러오지 못했어요'**
  String get assetLoadFailedSummary;

  /// No description provided for @assetLoadFailedTrend.
  ///
  /// In ko, this message translates to:
  /// **'순자산 추이를 불러오지 못했어요'**
  String get assetLoadFailedTrend;

  /// No description provided for @assetLoadFailedAssets.
  ///
  /// In ko, this message translates to:
  /// **'자산을 불러오지 못했어요'**
  String get assetLoadFailedAssets;

  /// No description provided for @assetLoadFailedGoals.
  ///
  /// In ko, this message translates to:
  /// **'저축 목표를 불러오지 못했어요'**
  String get assetLoadFailedGoals;

  /// No description provided for @assetEmptyCta.
  ///
  /// In ko, this message translates to:
  /// **'계좌 · 카드 관리로 가기'**
  String get assetEmptyCta;

  /// No description provided for @assetAccountAdded.
  ///
  /// In ko, this message translates to:
  /// **'계좌가 추가되었습니다'**
  String get assetAccountAdded;

  /// No description provided for @assetAccountUpdated.
  ///
  /// In ko, this message translates to:
  /// **'계좌가 수정되었습니다'**
  String get assetAccountUpdated;

  /// No description provided for @assetAccountDeleted.
  ///
  /// In ko, this message translates to:
  /// **'계좌가 삭제되었습니다'**
  String get assetAccountDeleted;

  /// No description provided for @assetAccountDelete.
  ///
  /// In ko, this message translates to:
  /// **'계좌 삭제'**
  String get assetAccountDelete;

  /// No description provided for @assetAccountDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'\"{name}\"을(를) 목록에서 삭제해요. 연결된 거래 내역은 그대로 남아요. 삭제한 자산은 되돌릴 수 없어요.'**
  String assetAccountDeleteConfirm(String name);

  /// No description provided for @assetActionFailed.
  ///
  /// In ko, this message translates to:
  /// **'실패'**
  String get assetActionFailed;

  /// No description provided for @assetDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'삭제 실패'**
  String get assetDeleteFailed;

  /// No description provided for @assetInstitutionBrand.
  ///
  /// In ko, this message translates to:
  /// **'기관'**
  String get assetInstitutionBrand;

  /// No description provided for @assetBankSearchHint.
  ///
  /// In ko, this message translates to:
  /// **'기관 이름 검색'**
  String get assetBankSearchHint;

  /// No description provided for @assetNickname.
  ///
  /// In ko, this message translates to:
  /// **'별칭'**
  String get assetNickname;

  /// No description provided for @assetNicknamePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'예: 생활비 통장'**
  String get assetNicknamePlaceholder;

  /// No description provided for @assetNicknameRequired.
  ///
  /// In ko, this message translates to:
  /// **'별칭을 입력해주세요.'**
  String get assetNicknameRequired;

  /// No description provided for @assetNicknameDuplicate.
  ///
  /// In ko, this message translates to:
  /// **'같은 별칭의 자산이 이미 있어요.'**
  String get assetNicknameDuplicate;

  /// No description provided for @assetBalanceLabel.
  ///
  /// In ko, this message translates to:
  /// **'잔액'**
  String get assetBalanceLabel;

  /// No description provided for @assetBalanceEditHint.
  ///
  /// In ko, this message translates to:
  /// **'잔액을 바꾸면 지금 이전의 내역은 이 잔액에 이미 들어 있는 것으로 보고 이후 내역만 더해져요.'**
  String get assetBalanceEditHint;

  /// No description provided for @assetOverdraftUsedLabel.
  ///
  /// In ko, this message translates to:
  /// **'사용 중인 금액'**
  String get assetOverdraftUsedLabel;

  /// No description provided for @assetLoanRemainingLabel.
  ///
  /// In ko, this message translates to:
  /// **'남은 대출 금액'**
  String get assetLoanRemainingLabel;

  /// No description provided for @assetOverdraftLimitLabel.
  ///
  /// In ko, this message translates to:
  /// **'약정 한도'**
  String get assetOverdraftLimitLabel;

  /// No description provided for @assetOverdraftHint.
  ///
  /// In ko, this message translates to:
  /// **'쓴 만큼을 양수로 넣어주세요. 빚으로 계산돼요.'**
  String get assetOverdraftHint;

  /// No description provided for @assetLoanHint.
  ///
  /// In ko, this message translates to:
  /// **'아직 갚지 않은 금액을 적어주세요.'**
  String get assetLoanHint;

  /// No description provided for @assetCurrency.
  ///
  /// In ko, this message translates to:
  /// **'통화'**
  String get assetCurrency;

  /// No description provided for @assetExchangeRate.
  ///
  /// In ko, this message translates to:
  /// **'환율'**
  String get assetExchangeRate;

  /// No description provided for @assetExchangeRateHint.
  ///
  /// In ko, this message translates to:
  /// **'{code} 1당 원화'**
  String assetExchangeRateHint(String code);

  /// No description provided for @assetExchangeRateDesc.
  ///
  /// In ko, this message translates to:
  /// **'외화 잔액 · 예수금을 원화로 바꿀 때 써요.'**
  String get assetExchangeRateDesc;

  /// No description provided for @assetExchangeRateRequired.
  ///
  /// In ko, this message translates to:
  /// **'환율을 입력해주세요.'**
  String get assetExchangeRateRequired;

  /// No description provided for @assetMemoPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'예: 계좌번호 뒷자리 1234'**
  String get assetMemoPlaceholder;

  /// No description provided for @assetCreditLimitLabel.
  ///
  /// In ko, this message translates to:
  /// **'신용한도'**
  String get assetCreditLimitLabel;

  /// No description provided for @assetPaymentDayLabel.
  ///
  /// In ko, this message translates to:
  /// **'결제일'**
  String get assetPaymentDayLabel;

  /// No description provided for @assetPaymentDaySelect.
  ///
  /// In ko, this message translates to:
  /// **'결제일 선택'**
  String get assetPaymentDaySelect;

  /// No description provided for @assetPaymentDay.
  ///
  /// In ko, this message translates to:
  /// **'결제일'**
  String get assetPaymentDay;

  /// No description provided for @assetLinkedAccountLabel.
  ///
  /// In ko, this message translates to:
  /// **'연결 계좌'**
  String get assetLinkedAccountLabel;

  /// No description provided for @assetLinkedAccountSelect.
  ///
  /// In ko, this message translates to:
  /// **'연결 계좌 선택'**
  String get assetLinkedAccountSelect;

  /// No description provided for @assetLinkedAccountHint.
  ///
  /// In ko, this message translates to:
  /// **'이 카드로 결제하면 이 계좌에서 바로 빠져나가요.'**
  String get assetLinkedAccountHint;

  /// No description provided for @assetPaymentAccountLabel.
  ///
  /// In ko, this message translates to:
  /// **'결제 출금계좌'**
  String get assetPaymentAccountLabel;

  /// No description provided for @assetNoBankAccounts.
  ///
  /// In ko, this message translates to:
  /// **'입출금 계좌가 없어요'**
  String get assetNoBankAccounts;

  /// No description provided for @assetPaymentAccountSelect.
  ///
  /// In ko, this message translates to:
  /// **'결제 출금계좌 선택'**
  String get assetPaymentAccountSelect;

  /// No description provided for @assetPaymentAccountHint.
  ///
  /// In ko, this message translates to:
  /// **'결제일에 이 계좌에서 청구액이 빠져요.'**
  String get assetPaymentAccountHint;

  /// No description provided for @assetCardAdded.
  ///
  /// In ko, this message translates to:
  /// **'카드가 추가되었습니다'**
  String get assetCardAdded;

  /// No description provided for @assetCardUpdated.
  ///
  /// In ko, this message translates to:
  /// **'카드가 수정되었습니다'**
  String get assetCardUpdated;

  /// No description provided for @assetCardDelete.
  ///
  /// In ko, this message translates to:
  /// **'카드 삭제'**
  String get assetCardDelete;

  /// No description provided for @assetCardDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'\"{name}\"을(를) 목록에서 삭제해요. 연결된 거래 내역은 그대로 남아요. 삭제한 자산은 되돌릴 수 없어요.'**
  String assetCardDeleteConfirm(String name);

  /// No description provided for @assetCardDeleted.
  ///
  /// In ko, this message translates to:
  /// **'카드가 삭제되었습니다'**
  String get assetCardDeleted;

  /// No description provided for @assetCardProduct.
  ///
  /// In ko, this message translates to:
  /// **'카드 상품'**
  String get assetCardProduct;

  /// No description provided for @assetIncludeDiscontinued.
  ///
  /// In ko, this message translates to:
  /// **'단종 카드도 보기'**
  String get assetIncludeDiscontinued;

  /// No description provided for @assetCardSearchHint.
  ///
  /// In ko, this message translates to:
  /// **'카드 이름 검색'**
  String get assetCardSearchHint;

  /// No description provided for @assetCardNicknamePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'예: 생활 카드'**
  String get assetCardNicknamePlaceholder;

  /// No description provided for @assetCurrentUsage.
  ///
  /// In ko, this message translates to:
  /// **'이전 미결제 사용액'**
  String get assetCurrentUsage;

  /// No description provided for @assetCurrentUsageHint.
  ///
  /// In ko, this message translates to:
  /// **'아직 결제되지 않은 사용액을 적어주세요.'**
  String get assetCurrentUsageHint;

  /// No description provided for @assetOutstandingNow.
  ///
  /// In ko, this message translates to:
  /// **'지금 미결제 잔액 {amount}'**
  String assetOutstandingNow(String amount);

  /// No description provided for @assetCarryoverLocked.
  ///
  /// In ko, this message translates to:
  /// **'결제가 끝나 고칠 수 없어요.'**
  String get assetCarryoverLocked;

  /// No description provided for @assetDueCarryoverLabel.
  ///
  /// In ko, this message translates to:
  /// **'{date}에 결제될 금액'**
  String assetDueCarryoverLabel(String date);

  /// No description provided for @assetDueCarryoverHint.
  ///
  /// In ko, this message translates to:
  /// **'카드사 앱에 \'결제 예정 금액\'으로 보이는 금액이에요. 그날 결제계좌에서 빠져요.'**
  String get assetDueCarryoverHint;

  /// No description provided for @assetCarryoverAfterLabel.
  ///
  /// In ko, this message translates to:
  /// **'그 뒤 쓴 금액'**
  String get assetCarryoverAfterLabel;

  /// No description provided for @assetCarryoverAfterHint.
  ///
  /// In ko, this message translates to:
  /// **'지난 청구 뒤로 쓴 금액이에요. {date}에 결제돼요.'**
  String assetCarryoverAfterHint(String date);

  /// No description provided for @assetCarryoverAfterHintNoDate.
  ///
  /// In ko, this message translates to:
  /// **'지난 청구 뒤로 쓴 금액이에요.'**
  String get assetCarryoverAfterHintNoDate;

  /// No description provided for @assetPaymentDayChangeConfirm.
  ///
  /// In ko, this message translates to:
  /// **'바꾼 결제일은 다음 회차부터 적용돼요. {month}월분은 {date}에 결제돼요.'**
  String assetPaymentDayChangeConfirm(int month, String date);

  /// No description provided for @assetNewCard.
  ///
  /// In ko, this message translates to:
  /// **'새 카드'**
  String get assetNewCard;

  /// No description provided for @assetAnnualFee.
  ///
  /// In ko, this message translates to:
  /// **'연회비'**
  String get assetAnnualFee;

  /// No description provided for @assetCardShortCredit.
  ///
  /// In ko, this message translates to:
  /// **'신용'**
  String get assetCardShortCredit;

  /// No description provided for @assetCardShortCheck.
  ///
  /// In ko, this message translates to:
  /// **'체크'**
  String get assetCardShortCheck;

  /// No description provided for @assetDiscontinued.
  ///
  /// In ko, this message translates to:
  /// **'단종'**
  String get assetDiscontinued;

  /// No description provided for @assetInvestAdded.
  ///
  /// In ko, this message translates to:
  /// **'투자가 추가되었습니다'**
  String get assetInvestAdded;

  /// No description provided for @assetInvestUpdated.
  ///
  /// In ko, this message translates to:
  /// **'투자가 수정되었습니다'**
  String get assetInvestUpdated;

  /// No description provided for @assetInvestDeleted.
  ///
  /// In ko, this message translates to:
  /// **'투자가 삭제되었습니다'**
  String get assetInvestDeleted;

  /// No description provided for @assetInvestDelete.
  ///
  /// In ko, this message translates to:
  /// **'투자 삭제'**
  String get assetInvestDelete;

  /// No description provided for @assetInvestDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'\"{name}\"을(를) 목록에서 삭제해요. 연결된 거래 내역은 그대로 남아요. 삭제한 자산은 되돌릴 수 없어요.'**
  String assetInvestDeleteConfirm(String name);

  /// No description provided for @assetBrokerExchange.
  ///
  /// In ko, this message translates to:
  /// **'증권사 · 거래소'**
  String get assetBrokerExchange;

  /// No description provided for @assetInvestSearchHint.
  ///
  /// In ko, this message translates to:
  /// **'증권사 이름 검색'**
  String get assetInvestSearchHint;

  /// No description provided for @assetProductPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'예: 연금저축, 금 보유분'**
  String get assetProductPlaceholder;

  /// No description provided for @assetValuation.
  ///
  /// In ko, this message translates to:
  /// **'평가액 (원)'**
  String get assetValuation;

  /// No description provided for @assetNewInvestment.
  ///
  /// In ko, this message translates to:
  /// **'새 투자 상품'**
  String get assetNewInvestment;

  /// No description provided for @assetCryptoExchange.
  ///
  /// In ko, this message translates to:
  /// **'가상자산거래소'**
  String get assetCryptoExchange;

  /// No description provided for @assetCategoryCommercialBank.
  ///
  /// In ko, this message translates to:
  /// **'시중은행'**
  String get assetCategoryCommercialBank;

  /// No description provided for @assetCategoryInternetBank.
  ///
  /// In ko, this message translates to:
  /// **'인터넷은행'**
  String get assetCategoryInternetBank;

  /// No description provided for @assetCategoryLocalBank.
  ///
  /// In ko, this message translates to:
  /// **'지방은행'**
  String get assetCategoryLocalBank;

  /// No description provided for @assetCategorySpecialBank.
  ///
  /// In ko, this message translates to:
  /// **'특수은행'**
  String get assetCategorySpecialBank;

  /// No description provided for @assetCategorySavingsInstitution.
  ///
  /// In ko, this message translates to:
  /// **'저축기관'**
  String get assetCategorySavingsInstitution;

  /// No description provided for @assetCategoryForeignBank.
  ///
  /// In ko, this message translates to:
  /// **'외국계'**
  String get assetCategoryForeignBank;

  /// No description provided for @assetCategoryOther.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get assetCategoryOther;

  /// No description provided for @assetCategoryBrokerage.
  ///
  /// In ko, this message translates to:
  /// **'증권사'**
  String get assetCategoryBrokerage;

  /// No description provided for @assetCategoryCommodityExchange.
  ///
  /// In ko, this message translates to:
  /// **'상품거래소'**
  String get assetCategoryCommodityExchange;

  /// No description provided for @assetCategoryCryptoExchange.
  ///
  /// In ko, this message translates to:
  /// **'가상자산거래소'**
  String get assetCategoryCryptoExchange;

  /// No description provided for @assetCardDetail.
  ///
  /// In ko, this message translates to:
  /// **'카드 상세'**
  String get assetCardDetail;

  /// No description provided for @assetInvestDetail.
  ///
  /// In ko, this message translates to:
  /// **'투자 상세'**
  String get assetInvestDetail;

  /// No description provided for @assetAccountDetail.
  ///
  /// In ko, this message translates to:
  /// **'계좌 상세'**
  String get assetAccountDetail;

  /// No description provided for @assetHideAmount.
  ///
  /// In ko, this message translates to:
  /// **'금액 가리기'**
  String get assetHideAmount;

  /// No description provided for @assetPeriod3m.
  ///
  /// In ko, this message translates to:
  /// **'3개월'**
  String get assetPeriod3m;

  /// No description provided for @assetPeriod6m.
  ///
  /// In ko, this message translates to:
  /// **'6개월'**
  String get assetPeriod6m;

  /// No description provided for @assetPeriod1y.
  ///
  /// In ko, this message translates to:
  /// **'1년'**
  String get assetPeriod1y;

  /// No description provided for @assetWeeksCount.
  ///
  /// In ko, this message translates to:
  /// **'{weeks}주'**
  String assetWeeksCount(int weeks);

  /// No description provided for @assetTrendKindUsage.
  ///
  /// In ko, this message translates to:
  /// **'사용 추이'**
  String get assetTrendKindUsage;

  /// No description provided for @assetTrendKindValuation.
  ///
  /// In ko, this message translates to:
  /// **'평가액 추이'**
  String get assetTrendKindValuation;

  /// No description provided for @assetTrendKindBalance.
  ///
  /// In ko, this message translates to:
  /// **'잔액 추이'**
  String get assetTrendKindBalance;

  /// No description provided for @assetTrendRecent.
  ///
  /// In ko, this message translates to:
  /// **'최근 {weeks} {kind}'**
  String assetTrendRecent(String weeks, String kind);

  /// No description provided for @assetValueLabelCard.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 결제 예정'**
  String get assetValueLabelCard;

  /// No description provided for @assetValueLabelCheckCard.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 사용액'**
  String get assetValueLabelCheckCard;

  /// No description provided for @assetCheckCardMonthLabel.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 사용'**
  String get assetCheckCardMonthLabel;

  /// No description provided for @assetMonthTxCount.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 내역 · {count}'**
  String assetMonthTxCount(int count);

  /// No description provided for @assetValuationShort.
  ///
  /// In ko, this message translates to:
  /// **'평가액'**
  String get assetValuationShort;

  /// No description provided for @assetSeriesUsage.
  ///
  /// In ko, this message translates to:
  /// **'사용'**
  String get assetSeriesUsage;

  /// No description provided for @assetRecentTxCount.
  ///
  /// In ko, this message translates to:
  /// **'최근 거래 · {count}'**
  String assetRecentTxCount(int count);

  /// No description provided for @assetViewAll.
  ///
  /// In ko, this message translates to:
  /// **'전체 보기'**
  String get assetViewAll;

  /// No description provided for @assetTossLinkStarted.
  ///
  /// In ko, this message translates to:
  /// **'토스 시세 연동을 시작했어요'**
  String get assetTossLinkStarted;

  /// No description provided for @assetLinkFailed.
  ///
  /// In ko, this message translates to:
  /// **'연결 실패'**
  String get assetLinkFailed;

  /// No description provided for @assetTossUnlinked.
  ///
  /// In ko, this message translates to:
  /// **'토스 연결을 해제했어요'**
  String get assetTossUnlinked;

  /// No description provided for @assetUnlinkFailed.
  ///
  /// In ko, this message translates to:
  /// **'해제 실패'**
  String get assetUnlinkFailed;

  /// No description provided for @assetQtyUpdated.
  ///
  /// In ko, this message translates to:
  /// **'보유 수량을 수정했어요'**
  String get assetQtyUpdated;

  /// No description provided for @assetUpdateFailed.
  ///
  /// In ko, this message translates to:
  /// **'수정 실패'**
  String get assetUpdateFailed;

  /// No description provided for @assetTossLinked.
  ///
  /// In ko, this message translates to:
  /// **'토스 연동 중'**
  String get assetTossLinked;

  /// No description provided for @assetHoldings.
  ///
  /// In ko, this message translates to:
  /// **'보유 종목'**
  String get assetHoldings;

  /// No description provided for @tradeTitle.
  ///
  /// In ko, this message translates to:
  /// **'매수·매도'**
  String get tradeTitle;

  /// No description provided for @tradeBuy.
  ///
  /// In ko, this message translates to:
  /// **'매수'**
  String get tradeBuy;

  /// No description provided for @tradeSell.
  ///
  /// In ko, this message translates to:
  /// **'매도'**
  String get tradeSell;

  /// No description provided for @tradeBought.
  ///
  /// In ko, this message translates to:
  /// **'매수를 기록했어요'**
  String get tradeBought;

  /// No description provided for @tradeSold.
  ///
  /// In ko, this message translates to:
  /// **'매도를 기록했어요'**
  String get tradeSold;

  /// No description provided for @tradeHolding.
  ///
  /// In ko, this message translates to:
  /// **'종목'**
  String get tradeHolding;

  /// No description provided for @tradeHoldingType.
  ///
  /// In ko, this message translates to:
  /// **'종목 유형'**
  String get tradeHoldingType;

  /// No description provided for @tradeNoHolding.
  ///
  /// In ko, this message translates to:
  /// **'보유 종목이 없어요'**
  String get tradeNoHolding;

  /// No description provided for @tradeAddNewHolding.
  ///
  /// In ko, this message translates to:
  /// **'새 종목 사기'**
  String get tradeAddNewHolding;

  /// No description provided for @tradePickExisting.
  ///
  /// In ko, this message translates to:
  /// **'보유 종목에서 고르기'**
  String get tradePickExisting;

  /// No description provided for @tradeNewHoldingPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'종목명을 적어주세요'**
  String get tradeNewHoldingPlaceholder;

  /// No description provided for @tradeQuantity.
  ///
  /// In ko, this message translates to:
  /// **'수량'**
  String get tradeQuantity;

  /// No description provided for @tradeAmount.
  ///
  /// In ko, this message translates to:
  /// **'거래대금 (원)'**
  String get tradeAmount;

  /// No description provided for @tradeAmountHelp.
  ///
  /// In ko, this message translates to:
  /// **'수수료를 뺀 금액이에요. 수수료는 아래에 따로 적어주세요.'**
  String get tradeAmountHelp;

  /// No description provided for @tradeFee.
  ///
  /// In ko, this message translates to:
  /// **'수수료·세금 (원)'**
  String get tradeFee;

  /// No description provided for @tradeMemo.
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get tradeMemo;

  /// No description provided for @tradeMemoPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'선택 입력'**
  String get tradeMemoPlaceholder;

  /// No description provided for @tradeSettlement.
  ///
  /// In ko, this message translates to:
  /// **'결제 계좌'**
  String get tradeSettlement;

  /// No description provided for @tradeSettlementCash.
  ///
  /// In ko, this message translates to:
  /// **'증권계좌 예수금'**
  String get tradeSettlementCash;

  /// No description provided for @tradeSettlementCashHelp.
  ///
  /// In ko, this message translates to:
  /// **'증권계좌 예수금에서 결제해요. 모자라면 예수금이 마이너스로 남아요.'**
  String get tradeSettlementCashHelp;

  /// No description provided for @tradeSettlementAccountHelp.
  ///
  /// In ko, this message translates to:
  /// **'예수금이 모자라면 이 계좌에서 부족분만큼 자동으로 이체돼요.'**
  String get tradeSettlementAccountHelp;

  /// No description provided for @tradeSettlementDelta.
  ///
  /// In ko, this message translates to:
  /// **'결제 계좌 변동'**
  String get tradeSettlementDelta;

  /// No description provided for @tradeCashAfter.
  ///
  /// In ko, this message translates to:
  /// **'거래 후 예수금'**
  String get tradeCashAfter;

  /// No description provided for @tradeRealizedPreview.
  ///
  /// In ko, this message translates to:
  /// **'실현손익'**
  String get tradeRealizedPreview;

  /// No description provided for @tradeFundingNotice.
  ///
  /// In ko, this message translates to:
  /// **'예수금이 모자라 결제 계좌에서 {amount}만큼 옮겨요'**
  String tradeFundingNotice(String amount);

  /// No description provided for @tradeInsufficientCash.
  ///
  /// In ko, this message translates to:
  /// **'예수금이 마이너스가 돼요. 그대로 기록됩니다.'**
  String get tradeInsufficientCash;

  /// No description provided for @tradeInsufficientQty.
  ///
  /// In ko, this message translates to:
  /// **'보유 수량보다 많이 팔 수 없어요.'**
  String get tradeInsufficientQty;

  /// No description provided for @tradeQtyRequired.
  ///
  /// In ko, this message translates to:
  /// **'수량을 넣어주세요.'**
  String get tradeQtyRequired;

  /// No description provided for @tradeAmountRequired.
  ///
  /// In ko, this message translates to:
  /// **'거래대금을 넣어주세요.'**
  String get tradeAmountRequired;

  /// No description provided for @tradePreview.
  ///
  /// In ko, this message translates to:
  /// **'거래 후 미리보기'**
  String get tradePreview;

  /// No description provided for @tradeHistory.
  ///
  /// In ko, this message translates to:
  /// **'거래 기록'**
  String get tradeHistory;

  /// No description provided for @tradeDeleted.
  ///
  /// In ko, this message translates to:
  /// **'거래를 취소했어요'**
  String get tradeDeleted;

  /// No description provided for @tradeDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'거래 취소'**
  String get tradeDeleteTitle;

  /// No description provided for @tradeDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'이 거래를 취소하시겠어요? 예수금과 보유 수량이 거래 전으로 돌아가요.'**
  String get tradeDeleteConfirm;

  /// No description provided for @assetDetailTitle.
  ///
  /// In ko, this message translates to:
  /// **'자산 상세'**
  String get assetDetailTitle;

  /// No description provided for @assetNotFoundTitle.
  ///
  /// In ko, this message translates to:
  /// **'자산을 찾을 수 없어요'**
  String get assetNotFoundTitle;

  /// No description provided for @assetDetailDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'자산을 삭제하지 못했어요.'**
  String get assetDetailDeleteFailed;

  /// No description provided for @assetNotFoundDesc.
  ///
  /// In ko, this message translates to:
  /// **'지웠거나 없는 자산이에요.'**
  String get assetNotFoundDesc;

  /// No description provided for @assetNotFoundAction.
  ///
  /// In ko, this message translates to:
  /// **'자산으로'**
  String get assetNotFoundAction;

  /// No description provided for @assetLoadFailTitle.
  ///
  /// In ko, this message translates to:
  /// **'자산을 불러오지 못했어요'**
  String get assetLoadFailTitle;

  /// No description provided for @assetMoreOf.
  ///
  /// In ko, this message translates to:
  /// **'{name} 더보기'**
  String assetMoreOf(String name);

  /// No description provided for @tradeDetailTitle.
  ///
  /// In ko, this message translates to:
  /// **'거래 기록'**
  String get tradeDetailTitle;

  /// No description provided for @tradeKind.
  ///
  /// In ko, this message translates to:
  /// **'종류'**
  String get tradeKind;

  /// No description provided for @tradeHoldingLabel.
  ///
  /// In ko, this message translates to:
  /// **'종목'**
  String get tradeHoldingLabel;

  /// No description provided for @tradeUnitPrice.
  ///
  /// In ko, this message translates to:
  /// **'단가'**
  String get tradeUnitPrice;

  /// No description provided for @tradeAmountLabel.
  ///
  /// In ko, this message translates to:
  /// **'거래대금'**
  String get tradeAmountLabel;

  /// No description provided for @tradeFeeLabel.
  ///
  /// In ko, this message translates to:
  /// **'수수료 · 세금'**
  String get tradeFeeLabel;

  /// No description provided for @tradeDateTime.
  ///
  /// In ko, this message translates to:
  /// **'거래 일시'**
  String get tradeDateTime;

  /// No description provided for @tradeDeleteConfirmTarget.
  ///
  /// In ko, this message translates to:
  /// **'{date} {name} {qty} {kind} 거래를 취소할까요? 예수금과 보유 수량이 거래 전으로 돌아가요.'**
  String tradeDeleteConfirmTarget(
    String date,
    String name,
    String qty,
    String kind,
  );

  /// No description provided for @tradeCancelFailed.
  ///
  /// In ko, this message translates to:
  /// **'거래를 취소하지 못했어요.'**
  String get tradeCancelFailed;

  /// No description provided for @holdingTypeStock.
  ///
  /// In ko, this message translates to:
  /// **'주식'**
  String get holdingTypeStock;

  /// No description provided for @holdingTypeGold.
  ///
  /// In ko, this message translates to:
  /// **'금'**
  String get holdingTypeGold;

  /// No description provided for @holdingTypeCrypto.
  ///
  /// In ko, this message translates to:
  /// **'코인'**
  String get holdingTypeCrypto;

  /// No description provided for @holdingAvgPrice.
  ///
  /// In ko, this message translates to:
  /// **'평단가'**
  String get holdingAvgPrice;

  /// No description provided for @holdingAvgPriceInline.
  ///
  /// In ko, this message translates to:
  /// **'평단가 {avg}'**
  String holdingAvgPriceInline(String avg);

  /// No description provided for @holdingTotalCost.
  ///
  /// In ko, this message translates to:
  /// **'매수원가'**
  String get holdingTotalCost;

  /// No description provided for @tradeHeldSummary.
  ///
  /// In ko, this message translates to:
  /// **'보유 {qty} · 평단가 {avg}'**
  String tradeHeldSummary(String qty, String avg);

  /// No description provided for @assetCashBalance.
  ///
  /// In ko, this message translates to:
  /// **'예수금'**
  String get assetCashBalance;

  /// No description provided for @assetHoldingKrwInputHint.
  ///
  /// In ko, this message translates to:
  /// **'원화로 입력해요'**
  String get assetHoldingKrwInputHint;

  /// No description provided for @fxApproxKrw.
  ///
  /// In ko, this message translates to:
  /// **'약 {amount}'**
  String fxApproxKrw(String amount);

  /// No description provided for @assetHoldingBalance.
  ///
  /// In ko, this message translates to:
  /// **'평가금액'**
  String get assetHoldingBalance;

  /// 투자 편집 보유 머리 요약 — 연동 시세를 못 받아 합계를 모를 때(0 이라 하지 않는다)
  ///
  /// In ko, this message translates to:
  /// **'{count}종목 · —'**
  String assetHoldingsSummaryUnknown(int count);

  /// No description provided for @assetHoldingsSummary.
  ///
  /// In ko, this message translates to:
  /// **'{count}종목 · {amount}원'**
  String assetHoldingsSummary(int count, String amount);

  /// No description provided for @assetHoldingRep.
  ///
  /// In ko, this message translates to:
  /// **'{name} 외 {count}종목'**
  String assetHoldingRep(String name, int count);

  /// No description provided for @assetNoHoldings.
  ///
  /// In ko, this message translates to:
  /// **'보유 종목 없음'**
  String get assetNoHoldings;

  /// No description provided for @assetHoldingLinkedBadge.
  ///
  /// In ko, this message translates to:
  /// **'연동'**
  String get assetHoldingLinkedBadge;

  /// No description provided for @assetHoldingLinkedSub.
  ///
  /// In ko, this message translates to:
  /// **'현재가 {price} × 수량'**
  String assetHoldingLinkedSub(String price);

  /// No description provided for @assetHoldingManualSub.
  ///
  /// In ko, this message translates to:
  /// **'평가액 직접 입력'**
  String get assetHoldingManualSub;

  /// No description provided for @assetHoldingLinkedDetail.
  ///
  /// In ko, this message translates to:
  /// **'{qty}주 · 현재가 {price} 연동'**
  String assetHoldingLinkedDetail(String qty, String price);

  /// No description provided for @assetHoldingManualDetail.
  ///
  /// In ko, this message translates to:
  /// **'직접 입력'**
  String get assetHoldingManualDetail;

  /// No description provided for @assetHoldingsEmptyEdit.
  ///
  /// In ko, this message translates to:
  /// **'검색으로 보유 종목을 더할 수 있어요. 연동 종목은 현재가 × 수량으로 평가액이 자동 계산돼요.'**
  String get assetHoldingsEmptyEdit;

  /// No description provided for @assetHoldingsEmptyManual.
  ///
  /// In ko, this message translates to:
  /// **'위 버튼으로 보유분을 더할 수 있어요. 시세 연동이 없어 평가액은 직접 입력해요.'**
  String get assetHoldingsEmptyManual;

  /// No description provided for @assetHoldingsEmptyDetail.
  ///
  /// In ko, this message translates to:
  /// **'보유 종목이 없어요'**
  String get assetHoldingsEmptyDetail;

  /// No description provided for @assetHoldingSearchHint.
  ///
  /// In ko, this message translates to:
  /// **'종목 이름 검색'**
  String get assetHoldingSearchHint;

  /// No description provided for @assetHoldingAddManual.
  ///
  /// In ko, this message translates to:
  /// **'\"{name}\" 직접 추가 — 평가액 입력'**
  String assetHoldingAddManual(String name);

  /// No description provided for @assetSharesUnit.
  ///
  /// In ko, this message translates to:
  /// **'주'**
  String get assetSharesUnit;

  /// No description provided for @assetHoldingTypeStock.
  ///
  /// In ko, this message translates to:
  /// **'주식'**
  String get assetHoldingTypeStock;

  /// No description provided for @assetHoldingTypeGold.
  ///
  /// In ko, this message translates to:
  /// **'금'**
  String get assetHoldingTypeGold;

  /// No description provided for @assetHoldingTypeCrypto.
  ///
  /// In ko, this message translates to:
  /// **'코인'**
  String get assetHoldingTypeCrypto;

  /// No description provided for @assetHoldingAddGold.
  ///
  /// In ko, this message translates to:
  /// **'금 추가'**
  String get assetHoldingAddGold;

  /// No description provided for @assetHoldingAddCrypto.
  ///
  /// In ko, this message translates to:
  /// **'코인 추가'**
  String get assetHoldingAddCrypto;

  /// No description provided for @assetHoldingUnitGram.
  ///
  /// In ko, this message translates to:
  /// **'g'**
  String get assetHoldingUnitGram;

  /// No description provided for @assetHoldingUnitCount.
  ///
  /// In ko, this message translates to:
  /// **'개'**
  String get assetHoldingUnitCount;

  /// No description provided for @assetHoldingNamePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'항목 이름'**
  String get assetHoldingNamePlaceholder;

  /// No description provided for @assetHoldingQtyUnit.
  ///
  /// In ko, this message translates to:
  /// **'{qty}{unit}'**
  String assetHoldingQtyUnit(String qty, String unit);

  /// No description provided for @assetInvestHoldingsSub.
  ///
  /// In ko, this message translates to:
  /// **'투자 · 보유 {count}종목'**
  String assetInvestHoldingsSub(int count);

  /// No description provided for @assetTodayChange.
  ///
  /// In ko, this message translates to:
  /// **'오늘 {amount}원'**
  String assetTodayChange(String amount);

  /// No description provided for @assetSharesCount.
  ///
  /// In ko, this message translates to:
  /// **'{n}주'**
  String assetSharesCount(String n);

  /// No description provided for @assetTossValuationFormula.
  ///
  /// In ko, this message translates to:
  /// **'평가액 = 토스 현재가 × {qty}주 로 실시간 계산됩니다.'**
  String assetTossValuationFormula(int qty);

  /// No description provided for @assetHoldingQty.
  ///
  /// In ko, this message translates to:
  /// **'보유 수량'**
  String get assetHoldingQty;

  /// No description provided for @assetEditQty.
  ///
  /// In ko, this message translates to:
  /// **'수량 수정'**
  String get assetEditQty;

  /// No description provided for @assetUnlink.
  ///
  /// In ko, this message translates to:
  /// **'연결 해제'**
  String get assetUnlink;

  /// No description provided for @assetTossRealtimeTitle.
  ///
  /// In ko, this message translates to:
  /// **'토스 시세로 실시간 평가'**
  String get assetTossRealtimeTitle;

  /// No description provided for @assetTossRealtimeDesc.
  ///
  /// In ko, this message translates to:
  /// **'보유 종목과 수량을 등록하면 토스 현재가 × 수량으로 평가액이 실시간 반영됩니다.'**
  String get assetTossRealtimeDesc;

  /// No description provided for @assetTapToChange.
  ///
  /// In ko, this message translates to:
  /// **'변경하려면 탭'**
  String get assetTapToChange;

  /// No description provided for @assetStockSearchHint.
  ///
  /// In ko, this message translates to:
  /// **'종목명·코드 검색 (예: 삼성전자, 005930)'**
  String get assetStockSearchHint;

  /// No description provided for @stockSecurityTypeIndex.
  ///
  /// In ko, this message translates to:
  /// **'지수'**
  String get stockSecurityTypeIndex;

  /// No description provided for @stockSecurityTypeWarrant.
  ///
  /// In ko, this message translates to:
  /// **'워런트'**
  String get stockSecurityTypeWarrant;

  /// No description provided for @stockMarketKospi.
  ///
  /// In ko, this message translates to:
  /// **'코스피'**
  String get stockMarketKospi;

  /// No description provided for @stockMarketKosdaq.
  ///
  /// In ko, this message translates to:
  /// **'코스닥'**
  String get stockMarketKosdaq;

  /// No description provided for @stockMarketKonex.
  ///
  /// In ko, this message translates to:
  /// **'코넥스'**
  String get stockMarketKonex;

  /// No description provided for @stockMarketKrxIdx.
  ///
  /// In ko, this message translates to:
  /// **'KRX 지수'**
  String get stockMarketKrxIdx;

  /// No description provided for @stockMarketNas.
  ///
  /// In ko, this message translates to:
  /// **'나스닥'**
  String get stockMarketNas;

  /// No description provided for @stockMarketNys.
  ///
  /// In ko, this message translates to:
  /// **'뉴욕'**
  String get stockMarketNys;

  /// No description provided for @stockMarketAms.
  ///
  /// In ko, this message translates to:
  /// **'아멕스'**
  String get stockMarketAms;

  /// No description provided for @stockMarketShs.
  ///
  /// In ko, this message translates to:
  /// **'상해'**
  String get stockMarketShs;

  /// No description provided for @stockMarketShi.
  ///
  /// In ko, this message translates to:
  /// **'상해지수'**
  String get stockMarketShi;

  /// No description provided for @stockMarketSzs.
  ///
  /// In ko, this message translates to:
  /// **'심천'**
  String get stockMarketSzs;

  /// No description provided for @stockMarketSzi.
  ///
  /// In ko, this message translates to:
  /// **'심천지수'**
  String get stockMarketSzi;

  /// No description provided for @stockMarketTse.
  ///
  /// In ko, this message translates to:
  /// **'도쿄'**
  String get stockMarketTse;

  /// No description provided for @stockMarketHks.
  ///
  /// In ko, this message translates to:
  /// **'홍콩'**
  String get stockMarketHks;

  /// No description provided for @stockMarketHnx.
  ///
  /// In ko, this message translates to:
  /// **'하노이'**
  String get stockMarketHnx;

  /// No description provided for @stockMarketHsx.
  ///
  /// In ko, this message translates to:
  /// **'호치민'**
  String get stockMarketHsx;

  /// No description provided for @assetLinkByCode.
  ///
  /// In ko, this message translates to:
  /// **'「{code}」 코드로 연결'**
  String assetLinkByCode(String code);

  /// No description provided for @assetLink.
  ///
  /// In ko, this message translates to:
  /// **'연결'**
  String get assetLink;

  /// No description provided for @assetChartNoData.
  ///
  /// In ko, this message translates to:
  /// **'표시할 데이터가 없어요'**
  String get assetChartNoData;

  /// No description provided for @assetNoLinkedTx.
  ///
  /// In ko, this message translates to:
  /// **'연결된 거래 내역이 없어요.'**
  String get assetNoLinkedTx;

  /// No description provided for @assetTxFallback.
  ///
  /// In ko, this message translates to:
  /// **'거래'**
  String get assetTxFallback;

  /// No description provided for @assetPayConfirmMessage.
  ///
  /// In ko, this message translates to:
  /// **'결제 예정액 {amount}을 지금 결제할까요?'**
  String assetPayConfirmMessage(String amount);

  /// No description provided for @assetPayConfirmDateSuffix.
  ///
  /// In ko, this message translates to:
  /// **' {date} 결제 예정분이에요.'**
  String assetPayConfirmDateSuffix(String date);

  /// No description provided for @assetCancelPayment.
  ///
  /// In ko, this message translates to:
  /// **'결제 취소'**
  String get assetCancelPayment;

  /// No description provided for @assetCancelPaymentConfirm.
  ///
  /// In ko, this message translates to:
  /// **'{date}에 낸 {amount}원을 되돌려요. 통장 잔액과 카드 청구가 결제 전으로 돌아가요.'**
  String assetCancelPaymentConfirm(String amount, String date);

  /// No description provided for @assetPaymentCancelled.
  ///
  /// In ko, this message translates to:
  /// **'결제를 취소했어요'**
  String get assetPaymentCancelled;

  /// No description provided for @assetInstallmentPayoff.
  ///
  /// In ko, this message translates to:
  /// **'남은 할부 한 번에 정리'**
  String get assetInstallmentPayoff;

  /// No description provided for @assetInstallmentPayoffConfirm.
  ///
  /// In ko, this message translates to:
  /// **'남은 할부 {amount}원을 이번 결제 예정액에 한 번에 넣을까요? 다음 회차부터는 청구되지 않아요.'**
  String assetInstallmentPayoffConfirm(String amount);

  /// No description provided for @assetInstallmentPayoffUndo.
  ///
  /// In ko, this message translates to:
  /// **'되돌리기'**
  String get assetInstallmentPayoffUndo;

  /// No description provided for @assetInstallmentPayoffUndoConfirm.
  ///
  /// In ko, this message translates to:
  /// **'남은 원금 정리를 취소하고 원래 회차대로 나눠 낼까요?'**
  String get assetInstallmentPayoffUndoConfirm;

  /// No description provided for @assetInstallmentPaidOffBadge.
  ///
  /// In ko, this message translates to:
  /// **'남은 원금 정리됨'**
  String get assetInstallmentPaidOffBadge;

  /// No description provided for @assetInstallmentBadge.
  ///
  /// In ko, this message translates to:
  /// **'할부 {months}개월'**
  String assetInstallmentBadge(int months);

  /// No description provided for @assetInstallmentSeq.
  ///
  /// In ko, this message translates to:
  /// **'{seq}/{total}회차'**
  String assetInstallmentSeq(int seq, int total);

  /// No description provided for @assetInstallmentPrincipal.
  ///
  /// In ko, this message translates to:
  /// **'원금 {amount}'**
  String assetInstallmentPrincipal(String amount);

  /// No description provided for @assetInstallmentFallback.
  ///
  /// In ko, this message translates to:
  /// **'할부'**
  String get assetInstallmentFallback;

  /// No description provided for @assetLumpSumLabel.
  ///
  /// In ko, this message translates to:
  /// **'일시불'**
  String get assetLumpSumLabel;

  /// No description provided for @assetAlreadyPaidLabel.
  ///
  /// In ko, this message translates to:
  /// **'선결제 차감'**
  String get assetAlreadyPaidLabel;

  /// No description provided for @assetPayNow.
  ///
  /// In ko, this message translates to:
  /// **'지금 결제'**
  String get assetPayNow;

  /// No description provided for @assetPayFailed.
  ///
  /// In ko, this message translates to:
  /// **'결제하지 못했어요. 잠시 뒤 다시 시도해주세요.'**
  String get assetPayFailed;

  /// No description provided for @assetInstallmentPayoffFailed.
  ///
  /// In ko, this message translates to:
  /// **'할부를 정리하지 못했어요.'**
  String get assetInstallmentPayoffFailed;

  /// No description provided for @assetInstallmentPayoffUndoFailed.
  ///
  /// In ko, this message translates to:
  /// **'할부 정리를 되돌리지 못했어요.'**
  String get assetInstallmentPayoffUndoFailed;

  /// No description provided for @assetCancelPaymentFailed.
  ///
  /// In ko, this message translates to:
  /// **'결제를 취소하지 못했어요.'**
  String get assetCancelPaymentFailed;

  /// No description provided for @assetPayAction.
  ///
  /// In ko, this message translates to:
  /// **'결제하기'**
  String get assetPayAction;

  /// No description provided for @assetPayAmount.
  ///
  /// In ko, this message translates to:
  /// **'결제 금액'**
  String get assetPayAmount;

  /// No description provided for @assetPayRemainder.
  ///
  /// In ko, this message translates to:
  /// **'남은 {amount}은 결제일에 빠져요.'**
  String assetPayRemainder(String amount);

  /// No description provided for @assetPayMoveNote.
  ///
  /// In ko, this message translates to:
  /// **'계좌에서는 사용액으로 잡힌 {amount}만 빠져요. 나머지는 청구 기록으로만 남아요.'**
  String assetPayMoveNote(String amount);

  /// No description provided for @assetPayNoAccountNote.
  ///
  /// In ko, this message translates to:
  /// **'연결된 결제 계좌가 없어 이체 없이 사용액만 정리돼요.'**
  String get assetPayNoAccountNote;

  /// No description provided for @assetPaymentRecorded.
  ///
  /// In ko, this message translates to:
  /// **'결제가 기록되었습니다'**
  String get assetPaymentRecorded;

  /// No description provided for @assetBillingLoadError.
  ///
  /// In ko, this message translates to:
  /// **'청구 정보를 불러오지 못했어요'**
  String get assetBillingLoadError;

  /// No description provided for @assetUpcomingPayment.
  ///
  /// In ko, this message translates to:
  /// **'결제 예정'**
  String get assetUpcomingPayment;

  /// No description provided for @assetScheduledTag.
  ///
  /// In ko, this message translates to:
  /// **'예정'**
  String get assetScheduledTag;

  /// No description provided for @assetPaidDone.
  ///
  /// In ko, this message translates to:
  /// **'결제 완료'**
  String get assetPaidDone;

  /// No description provided for @assetLimitUsage.
  ///
  /// In ko, this message translates to:
  /// **'한도 사용'**
  String get assetLimitUsage;

  /// No description provided for @assetLimitPctUsed.
  ///
  /// In ko, this message translates to:
  /// **'{pct}% 사용'**
  String assetLimitPctUsed(int pct);

  /// No description provided for @assetLimitOf.
  ///
  /// In ko, this message translates to:
  /// **'{used} / 한도 {limit}'**
  String assetLimitOf(String used, String limit);

  /// No description provided for @assetLimitRemain.
  ///
  /// In ko, this message translates to:
  /// **'잔여 {amount}'**
  String assetLimitRemain(String amount);

  /// No description provided for @assetPerfRemain.
  ///
  /// In ko, this message translates to:
  /// **'실적까지 {amount}'**
  String assetPerfRemain(String amount);

  /// No description provided for @assetUsageHistory.
  ///
  /// In ko, this message translates to:
  /// **'이용 내역'**
  String get assetUsageHistory;

  /// No description provided for @assetSortRecent.
  ///
  /// In ko, this message translates to:
  /// **'최근순'**
  String get assetSortRecent;

  /// No description provided for @assetSortAmount.
  ///
  /// In ko, this message translates to:
  /// **'고액순'**
  String get assetSortAmount;

  /// No description provided for @assetSortCategory.
  ///
  /// In ko, this message translates to:
  /// **'카테고리별'**
  String get assetSortCategory;

  /// No description provided for @assetDueOn.
  ///
  /// In ko, this message translates to:
  /// **'{date} 결제'**
  String assetDueOn(String date);

  /// No description provided for @assetDueThisMonth.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 결제 예정'**
  String get assetDueThisMonth;

  /// No description provided for @assetUsagePeriodLabel.
  ///
  /// In ko, this message translates to:
  /// **'카드 이용 기간'**
  String get assetUsagePeriodLabel;

  /// No description provided for @assetCycleMix.
  ///
  /// In ko, this message translates to:
  /// **'이번 회차 구성'**
  String get assetCycleMix;

  /// No description provided for @assetPerfTitle.
  ///
  /// In ko, this message translates to:
  /// **'{month}월 실적'**
  String assetPerfTitle(String month);

  /// No description provided for @assetPerfAchieved.
  ///
  /// In ko, this message translates to:
  /// **'실적 달성'**
  String get assetPerfAchieved;

  /// No description provided for @assetPayAmountEmpty.
  ///
  /// In ko, this message translates to:
  /// **'결제 금액을 넣어주세요.'**
  String get assetPayAmountEmpty;

  /// No description provided for @assetPayAmountOver.
  ///
  /// In ko, this message translates to:
  /// **'결제 금액은 {amount}까지예요.'**
  String assetPayAmountOver(String amount);

  /// No description provided for @assetYearLabel.
  ///
  /// In ko, this message translates to:
  /// **'{year}년'**
  String assetYearLabel(String year);

  /// No description provided for @assetSortAria.
  ///
  /// In ko, this message translates to:
  /// **'이용 내역 정렬'**
  String get assetSortAria;

  /// No description provided for @assetPeriodPick.
  ///
  /// In ko, this message translates to:
  /// **'결제 회차'**
  String get assetPeriodPick;

  /// No description provided for @assetNoUsage.
  ///
  /// In ko, this message translates to:
  /// **'이용 내역이 없어요.'**
  String get assetNoUsage;

  /// No description provided for @assetBillingPeriod.
  ///
  /// In ko, this message translates to:
  /// **'{start}~{end} 사용분'**
  String assetBillingPeriod(String start, String end);

  /// No description provided for @assetMonthlyPaymentDay.
  ///
  /// In ko, this message translates to:
  /// **'매월 {day}일'**
  String assetMonthlyPaymentDay(int day);

  /// No description provided for @assetBillingHistory.
  ///
  /// In ko, this message translates to:
  /// **'청구 이력'**
  String get assetBillingHistory;

  /// No description provided for @assetStatusPending.
  ///
  /// In ko, this message translates to:
  /// **'대기'**
  String get assetStatusPending;

  /// No description provided for @assetStatusSkipped.
  ///
  /// In ko, this message translates to:
  /// **'건너뜀'**
  String get assetStatusSkipped;

  /// No description provided for @todoTitle.
  ///
  /// In ko, this message translates to:
  /// **'할 일'**
  String get todoTitle;

  /// No description provided for @todoEmpty.
  ///
  /// In ko, this message translates to:
  /// **'할 일이 없습니다'**
  String get todoEmpty;

  /// No description provided for @todoCreateFirst.
  ///
  /// In ko, this message translates to:
  /// **'첫 번째 할 일을 만들어보세요'**
  String get todoCreateFirst;

  /// No description provided for @todoQuickAddHint.
  ///
  /// In ko, this message translates to:
  /// **'+ 빠른 할 일 추가'**
  String get todoQuickAddHint;

  /// No description provided for @todoStatusAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get todoStatusAll;

  /// No description provided for @todoStatusCompleted.
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get todoStatusCompleted;

  /// No description provided for @todoPriorityAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get todoPriorityAll;

  /// No description provided for @todoPriorityHigh.
  ///
  /// In ko, this message translates to:
  /// **'높음'**
  String get todoPriorityHigh;

  /// No description provided for @todoPriorityMedium.
  ///
  /// In ko, this message translates to:
  /// **'보통'**
  String get todoPriorityMedium;

  /// No description provided for @todoPriorityLow.
  ///
  /// In ko, this message translates to:
  /// **'낮음'**
  String get todoPriorityLow;

  /// No description provided for @todoTagMgmt.
  ///
  /// In ko, this message translates to:
  /// **'태그 관리'**
  String get todoTagMgmt;

  /// No description provided for @memoTitle.
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get memoTitle;

  /// No description provided for @memoEmpty.
  ///
  /// In ko, this message translates to:
  /// **'메모가 없어요'**
  String get memoEmpty;

  /// No description provided for @memoSearchEmpty.
  ///
  /// In ko, this message translates to:
  /// **'결과가 없어요'**
  String get memoSearchEmpty;

  /// No description provided for @memoSearchHint.
  ///
  /// In ko, this message translates to:
  /// **'메모 검색'**
  String get memoSearchHint;

  /// No description provided for @memoPin.
  ///
  /// In ko, this message translates to:
  /// **'고정'**
  String get memoPin;

  /// No description provided for @memoUnpin.
  ///
  /// In ko, this message translates to:
  /// **'고정 해제'**
  String get memoUnpin;

  /// No description provided for @calTitle.
  ///
  /// In ko, this message translates to:
  /// **'캘린더'**
  String get calTitle;

  /// No description provided for @calToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get calToday;

  /// No description provided for @calMonthView.
  ///
  /// In ko, this message translates to:
  /// **'월'**
  String get calMonthView;

  /// No description provided for @calWeekView.
  ///
  /// In ko, this message translates to:
  /// **'주'**
  String get calWeekView;

  /// No description provided for @calDayView.
  ///
  /// In ko, this message translates to:
  /// **'일'**
  String get calDayView;

  /// No description provided for @calYearView.
  ///
  /// In ko, this message translates to:
  /// **'연'**
  String get calYearView;

  /// No description provided for @calAgendaView.
  ///
  /// In ko, this message translates to:
  /// **'안건'**
  String get calAgendaView;

  /// No description provided for @calNoEvents.
  ///
  /// In ko, this message translates to:
  /// **'일정이 없습니다'**
  String get calNoEvents;

  /// No description provided for @calEventAdd.
  ///
  /// In ko, this message translates to:
  /// **'일정 추가'**
  String get calEventAdd;

  /// No description provided for @calEventEdit.
  ///
  /// In ko, this message translates to:
  /// **'일정 수정'**
  String get calEventEdit;

  /// No description provided for @calEventDelete.
  ///
  /// In ko, this message translates to:
  /// **'일정 삭제'**
  String get calEventDelete;

  /// No description provided for @calLabelMgmt.
  ///
  /// In ko, this message translates to:
  /// **'라벨 관리'**
  String get calLabelMgmt;

  /// No description provided for @calMyCalendars.
  ///
  /// In ko, this message translates to:
  /// **'내 캘린더'**
  String get calMyCalendars;

  /// No description provided for @calAllDay.
  ///
  /// In ko, this message translates to:
  /// **'종일'**
  String get calAllDay;

  /// No description provided for @calRepeat.
  ///
  /// In ko, this message translates to:
  /// **'반복'**
  String get calRepeat;

  /// No description provided for @calRepeatNone.
  ///
  /// In ko, this message translates to:
  /// **'안 함'**
  String get calRepeatNone;

  /// No description provided for @calRepeatDaily.
  ///
  /// In ko, this message translates to:
  /// **'매일'**
  String get calRepeatDaily;

  /// No description provided for @calRepeatWeekly.
  ///
  /// In ko, this message translates to:
  /// **'매주'**
  String get calRepeatWeekly;

  /// No description provided for @calRepeatMonthly.
  ///
  /// In ko, this message translates to:
  /// **'매월'**
  String get calRepeatMonthly;

  /// No description provided for @calRepeatYearly.
  ///
  /// In ko, this message translates to:
  /// **'매년'**
  String get calRepeatYearly;

  /// No description provided for @calLocation.
  ///
  /// In ko, this message translates to:
  /// **'장소'**
  String get calLocation;

  /// No description provided for @calMemo.
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get calMemo;

  /// No description provided for @calStartDate.
  ///
  /// In ko, this message translates to:
  /// **'시작'**
  String get calStartDate;

  /// No description provided for @calEndDate.
  ///
  /// In ko, this message translates to:
  /// **'종료'**
  String get calEndDate;

  /// No description provided for @calFieldTitle.
  ///
  /// In ko, this message translates to:
  /// **'제목'**
  String get calFieldTitle;

  /// No description provided for @calFieldDescription.
  ///
  /// In ko, this message translates to:
  /// **'설명'**
  String get calFieldDescription;

  /// No description provided for @calFieldCalendar.
  ///
  /// In ko, this message translates to:
  /// **'캘린더'**
  String get calFieldCalendar;

  /// No description provided for @calFieldLabel.
  ///
  /// In ko, this message translates to:
  /// **'라벨'**
  String get calFieldLabel;

  /// No description provided for @calFieldColor.
  ///
  /// In ko, this message translates to:
  /// **'색상'**
  String get calFieldColor;

  /// No description provided for @calFieldName.
  ///
  /// In ko, this message translates to:
  /// **'이름'**
  String get calFieldName;

  /// No description provided for @calFieldReminder.
  ///
  /// In ko, this message translates to:
  /// **'알림'**
  String get calFieldReminder;

  /// No description provided for @calFieldStartDate.
  ///
  /// In ko, this message translates to:
  /// **'시작일'**
  String get calFieldStartDate;

  /// No description provided for @calFieldEndDate.
  ///
  /// In ko, this message translates to:
  /// **'종료일'**
  String get calFieldEndDate;

  /// No description provided for @calTitlePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'예: 치과 정기 검진'**
  String get calTitlePlaceholder;

  /// No description provided for @calDescriptionPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'예: 준비물과 안내 사항'**
  String get calDescriptionPlaceholder;

  /// No description provided for @calLocationPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'예: 본사 3층 회의실'**
  String get calLocationPlaceholder;

  /// No description provided for @calSelectCalendar.
  ///
  /// In ko, this message translates to:
  /// **'캘린더 선택'**
  String get calSelectCalendar;

  /// No description provided for @calNoLabel.
  ///
  /// In ko, this message translates to:
  /// **'라벨 없음'**
  String get calNoLabel;

  /// No description provided for @calLabelNamePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'예: 중요, 마감일, 회의'**
  String get calLabelNamePlaceholder;

  /// No description provided for @calCalendarNamePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'예: 가족, 업무, 운동 일정'**
  String get calCalendarNamePlaceholder;

  /// No description provided for @calCalendarNameFieldPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'캘린더 이름'**
  String get calCalendarNameFieldPlaceholder;

  /// No description provided for @calInviteCodePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'예: 3F9A1C2B'**
  String get calInviteCodePlaceholder;

  /// No description provided for @calRecurrenceNone.
  ///
  /// In ko, this message translates to:
  /// **'반복 안 함'**
  String get calRecurrenceNone;

  /// No description provided for @calFormNone.
  ///
  /// In ko, this message translates to:
  /// **'없음'**
  String get calFormNone;

  /// No description provided for @calFormNoReminder.
  ///
  /// In ko, this message translates to:
  /// **'알림 없음'**
  String get calFormNoReminder;

  /// No description provided for @calFormCalendarLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'불러오지 못했어요'**
  String get calFormCalendarLoadFailed;

  /// No description provided for @calFormLabelHint.
  ///
  /// In ko, this message translates to:
  /// **'라벨은 설정의 캘린더 라벨에서 만들어요'**
  String get calFormLabelHint;

  /// No description provided for @calFormStartDay.
  ///
  /// In ko, this message translates to:
  /// **'시작 날짜'**
  String get calFormStartDay;

  /// No description provided for @calFormStartTime.
  ///
  /// In ko, this message translates to:
  /// **'시작 시각'**
  String get calFormStartTime;

  /// No description provided for @calFormEndDay.
  ///
  /// In ko, this message translates to:
  /// **'종료 날짜'**
  String get calFormEndDay;

  /// No description provided for @calFormEndTime.
  ///
  /// In ko, this message translates to:
  /// **'종료 시각'**
  String get calFormEndTime;

  /// No description provided for @calFormEndBeforeStart.
  ///
  /// In ko, this message translates to:
  /// **'종료가 시작보다 빠를 수 없어요'**
  String get calFormEndBeforeStart;

  /// No description provided for @calFormTitleRequired.
  ///
  /// In ko, this message translates to:
  /// **'제목을 입력해주세요'**
  String get calFormTitleRequired;

  /// No description provided for @calFormRows.
  ///
  /// In ko, this message translates to:
  /// **'일정 정보'**
  String get calFormRows;

  /// No description provided for @calFormRowsMore.
  ///
  /// In ko, this message translates to:
  /// **'반복 · 알림 · 장소 · 설명'**
  String get calFormRowsMore;

  /// No description provided for @calFormSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'일정을 저장하지 못했어요. 잠시 뒤 다시 시도해주세요.'**
  String get calFormSaveFailed;

  /// No description provided for @calFormDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'일정을 삭제하지 못했어요.'**
  String get calFormDeleteFailed;

  /// No description provided for @calReminderMinutesBefore.
  ///
  /// In ko, this message translates to:
  /// **'{n}분 전'**
  String calReminderMinutesBefore(int n);

  /// No description provided for @calReminderHourBefore.
  ///
  /// In ko, this message translates to:
  /// **'1시간 전'**
  String get calReminderHourBefore;

  /// No description provided for @calReminderDayBefore.
  ///
  /// In ko, this message translates to:
  /// **'1일 전'**
  String get calReminderDayBefore;

  /// No description provided for @calEventDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'\"{title}\" 일정을 삭제할까요? 삭제한 일정은 되돌릴 수 없어요.'**
  String calEventDeleteConfirm(String title);

  /// No description provided for @calEventDeleteConfirmRecurring.
  ///
  /// In ko, this message translates to:
  /// **'\"{title}\" 은 반복 일정이라 모든 회차가 함께 삭제돼요. 삭제한 일정은 되돌릴 수 없어요.'**
  String calEventDeleteConfirmRecurring(String title);

  /// No description provided for @calEventAdded.
  ///
  /// In ko, this message translates to:
  /// **'일정이 추가되었습니다'**
  String get calEventAdded;

  /// No description provided for @calEventUpdated.
  ///
  /// In ko, this message translates to:
  /// **'일정이 수정되었습니다'**
  String get calEventUpdated;

  /// No description provided for @calLabelsTitle.
  ///
  /// In ko, this message translates to:
  /// **'캘린더 라벨'**
  String get calLabelsTitle;

  /// No description provided for @calAllLabelsCount.
  ///
  /// In ko, this message translates to:
  /// **'전체 라벨 · {count}'**
  String calAllLabelsCount(int count);

  /// No description provided for @calLabelsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'라벨이 없어요'**
  String get calLabelsEmpty;

  /// No description provided for @calLabelsEmptyHint.
  ///
  /// In ko, this message translates to:
  /// **'위 \'라벨 추가\' 로 만들어요'**
  String get calLabelsEmptyHint;

  /// No description provided for @calLabelsIntro.
  ///
  /// In ko, this message translates to:
  /// **'모든 캘린더에서 같이 쓰는 라벨이에요. 일정을 만들 때 골라요.'**
  String get calLabelsIntro;

  /// No description provided for @calNewLabel.
  ///
  /// In ko, this message translates to:
  /// **'라벨 추가'**
  String get calNewLabel;

  /// No description provided for @calEditLabel.
  ///
  /// In ko, this message translates to:
  /// **'라벨 수정'**
  String get calEditLabel;

  /// No description provided for @calPreview.
  ///
  /// In ko, this message translates to:
  /// **'미리보기'**
  String get calPreview;

  /// No description provided for @calDeleteLabelTitle.
  ///
  /// In ko, this message translates to:
  /// **'라벨 삭제'**
  String get calDeleteLabelTitle;

  /// No description provided for @calDeleteLabelConfirm.
  ///
  /// In ko, this message translates to:
  /// **'\"{name}\" 라벨을 삭제할까요? 이 라벨이 붙은 일정은 라벨 없이 남아요. 삭제한 라벨은 되돌릴 수 없어요.'**
  String calDeleteLabelConfirm(String name);

  /// No description provided for @calDatePicker.
  ///
  /// In ko, this message translates to:
  /// **'월 선택'**
  String get calDatePicker;

  /// No description provided for @calFilterChipName.
  ///
  /// In ko, this message translates to:
  /// **'캘린더 {count}개 보는 중'**
  String calFilterChipName(int count);

  /// No description provided for @calMoreEvents.
  ///
  /// In ko, this message translates to:
  /// **'+{count}개'**
  String calMoreEvents(int count);

  /// No description provided for @calEventsLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'일정을 불러오지 못했어요'**
  String get calEventsLoadFailed;

  /// No description provided for @calCalendarChipCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}개'**
  String calCalendarChipCount(int count);

  /// No description provided for @calNoCalendars.
  ///
  /// In ko, this message translates to:
  /// **'캘린더가 없어요.'**
  String get calNoCalendars;

  /// No description provided for @calOtherSources.
  ///
  /// In ko, this message translates to:
  /// **'기타 소스'**
  String get calOtherSources;

  /// No description provided for @calHolidays.
  ///
  /// In ko, this message translates to:
  /// **'공휴일'**
  String get calHolidays;

  /// No description provided for @calManageShareSettings.
  ///
  /// In ko, this message translates to:
  /// **'캘린더 관리 · 공유 설정'**
  String get calManageShareSettings;

  /// No description provided for @calNoEventsThisDay.
  ///
  /// In ko, this message translates to:
  /// **'이 날에 일정이 없어요.'**
  String get calNoEventsThisDay;

  /// No description provided for @calEventTotalCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}건'**
  String calEventTotalCount(int count);

  /// No description provided for @calManageShareTitle.
  ///
  /// In ko, this message translates to:
  /// **'캘린더 관리 · 공유'**
  String get calManageShareTitle;

  /// No description provided for @calJoinByCode.
  ///
  /// In ko, this message translates to:
  /// **'초대 코드로 참여'**
  String get calJoinByCode;

  /// No description provided for @calShareIntro.
  ///
  /// In ko, this message translates to:
  /// **'캘린더를 만들고 멤버를 초대해 가족 · 친구와 함께 일정을 관리해요.'**
  String get calShareIntro;

  /// No description provided for @calJoinSectionTitle.
  ///
  /// In ko, this message translates to:
  /// **'초대 코드'**
  String get calJoinSectionTitle;

  /// No description provided for @calRoleOwner.
  ///
  /// In ko, this message translates to:
  /// **'소유자'**
  String get calRoleOwner;

  /// No description provided for @calRoleEditor.
  ///
  /// In ko, this message translates to:
  /// **'편집 가능'**
  String get calRoleEditor;

  /// No description provided for @calRoleViewer.
  ///
  /// In ko, this message translates to:
  /// **'읽기 전용'**
  String get calRoleViewer;

  /// No description provided for @calNewCalendar.
  ///
  /// In ko, this message translates to:
  /// **'캘린더 추가'**
  String get calNewCalendar;

  /// No description provided for @calMyCalendarsCount.
  ///
  /// In ko, this message translates to:
  /// **'내 캘린더 · {count}'**
  String calMyCalendarsCount(int count);

  /// No description provided for @calNoOwnedCalendars.
  ///
  /// In ko, this message translates to:
  /// **'소유한 캘린더가 없어요'**
  String get calNoOwnedCalendars;

  /// No description provided for @calSharedCalendarsCount.
  ///
  /// In ko, this message translates to:
  /// **'공유받은 캘린더 · {count}'**
  String calSharedCalendarsCount(int count);

  /// No description provided for @calNoSharedCalendars.
  ///
  /// In ko, this message translates to:
  /// **'공유받은 캘린더가 없어요'**
  String get calNoSharedCalendars;

  /// No description provided for @calDefault.
  ///
  /// In ko, this message translates to:
  /// **'기본'**
  String get calDefault;

  /// No description provided for @calOnlyMe.
  ///
  /// In ko, this message translates to:
  /// **'나만 사용'**
  String get calOnlyMe;

  /// No description provided for @calMemberCount.
  ///
  /// In ko, this message translates to:
  /// **'멤버 {count}명'**
  String calMemberCount(int count);

  /// No description provided for @calJoinCardBody.
  ///
  /// In ko, this message translates to:
  /// **'공유받은 초대 코드를 넣으면 그 캘린더에 들어가요.'**
  String get calJoinCardBody;

  /// No description provided for @calJoin.
  ///
  /// In ko, this message translates to:
  /// **'참여'**
  String get calJoin;

  /// No description provided for @calCreate.
  ///
  /// In ko, this message translates to:
  /// **'만들기'**
  String get calCreate;

  /// No description provided for @calJoinedCalendar.
  ///
  /// In ko, this message translates to:
  /// **'\"{name}\" 캘린더에 참여했어요'**
  String calJoinedCalendar(String name);

  /// No description provided for @calInviteCode.
  ///
  /// In ko, this message translates to:
  /// **'초대 코드'**
  String get calInviteCode;

  /// No description provided for @calDeleteCalendar.
  ///
  /// In ko, this message translates to:
  /// **'캘린더 삭제'**
  String get calDeleteCalendar;

  /// No description provided for @calCalendarUpdated.
  ///
  /// In ko, this message translates to:
  /// **'캘린더를 수정했어요'**
  String get calCalendarUpdated;

  /// No description provided for @calInviteCodeRegenerated.
  ///
  /// In ko, this message translates to:
  /// **'초대 코드를 새로 만들었어요'**
  String get calInviteCodeRegenerated;

  /// No description provided for @calInviteCodeCopied.
  ///
  /// In ko, this message translates to:
  /// **'초대 코드를 복사했어요'**
  String get calInviteCodeCopied;

  /// No description provided for @calRemoveMember.
  ///
  /// In ko, this message translates to:
  /// **'멤버 내보내기'**
  String get calRemoveMember;

  /// No description provided for @calRemoveMemberConfirm.
  ///
  /// In ko, this message translates to:
  /// **'\"{name}\" 님을 캘린더에서 내보낼까요?'**
  String calRemoveMemberConfirm(String name);

  /// No description provided for @calRemove.
  ///
  /// In ko, this message translates to:
  /// **'내보내기'**
  String get calRemove;

  /// No description provided for @calDeleteCalendarConfirm.
  ///
  /// In ko, this message translates to:
  /// **'\"{name}\" 캘린더를 삭제할까요? 일정은 기본 캘린더로 옮겨지고, 멤버는 이 캘린더를 더 볼 수 없어요. 삭제한 캘린더는 되돌릴 수 없어요.'**
  String calDeleteCalendarConfirm(String name);

  /// No description provided for @calDeleteCalendarFailed.
  ///
  /// In ko, this message translates to:
  /// **'캘린더를 삭제하지 못했어요.'**
  String get calDeleteCalendarFailed;

  /// No description provided for @calLabelDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'라벨을 삭제하지 못했어요.'**
  String get calLabelDeleteFailed;

  /// No description provided for @calCopy.
  ///
  /// In ko, this message translates to:
  /// **'복사'**
  String get calCopy;

  /// No description provided for @calRegenerate.
  ///
  /// In ko, this message translates to:
  /// **'새로 만들기'**
  String get calRegenerate;

  /// No description provided for @calMembers.
  ///
  /// In ko, this message translates to:
  /// **'멤버'**
  String get calMembers;

  /// No description provided for @calMembersCount.
  ///
  /// In ko, this message translates to:
  /// **'멤버 · {count}'**
  String calMembersCount(int count);

  /// No description provided for @calMemberLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'멤버를 불러오지 못했어요'**
  String get calMemberLoadFailed;

  /// No description provided for @calManageNameTitle.
  ///
  /// In ko, this message translates to:
  /// **'캘린더 이름'**
  String get calManageNameTitle;

  /// No description provided for @calNameRequired.
  ///
  /// In ko, this message translates to:
  /// **'캘린더 이름을 입력해주세요.'**
  String get calNameRequired;

  /// No description provided for @calInviteHint.
  ///
  /// In ko, this message translates to:
  /// **'이 코드를 공유하면 다른 사람이 캘린더에 참여할 수 있어요.'**
  String get calInviteHint;

  /// No description provided for @calManageSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'저장하지 못했어요. 잠시 뒤 다시 시도해주세요.'**
  String get calManageSaveFailed;

  /// No description provided for @calCreateFailed.
  ///
  /// In ko, this message translates to:
  /// **'저장하지 못했어요. 잠시 뒤 다시 시도해주세요.'**
  String get calCreateFailed;

  /// No description provided for @calJoinInvalidCode.
  ///
  /// In ko, this message translates to:
  /// **'초대 코드를 확인해주세요.'**
  String get calJoinInvalidCode;

  /// No description provided for @calJoinAlreadyMember.
  ///
  /// In ko, this message translates to:
  /// **'이미 참여한 캘린더예요.'**
  String get calJoinAlreadyMember;

  /// No description provided for @calRemoveMemberFailed.
  ///
  /// In ko, this message translates to:
  /// **'멤버를 내보내지 못했어요.'**
  String get calRemoveMemberFailed;

  /// No description provided for @calColorChangeFailed.
  ///
  /// In ko, this message translates to:
  /// **'색을 바꾸지 못했어요.'**
  String get calColorChangeFailed;

  /// No description provided for @calRoleChangeFailed.
  ///
  /// In ko, this message translates to:
  /// **'권한을 바꾸지 못했어요.'**
  String get calRoleChangeFailed;

  /// No description provided for @calRegenerateFailed.
  ///
  /// In ko, this message translates to:
  /// **'초대 코드를 새로 만들지 못했어요.'**
  String get calRegenerateFailed;

  /// No description provided for @calInviteNone.
  ///
  /// In ko, this message translates to:
  /// **'초대 코드 없음'**
  String get calInviteNone;

  /// No description provided for @calJoinCodeRequired.
  ///
  /// In ko, this message translates to:
  /// **'초대 코드를 입력해주세요.'**
  String get calJoinCodeRequired;

  /// No description provided for @calLabelNameRequired.
  ///
  /// In ko, this message translates to:
  /// **'라벨 이름을 입력해주세요.'**
  String get calLabelNameRequired;

  /// No description provided for @calLabelNameDuplicate.
  ///
  /// In ko, this message translates to:
  /// **'같은 이름의 라벨이 이미 있어요.'**
  String get calLabelNameDuplicate;

  /// No description provided for @calLabelSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'저장하지 못했어요. 잠시 뒤 다시 시도해주세요.'**
  String get calLabelSaveFailed;

  /// No description provided for @calMeSuffix.
  ///
  /// In ko, this message translates to:
  /// **'(나)'**
  String get calMeSuffix;

  /// No description provided for @calMemberManage.
  ///
  /// In ko, this message translates to:
  /// **'{name} 관리'**
  String calMemberManage(String name);

  /// No description provided for @calChangeToEditor.
  ///
  /// In ko, this message translates to:
  /// **'편집 가능으로'**
  String get calChangeToEditor;

  /// No description provided for @calChangeToViewer.
  ///
  /// In ko, this message translates to:
  /// **'읽기 전용으로'**
  String get calChangeToViewer;

  /// No description provided for @calAdd.
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get calAdd;

  /// No description provided for @calActionFailed.
  ///
  /// In ko, this message translates to:
  /// **'실패'**
  String get calActionFailed;

  /// No description provided for @calSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'저장 실패'**
  String get calSaveFailed;

  /// No description provided for @calDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'삭제 실패'**
  String get calDeleteFailed;

  /// No description provided for @calJoinFailed.
  ///
  /// In ko, this message translates to:
  /// **'참여하지 못했어요. 잠시 뒤 다시 시도해주세요.'**
  String get calJoinFailed;

  /// No description provided for @calUpdateFailed.
  ///
  /// In ko, this message translates to:
  /// **'캘린더 표시를 바꾸지 못했어요.'**
  String get calUpdateFailed;

  /// No description provided for @importExecuteFailed.
  ///
  /// In ko, this message translates to:
  /// **'가져오지 못했어요.'**
  String get importExecuteFailed;

  /// No description provided for @calCalendarLoadError.
  ///
  /// In ko, this message translates to:
  /// **'캘린더를 불러오지 못했어요'**
  String get calCalendarLoadError;

  /// No description provided for @calLabelLoadError.
  ///
  /// In ko, this message translates to:
  /// **'라벨을 불러오지 못했어요'**
  String get calLabelLoadError;

  /// No description provided for @dashTitle.
  ///
  /// In ko, this message translates to:
  /// **'홈'**
  String get dashTitle;

  /// No description provided for @dashGreeting.
  ///
  /// In ko, this message translates to:
  /// **'오늘도 좋은 하루 되세요'**
  String get dashGreeting;

  /// No description provided for @dashTotalAssets.
  ///
  /// In ko, this message translates to:
  /// **'총 자산'**
  String get dashTotalAssets;

  /// No description provided for @dashChange.
  ///
  /// In ko, this message translates to:
  /// **'변화'**
  String get dashChange;

  /// No description provided for @dashThisMonthExpense.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 지출'**
  String get dashThisMonthExpense;

  /// No description provided for @dashThisMonthIncome.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 수입'**
  String get dashThisMonthIncome;

  /// No description provided for @dashRecent.
  ///
  /// In ko, this message translates to:
  /// **'최근 거래'**
  String get dashRecent;

  /// No description provided for @dashUpcoming.
  ///
  /// In ko, this message translates to:
  /// **'다가오는 일정'**
  String get dashUpcoming;

  /// No description provided for @dashRecentTodos.
  ///
  /// In ko, this message translates to:
  /// **'최근 할 일'**
  String get dashRecentTodos;

  /// No description provided for @dashOverdue.
  ///
  /// In ko, this message translates to:
  /// **'연체 {count}'**
  String dashOverdue(int count);

  /// No description provided for @dashOverdueRead.
  ///
  /// In ko, this message translates to:
  /// **'연체 {count}건'**
  String dashOverdueRead(int count);

  /// No description provided for @dashTrendTitle.
  ///
  /// In ko, this message translates to:
  /// **'최근 6개월'**
  String get dashTrendTitle;

  /// No description provided for @dashEmptyTransactions.
  ///
  /// In ko, this message translates to:
  /// **'최근 거래가 없습니다'**
  String get dashEmptyTransactions;

  /// No description provided for @dashEmptyEvents.
  ///
  /// In ko, this message translates to:
  /// **'예정된 일정이 없습니다'**
  String get dashEmptyEvents;

  /// No description provided for @dashEmptyTodos.
  ///
  /// In ko, this message translates to:
  /// **'처리할 할 일이 없습니다'**
  String get dashEmptyTodos;

  /// No description provided for @dashAddTx.
  ///
  /// In ko, this message translates to:
  /// **'거래 추가'**
  String get dashAddTx;

  /// No description provided for @dashTodayLabel.
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get dashTodayLabel;

  /// No description provided for @dashTomorrowLabel.
  ///
  /// In ko, this message translates to:
  /// **'내일'**
  String get dashTomorrowLabel;

  /// No description provided for @dashDaysLeft.
  ///
  /// In ko, this message translates to:
  /// **'D-{n}'**
  String dashDaysLeft(int n);

  /// No description provided for @dashVsLastMonth.
  ///
  /// In ko, this message translates to:
  /// **'지난달 대비'**
  String get dashVsLastMonth;

  /// No description provided for @dashLiabilities.
  ///
  /// In ko, this message translates to:
  /// **'부채'**
  String get dashLiabilities;

  /// No description provided for @dashMonthLedger.
  ///
  /// In ko, this message translates to:
  /// **'{month}월 가계부'**
  String dashMonthLedger(int month);

  /// No description provided for @dashDailyAvgPrefix.
  ///
  /// In ko, this message translates to:
  /// **'하루 평균 '**
  String get dashDailyAvgPrefix;

  /// No description provided for @dashSpentMasked.
  ///
  /// In ko, this message translates to:
  /// **' 썼어요.'**
  String get dashSpentMasked;

  /// No description provided for @dashSpentUnit.
  ///
  /// In ko, this message translates to:
  /// **'원 썼어요.'**
  String get dashSpentUnit;

  /// No description provided for @dashVsPrevPrefix.
  ///
  /// In ko, this message translates to:
  /// **' 전월 대비 '**
  String get dashVsPrevPrefix;

  /// No description provided for @dashSaving.
  ///
  /// In ko, this message translates to:
  /// **' 절약 중이에요.'**
  String get dashSaving;

  /// No description provided for @dashSpentMore.
  ///
  /// In ko, this message translates to:
  /// **' 더 썼어요.'**
  String get dashSpentMore;

  /// No description provided for @dashSame.
  ///
  /// In ko, this message translates to:
  /// **' 동일해요.'**
  String get dashSame;

  /// No description provided for @dashNoCategoryData.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 지출이 없어요'**
  String get dashNoCategoryData;

  /// No description provided for @dashNoBudget.
  ///
  /// In ko, this message translates to:
  /// **'등록된 예산이 없어요'**
  String get dashNoBudget;

  /// No description provided for @dashTodaySpend.
  ///
  /// In ko, this message translates to:
  /// **'오늘 쓴 돈'**
  String get dashTodaySpend;

  /// No description provided for @dashNoTodaySpend.
  ///
  /// In ko, this message translates to:
  /// **'오늘은 아직 쓴 돈이 없어요'**
  String get dashNoTodaySpend;

  /// No description provided for @dashViewAll.
  ///
  /// In ko, this message translates to:
  /// **'전체 보기'**
  String get dashViewAll;

  /// No description provided for @dashHideAmountsSettings.
  ///
  /// In ko, this message translates to:
  /// **'금액 가리기 설정'**
  String get dashHideAmountsSettings;

  /// No description provided for @dashNoLastMonth.
  ///
  /// In ko, this message translates to:
  /// **'지난달 기록 없음'**
  String get dashNoLastMonth;

  /// No description provided for @dashBudgetOf.
  ///
  /// In ko, this message translates to:
  /// **'{name} 예산'**
  String dashBudgetOf(String name);

  /// No description provided for @dashBudgetTotal.
  ///
  /// In ko, this message translates to:
  /// **'총 예산'**
  String get dashBudgetTotal;

  /// No description provided for @dashCategoryChartLabel.
  ///
  /// In ko, this message translates to:
  /// **'{month}월 카테고리별 지출, 합계 {total}'**
  String dashCategoryChartLabel(int month, String total);

  /// No description provided for @dashCategoryOthers.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get dashCategoryOthers;

  /// No description provided for @dashTableShare.
  ///
  /// In ko, this message translates to:
  /// **'비율'**
  String get dashTableShare;

  /// No description provided for @dashTableAmount.
  ///
  /// In ko, this message translates to:
  /// **'금액'**
  String get dashTableAmount;

  /// No description provided for @dashFailNetWorth.
  ///
  /// In ko, this message translates to:
  /// **'순자산을 불러오지 못했어요'**
  String get dashFailNetWorth;

  /// No description provided for @dashFailMonth.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 가계부를 불러오지 못했어요'**
  String get dashFailMonth;

  /// No description provided for @dashFailCategory.
  ///
  /// In ko, this message translates to:
  /// **'카테고리를 불러오지 못했어요'**
  String get dashFailCategory;

  /// No description provided for @dashFailBudget.
  ///
  /// In ko, this message translates to:
  /// **'예산을 불러오지 못했어요'**
  String get dashFailBudget;

  /// No description provided for @dashFailUpcoming.
  ///
  /// In ko, this message translates to:
  /// **'다가오는 일정을 불러오지 못했어요'**
  String get dashFailUpcoming;

  /// No description provided for @dashFailTodos.
  ///
  /// In ko, this message translates to:
  /// **'최근 할 일을 불러오지 못했어요'**
  String get dashFailTodos;

  /// No description provided for @dashFailToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘 쓴 돈을 불러오지 못했어요'**
  String get dashFailToday;

  /// No description provided for @dashFailDesc.
  ///
  /// In ko, this message translates to:
  /// **'잠시 뒤 다시 시도해주세요.'**
  String get dashFailDesc;

  /// No description provided for @expTitle.
  ///
  /// In ko, this message translates to:
  /// **'가계부'**
  String get expTitle;

  /// No description provided for @expFilterAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get expFilterAll;

  /// No description provided for @expFilterIncome.
  ///
  /// In ko, this message translates to:
  /// **'수입'**
  String get expFilterIncome;

  /// No description provided for @expFilterExpense.
  ///
  /// In ko, this message translates to:
  /// **'지출'**
  String get expFilterExpense;

  /// No description provided for @expFilterTransfer.
  ///
  /// In ko, this message translates to:
  /// **'이체'**
  String get expFilterTransfer;

  /// No description provided for @expEmpty.
  ///
  /// In ko, this message translates to:
  /// **'거래가 없습니다'**
  String get expEmpty;

  /// No description provided for @expEmptyDescription.
  ///
  /// In ko, this message translates to:
  /// **'새 거래를 추가해서 가계부를 시작하세요'**
  String get expEmptyDescription;

  /// No description provided for @expAdd.
  ///
  /// In ko, this message translates to:
  /// **'거래 추가'**
  String get expAdd;

  /// No description provided for @expEdit.
  ///
  /// In ko, this message translates to:
  /// **'거래 수정'**
  String get expEdit;

  /// No description provided for @expDelete.
  ///
  /// In ko, this message translates to:
  /// **'거래 삭제'**
  String get expDelete;

  /// No description provided for @expAmount.
  ///
  /// In ko, this message translates to:
  /// **'금액'**
  String get expAmount;

  /// No description provided for @expCategory.
  ///
  /// In ko, this message translates to:
  /// **'카테고리'**
  String get expCategory;

  /// No description provided for @expAsset.
  ///
  /// In ko, this message translates to:
  /// **'자산'**
  String get expAsset;

  /// No description provided for @expDate.
  ///
  /// In ko, this message translates to:
  /// **'날짜'**
  String get expDate;

  /// No description provided for @expMerchant.
  ///
  /// In ko, this message translates to:
  /// **'가맹점'**
  String get expMerchant;

  /// No description provided for @expPaymentMethod.
  ///
  /// In ko, this message translates to:
  /// **'결제 수단'**
  String get expPaymentMethod;

  /// No description provided for @expForeignPayment.
  ///
  /// In ko, this message translates to:
  /// **'해외 결제'**
  String get expForeignPayment;

  /// No description provided for @expCurrency.
  ///
  /// In ko, this message translates to:
  /// **'통화'**
  String get expCurrency;

  /// No description provided for @expOriginalAmount.
  ///
  /// In ko, this message translates to:
  /// **'현지 금액'**
  String get expOriginalAmount;

  /// No description provided for @expExchangeRate.
  ///
  /// In ko, this message translates to:
  /// **'환율'**
  String get expExchangeRate;

  /// No description provided for @expFxHint.
  ///
  /// In ko, this message translates to:
  /// **'{original} → {krw}'**
  String expFxHint(String original, String krw);

  /// No description provided for @expInstallment.
  ///
  /// In ko, this message translates to:
  /// **'할부'**
  String get expInstallment;

  /// No description provided for @expRefund.
  ///
  /// In ko, this message translates to:
  /// **'환불'**
  String get expRefund;

  /// No description provided for @expRefundConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'환불 처리'**
  String get expRefundConfirmTitle;

  /// No description provided for @expRefundConfirmBody.
  ///
  /// In ko, this message translates to:
  /// **'이 거래를 환불로 표시해요. 합계에서 빠지고 {amount}이 {asset}에 돌아가요.'**
  String expRefundConfirmBody(String amount, String asset);

  /// No description provided for @expRefundConfirmBodyRecordOnly.
  ///
  /// In ko, this message translates to:
  /// **'이 거래를 환불로 표시해요. 합계에서 빠져요.'**
  String get expRefundConfirmBodyRecordOnly;

  /// No description provided for @expRefundConfirmBodyCardNoAccount.
  ///
  /// In ko, this message translates to:
  /// **'결제계좌가 없어 카드 잔액만 정리돼요.'**
  String get expRefundConfirmBodyCardNoAccount;

  /// No description provided for @expRefundDate.
  ///
  /// In ko, this message translates to:
  /// **'환불일'**
  String get expRefundDate;

  /// No description provided for @expRefundConfirm.
  ///
  /// In ko, this message translates to:
  /// **'환불 처리'**
  String get expRefundConfirm;

  /// No description provided for @expRefundedAt.
  ///
  /// In ko, this message translates to:
  /// **'환불됨 · {date} — 합계에서 빠져 있어요.'**
  String expRefundedAt(String date);

  /// No description provided for @expRefundCancel.
  ///
  /// In ko, this message translates to:
  /// **'환불 취소'**
  String get expRefundCancel;

  /// No description provided for @expRefundCancelConfirm.
  ///
  /// In ko, this message translates to:
  /// **'환불 표시를 지울까요? 이 거래가 합계에 다시 들어가고, 환급된 금액도 되돌아가요.'**
  String get expRefundCancelConfirm;

  /// No description provided for @expRefundCancelConfirmPlain.
  ///
  /// In ko, this message translates to:
  /// **'환불 표시를 지울까요? 이 거래가 합계에 다시 들어가요.'**
  String get expRefundCancelConfirmPlain;

  /// No description provided for @expRefundedBadge.
  ///
  /// In ko, this message translates to:
  /// **'환불됨'**
  String get expRefundedBadge;

  /// No description provided for @expRefundedToast.
  ///
  /// In ko, this message translates to:
  /// **'미리 낸 돈 중 {amount}이 계좌로 돌아왔어요.'**
  String expRefundedToast(String amount);

  /// No description provided for @expLumpSum.
  ///
  /// In ko, this message translates to:
  /// **'일시불'**
  String get expLumpSum;

  /// No description provided for @expInstallmentMonths.
  ///
  /// In ko, this message translates to:
  /// **'{months}개월'**
  String expInstallmentMonths(int months);

  /// No description provided for @expInstallmentHint.
  ///
  /// In ko, this message translates to:
  /// **'매달 약 {perMonth}원씩 {months}회 청구돼요'**
  String expInstallmentHint(String perMonth, int months);

  /// No description provided for @expDescription.
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get expDescription;

  /// No description provided for @expTypeIncome.
  ///
  /// In ko, this message translates to:
  /// **'수입'**
  String get expTypeIncome;

  /// No description provided for @expTypeExpense.
  ///
  /// In ko, this message translates to:
  /// **'지출'**
  String get expTypeExpense;

  /// No description provided for @transferFeePrefix.
  ///
  /// In ko, this message translates to:
  /// **'수수료'**
  String get transferFeePrefix;

  /// No description provided for @transferReceivedTag.
  ///
  /// In ko, this message translates to:
  /// **'받는 금액 {amount}'**
  String transferReceivedTag(String amount);

  /// No description provided for @transferReceived.
  ///
  /// In ko, this message translates to:
  /// **'받는 금액'**
  String get transferReceived;

  /// No description provided for @transferPrincipal.
  ///
  /// In ko, this message translates to:
  /// **'원금'**
  String get transferPrincipal;

  /// No description provided for @transferWithdrawn.
  ///
  /// In ko, this message translates to:
  /// **'출금 합계'**
  String get transferWithdrawn;

  /// No description provided for @transferDeleted.
  ///
  /// In ko, this message translates to:
  /// **'이체를 삭제했어요'**
  String get transferDeleted;

  /// No description provided for @transferDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'이 이체를 삭제할까요? 양쪽 계좌 잔액이 이체 전으로 돌아가요. 삭제한 이체는 되돌릴 수 없어요.'**
  String get transferDeleteConfirm;

  /// No description provided for @transferDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'이체 삭제'**
  String get transferDeleteTitle;

  /// No description provided for @transferAutoTradeSettlement.
  ///
  /// In ko, this message translates to:
  /// **'주식을 살 때 예수금이 모자라 자동으로 만들어진 이체예요. 매수를 취소하면 함께 사라져요.'**
  String get transferAutoTradeSettlement;

  /// No description provided for @transferAutoCardPayment.
  ///
  /// In ko, this message translates to:
  /// **'카드 자동결제로 만들어진 이체예요. 청구 회차와 묶여 있어 따로 고칠 수 없어요.'**
  String get transferAutoCardPayment;

  /// No description provided for @transferAutoCardRefund.
  ///
  /// In ko, this message translates to:
  /// **'카드에 남은 과납금을 결제계좌로 돌려준 이체예요. 카드 잔액을 직접 보정하면 다음 날 자동으로 다시 맞춰져요.'**
  String get transferAutoCardRefund;

  /// No description provided for @transferAutoDefault.
  ///
  /// In ko, this message translates to:
  /// **'자동으로 만들어진 이체예요. 원래 거래를 지우면 함께 사라져요.'**
  String get transferAutoDefault;

  /// No description provided for @updateAvailable.
  ///
  /// In ko, this message translates to:
  /// **'{version} 버전이 나왔어요'**
  String updateAvailable(String version);

  /// No description provided for @updateAvailableDesc.
  ///
  /// In ko, this message translates to:
  /// **'눌러서 내려받아 설치하세요'**
  String get updateAvailableDesc;

  /// No description provided for @updateAvailableDescIos.
  ///
  /// In ko, this message translates to:
  /// **'눌러서 AltStore 에서 받으세요'**
  String get updateAvailableDescIos;

  /// No description provided for @updateSheetTitle.
  ///
  /// In ko, this message translates to:
  /// **'{version} 버전이 나왔어요'**
  String updateSheetTitle(String version);

  /// No description provided for @updateSheetSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'새 버전이 준비됐어요. 아래에서 바로 받을 수 있어요.'**
  String get updateSheetSubtitle;

  /// No description provided for @updateSheetChanges.
  ///
  /// In ko, this message translates to:
  /// **'이번에 달라진 점'**
  String get updateSheetChanges;

  /// No description provided for @updateSheetNoNotes.
  ///
  /// In ko, this message translates to:
  /// **'이번 버전의 변경 내용은 따로 정리되지 않았어요.'**
  String get updateSheetNoNotes;

  /// No description provided for @updateSheetLater.
  ///
  /// In ko, this message translates to:
  /// **'나중에'**
  String get updateSheetLater;

  /// No description provided for @updateSheetNow.
  ///
  /// In ko, this message translates to:
  /// **'업데이트'**
  String get updateSheetNow;

  /// No description provided for @updateSheetRetry.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get updateSheetRetry;

  /// No description provided for @updateSheetDownloading.
  ///
  /// In ko, this message translates to:
  /// **'받는 중이에요'**
  String get updateSheetDownloading;

  /// No description provided for @updateSheetOpening.
  ///
  /// In ko, this message translates to:
  /// **'설치 화면을 여는 중이에요'**
  String get updateSheetOpening;

  /// No description provided for @updateSheetFailed.
  ///
  /// In ko, this message translates to:
  /// **'앱에서 받지 못해 브라우저로 열어요.'**
  String get updateSheetFailed;

  /// No description provided for @updateTitle.
  ///
  /// In ko, this message translates to:
  /// **'업데이트'**
  String get updateTitle;

  /// No description provided for @updateGateTitle.
  ///
  /// In ko, this message translates to:
  /// **'새 버전 {version}이 나왔어요'**
  String updateGateTitle(String version);

  /// No description provided for @updateGateInstall.
  ///
  /// In ko, this message translates to:
  /// **'설치'**
  String get updateGateInstall;

  /// No description provided for @updateGateForcedCancelBody.
  ///
  /// In ko, this message translates to:
  /// **'꼭 필요한 업데이트가 들어 있어요.'**
  String get updateGateForcedCancelBody;

  /// No description provided for @updateCheckFailedTitle.
  ///
  /// In ko, this message translates to:
  /// **'업데이트를 확인하지 못했어요'**
  String get updateCheckFailedTitle;

  /// No description provided for @updateUpToDate.
  ///
  /// In ko, this message translates to:
  /// **'최신 버전이에요'**
  String get updateUpToDate;

  /// No description provided for @updateCurrentBuild.
  ///
  /// In ko, this message translates to:
  /// **'지금 빌드 {build}'**
  String updateCurrentBuild(String build);

  /// No description provided for @updateCheckFailed.
  ///
  /// In ko, this message translates to:
  /// **'새 버전을 확인하지 못했어요.'**
  String get updateCheckFailed;

  /// No description provided for @updateRequiredDesc.
  ///
  /// In ko, this message translates to:
  /// **'이번 버전부터 꼭 업데이트해야 해요. 받기 전에는 앱을 쓸 수 없어요.'**
  String get updateRequiredDesc;

  /// No description provided for @expScheduled.
  ///
  /// In ko, this message translates to:
  /// **'예정'**
  String get expScheduled;

  /// No description provided for @expTypeTransfer.
  ///
  /// In ko, this message translates to:
  /// **'이체'**
  String get expTypeTransfer;

  /// No description provided for @expTransferFrom.
  ///
  /// In ko, this message translates to:
  /// **'보낼 자산'**
  String get expTransferFrom;

  /// No description provided for @expTransferTo.
  ///
  /// In ko, this message translates to:
  /// **'받을 자산'**
  String get expTransferTo;

  /// No description provided for @expFee.
  ///
  /// In ko, this message translates to:
  /// **'수수료'**
  String get expFee;

  /// No description provided for @expFilter.
  ///
  /// In ko, this message translates to:
  /// **'필터'**
  String get expFilter;

  /// No description provided for @expFilterMin.
  ///
  /// In ko, this message translates to:
  /// **'최소'**
  String get expFilterMin;

  /// No description provided for @expFilterMax.
  ///
  /// In ko, this message translates to:
  /// **'최대'**
  String get expFilterMax;

  /// No description provided for @expFilterPeriod.
  ///
  /// In ko, this message translates to:
  /// **'기간'**
  String get expFilterPeriod;

  /// No description provided for @expSplit.
  ///
  /// In ko, this message translates to:
  /// **'내역 분할'**
  String get expSplit;

  /// No description provided for @expConvertDutch.
  ///
  /// In ko, this message translates to:
  /// **'더치페이로'**
  String get expConvertDutch;

  /// No description provided for @expConvertRecurring.
  ///
  /// In ko, this message translates to:
  /// **'반복 설정'**
  String get expConvertRecurring;

  /// No description provided for @expExport.
  ///
  /// In ko, this message translates to:
  /// **'내보내기'**
  String get expExport;

  /// No description provided for @expExportCsv.
  ///
  /// In ko, this message translates to:
  /// **'CSV 내보내기'**
  String get expExportCsv;

  /// No description provided for @expSummaryTitle.
  ///
  /// In ko, this message translates to:
  /// **'월간 요약'**
  String get expSummaryTitle;

  /// No description provided for @expSummaryIncome.
  ///
  /// In ko, this message translates to:
  /// **'수입'**
  String get expSummaryIncome;

  /// No description provided for @expSummaryExpense.
  ///
  /// In ko, this message translates to:
  /// **'지출'**
  String get expSummaryExpense;

  /// No description provided for @expSummaryBalance.
  ///
  /// In ko, this message translates to:
  /// **'잔액'**
  String get expSummaryBalance;

  /// No description provided for @budgetCategoryAdd.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 예산 추가'**
  String get budgetCategoryAdd;

  /// No description provided for @budgetCategoryEdit.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 예산 수정'**
  String get budgetCategoryEdit;

  /// No description provided for @budgetSubmitAdd.
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get budgetSubmitAdd;

  /// No description provided for @budgetFormAmountLabel.
  ///
  /// In ko, this message translates to:
  /// **'예산'**
  String get budgetFormAmountLabel;

  /// No description provided for @budgetFormCategoryPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 선택'**
  String get budgetFormCategoryPlaceholder;

  /// No description provided for @budgetFormQuickAmounts.
  ///
  /// In ko, this message translates to:
  /// **'빠른 금액'**
  String get budgetFormQuickAmounts;

  /// No description provided for @budgetFormErrCategory.
  ///
  /// In ko, this message translates to:
  /// **'카테고리를 골라주세요.'**
  String get budgetFormErrCategory;

  /// No description provided for @budgetFormErrTotal.
  ///
  /// In ko, this message translates to:
  /// **'총 예산을 입력해주세요.'**
  String get budgetFormErrTotal;

  /// No description provided for @budgetFormErrAmount.
  ///
  /// In ko, this message translates to:
  /// **'예산을 입력해주세요.'**
  String get budgetFormErrAmount;

  /// No description provided for @amountTooLarge.
  ///
  /// In ko, this message translates to:
  /// **'금액은 100억원까지 입력할 수 있어요.'**
  String get amountTooLarge;

  /// No description provided for @budgetPickUsed.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 예산이 있어요'**
  String get budgetPickUsed;

  /// No description provided for @budgetPickAllBudgeted.
  ///
  /// In ko, this message translates to:
  /// **'모든 지출 카테고리에 이미 예산이 있어요.'**
  String get budgetPickAllBudgeted;

  /// No description provided for @budgetPickNoCategory.
  ///
  /// In ko, this message translates to:
  /// **'예산을 줄 지출 카테고리가 없어요.'**
  String get budgetPickNoCategory;

  /// No description provided for @budgetPickLoadFailTitle.
  ///
  /// In ko, this message translates to:
  /// **'카테고리를 불러오지 못했어요'**
  String get budgetPickLoadFailTitle;

  /// No description provided for @budgetPickLoadFailDesc.
  ///
  /// In ko, this message translates to:
  /// **'잠시 뒤 다시 시도해주세요.'**
  String get budgetPickLoadFailDesc;

  /// No description provided for @budgetUpdated.
  ///
  /// In ko, this message translates to:
  /// **'예산이 수정되었습니다'**
  String get budgetUpdated;

  /// No description provided for @budgetAdded.
  ///
  /// In ko, this message translates to:
  /// **'예산이 추가되었습니다'**
  String get budgetAdded;

  /// No description provided for @budgetActionFailed.
  ///
  /// In ko, this message translates to:
  /// **'실패'**
  String get budgetActionFailed;

  /// No description provided for @budgetDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'\"{name}\" 예산을 삭제할까요?'**
  String budgetDeleteTitle(String name);

  /// No description provided for @budgetDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'삭제한 예산은 되돌릴 수 없어요.'**
  String get budgetDeleteConfirm;

  /// No description provided for @budgetDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'예산을 삭제하지 못했어요.'**
  String get budgetDeleteFailed;

  /// No description provided for @budgetSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'예산을 저장하지 못했어요.'**
  String get budgetSaveFailed;

  /// No description provided for @assetSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'자산을 저장하지 못했어요.'**
  String get assetSaveFailed;

  /// No description provided for @assetSaveCardForeign.
  ///
  /// In ko, this message translates to:
  /// **'카드는 원화로만 등록할 수 있어요.'**
  String get assetSaveCardForeign;

  /// No description provided for @assetSaveRateRequired.
  ///
  /// In ko, this message translates to:
  /// **'외화 자산은 환율을 입력해야 저장할 수 있어요.'**
  String get assetSaveRateRequired;

  /// No description provided for @tradeSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'매매를 처리하지 못했어요.'**
  String get tradeSaveFailed;

  /// No description provided for @tradeSaveInsufficientQty.
  ///
  /// In ko, this message translates to:
  /// **'보유 수량이 부족해요.'**
  String get tradeSaveInsufficientQty;

  /// No description provided for @budgetMonthlyLimit.
  ///
  /// In ko, this message translates to:
  /// **'월 예산 한도'**
  String get budgetMonthlyLimit;

  /// No description provided for @budgetLoadError.
  ///
  /// In ko, this message translates to:
  /// **'예산을 불러오지 못했습니다'**
  String get budgetLoadError;

  /// No description provided for @budgetSelectMonth.
  ///
  /// In ko, this message translates to:
  /// **'월 선택'**
  String get budgetSelectMonth;

  /// No description provided for @budgetMonthOverallCap.
  ///
  /// In ko, this message translates to:
  /// **'{month}월 총 예산'**
  String budgetMonthOverallCap(int month);

  /// No description provided for @budgetOverallCapDesc.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 전체 지출의 상한이에요 (카테고리 예산이 없는 지출도 포함).'**
  String get budgetOverallCapDesc;

  /// No description provided for @budgetOverallCapEmptyHint.
  ///
  /// In ko, this message translates to:
  /// **'총 예산이 아직 없어요. 설정에서 이번 달 최대 지출 한도를 정할 수 있어요.'**
  String get budgetOverallCapEmptyHint;

  /// No description provided for @budgetEmptyMonthTitle.
  ///
  /// In ko, this message translates to:
  /// **'{month}월 예산이 아직 없어요'**
  String budgetEmptyMonthTitle(int month);

  /// No description provided for @budgetEmptyMonthDesc.
  ///
  /// In ko, this message translates to:
  /// **'예산을 정하면 쓴 돈과 남은 돈을 한눈에 볼 수 있어요.'**
  String get budgetEmptyMonthDesc;

  /// No description provided for @budgetFailCompliance.
  ///
  /// In ko, this message translates to:
  /// **'예산 이행률을 불러오지 못했어요'**
  String get budgetFailCompliance;

  /// No description provided for @budgetManagerLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'예산을 불러오지 못했어요'**
  String get budgetManagerLoadFailed;

  /// No description provided for @budgetCategoryCount.
  ///
  /// In ko, this message translates to:
  /// **'{count} 카테고리'**
  String budgetCategoryCount(int count);

  /// No description provided for @budgetOverLimit.
  ///
  /// In ko, this message translates to:
  /// **'한도 초과 {amount}'**
  String budgetOverLimit(String amount);

  /// No description provided for @budgetTableMonth.
  ///
  /// In ko, this message translates to:
  /// **'달'**
  String get budgetTableMonth;

  /// No description provided for @budgetCurrentCategorySum.
  ///
  /// In ko, this message translates to:
  /// **'현재 카테고리 한도 합계'**
  String get budgetCurrentCategorySum;

  /// No description provided for @budgetPercentUsed.
  ///
  /// In ko, this message translates to:
  /// **'{pct}% 사용'**
  String budgetPercentUsed(String pct);

  /// No description provided for @budgetRemaining.
  ///
  /// In ko, this message translates to:
  /// **'남은 예산 {amount}'**
  String budgetRemaining(String amount);

  /// No description provided for @budgetOverBy.
  ///
  /// In ko, this message translates to:
  /// **'한도 {amount} 초과'**
  String budgetOverBy(String amount);

  /// No description provided for @budgetOverallCapLabel.
  ///
  /// In ko, this message translates to:
  /// **'총 예산'**
  String get budgetOverallCapLabel;

  /// No description provided for @budgetCategoryAllocated.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 할당'**
  String get budgetCategoryAllocated;

  /// No description provided for @budgetAllocatable.
  ///
  /// In ko, this message translates to:
  /// **'할당 가능'**
  String get budgetAllocatable;

  /// No description provided for @budgetOverAllocatedWarning.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 한도 합이 총 예산을 {amount} 초과했어요. 총 예산을 올리거나 카테고리 한도를 줄여주세요.'**
  String budgetOverAllocatedWarning(String amount);

  /// No description provided for @budgetSpendingPace.
  ///
  /// In ko, this message translates to:
  /// **'지출 페이스'**
  String get budgetSpendingPace;

  /// No description provided for @budgetPaceBarName.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 지출 페이스'**
  String get budgetPaceBarName;

  /// No description provided for @budgetPaceBarValue.
  ///
  /// In ko, this message translates to:
  /// **'{used}% 사용 · 이번 달 {elapsed}% 지남'**
  String budgetPaceBarValue(String used, String elapsed);

  /// No description provided for @budgetPaceOnTrack.
  ///
  /// In ko, this message translates to:
  /// **'정상 속도'**
  String get budgetPaceOnTrack;

  /// No description provided for @budgetPaceFast.
  ///
  /// In ko, this message translates to:
  /// **'빠른 속도'**
  String get budgetPaceFast;

  /// No description provided for @budgetMonthElapsed.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 {pct}% 경과 ↑'**
  String budgetMonthElapsed(String pct);

  /// No description provided for @budgetDailyAvg.
  ///
  /// In ko, this message translates to:
  /// **'일평균 지출'**
  String get budgetDailyAvg;

  /// No description provided for @budgetDailyRecommended.
  ///
  /// In ko, this message translates to:
  /// **'남은 일 권장 지출'**
  String get budgetDailyRecommended;

  /// No description provided for @budgetStatusTitle.
  ///
  /// In ko, this message translates to:
  /// **'예산 현황'**
  String get budgetStatusTitle;

  /// No description provided for @budgetOver.
  ///
  /// In ko, this message translates to:
  /// **'초과'**
  String get budgetOver;

  /// No description provided for @budgetHealthy.
  ///
  /// In ko, this message translates to:
  /// **'여유'**
  String get budgetHealthy;

  /// No description provided for @budgetByCategory.
  ///
  /// In ko, this message translates to:
  /// **'카테고리별 예산'**
  String get budgetByCategory;

  /// No description provided for @budgetCountSet.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 설정됨'**
  String budgetCountSet(int count);

  /// No description provided for @budgetNoCategoryBudgets.
  ///
  /// In ko, this message translates to:
  /// **'카테고리별 예산이 없어요'**
  String get budgetNoCategoryBudgets;

  /// No description provided for @budgetGoToSettings.
  ///
  /// In ko, this message translates to:
  /// **'예산 설정하러 가기'**
  String get budgetGoToSettings;

  /// No description provided for @budgetCategoryFallback.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 #{id}'**
  String budgetCategoryFallback(int id);

  /// No description provided for @budgetComplianceTitle.
  ///
  /// In ko, this message translates to:
  /// **'최근 6개월 예산 이행률'**
  String get budgetComplianceTitle;

  /// No description provided for @budgetComplianceSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'한도 대비 지출 %'**
  String get budgetComplianceSubtitle;

  /// No description provided for @budgetNoComplianceData.
  ///
  /// In ko, this message translates to:
  /// **'아직 이행률 데이터가 없어요'**
  String get budgetNoComplianceData;

  /// No description provided for @budgetVsLimit.
  ///
  /// In ko, this message translates to:
  /// **'한도 대비'**
  String get budgetVsLimit;

  /// No description provided for @budgetLimit.
  ///
  /// In ko, this message translates to:
  /// **'한도'**
  String get budgetLimit;

  /// No description provided for @budgetSetup.
  ///
  /// In ko, this message translates to:
  /// **'예산 설정'**
  String get budgetSetup;

  /// No description provided for @budgetCopyLastMonth.
  ///
  /// In ko, this message translates to:
  /// **'지난달 예산을 복사할까요?'**
  String get budgetCopyLastMonth;

  /// No description provided for @budgetCopyOverwriteMessage.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 예산 {count}개가 지난달 예산으로 바뀌어요. 바꾼 뒤에는 되돌릴 수 없어요.'**
  String budgetCopyOverwriteMessage(int count);

  /// No description provided for @budgetCopyPartialFailed.
  ///
  /// In ko, this message translates to:
  /// **'가져오지 못한 예산이 {count}개 있어요.'**
  String budgetCopyPartialFailed(int count);

  /// No description provided for @budgetCopiedDone.
  ///
  /// In ko, this message translates to:
  /// **'지난달 예산을 가져왔어요.'**
  String get budgetCopiedDone;

  /// No description provided for @budgetCopyUndo.
  ///
  /// In ko, this message translates to:
  /// **'되돌리기'**
  String get budgetCopyUndo;

  /// No description provided for @budgetCopyUndoPartial.
  ///
  /// In ko, this message translates to:
  /// **'되돌리지 못한 예산이 {count}개 남았어요.'**
  String budgetCopyUndoPartial(int count);

  /// No description provided for @budgetCopyLastMonthBtn.
  ///
  /// In ko, this message translates to:
  /// **'지난달 복사'**
  String get budgetCopyLastMonthBtn;

  /// No description provided for @budgetMonthTotal.
  ///
  /// In ko, this message translates to:
  /// **'{month}월 총 예산'**
  String budgetMonthTotal(int month);

  /// No description provided for @budgetNotSet.
  ///
  /// In ko, this message translates to:
  /// **'설정 안 됨'**
  String get budgetNotSet;

  /// No description provided for @budgetUsed.
  ///
  /// In ko, this message translates to:
  /// **'사용'**
  String get budgetUsed;

  /// No description provided for @budgetAllocated.
  ///
  /// In ko, this message translates to:
  /// **'할당됨'**
  String get budgetAllocated;

  /// No description provided for @budgetByCategoryCount.
  ///
  /// In ko, this message translates to:
  /// **'카테고리별 예산 · {count}개'**
  String budgetByCategoryCount(int count);

  /// No description provided for @budgetAdd.
  ///
  /// In ko, this message translates to:
  /// **'예산 추가'**
  String get budgetAdd;

  /// No description provided for @budgetNoCategorySet.
  ///
  /// In ko, this message translates to:
  /// **'설정된 카테고리 예산이 없어요'**
  String get budgetNoCategorySet;

  /// No description provided for @cardBenefitTypeDiscount.
  ///
  /// In ko, this message translates to:
  /// **'할인'**
  String get cardBenefitTypeDiscount;

  /// No description provided for @cardBenefitTypePoint.
  ///
  /// In ko, this message translates to:
  /// **'적립'**
  String get cardBenefitTypePoint;

  /// No description provided for @cardBenefitTypeMileage.
  ///
  /// In ko, this message translates to:
  /// **'마일리지'**
  String get cardBenefitTypeMileage;

  /// No description provided for @cardBenefitsTitle.
  ///
  /// In ko, this message translates to:
  /// **'카드 혜택'**
  String get cardBenefitsTitle;

  /// No description provided for @cardSelectTitle.
  ///
  /// In ko, this message translates to:
  /// **'카드 선택'**
  String get cardSelectTitle;

  /// No description provided for @cardSearchHintFull.
  ///
  /// In ko, this message translates to:
  /// **'카드 이름, 카드사로 검색'**
  String get cardSearchHintFull;

  /// No description provided for @cardSearchHintNameCompany.
  ///
  /// In ko, this message translates to:
  /// **'카드명 / 회사 검색'**
  String get cardSearchHintNameCompany;

  /// No description provided for @cardDetailLoadError.
  ///
  /// In ko, this message translates to:
  /// **'카드 정보를 불러오지 못했어요'**
  String get cardDetailLoadError;

  /// No description provided for @cardSearchError.
  ///
  /// In ko, this message translates to:
  /// **'카드 검색 실패'**
  String get cardSearchError;

  /// No description provided for @cardAddFailed.
  ///
  /// In ko, this message translates to:
  /// **'추가 실패'**
  String get cardAddFailed;

  /// No description provided for @cardDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'삭제 실패'**
  String get cardDeleteFailed;

  /// No description provided for @cardLastMonthPerf.
  ///
  /// In ko, this message translates to:
  /// **'전월 실적'**
  String get cardLastMonthPerf;

  /// No description provided for @cardKeyBenefitTags.
  ///
  /// In ko, this message translates to:
  /// **'주요 혜택 태그'**
  String get cardKeyBenefitTags;

  /// No description provided for @cardBenefitDetailCount.
  ///
  /// In ko, this message translates to:
  /// **'혜택 {count}개'**
  String cardBenefitDetailCount(int count);

  /// No description provided for @cardExpandAll.
  ///
  /// In ko, this message translates to:
  /// **'모두 펼치기'**
  String get cardExpandAll;

  /// No description provided for @cardCollapseAll.
  ///
  /// In ko, this message translates to:
  /// **'모두 접기'**
  String get cardCollapseAll;

  /// No description provided for @cardCautions.
  ///
  /// In ko, this message translates to:
  /// **'유의사항'**
  String get cardCautions;

  /// No description provided for @cardNone.
  ///
  /// In ko, this message translates to:
  /// **'없음'**
  String get cardNone;

  /// No description provided for @cardFeeUnknown.
  ///
  /// In ko, this message translates to:
  /// **'정보 없음'**
  String get cardFeeUnknown;

  /// No description provided for @cardFeeFree.
  ///
  /// In ko, this message translates to:
  /// **'무료'**
  String get cardFeeFree;

  /// No description provided for @cardPerfNone.
  ///
  /// In ko, this message translates to:
  /// **'실적 없음'**
  String get cardPerfNone;

  /// No description provided for @cardFeeDomesticOnly.
  ///
  /// In ko, this message translates to:
  /// **'국내전용 {amount}'**
  String cardFeeDomesticOnly(String amount);

  /// No description provided for @cardPerfMin.
  ///
  /// In ko, this message translates to:
  /// **'{amount} 이상'**
  String cardPerfMin(String amount);

  /// No description provided for @cardPerfMonthly.
  ///
  /// In ko, this message translates to:
  /// **'실적 {amount}'**
  String cardPerfMonthly(String amount);

  /// No description provided for @cardPerfMonthTitle.
  ///
  /// In ko, this message translates to:
  /// **'{month} 실적'**
  String cardPerfMonthTitle(String month);

  /// No description provided for @cardPerfAchieved.
  ///
  /// In ko, this message translates to:
  /// **'달성'**
  String get cardPerfAchieved;

  /// No description provided for @cardPerfRemaining.
  ///
  /// In ko, this message translates to:
  /// **'남은 {amount}'**
  String cardPerfRemaining(String amount);

  /// No description provided for @cardIncludeDiscontinued.
  ///
  /// In ko, this message translates to:
  /// **'단종 카드 포함'**
  String get cardIncludeDiscontinued;

  /// No description provided for @cardTotalCount.
  ///
  /// In ko, this message translates to:
  /// **'총 {count}장'**
  String cardTotalCount(String count);

  /// No description provided for @cardNoResults.
  ///
  /// In ko, this message translates to:
  /// **'찾는 카드가 없어요'**
  String get cardNoResults;

  /// No description provided for @cardNoResultsHint.
  ///
  /// In ko, this message translates to:
  /// **'다른 검색어나 조건으로 찾아보세요.'**
  String get cardNoResultsHint;

  /// No description provided for @cardRowFeeAmount.
  ///
  /// In ko, this message translates to:
  /// **'연회비 {amount}'**
  String cardRowFeeAmount(String amount);

  /// No description provided for @cardRowFeeLabel.
  ///
  /// In ko, this message translates to:
  /// **'연회비 {label}'**
  String cardRowFeeLabel(String label);

  /// No description provided for @cardRowFeeNone.
  ///
  /// In ko, this message translates to:
  /// **'연회비 없음'**
  String get cardRowFeeNone;

  /// No description provided for @cardRowFeeUnknown.
  ///
  /// In ko, this message translates to:
  /// **'연회비 정보 없음'**
  String get cardRowFeeUnknown;

  /// No description provided for @cardTypeChip.
  ///
  /// In ko, this message translates to:
  /// **'카드 종류'**
  String get cardTypeChip;

  /// No description provided for @cardBenefitChip.
  ///
  /// In ko, this message translates to:
  /// **'혜택'**
  String get cardBenefitChip;

  /// No description provided for @cardFilterBar.
  ///
  /// In ko, this message translates to:
  /// **'카드 거르기'**
  String get cardFilterBar;

  /// No description provided for @cardFilterClear.
  ///
  /// In ko, this message translates to:
  /// **'조건 모두 지우기'**
  String get cardFilterClear;

  /// No description provided for @cardFailDesc.
  ///
  /// In ko, this message translates to:
  /// **'잠시 뒤 다시 시도해주세요.'**
  String get cardFailDesc;

  /// No description provided for @cardBrands.
  ///
  /// In ko, this message translates to:
  /// **'브랜드'**
  String get cardBrands;

  /// No description provided for @cardNoBenefits.
  ///
  /// In ko, this message translates to:
  /// **'등록된 혜택이 없어요.'**
  String get cardNoBenefits;

  /// No description provided for @cardPickerNoMatch.
  ///
  /// In ko, this message translates to:
  /// **'일치하는 카드가 없습니다'**
  String get cardPickerNoMatch;

  /// No description provided for @categoryManageTitle.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 관리'**
  String get categoryManageTitle;

  /// No description provided for @categorySearchHint.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 검색'**
  String get categorySearchHint;

  /// No description provided for @categoryLoadError.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 로드 실패'**
  String get categoryLoadError;

  /// No description provided for @categoryNoResults.
  ///
  /// In ko, this message translates to:
  /// **'찾는 카테고리가 없어요.'**
  String get categoryNoResults;

  /// No description provided for @categoryEmpty.
  ///
  /// In ko, this message translates to:
  /// **'카테고리가 없어요.'**
  String get categoryEmpty;

  /// No description provided for @categoryAdd.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 추가'**
  String get categoryAdd;

  /// No description provided for @categoryAddAction.
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get categoryAddAction;

  /// No description provided for @recurringAddAction.
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get recurringAddAction;

  /// No description provided for @presetAddAction.
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get presetAddAction;

  /// No description provided for @categoryListTitleExpense.
  ///
  /// In ko, this message translates to:
  /// **'지출 카테고리 {count}개'**
  String categoryListTitleExpense(int count);

  /// No description provided for @categoryListTitleIncome.
  ///
  /// In ko, this message translates to:
  /// **'수입 카테고리 {count}개'**
  String categoryListTitleIncome(int count);

  /// No description provided for @categoryEdit.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 수정'**
  String get categoryEdit;

  /// No description provided for @categoryNameRequired.
  ///
  /// In ko, this message translates to:
  /// **'이름을 입력해주세요.'**
  String get categoryNameRequired;

  /// No description provided for @categoryNameTooLong.
  ///
  /// In ko, this message translates to:
  /// **'이름은 12자 이내로 입력해주세요.'**
  String get categoryNameTooLong;

  /// No description provided for @categoryNameDuplicate.
  ///
  /// In ko, this message translates to:
  /// **'같은 자리에 같은 이름의 카테고리가 있어요.'**
  String get categoryNameDuplicate;

  /// No description provided for @categoryParent.
  ///
  /// In ko, this message translates to:
  /// **'상위 카테고리'**
  String get categoryParent;

  /// No description provided for @categoryBudgetExceedTitle.
  ///
  /// In ko, this message translates to:
  /// **'예산 초과 확인'**
  String get categoryBudgetExceedTitle;

  /// No description provided for @categoryBudgetExceedMessage.
  ///
  /// In ko, this message translates to:
  /// **'옮기면 \"{parent}\" 예산을 {amount} 넘어요. 그래도 옮길까요?'**
  String categoryBudgetExceedMessage(String parent, String amount);

  /// No description provided for @categoryMove.
  ///
  /// In ko, this message translates to:
  /// **'옮기기'**
  String get categoryMove;

  /// No description provided for @categoryUpdated.
  ///
  /// In ko, this message translates to:
  /// **'카테고리가 수정되었습니다'**
  String get categoryUpdated;

  /// No description provided for @categoryAdded.
  ///
  /// In ko, this message translates to:
  /// **'카테고리가 추가되었습니다'**
  String get categoryAdded;

  /// No description provided for @categoryActionFailed.
  ///
  /// In ko, this message translates to:
  /// **'실패'**
  String get categoryActionFailed;

  /// No description provided for @categoryDeleteBlockedTitle.
  ///
  /// In ko, this message translates to:
  /// **'삭제할 수 없어요'**
  String get categoryDeleteBlockedTitle;

  /// No description provided for @categoryDeleteHasChildren.
  ///
  /// In ko, this message translates to:
  /// **'\"{name}\" 카테고리에 하위 카테고리가 있어 삭제할 수 없어요. 먼저 하위 카테고리를 정리해주세요.'**
  String categoryDeleteHasChildren(String name);

  /// No description provided for @categoryDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'\"{name}\" 카테고리를 삭제할까요?'**
  String categoryDeleteConfirm(String name);

  /// No description provided for @categoryDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'카테고리를 삭제하지 못했어요.'**
  String get categoryDeleteFailed;

  /// No description provided for @categorySaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'카테고리를 저장하지 못했어요.'**
  String get categorySaveFailed;

  /// No description provided for @categoryMoveTxFailed.
  ///
  /// In ko, this message translates to:
  /// **'거래를 옮기지 못했어요.'**
  String get categoryMoveTxFailed;

  /// No description provided for @categoryReorderFailed.
  ///
  /// In ko, this message translates to:
  /// **'순서를 바꾸지 못했어요.'**
  String get categoryReorderFailed;

  /// No description provided for @todoSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'할 일을 저장하지 못했어요.'**
  String get todoSaveFailed;

  /// No description provided for @categoryParentMoveHint.
  ///
  /// In ko, this message translates to:
  /// **'최상위로 올리려면 새 최상위를 만들어 거래를 옮겨주세요.'**
  String get categoryParentMoveHint;

  /// No description provided for @categoryMakeRoot.
  ///
  /// In ko, this message translates to:
  /// **'최상위'**
  String get categoryMakeRoot;

  /// No description provided for @categoryNamePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'예: 반려동물, 부수입'**
  String get categoryNamePlaceholder;

  /// No description provided for @categoryIconLabel.
  ///
  /// In ko, this message translates to:
  /// **'아이콘'**
  String get categoryIconLabel;

  /// No description provided for @categoryLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'카테고리를 불러오지 못했어요'**
  String get categoryLoadFailed;

  /// No description provided for @categoryDeleteMessage.
  ///
  /// In ko, this message translates to:
  /// **'이미 기록된 거래는 삭제되지 않고 그대로 남아요. 이 카테고리에 걸린 예산은 함께 삭제돼요.'**
  String get categoryDeleteMessage;

  /// No description provided for @categoryDeleteRecurring.
  ///
  /// In ko, this message translates to:
  /// **'이 카테고리를 쓰는 반복 거래 {count}개는 계속 이 카테고리로 기록돼요.'**
  String categoryDeleteRecurring(int count);

  /// No description provided for @categoryExpandOf.
  ///
  /// In ko, this message translates to:
  /// **'{name} 하위 카테고리'**
  String categoryExpandOf(String name);

  /// No description provided for @categoryMoreOf.
  ///
  /// In ko, this message translates to:
  /// **'{name} 더보기'**
  String categoryMoreOf(String name);

  /// No description provided for @categoryDragReorderOf.
  ///
  /// In ko, this message translates to:
  /// **'{name} 순서 바꾸기'**
  String categoryDragReorderOf(String name);

  /// No description provided for @categoryKindLabel.
  ///
  /// In ko, this message translates to:
  /// **'종류'**
  String get categoryKindLabel;

  /// No description provided for @categorySubmitAdd.
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get categorySubmitAdd;

  /// No description provided for @categoryAddSub.
  ///
  /// In ko, this message translates to:
  /// **'하위 카테고리 추가'**
  String get categoryAddSub;

  /// No description provided for @authLoginPrompt.
  ///
  /// In ko, this message translates to:
  /// **'그루 계정으로 로그인해주세요.'**
  String get authLoginPrompt;

  /// No description provided for @authSsoLogin.
  ///
  /// In ko, this message translates to:
  /// **'그루 계정으로 로그인'**
  String get authSsoLogin;

  /// No description provided for @authLoginTitle.
  ///
  /// In ko, this message translates to:
  /// **'로그인'**
  String get authLoginTitle;

  /// No description provided for @authLoginFailed.
  ///
  /// In ko, this message translates to:
  /// **'로그인하지 못했어요.'**
  String get authLoginFailed;

  /// No description provided for @authLoginExpired.
  ///
  /// In ko, this message translates to:
  /// **'로그인 시간이 지났어요. 다시 로그인해주세요.'**
  String get authLoginExpired;

  /// No description provided for @authLoginError.
  ///
  /// In ko, this message translates to:
  /// **'로그인을 처리하지 못했어요.'**
  String get authLoginError;

  /// No description provided for @authSecurityNotHttps.
  ///
  /// In ko, this message translates to:
  /// **'로그인 서버와 안전하게 연결되지 않았어요.'**
  String get authSecurityNotHttps;

  /// No description provided for @authStateMismatch.
  ///
  /// In ko, this message translates to:
  /// **'보안 검증에 실패했어요 (state 불일치). 다시 시도해주세요.'**
  String get authStateMismatch;

  /// No description provided for @authNoAuthCode.
  ///
  /// In ko, this message translates to:
  /// **'인가코드를 받지 못했어요. 다시 시도해주세요.'**
  String get authNoAuthCode;

  /// No description provided for @authPageLoadError.
  ///
  /// In ko, this message translates to:
  /// **'로그인 페이지를 불러오지 못했어요.'**
  String get authPageLoadError;

  /// No description provided for @dutchSendRequest.
  ///
  /// In ko, this message translates to:
  /// **'요청'**
  String get dutchSendRequest;

  /// No description provided for @dutchSendRequestOf.
  ///
  /// In ko, this message translates to:
  /// **'{name}님에게 송금 요청'**
  String dutchSendRequestOf(String name);

  /// No description provided for @dutchRequestSoon.
  ///
  /// In ko, this message translates to:
  /// **'송금 요청은 곧 열려요.'**
  String get dutchRequestSoon;

  /// No description provided for @dutchStepLabel.
  ///
  /// In ko, this message translates to:
  /// **'{step} / {total}단계'**
  String dutchStepLabel(int step, int total);

  /// No description provided for @dutchInfoTitle.
  ///
  /// In ko, this message translates to:
  /// **'정산 정보'**
  String get dutchInfoTitle;

  /// No description provided for @dutchTitleRequired.
  ///
  /// In ko, this message translates to:
  /// **'정산 이름을 입력해주세요.'**
  String get dutchTitleRequired;

  /// No description provided for @dutchAmountRequired.
  ///
  /// In ko, this message translates to:
  /// **'총 금액을 입력해주세요.'**
  String get dutchAmountRequired;

  /// No description provided for @dutchNeedOne.
  ///
  /// In ko, this message translates to:
  /// **'함께 정산할 사람을 한 명 이상 더해주세요.'**
  String get dutchNeedOne;

  /// No description provided for @dutchPaidProgress.
  ///
  /// In ko, this message translates to:
  /// **'{paid}/{total}명 냈어요'**
  String dutchPaidProgress(int paid, int total);

  /// No description provided for @dutchAllPaid.
  ///
  /// In ko, this message translates to:
  /// **'모두 냈어요'**
  String get dutchAllPaid;

  /// No description provided for @dutchPerPersonOf.
  ///
  /// In ko, this message translates to:
  /// **'1인당 {amount}'**
  String dutchPerPersonOf(String amount);

  /// No description provided for @dutchPerPersonRestOf.
  ///
  /// In ko, this message translates to:
  /// **'1인당 {amount} · {rest}은 {name}'**
  String dutchPerPersonRestOf(String amount, String rest, String name);

  /// No description provided for @dutchSummaryLine.
  ///
  /// In ko, this message translates to:
  /// **'{count}명 · 1인당 {amount}'**
  String dutchSummaryLine(int count, String amount);

  /// No description provided for @dutchPayerPaid.
  ///
  /// In ko, this message translates to:
  /// **'결제했어요'**
  String get dutchPayerPaid;

  /// No description provided for @dutchPayerPaidShare.
  ///
  /// In ko, this message translates to:
  /// **'결제했어요 · 몫 {amount}'**
  String dutchPayerPaidShare(String amount);

  /// No description provided for @dutchShareDone.
  ///
  /// In ko, this message translates to:
  /// **'{amount} 냈어요'**
  String dutchShareDone(String amount);

  /// No description provided for @dutchShareDue.
  ///
  /// In ko, this message translates to:
  /// **'{amount} 보낼 차례'**
  String dutchShareDue(String amount);

  /// No description provided for @dutchBadgePaid.
  ///
  /// In ko, this message translates to:
  /// **'냈어요'**
  String get dutchBadgePaid;

  /// No description provided for @dutchMarkReceived.
  ///
  /// In ko, this message translates to:
  /// **'받음'**
  String get dutchMarkReceived;

  /// No description provided for @dutchMarkReceivedOf.
  ///
  /// In ko, this message translates to:
  /// **'{name} 받음 처리'**
  String dutchMarkReceivedOf(String name);

  /// No description provided for @dutchSettleAll.
  ///
  /// In ko, this message translates to:
  /// **'모두 받음'**
  String get dutchSettleAll;

  /// No description provided for @dutchParticipantsHeader.
  ///
  /// In ko, this message translates to:
  /// **'참여자 · {count}'**
  String dutchParticipantsHeader(int count);

  /// No description provided for @dutchSuggestHeader.
  ///
  /// In ko, this message translates to:
  /// **'함께 정산했던 사람'**
  String get dutchSuggestHeader;

  /// No description provided for @dutchSuggestChip.
  ///
  /// In ko, this message translates to:
  /// **'+ {name}'**
  String dutchSuggestChip(String name);

  /// No description provided for @dutchPayerSelect.
  ///
  /// In ko, this message translates to:
  /// **'결제한 사람'**
  String get dutchPayerSelect;

  /// No description provided for @dutchLoadFailedTitle.
  ///
  /// In ko, this message translates to:
  /// **'더치페이를 불러오지 못했어요'**
  String get dutchLoadFailedTitle;

  /// No description provided for @dutchLoadFailedDesc.
  ///
  /// In ko, this message translates to:
  /// **'잠시 뒤 다시 시도해주세요.'**
  String get dutchLoadFailedDesc;

  /// No description provided for @dutchNoReceivable.
  ///
  /// In ko, this message translates to:
  /// **'받을 돈 없음'**
  String get dutchNoReceivable;

  /// No description provided for @dutchMarkFailed.
  ///
  /// In ko, this message translates to:
  /// **'받음 처리를 하지 못했어요.'**
  String get dutchMarkFailed;

  /// No description provided for @dutchTitle.
  ///
  /// In ko, this message translates to:
  /// **'더치페이'**
  String get dutchTitle;

  /// No description provided for @dutchCreate.
  ///
  /// In ko, this message translates to:
  /// **'정산 만들기'**
  String get dutchCreate;

  /// No description provided for @dutchTabActive.
  ///
  /// In ko, this message translates to:
  /// **'진행 중'**
  String get dutchTabActive;

  /// No description provided for @dutchTabPast.
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get dutchTabPast;

  /// No description provided for @dutchTabFriends.
  ///
  /// In ko, this message translates to:
  /// **'친구'**
  String get dutchTabFriends;

  /// No description provided for @dutchEmptyActiveTitle.
  ///
  /// In ko, this message translates to:
  /// **'진행 중인 정산이 없어요'**
  String get dutchEmptyActiveTitle;

  /// No description provided for @dutchEmptyActiveSub.
  ///
  /// In ko, this message translates to:
  /// **'오른쪽 아래 + 버튼으로 새 정산을 만들어보세요.'**
  String get dutchEmptyActiveSub;

  /// No description provided for @dutchEmptyPastTitle.
  ///
  /// In ko, this message translates to:
  /// **'완료된 정산이 없어요'**
  String get dutchEmptyPastTitle;

  /// No description provided for @dutchEmptyPastSub.
  ///
  /// In ko, this message translates to:
  /// **'정산을 마치면 여기에 모여요.'**
  String get dutchEmptyPastSub;

  /// No description provided for @dutchEmptyFriendsTitle.
  ///
  /// In ko, this message translates to:
  /// **'함께 정산한 친구가 없어요'**
  String get dutchEmptyFriendsTitle;

  /// No description provided for @dutchEmptyFriendsSub.
  ///
  /// In ko, this message translates to:
  /// **'정산에 친구를 더하면 여기에 모여요.'**
  String get dutchEmptyFriendsSub;

  /// No description provided for @dutchActionFailed.
  ///
  /// In ko, this message translates to:
  /// **'실패'**
  String get dutchActionFailed;

  /// No description provided for @dutchSettleFailed.
  ///
  /// In ko, this message translates to:
  /// **'모두 받음 처리를 하지 못했어요.'**
  String get dutchSettleFailed;

  /// No description provided for @dutchDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'정산을 삭제하지 못했어요.'**
  String get dutchDeleteFailed;

  /// No description provided for @dutchToReceive.
  ///
  /// In ko, this message translates to:
  /// **'받을 돈'**
  String get dutchToReceive;

  /// No description provided for @dutchToSend.
  ///
  /// In ko, this message translates to:
  /// **'보낼 돈'**
  String get dutchToSend;

  /// No description provided for @dutchFromPeople.
  ///
  /// In ko, this message translates to:
  /// **'{count}명에게서'**
  String dutchFromPeople(int count);

  /// No description provided for @dutchToPeople.
  ///
  /// In ko, this message translates to:
  /// **'{count}명에게'**
  String dutchToPeople(int count);

  /// No description provided for @dutchPerPersonLabel.
  ///
  /// In ko, this message translates to:
  /// **'1인당'**
  String get dutchPerPersonLabel;

  /// No description provided for @dutchNPeople.
  ///
  /// In ko, this message translates to:
  /// **'{count}명'**
  String dutchNPeople(int count);

  /// No description provided for @dutchSettledTogetherCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}회 함께 정산'**
  String dutchSettledTogetherCount(int count);

  /// No description provided for @dutchSettled.
  ///
  /// In ko, this message translates to:
  /// **'정산 완료'**
  String get dutchSettled;

  /// No description provided for @dutchMe.
  ///
  /// In ko, this message translates to:
  /// **'나'**
  String get dutchMe;

  /// No description provided for @dutchPayer.
  ///
  /// In ko, this message translates to:
  /// **'결제자'**
  String get dutchPayer;

  /// No description provided for @dutchNameLabel.
  ///
  /// In ko, this message translates to:
  /// **'정산 이름'**
  String get dutchNameLabel;

  /// No description provided for @dutchNamePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'예: 팀 저녁 회식'**
  String get dutchNamePlaceholder;

  /// No description provided for @dutchPlaceLabel.
  ///
  /// In ko, this message translates to:
  /// **'장소'**
  String get dutchPlaceLabel;

  /// No description provided for @dutchPlacePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'장소 또는 상호명'**
  String get dutchPlacePlaceholder;

  /// No description provided for @dutchTotalLabel.
  ///
  /// In ko, this message translates to:
  /// **'총 금액'**
  String get dutchTotalLabel;

  /// No description provided for @dutchDateLabel.
  ///
  /// In ko, this message translates to:
  /// **'날짜'**
  String get dutchDateLabel;

  /// No description provided for @dutchAddNamePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'이름 입력 후 추가'**
  String get dutchAddNamePlaceholder;

  /// No description provided for @dutchNameAlreadyAdded.
  ///
  /// In ko, this message translates to:
  /// **'이미 넣은 이름이에요.'**
  String get dutchNameAlreadyAdded;

  /// No description provided for @dutchAdd.
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get dutchAdd;

  /// No description provided for @dutchNext.
  ///
  /// In ko, this message translates to:
  /// **'다음'**
  String get dutchNext;

  /// No description provided for @dutchPrev.
  ///
  /// In ko, this message translates to:
  /// **'이전'**
  String get dutchPrev;

  /// No description provided for @dutchParticipant.
  ///
  /// In ko, this message translates to:
  /// **'참여자'**
  String get dutchParticipant;

  /// No description provided for @dutchDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'더치페이 삭제'**
  String get dutchDeleteTitle;

  /// No description provided for @dutchDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'\"{title}\" 더치페이를 삭제할까요? 삭제한 더치페이는 되돌릴 수 없어요.'**
  String dutchDeleteConfirm(String title);

  /// No description provided for @dutchRequestAll.
  ///
  /// In ko, this message translates to:
  /// **'일괄 요청'**
  String get dutchRequestAll;

  /// No description provided for @dutchNoName.
  ///
  /// In ko, this message translates to:
  /// **'(이름 없음)'**
  String get dutchNoName;

  /// No description provided for @dutchStartTitle.
  ///
  /// In ko, this message translates to:
  /// **'더치페이 시작'**
  String get dutchStartTitle;

  /// No description provided for @dutchFromTxDesc.
  ///
  /// In ko, this message translates to:
  /// **'이 거래를 기준으로 더치페이 정산을 만듭니다. 참여자에게 송금 요청을 보내고, 정산 진행 상황을 추적할 수 있어요.'**
  String get dutchFromTxDesc;

  /// No description provided for @dutchSplitMethod.
  ///
  /// In ko, this message translates to:
  /// **'분배 방식'**
  String get dutchSplitMethod;

  /// No description provided for @dutchSplitEqualTitle.
  ///
  /// In ko, this message translates to:
  /// **'N분의 1'**
  String get dutchSplitEqualTitle;

  /// No description provided for @dutchSplitEqualSub.
  ///
  /// In ko, this message translates to:
  /// **'균등 분배'**
  String get dutchSplitEqualSub;

  /// No description provided for @dutchSplitRatioTitle.
  ///
  /// In ko, this message translates to:
  /// **'비율'**
  String get dutchSplitRatioTitle;

  /// No description provided for @dutchSplitRatioSub.
  ///
  /// In ko, this message translates to:
  /// **'인원수·기준'**
  String get dutchSplitRatioSub;

  /// No description provided for @dutchSplitCustomTitle.
  ///
  /// In ko, this message translates to:
  /// **'개별 금액'**
  String get dutchSplitCustomTitle;

  /// No description provided for @dutchSplitCustomSub.
  ///
  /// In ko, this message translates to:
  /// **'각자 다르게'**
  String get dutchSplitCustomSub;

  /// No description provided for @dutchIncludeMyself.
  ///
  /// In ko, this message translates to:
  /// **'나도 포함해서 분배'**
  String get dutchIncludeMyself;

  /// No description provided for @dutchIncludeMyselfDesc.
  ///
  /// In ko, this message translates to:
  /// **'내 몫도 계산됩니다'**
  String get dutchIncludeMyselfDesc;

  /// No description provided for @dutchIncludeMyselfOffDesc.
  ///
  /// In ko, this message translates to:
  /// **'내가 전액 결제, 다른 사람 몫만 받아요'**
  String get dutchIncludeMyselfOffDesc;

  /// No description provided for @dutchSourceSub.
  ///
  /// In ko, this message translates to:
  /// **'참여자에게 송금 요청'**
  String get dutchSourceSub;

  /// No description provided for @dutchRequestMsgLabel.
  ///
  /// In ko, this message translates to:
  /// **'요청 메시지 (선택)'**
  String get dutchRequestMsgLabel;

  /// No description provided for @dutchRequestMsgPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'참여자에게 함께 보낼 한마디를 적어주세요'**
  String get dutchRequestMsgPlaceholder;

  /// No description provided for @dutchShortBy.
  ///
  /// In ko, this message translates to:
  /// **'합계가 총액보다 {amount}원 부족합니다.'**
  String dutchShortBy(String amount);

  /// No description provided for @dutchOverBy.
  ///
  /// In ko, this message translates to:
  /// **'합계가 총액보다 {amount}원 초과합니다.'**
  String dutchOverBy(String amount);

  /// No description provided for @dutchCreated.
  ///
  /// In ko, this message translates to:
  /// **'정산이 만들어졌어요'**
  String get dutchCreated;

  /// No description provided for @expLoadError.
  ///
  /// In ko, this message translates to:
  /// **'거래를 불러오지 못했어요'**
  String get expLoadError;

  /// No description provided for @expTransfersLoadError.
  ///
  /// In ko, this message translates to:
  /// **'이체 내역을 불러오지 못했어요.'**
  String get expTransfersLoadError;

  /// No description provided for @expEmptyMonth.
  ///
  /// In ko, this message translates to:
  /// **'이 달에는 거래가 없습니다'**
  String get expEmptyMonth;

  /// No description provided for @expEmptyDay.
  ///
  /// In ko, this message translates to:
  /// **'이 날의 거래가 없어요'**
  String get expEmptyDay;

  /// No description provided for @expTotal.
  ///
  /// In ko, this message translates to:
  /// **'합계'**
  String get expTotal;

  /// No description provided for @expFiltering.
  ///
  /// In ko, this message translates to:
  /// **'필터 중'**
  String get expFiltering;

  /// No description provided for @expFilteringBy.
  ///
  /// In ko, this message translates to:
  /// **'{name} 필터 중'**
  String expFilteringBy(String name);

  /// No description provided for @expViewList.
  ///
  /// In ko, this message translates to:
  /// **'목록'**
  String get expViewList;

  /// No description provided for @expViewCalendar.
  ///
  /// In ko, this message translates to:
  /// **'달력'**
  String get expViewCalendar;

  /// No description provided for @expTxCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}건'**
  String expTxCount(int count);

  /// No description provided for @expAddShort.
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get expAddShort;

  /// No description provided for @expTransferDone.
  ///
  /// In ko, this message translates to:
  /// **'이체가 완료되었습니다'**
  String get expTransferDone;

  /// No description provided for @expActionFailed.
  ///
  /// In ko, this message translates to:
  /// **'실패'**
  String get expActionFailed;

  /// No description provided for @expUpdated.
  ///
  /// In ko, this message translates to:
  /// **'거래가 수정되었습니다'**
  String get expUpdated;

  /// No description provided for @expAdded.
  ///
  /// In ko, this message translates to:
  /// **'거래가 추가되었습니다'**
  String get expAdded;

  /// No description provided for @expDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'\"{name}\" 거래를 삭제할까요? 연결된 자산 잔액이 함께 바뀌어요. 삭제한 거래는 되돌릴 수 없어요.'**
  String expDeleteConfirm(String name);

  /// No description provided for @expDeleted.
  ///
  /// In ko, this message translates to:
  /// **'거래가 삭제되었습니다'**
  String get expDeleted;

  /// No description provided for @expSplitMismatch.
  ///
  /// In ko, this message translates to:
  /// **'분할 내역과 금액이 달라요'**
  String get expSplitMismatch;

  /// No description provided for @expSplitDiff.
  ///
  /// In ko, this message translates to:
  /// **'새 총액 {total}원 · 분할 합계 {sum}원 · {diff}원 차이'**
  String expSplitDiff(String total, String sum, String diff);

  /// No description provided for @expSplitReconcile.
  ///
  /// In ko, this message translates to:
  /// **'분할 내역 맞추기'**
  String get expSplitReconcile;

  /// No description provided for @expPresetLoad.
  ///
  /// In ko, this message translates to:
  /// **'프리셋 불러오기'**
  String get expPresetLoad;

  /// No description provided for @expPresetApplied.
  ///
  /// In ko, this message translates to:
  /// **'적용됨'**
  String get expPresetApplied;

  /// No description provided for @expPresetSaveCurrent.
  ///
  /// In ko, this message translates to:
  /// **'현재 입력값 저장'**
  String get expPresetSaveCurrent;

  /// No description provided for @expPresetEmpty.
  ///
  /// In ko, this message translates to:
  /// **'저장된 프리셋이 없어요. 자주 쓰는 내역을 입력 후 “현재 입력값 저장”을 눌러보세요.'**
  String get expPresetEmpty;

  /// No description provided for @expPresetFilled.
  ///
  /// In ko, this message translates to:
  /// **'프리셋 값이 채워졌어요. 금액·내역만 수정해서 저장하세요.'**
  String get expPresetFilled;

  /// No description provided for @expClear.
  ///
  /// In ko, this message translates to:
  /// **'해제'**
  String get expClear;

  /// No description provided for @expSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'저장 실패'**
  String get expSaveFailed;

  /// No description provided for @expPresetSaveTitle.
  ///
  /// In ko, this message translates to:
  /// **'프리셋으로 저장'**
  String get expPresetSaveTitle;

  /// No description provided for @expPresetNamePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'예: 점심 도시락'**
  String get expPresetNamePlaceholder;

  /// No description provided for @presetNameDuplicate.
  ///
  /// In ko, this message translates to:
  /// **'같은 이름의 프리셋이 이미 있어요.'**
  String get presetNameDuplicate;

  /// No description provided for @expPresetLockAmount.
  ///
  /// In ko, this message translates to:
  /// **'금액 잠금 — 적용 시 {amount}원 자동 채움'**
  String expPresetLockAmount(String amount);

  /// No description provided for @expPayCash.
  ///
  /// In ko, this message translates to:
  /// **'현금'**
  String get expPayCash;

  /// No description provided for @expPayCard.
  ///
  /// In ko, this message translates to:
  /// **'카드'**
  String get expPayCard;

  /// No description provided for @expPayTransfer.
  ///
  /// In ko, this message translates to:
  /// **'계좌이체'**
  String get expPayTransfer;

  /// No description provided for @expPayOther.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get expPayOther;

  /// No description provided for @expAutoLock.
  ///
  /// In ko, this message translates to:
  /// **'자동 생성'**
  String get expAutoLock;

  /// No description provided for @expAutoSourceTradeRealized.
  ///
  /// In ko, this message translates to:
  /// **'주식을 팔아 생긴 실현손익이에요. 금액은 매매 내역에서 계산돼요.'**
  String get expAutoSourceTradeRealized;

  /// No description provided for @expAutoSourceTransferInterest.
  ///
  /// In ko, this message translates to:
  /// **'이체에 붙은 이자예요. 금액은 이체 내역에서 계산돼요.'**
  String get expAutoSourceTransferInterest;

  /// No description provided for @expAutoSourceCardCarryover.
  ///
  /// In ko, this message translates to:
  /// **'카드를 등록할 때 적은 이전 미결제 사용액이에요. 금액은 카드 수정에서 바꿔요.'**
  String get expAutoSourceCardCarryover;

  /// No description provided for @expAutoSourceDefault.
  ///
  /// In ko, this message translates to:
  /// **'자동으로 만들어진 거래예요. 원래 거래를 지우면 함께 사라져요.'**
  String get expAutoSourceDefault;

  /// No description provided for @expPresetLock.
  ///
  /// In ko, this message translates to:
  /// **'프리셋 잠금'**
  String get expPresetLock;

  /// No description provided for @expNoCategoryForType.
  ///
  /// In ko, this message translates to:
  /// **'이 타입에 해당하는 카테고리가 없습니다'**
  String get expNoCategoryForType;

  /// No description provided for @expSubcategory.
  ///
  /// In ko, this message translates to:
  /// **'세부 카테고리'**
  String get expSubcategory;

  /// No description provided for @expTopCategorySuffix.
  ///
  /// In ko, this message translates to:
  /// **'{name} (상위)'**
  String expTopCategorySuffix(String name);

  /// No description provided for @expIncomeSource.
  ///
  /// In ko, this message translates to:
  /// **'수입처'**
  String get expIncomeSource;

  /// No description provided for @expPayee.
  ///
  /// In ko, this message translates to:
  /// **'거래처'**
  String get expPayee;

  /// No description provided for @expIncomeSourcePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'예: 월급'**
  String get expIncomeSourcePlaceholder;

  /// No description provided for @expPayeePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'예: 회사 앞 도시락'**
  String get expPayeePlaceholder;

  /// No description provided for @expIncomeMethod.
  ///
  /// In ko, this message translates to:
  /// **'수입 방식'**
  String get expIncomeMethod;

  /// No description provided for @expNone.
  ///
  /// In ko, this message translates to:
  /// **'선택 안 함'**
  String get expNone;

  /// No description provided for @expDepositAccount.
  ///
  /// In ko, this message translates to:
  /// **'입금 계좌'**
  String get expDepositAccount;

  /// No description provided for @expAccountCard.
  ///
  /// In ko, this message translates to:
  /// **'계좌·카드'**
  String get expAccountCard;

  /// No description provided for @expAssetLoadError.
  ///
  /// In ko, this message translates to:
  /// **'자산 로드 실패'**
  String get expAssetLoadError;

  /// No description provided for @expWithdrawAccount.
  ///
  /// In ko, this message translates to:
  /// **'출금 계좌'**
  String get expWithdrawAccount;

  /// No description provided for @expSelect.
  ///
  /// In ko, this message translates to:
  /// **'선택'**
  String get expSelect;

  /// No description provided for @expTransferSameAsset.
  ///
  /// In ko, this message translates to:
  /// **'보낼/받을 자산은 달라야 합니다'**
  String get expTransferSameAsset;

  /// No description provided for @expFeeOptional.
  ///
  /// In ko, this message translates to:
  /// **'수수료 (선택)'**
  String get expFeeOptional;

  /// No description provided for @expInterest.
  ///
  /// In ko, this message translates to:
  /// **'이자'**
  String get expInterest;

  /// No description provided for @expInterestHint.
  ///
  /// In ko, this message translates to:
  /// **'상환액 중 이자 몫 — 부채는 이자를 뺀 만큼만 줄어들어요'**
  String get expInterestHint;

  /// No description provided for @expInterestSplit.
  ///
  /// In ko, this message translates to:
  /// **'원금 {principal}원 · 이자 {interest}원'**
  String expInterestSplit(String principal, String interest);

  /// No description provided for @expDateTime.
  ///
  /// In ko, this message translates to:
  /// **'날짜·시간'**
  String get expDateTime;

  /// No description provided for @expMemoPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'예: 점심, 회식 등'**
  String get expMemoPlaceholder;

  /// No description provided for @expIncomeDetail.
  ///
  /// In ko, this message translates to:
  /// **'수입 상세'**
  String get expIncomeDetail;

  /// No description provided for @expExpenseDetail.
  ///
  /// In ko, this message translates to:
  /// **'지출 상세'**
  String get expExpenseDetail;

  /// No description provided for @expTxFallback.
  ///
  /// In ko, this message translates to:
  /// **'거래'**
  String get expTxFallback;

  /// No description provided for @expUncategorized.
  ///
  /// In ko, this message translates to:
  /// **'미분류'**
  String get expUncategorized;

  /// No description provided for @expNotSelected.
  ///
  /// In ko, this message translates to:
  /// **'미선택'**
  String get expNotSelected;

  /// No description provided for @expThisMonth.
  ///
  /// In ko, this message translates to:
  /// **'이번 달'**
  String get expThisMonth;

  /// No description provided for @expTimesCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}회'**
  String expTimesCount(int count);

  /// No description provided for @expItem.
  ///
  /// In ko, this message translates to:
  /// **'항목'**
  String get expItem;

  /// No description provided for @expFilterApply.
  ///
  /// In ko, this message translates to:
  /// **'필터 적용'**
  String get expFilterApply;

  /// No description provided for @expNSelected.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 선택'**
  String expNSelected(int count);

  /// No description provided for @expPeriodCustom.
  ///
  /// In ko, this message translates to:
  /// **'직접 선택'**
  String get expPeriodCustom;

  /// No description provided for @expDateRangeError.
  ///
  /// In ko, this message translates to:
  /// **'시작일이 종료일보다 늦을 수 없어요.'**
  String get expDateRangeError;

  /// No description provided for @expTxType.
  ///
  /// In ko, this message translates to:
  /// **'거래 종류'**
  String get expTxType;

  /// No description provided for @expAmountRange.
  ///
  /// In ko, this message translates to:
  /// **'금액 범위'**
  String get expAmountRange;

  /// No description provided for @expMinAmount.
  ///
  /// In ko, this message translates to:
  /// **'최소 금액'**
  String get expMinAmount;

  /// No description provided for @expMaxAmount.
  ///
  /// In ko, this message translates to:
  /// **'최대 금액'**
  String get expMaxAmount;

  /// No description provided for @expSplitSave.
  ///
  /// In ko, this message translates to:
  /// **'분할 저장'**
  String get expSplitSave;

  /// No description provided for @expSplitRemove.
  ///
  /// In ko, this message translates to:
  /// **'분할 해제'**
  String get expSplitRemove;

  /// No description provided for @expSplitLoadError.
  ///
  /// In ko, this message translates to:
  /// **'분할 내역 로드 실패'**
  String get expSplitLoadError;

  /// No description provided for @expAddAmount.
  ///
  /// In ko, this message translates to:
  /// **'추가 금액'**
  String get expAddAmount;

  /// No description provided for @expSplitSaved.
  ///
  /// In ko, this message translates to:
  /// **'분할이 저장되었습니다'**
  String get expSplitSaved;

  /// No description provided for @expSplitRemoveConfirm.
  ///
  /// In ko, this message translates to:
  /// **'이 거래의 분할 내역을 모두 지워요. 지운 내역은 되돌릴 수 없어요.'**
  String get expSplitRemoveConfirm;

  /// No description provided for @expClearFailed.
  ///
  /// In ko, this message translates to:
  /// **'해제 실패'**
  String get expClearFailed;

  /// No description provided for @expSplitMatches.
  ///
  /// In ko, this message translates to:
  /// **'분할 합계가 총액과 일치해요'**
  String get expSplitMatches;

  /// No description provided for @expSplitSum.
  ///
  /// In ko, this message translates to:
  /// **'분할 합계'**
  String get expSplitSum;

  /// No description provided for @expTotalAmount.
  ///
  /// In ko, this message translates to:
  /// **'총액'**
  String get expTotalAmount;

  /// No description provided for @expSplitTotalChanged.
  ///
  /// In ko, this message translates to:
  /// **'총액이 바뀌어 분할을 맞춰야 해요'**
  String get expSplitTotalChanged;

  /// No description provided for @expSplitMismatchTotal.
  ///
  /// In ko, this message translates to:
  /// **'분할 합계가 총액과 달라요'**
  String get expSplitMismatchTotal;

  /// No description provided for @expSplitCheckItems.
  ///
  /// In ko, this message translates to:
  /// **'분할 항목을 확인해주세요'**
  String get expSplitCheckItems;

  /// No description provided for @expShort.
  ///
  /// In ko, this message translates to:
  /// **'부족'**
  String get expShort;

  /// No description provided for @expOver.
  ///
  /// In ko, this message translates to:
  /// **'초과'**
  String get expOver;

  /// No description provided for @expQuickAdjust.
  ///
  /// In ko, this message translates to:
  /// **'빠르게 맞추기'**
  String get expQuickAdjust;

  /// No description provided for @expProrate.
  ///
  /// In ko, this message translates to:
  /// **'비례 배분'**
  String get expProrate;

  /// No description provided for @expProrateDesc.
  ///
  /// In ko, this message translates to:
  /// **'비중대로 자동 조정'**
  String get expProrateDesc;

  /// No description provided for @expApplyToLargest.
  ///
  /// In ko, this message translates to:
  /// **'큰 항목 반영'**
  String get expApplyToLargest;

  /// No description provided for @expApplyToLargestDesc.
  ///
  /// In ko, this message translates to:
  /// **'가장 큰 항목에 차액'**
  String get expApplyToLargestDesc;

  /// No description provided for @expAdjustItem.
  ///
  /// In ko, this message translates to:
  /// **'조정 항목'**
  String get expAdjustItem;

  /// No description provided for @expAdjustItemDesc.
  ///
  /// In ko, this message translates to:
  /// **'부족분을 새 항목으로'**
  String get expAdjustItemDesc;

  /// No description provided for @expRecommended.
  ///
  /// In ko, this message translates to:
  /// **'추천'**
  String get expRecommended;

  /// No description provided for @expSplitDesc.
  ///
  /// In ko, this message translates to:
  /// **'하나의 결제를 카테고리·항목별로 나누어 기록합니다. 예: 마트에서 식품과 생활품을 함께 결제한 경우.'**
  String get expSplitDesc;

  /// No description provided for @expOriginalTx.
  ///
  /// In ko, this message translates to:
  /// **'원 거래'**
  String get expOriginalTx;

  /// No description provided for @expAddItem.
  ///
  /// In ko, this message translates to:
  /// **'항목 추가'**
  String get expAddItem;

  /// No description provided for @expSplitEven.
  ///
  /// In ko, this message translates to:
  /// **'균등 분배'**
  String get expSplitEven;

  /// No description provided for @expSplitRatio.
  ///
  /// In ko, this message translates to:
  /// **'분할 비율'**
  String get expSplitRatio;

  /// No description provided for @expDeleteItem.
  ///
  /// In ko, this message translates to:
  /// **'항목 삭제'**
  String get expDeleteItem;

  /// No description provided for @expItemNamePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'항목 이름 (선택)'**
  String get expItemNamePlaceholder;

  /// No description provided for @exportTitle.
  ///
  /// In ko, this message translates to:
  /// **'데이터 내보내기'**
  String get exportTitle;

  /// No description provided for @exportShareText.
  ///
  /// In ko, this message translates to:
  /// **'데이터 내보내기 ({start} ~ {end})'**
  String exportShareText(String start, String end);

  /// No description provided for @exportSuccess.
  ///
  /// In ko, this message translates to:
  /// **'내보냈어요.'**
  String get exportSuccess;

  /// No description provided for @exportTypeExpense.
  ///
  /// In ko, this message translates to:
  /// **'거래 내역'**
  String get exportTypeExpense;

  /// No description provided for @exportTypeAsset.
  ///
  /// In ko, this message translates to:
  /// **'자산 · 계좌'**
  String get exportTypeAsset;

  /// No description provided for @exportTypeBudget.
  ///
  /// In ko, this message translates to:
  /// **'예산 설정'**
  String get exportTypeBudget;

  /// No description provided for @exportTypeCategory.
  ///
  /// In ko, this message translates to:
  /// **'카테고리'**
  String get exportTypeCategory;

  /// No description provided for @exportTypeMemo.
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get exportTypeMemo;

  /// No description provided for @exportTypeCalendar.
  ///
  /// In ko, this message translates to:
  /// **'캘린더 일정'**
  String get exportTypeCalendar;

  /// No description provided for @exportTypeTodo.
  ///
  /// In ko, this message translates to:
  /// **'할 일'**
  String get exportTypeTodo;

  /// No description provided for @exportFormatCsvDesc.
  ///
  /// In ko, this message translates to:
  /// **'엑셀 · 구글 시트'**
  String get exportFormatCsvDesc;

  /// No description provided for @exportFormatExcelDesc.
  ///
  /// In ko, this message translates to:
  /// **'Microsoft Excel'**
  String get exportFormatExcelDesc;

  /// No description provided for @exportFormatJsonDesc.
  ///
  /// In ko, this message translates to:
  /// **'개발자 · 백업'**
  String get exportFormatJsonDesc;

  /// No description provided for @exportPeriodThisMonth.
  ///
  /// In ko, this message translates to:
  /// **'이번 달'**
  String get exportPeriodThisMonth;

  /// No description provided for @exportPeriodLastMonth.
  ///
  /// In ko, this message translates to:
  /// **'지난 달'**
  String get exportPeriodLastMonth;

  /// No description provided for @exportPeriodLast3Months.
  ///
  /// In ko, this message translates to:
  /// **'최근 3개월'**
  String get exportPeriodLast3Months;

  /// No description provided for @exportPeriodThisYear.
  ///
  /// In ko, this message translates to:
  /// **'올해'**
  String get exportPeriodThisYear;

  /// No description provided for @exportPeriodCustom.
  ///
  /// In ko, this message translates to:
  /// **'사용자 지정'**
  String get exportPeriodCustom;

  /// No description provided for @exportPeriodTitle.
  ///
  /// In ko, this message translates to:
  /// **'기간 선택'**
  String get exportPeriodTitle;

  /// No description provided for @exportDateRangeError.
  ///
  /// In ko, this message translates to:
  /// **'시작일이 종료일보다 늦을 수 없어요.'**
  String get exportDateRangeError;

  /// No description provided for @exportTypesTitle.
  ///
  /// In ko, this message translates to:
  /// **'데이터 종류 — {count}개 선택됨'**
  String exportTypesTitle(int count);

  /// No description provided for @exportTypesDesc.
  ///
  /// In ko, this message translates to:
  /// **'내보낼 데이터를 골라주세요. 여러 종류는 ZIP으로 묶어요.'**
  String get exportTypesDesc;

  /// No description provided for @exportCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}건'**
  String exportCount(int count);

  /// No description provided for @exportFormatTitle.
  ///
  /// In ko, this message translates to:
  /// **'파일 형식'**
  String get exportFormatTitle;

  /// No description provided for @exportMaskLabel.
  ///
  /// In ko, this message translates to:
  /// **'민감 정보 가리기 (잔액 · 금액 · 기관)'**
  String get exportMaskLabel;

  /// No description provided for @exportPreview.
  ///
  /// In ko, this message translates to:
  /// **'미리보기'**
  String get exportPreview;

  /// No description provided for @exportRun.
  ///
  /// In ko, this message translates to:
  /// **'내보내기'**
  String get exportRun;

  /// No description provided for @exportEmpty.
  ///
  /// In ko, this message translates to:
  /// **'이 기간에 내보낼 데이터가 없어요.'**
  String get exportEmpty;

  /// No description provided for @exportPreviewRows.
  ///
  /// In ko, this message translates to:
  /// **'상위 {count}행 미리보기'**
  String exportPreviewRows(int count);

  /// No description provided for @fileAttachTitle.
  ///
  /// In ko, this message translates to:
  /// **'첨부 파일'**
  String get fileAttachTitle;

  /// No description provided for @fileTooltipGallery.
  ///
  /// In ko, this message translates to:
  /// **'갤러리'**
  String get fileTooltipGallery;

  /// No description provided for @fileTooltipCamera.
  ///
  /// In ko, this message translates to:
  /// **'카메라'**
  String get fileTooltipCamera;

  /// No description provided for @fileTooltipFile.
  ///
  /// In ko, this message translates to:
  /// **'파일'**
  String get fileTooltipFile;

  /// No description provided for @fileUploadComplete.
  ///
  /// In ko, this message translates to:
  /// **'{name} 파일을 올렸어요.'**
  String fileUploadComplete(String name);

  /// No description provided for @fileUploadFailed.
  ///
  /// In ko, this message translates to:
  /// **'파일을 올리지 못했어요.'**
  String get fileUploadFailed;

  /// No description provided for @fileDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'파일 삭제'**
  String get fileDeleteTitle;

  /// No description provided for @fileDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'\"{name}\" 파일을 삭제할까요? 삭제한 파일은 되돌릴 수 없어요.'**
  String fileDeleteConfirm(String name);

  /// No description provided for @fileDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'파일을 삭제하지 못했어요.'**
  String get fileDeleteFailed;

  /// No description provided for @fileLoadError.
  ///
  /// In ko, this message translates to:
  /// **'첨부 로드 실패'**
  String get fileLoadError;

  /// No description provided for @fileEmpty.
  ///
  /// In ko, this message translates to:
  /// **'첨부된 파일 없음'**
  String get fileEmpty;

  /// No description provided for @moreGroupMoney.
  ///
  /// In ko, this message translates to:
  /// **'돈 관리'**
  String get moreGroupMoney;

  /// No description provided for @moreGroupDaily.
  ///
  /// In ko, this message translates to:
  /// **'일상'**
  String get moreGroupDaily;

  /// No description provided for @moreGroupPersonal.
  ///
  /// In ko, this message translates to:
  /// **'개인화'**
  String get moreGroupPersonal;

  /// No description provided for @moreGroupSystem.
  ///
  /// In ko, this message translates to:
  /// **'계정·시스템'**
  String get moreGroupSystem;

  /// No description provided for @moreItemStocks.
  ///
  /// In ko, this message translates to:
  /// **'증권'**
  String get moreItemStocks;

  /// No description provided for @moreItemStats.
  ///
  /// In ko, this message translates to:
  /// **'통계'**
  String get moreItemStats;

  /// No description provided for @moreItemRecurring.
  ///
  /// In ko, this message translates to:
  /// **'반복 거래'**
  String get moreItemRecurring;

  /// No description provided for @moreItemAccountCard.
  ///
  /// In ko, this message translates to:
  /// **'계좌 · 카드 관리'**
  String get moreItemAccountCard;

  /// No description provided for @moreItemCardBenefits.
  ///
  /// In ko, this message translates to:
  /// **'카드 혜택'**
  String get moreItemCardBenefits;

  /// No description provided for @moreItemDisplay.
  ///
  /// In ko, this message translates to:
  /// **'표시 설정'**
  String get moreItemDisplay;

  /// No description provided for @moreItemAccount.
  ///
  /// In ko, this message translates to:
  /// **'계정'**
  String get moreItemAccount;

  /// No description provided for @moreDescExpense.
  ///
  /// In ko, this message translates to:
  /// **'지출 · 수입 · 이체'**
  String get moreDescExpense;

  /// No description provided for @moreDescAsset.
  ///
  /// In ko, this message translates to:
  /// **'계좌 · 카드 · 투자 · 부채'**
  String get moreDescAsset;

  /// No description provided for @moreDescStocks.
  ///
  /// In ko, this message translates to:
  /// **'시세 · 보유 · 관심 · 호가'**
  String get moreDescStocks;

  /// No description provided for @moreDescBudget.
  ///
  /// In ko, this message translates to:
  /// **'월간 · 카테고리별'**
  String get moreDescBudget;

  /// No description provided for @moreDescSavingGoal.
  ///
  /// In ko, this message translates to:
  /// **'목표 · 진행률'**
  String get moreDescSavingGoal;

  /// No description provided for @moreDescStats.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 · 트렌드 · 비교'**
  String get moreDescStats;

  /// No description provided for @moreDescRecurring.
  ///
  /// In ko, this message translates to:
  /// **'구독 · 고정비'**
  String get moreDescRecurring;

  /// No description provided for @moreDescAccountCard.
  ///
  /// In ko, this message translates to:
  /// **'계좌·카드 추가·편집'**
  String get moreDescAccountCard;

  /// No description provided for @moreDescCalendar.
  ///
  /// In ko, this message translates to:
  /// **'일정 · 반복 · 알림'**
  String get moreDescCalendar;

  /// No description provided for @moreDescTodo.
  ///
  /// In ko, this message translates to:
  /// **'마감 · 우선순위 · 태그'**
  String get moreDescTodo;

  /// No description provided for @moreDescMemo.
  ///
  /// In ko, this message translates to:
  /// **'분류 · 고정 · 검색'**
  String get moreDescMemo;

  /// No description provided for @moreDescDutchPay.
  ///
  /// In ko, this message translates to:
  /// **'정산 · 친구 · 송금 요청'**
  String get moreDescDutchPay;

  /// No description provided for @moreDescCardBenefits.
  ///
  /// In ko, this message translates to:
  /// **'신용·체크 카드 검색'**
  String get moreDescCardBenefits;

  /// No description provided for @moreDescCategories.
  ///
  /// In ko, this message translates to:
  /// **'지출 · 수입'**
  String get moreDescCategories;

  /// No description provided for @moreDescPresets.
  ///
  /// In ko, this message translates to:
  /// **'자주 쓰는 내역'**
  String get moreDescPresets;

  /// No description provided for @moreDescDisplay.
  ///
  /// In ko, this message translates to:
  /// **'테마 · 언어 · 통화'**
  String get moreDescDisplay;

  /// No description provided for @moreDescSettings.
  ///
  /// In ko, this message translates to:
  /// **'전체 설정 메뉴'**
  String get moreDescSettings;

  /// No description provided for @moreDescNotifications.
  ///
  /// In ko, this message translates to:
  /// **'푸시 · 방해 금지'**
  String get moreDescNotifications;

  /// No description provided for @moreDescExport.
  ///
  /// In ko, this message translates to:
  /// **'CSV · Excel · JSON'**
  String get moreDescExport;

  /// No description provided for @moreDescAccount.
  ///
  /// In ko, this message translates to:
  /// **'프로필 · 보안 · 구독'**
  String get moreDescAccount;

  /// No description provided for @moreSearchHint.
  ///
  /// In ko, this message translates to:
  /// **'메뉴 검색'**
  String get moreSearchHint;

  /// No description provided for @moreSearchEmpty.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과가 없어요'**
  String get moreSearchEmpty;

  /// No description provided for @settingsGroupDataMgmt.
  ///
  /// In ko, this message translates to:
  /// **'데이터 관리'**
  String get settingsGroupDataMgmt;

  /// No description provided for @settingsMenuCategory.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 관리'**
  String get settingsMenuCategory;

  /// No description provided for @settingsMenuAccountCard.
  ///
  /// In ko, this message translates to:
  /// **'계좌 · 카드 관리'**
  String get settingsMenuAccountCard;

  /// No description provided for @settingsMenuBudget.
  ///
  /// In ko, this message translates to:
  /// **'예산 설정'**
  String get settingsMenuBudget;

  /// No description provided for @settingsMenuRecurring.
  ///
  /// In ko, this message translates to:
  /// **'반복 거래 관리'**
  String get settingsMenuRecurring;

  /// No description provided for @settingsMenuPreset.
  ///
  /// In ko, this message translates to:
  /// **'프리셋 관리'**
  String get settingsMenuPreset;

  /// No description provided for @settingsGroupTagsLabels.
  ///
  /// In ko, this message translates to:
  /// **'태그 · 라벨'**
  String get settingsGroupTagsLabels;

  /// No description provided for @settingsGroupShare.
  ///
  /// In ko, this message translates to:
  /// **'공유'**
  String get settingsGroupShare;

  /// No description provided for @settingsMenuCalendarShare.
  ///
  /// In ko, this message translates to:
  /// **'캘린더 관리 · 공유'**
  String get settingsMenuCalendarShare;

  /// No description provided for @settingsMenuCalendarLabel.
  ///
  /// In ko, this message translates to:
  /// **'캘린더 라벨'**
  String get settingsMenuCalendarLabel;

  /// No description provided for @settingsGroupApp.
  ///
  /// In ko, this message translates to:
  /// **'앱 환경'**
  String get settingsGroupApp;

  /// No description provided for @settingsMenuAppearance.
  ///
  /// In ko, this message translates to:
  /// **'표시 설정'**
  String get settingsMenuAppearance;

  /// No description provided for @settingsGroupData.
  ///
  /// In ko, this message translates to:
  /// **'데이터'**
  String get settingsGroupData;

  /// No description provided for @settingsGroupAccount.
  ///
  /// In ko, this message translates to:
  /// **'계정'**
  String get settingsGroupAccount;

  /// No description provided for @settingsMenuAccountMgmt.
  ///
  /// In ko, this message translates to:
  /// **'계정 관리'**
  String get settingsMenuAccountMgmt;

  /// No description provided for @settingsMenuPrivacyPolicy.
  ///
  /// In ko, this message translates to:
  /// **'개인정보 처리방침'**
  String get settingsMenuPrivacyPolicy;

  /// No description provided for @settingsPrivacyOpenFailed.
  ///
  /// In ko, this message translates to:
  /// **'처리방침을 열지 못했어요.'**
  String get settingsPrivacyOpenFailed;

  /// No description provided for @settingsGroupHelp.
  ///
  /// In ko, this message translates to:
  /// **'도움말'**
  String get settingsGroupHelp;

  /// No description provided for @settingsMenuGuide.
  ///
  /// In ko, this message translates to:
  /// **'설명서'**
  String get settingsMenuGuide;

  /// No description provided for @settingsGuideOpenFailed.
  ///
  /// In ko, this message translates to:
  /// **'설명서를 열지 못했어요.'**
  String get settingsGuideOpenFailed;

  /// No description provided for @appearanceTitle.
  ///
  /// In ko, this message translates to:
  /// **'표시 설정'**
  String get appearanceTitle;

  /// No description provided for @appearanceTheme.
  ///
  /// In ko, this message translates to:
  /// **'테마'**
  String get appearanceTheme;

  /// No description provided for @appearanceThemeLight.
  ///
  /// In ko, this message translates to:
  /// **'라이트'**
  String get appearanceThemeLight;

  /// No description provided for @appearanceThemeLightDesc.
  ///
  /// In ko, this message translates to:
  /// **'밝은 배경'**
  String get appearanceThemeLightDesc;

  /// No description provided for @appearanceThemeDark.
  ///
  /// In ko, this message translates to:
  /// **'다크'**
  String get appearanceThemeDark;

  /// No description provided for @appearanceThemeDarkDesc.
  ///
  /// In ko, this message translates to:
  /// **'어두운 배경'**
  String get appearanceThemeDarkDesc;

  /// No description provided for @appearanceThemeSystem.
  ///
  /// In ko, this message translates to:
  /// **'시스템'**
  String get appearanceThemeSystem;

  /// No description provided for @appearanceThemeSystemDesc.
  ///
  /// In ko, this message translates to:
  /// **'OS 설정 따라가기'**
  String get appearanceThemeSystemDesc;

  /// No description provided for @hideAmountsTitle.
  ///
  /// In ko, this message translates to:
  /// **'금액 가리기'**
  String get hideAmountsTitle;

  /// No description provided for @hideAmountsSectionDesc.
  ///
  /// In ko, this message translates to:
  /// **'가릴 카드를 골라 두세요. 저장할 때 한 번만 본인 확인을 해요.'**
  String get hideAmountsSectionDesc;

  /// No description provided for @hideAmountsTabAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get hideAmountsTabAll;

  /// No description provided for @hideAmountsSelectAll.
  ///
  /// In ko, this message translates to:
  /// **'모두 선택'**
  String get hideAmountsSelectAll;

  /// No description provided for @hideAmountsClearAll.
  ///
  /// In ko, this message translates to:
  /// **'모두 해제'**
  String get hideAmountsClearAll;

  /// No description provided for @hideAmountsScreensCount.
  ///
  /// In ko, this message translates to:
  /// **'가릴 화면 · {count} / {total}'**
  String hideAmountsScreensCount(int count, int total);

  /// No description provided for @hideAmountsSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'금액 가리기를 저장하지 못했어요.'**
  String get hideAmountsSaveFailed;

  /// No description provided for @hideAmountsDiscardTitle.
  ///
  /// In ko, this message translates to:
  /// **'저장하지 않고 나가기'**
  String get hideAmountsDiscardTitle;

  /// No description provided for @hideAmountsDiscardBody.
  ///
  /// In ko, this message translates to:
  /// **'고른 내용이 사라져요.'**
  String get hideAmountsDiscardBody;

  /// No description provided for @hideAmountsDiscardConfirm.
  ///
  /// In ko, this message translates to:
  /// **'나가기'**
  String get hideAmountsDiscardConfirm;

  /// No description provided for @hideAmountsKindLabel.
  ///
  /// In ko, this message translates to:
  /// **'거래 종류'**
  String get hideAmountsKindLabel;

  /// No description provided for @hideAmountsKindNote.
  ///
  /// In ko, this message translates to:
  /// **'화면과 상관없이 그 종류의 거래 금액을 가려요. 수입이나 지출을 가리면 합계 · 잔액도 함께 가려져요.'**
  String get hideAmountsKindNote;

  /// No description provided for @hideAmountsKindHelp.
  ///
  /// In ko, this message translates to:
  /// **'거래 종류 안내'**
  String get hideAmountsKindHelp;

  /// No description provided for @hideAmountsTabsLabel.
  ///
  /// In ko, this message translates to:
  /// **'화면 고르기'**
  String get hideAmountsTabsLabel;

  /// No description provided for @hideAmountsScreensTitle.
  ///
  /// In ko, this message translates to:
  /// **'가릴 화면 · '**
  String get hideAmountsScreensTitle;

  /// No description provided for @hideCardKindExpense.
  ///
  /// In ko, this message translates to:
  /// **'지출 거래'**
  String get hideCardKindExpense;

  /// No description provided for @hideCardKindIncome.
  ///
  /// In ko, this message translates to:
  /// **'수입 거래'**
  String get hideCardKindIncome;

  /// No description provided for @hideCardKindTransfer.
  ///
  /// In ko, this message translates to:
  /// **'이체 거래'**
  String get hideCardKindTransfer;

  /// No description provided for @hideAmountsPageHome.
  ///
  /// In ko, this message translates to:
  /// **'홈'**
  String get hideAmountsPageHome;

  /// No description provided for @hideAmountsPageAsset.
  ///
  /// In ko, this message translates to:
  /// **'자산'**
  String get hideAmountsPageAsset;

  /// No description provided for @hideAmountsPageLedger.
  ///
  /// In ko, this message translates to:
  /// **'가계부'**
  String get hideAmountsPageLedger;

  /// No description provided for @hideAmountsPageStats.
  ///
  /// In ko, this message translates to:
  /// **'통계'**
  String get hideAmountsPageStats;

  /// No description provided for @hideAmountsPageBudget.
  ///
  /// In ko, this message translates to:
  /// **'예산'**
  String get hideAmountsPageBudget;

  /// No description provided for @hideAmountsPageStocks.
  ///
  /// In ko, this message translates to:
  /// **'증권'**
  String get hideAmountsPageStocks;

  /// No description provided for @hideAmountsPageDutchpay.
  ///
  /// In ko, this message translates to:
  /// **'더치페이'**
  String get hideAmountsPageDutchpay;

  /// No description provided for @hideAmountsPageEtc.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get hideAmountsPageEtc;

  /// No description provided for @hideCardHomeNetWorth.
  ///
  /// In ko, this message translates to:
  /// **'순자산'**
  String get hideCardHomeNetWorth;

  /// No description provided for @hideCardHomeMonthExpense.
  ///
  /// In ko, this message translates to:
  /// **'이번달 수입·지출'**
  String get hideCardHomeMonthExpense;

  /// No description provided for @hideCardHomeCategoryDonut.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 도넛'**
  String get hideCardHomeCategoryDonut;

  /// No description provided for @hideCardHomeBudget.
  ///
  /// In ko, this message translates to:
  /// **'예산 진행'**
  String get hideCardHomeBudget;

  /// No description provided for @hideCardHomeTodaySpend.
  ///
  /// In ko, this message translates to:
  /// **'오늘 지출'**
  String get hideCardHomeTodaySpend;

  /// No description provided for @hideCardHomeUpcoming.
  ///
  /// In ko, this message translates to:
  /// **'예정 결제'**
  String get hideCardHomeUpcoming;

  /// No description provided for @hideCardAssetNetWorth.
  ///
  /// In ko, this message translates to:
  /// **'총 순자산·추이'**
  String get hideCardAssetNetWorth;

  /// No description provided for @hideCardAssetComposition.
  ///
  /// In ko, this message translates to:
  /// **'자산 구성'**
  String get hideCardAssetComposition;

  /// No description provided for @hideCardAssetAccounts.
  ///
  /// In ko, this message translates to:
  /// **'계좌·예금'**
  String get hideCardAssetAccounts;

  /// No description provided for @hideCardAssetInvestments.
  ///
  /// In ko, this message translates to:
  /// **'투자'**
  String get hideCardAssetInvestments;

  /// No description provided for @hideCardAssetCards.
  ///
  /// In ko, this message translates to:
  /// **'카드'**
  String get hideCardAssetCards;

  /// No description provided for @hideCardAssetLoans.
  ///
  /// In ko, this message translates to:
  /// **'대출'**
  String get hideCardAssetLoans;

  /// No description provided for @hideCardAssetSavingGoals.
  ///
  /// In ko, this message translates to:
  /// **'저축목표'**
  String get hideCardAssetSavingGoals;

  /// No description provided for @hideCardAssetUpcoming.
  ///
  /// In ko, this message translates to:
  /// **'예정 결제'**
  String get hideCardAssetUpcoming;

  /// No description provided for @hideCardAssetDetail.
  ///
  /// In ko, this message translates to:
  /// **'자산 상세'**
  String get hideCardAssetDetail;

  /// No description provided for @hideCardAssetManage.
  ///
  /// In ko, this message translates to:
  /// **'계좌 · 카드 관리'**
  String get hideCardAssetManage;

  /// No description provided for @hideCardLedgerMonthSummary.
  ///
  /// In ko, this message translates to:
  /// **'월 합계'**
  String get hideCardLedgerMonthSummary;

  /// No description provided for @hideCardLedgerCalendar.
  ///
  /// In ko, this message translates to:
  /// **'캘린더 금액'**
  String get hideCardLedgerCalendar;

  /// No description provided for @hideCardLedgerTxList.
  ///
  /// In ko, this message translates to:
  /// **'거래 목록'**
  String get hideCardLedgerTxList;

  /// No description provided for @hideCardLedgerTxDetail.
  ///
  /// In ko, this message translates to:
  /// **'거래 상세'**
  String get hideCardLedgerTxDetail;

  /// No description provided for @hideCardStatsCategory.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 탭'**
  String get hideCardStatsCategory;

  /// No description provided for @hideCardStatsTrend.
  ///
  /// In ko, this message translates to:
  /// **'추이 탭'**
  String get hideCardStatsTrend;

  /// No description provided for @hideCardStatsCompare.
  ///
  /// In ko, this message translates to:
  /// **'비교 탭'**
  String get hideCardStatsCompare;

  /// No description provided for @hideCardBudgetHeader.
  ///
  /// In ko, this message translates to:
  /// **'예산 요약'**
  String get hideCardBudgetHeader;

  /// No description provided for @hideCardBudgetPace.
  ///
  /// In ko, this message translates to:
  /// **'소비 속도'**
  String get hideCardBudgetPace;

  /// No description provided for @hideCardBudgetStatus.
  ///
  /// In ko, this message translates to:
  /// **'상태'**
  String get hideCardBudgetStatus;

  /// No description provided for @hideCardBudgetCategories.
  ///
  /// In ko, this message translates to:
  /// **'카테고리별 예산'**
  String get hideCardBudgetCategories;

  /// No description provided for @hideCardBudgetCompliance.
  ///
  /// In ko, this message translates to:
  /// **'준수율'**
  String get hideCardBudgetCompliance;

  /// No description provided for @hideCardBudgetManage.
  ///
  /// In ko, this message translates to:
  /// **'예산 관리'**
  String get hideCardBudgetManage;

  /// No description provided for @hideCardStocksSummary.
  ///
  /// In ko, this message translates to:
  /// **'평가액 요약'**
  String get hideCardStocksSummary;

  /// No description provided for @hideCardStocksHoldings.
  ///
  /// In ko, this message translates to:
  /// **'보유 종목'**
  String get hideCardStocksHoldings;

  /// No description provided for @hideCardStocksDetail.
  ///
  /// In ko, this message translates to:
  /// **'종목 상세'**
  String get hideCardStocksDetail;

  /// No description provided for @hideCardDutchpaySummary.
  ///
  /// In ko, this message translates to:
  /// **'더치페이 요약'**
  String get hideCardDutchpaySummary;

  /// No description provided for @hideCardDutchpaySessions.
  ///
  /// In ko, this message translates to:
  /// **'정산 목록'**
  String get hideCardDutchpaySessions;

  /// No description provided for @hideCardEtcSearch.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과'**
  String get hideCardEtcSearch;

  /// No description provided for @hideCardEtcRecurring.
  ///
  /// In ko, this message translates to:
  /// **'정기 거래'**
  String get hideCardEtcRecurring;

  /// No description provided for @hideCardEtcPreset.
  ///
  /// In ko, this message translates to:
  /// **'프리셋'**
  String get hideCardEtcPreset;

  /// No description provided for @appearanceHideAmount.
  ///
  /// In ko, this message translates to:
  /// **'금액 가리기'**
  String get appearanceHideAmount;

  /// No description provided for @appearanceHideAmountDesc.
  ///
  /// In ko, this message translates to:
  /// **'모든 화면의 금액을 ••••로 표시합니다'**
  String get appearanceHideAmountDesc;

  /// No description provided for @appearanceRegion.
  ///
  /// In ko, this message translates to:
  /// **'기준 지역'**
  String get appearanceRegion;

  /// No description provided for @appearanceRegionDesc.
  ///
  /// In ko, this message translates to:
  /// **'\'오늘\'과 통계의 하루를 이 지역 기준으로 계산해요. 화면의 시간은 기기 시간대로 보여요.'**
  String get appearanceRegionDesc;

  /// No description provided for @appearanceCurrency.
  ///
  /// In ko, this message translates to:
  /// **'기본 통화'**
  String get appearanceCurrency;

  /// No description provided for @appearanceCurrencyKrw.
  ///
  /// In ko, this message translates to:
  /// **'대한민국 원'**
  String get appearanceCurrencyKrw;

  /// No description provided for @appearanceCurrencyUsd.
  ///
  /// In ko, this message translates to:
  /// **'미국 달러'**
  String get appearanceCurrencyUsd;

  /// No description provided for @appearanceCurrencyEur.
  ///
  /// In ko, this message translates to:
  /// **'유로'**
  String get appearanceCurrencyEur;

  /// No description provided for @appearanceCurrencyJpy.
  ///
  /// In ko, this message translates to:
  /// **'일본 엔'**
  String get appearanceCurrencyJpy;

  /// No description provided for @appearanceCurrencyDesc.
  ///
  /// In ko, this message translates to:
  /// **'새 자산·거래를 만들 때 이 통화가 먼저 골라져요.'**
  String get appearanceCurrencyDesc;

  /// No description provided for @appearanceRegionLoadError.
  ///
  /// In ko, this message translates to:
  /// **'기준 지역을 불러오지 못했어요'**
  String get appearanceRegionLoadError;

  /// No description provided for @appearanceCurrencyLoadError.
  ///
  /// In ko, this message translates to:
  /// **'기본 통화를 불러오지 못했어요'**
  String get appearanceCurrencyLoadError;

  /// No description provided for @appearanceSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'설정을 바꾸지 못했어요.'**
  String get appearanceSaveFailed;

  /// No description provided for @passwordChanged.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호를 바꿨어요.'**
  String get passwordChanged;

  /// No description provided for @passwordChangeFailed.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호를 바꾸지 못했어요. 잠시 뒤 다시 시도해주세요.'**
  String get passwordChangeFailed;

  /// No description provided for @passwordCurrent.
  ///
  /// In ko, this message translates to:
  /// **'현재 비밀번호'**
  String get passwordCurrent;

  /// No description provided for @passwordChangeDescription.
  ///
  /// In ko, this message translates to:
  /// **'현재 비밀번호를 확인한 뒤 새 비밀번호로 바꿔요'**
  String get passwordChangeDescription;

  /// No description provided for @passwordCurrentInvalid.
  ///
  /// In ko, this message translates to:
  /// **'현재 비밀번호가 맞지 않아요'**
  String get passwordCurrentInvalid;

  /// No description provided for @passwordNew.
  ///
  /// In ko, this message translates to:
  /// **'새 비밀번호'**
  String get passwordNew;

  /// No description provided for @passwordNewConfirm.
  ///
  /// In ko, this message translates to:
  /// **'새 비밀번호 확인'**
  String get passwordNewConfirm;

  /// No description provided for @passwordMismatch.
  ///
  /// In ko, this message translates to:
  /// **'새 비밀번호가 일치하지 않아요'**
  String get passwordMismatch;

  /// No description provided for @passwordMatched.
  ///
  /// In ko, this message translates to:
  /// **'새 비밀번호가 일치해요'**
  String get passwordMatched;

  /// No description provided for @passwordRuleLength.
  ///
  /// In ko, this message translates to:
  /// **'8자 이상'**
  String get passwordRuleLength;

  /// No description provided for @passwordRuleSpecial.
  ///
  /// In ko, this message translates to:
  /// **'특수문자 1자 이상'**
  String get passwordRuleSpecial;

  /// No description provided for @passwordSameAsCurrent.
  ///
  /// In ko, this message translates to:
  /// **'현재 비밀번호와 다른 비밀번호를 입력해주세요'**
  String get passwordSameAsCurrent;

  /// No description provided for @passwordChangeAction.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get passwordChangeAction;

  /// No description provided for @accountTitle.
  ///
  /// In ko, this message translates to:
  /// **'계정'**
  String get accountTitle;

  /// No description provided for @accountDefaultName.
  ///
  /// In ko, this message translates to:
  /// **'사용자'**
  String get accountDefaultName;

  /// No description provided for @accountJoined.
  ///
  /// In ko, this message translates to:
  /// **'가입 {date}'**
  String accountJoined(String date);

  /// No description provided for @accountEditComingSoon.
  ///
  /// In ko, this message translates to:
  /// **'프로필 수정은 곧 열려요.'**
  String get accountEditComingSoon;

  /// No description provided for @accountSecurity.
  ///
  /// In ko, this message translates to:
  /// **'보안'**
  String get accountSecurity;

  /// No description provided for @accountPasswordDesc.
  ///
  /// In ko, this message translates to:
  /// **'주기적으로 바꾸면 안전해요'**
  String get accountPasswordDesc;

  /// No description provided for @accountTwoFa.
  ///
  /// In ko, this message translates to:
  /// **'2단계 인증'**
  String get accountTwoFa;

  /// No description provided for @accountDevices.
  ///
  /// In ko, this message translates to:
  /// **'로그인된 기기'**
  String get accountDevices;

  /// No description provided for @accountCurrentDevice.
  ///
  /// In ko, this message translates to:
  /// **'현재 기기'**
  String get accountCurrentDevice;

  /// No description provided for @devicesTitle.
  ///
  /// In ko, this message translates to:
  /// **'로그인된 기기'**
  String get devicesTitle;

  /// No description provided for @devicesIntro.
  ///
  /// In ko, this message translates to:
  /// **'이 계정으로 로그인된 기기예요. 낯선 기기가 있으면 로그아웃해주세요.'**
  String get devicesIntro;

  /// No description provided for @devicesCurrent.
  ///
  /// In ko, this message translates to:
  /// **'현재 기기'**
  String get devicesCurrent;

  /// No description provided for @devicesUnknown.
  ///
  /// In ko, this message translates to:
  /// **'알 수 없는 기기'**
  String get devicesUnknown;

  /// No description provided for @devicesLastUsed.
  ///
  /// In ko, this message translates to:
  /// **'마지막 사용 {when}'**
  String devicesLastUsed(String when);

  /// No description provided for @devicesEmpty.
  ///
  /// In ko, this message translates to:
  /// **'로그인된 기기가 없어요'**
  String get devicesEmpty;

  /// No description provided for @devicesLoadError.
  ///
  /// In ko, this message translates to:
  /// **'기기 목록을 불러오지 못했어요'**
  String get devicesLoadError;

  /// No description provided for @devicesLoadErrorHint.
  ///
  /// In ko, this message translates to:
  /// **'잠시 뒤 다시 시도해주세요.'**
  String get devicesLoadErrorHint;

  /// No description provided for @devicesLogoutLabel.
  ///
  /// In ko, this message translates to:
  /// **'{device} 로그아웃'**
  String devicesLogoutLabel(String device);

  /// No description provided for @devicesLogoutFailed.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃하지 못했어요.'**
  String get devicesLogoutFailed;

  /// No description provided for @devicesLogout.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get devicesLogout;

  /// No description provided for @devicesLogoutTitle.
  ///
  /// In ko, this message translates to:
  /// **'{device}에서 로그아웃할까요?'**
  String devicesLogoutTitle(String device);

  /// No description provided for @devicesLogoutConfirm.
  ///
  /// In ko, this message translates to:
  /// **'그 기기는 다시 로그인해야 해요.'**
  String get devicesLogoutConfirm;

  /// No description provided for @devicesLogoutAll.
  ///
  /// In ko, this message translates to:
  /// **'모든 기기에서 로그아웃'**
  String get devicesLogoutAll;

  /// No description provided for @devicesLogoutAllTitle.
  ///
  /// In ko, this message translates to:
  /// **'모든 기기에서 로그아웃할까요?'**
  String get devicesLogoutAllTitle;

  /// No description provided for @devicesLogoutAllConfirm.
  ///
  /// In ko, this message translates to:
  /// **'지금 쓰는 기기도 로그아웃돼요. 다시 로그인해야 해요.'**
  String get devicesLogoutAllConfirm;

  /// No description provided for @accountConnected.
  ///
  /// In ko, this message translates to:
  /// **'연결된 계정'**
  String get accountConnected;

  /// No description provided for @accountNotConnected.
  ///
  /// In ko, this message translates to:
  /// **'연결 안 됨'**
  String get accountNotConnected;

  /// No description provided for @accountConnect.
  ///
  /// In ko, this message translates to:
  /// **'연결'**
  String get accountConnect;

  /// No description provided for @accountLinked.
  ///
  /// In ko, this message translates to:
  /// **'연결됨'**
  String get accountLinked;

  /// No description provided for @accountDisconnect.
  ///
  /// In ko, this message translates to:
  /// **'해제'**
  String get accountDisconnect;

  /// No description provided for @accountProvidersError.
  ///
  /// In ko, this message translates to:
  /// **'연결 상태를 불러오지 못했어요'**
  String get accountProvidersError;

  /// No description provided for @accountLinkError.
  ///
  /// In ko, this message translates to:
  /// **'계정을 연결하지 못했어요.'**
  String get accountLinkError;

  /// No description provided for @accountUnlinkError.
  ///
  /// In ko, this message translates to:
  /// **'연결을 해제하지 못했어요.'**
  String get accountUnlinkError;

  /// No description provided for @accountLinkedToast.
  ///
  /// In ko, this message translates to:
  /// **'{name} 계정이 연결됐어요.'**
  String accountLinkedToast(String name);

  /// No description provided for @accountUnlinkedToast.
  ///
  /// In ko, this message translates to:
  /// **'Google 연결을 해제했어요.'**
  String get accountUnlinkedToast;

  /// No description provided for @accountSecuritiesDesc.
  ///
  /// In ko, this message translates to:
  /// **'토스·나무 등 증권사 API 키를 연결해요'**
  String get accountSecuritiesDesc;

  /// No description provided for @accountBilling.
  ///
  /// In ko, this message translates to:
  /// **'구독·결제'**
  String get accountBilling;

  /// No description provided for @accountNextBilling.
  ///
  /// In ko, this message translates to:
  /// **'다음 결제 {date} · '**
  String accountNextBilling(String date);

  /// No description provided for @accountProActive.
  ///
  /// In ko, this message translates to:
  /// **'Pro 이용 중'**
  String get accountProActive;

  /// No description provided for @accountProPromo.
  ///
  /// In ko, this message translates to:
  /// **'증권 투자는 Pro 전용 · 지금 시작하기'**
  String get accountProPromo;

  /// No description provided for @accountProStart.
  ///
  /// In ko, this message translates to:
  /// **'Pro 시작'**
  String get accountProStart;

  /// No description provided for @accountManage.
  ///
  /// In ko, this message translates to:
  /// **'계정 관리'**
  String get accountManage;

  /// No description provided for @accountLogoutDesc.
  ///
  /// In ko, this message translates to:
  /// **'이 기기에서만'**
  String get accountLogoutDesc;

  /// No description provided for @accountWithdraw.
  ///
  /// In ko, this message translates to:
  /// **'그루 담다 이용 해지'**
  String get accountWithdraw;

  /// No description provided for @accountWithdrawDesc.
  ///
  /// In ko, this message translates to:
  /// **'복구할 수 없어요'**
  String get accountWithdrawDesc;

  /// No description provided for @accountAppVersion.
  ///
  /// In ko, this message translates to:
  /// **'앱 버전 {version}'**
  String accountAppVersion(String version);

  /// No description provided for @accountAppVersionLatest.
  ///
  /// In ko, this message translates to:
  /// **'최신 버전'**
  String get accountAppVersionLatest;

  /// No description provided for @accountAppVersionUpdate.
  ///
  /// In ko, this message translates to:
  /// **'새 버전 {version}'**
  String accountAppVersionUpdate(String version);

  /// No description provided for @accountLogoutConfirm.
  ///
  /// In ko, this message translates to:
  /// **'이 기기에서 로그아웃할까요?'**
  String get accountLogoutConfirm;

  /// No description provided for @accountWithdrawTitle.
  ///
  /// In ko, this message translates to:
  /// **'그루 담다 이용 해지'**
  String get accountWithdrawTitle;

  /// No description provided for @withdrawIntro.
  ///
  /// In ko, this message translates to:
  /// **'이용을 해지하면 바로 로그인이 막히고 되돌릴 수 없어요.'**
  String get withdrawIntro;

  /// No description provided for @withdrawImpactCalendarsOwned.
  ///
  /// In ko, this message translates to:
  /// **'내가 만든 공유 캘린더 {count}개가 삭제되고 멤버도 볼 수 없어요'**
  String withdrawImpactCalendarsOwned(int count);

  /// No description provided for @withdrawImpactCalendarMemberships.
  ///
  /// In ko, this message translates to:
  /// **'참여 중인 캘린더 {count}개에서 빠져요'**
  String withdrawImpactCalendarMemberships(int count);

  /// No description provided for @withdrawImpactDutchPaysOwned.
  ///
  /// In ko, this message translates to:
  /// **'내가 만든 정산 {count}개가 삭제돼요'**
  String withdrawImpactDutchPaysOwned(int count);

  /// No description provided for @withdrawImpactDutchPayParticipations.
  ///
  /// In ko, this message translates to:
  /// **'참여 중인 정산 {count}개에 탈퇴한 사용자로 남아요'**
  String withdrawImpactDutchPayParticipations(int count);

  /// No description provided for @withdrawIrreversibleTitle.
  ///
  /// In ko, this message translates to:
  /// **'되돌릴 수 없어요'**
  String get withdrawIrreversibleTitle;

  /// No description provided for @withdrawIrreversibleRejoin.
  ///
  /// In ko, this message translates to:
  /// **'같은 아이디와 이메일로는 다시 가입할 수 없어요.'**
  String get withdrawIrreversibleRejoin;

  /// No description provided for @withdrawIrreversibleData.
  ///
  /// In ko, this message translates to:
  /// **'해지한 뒤에는 기록을 다시 볼 수 없어요.'**
  String get withdrawIrreversibleData;

  /// No description provided for @withdrawDataRetention.
  ///
  /// In ko, this message translates to:
  /// **'가계부 데이터는 개인정보 처리방침에 따라 보관 후 파기돼요. 필요한 자료는 해지 전에 내보내주세요.'**
  String get withdrawDataRetention;

  /// No description provided for @withdrawReasonLabel.
  ///
  /// In ko, this message translates to:
  /// **'떠나는 이유'**
  String get withdrawReasonLabel;

  /// No description provided for @withdrawReasonPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'알려주면 다음에 더 낫게 만들게요'**
  String get withdrawReasonPlaceholder;

  /// No description provided for @withdrawNext.
  ///
  /// In ko, this message translates to:
  /// **'계속'**
  String get withdrawNext;

  /// No description provided for @withdrawConfirm.
  ///
  /// In ko, this message translates to:
  /// **'해지하기'**
  String get withdrawConfirm;

  /// No description provided for @withdrawReauthIntro.
  ///
  /// In ko, this message translates to:
  /// **'본인이 맞는지 한 번만 더 확인할게요.'**
  String get withdrawReauthIntro;

  /// No description provided for @withdrawUseEmailCode.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호가 없다면 메일로 코드 받기'**
  String get withdrawUseEmailCode;

  /// No description provided for @withdrawUsePassword.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호로 확인하기'**
  String get withdrawUsePassword;

  /// No description provided for @withdrawCodeLabel.
  ///
  /// In ko, this message translates to:
  /// **'인증 코드'**
  String get withdrawCodeLabel;

  /// No description provided for @withdrawCodePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'6자리 숫자'**
  String get withdrawCodePlaceholder;

  /// No description provided for @withdrawSendCode.
  ///
  /// In ko, this message translates to:
  /// **'코드 받기'**
  String get withdrawSendCode;

  /// No description provided for @withdrawResendCode.
  ///
  /// In ko, this message translates to:
  /// **'다시 받기'**
  String get withdrawResendCode;

  /// No description provided for @withdrawCodeSent.
  ///
  /// In ko, this message translates to:
  /// **'메일로 코드를 보냈어요.'**
  String get withdrawCodeSent;

  /// No description provided for @withdrawFailed.
  ///
  /// In ko, this message translates to:
  /// **'해지하지 못했어요. 잠시 뒤 다시 시도해주세요.'**
  String get withdrawFailed;

  /// No description provided for @withdrawBlockedSubscription.
  ///
  /// In ko, this message translates to:
  /// **'구독이 남아 있어 아직 해지할 수 없어요.'**
  String get withdrawBlockedSubscription;

  /// No description provided for @withdrawBlockedSubscriptionUntil.
  ///
  /// In ko, this message translates to:
  /// **'구독이 {date}까지 남아 있어 아직 해지할 수 없어요.'**
  String withdrawBlockedSubscriptionUntil(String date);

  /// No description provided for @withdrawBlockedOther.
  ///
  /// In ko, this message translates to:
  /// **'아직 해지할 수 없는 상태예요.'**
  String get withdrawBlockedOther;

  /// No description provided for @withdrawBlockedHint.
  ///
  /// In ko, this message translates to:
  /// **'구독을 먼저 해지하면 남은 기간이 끝난 뒤에 이용 해지를 할 수 있어요.'**
  String get withdrawBlockedHint;

  /// No description provided for @withdrawnTitle.
  ///
  /// In ko, this message translates to:
  /// **'이용 해지가 끝났어요'**
  String get withdrawnTitle;

  /// No description provided for @withdrawnBody.
  ///
  /// In ko, this message translates to:
  /// **'그동안 그루 담다를 써 주셔서 감사했습니다. 남은 데이터는 개인정보 처리방침에 따라 보관 후 파기돼요.'**
  String get withdrawnBody;

  /// No description provided for @withdrawnToLogin.
  ///
  /// In ko, this message translates to:
  /// **'로그인 화면으로'**
  String get withdrawnToLogin;

  /// No description provided for @withdrawCodeDescription.
  ///
  /// In ko, this message translates to:
  /// **'10분 안에 입력해주세요 · 5번 틀리면 다시 받아요.'**
  String get withdrawCodeDescription;

  /// No description provided for @withdrawCodeIncomplete.
  ///
  /// In ko, this message translates to:
  /// **'인증 코드 6자리를 입력해주세요.'**
  String get withdrawCodeIncomplete;

  /// No description provided for @withdrawCodeWrong.
  ///
  /// In ko, this message translates to:
  /// **'코드가 맞지 않거나 시간이 지났어요. 확인하거나 다시 받아주세요.'**
  String get withdrawCodeWrong;

  /// No description provided for @withdrawResendCooldown.
  ///
  /// In ko, this message translates to:
  /// **'다시 받기({seconds}초)'**
  String withdrawResendCooldown(int seconds);

  /// No description provided for @withdrawBusy.
  ///
  /// In ko, this message translates to:
  /// **'해지하는 중'**
  String get withdrawBusy;

  /// No description provided for @withdrawLoadFailedTitle.
  ///
  /// In ko, this message translates to:
  /// **'해지 정보를 불러오지 못했어요'**
  String get withdrawLoadFailedTitle;

  /// No description provided for @sheetLeaveTitle.
  ///
  /// In ko, this message translates to:
  /// **'작성한 내용이 사라져요'**
  String get sheetLeaveTitle;

  /// No description provided for @sheetLeaveDescription.
  ///
  /// In ko, this message translates to:
  /// **'나가면 입력한 내용이 저장되지 않아요.'**
  String get sheetLeaveDescription;

  /// No description provided for @sheetLeaveStay.
  ///
  /// In ko, this message translates to:
  /// **'계속 작성'**
  String get sheetLeaveStay;

  /// No description provided for @sheetLeaveLeave.
  ///
  /// In ko, this message translates to:
  /// **'나가기'**
  String get sheetLeaveLeave;

  /// No description provided for @notiSettings.
  ///
  /// In ko, this message translates to:
  /// **'알림 설정'**
  String get notiSettings;

  /// No description provided for @notiSettingsLoadError.
  ///
  /// In ko, this message translates to:
  /// **'알림 설정을 불러오지 못했어요'**
  String get notiSettingsLoadError;

  /// No description provided for @notiKindTitle.
  ///
  /// In ko, this message translates to:
  /// **'알림 종류'**
  String get notiKindTitle;

  /// No description provided for @notiPayment.
  ///
  /// In ko, this message translates to:
  /// **'결제 알림'**
  String get notiPayment;

  /// No description provided for @notiPaymentDesc.
  ///
  /// In ko, this message translates to:
  /// **'결제 예정일 D-1, 결제일 당일 알림'**
  String get notiPaymentDesc;

  /// No description provided for @notiBudgetDesc.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 예산 {threshold}%·100% 도달'**
  String notiBudgetDesc(int threshold);

  /// No description provided for @notiAutoRecord.
  ///
  /// In ko, this message translates to:
  /// **'자동 기록 알림'**
  String get notiAutoRecord;

  /// No description provided for @notiAutoRecordDesc.
  ///
  /// In ko, this message translates to:
  /// **'반복 거래가 자동으로 기록되었을 때'**
  String get notiAutoRecordDesc;

  /// No description provided for @notiDutchPay.
  ///
  /// In ko, this message translates to:
  /// **'더치페이 알림'**
  String get notiDutchPay;

  /// No description provided for @notiDutchPayDesc.
  ///
  /// In ko, this message translates to:
  /// **'송금 요청 / 정산 완료 알림'**
  String get notiDutchPayDesc;

  /// No description provided for @notiCalendarDesc.
  ///
  /// In ko, this message translates to:
  /// **'캘린더 일정 시작 15분 전'**
  String get notiCalendarDesc;

  /// No description provided for @notiWeeklyReport.
  ///
  /// In ko, this message translates to:
  /// **'주간 리포트'**
  String get notiWeeklyReport;

  /// No description provided for @notiWeeklyReportDesc.
  ///
  /// In ko, this message translates to:
  /// **'매주 월요일 오전 9시'**
  String get notiWeeklyReportDesc;

  /// No description provided for @notiMonthlyReport.
  ///
  /// In ko, this message translates to:
  /// **'월간 리포트'**
  String get notiMonthlyReport;

  /// No description provided for @notiMonthlyReportDesc.
  ///
  /// In ko, this message translates to:
  /// **'매월 1일 오전 9시'**
  String get notiMonthlyReportDesc;

  /// No description provided for @notiPush.
  ///
  /// In ko, this message translates to:
  /// **'푸시 알림'**
  String get notiPush;

  /// No description provided for @notiPushOn.
  ///
  /// In ko, this message translates to:
  /// **'모든 알림이 켜져 있어요'**
  String get notiPushOn;

  /// No description provided for @notiPushOff.
  ///
  /// In ko, this message translates to:
  /// **'알림이 꺼져 있어요'**
  String get notiPushOff;

  /// No description provided for @notiThresholdTitle.
  ///
  /// In ko, this message translates to:
  /// **'예산 알림 기준'**
  String get notiThresholdTitle;

  /// No description provided for @notiQuietTitle.
  ///
  /// In ko, this message translates to:
  /// **'방해 금지 시간'**
  String get notiQuietTitle;

  /// No description provided for @notiQuietToggle.
  ///
  /// In ko, this message translates to:
  /// **'방해 금지 사용'**
  String get notiQuietToggle;

  /// No description provided for @notiQuietToggleDesc.
  ///
  /// In ko, this message translates to:
  /// **'시간대를 지정해 자동 무음'**
  String get notiQuietToggleDesc;

  /// No description provided for @notiQuietStart.
  ///
  /// In ko, this message translates to:
  /// **'시작'**
  String get notiQuietStart;

  /// No description provided for @notiQuietEnd.
  ///
  /// In ko, this message translates to:
  /// **'종료'**
  String get notiQuietEnd;

  /// No description provided for @notiSoundTitle.
  ///
  /// In ko, this message translates to:
  /// **'소리 · 진동'**
  String get notiSoundTitle;

  /// No description provided for @notiSound.
  ///
  /// In ko, this message translates to:
  /// **'알림음'**
  String get notiSound;

  /// No description provided for @notiSoundDesc.
  ///
  /// In ko, this message translates to:
  /// **'앱 알림 사운드'**
  String get notiSoundDesc;

  /// No description provided for @notiSoundChime.
  ///
  /// In ko, this message translates to:
  /// **'차임'**
  String get notiSoundChime;

  /// No description provided for @notiSoundDefault.
  ///
  /// In ko, this message translates to:
  /// **'기본'**
  String get notiSoundDefault;

  /// No description provided for @notiSoundNone.
  ///
  /// In ko, this message translates to:
  /// **'무음'**
  String get notiSoundNone;

  /// No description provided for @notiVibration.
  ///
  /// In ko, this message translates to:
  /// **'진동'**
  String get notiVibration;

  /// No description provided for @notiVibrationDesc.
  ///
  /// In ko, this message translates to:
  /// **'모바일에서 진동 함께 알림'**
  String get notiVibrationDesc;

  /// No description provided for @notiEmailTitle.
  ///
  /// In ko, this message translates to:
  /// **'이메일 알림'**
  String get notiEmailTitle;

  /// No description provided for @notiEmailToggle.
  ///
  /// In ko, this message translates to:
  /// **'이메일 받기'**
  String get notiEmailToggle;

  /// No description provided for @notiEmailNone.
  ///
  /// In ko, this message translates to:
  /// **'등록된 이메일이 없어요'**
  String get notiEmailNone;

  /// No description provided for @notiEmailFreq.
  ///
  /// In ko, this message translates to:
  /// **'발송 주기'**
  String get notiEmailFreq;

  /// No description provided for @notiEmailDaily.
  ///
  /// In ko, this message translates to:
  /// **'매일'**
  String get notiEmailDaily;

  /// No description provided for @notiEmailWeekly.
  ///
  /// In ko, this message translates to:
  /// **'매주'**
  String get notiEmailWeekly;

  /// No description provided for @notiEmailMonthly.
  ///
  /// In ko, this message translates to:
  /// **'매월'**
  String get notiEmailMonthly;

  /// No description provided for @presetManageTitle.
  ///
  /// In ko, this message translates to:
  /// **'프리셋 관리'**
  String get presetManageTitle;

  /// No description provided for @presetDetailTitle.
  ///
  /// In ko, this message translates to:
  /// **'프리셋 상세'**
  String get presetDetailTitle;

  /// No description provided for @presetTypeLabel.
  ///
  /// In ko, this message translates to:
  /// **'종류'**
  String get presetTypeLabel;

  /// No description provided for @presetDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'이미 기록된 거래는 그대로 남아요. 삭제한 프리셋은 되돌릴 수 없어요.'**
  String get presetDeleteConfirm;

  /// No description provided for @presetDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'프리셋을 삭제하지 못했어요'**
  String get presetDeleteFailed;

  /// No description provided for @presetSortUsed.
  ///
  /// In ko, this message translates to:
  /// **'많이 쓴 순'**
  String get presetSortUsed;

  /// No description provided for @presetSortRecent.
  ///
  /// In ko, this message translates to:
  /// **'최근 사용'**
  String get presetSortRecent;

  /// No description provided for @presetSortName.
  ///
  /// In ko, this message translates to:
  /// **'이름순'**
  String get presetSortName;

  /// No description provided for @presetListTitle.
  ///
  /// In ko, this message translates to:
  /// **'프리셋 {count}개'**
  String presetListTitle(int count);

  /// No description provided for @presetUses.
  ///
  /// In ko, this message translates to:
  /// **'{count}번'**
  String presetUses(int count);

  /// No description provided for @presetSortLabel.
  ///
  /// In ko, this message translates to:
  /// **'정렬'**
  String get presetSortLabel;

  /// No description provided for @presetLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'프리셋을 불러오지 못했어요'**
  String get presetLoadFailed;

  /// No description provided for @presetCategoryLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'카테고리를 불러오지 못했어요'**
  String get presetCategoryLoadFailed;

  /// No description provided for @presetDeleteConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'\"{name}\" 프리셋을 삭제할까요?'**
  String presetDeleteConfirmTitle(String name);

  /// No description provided for @presetNoteFixed.
  ///
  /// In ko, this message translates to:
  /// **'고정 금액'**
  String get presetNoteFixed;

  /// No description provided for @presetNoteUses.
  ///
  /// In ko, this message translates to:
  /// **'{count}번 썼어요'**
  String presetNoteUses(int count);

  /// No description provided for @presetNoteUnused.
  ///
  /// In ko, this message translates to:
  /// **'아직 쓰지 않았어요'**
  String get presetNoteUnused;

  /// No description provided for @presetNoteLast.
  ///
  /// In ko, this message translates to:
  /// **'마지막 {month}월 {day}일'**
  String presetNoteLast(int month, int day);

  /// No description provided for @presetFixedOn.
  ///
  /// In ko, this message translates to:
  /// **'켬'**
  String get presetFixedOn;

  /// No description provided for @presetFixedOff.
  ///
  /// In ko, this message translates to:
  /// **'끔'**
  String get presetFixedOff;

  /// No description provided for @presetNameRequired.
  ///
  /// In ko, this message translates to:
  /// **'이름을 입력해주세요.'**
  String get presetNameRequired;

  /// No description provided for @presetNameTooLong.
  ///
  /// In ko, this message translates to:
  /// **'프리셋 이름은 12자 이내로 입력해주세요.'**
  String get presetNameTooLong;

  /// No description provided for @presetCategoryRequired.
  ///
  /// In ko, this message translates to:
  /// **'카테고리를 골라주세요.'**
  String get presetCategoryRequired;

  /// No description provided for @presetFromRequired.
  ///
  /// In ko, this message translates to:
  /// **'보내는 계좌를 골라주세요.'**
  String get presetFromRequired;

  /// No description provided for @presetToRequired.
  ///
  /// In ko, this message translates to:
  /// **'받는 계좌를 골라주세요.'**
  String get presetToRequired;

  /// No description provided for @presetSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'저장하지 못했어요. 잠시 뒤 다시 시도해주세요.'**
  String get presetSaveFailed;

  /// No description provided for @presetAmountLabel.
  ///
  /// In ko, this message translates to:
  /// **'금액'**
  String get presetAmountLabel;

  /// No description provided for @presetFeeLabel.
  ///
  /// In ko, this message translates to:
  /// **'수수료'**
  String get presetFeeLabel;

  /// No description provided for @presetAmountBlank.
  ///
  /// In ko, this message translates to:
  /// **'비워 둠'**
  String get presetAmountBlank;

  /// No description provided for @presetAmountHint.
  ///
  /// In ko, this message translates to:
  /// **'비워 두면 불러올 때 금액을 직접 넣어요.'**
  String get presetAmountHint;

  /// No description provided for @presetMemoPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'선택 사항'**
  String get presetMemoPlaceholder;

  /// No description provided for @presetInterestTooLarge.
  ///
  /// In ko, this message translates to:
  /// **'이자는 금액보다 클 수 없어요.'**
  String get presetInterestTooLarge;

  /// No description provided for @presetSelectOf.
  ///
  /// In ko, this message translates to:
  /// **'{field} 선택'**
  String presetSelectOf(String field);

  /// No description provided for @presetNoneOf.
  ///
  /// In ko, this message translates to:
  /// **'{field} 없음'**
  String presetNoneOf(String field);

  /// No description provided for @presetNoneValue.
  ///
  /// In ko, this message translates to:
  /// **'없음'**
  String get presetNoneValue;

  /// No description provided for @presetMemoNone.
  ///
  /// In ko, this message translates to:
  /// **'메모 없음'**
  String get presetMemoNone;

  /// No description provided for @presetNoAccount.
  ///
  /// In ko, this message translates to:
  /// **'계좌·카드 없음'**
  String get presetNoAccount;

  /// No description provided for @presetNoPayment.
  ///
  /// In ko, this message translates to:
  /// **'결제 수단 없음'**
  String get presetNoPayment;

  /// No description provided for @presetNoCategoryOfKind.
  ///
  /// In ko, this message translates to:
  /// **'이 종류의 카테고리가 없어요.'**
  String get presetNoCategoryOfKind;

  /// No description provided for @presetFromAccount.
  ///
  /// In ko, this message translates to:
  /// **'보내는 계좌'**
  String get presetFromAccount;

  /// No description provided for @presetToAccount.
  ///
  /// In ko, this message translates to:
  /// **'받는 계좌'**
  String get presetToAccount;

  /// No description provided for @presetShowAll.
  ///
  /// In ko, this message translates to:
  /// **'모두 보기'**
  String get presetShowAll;

  /// No description provided for @presetPickTitle.
  ///
  /// In ko, this message translates to:
  /// **'프리셋 고르기'**
  String get presetPickTitle;

  /// No description provided for @presetSearch.
  ///
  /// In ko, this message translates to:
  /// **'프리셋 검색'**
  String get presetSearch;

  /// No description provided for @presetNoResult.
  ///
  /// In ko, this message translates to:
  /// **'찾는 프리셋이 없어요.'**
  String get presetNoResult;

  /// No description provided for @presetAdd.
  ///
  /// In ko, this message translates to:
  /// **'프리셋 추가'**
  String get presetAdd;

  /// No description provided for @presetAmountEmpty.
  ///
  /// In ko, this message translates to:
  /// **'금액 비움'**
  String get presetAmountEmpty;

  /// No description provided for @presetNoCategory.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 없음'**
  String get presetNoCategory;

  /// No description provided for @presetEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'저장된 프리셋이 없어요'**
  String get presetEmptyTitle;

  /// No description provided for @presetEmptyDesc.
  ///
  /// In ko, this message translates to:
  /// **'자주 쓰는 내역(점심 · 교통비 등)을 저장해 두면 내역을 추가할 때 한 번 눌러 카테고리 · 계좌 · 내역을 채워요.'**
  String get presetEmptyDesc;

  /// No description provided for @presetEditTitle.
  ///
  /// In ko, this message translates to:
  /// **'프리셋 수정'**
  String get presetEditTitle;

  /// No description provided for @presetSubmitAdd.
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get presetSubmitAdd;

  /// No description provided for @presetName.
  ///
  /// In ko, this message translates to:
  /// **'프리셋 이름'**
  String get presetName;

  /// No description provided for @presetMerchant.
  ///
  /// In ko, this message translates to:
  /// **'기본 내역'**
  String get presetMerchant;

  /// No description provided for @presetMerchantPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'예: 회사 앞 도시락'**
  String get presetMerchantPlaceholder;

  /// No description provided for @presetAssetCard.
  ///
  /// In ko, this message translates to:
  /// **'계좌·카드'**
  String get presetAssetCard;

  /// No description provided for @recurringToggleFailed.
  ///
  /// In ko, this message translates to:
  /// **'변경 실패'**
  String get recurringToggleFailed;

  /// No description provided for @recurringDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'반복 거래 삭제'**
  String get recurringDeleteTitle;

  /// No description provided for @recurringDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'\"{name}\" 반복 설정을 삭제할까요? 이미 기록된 거래는 그대로 남아요. 삭제한 반복 설정은 되돌릴 수 없어요.'**
  String recurringDeleteConfirm(String name);

  /// No description provided for @recurringDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'삭제 실패'**
  String get recurringDeleteFailed;

  /// No description provided for @recurringLoadError.
  ///
  /// In ko, this message translates to:
  /// **'반복 거래를 불러오지 못했습니다'**
  String get recurringLoadError;

  /// No description provided for @recurringAllList.
  ///
  /// In ko, this message translates to:
  /// **'전체 목록'**
  String get recurringAllList;

  /// No description provided for @recurringAdd.
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get recurringAdd;

  /// No description provided for @recurringFilterAll.
  ///
  /// In ko, this message translates to:
  /// **'전체 {count}'**
  String recurringFilterAll(int count);

  /// No description provided for @recurringFilterExpense.
  ///
  /// In ko, this message translates to:
  /// **'지출 {count}'**
  String recurringFilterExpense(int count);

  /// No description provided for @recurringFilterIncome.
  ///
  /// In ko, this message translates to:
  /// **'수입 {count}'**
  String recurringFilterIncome(int count);

  /// No description provided for @recurringFilterTransfer.
  ///
  /// In ko, this message translates to:
  /// **'이체 {count}'**
  String recurringFilterTransfer(int count);

  /// No description provided for @recurringFilterPaused.
  ///
  /// In ko, this message translates to:
  /// **'일시정지 {count}'**
  String recurringFilterPaused(int count);

  /// No description provided for @recurringStatActive.
  ///
  /// In ko, this message translates to:
  /// **'활성 반복'**
  String get recurringStatActive;

  /// No description provided for @recurringCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}개'**
  String recurringCount(int count);

  /// No description provided for @recurringPaused.
  ///
  /// In ko, this message translates to:
  /// **'일시정지'**
  String get recurringPaused;

  /// No description provided for @recurringPauseAction.
  ///
  /// In ko, this message translates to:
  /// **'정지'**
  String get recurringPauseAction;

  /// No description provided for @recurringMonthlyExpense.
  ///
  /// In ko, this message translates to:
  /// **'매월 고정 지출'**
  String get recurringMonthlyExpense;

  /// No description provided for @recurringMonthlyIncome.
  ///
  /// In ko, this message translates to:
  /// **'매월 고정 수입'**
  String get recurringMonthlyIncome;

  /// No description provided for @recurringUpcoming.
  ///
  /// In ko, this message translates to:
  /// **'다가오는 7일'**
  String get recurringUpcoming;

  /// No description provided for @recurringUpcomingCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}건 예정'**
  String recurringUpcomingCount(int count);

  /// No description provided for @recurringToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get recurringToday;

  /// No description provided for @recurringNoAccount.
  ///
  /// In ko, this message translates to:
  /// **'계좌 없음'**
  String get recurringNoAccount;

  /// No description provided for @recurringOccurrences.
  ///
  /// In ko, this message translates to:
  /// **'{executed}/{max}회'**
  String recurringOccurrences(int executed, int max);

  /// No description provided for @recurringNext.
  ///
  /// In ko, this message translates to:
  /// **'다음'**
  String get recurringNext;

  /// No description provided for @recurringStart.
  ///
  /// In ko, this message translates to:
  /// **'시작'**
  String get recurringStart;

  /// No description provided for @recurringEmpty.
  ///
  /// In ko, this message translates to:
  /// **'해당하는 반복 거래가 없어요'**
  String get recurringEmpty;

  /// No description provided for @recurringIndefinite.
  ///
  /// In ko, this message translates to:
  /// **'무기한'**
  String get recurringIndefinite;

  /// No description provided for @recurringNotifyShort.
  ///
  /// In ko, this message translates to:
  /// **'알림'**
  String get recurringNotifyShort;

  /// No description provided for @recurringAddTitle.
  ///
  /// In ko, this message translates to:
  /// **'반복 거래 추가'**
  String get recurringAddTitle;

  /// No description provided for @recurringEditTitle.
  ///
  /// In ko, this message translates to:
  /// **'반복 거래 수정'**
  String get recurringEditTitle;

  /// No description provided for @recurringSaveSubmit.
  ///
  /// In ko, this message translates to:
  /// **'반복 저장'**
  String get recurringSaveSubmit;

  /// No description provided for @recurringUpdated.
  ///
  /// In ko, this message translates to:
  /// **'반복 설정이 수정되었습니다'**
  String get recurringUpdated;

  /// No description provided for @recurringSaved.
  ///
  /// In ko, this message translates to:
  /// **'반복 설정이 저장되었습니다'**
  String get recurringSaved;

  /// No description provided for @recurringSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'저장 실패'**
  String get recurringSaveFailed;

  /// No description provided for @recurringIntro.
  ///
  /// In ko, this message translates to:
  /// **'이 거래를 정해진 주기로 자동 반복합니다. 구독료·월세·정기 후원 등에 사용해보세요.'**
  String get recurringIntro;

  /// No description provided for @recurringFrequencyLabel.
  ///
  /// In ko, this message translates to:
  /// **'반복 주기'**
  String get recurringFrequencyLabel;

  /// No description provided for @recurringDayOfWeekLabel.
  ///
  /// In ko, this message translates to:
  /// **'요일'**
  String get recurringDayOfWeekLabel;

  /// No description provided for @recurringDayOfMonthLabel.
  ///
  /// In ko, this message translates to:
  /// **'반복 일자'**
  String get recurringDayOfMonthLabel;

  /// No description provided for @recurringDayNote.
  ///
  /// In ko, this message translates to:
  /// **'해당 일이 없는 달은 말일에 처리됩니다'**
  String get recurringDayNote;

  /// No description provided for @recurringEndLabel.
  ///
  /// In ko, this message translates to:
  /// **'종료'**
  String get recurringEndLabel;

  /// No description provided for @recurringExecutionTime.
  ///
  /// In ko, this message translates to:
  /// **'실행 시각'**
  String get recurringExecutionTime;

  /// No description provided for @recurringIndefiniteDesc.
  ///
  /// In ko, this message translates to:
  /// **'중지할 때까지 계속 반복'**
  String get recurringIndefiniteDesc;

  /// No description provided for @recurringByCount.
  ///
  /// In ko, this message translates to:
  /// **'횟수 지정'**
  String get recurringByCount;

  /// No description provided for @recurringTotal.
  ///
  /// In ko, this message translates to:
  /// **'총'**
  String get recurringTotal;

  /// No description provided for @recurringTimesUnit.
  ///
  /// In ko, this message translates to:
  /// **'회'**
  String get recurringTimesUnit;

  /// No description provided for @recurringByDate.
  ///
  /// In ko, this message translates to:
  /// **'종료일 지정'**
  String get recurringByDate;

  /// No description provided for @recurringOptions.
  ///
  /// In ko, this message translates to:
  /// **'옵션'**
  String get recurringOptions;

  /// No description provided for @recurringAutoLog.
  ///
  /// In ko, this message translates to:
  /// **'자동 기록'**
  String get recurringAutoLog;

  /// No description provided for @recurringAutoLogDesc.
  ///
  /// In ko, this message translates to:
  /// **'해당 일자에 거래를 자동으로 추가합니다'**
  String get recurringAutoLogDesc;

  /// No description provided for @recurringNotifyDayBefore.
  ///
  /// In ko, this message translates to:
  /// **'하루 전 알림'**
  String get recurringNotifyDayBefore;

  /// No description provided for @recurringNotifyDesc.
  ///
  /// In ko, this message translates to:
  /// **'결제·이체 예정일 전날 알림을 보냅니다'**
  String get recurringNotifyDesc;

  /// No description provided for @recurringNextDates.
  ///
  /// In ko, this message translates to:
  /// **'다음 예정일'**
  String get recurringNextDates;

  /// No description provided for @recurringSourceSub.
  ///
  /// In ko, this message translates to:
  /// **'구독료·월세 등 정기 거래에 쓰여요'**
  String get recurringSourceSub;

  /// No description provided for @recurringStartFrom.
  ///
  /// In ko, this message translates to:
  /// **'{date} 시작'**
  String recurringStartFrom(String date);

  /// No description provided for @recurringMerchant.
  ///
  /// In ko, this message translates to:
  /// **'거래처'**
  String get recurringMerchant;

  /// No description provided for @recurringMerchantPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'예: 넷플릭스'**
  String get recurringMerchantPlaceholder;

  /// No description provided for @recurringAssetCard.
  ///
  /// In ko, this message translates to:
  /// **'계좌·카드'**
  String get recurringAssetCard;

  /// No description provided for @recurringAssetLoadError.
  ///
  /// In ko, this message translates to:
  /// **'자산 로드 실패'**
  String get recurringAssetLoadError;

  /// No description provided for @recurringSelectNone.
  ///
  /// In ko, this message translates to:
  /// **'선택 안 함'**
  String get recurringSelectNone;

  /// No description provided for @recurringStartDateLabel.
  ///
  /// In ko, this message translates to:
  /// **'반복 시작일'**
  String get recurringStartDateLabel;

  /// No description provided for @recurringParentCategory.
  ///
  /// In ko, this message translates to:
  /// **'{name} (상위)'**
  String recurringParentCategory(String name);

  /// No description provided for @savingGoalLoadError.
  ///
  /// In ko, this message translates to:
  /// **'저축 목표 로드 실패'**
  String get savingGoalLoadError;

  /// No description provided for @savingGoalFailTitle.
  ///
  /// In ko, this message translates to:
  /// **'저축 목표를 불러오지 못했어요'**
  String get savingGoalFailTitle;

  /// No description provided for @savingGoalOverallProgress.
  ///
  /// In ko, this message translates to:
  /// **'전체 진행률'**
  String get savingGoalOverallProgress;

  /// No description provided for @savingGoalListCount.
  ///
  /// In ko, this message translates to:
  /// **'목표 목록 · {n}개'**
  String savingGoalListCount(int n);

  /// No description provided for @savingGoalAddAction.
  ///
  /// In ko, this message translates to:
  /// **'목표 추가'**
  String get savingGoalAddAction;

  /// No description provided for @savingGoalManagePrompt.
  ///
  /// In ko, this message translates to:
  /// **'설정에서 저축 목표를 추가해보세요.'**
  String get savingGoalManagePrompt;

  /// No description provided for @savingGoalManageLink.
  ///
  /// In ko, this message translates to:
  /// **'관리'**
  String get savingGoalManageLink;

  /// No description provided for @savingGoalNoDeadline.
  ///
  /// In ko, this message translates to:
  /// **'기한 없음'**
  String get savingGoalNoDeadline;

  /// No description provided for @savingGoalCurrentLabel.
  ///
  /// In ko, this message translates to:
  /// **'현재 모은 금액'**
  String get savingGoalCurrentLabel;

  /// No description provided for @savingGoalIconLabel.
  ///
  /// In ko, this message translates to:
  /// **'아이콘'**
  String get savingGoalIconLabel;

  /// No description provided for @savingGoalEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 저축 목표가 없어요. ‘목표 추가’로 시작해보세요.'**
  String get savingGoalEmpty;

  /// No description provided for @savingGoalActionFailed.
  ///
  /// In ko, this message translates to:
  /// **'실패'**
  String get savingGoalActionFailed;

  /// No description provided for @savingGoalAchieved.
  ///
  /// In ko, this message translates to:
  /// **'달성'**
  String get savingGoalAchieved;

  /// No description provided for @savingGoalAdd.
  ///
  /// In ko, this message translates to:
  /// **'저축 목표 추가'**
  String get savingGoalAdd;

  /// No description provided for @savingGoalSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'저축 목표를 저장하지 못했어요.'**
  String get savingGoalSaveFailed;

  /// No description provided for @savingGoalFirstContributeFailed.
  ///
  /// In ko, this message translates to:
  /// **'목표는 만들었지만 첫 납입을 기록하지 못했어요.'**
  String get savingGoalFirstContributeFailed;

  /// No description provided for @savingGoalEdit.
  ///
  /// In ko, this message translates to:
  /// **'저축 목표 수정'**
  String get savingGoalEdit;

  /// No description provided for @savingGoalSubmitAdd.
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get savingGoalSubmitAdd;

  /// No description provided for @savingGoalDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'\"{title}\" 목표를 삭제할까요?'**
  String savingGoalDeleteTitle(String title);

  /// No description provided for @savingGoalDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'삭제한 저축 목표는 되돌릴 수 없어요.'**
  String get savingGoalDeleteConfirm;

  /// No description provided for @savingGoalDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'저축 목표를 삭제하지 못했어요.'**
  String get savingGoalDeleteFailed;

  /// No description provided for @savingGoalNameLabel.
  ///
  /// In ko, this message translates to:
  /// **'목표 이름'**
  String get savingGoalNameLabel;

  /// No description provided for @savingGoalNameHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 유럽 여행'**
  String get savingGoalNameHint;

  /// No description provided for @savingGoalNameDuplicate.
  ///
  /// In ko, this message translates to:
  /// **'같은 이름의 목표가 이미 있어요.'**
  String get savingGoalNameDuplicate;

  /// No description provided for @savingGoalAmountLabel.
  ///
  /// In ko, this message translates to:
  /// **'목표 금액'**
  String get savingGoalAmountLabel;

  /// No description provided for @savingGoalDeadlineLabel.
  ///
  /// In ko, this message translates to:
  /// **'목표일'**
  String get savingGoalDeadlineLabel;

  /// No description provided for @savingGoalDeadlineHint.
  ///
  /// In ko, this message translates to:
  /// **'없음'**
  String get savingGoalDeadlineHint;

  /// No description provided for @savingGoalColorLabel.
  ///
  /// In ko, this message translates to:
  /// **'색상'**
  String get savingGoalColorLabel;

  /// No description provided for @savingGoalErrName.
  ///
  /// In ko, this message translates to:
  /// **'목표 이름을 입력해주세요.'**
  String get savingGoalErrName;

  /// No description provided for @savingGoalErrNameTooLong.
  ///
  /// In ko, this message translates to:
  /// **'목표 이름은 {max}자 이내로 입력해주세요.'**
  String savingGoalErrNameTooLong(int max);

  /// No description provided for @savingGoalErrAmount.
  ///
  /// In ko, this message translates to:
  /// **'목표 금액을 입력해주세요.'**
  String get savingGoalErrAmount;

  /// No description provided for @savingGoalErrAmountTooLarge.
  ///
  /// In ko, this message translates to:
  /// **'목표 금액은 100억원까지 입력할 수 있어요.'**
  String get savingGoalErrAmountTooLarge;

  /// No description provided for @savingGoalErrCurrentExceeds.
  ///
  /// In ko, this message translates to:
  /// **'현재 모은 금액이 목표 금액보다 클 수 없어요.'**
  String get savingGoalErrCurrentExceeds;

  /// No description provided for @savingGoalDeadlineClear.
  ///
  /// In ko, this message translates to:
  /// **'목표일 지우기'**
  String get savingGoalDeadlineClear;

  /// No description provided for @searchAdvancedFilter.
  ///
  /// In ko, this message translates to:
  /// **'고급 필터'**
  String get searchAdvancedFilter;

  /// No description provided for @searchAdvancedOn.
  ///
  /// In ko, this message translates to:
  /// **'고급 필터, 적용 중'**
  String get searchAdvancedOn;

  /// No description provided for @searchHeading.
  ///
  /// In ko, this message translates to:
  /// **'검색'**
  String get searchHeading;

  /// No description provided for @searchHint.
  ///
  /// In ko, this message translates to:
  /// **'거래 검색'**
  String get searchHint;

  /// No description provided for @searchTypeGroup.
  ///
  /// In ko, this message translates to:
  /// **'거래 종류'**
  String get searchTypeGroup;

  /// No description provided for @searchBadAmount.
  ///
  /// In ko, this message translates to:
  /// **'최소 금액을 최대 금액보다 작게 해주세요'**
  String get searchBadAmount;

  /// No description provided for @searchFailed.
  ///
  /// In ko, this message translates to:
  /// **'검색하지 못했어요'**
  String get searchFailed;

  /// No description provided for @searchFailedDesc.
  ///
  /// In ko, this message translates to:
  /// **'잠시 뒤 다시 시도해주세요.'**
  String get searchFailedDesc;

  /// No description provided for @searchEmptyHint.
  ///
  /// In ko, this message translates to:
  /// **'키워드, 가맹점, 메모로 검색해보세요'**
  String get searchEmptyHint;

  /// No description provided for @searchNoResults.
  ///
  /// In ko, this message translates to:
  /// **'결과가 없어요'**
  String get searchNoResults;

  /// No description provided for @statsTabTrend.
  ///
  /// In ko, this message translates to:
  /// **'추이'**
  String get statsTabTrend;

  /// No description provided for @statsTabCompare.
  ///
  /// In ko, this message translates to:
  /// **'비교'**
  String get statsTabCompare;

  /// No description provided for @statsThisQuarter.
  ///
  /// In ko, this message translates to:
  /// **'이번 분기'**
  String get statsThisQuarter;

  /// No description provided for @statsThisYear.
  ///
  /// In ko, this message translates to:
  /// **'올해'**
  String get statsThisYear;

  /// No description provided for @statsCustomPeriod.
  ///
  /// In ko, this message translates to:
  /// **'선택 기간'**
  String get statsCustomPeriod;

  /// No description provided for @statsLastMonth.
  ///
  /// In ko, this message translates to:
  /// **'지난 달'**
  String get statsLastMonth;

  /// No description provided for @statsLastQuarter.
  ///
  /// In ko, this message translates to:
  /// **'지난 분기'**
  String get statsLastQuarter;

  /// No description provided for @statsLastYear.
  ///
  /// In ko, this message translates to:
  /// **'작년'**
  String get statsLastYear;

  /// No description provided for @statsPrevPeriod.
  ///
  /// In ko, this message translates to:
  /// **'이전 기간'**
  String get statsPrevPeriod;

  /// No description provided for @statsMomMonth.
  ///
  /// In ko, this message translates to:
  /// **'{prev} 대비'**
  String statsMomMonth(String prev);

  /// No description provided for @statsMomPrevMonth.
  ///
  /// In ko, this message translates to:
  /// **'전월'**
  String get statsMomPrevMonth;

  /// No description provided for @statsMomPrevQuarter.
  ///
  /// In ko, this message translates to:
  /// **'전분기'**
  String get statsMomPrevQuarter;

  /// No description provided for @statsMomPrevYear.
  ///
  /// In ko, this message translates to:
  /// **'전년'**
  String get statsMomPrevYear;

  /// No description provided for @statsDailyAvg.
  ///
  /// In ko, this message translates to:
  /// **'하루 평균'**
  String get statsDailyAvg;

  /// No description provided for @statsMonthlyAvg.
  ///
  /// In ko, this message translates to:
  /// **'월 평균'**
  String get statsMonthlyAvg;

  /// No description provided for @statsPeriodPickerTitle.
  ///
  /// In ko, this message translates to:
  /// **'기간 선택'**
  String get statsPeriodPickerTitle;

  /// No description provided for @statsNoData.
  ///
  /// In ko, this message translates to:
  /// **'데이터가 없어요.'**
  String get statsNoData;

  /// No description provided for @statsNoDataShort.
  ///
  /// In ko, this message translates to:
  /// **'데이터 없음'**
  String get statsNoDataShort;

  /// No description provided for @statsUnassigned.
  ///
  /// In ko, this message translates to:
  /// **'미지정'**
  String get statsUnassigned;

  /// No description provided for @statsCategoryDetail.
  ///
  /// In ko, this message translates to:
  /// **'{name} 세부'**
  String statsCategoryDetail(String name);

  /// No description provided for @statsPeriodSpending.
  ///
  /// In ko, this message translates to:
  /// **'{period} 지출'**
  String statsPeriodSpending(String period);

  /// No description provided for @statsSpendingByCategory.
  ///
  /// In ko, this message translates to:
  /// **'카테고리별 지출'**
  String get statsSpendingByCategory;

  /// No description provided for @statsNoCategoryData.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 데이터가 없어요.'**
  String get statsNoCategoryData;

  /// No description provided for @statsTopMerchantsTitle.
  ///
  /// In ko, this message translates to:
  /// **'많이 쓴 가맹점 TOP 5'**
  String get statsTopMerchantsTitle;

  /// No description provided for @statsNoMerchantData.
  ///
  /// In ko, this message translates to:
  /// **'가맹점 데이터가 없어요.'**
  String get statsNoMerchantData;

  /// No description provided for @statsNoName.
  ///
  /// In ko, this message translates to:
  /// **'(이름 없음)'**
  String get statsNoName;

  /// No description provided for @statsTimeMorning.
  ///
  /// In ko, this message translates to:
  /// **'아침'**
  String get statsTimeMorning;

  /// No description provided for @statsTimeLunch.
  ///
  /// In ko, this message translates to:
  /// **'점심'**
  String get statsTimeLunch;

  /// No description provided for @statsTimeAfternoon.
  ///
  /// In ko, this message translates to:
  /// **'오후'**
  String get statsTimeAfternoon;

  /// No description provided for @statsTimeEvening.
  ///
  /// In ko, this message translates to:
  /// **'저녁'**
  String get statsTimeEvening;

  /// No description provided for @statsTimeLateNight.
  ///
  /// In ko, this message translates to:
  /// **'심야'**
  String get statsTimeLateNight;

  /// No description provided for @statsTimeDawn.
  ///
  /// In ko, this message translates to:
  /// **'새벽'**
  String get statsTimeDawn;

  /// No description provided for @statsPatternTitle.
  ///
  /// In ko, this message translates to:
  /// **'요일·시간대 지출 패턴'**
  String get statsPatternTitle;

  /// No description provided for @statsPatternDesc.
  ///
  /// In ko, this message translates to:
  /// **'색이 진할수록 지출이 많은 시간대예요 (단위: 원)'**
  String get statsPatternDesc;

  /// No description provided for @statsTooFewTx.
  ///
  /// In ko, this message translates to:
  /// **'{period} 거래가 아직 적어요.'**
  String statsTooFewTx(String period);

  /// No description provided for @statsLegendLow.
  ///
  /// In ko, this message translates to:
  /// **'적음'**
  String get statsLegendLow;

  /// No description provided for @statsLegendHigh.
  ///
  /// In ko, this message translates to:
  /// **'많음'**
  String get statsLegendHigh;

  /// No description provided for @statsTotalPrefix.
  ///
  /// In ko, this message translates to:
  /// **'총'**
  String get statsTotalPrefix;

  /// No description provided for @statsDaysTotal.
  ///
  /// In ko, this message translates to:
  /// **'{days}일 합계'**
  String statsDaysTotal(int days);

  /// No description provided for @statsMomCalculating.
  ///
  /// In ko, this message translates to:
  /// **'{prev} 대비 계산 중…'**
  String statsMomCalculating(String prev);

  /// No description provided for @statsMomUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'{prev} 비교 불가'**
  String statsMomUnavailable(String prev);

  /// No description provided for @statsTopCategory.
  ///
  /// In ko, this message translates to:
  /// **'가장 많이 쓴 카테고리'**
  String get statsTopCategory;

  /// No description provided for @statsTopMerchant.
  ///
  /// In ko, this message translates to:
  /// **'가장 많이 쓴 가맹점'**
  String get statsTopMerchant;

  /// No description provided for @statsIncomeExpenseTrend.
  ///
  /// In ko, this message translates to:
  /// **'수입·지출 추이'**
  String get statsIncomeExpenseTrend;

  /// No description provided for @statsNoTrendData.
  ///
  /// In ko, this message translates to:
  /// **'추이 데이터가 없어요.'**
  String get statsNoTrendData;

  /// No description provided for @statsAvgIncome.
  ///
  /// In ko, this message translates to:
  /// **'평균 수입'**
  String get statsAvgIncome;

  /// No description provided for @statsAvgExpense.
  ///
  /// In ko, this message translates to:
  /// **'평균 지출'**
  String get statsAvgExpense;

  /// No description provided for @statsNetSavings.
  ///
  /// In ko, this message translates to:
  /// **'순저축'**
  String get statsNetSavings;

  /// No description provided for @statsAvgSavings.
  ///
  /// In ko, this message translates to:
  /// **'평균 저축'**
  String get statsAvgSavings;

  /// No description provided for @statsSavingsRate.
  ///
  /// In ko, this message translates to:
  /// **'저축률'**
  String get statsSavingsRate;

  /// No description provided for @statsSavingsInsight.
  ///
  /// In ko, this message translates to:
  /// **'월 평균 수입의 {pct}%를 저축하고 있어요'**
  String statsSavingsInsight(int pct);

  /// No description provided for @statsDailyNetSavings.
  ///
  /// In ko, this message translates to:
  /// **'일별 순저축'**
  String get statsDailyNetSavings;

  /// No description provided for @statsMonthlyNetSavings.
  ///
  /// In ko, this message translates to:
  /// **'월별 순저축'**
  String get statsMonthlyNetSavings;

  /// No description provided for @statsCatTrendTitle.
  ///
  /// In ko, this message translates to:
  /// **'주요 카테고리 월별 추이'**
  String get statsCatTrendTitle;

  /// No description provided for @statsCatTrendTop3.
  ///
  /// In ko, this message translates to:
  /// **'지출 TOP 3'**
  String get statsCatTrendTop3;

  /// No description provided for @statsIncomeMinusExpense.
  ///
  /// In ko, this message translates to:
  /// **'수입 − 지출'**
  String get statsIncomeMinusExpense;

  /// No description provided for @statsNoDataFor.
  ///
  /// In ko, this message translates to:
  /// **'{period} 데이터 없음'**
  String statsNoDataFor(String period);

  /// No description provided for @statsCategoryByMom.
  ///
  /// In ko, this message translates to:
  /// **'카테고리별 {mom}'**
  String statsCategoryByMom(String mom);

  /// No description provided for @statsCategoryDelta.
  ///
  /// In ko, this message translates to:
  /// **'카테고리별 증감'**
  String get statsCategoryDelta;

  /// No description provided for @statsSortByChange.
  ///
  /// In ko, this message translates to:
  /// **'변화 큰 순'**
  String get statsSortByChange;

  /// No description provided for @statsNoCompareData.
  ///
  /// In ko, this message translates to:
  /// **'비교할 데이터가 없어요.'**
  String get statsNoCompareData;

  /// No description provided for @statsWeekdayTitle.
  ///
  /// In ko, this message translates to:
  /// **'요일별 지출 비교'**
  String get statsWeekdayTitle;

  /// No description provided for @statsThisMonthShort.
  ///
  /// In ko, this message translates to:
  /// **'이번 달'**
  String get statsThisMonthShort;

  /// No description provided for @statsLastMonthShort.
  ///
  /// In ko, this message translates to:
  /// **'지난 달'**
  String get statsLastMonthShort;

  /// No description provided for @statsWeekdayInsightDown.
  ///
  /// In ko, this message translates to:
  /// **'{day}요일 지출이 {prev}보다 {amount} 줄었어요.'**
  String statsWeekdayInsightDown(String prev, String day, String amount);

  /// No description provided for @statsWeekdayInsightUp.
  ///
  /// In ko, this message translates to:
  /// **'{day}요일 지출이 {prev}보다 {amount} 늘었어요.'**
  String statsWeekdayInsightUp(String prev, String day, String amount);

  /// No description provided for @statsWeekdayInsightSame.
  ///
  /// In ko, this message translates to:
  /// **'{prev} 비슷해요.'**
  String statsWeekdayInsightSame(String prev);

  /// No description provided for @statsVsLastPrefix.
  ///
  /// In ko, this message translates to:
  /// **'{prev}보다'**
  String statsVsLastPrefix(String prev);

  /// No description provided for @statsVsLastDirLess.
  ///
  /// In ko, this message translates to:
  /// **'덜'**
  String get statsVsLastDirLess;

  /// No description provided for @statsVsLastDirMore.
  ///
  /// In ko, this message translates to:
  /// **'더'**
  String get statsVsLastDirMore;

  /// No description provided for @statsVsLastSuffix.
  ///
  /// In ko, this message translates to:
  /// **'썼어요'**
  String statsVsLastSuffix(String prev);

  /// No description provided for @statsCompareDailyAvg.
  ///
  /// In ko, this message translates to:
  /// **'하루 평균'**
  String get statsCompareDailyAvg;

  /// No description provided for @statsCompareTxCount.
  ///
  /// In ko, this message translates to:
  /// **'거래 건수'**
  String get statsCompareTxCount;

  /// No description provided for @statsComparePerTx.
  ///
  /// In ko, this message translates to:
  /// **'건당 평균'**
  String get statsComparePerTx;

  /// No description provided for @statsCountValue.
  ///
  /// In ko, this message translates to:
  /// **'{count}건'**
  String statsCountValue(int count);

  /// No description provided for @stocksChartLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'차트를 불러오지 못했어요.'**
  String get stocksChartLoadFailed;

  /// No description provided for @stocksSearch.
  ///
  /// In ko, this message translates to:
  /// **'종목 검색'**
  String get stocksSearch;

  /// No description provided for @stocksSearchPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'종목 검색'**
  String get stocksSearchPlaceholder;

  /// No description provided for @stocksSearchNoResults.
  ///
  /// In ko, this message translates to:
  /// **'\'{query}\'에 대한 검색 결과가 없어요'**
  String stocksSearchNoResults(String query);

  /// No description provided for @stocksTabHoldings.
  ///
  /// In ko, this message translates to:
  /// **'보유'**
  String get stocksTabHoldings;

  /// No description provided for @stocksTabWatch.
  ///
  /// In ko, this message translates to:
  /// **'관심'**
  String get stocksTabWatch;

  /// No description provided for @stocksTabDiscover.
  ///
  /// In ko, this message translates to:
  /// **'발견'**
  String get stocksTabDiscover;

  /// No description provided for @stocksNoHoldings.
  ///
  /// In ko, this message translates to:
  /// **'보유 중인 종목이 없어요'**
  String get stocksNoHoldings;

  /// No description provided for @stocksSharesHeld.
  ///
  /// In ko, this message translates to:
  /// **'{qty}주 보유'**
  String stocksSharesHeld(String qty);

  /// No description provided for @stocksRange1d.
  ///
  /// In ko, this message translates to:
  /// **'1일'**
  String get stocksRange1d;

  /// No description provided for @stocksRange1w.
  ///
  /// In ko, this message translates to:
  /// **'1주'**
  String get stocksRange1w;

  /// No description provided for @stocksRange1m.
  ///
  /// In ko, this message translates to:
  /// **'1개월'**
  String get stocksRange1m;

  /// No description provided for @stocksRange3m.
  ///
  /// In ko, this message translates to:
  /// **'3개월'**
  String get stocksRange3m;

  /// No description provided for @stocksRange1y.
  ///
  /// In ko, this message translates to:
  /// **'1년'**
  String get stocksRange1y;

  /// No description provided for @stocksUnitCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}개'**
  String stocksUnitCount(int count);

  /// No description provided for @stocksSharesUnit.
  ///
  /// In ko, this message translates to:
  /// **'{qty}주'**
  String stocksSharesUnit(String qty);

  /// No description provided for @stocksTradingSuspended.
  ///
  /// In ko, this message translates to:
  /// **'거래정지'**
  String get stocksTradingSuspended;

  /// No description provided for @stocksTradingNormal.
  ///
  /// In ko, this message translates to:
  /// **'정상'**
  String get stocksTradingNormal;

  /// No description provided for @stocksWarningLiquidationTrading.
  ///
  /// In ko, this message translates to:
  /// **'정리매매'**
  String get stocksWarningLiquidationTrading;

  /// No description provided for @stocksWarningOverheated.
  ///
  /// In ko, this message translates to:
  /// **'단기과열'**
  String get stocksWarningOverheated;

  /// No description provided for @stocksWarningShortTermOverheat.
  ///
  /// In ko, this message translates to:
  /// **'단기과열'**
  String get stocksWarningShortTermOverheat;

  /// No description provided for @stocksWarningExcessiveRise.
  ///
  /// In ko, this message translates to:
  /// **'이상급등'**
  String get stocksWarningExcessiveRise;

  /// No description provided for @stocksWarningInvestmentWarning.
  ///
  /// In ko, this message translates to:
  /// **'투자경고'**
  String get stocksWarningInvestmentWarning;

  /// No description provided for @stocksWarningInvestmentRisk.
  ///
  /// In ko, this message translates to:
  /// **'투자위험'**
  String get stocksWarningInvestmentRisk;

  /// No description provided for @stocksWarningInvestmentCaution.
  ///
  /// In ko, this message translates to:
  /// **'투자주의'**
  String get stocksWarningInvestmentCaution;

  /// No description provided for @stocksWarningVi.
  ///
  /// In ko, this message translates to:
  /// **'VI 발동'**
  String get stocksWarningVi;

  /// No description provided for @stocksWarningViStatic.
  ///
  /// In ko, this message translates to:
  /// **'정적 VI'**
  String get stocksWarningViStatic;

  /// No description provided for @stocksWarningViDynamic.
  ///
  /// In ko, this message translates to:
  /// **'동적 VI'**
  String get stocksWarningViDynamic;

  /// No description provided for @stocksWarningStockWarrants.
  ///
  /// In ko, this message translates to:
  /// **'신주인수권'**
  String get stocksWarningStockWarrants;

  /// No description provided for @stocksWarningAdministrative.
  ///
  /// In ko, this message translates to:
  /// **'관리종목'**
  String get stocksWarningAdministrative;

  /// No description provided for @stocksWarningAdjustmentOfShares.
  ///
  /// In ko, this message translates to:
  /// **'주식병합·분할'**
  String get stocksWarningAdjustmentOfShares;

  /// No description provided for @stocksNoWatchlist.
  ///
  /// In ko, this message translates to:
  /// **'관심 종목이 없어요'**
  String get stocksNoWatchlist;

  /// No description provided for @stocksDetailTitle.
  ///
  /// In ko, this message translates to:
  /// **'종목 상세'**
  String get stocksDetailTitle;

  /// No description provided for @stocksMarketHoliday.
  ///
  /// In ko, this message translates to:
  /// **'휴장'**
  String get stocksMarketHoliday;

  /// No description provided for @stocksMarketTrading.
  ///
  /// In ko, this message translates to:
  /// **'장중 · {time}'**
  String stocksMarketTrading(String time);

  /// No description provided for @stocksMarketOpensAt.
  ///
  /// In ko, this message translates to:
  /// **'개장 {time}'**
  String stocksMarketOpensAt(String time);

  /// No description provided for @stocksMarketClosed.
  ///
  /// In ko, this message translates to:
  /// **'장마감'**
  String get stocksMarketClosed;

  /// No description provided for @stocksMarketKr.
  ///
  /// In ko, this message translates to:
  /// **'국내'**
  String get stocksMarketKr;

  /// No description provided for @stocksMarketUs.
  ///
  /// In ko, this message translates to:
  /// **'미국'**
  String get stocksMarketUs;

  /// No description provided for @stocksMyEval.
  ///
  /// In ko, this message translates to:
  /// **'내 투자 평가금액'**
  String get stocksMyEval;

  /// No description provided for @stocksPurchaseAmount.
  ///
  /// In ko, this message translates to:
  /// **'매입금액'**
  String get stocksPurchaseAmount;

  /// No description provided for @stocksHoldingsLabel.
  ///
  /// In ko, this message translates to:
  /// **'보유 종목'**
  String get stocksHoldingsLabel;

  /// No description provided for @stocksExchangeRate.
  ///
  /// In ko, this message translates to:
  /// **'환율(USD)'**
  String get stocksExchangeRate;

  /// No description provided for @stocksSell.
  ///
  /// In ko, this message translates to:
  /// **'매도'**
  String get stocksSell;

  /// No description provided for @stocksBuy.
  ///
  /// In ko, this message translates to:
  /// **'매수'**
  String get stocksBuy;

  /// No description provided for @stocksFeeUs.
  ///
  /// In ko, this message translates to:
  /// **'미국주식 매매수수료 0.1% · 환전 수수료 별도 적용'**
  String get stocksFeeUs;

  /// No description provided for @stocksFeeKr.
  ///
  /// In ko, this message translates to:
  /// **'국내주식 매매수수료 무료 (2026.6까지) · 이후 KRX 0.015% / NXT 0.014%'**
  String get stocksFeeKr;

  /// No description provided for @stocksEvalAmount.
  ///
  /// In ko, this message translates to:
  /// **'평가금액'**
  String get stocksEvalAmount;

  /// No description provided for @stocksEvalPnl.
  ///
  /// In ko, this message translates to:
  /// **'평가손익'**
  String get stocksEvalPnl;

  /// No description provided for @stocksQuantityHeld.
  ///
  /// In ko, this message translates to:
  /// **'보유수량'**
  String get stocksQuantityHeld;

  /// No description provided for @stocksReturnRate.
  ///
  /// In ko, this message translates to:
  /// **'수익률'**
  String get stocksReturnRate;

  /// No description provided for @stocksDayPnl.
  ///
  /// In ko, this message translates to:
  /// **'일간 손익'**
  String get stocksDayPnl;

  /// No description provided for @stocksAvgPrice.
  ///
  /// In ko, this message translates to:
  /// **'평균단가'**
  String get stocksAvgPrice;

  /// No description provided for @stocksFeesTax.
  ///
  /// In ko, this message translates to:
  /// **'수수료·세금'**
  String get stocksFeesTax;

  /// No description provided for @stocksSellable.
  ///
  /// In ko, this message translates to:
  /// **'매도가능'**
  String get stocksSellable;

  /// No description provided for @stocksMyHoldings.
  ///
  /// In ko, this message translates to:
  /// **'내 보유'**
  String get stocksMyHoldings;

  /// No description provided for @stocksMarket.
  ///
  /// In ko, this message translates to:
  /// **'시장'**
  String get stocksMarket;

  /// No description provided for @stocksInstrumentType.
  ///
  /// In ko, this message translates to:
  /// **'종목 유형'**
  String get stocksInstrumentType;

  /// No description provided for @stocksInstrumentStock.
  ///
  /// In ko, this message translates to:
  /// **'주식'**
  String get stocksInstrumentStock;

  /// No description provided for @stocksCurrency.
  ///
  /// In ko, this message translates to:
  /// **'통화'**
  String get stocksCurrency;

  /// No description provided for @stocksMarketCap.
  ///
  /// In ko, this message translates to:
  /// **'시가총액'**
  String get stocksMarketCap;

  /// No description provided for @stocksUpperLimit.
  ///
  /// In ko, this message translates to:
  /// **'상한가'**
  String get stocksUpperLimit;

  /// No description provided for @stocksLowerLimit.
  ///
  /// In ko, this message translates to:
  /// **'하한가'**
  String get stocksLowerLimit;

  /// No description provided for @stocksListingDate.
  ///
  /// In ko, this message translates to:
  /// **'상장일'**
  String get stocksListingDate;

  /// No description provided for @stocksSharesOutstanding.
  ///
  /// In ko, this message translates to:
  /// **'발행주식수'**
  String get stocksSharesOutstanding;

  /// No description provided for @stocksTradingStatus.
  ///
  /// In ko, this message translates to:
  /// **'거래상태'**
  String get stocksTradingStatus;

  /// No description provided for @stocksBasicInfo.
  ///
  /// In ko, this message translates to:
  /// **'기본 정보'**
  String get stocksBasicInfo;

  /// No description provided for @stocksBidVolume.
  ///
  /// In ko, this message translates to:
  /// **'매수 잔량'**
  String get stocksBidVolume;

  /// No description provided for @stocksAskVolume.
  ///
  /// In ko, this message translates to:
  /// **'매도 잔량'**
  String get stocksAskVolume;

  /// No description provided for @stocksGainers.
  ///
  /// In ko, this message translates to:
  /// **'급상승'**
  String get stocksGainers;

  /// No description provided for @stocksLosers.
  ///
  /// In ko, this message translates to:
  /// **'급하락'**
  String get stocksLosers;

  /// No description provided for @stocksVolume.
  ///
  /// In ko, this message translates to:
  /// **'거래량'**
  String get stocksVolume;

  /// No description provided for @stocksOrderbookLoading.
  ///
  /// In ko, this message translates to:
  /// **'호가를 불러오는 중이에요'**
  String get stocksOrderbookLoading;

  /// No description provided for @stocksOrderbookEmpty.
  ///
  /// In ko, this message translates to:
  /// **'호가 정보가 없어요'**
  String get stocksOrderbookEmpty;

  /// No description provided for @stocksTradesLoading.
  ///
  /// In ko, this message translates to:
  /// **'체결 내역을 불러오는 중이에요'**
  String get stocksTradesLoading;

  /// No description provided for @stocksTradesEmpty.
  ///
  /// In ko, this message translates to:
  /// **'체결 내역이 없어요'**
  String get stocksTradesEmpty;

  /// No description provided for @stocksOrderbook.
  ///
  /// In ko, this message translates to:
  /// **'호가'**
  String get stocksOrderbook;

  /// No description provided for @stocksTrades.
  ///
  /// In ko, this message translates to:
  /// **'체결'**
  String get stocksTrades;

  /// No description provided for @stocksTradeTime.
  ///
  /// In ko, this message translates to:
  /// **'체결시각'**
  String get stocksTradeTime;

  /// No description provided for @stocksTradePrice.
  ///
  /// In ko, this message translates to:
  /// **'체결가'**
  String get stocksTradePrice;

  /// No description provided for @stocksTradeVolume.
  ///
  /// In ko, this message translates to:
  /// **'체결량'**
  String get stocksTradeVolume;

  /// No description provided for @stocksDailyPrices.
  ///
  /// In ko, this message translates to:
  /// **'일별 시세'**
  String get stocksDailyPrices;

  /// No description provided for @stocksDailyPricesLoading.
  ///
  /// In ko, this message translates to:
  /// **'일별 시세를 불러오는 중이에요'**
  String get stocksDailyPricesLoading;

  /// No description provided for @stocksDailyPricesEmpty.
  ///
  /// In ko, this message translates to:
  /// **'일별 시세가 없어요'**
  String get stocksDailyPricesEmpty;

  /// No description provided for @stocksDate.
  ///
  /// In ko, this message translates to:
  /// **'일자'**
  String get stocksDate;

  /// No description provided for @stocksClosePrice.
  ///
  /// In ko, this message translates to:
  /// **'종가'**
  String get stocksClosePrice;

  /// No description provided for @stocksChangeRate.
  ///
  /// In ko, this message translates to:
  /// **'등락률'**
  String get stocksChangeRate;

  /// No description provided for @stocksSearchHint.
  ///
  /// In ko, this message translates to:
  /// **'종목명·심볼로 검색하세요 (국내 + 미국·중국·일본·홍콩·베트남)'**
  String get stocksSearchHint;

  /// No description provided for @stocksPriceUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'토스 시세 미지원 종목이에요 (국내·미국만 제공)'**
  String get stocksPriceUnavailable;

  /// No description provided for @stocksRankingLoading.
  ///
  /// In ko, this message translates to:
  /// **'순위를 불러오는 중이에요'**
  String get stocksRankingLoading;

  /// No description provided for @stocksRankingEmpty.
  ///
  /// In ko, this message translates to:
  /// **'집계된 순위가 없어요'**
  String get stocksRankingEmpty;

  /// No description provided for @stocksWatchDefaultGroupName.
  ///
  /// In ko, this message translates to:
  /// **'관심'**
  String get stocksWatchDefaultGroupName;

  /// No description provided for @stocksWatchGroupAdd.
  ///
  /// In ko, this message translates to:
  /// **'그룹 추가'**
  String get stocksWatchGroupAdd;

  /// No description provided for @stocksWatchGroupRename.
  ///
  /// In ko, this message translates to:
  /// **'그룹 이름 바꾸기'**
  String get stocksWatchGroupRename;

  /// No description provided for @stocksWatchGroupDelete.
  ///
  /// In ko, this message translates to:
  /// **'그룹 삭제'**
  String get stocksWatchGroupDelete;

  /// No description provided for @stocksWatchGroupNamePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'그룹 이름'**
  String get stocksWatchGroupNamePlaceholder;

  /// No description provided for @stocksWatchGroupSaveFail.
  ///
  /// In ko, this message translates to:
  /// **'그룹을 저장하지 못했어요.'**
  String get stocksWatchGroupSaveFail;

  /// No description provided for @stocksWatchAddFail.
  ///
  /// In ko, this message translates to:
  /// **'관심 종목에 넣지 못했어요.'**
  String get stocksWatchAddFail;

  /// No description provided for @stocksWatchGroupDeleteFail.
  ///
  /// In ko, this message translates to:
  /// **'그룹을 삭제하지 못했어요.'**
  String get stocksWatchGroupDeleteFail;

  /// No description provided for @stocksWatchRemoveFail.
  ///
  /// In ko, this message translates to:
  /// **'관심 종목에서 빼지 못했어요.'**
  String get stocksWatchRemoveFail;

  /// No description provided for @stocksMarketToggleKr.
  ///
  /// In ko, this message translates to:
  /// **'국내'**
  String get stocksMarketToggleKr;

  /// No description provided for @stocksMarketToggleUs.
  ///
  /// In ko, this message translates to:
  /// **'미국'**
  String get stocksMarketToggleUs;

  /// No description provided for @todoAdd.
  ///
  /// In ko, this message translates to:
  /// **'할 일 추가'**
  String get todoAdd;

  /// No description provided for @todoEditTitle.
  ///
  /// In ko, this message translates to:
  /// **'할 일 수정'**
  String get todoEditTitle;

  /// No description provided for @todoDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'할 일 삭제'**
  String get todoDeleteTitle;

  /// No description provided for @todoDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'\"{title}\" 할 일을 삭제할까요? 되돌릴 수 없어요.'**
  String todoDeleteConfirm(String title);

  /// No description provided for @todoDetail.
  ///
  /// In ko, this message translates to:
  /// **'자세히'**
  String get todoDetail;

  /// No description provided for @todoCompletionRate.
  ///
  /// In ko, this message translates to:
  /// **'완료율'**
  String get todoCompletionRate;

  /// No description provided for @todoQuickAddPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'할 일을 입력하고 Enter'**
  String get todoQuickAddPlaceholder;

  /// No description provided for @todoTitlePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'할 일을 적어주세요'**
  String get todoTitlePlaceholder;

  /// No description provided for @todoTitleRequired.
  ///
  /// In ko, this message translates to:
  /// **'제목을 입력해주세요.'**
  String get todoTitleRequired;

  /// No description provided for @todoDueDate.
  ///
  /// In ko, this message translates to:
  /// **'마감일'**
  String get todoDueDate;

  /// No description provided for @todoUnset.
  ///
  /// In ko, this message translates to:
  /// **'미설정'**
  String get todoUnset;

  /// No description provided for @todoTag.
  ///
  /// In ko, this message translates to:
  /// **'태그'**
  String get todoTag;

  /// No description provided for @todoTagSelect.
  ///
  /// In ko, this message translates to:
  /// **'태그 선택'**
  String get todoTagSelect;

  /// No description provided for @todoTagNone.
  ///
  /// In ko, this message translates to:
  /// **'태그 없음'**
  String get todoTagNone;

  /// No description provided for @todoPriorityLabel.
  ///
  /// In ko, this message translates to:
  /// **'우선순위'**
  String get todoPriorityLabel;

  /// No description provided for @todoPriorityImportant.
  ///
  /// In ko, this message translates to:
  /// **'중요'**
  String get todoPriorityImportant;

  /// No description provided for @todoPriorityRelaxed.
  ///
  /// In ko, this message translates to:
  /// **'여유'**
  String get todoPriorityRelaxed;

  /// No description provided for @todoContentLabel.
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get todoContentLabel;

  /// No description provided for @todoContentPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'예: # 제목 / **굵게** / - 항목 / - [ ] 체크'**
  String get todoContentPlaceholder;

  /// No description provided for @todoEditMode.
  ///
  /// In ko, this message translates to:
  /// **'편집'**
  String get todoEditMode;

  /// No description provided for @todoPreview.
  ///
  /// In ko, this message translates to:
  /// **'미리보기'**
  String get todoPreview;

  /// No description provided for @todoNoContent.
  ///
  /// In ko, this message translates to:
  /// **'없음'**
  String get todoNoContent;

  /// No description provided for @todoEmptyToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘 할 일이 없어요'**
  String get todoEmptyToday;

  /// No description provided for @todoEmptyWeek.
  ///
  /// In ko, this message translates to:
  /// **'이번 주는 한가해요'**
  String get todoEmptyWeek;

  /// No description provided for @todoEmptyDone.
  ///
  /// In ko, this message translates to:
  /// **'아직 완료된 일이 없어요'**
  String get todoEmptyDone;

  /// No description provided for @todoEmptyAll.
  ///
  /// In ko, this message translates to:
  /// **'할 일이 없어요'**
  String get todoEmptyAll;

  /// No description provided for @todoEmptyDoneHint.
  ///
  /// In ko, this message translates to:
  /// **'할 일을 완료하면 여기에 모입니다.'**
  String get todoEmptyDoneHint;

  /// No description provided for @todoEmptyAddHint.
  ///
  /// In ko, this message translates to:
  /// **'위 입력칸으로 빠르게 추가해보세요.'**
  String get todoEmptyAddHint;

  /// No description provided for @todoNewProject.
  ///
  /// In ko, this message translates to:
  /// **'새 프로젝트'**
  String get todoNewProject;

  /// No description provided for @todoProjectNamePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'프로젝트 이름'**
  String get todoProjectNamePlaceholder;

  /// No description provided for @todoDescOptional.
  ///
  /// In ko, this message translates to:
  /// **'설명 (선택)'**
  String get todoDescOptional;

  /// No description provided for @todoAdding.
  ///
  /// In ko, this message translates to:
  /// **'추가 중...'**
  String get todoAdding;

  /// No description provided for @todoAddProject.
  ///
  /// In ko, this message translates to:
  /// **'프로젝트 추가'**
  String get todoAddProject;

  /// No description provided for @todoRegisteredProjects.
  ///
  /// In ko, this message translates to:
  /// **'등록된 프로젝트'**
  String get todoRegisteredProjects;

  /// No description provided for @todoNoProjects.
  ///
  /// In ko, this message translates to:
  /// **'등록된 프로젝트가 없습니다'**
  String get todoNoProjects;

  /// No description provided for @todoDeleteProjectTitle.
  ///
  /// In ko, this message translates to:
  /// **'프로젝트 삭제'**
  String get todoDeleteProjectTitle;

  /// No description provided for @todoDeleteProjectConfirm.
  ///
  /// In ko, this message translates to:
  /// **'\"{name}\" 프로젝트를 삭제하시겠어요? 연결된 할 일은 프로젝트 미지정으로 변경됩니다.'**
  String todoDeleteProjectConfirm(String name);

  /// No description provided for @todoNewTag.
  ///
  /// In ko, this message translates to:
  /// **'태그 추가'**
  String get todoNewTag;

  /// No description provided for @todoTagNamePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'태그 이름'**
  String get todoTagNamePlaceholder;

  /// No description provided for @todoRegisteredTags.
  ///
  /// In ko, this message translates to:
  /// **'등록된 태그'**
  String get todoRegisteredTags;

  /// No description provided for @todoNoTags.
  ///
  /// In ko, this message translates to:
  /// **'등록된 태그가 없습니다'**
  String get todoNoTags;

  /// No description provided for @todoDeleteTagTitle.
  ///
  /// In ko, this message translates to:
  /// **'태그 삭제'**
  String get todoDeleteTagTitle;

  /// No description provided for @todoDeleteTagConfirm.
  ///
  /// In ko, this message translates to:
  /// **'\"{name}\" 태그를 삭제하면 이 태그를 쓰는 할 일 {count}건은 태그 없음으로 남아요. 삭제한 태그는 되돌릴 수 없어요.'**
  String todoDeleteTagConfirm(String name, int count);

  /// No description provided for @todoActionFailed.
  ///
  /// In ko, this message translates to:
  /// **'실패'**
  String get todoActionFailed;

  /// No description provided for @todoAddFailed.
  ///
  /// In ko, this message translates to:
  /// **'추가 실패'**
  String get todoAddFailed;

  /// No description provided for @todoDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'할 일을 삭제하지 못했어요.'**
  String get todoDeleteFailed;

  /// No description provided for @todoUpdateFailed.
  ///
  /// In ko, this message translates to:
  /// **'수정 실패'**
  String get todoUpdateFailed;

  /// No description provided for @todoStatusChangeFailed.
  ///
  /// In ko, this message translates to:
  /// **'상태 변경 실패'**
  String get todoStatusChangeFailed;

  /// No description provided for @todoMoveFailed.
  ///
  /// In ko, this message translates to:
  /// **'이동 실패'**
  String get todoMoveFailed;

  /// No description provided for @todoLoadError.
  ///
  /// In ko, this message translates to:
  /// **'할 일을 불러오지 못했어요'**
  String get todoLoadError;

  /// No description provided for @todoProjectLoadError.
  ///
  /// In ko, this message translates to:
  /// **'프로젝트 로드 실패'**
  String get todoProjectLoadError;

  /// No description provided for @todoTagLoadError.
  ///
  /// In ko, this message translates to:
  /// **'태그를 불러오지 못했어요'**
  String get todoTagLoadError;

  /// No description provided for @subManageTitle.
  ///
  /// In ko, this message translates to:
  /// **'구독 관리'**
  String get subManageTitle;

  /// No description provided for @subUsingPro.
  ///
  /// In ko, this message translates to:
  /// **'담다 Pro 이용 중'**
  String get subUsingPro;

  /// No description provided for @subUsingFree.
  ///
  /// In ko, this message translates to:
  /// **'Free 플랜 이용 중'**
  String get subUsingFree;

  /// No description provided for @subNextBilling.
  ///
  /// In ko, this message translates to:
  /// **'다음 결제 {date} · {amount}'**
  String subNextBilling(String date, String amount);

  /// No description provided for @subProUntil.
  ///
  /// In ko, this message translates to:
  /// **'{date}까지 이용'**
  String subProUntil(String date);

  /// No description provided for @subFreeLockedDesc.
  ///
  /// In ko, this message translates to:
  /// **'증권 연동 · 실시간 시세가 잠겨 있어요'**
  String get subFreeLockedDesc;

  /// No description provided for @subSpotlightDesc.
  ///
  /// In ko, this message translates to:
  /// **'증권 투자는 Pro 전용이에요. 실시간 시세 · 호가, 국내외 종목 검색, 관심종목, 보유 손익까지 — Pro를 구독하면 증권 탭이 바로 열려요.'**
  String get subSpotlightDesc;

  /// No description provided for @subCycleMonthly.
  ///
  /// In ko, this message translates to:
  /// **'월간'**
  String get subCycleMonthly;

  /// No description provided for @subCycleYearly.
  ///
  /// In ko, this message translates to:
  /// **'연간'**
  String get subCycleYearly;

  /// No description provided for @subCycleLabel.
  ///
  /// In ko, this message translates to:
  /// **'결제 주기'**
  String get subCycleLabel;

  /// No description provided for @subCycleYearlyOff.
  ///
  /// In ko, this message translates to:
  /// **'연간 {pct}%↓'**
  String subCycleYearlyOff(int pct);

  /// No description provided for @subYearlyPerMonth.
  ///
  /// In ko, this message translates to:
  /// **'월 {amount} 꼴 · {pct}% 절약'**
  String subYearlyPerMonth(String amount, int pct);

  /// No description provided for @subMonthlyBilling.
  ///
  /// In ko, this message translates to:
  /// **'월 단위 결제'**
  String get subMonthlyBilling;

  /// No description provided for @subFeatureCompare.
  ///
  /// In ko, this message translates to:
  /// **'기능 비교'**
  String get subFeatureCompare;

  /// No description provided for @subCurrentPlan.
  ///
  /// In ko, this message translates to:
  /// **'현재 플랜'**
  String get subCurrentPlan;

  /// No description provided for @subFreeCaption.
  ///
  /// In ko, this message translates to:
  /// **'기본 가계부 기능'**
  String get subFreeCaption;

  /// No description provided for @subFeatLedger.
  ///
  /// In ko, this message translates to:
  /// **'가계부 · 자산 관리'**
  String get subFeatLedger;

  /// No description provided for @subFeatBudget.
  ///
  /// In ko, this message translates to:
  /// **'예산 · 저축 목표 · 캘린더'**
  String get subFeatBudget;

  /// No description provided for @subFeatSecurities.
  ///
  /// In ko, this message translates to:
  /// **'증권사 연동 · 실시간 시세 · 자산 실시간 금액'**
  String get subFeatSecurities;

  /// No description provided for @subStarted.
  ///
  /// In ko, this message translates to:
  /// **'담다 Pro 구독이 시작됐어요.'**
  String get subStarted;

  /// No description provided for @subFailed.
  ///
  /// In ko, this message translates to:
  /// **'구독을 시작하지 못했어요.'**
  String get subFailed;

  /// No description provided for @subCancelConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'구독 해지'**
  String get subCancelConfirmTitle;

  /// No description provided for @subCancelConfirmMsg.
  ///
  /// In ko, this message translates to:
  /// **'해지하면 {date}부터 Free 플랜으로 전환되고 증권 탭이 잠겨요. 그 전까지는 Pro 기능을 계속 쓸 수 있어요.'**
  String subCancelConfirmMsg(String date);

  /// No description provided for @subCancel.
  ///
  /// In ko, this message translates to:
  /// **'구독 해지'**
  String get subCancel;

  /// No description provided for @subKeep.
  ///
  /// In ko, this message translates to:
  /// **'유지하기'**
  String get subKeep;

  /// No description provided for @subCanceled.
  ///
  /// In ko, this message translates to:
  /// **'구독을 해지했어요.'**
  String get subCanceled;

  /// No description provided for @subCancelFailed.
  ///
  /// In ko, this message translates to:
  /// **'구독을 해지하지 못했어요.'**
  String get subCancelFailed;

  /// No description provided for @subNextBillingDate.
  ///
  /// In ko, this message translates to:
  /// **'다음 결제일'**
  String get subNextBillingDate;

  /// No description provided for @subStartPro.
  ///
  /// In ko, this message translates to:
  /// **'Pro 시작하기'**
  String get subStartPro;

  /// No description provided for @subLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'구독 정보를 불러오지 못했어요'**
  String get subLoadFailed;

  /// No description provided for @subLoadFailedDesc.
  ///
  /// In ko, this message translates to:
  /// **'잠시 뒤 다시 시도해주세요.'**
  String get subLoadFailedDesc;

  /// No description provided for @secLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'증권 정보를 불러오지 못했어요'**
  String get secLoadFailed;

  /// No description provided for @subPricePerMonth.
  ///
  /// In ko, this message translates to:
  /// **'{amount} / 월'**
  String subPricePerMonth(String amount);

  /// No description provided for @subPricePerYear.
  ///
  /// In ko, this message translates to:
  /// **'{amount} / 년'**
  String subPricePerYear(String amount);

  /// No description provided for @subNextBillingNoAmount.
  ///
  /// In ko, this message translates to:
  /// **'다음 결제 {date}'**
  String subNextBillingNoAmount(String date);

  /// No description provided for @subConnected.
  ///
  /// In ko, this message translates to:
  /// **'연결됨'**
  String get subConnected;

  /// No description provided for @subBrokerStatusConnectedAt.
  ///
  /// In ko, this message translates to:
  /// **'연결됨 · {date} 확인'**
  String subBrokerStatusConnectedAt(String date);

  /// No description provided for @subBrokerStatusNone.
  ///
  /// In ko, this message translates to:
  /// **'연결 안 됨'**
  String get subBrokerStatusNone;

  /// No description provided for @subBrokerDisconnectConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'{broker} 연결을 해제할까요?'**
  String subBrokerDisconnectConfirmTitle(String broker);

  /// No description provided for @subBrokerDisconnectConfirmBody.
  ///
  /// In ko, this message translates to:
  /// **'해제하면 이 증권사의 보유 주식과 시세를 더 이상 가져오지 않아요. 다시 연결하려면 키를 새로 입력해야 해요.'**
  String get subBrokerDisconnectConfirmBody;

  /// No description provided for @subConnecting.
  ///
  /// In ko, this message translates to:
  /// **'연결 중…'**
  String get subConnecting;

  /// No description provided for @subConnect.
  ///
  /// In ko, this message translates to:
  /// **'연결하기'**
  String get subConnect;

  /// No description provided for @subBrokerInvalidCred.
  ///
  /// In ko, this message translates to:
  /// **'인증정보가 올바르지 않아요.'**
  String get subBrokerInvalidCred;

  /// No description provided for @subBrokerConnectFailed.
  ///
  /// In ko, this message translates to:
  /// **'증권사를 연결하지 못했어요.'**
  String get subBrokerConnectFailed;

  /// No description provided for @subDisconnectFailed.
  ///
  /// In ko, this message translates to:
  /// **'연결을 해제하지 못했어요.'**
  String get subDisconnectFailed;

  /// No description provided for @memoNew.
  ///
  /// In ko, this message translates to:
  /// **'메모 추가'**
  String get memoNew;

  /// No description provided for @memoEditTitle.
  ///
  /// In ko, this message translates to:
  /// **'메모 수정'**
  String get memoEditTitle;

  /// No description provided for @memoLoadError.
  ///
  /// In ko, this message translates to:
  /// **'메모를 불러오지 못했어요'**
  String get memoLoadError;

  /// No description provided for @memoSectionPinned.
  ///
  /// In ko, this message translates to:
  /// **'고정 · {count}'**
  String memoSectionPinned(int count);

  /// No description provided for @memoSectionAll.
  ///
  /// In ko, this message translates to:
  /// **'모든 메모 · {count}'**
  String memoSectionAll(int count);

  /// No description provided for @memoEmptyDesc.
  ///
  /// In ko, this message translates to:
  /// **'오른쪽 아래 + 버튼으로 첫 메모를 써보세요.'**
  String get memoEmptyDesc;

  /// No description provided for @memoSearchEmptyDesc.
  ///
  /// In ko, this message translates to:
  /// **'다른 검색어를 입력해보세요.'**
  String get memoSearchEmptyDesc;

  /// No description provided for @memoUntitled.
  ///
  /// In ko, this message translates to:
  /// **'제목 없음'**
  String get memoUntitled;

  /// No description provided for @memoDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'메모 삭제'**
  String get memoDeleteTitle;

  /// No description provided for @memoDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'\"{name}\" 메모를 삭제할까요? 삭제한 메모는 되돌릴 수 없어요.'**
  String memoDeleteConfirm(String name);

  /// No description provided for @memoFieldTitle.
  ///
  /// In ko, this message translates to:
  /// **'제목'**
  String get memoFieldTitle;

  /// No description provided for @memoTitleRequired.
  ///
  /// In ko, this message translates to:
  /// **'제목을 입력해주세요.'**
  String get memoTitleRequired;

  /// No description provided for @memoFieldContent.
  ///
  /// In ko, this message translates to:
  /// **'내용'**
  String get memoFieldContent;

  /// No description provided for @memoContentPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'여기에 메모를 작성해주세요'**
  String get memoContentPlaceholder;

  /// No description provided for @memoFieldTag.
  ///
  /// In ko, this message translates to:
  /// **'태그'**
  String get memoFieldTag;

  /// No description provided for @memoTagNone.
  ///
  /// In ko, this message translates to:
  /// **'태그 없음'**
  String get memoTagNone;

  /// No description provided for @memoTagEmptyHint.
  ///
  /// In ko, this message translates to:
  /// **'태그는 설정 › 메모 태그에서 만들어요.'**
  String get memoTagEmptyHint;

  /// No description provided for @memoAllChip.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get memoAllChip;

  /// No description provided for @memoLoadFailedDesc.
  ///
  /// In ko, this message translates to:
  /// **'잠시 뒤 다시 시도해주세요.'**
  String get memoLoadFailedDesc;

  /// No description provided for @memoTagFilter.
  ///
  /// In ko, this message translates to:
  /// **'태그로 거르기'**
  String get memoTagFilter;

  /// No description provided for @memoSaved.
  ///
  /// In ko, this message translates to:
  /// **'저장했어요.'**
  String get memoSaved;

  /// No description provided for @memoSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'저장하지 못했어요. 잠시 뒤 다시 시도해주세요.'**
  String get memoSaveFailed;

  /// No description provided for @memoDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'삭제하지 못했어요. 잠시 뒤 다시 시도해주세요.'**
  String get memoDeleteFailed;

  /// No description provided for @memoPinFailed.
  ///
  /// In ko, this message translates to:
  /// **'고정을 바꾸지 못했어요.'**
  String get memoPinFailed;

  /// No description provided for @memoModifiedAt.
  ///
  /// In ko, this message translates to:
  /// **'{time} 수정'**
  String memoModifiedAt(String time);

  /// No description provided for @memoMoreOf.
  ///
  /// In ko, this message translates to:
  /// **'{name} 더보기'**
  String memoMoreOf(String name);

  /// No description provided for @memoSwipeUnpin.
  ///
  /// In ko, this message translates to:
  /// **'해제'**
  String get memoSwipeUnpin;

  /// No description provided for @mtagSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'저장하지 못했어요. 잠시 뒤 다시 시도해주세요.'**
  String get mtagSaveFailed;

  /// No description provided for @mtagDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'삭제하지 못했어요. 잠시 뒤 다시 시도해주세요.'**
  String get mtagDeleteFailed;

  /// No description provided for @ttagSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'저장하지 못했어요. 잠시 뒤 다시 시도해주세요.'**
  String get ttagSaveFailed;

  /// No description provided for @ttagDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'삭제하지 못했어요. 잠시 뒤 다시 시도해주세요.'**
  String get ttagDeleteFailed;

  /// No description provided for @memoNewTag.
  ///
  /// In ko, this message translates to:
  /// **'태그 추가'**
  String get memoNewTag;

  /// No description provided for @memoTagNamePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'예: 아이디어'**
  String get memoTagNamePlaceholder;

  /// No description provided for @memoDeleteTagTitle.
  ///
  /// In ko, this message translates to:
  /// **'태그 삭제'**
  String get memoDeleteTagTitle;

  /// No description provided for @memoDeleteTagConfirm.
  ///
  /// In ko, this message translates to:
  /// **'\"{name}\" 태그를 삭제하면 이 태그를 쓰는 메모 {count}건은 태그 없음으로 남아요. 삭제한 태그는 되돌릴 수 없어요.'**
  String memoDeleteTagConfirm(String name, int count);

  /// No description provided for @memoTagLoadError.
  ///
  /// In ko, this message translates to:
  /// **'태그를 불러오지 못했어요'**
  String get memoTagLoadError;

  /// No description provided for @mtagTitle.
  ///
  /// In ko, this message translates to:
  /// **'메모 태그'**
  String get mtagTitle;

  /// No description provided for @mtagDesc.
  ///
  /// In ko, this message translates to:
  /// **'메모에 붙이는 태그예요. 메모 화면의 거르기에 쓰여요. 태그를 지우면 그 메모는 \'태그 없음\' 으로 남아요.'**
  String get mtagDesc;

  /// No description provided for @mtagEmpty.
  ///
  /// In ko, this message translates to:
  /// **'태그가 없어요'**
  String get mtagEmpty;

  /// No description provided for @mtagEditTitle.
  ///
  /// In ko, this message translates to:
  /// **'태그 수정'**
  String get mtagEditTitle;

  /// No description provided for @mtagNameLabel.
  ///
  /// In ko, this message translates to:
  /// **'이름'**
  String get mtagNameLabel;

  /// No description provided for @mtagColorLabel.
  ///
  /// In ko, this message translates to:
  /// **'색상'**
  String get mtagColorLabel;

  /// No description provided for @mtagUsage.
  ///
  /// In ko, this message translates to:
  /// **'{count}건에 사용 중'**
  String mtagUsage(int count);

  /// No description provided for @memoPinToTop.
  ///
  /// In ko, this message translates to:
  /// **'상단에 고정'**
  String get memoPinToTop;

  /// No description provided for @memoFieldColor.
  ///
  /// In ko, this message translates to:
  /// **'색상'**
  String get memoFieldColor;

  /// No description provided for @dateToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get dateToday;

  /// No description provided for @dateTomorrow.
  ///
  /// In ko, this message translates to:
  /// **'내일'**
  String get dateTomorrow;

  /// No description provided for @dateYesterday.
  ///
  /// In ko, this message translates to:
  /// **'어제'**
  String get dateYesterday;

  /// No description provided for @dateInDays.
  ///
  /// In ko, this message translates to:
  /// **'{n}일 후'**
  String dateInDays(int n);

  /// No description provided for @dateDaysAgo.
  ///
  /// In ko, this message translates to:
  /// **'{n}일 전'**
  String dateDaysAgo(int n);

  /// No description provided for @dateJustNow.
  ///
  /// In ko, this message translates to:
  /// **'방금 전'**
  String get dateJustNow;

  /// No description provided for @dateMinutesAgo.
  ///
  /// In ko, this message translates to:
  /// **'{n}분 전'**
  String dateMinutesAgo(int n);

  /// No description provided for @dateHoursAgo.
  ///
  /// In ko, this message translates to:
  /// **'{n}시간 전'**
  String dateHoursAgo(int n);

  /// No description provided for @todoNoDue.
  ///
  /// In ko, this message translates to:
  /// **'마감일 없음'**
  String get todoNoDue;

  /// No description provided for @todoGroupLabel.
  ///
  /// In ko, this message translates to:
  /// **'{label} · {count}건'**
  String todoGroupLabel(String label, int count);

  /// No description provided for @dayN.
  ///
  /// In ko, this message translates to:
  /// **'{d}일'**
  String dayN(int d);

  /// No description provided for @weekN.
  ///
  /// In ko, this message translates to:
  /// **'{n}주'**
  String weekN(int n);

  /// No description provided for @countUnit.
  ///
  /// In ko, this message translates to:
  /// **'건'**
  String get countUnit;

  /// No description provided for @dayUnit.
  ///
  /// In ko, this message translates to:
  /// **'일'**
  String get dayUnit;

  /// No description provided for @constHeroTodayTarget.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 목표 별자리'**
  String get constHeroTodayTarget;

  /// No description provided for @constHeroCollectedBang.
  ///
  /// In ko, this message translates to:
  /// **'{name} 수집!'**
  String constHeroCollectedBang(String name);

  /// No description provided for @constHeroStarlightCount.
  ///
  /// In ko, this message translates to:
  /// **'{lit}/{goal} 별빛'**
  String constHeroStarlightCount(int lit, int goal);

  /// No description provided for @constHeroCaptionDone.
  ///
  /// In ko, this message translates to:
  /// **'도감에 새겨졌어요 · 완료할수록 더 반짝여요'**
  String get constHeroCaptionDone;

  /// No description provided for @constHeroCaptionProgress.
  ///
  /// In ko, this message translates to:
  /// **'오늘 {count}건 완료'**
  String constHeroCaptionProgress(int count);

  /// No description provided for @constHeroCaptionMemo.
  ///
  /// In ko, this message translates to:
  /// **'메모 별빛 +{count}'**
  String constHeroCaptionMemo(int count);

  /// No description provided for @constHeroCaptionRemain.
  ///
  /// In ko, this message translates to:
  /// **'{count}별 남음'**
  String constHeroCaptionRemain(int count);

  /// No description provided for @constHeroCaptionEmpty.
  ///
  /// In ko, this message translates to:
  /// **'할 일을 완료하면 별이 켜져요'**
  String get constHeroCaptionEmpty;

  /// No description provided for @constHeroStreak.
  ///
  /// In ko, this message translates to:
  /// **'연속 관측 {count}일'**
  String constHeroStreak(int count);

  /// No description provided for @constHeroGuardInfo.
  ///
  /// In ko, this message translates to:
  /// **'보호 {count} · 중요 +3 · 보통 +2 · 여유 +1'**
  String constHeroGuardInfo(int count);

  /// No description provided for @constMySkyTitle.
  ///
  /// In ko, this message translates to:
  /// **'나의 밤하늘'**
  String get constMySkyTitle;

  /// No description provided for @constMySkyTotal.
  ///
  /// In ko, this message translates to:
  /// **'누적 {count}개'**
  String constMySkyTotal(int count);

  /// No description provided for @constMySkySubtitle.
  ///
  /// In ko, this message translates to:
  /// **'최근 2주 · 흐린 밤도 기록에 남아요'**
  String get constMySkySubtitle;

  /// No description provided for @constCollectionTitle.
  ///
  /// In ko, this message translates to:
  /// **'별자리 도감'**
  String get constCollectionTitle;

  /// No description provided for @constCollectionProgress.
  ///
  /// In ko, this message translates to:
  /// **'{collected}/{total} 수집'**
  String constCollectionProgress(int collected, int total);

  /// No description provided for @constCollectionSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'별 개수만큼 별빛을 모으면 수집돼요'**
  String get constCollectionSubtitle;

  /// No description provided for @constCollectionTodayBadge.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 목표'**
  String get constCollectionTodayBadge;

  /// No description provided for @constCollectionTimes.
  ///
  /// In ko, this message translates to:
  /// **'{count}회'**
  String constCollectionTimes(int count);

  /// No description provided for @constCollectionNotCollected.
  ///
  /// In ko, this message translates to:
  /// **'미수집'**
  String get constCollectionNotCollected;

  /// No description provided for @constDetailNotMet.
  ///
  /// In ko, this message translates to:
  /// **'아직 만나지 못한 별자리예요'**
  String get constDetailNotMet;

  /// No description provided for @todoDetailTitle.
  ///
  /// In ko, this message translates to:
  /// **'할 일 상세'**
  String get todoDetailTitle;

  /// No description provided for @todoDetailStatus.
  ///
  /// In ko, this message translates to:
  /// **'상태'**
  String get todoDetailStatus;

  /// No description provided for @todoStatusPending.
  ///
  /// In ko, this message translates to:
  /// **'대기'**
  String get todoStatusPending;

  /// No description provided for @todoDetailCompletedAt.
  ///
  /// In ko, this message translates to:
  /// **'완료 일시'**
  String get todoDetailCompletedAt;

  /// No description provided for @todoDetailContent.
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get todoDetailContent;

  /// No description provided for @memoDetailNoContent.
  ///
  /// In ko, this message translates to:
  /// **'내용 없음'**
  String get memoDetailNoContent;

  /// No description provided for @calEventDetailTitle.
  ///
  /// In ko, this message translates to:
  /// **'일정 상세'**
  String get calEventDetailTitle;

  /// No description provided for @calDetailNone.
  ///
  /// In ko, this message translates to:
  /// **'없음'**
  String get calDetailNone;

  /// No description provided for @exportTab.
  ///
  /// In ko, this message translates to:
  /// **'내보내기'**
  String get exportTab;

  /// No description provided for @importTab.
  ///
  /// In ko, this message translates to:
  /// **'가져오기'**
  String get importTab;

  /// No description provided for @importSourceTitle.
  ///
  /// In ko, this message translates to:
  /// **'어떤 앱에서 가져오나요?'**
  String get importSourceTitle;

  /// No description provided for @importSourceDesc.
  ///
  /// In ko, this message translates to:
  /// **'기존에 쓰던 가계부를 고르면 열 구조를 자동으로 맞춰요.'**
  String get importSourceDesc;

  /// No description provided for @importSourceGroo.
  ///
  /// In ko, this message translates to:
  /// **'그루 담다'**
  String get importSourceGroo;

  /// No description provided for @importSourceGrooDesc.
  ///
  /// In ko, this message translates to:
  /// **'그루 담다에서 내보낸 파일'**
  String get importSourceGrooDesc;

  /// No description provided for @importSourceEasybudget.
  ///
  /// In ko, this message translates to:
  /// **'편한가계부·머니매니저'**
  String get importSourceEasybudget;

  /// No description provided for @importSourceEasybudgetDesc.
  ///
  /// In ko, this message translates to:
  /// **'Excel 백업'**
  String get importSourceEasybudgetDesc;

  /// No description provided for @importSourceBanksalad.
  ///
  /// In ko, this message translates to:
  /// **'뱅크샐러드'**
  String get importSourceBanksalad;

  /// No description provided for @importSourceBanksaladDesc.
  ///
  /// In ko, this message translates to:
  /// **'가계부 내역'**
  String get importSourceBanksaladDesc;

  /// No description provided for @importSourceToss.
  ///
  /// In ko, this message translates to:
  /// **'토스'**
  String get importSourceToss;

  /// No description provided for @importSourceTossDesc.
  ///
  /// In ko, this message translates to:
  /// **'거래내역'**
  String get importSourceTossDesc;

  /// No description provided for @importSourceCustom.
  ///
  /// In ko, this message translates to:
  /// **'직접 매핑'**
  String get importSourceCustom;

  /// No description provided for @importSourceCustomDesc.
  ///
  /// In ko, this message translates to:
  /// **'CSV · Excel 직접 연결'**
  String get importSourceCustomDesc;

  /// No description provided for @importUploadTitle.
  ///
  /// In ko, this message translates to:
  /// **'파일 업로드'**
  String get importUploadTitle;

  /// No description provided for @importUploadDesc.
  ///
  /// In ko, this message translates to:
  /// **'CSV 또는 Excel(.xlsx, .xls) 파일을 올려주세요. 최대 10MB.'**
  String get importUploadDesc;

  /// No description provided for @importDropTitle.
  ///
  /// In ko, this message translates to:
  /// **'파일 선택'**
  String get importDropTitle;

  /// No description provided for @importDropHint.
  ///
  /// In ko, this message translates to:
  /// **'.csv · .xlsx · .xls 지원'**
  String get importDropHint;

  /// No description provided for @importAnalyzing.
  ///
  /// In ko, this message translates to:
  /// **'파일을 분석하는 중'**
  String get importAnalyzing;

  /// No description provided for @importNotice.
  ///
  /// In ko, this message translates to:
  /// **'가져온 데이터는 기존 거래에 추가되며 덮어쓰지 않아요. 미리보기에서 중복 · 오류를 확인할 수 있어요.'**
  String get importNotice;

  /// No description provided for @importFileTitle.
  ///
  /// In ko, this message translates to:
  /// **'가져올 파일'**
  String get importFileTitle;

  /// No description provided for @importRowsDetected.
  ///
  /// In ko, this message translates to:
  /// **'{total}개 행 · 유효 {valid}건'**
  String importRowsDetected(int total, int valid);

  /// No description provided for @importChange.
  ///
  /// In ko, this message translates to:
  /// **'변경'**
  String get importChange;

  /// No description provided for @importMapTitle.
  ///
  /// In ko, this message translates to:
  /// **'열 매핑'**
  String get importMapTitle;

  /// No description provided for @importMapDesc.
  ///
  /// In ko, this message translates to:
  /// **'파일의 열을 가계부 항목에 연결해요. 자동으로 찾은 값을 확인하고 바꿀 수 있어요.'**
  String get importMapDesc;

  /// No description provided for @importNotMapped.
  ///
  /// In ko, this message translates to:
  /// **'— 가져오지 않음 —'**
  String get importNotMapped;

  /// No description provided for @importFieldSubcategory.
  ///
  /// In ko, this message translates to:
  /// **'소분류'**
  String get importFieldSubcategory;

  /// No description provided for @importFieldTime.
  ///
  /// In ko, this message translates to:
  /// **'시간'**
  String get importFieldTime;

  /// No description provided for @importFieldMerchant.
  ///
  /// In ko, this message translates to:
  /// **'거래처'**
  String get importFieldMerchant;

  /// No description provided for @importFieldPaymentMethod.
  ///
  /// In ko, this message translates to:
  /// **'결제수단'**
  String get importFieldPaymentMethod;

  /// No description provided for @importBlockedTitle.
  ///
  /// In ko, this message translates to:
  /// **'{names} 카테고리에 거래가 직접 등록돼 있어 하위 분류를 만들 수 없어요'**
  String importBlockedTitle(String names);

  /// No description provided for @importBlockedDesc.
  ///
  /// In ko, this message translates to:
  /// **'해당 대분류를 쓰는 행은 저장에 실패해요. 그 카테고리의 거래를 하위로 옮기거나 파일의 분류를 바꿔주세요.'**
  String get importBlockedDesc;

  /// No description provided for @categoryMoveTxAction.
  ///
  /// In ko, this message translates to:
  /// **'옮기기'**
  String get categoryMoveTxAction;

  /// No description provided for @categoryMoveTxTitle.
  ///
  /// In ko, this message translates to:
  /// **'거래 옮기기'**
  String get categoryMoveTxTitle;

  /// No description provided for @categoryMoveTxEntry.
  ///
  /// In ko, this message translates to:
  /// **'거래 옮기기'**
  String get categoryMoveTxEntry;

  /// No description provided for @categoryMoveTxDesc.
  ///
  /// In ko, this message translates to:
  /// **'{name}에 달린 거래 · 반복 거래 · 나눈 거래를 모두 옮겨요.'**
  String categoryMoveTxDesc(String name);

  /// No description provided for @categoryMoveTxModeNew.
  ///
  /// In ko, this message translates to:
  /// **'새 하위 만들기'**
  String get categoryMoveTxModeNew;

  /// No description provided for @categoryMoveTxModeExisting.
  ///
  /// In ko, this message translates to:
  /// **'기존 카테고리로'**
  String get categoryMoveTxModeExisting;

  /// No description provided for @categoryMoveTxMode.
  ///
  /// In ko, this message translates to:
  /// **'옮기는 방법'**
  String get categoryMoveTxMode;

  /// No description provided for @categoryMoveTxChildName.
  ///
  /// In ko, this message translates to:
  /// **'만들 하위 이름'**
  String get categoryMoveTxChildName;

  /// No description provided for @categoryMoveTxChildPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'예: 강의'**
  String get categoryMoveTxChildPlaceholder;

  /// No description provided for @categoryMoveTxNewHint.
  ///
  /// In ko, this message translates to:
  /// **'{name} 아래에 만들고 거래를 모두 그리로 옮겨요. 그러면 다른 하위도 만들 수 있어요.'**
  String categoryMoveTxNewHint(String name);

  /// No description provided for @categoryMoveTxTarget.
  ///
  /// In ko, this message translates to:
  /// **'옮길 카테고리'**
  String get categoryMoveTxTarget;

  /// No description provided for @categoryMoveTxTargetPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 고르기'**
  String get categoryMoveTxTargetPlaceholder;

  /// No description provided for @categoryMoveTxHint.
  ///
  /// In ko, this message translates to:
  /// **'같은 종류의 맨 아래 카테고리만 고를 수 있어요.'**
  String get categoryMoveTxHint;

  /// No description provided for @categoryMoveTxNoTarget.
  ///
  /// In ko, this message translates to:
  /// **'옮길 수 있는 카테고리가 없어요. 먼저 하나 만들어주세요.'**
  String get categoryMoveTxNoTarget;

  /// No description provided for @categoryMoveTxErrChildName.
  ///
  /// In ko, this message translates to:
  /// **'만들 하위 이름을 입력해주세요.'**
  String get categoryMoveTxErrChildName;

  /// No description provided for @categoryMoveTxErrTarget.
  ///
  /// In ko, this message translates to:
  /// **'옮길 카테고리를 골라주세요.'**
  String get categoryMoveTxErrTarget;

  /// No description provided for @categoryMoveTxDone.
  ///
  /// In ko, this message translates to:
  /// **'{count}건을 옮겼어요'**
  String categoryMoveTxDone(int count);

  /// No description provided for @importFieldDate.
  ///
  /// In ko, this message translates to:
  /// **'날짜'**
  String get importFieldDate;

  /// No description provided for @importFieldType.
  ///
  /// In ko, this message translates to:
  /// **'수입 · 지출'**
  String get importFieldType;

  /// No description provided for @importFieldAmount.
  ///
  /// In ko, this message translates to:
  /// **'금액'**
  String get importFieldAmount;

  /// No description provided for @importFieldCategory.
  ///
  /// In ko, this message translates to:
  /// **'카테고리'**
  String get importFieldCategory;

  /// No description provided for @importFieldAsset.
  ///
  /// In ko, this message translates to:
  /// **'자산 · 결제수단'**
  String get importFieldAsset;

  /// No description provided for @importFieldMemo.
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get importFieldMemo;

  /// No description provided for @importPreviewDesc.
  ///
  /// In ko, this message translates to:
  /// **'중복 의심 {dup}건'**
  String importPreviewDesc(int dup);

  /// No description provided for @importIncome.
  ///
  /// In ko, this message translates to:
  /// **'수입'**
  String get importIncome;

  /// No description provided for @importExpense.
  ///
  /// In ko, this message translates to:
  /// **'지출'**
  String get importExpense;

  /// No description provided for @importDupBadge.
  ///
  /// In ko, this message translates to:
  /// **'중복?'**
  String get importDupBadge;

  /// No description provided for @importOptionsTitle.
  ///
  /// In ko, this message translates to:
  /// **'가져오기 옵션'**
  String get importOptionsTitle;

  /// No description provided for @importOptDupSkip.
  ///
  /// In ko, this message translates to:
  /// **'중복 거래 건너뛰기'**
  String get importOptDupSkip;

  /// No description provided for @importOptDupSkipDesc.
  ///
  /// In ko, this message translates to:
  /// **'날짜 · 금액 · 내용이 같은 {dup}건을 제외해요.'**
  String importOptDupSkipDesc(int dup);

  /// No description provided for @importOptAutoCat.
  ///
  /// In ko, this message translates to:
  /// **'새 카테고리 자동 생성'**
  String get importOptAutoCat;

  /// No description provided for @importOptAutoCatDesc.
  ///
  /// In ko, this message translates to:
  /// **'없는 카테고리는 자동으로 만들어요.'**
  String get importOptAutoCatDesc;

  /// No description provided for @importPrev.
  ///
  /// In ko, this message translates to:
  /// **'이전'**
  String get importPrev;

  /// No description provided for @importDoImport.
  ///
  /// In ko, this message translates to:
  /// **'{count}건 가져오기'**
  String importDoImport(int count);

  /// No description provided for @importDoneTitle.
  ///
  /// In ko, this message translates to:
  /// **'가져오기 완료'**
  String get importDoneTitle;

  /// No description provided for @importDoneCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}건을 가져왔어요'**
  String importDoneCount(int count);

  /// No description provided for @importDoneDetail.
  ///
  /// In ko, this message translates to:
  /// **'건너뛴 거래 {skipped}건 · 못 가져온 거래 {failed}건.'**
  String importDoneDetail(int skipped, int failed);

  /// No description provided for @importAnother.
  ///
  /// In ko, this message translates to:
  /// **'다른 파일 가져오기'**
  String get importAnother;

  /// No description provided for @importStepUpload.
  ///
  /// In ko, this message translates to:
  /// **'파일 선택'**
  String get importStepUpload;

  /// No description provided for @importStepMapping.
  ///
  /// In ko, this message translates to:
  /// **'열 매핑'**
  String get importStepMapping;

  /// No description provided for @importStepDone.
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get importStepDone;

  /// No description provided for @exportTabsLabel.
  ///
  /// In ko, this message translates to:
  /// **'데이터 내보내기 · 가져오기'**
  String get exportTabsLabel;

  /// No description provided for @exportSelectAll.
  ///
  /// In ko, this message translates to:
  /// **'모두'**
  String get exportSelectAll;

  /// No description provided for @exportCountsFailed.
  ///
  /// In ko, this message translates to:
  /// **'건수를 불러오지 못했어요.'**
  String get exportCountsFailed;

  /// No description provided for @exportPreviewFailed.
  ///
  /// In ko, this message translates to:
  /// **'미리보기를 불러오지 못했어요.'**
  String get exportPreviewFailed;

  /// No description provided for @exportRangePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'기간 선택'**
  String get exportRangePlaceholder;

  /// No description provided for @exportStalled.
  ///
  /// In ko, this message translates to:
  /// **'파일을 받는 중에 멈췄어요.'**
  String get exportStalled;

  /// No description provided for @exportFailed.
  ///
  /// In ko, this message translates to:
  /// **'내보내지 못했어요.'**
  String get exportFailed;

  /// No description provided for @exportPreviewTabsLabel.
  ///
  /// In ko, this message translates to:
  /// **'미리보기 데이터 종류'**
  String get exportPreviewTabsLabel;

  /// No description provided for @importStepMeta.
  ///
  /// In ko, this message translates to:
  /// **'{current} / {total}단계'**
  String importStepMeta(int current, int total);

  /// No description provided for @importBusy.
  ///
  /// In ko, this message translates to:
  /// **'가져오는 중'**
  String get importBusy;

  /// No description provided for @withdrawPasswordPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'현재 비밀번호를 입력해주세요'**
  String get withdrawPasswordPlaceholder;

  /// No description provided for @withdrawLocked.
  ///
  /// In ko, this message translates to:
  /// **'5번 틀렸어요. 코드를 다시 받아주세요.'**
  String get withdrawLocked;

  /// No description provided for @importStepUploadDesc.
  ///
  /// In ko, this message translates to:
  /// **'가져올 앱과 파일을 골라주세요.'**
  String get importStepUploadDesc;

  /// No description provided for @importStepMappingDesc.
  ///
  /// In ko, this message translates to:
  /// **'열이 맞는지 확인하고 가져올 거래를 점검해주세요.'**
  String get importStepMappingDesc;

  /// No description provided for @withdrawCodeHint.
  ///
  /// In ko, this message translates to:
  /// **'메일함에 코드가 안 보이면 스팸함도 확인해주세요.'**
  String get withdrawCodeHint;

  /// No description provided for @withdrawPasswordWrong.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호가 맞지 않아요. 다시 확인해주세요.'**
  String get withdrawPasswordWrong;

  /// No description provided for @withdrawLoadFailedDescription.
  ///
  /// In ko, this message translates to:
  /// **'잠시 뒤 다시 시도해주세요.'**
  String get withdrawLoadFailedDescription;

  /// No description provided for @exportPreviewFooter.
  ///
  /// In ko, this message translates to:
  /// **'상위 {rows}행 미리보기 · 선택한 {types}종 합계 약 {total}건'**
  String exportPreviewFooter(int rows, int types, int total);

  /// No description provided for @exportPreviewEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'미리볼 데이터가 없어요'**
  String get exportPreviewEmptyTitle;

  /// No description provided for @importCreatedCatTitle.
  ///
  /// In ko, this message translates to:
  /// **'새로 만든 카테고리 {count}개'**
  String importCreatedCatTitle(int count);

  /// No description provided for @importNewCatMore.
  ///
  /// In ko, this message translates to:
  /// **'외 {count}개'**
  String importNewCatMore(int count);

  /// No description provided for @importFailuresTitle.
  ///
  /// In ko, this message translates to:
  /// **'실패한 행 {count}건'**
  String importFailuresTitle(int count);

  /// No description provided for @importFailureLine.
  ///
  /// In ko, this message translates to:
  /// **'{line}행'**
  String importFailureLine(int line);

  /// No description provided for @importFailuresCapped.
  ///
  /// In ko, this message translates to:
  /// **'실패 {total}건 중 앞의 {shown}건만 보여줘요.'**
  String importFailuresCapped(int total, int shown);

  /// No description provided for @importFailReasonDate.
  ///
  /// In ko, this message translates to:
  /// **'날짜를 읽을 수 없어요'**
  String get importFailReasonDate;

  /// No description provided for @importFailReasonAmount.
  ///
  /// In ko, this message translates to:
  /// **'금액을 읽을 수 없어요'**
  String get importFailReasonAmount;

  /// No description provided for @importFailReasonType.
  ///
  /// In ko, this message translates to:
  /// **'수입 · 지출 구분을 읽을 수 없어요'**
  String get importFailReasonType;

  /// No description provided for @importFailReasonParentHasTx.
  ///
  /// In ko, this message translates to:
  /// **'이 카테고리에는 거래가 직접 달려 있어 하위 분류를 만들 수 없어요'**
  String get importFailReasonParentHasTx;

  /// No description provided for @importFailReasonResolve.
  ///
  /// In ko, this message translates to:
  /// **'카테고리나 자산을 찾지 못했어요'**
  String get importFailReasonResolve;

  /// No description provided for @importFailReasonSave.
  ///
  /// In ko, this message translates to:
  /// **'저장하는 중에 오류가 나서 가져오지 못했어요'**
  String get importFailReasonSave;

  /// No description provided for @importFailReasonUnknown.
  ///
  /// In ko, this message translates to:
  /// **'알 수 없는 이유로 가져오지 못했어요'**
  String get importFailReasonUnknown;

  /// No description provided for @importFileTooLarge.
  ///
  /// In ko, this message translates to:
  /// **'파일은 10MB까지 올릴 수 있어요.'**
  String get importFileTooLarge;

  /// No description provided for @importFileInvalid.
  ///
  /// In ko, this message translates to:
  /// **'CSV 또는 Excel 파일만 올릴 수 있어요.'**
  String get importFileInvalid;

  /// No description provided for @importBadgeError.
  ///
  /// In ko, this message translates to:
  /// **'오류'**
  String get importBadgeError;

  /// No description provided for @importBadgeDup.
  ///
  /// In ko, this message translates to:
  /// **'중복'**
  String get importBadgeDup;

  /// No description provided for @importGoExpense.
  ///
  /// In ko, this message translates to:
  /// **'가계부로 가기'**
  String get importGoExpense;

  /// No description provided for @calDetailDday.
  ///
  /// In ko, this message translates to:
  /// **'D-DAY'**
  String get calDetailDday;

  /// No description provided for @calDetailDdayLeft.
  ///
  /// In ko, this message translates to:
  /// **'D-{n}'**
  String calDetailDdayLeft(int n);

  /// No description provided for @calDetailDdayPast.
  ///
  /// In ko, this message translates to:
  /// **'{n}일 지남'**
  String calDetailDdayPast(int n);

  /// No description provided for @calDetailDurationH.
  ///
  /// In ko, this message translates to:
  /// **'{h}시간'**
  String calDetailDurationH(int h);

  /// No description provided for @calDetailDurationHM.
  ///
  /// In ko, this message translates to:
  /// **'{h}시간 {m}분'**
  String calDetailDurationHM(int h, int m);

  /// No description provided for @calDetailDurationM.
  ///
  /// In ko, this message translates to:
  /// **'{m}분'**
  String calDetailDurationM(int m);

  /// No description provided for @categoryReorderEdit.
  ///
  /// In ko, this message translates to:
  /// **'순서 바꾸기'**
  String get categoryReorderEdit;

  /// No description provided for @categoryReorderHint.
  ///
  /// In ko, this message translates to:
  /// **'손잡이를 끌어 순서를 바꿔요. 상위는 상위끼리, 하위는 같은 상위 안에서 옮겨요.'**
  String get categoryReorderHint;

  /// No description provided for @txmSpendSummary.
  ///
  /// In ko, this message translates to:
  /// **'소비 요약'**
  String get txmSpendSummary;

  /// No description provided for @txmInsightLessPre.
  ///
  /// In ko, this message translates to:
  /// **'지난달보다 '**
  String get txmInsightLessPre;

  /// No description provided for @txmInsightLessHl.
  ///
  /// In ko, this message translates to:
  /// **'{amount} 덜'**
  String txmInsightLessHl(String amount);

  /// No description provided for @txmInsightLessPost.
  ///
  /// In ko, this message translates to:
  /// **' 쓰는 중'**
  String get txmInsightLessPost;

  /// No description provided for @txmInsightMorePre.
  ///
  /// In ko, this message translates to:
  /// **'지난달보다 '**
  String get txmInsightMorePre;

  /// No description provided for @txmInsightMoreHl.
  ///
  /// In ko, this message translates to:
  /// **'{amount} 더'**
  String txmInsightMoreHl(String amount);

  /// No description provided for @txmInsightMorePost.
  ///
  /// In ko, this message translates to:
  /// **' 쓰는 중'**
  String get txmInsightMorePost;

  /// No description provided for @txmInsightSame.
  ///
  /// In ko, this message translates to:
  /// **'지난달과 비슷하게 쓰고 있어요'**
  String get txmInsightSame;

  /// No description provided for @txmInsightNone.
  ///
  /// In ko, this message translates to:
  /// **'이 달에는 거래 내역이 없어요'**
  String get txmInsightNone;

  /// No description provided for @txmInsightTopCatPre.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 '**
  String get txmInsightTopCatPre;

  /// No description provided for @txmInsightTopCatPost.
  ///
  /// In ko, this message translates to:
  /// **'에 가장 많이 썼어요'**
  String get txmInsightTopCatPost;

  /// No description provided for @txmPrevMonthBtn.
  ///
  /// In ko, this message translates to:
  /// **'{month} 이용 내역 보기'**
  String txmPrevMonthBtn(String month);

  /// No description provided for @txmEmptyMonth.
  ///
  /// In ko, this message translates to:
  /// **'{month} 거래가 없어요'**
  String txmEmptyMonth(String month);

  /// No description provided for @txmEmptyMonthDesc.
  ///
  /// In ko, this message translates to:
  /// **'다른 달을 살펴보거나 첫 거래를 추가해보세요.'**
  String get txmEmptyMonthDesc;

  /// No description provided for @txmToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get txmToday;

  /// No description provided for @txmYesterday.
  ///
  /// In ko, this message translates to:
  /// **'어제'**
  String get txmYesterday;

  /// No description provided for @expChipMin.
  ///
  /// In ko, this message translates to:
  /// **'{amount} 이상'**
  String expChipMin(String amount);

  /// No description provided for @expChipMax.
  ///
  /// In ko, this message translates to:
  /// **'{amount} 이하'**
  String expChipMax(String amount);

  /// No description provided for @tdmTodayLeft.
  ///
  /// In ko, this message translates to:
  /// **'오늘 할 일 {count}개'**
  String tdmTodayLeft(int count);

  /// No description provided for @tdmTodayDone.
  ///
  /// In ko, this message translates to:
  /// **'오늘 할 일 끝!'**
  String get tdmTodayDone;

  /// No description provided for @tdmNightSkyBtn.
  ///
  /// In ko, this message translates to:
  /// **'밤하늘'**
  String get tdmNightSkyBtn;

  /// No description provided for @tdmStarlightHint.
  ///
  /// In ko, this message translates to:
  /// **'별빛 {lit}/{goal} · {left}개 더 모으면 {name} 수집'**
  String tdmStarlightHint(int lit, int goal, int left, String name);

  /// No description provided for @tdmCollectedHint.
  ///
  /// In ko, this message translates to:
  /// **'{name} 수집 완료 · 연속 {streak}일'**
  String tdmCollectedHint(String name, int streak);

  /// No description provided for @tdmDoneRatio.
  ///
  /// In ko, this message translates to:
  /// **'{done}/{total} 완료'**
  String tdmDoneRatio(int done, int total);

  /// No description provided for @tdmFilterTag.
  ///
  /// In ko, this message translates to:
  /// **'태그'**
  String get tdmFilterTag;

  /// No description provided for @tdmHideDone.
  ///
  /// In ko, this message translates to:
  /// **'완료한 할 일 숨기기'**
  String get tdmHideDone;

  /// No description provided for @tdmEmptyMonth.
  ///
  /// In ko, this message translates to:
  /// **'{month} 할 일이 없어요'**
  String tdmEmptyMonth(String month);

  /// No description provided for @tdmEmptyMonthDesc.
  ///
  /// In ko, this message translates to:
  /// **'오른쪽 아래 + 버튼으로 추가해보세요.'**
  String get tdmEmptyMonthDesc;

  /// No description provided for @tdmEmptyFilter.
  ///
  /// In ko, this message translates to:
  /// **'조건에 맞는 할 일이 없어요'**
  String get tdmEmptyFilter;

  /// No description provided for @tdmEmptyFilterDesc.
  ///
  /// In ko, this message translates to:
  /// **'조건을 바꾸거나 지워보세요.'**
  String get tdmEmptyFilterDesc;

  /// No description provided for @tdmStarToastGain.
  ///
  /// In ko, this message translates to:
  /// **'별빛 +{gain} · 수집까지 {left}별'**
  String tdmStarToastGain(int gain, int left);

  /// No description provided for @tdmStarToastCollected.
  ///
  /// In ko, this message translates to:
  /// **'별빛 +{gain} · 오늘의 별자리 수집!'**
  String tdmStarToastCollected(int gain);

  /// No description provided for @constHeroLabel.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 목표 별자리 {name} {lit}/{goal} 별빛'**
  String constHeroLabel(String name, int lit, int goal);

  /// No description provided for @constFailToday.
  ///
  /// In ko, this message translates to:
  /// **'밤하늘을 불러오지 못했어요'**
  String get constFailToday;

  /// No description provided for @constFailSky.
  ///
  /// In ko, this message translates to:
  /// **'나의 밤하늘을 불러오지 못했어요'**
  String get constFailSky;

  /// No description provided for @constFailCollection.
  ///
  /// In ko, this message translates to:
  /// **'별자리 도감을 불러오지 못했어요'**
  String get constFailCollection;

  /// No description provided for @constLoadFailedDesc.
  ///
  /// In ko, this message translates to:
  /// **'잠시 뒤 다시 시도해주세요.'**
  String get constLoadFailedDesc;

  /// No description provided for @frpLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'관측 리포트를 불러오지 못했어요'**
  String get frpLoadFailed;

  /// No description provided for @frpRowName.
  ///
  /// In ko, this message translates to:
  /// **'관측 리포트, 오늘의 목표 {name}'**
  String frpRowName(String name);

  /// No description provided for @constMySkyCellToday.
  ///
  /// In ko, this message translates to:
  /// **'{date}, 오늘'**
  String constMySkyCellToday(String date);

  /// No description provided for @constMySkyCellCollected.
  ///
  /// In ko, this message translates to:
  /// **'{date}, 수집 {name}'**
  String constMySkyCellCollected(String date, String name);

  /// No description provided for @constMySkyCellCloudy.
  ///
  /// In ko, this message translates to:
  /// **'{date}, 흐린 밤'**
  String constMySkyCellCloudy(String date);

  /// No description provided for @constMySkyCellRest.
  ///
  /// In ko, this message translates to:
  /// **'{date}, 쉰 밤'**
  String constMySkyCellRest(String date);

  /// No description provided for @constCollectionBadgeNew.
  ///
  /// In ko, this message translates to:
  /// **'NEW'**
  String get constCollectionBadgeNew;

  /// No description provided for @constCollectionViewOwnedNamed.
  ///
  /// In ko, this message translates to:
  /// **'{name} 감상하기'**
  String constCollectionViewOwnedNamed(String name);

  /// No description provided for @constCollectionViewLockedNamed.
  ///
  /// In ko, this message translates to:
  /// **'{name} 미리보기'**
  String constCollectionViewLockedNamed(String name);

  /// No description provided for @constDetailSkyName.
  ///
  /// In ko, this message translates to:
  /// **'{name} 별자리 그림'**
  String constDetailSkyName(String name);

  /// No description provided for @constDetailStarCountLabel.
  ///
  /// In ko, this message translates to:
  /// **'별 개수'**
  String get constDetailStarCountLabel;

  /// No description provided for @constDetailStarCountValue.
  ///
  /// In ko, this message translates to:
  /// **'{count}개'**
  String constDetailStarCountValue(int count);

  /// No description provided for @constDetailCollectLabel.
  ///
  /// In ko, this message translates to:
  /// **'수집'**
  String get constDetailCollectLabel;

  /// No description provided for @constDetailCollectValue.
  ///
  /// In ko, this message translates to:
  /// **'{count}번'**
  String constDetailCollectValue(int count);

  /// No description provided for @frpPrevWeek.
  ///
  /// In ko, this message translates to:
  /// **'이전 주'**
  String get frpPrevWeek;

  /// No description provided for @frpNextWeek.
  ///
  /// In ko, this message translates to:
  /// **'다음 주'**
  String get frpNextWeek;

  /// No description provided for @frpObsWitheredGuard.
  ///
  /// In ko, this message translates to:
  /// **'흐린 밤 · 구름 보호로 스트릭 유지'**
  String get frpObsWitheredGuard;

  /// No description provided for @frpPctBang.
  ///
  /// In ko, this message translates to:
  /// **'{pct}% 달성!'**
  String frpPctBang(int pct);

  /// No description provided for @frpMissedWeight.
  ///
  /// In ko, this message translates to:
  /// **'별빛 +{count}'**
  String frpMissedWeight(int count);

  /// No description provided for @frpLegendMemo.
  ///
  /// In ko, this message translates to:
  /// **'메모 별빛'**
  String get frpLegendMemo;

  /// No description provided for @frpBarsName.
  ///
  /// In ko, this message translates to:
  /// **'요일별 별빛'**
  String get frpBarsName;

  /// No description provided for @frpStampName.
  ///
  /// In ko, this message translates to:
  /// **'{count}일째 연속 관측'**
  String frpStampName(int count);

  /// No description provided for @constDetailTodayDesc.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 목표 별자리'**
  String get constDetailTodayDesc;

  /// No description provided for @constDetailTodayProgress.
  ///
  /// In ko, this message translates to:
  /// **'오늘 모은 별빛'**
  String get constDetailTodayProgress;

  /// No description provided for @constDetailTodayPct.
  ///
  /// In ko, this message translates to:
  /// **'{pct}%'**
  String constDetailTodayPct(int pct);

  /// No description provided for @constDetailTodayRemain.
  ///
  /// In ko, this message translates to:
  /// **'{lit}/{goal} 별빛 · {count}별 남음'**
  String constDetailTodayRemain(int lit, int goal, int count);

  /// No description provided for @constDetailTodayAll.
  ///
  /// In ko, this message translates to:
  /// **'{lit}/{goal} 별빛'**
  String constDetailTodayAll(int lit, int goal);

  /// No description provided for @nightSkyTitle.
  ///
  /// In ko, this message translates to:
  /// **'밤하늘'**
  String get nightSkyTitle;

  /// No description provided for @forestReportTitle.
  ///
  /// In ko, this message translates to:
  /// **'관측 리포트'**
  String get forestReportTitle;

  /// No description provided for @fcolViewCta.
  ///
  /// In ko, this message translates to:
  /// **'감상하기'**
  String get fcolViewCta;

  /// No description provided for @fcolPreviewCta.
  ///
  /// In ko, this message translates to:
  /// **'미리보기'**
  String get fcolPreviewCta;

  /// No description provided for @fcolLockedHint.
  ///
  /// In ko, this message translates to:
  /// **'별빛 {count}개를 하룻밤에 모으면 만날 수 있어요.'**
  String fcolLockedHint(int count);

  /// No description provided for @frpObsResult.
  ///
  /// In ko, this message translates to:
  /// **'관측 결과'**
  String get frpObsResult;

  /// No description provided for @frpObsToday.
  ///
  /// In ko, this message translates to:
  /// **'{name} {lit}/{goal} 진행 중'**
  String frpObsToday(String name, int lit, int goal);

  /// No description provided for @frpObsCollected.
  ///
  /// In ko, this message translates to:
  /// **'{name} 수집!'**
  String frpObsCollected(String name);

  /// No description provided for @frpObsWithered.
  ///
  /// In ko, this message translates to:
  /// **'흐린 밤'**
  String get frpObsWithered;

  /// No description provided for @frpObsRest.
  ///
  /// In ko, this message translates to:
  /// **'쉬어간 밤'**
  String get frpObsRest;

  /// No description provided for @frpStampDays.
  ///
  /// In ko, this message translates to:
  /// **'{count}일째'**
  String frpStampDays(int count);

  /// No description provided for @frpStampLabel.
  ///
  /// In ko, this message translates to:
  /// **'연속 관측!'**
  String get frpStampLabel;

  /// No description provided for @frpStarGather.
  ///
  /// In ko, this message translates to:
  /// **'별빛 모으기'**
  String get frpStarGather;

  /// No description provided for @frpPctBadge.
  ///
  /// In ko, this message translates to:
  /// **'{pct}% 달성'**
  String frpPctBadge(int pct);

  /// No description provided for @frpTileStar.
  ///
  /// In ko, this message translates to:
  /// **'모은 별빛'**
  String get frpTileStar;

  /// No description provided for @frpTileStarVal.
  ///
  /// In ko, this message translates to:
  /// **'{count}개'**
  String frpTileStarVal(int count);

  /// No description provided for @frpTileDone.
  ///
  /// In ko, this message translates to:
  /// **'완료한 할 일'**
  String get frpTileDone;

  /// No description provided for @frpTileDoneVal.
  ///
  /// In ko, this message translates to:
  /// **'{count}건'**
  String frpTileDoneVal(int count);

  /// No description provided for @frpAnalysis.
  ///
  /// In ko, this message translates to:
  /// **'별빛 분석'**
  String get frpAnalysis;

  /// No description provided for @frpLegendItem.
  ///
  /// In ko, this message translates to:
  /// **'{label} 완료 {count}'**
  String frpLegendItem(String label, int count);

  /// No description provided for @frpMissed.
  ///
  /// In ko, this message translates to:
  /// **'못다 켠 별'**
  String get frpMissed;

  /// No description provided for @frpMissedAllDone.
  ///
  /// In ko, this message translates to:
  /// **'오늘 하늘의 별을 모두 켰어요. 남은 별빛은 내일 밤으로!'**
  String get frpMissedAllDone;

  /// No description provided for @frpMissedCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}개'**
  String frpMissedCount(int count);

  /// No description provided for @frpAsOf.
  ///
  /// In ko, this message translates to:
  /// **'{ts} 기준'**
  String frpAsOf(String ts);

  /// No description provided for @settingsMenuTodoTag.
  ///
  /// In ko, this message translates to:
  /// **'할 일 태그'**
  String get settingsMenuTodoTag;

  /// No description provided for @settingsMenuMemoTag.
  ///
  /// In ko, this message translates to:
  /// **'메모 태그'**
  String get settingsMenuMemoTag;

  /// No description provided for @ttagUsage.
  ///
  /// In ko, this message translates to:
  /// **'{count}건에 사용 중'**
  String ttagUsage(int count);

  /// No description provided for @calLabelUsage.
  ///
  /// In ko, this message translates to:
  /// **'{count}건에 사용 중'**
  String calLabelUsage(Object count);

  /// No description provided for @ttagEditTitle.
  ///
  /// In ko, this message translates to:
  /// **'태그 수정'**
  String get ttagEditTitle;

  /// No description provided for @ttagTitle.
  ///
  /// In ko, this message translates to:
  /// **'할 일 태그'**
  String get ttagTitle;

  /// No description provided for @ttagDesc.
  ///
  /// In ko, this message translates to:
  /// **'할 일에 붙이는 태그예요. 할 일 화면의 거르기와 태그별 개수에 쓰여요. 태그를 지우면 그 할 일은 \'태그 없음\'으로 남아요.'**
  String get ttagDesc;

  /// No description provided for @ttagAddCta.
  ///
  /// In ko, this message translates to:
  /// **'태그 추가'**
  String get ttagAddCta;

  /// No description provided for @ttagColorLabel.
  ///
  /// In ko, this message translates to:
  /// **'색상'**
  String get ttagColorLabel;

  /// No description provided for @ttagNameLabel.
  ///
  /// In ko, this message translates to:
  /// **'이름'**
  String get ttagNameLabel;

  /// No description provided for @ttagEmpty.
  ///
  /// In ko, this message translates to:
  /// **'태그가 없어요'**
  String get ttagEmpty;

  /// No description provided for @ttagDeleteDesc.
  ///
  /// In ko, this message translates to:
  /// **'이 태그를 쓰는 할 일 {count}건은 태그 없음으로 남아요.'**
  String ttagDeleteDesc(int count);

  /// No description provided for @iconPickerTitle.
  ///
  /// In ko, this message translates to:
  /// **'아이콘 선택'**
  String get iconPickerTitle;

  /// No description provided for @iconPickerSearchHint.
  ///
  /// In ko, this message translates to:
  /// **'아이콘 검색...'**
  String get iconPickerSearchHint;

  /// No description provided for @iconPickerNone.
  ///
  /// In ko, this message translates to:
  /// **'없음'**
  String get iconPickerNone;

  /// No description provided for @iconPickerNoResults.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과가 없습니다'**
  String get iconPickerNoResults;

  /// No description provided for @iconPickerResultCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 결과'**
  String iconPickerResultCount(int count);

  /// No description provided for @iconPickerTotalHint.
  ///
  /// In ko, this message translates to:
  /// **'전체 {count}개 · 스크롤해서 더 보기'**
  String iconPickerTotalHint(int count);

  /// No description provided for @smsPasteTitle.
  ///
  /// In ko, this message translates to:
  /// **'결제 문자로 기록'**
  String get smsPasteTitle;

  /// No description provided for @smsPasteDesc.
  ///
  /// In ko, this message translates to:
  /// **'카드사에서 온 결제 문자를 붙여넣으면 금액·가맹점·일시를 읽어 지출 폼을 채워드려요. 저장 전에 확인할 수 있어요.'**
  String get smsPasteDesc;

  /// No description provided for @smsPasteFieldLabel.
  ///
  /// In ko, this message translates to:
  /// **'결제 문자'**
  String get smsPasteFieldLabel;

  /// No description provided for @smsPastePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'[Web발신]\n숲빛카드 5,500원\n골목찻집'**
  String get smsPastePlaceholder;

  /// No description provided for @smsPasteAction.
  ///
  /// In ko, this message translates to:
  /// **'문자 읽기'**
  String get smsPasteAction;

  /// No description provided for @smsPasteFromClipboard.
  ///
  /// In ko, this message translates to:
  /// **'클립보드에서 붙여넣기'**
  String get smsPasteFromClipboard;

  /// No description provided for @smsClipboardEmpty.
  ///
  /// In ko, this message translates to:
  /// **'클립보드에 텍스트가 없어요.'**
  String get smsClipboardEmpty;

  /// No description provided for @smsParseFailed.
  ///
  /// In ko, this message translates to:
  /// **'문자를 읽지 못했어요. 잠시 뒤 다시 시도해주세요.'**
  String get smsParseFailed;

  /// No description provided for @smsNotRecognized.
  ///
  /// In ko, this message translates to:
  /// **'결제 문자로 보이지 않아요. 문자 전체를 붙여넣었는지 확인해주세요.'**
  String get smsNotRecognized;

  /// No description provided for @smsCancelNotice.
  ///
  /// In ko, this message translates to:
  /// **'취소 문자예요. 자동 기록은 지원하지 않아요 — 원래 지출을 찾아 환불로 기록해주세요.'**
  String get smsCancelNotice;

  /// No description provided for @smsLowConfidence.
  ///
  /// In ko, this message translates to:
  /// **'일부 항목을 읽지 못했어요. 확인하고 채워주세요.'**
  String get smsLowConfidence;

  /// No description provided for @smsRememberCard.
  ///
  /// In ko, this message translates to:
  /// **'이 카드를 기억해서 다음부터 자동으로 연결하기'**
  String get smsRememberCard;

  /// No description provided for @moreItemSmsPaste.
  ///
  /// In ko, this message translates to:
  /// **'결제 문자로 기록'**
  String get moreItemSmsPaste;

  /// No description provided for @moreDescSmsPaste.
  ///
  /// In ko, this message translates to:
  /// **'카드 결제 문자를 붙여넣어 지출 추가'**
  String get moreDescSmsPaste;

  /// No description provided for @smsClipboardBannerTitle.
  ///
  /// In ko, this message translates to:
  /// **'복사한 결제 문자가 있어요'**
  String get smsClipboardBannerTitle;

  /// No description provided for @smsClipboardBannerDesc.
  ///
  /// In ko, this message translates to:
  /// **'붙여넣어 지출로 기록할 수 있어요.'**
  String get smsClipboardBannerDesc;

  /// No description provided for @smsInboxTitle.
  ///
  /// In ko, this message translates to:
  /// **'결제 알림 수신함'**
  String get smsInboxTitle;

  /// No description provided for @smsInboxClear.
  ///
  /// In ko, this message translates to:
  /// **'비우기'**
  String get smsInboxClear;

  /// No description provided for @smsInboxEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 받은 결제 알림이 없어요'**
  String get smsInboxEmpty;

  /// No description provided for @smsInboxEmptyDesc.
  ///
  /// In ko, this message translates to:
  /// **'카드 결제가 감지되면 여기에 쌓여요. 눌러서 지출로 기록할 수 있어요.'**
  String get smsInboxEmptyDesc;

  /// No description provided for @smsInboxRemoveTitle.
  ///
  /// In ko, this message translates to:
  /// **'문자를 삭제할까요?'**
  String get smsInboxRemoveTitle;

  /// No description provided for @smsInboxRemoveConfirm.
  ///
  /// In ko, this message translates to:
  /// **'{target} 문자를 목록에서 삭제해요. 기록으로 남기지 않아요.'**
  String smsInboxRemoveConfirm(String target);

  /// No description provided for @smsInboxRemoveLabel.
  ///
  /// In ko, this message translates to:
  /// **'{name} 삭제'**
  String smsInboxRemoveLabel(String name);

  /// No description provided for @smsInboxClearTitle.
  ///
  /// In ko, this message translates to:
  /// **'문자를 모두 삭제할까요?'**
  String get smsInboxClearTitle;

  /// No description provided for @smsInboxClearConfirm.
  ///
  /// In ko, this message translates to:
  /// **'수신함의 문자 {count}건을 모두 삭제해요. 기록으로 남기지 않아요.'**
  String smsInboxClearConfirm(int count);

  /// No description provided for @smsPermissionOffTitle.
  ///
  /// In ko, this message translates to:
  /// **'결제를 감지해도 알려드릴 수 없어요'**
  String get smsPermissionOffTitle;

  /// No description provided for @smsPermissionOffDesc.
  ///
  /// In ko, this message translates to:
  /// **'알림 권한을 켜면 결제가 잡힐 때 바로 알려드려요. 꺼둬도 감지는 계속되고 수신함에 쌓여요.'**
  String get smsPermissionOffDesc;

  /// No description provided for @moreItemSmsInbox.
  ///
  /// In ko, this message translates to:
  /// **'결제 알림 수신함'**
  String get moreItemSmsInbox;

  /// No description provided for @moreDescSmsInbox.
  ///
  /// In ko, this message translates to:
  /// **'감지된 카드 결제를 지출로 기록'**
  String get moreDescSmsInbox;

  /// No description provided for @smsNotiAccessOffTitle.
  ///
  /// In ko, this message translates to:
  /// **'결제 감지가 꺼져 있어요'**
  String get smsNotiAccessOffTitle;

  /// No description provided for @smsNotiAccessOffDesc.
  ///
  /// In ko, this message translates to:
  /// **'알림 접근을 켜면 카드사·은행 앱 알림과 결제 문자를 읽어 기록할 수 있어요. 읽는 건 결제 알림뿐이고 나머지는 곧바로 버려요.'**
  String get smsNotiAccessOffDesc;

  /// No description provided for @updateAutoBlockerTitle.
  ///
  /// In ko, this message translates to:
  /// **'삼성 자동 차단을 꺼야 설치돼요'**
  String get updateAutoBlockerTitle;

  /// No description provided for @updateAutoBlockerDesc.
  ///
  /// In ko, this message translates to:
  /// **'갤럭시는 스토어 밖에서 받은 앱의 설치를 기본으로 막아요. 이 앱이 위험해서가 아니라 설치 경로를 통째로 막는 기능이라, 꺼두지 않으면 받아도 설치가 되지 않아요.'**
  String get updateAutoBlockerDesc;

  /// No description provided for @updateAutoBlockerPath.
  ///
  /// In ko, this message translates to:
  /// **'설정 > 보안 및 개인정보 보호 > 자동 차단에서 꺼주세요. 설치가 끝나면 다시 켜도 괜찮아요.'**
  String get updateAutoBlockerPath;

  /// No description provided for @updateAutoBlockerAfterDirect.
  ///
  /// In ko, this message translates to:
  /// **'자동 차단을 끄고 돌아와서 받기를 눌러주세요. 설치가 끝나면 다시 켜도 괜찮아요.'**
  String get updateAutoBlockerAfterDirect;

  /// No description provided for @updateAutoBlockerAfterSecurity.
  ///
  /// In ko, this message translates to:
  /// **'목록에서 자동 차단을 찾아 꺼주세요. 설치가 끝나면 다시 켜도 괜찮아요.'**
  String get updateAutoBlockerAfterSecurity;

  /// No description provided for @updateAutoBlockerOpen.
  ///
  /// In ko, this message translates to:
  /// **'설정 열기'**
  String get updateAutoBlockerOpen;

  /// No description provided for @settingsSecuritiesLink.
  ///
  /// In ko, this message translates to:
  /// **'증권사 연동'**
  String get settingsSecuritiesLink;

  /// No description provided for @settingsSecuritiesLinkDesc.
  ///
  /// In ko, this message translates to:
  /// **'본인 API 키를 등록하면 보유 주식·시세를 자동으로 가져와요. 키는 서버에 암호화되어 저장되고 본인만 사용해요.'**
  String get settingsSecuritiesLinkDesc;

  /// No description provided for @securitiesLoadError.
  ///
  /// In ko, this message translates to:
  /// **'증권사 목록을 불러오지 못했어요'**
  String get securitiesLoadError;

  /// No description provided for @subBrokerSectionTitle.
  ///
  /// In ko, this message translates to:
  /// **'증권 데이터 연동'**
  String get subBrokerSectionTitle;

  /// No description provided for @subBrokerPrimary.
  ///
  /// In ko, this message translates to:
  /// **'기본'**
  String get subBrokerPrimary;

  /// No description provided for @subBrokerUseAsPrimary.
  ///
  /// In ko, this message translates to:
  /// **'기본으로 쓰기'**
  String get subBrokerUseAsPrimary;

  /// No description provided for @subBrokerPrimaryNotice.
  ///
  /// In ko, this message translates to:
  /// **'가계부 자산은 여기서 고른 증권사 시세로 계산해요.'**
  String get subBrokerPrimaryNotice;

  /// No description provided for @subBrokerPrimaryFailed.
  ///
  /// In ko, this message translates to:
  /// **'기본 증권사를 바꾸지 못했어요.'**
  String get subBrokerPrimaryFailed;

  /// No description provided for @subBrokerConnected.
  ///
  /// In ko, this message translates to:
  /// **'{broker} 연결을 마쳤어요.'**
  String subBrokerConnected(String broker);

  /// No description provided for @subBrokerDisconnected.
  ///
  /// In ko, this message translates to:
  /// **'연결을 해제했어요.'**
  String get subBrokerDisconnected;

  /// No description provided for @subBrokerPrimaryChanged.
  ///
  /// In ko, this message translates to:
  /// **'이제 {broker} 시세로 자산을 평가해요.'**
  String subBrokerPrimaryChanged(String broker);

  /// No description provided for @subBrokerKeyNotice.
  ///
  /// In ko, this message translates to:
  /// **'키는 서버에 암호화되어 저장되며 본인만 사용합니다. 발급은 {broker} 개발자센터에서.'**
  String subBrokerKeyNotice(String broker);

  /// No description provided for @subBrokerToggleReveal.
  ///
  /// In ko, this message translates to:
  /// **'{field} 보기'**
  String subBrokerToggleReveal(String field);

  /// No description provided for @brokerToss.
  ///
  /// In ko, this message translates to:
  /// **'토스증권'**
  String get brokerToss;

  /// No description provided for @brokerNamu.
  ///
  /// In ko, this message translates to:
  /// **'나무증권'**
  String get brokerNamu;

  /// No description provided for @stocksBrokerUnsupported.
  ///
  /// In ko, this message translates to:
  /// **'앱이 아직 모르는 증권사예요. 앱을 업데이트하면 볼 수 있어요.'**
  String get stocksBrokerUnsupported;

  /// No description provided for @namuPriceEmpty.
  ///
  /// In ko, this message translates to:
  /// **'현재가가 없는 종목이에요'**
  String get namuPriceEmpty;

  /// No description provided for @namuTabDomestic.
  ///
  /// In ko, this message translates to:
  /// **'국내'**
  String get namuTabDomestic;

  /// No description provided for @namuTabOverseas.
  ///
  /// In ko, this message translates to:
  /// **'해외'**
  String get namuTabOverseas;

  /// No description provided for @namuHoldingsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'보유 중인 종목이 없어요'**
  String get namuHoldingsEmpty;

  /// No description provided for @expFilterMatch.
  ///
  /// In ko, this message translates to:
  /// **'조건 맞추기'**
  String get expFilterMatch;

  /// No description provided for @expFilterMatchAll.
  ///
  /// In ko, this message translates to:
  /// **'모두 일치'**
  String get expFilterMatchAll;

  /// No description provided for @expFilterMatchAny.
  ///
  /// In ko, this message translates to:
  /// **'하나라도 일치'**
  String get expFilterMatchAny;

  /// No description provided for @expFilterMatchHint.
  ///
  /// In ko, this message translates to:
  /// **'조건이 두 개 이상일 때 고를 수 있어요.'**
  String get expFilterMatchHint;

  /// No description provided for @expFilterAddPeriod.
  ///
  /// In ko, this message translates to:
  /// **'기간 추가'**
  String get expFilterAddPeriod;

  /// No description provided for @expFilterAddAmountRange.
  ///
  /// In ko, this message translates to:
  /// **'구간 추가'**
  String get expFilterAddAmountRange;

  /// No description provided for @expFilterPeriodAlwaysAnd.
  ///
  /// In ko, this message translates to:
  /// **'기간은 항상 함께 적용돼요.'**
  String get expFilterPeriodAlwaysAnd;

  /// No description provided for @expFilterRemoveRow.
  ///
  /// In ko, this message translates to:
  /// **'이 줄 지우기'**
  String get expFilterRemoveRow;

  /// No description provided for @expFilterExcluded.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 빼고'**
  String expFilterExcluded(int count);

  /// No description provided for @expRecordOnlyBadge.
  ///
  /// In ko, this message translates to:
  /// **'기록만'**
  String get expRecordOnlyBadge;

  /// No description provided for @expRecordOnlyNote.
  ///
  /// In ko, this message translates to:
  /// **'결제가 끝난 회차에 적은 거래라 기록만 남았어요. 계좌에서는 빠지지 않았어요.'**
  String get expRecordOnlyNote;

  /// No description provided for @expRecordOnlyPartNote.
  ///
  /// In ko, this message translates to:
  /// **'이 중 {amount}은 결제가 끝난 회차분이라 기록만 남았어요. 남은 회차는 정상 청구돼요.'**
  String expRecordOnlyPartNote(String amount);

  /// No description provided for @expClosedCycleLine.
  ///
  /// In ko, this message translates to:
  /// **'이미 결제가 끝난 회차예요. 기록만 바뀌고 계좌 잔액은 그대로예요.'**
  String get expClosedCycleLine;

  /// No description provided for @expClosedCycleToast.
  ///
  /// In ko, this message translates to:
  /// **'결제가 끝난 회차라 기록만 바뀌고 계좌 잔액은 그대로예요.'**
  String get expClosedCycleToast;

  /// No description provided for @expClosedCyclePartLine.
  ///
  /// In ko, this message translates to:
  /// **'지난 회차분은 기록만 남아요.'**
  String get expClosedCyclePartLine;

  /// No description provided for @expFixBalance.
  ///
  /// In ko, this message translates to:
  /// **'잔액 고치기'**
  String get expFixBalance;

  /// No description provided for @expMoneyLockedNote.
  ///
  /// In ko, this message translates to:
  /// **'결제가 끝난 거래예요. 금액·날짜를 바꾸려면 고쳐 쓰기를 눌러주세요'**
  String get expMoneyLockedNote;

  /// No description provided for @expMoneyLockedPaidOffNote.
  ///
  /// In ko, this message translates to:
  /// **'결제가 끝난 거래예요. 중도 정리한 할부라 금액·날짜를 바꿀 수 없어요.'**
  String get expMoneyLockedPaidOffNote;

  /// No description provided for @expRewrite.
  ///
  /// In ko, this message translates to:
  /// **'고쳐 쓰기'**
  String get expRewrite;

  /// No description provided for @expRewriteConfirmLead.
  ///
  /// In ko, this message translates to:
  /// **'원래 거래는 지워지고 새 거래로 바뀌어요.'**
  String get expRewriteConfirmLead;

  /// No description provided for @expRewriteConfirmClosed.
  ///
  /// In ko, this message translates to:
  /// **'기록만 바뀌고 계좌 잔액은 그대로예요.'**
  String get expRewriteConfirmClosed;

  /// No description provided for @expRewriteConfirmOpen.
  ///
  /// In ko, this message translates to:
  /// **'새 거래는 {date} 결제에 청구돼요. 원래 거래는 이미 결제된 회차에서 기록만 빠져요.'**
  String expRewriteConfirmOpen(String date);

  /// No description provided for @expSaveConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'저장할까요?'**
  String get expSaveConfirmTitle;

  /// No description provided for @assetPreRegistrationNote.
  ///
  /// In ko, this message translates to:
  /// **'카드 등록 이전 거래라 실제와 맞지 않을 수 있어요'**
  String get assetPreRegistrationNote;

  /// No description provided for @assetRecordCycle.
  ///
  /// In ko, this message translates to:
  /// **'기록 회차'**
  String get assetRecordCycle;

  /// No description provided for @assetClosedPaidLine.
  ///
  /// In ko, this message translates to:
  /// **'계좌에서 나간 돈은 {paid}이에요. 나머지 {diff}은 기록만 남긴 금액이에요'**
  String assetClosedPaidLine(String paid, String diff);

  /// No description provided for @assetClosedOverpaidLine.
  ///
  /// In ko, this message translates to:
  /// **'기록은 {recorded}인데 계좌에서는 {paid}이 나갔어요'**
  String assetClosedOverpaidLine(String recorded, String paid);

  /// No description provided for @assetPaymentDayMissing.
  ///
  /// In ko, this message translates to:
  /// **'결제일을 넣어주세요'**
  String get assetPaymentDayMissing;

  /// 로딩 원(Progress Circle)의 기본 이름 — 스크린 리더가 읽는다. 기다리는 일을 알면 그 이름을 넘긴다(영수증 사진 올리는 중)
  ///
  /// In ko, this message translates to:
  /// **'불러오는 중'**
  String get dsProgressCircleLabel;

  /// 기다리는 영역이 1초를 넘으면 보조 기술에 한 번 읽는 글(Skeleton 의 상태 글). 세 점이 아니라 말줄임표 하나
  ///
  /// In ko, this message translates to:
  /// **'불러오는 중…'**
  String get dsLoadingWaiting;

  /// 기다리는 영역이 5초를 넘으면 보이고 읽는 글(Skeleton 의 오래 걸림 글)
  ///
  /// In ko, this message translates to:
  /// **'평소보다 오래 걸리고 있어요.'**
  String get dsLoadingSlow;

  /// Progress — 한도를 넘었을 때 오른쪽 글("20,000원 초과")
  ///
  /// In ko, this message translates to:
  /// **'{amount} 초과'**
  String dsProgressOver(String amount);

  /// Progress — 목표에 닿았을 때 오른쪽 글
  ///
  /// In ko, this message translates to:
  /// **'달성'**
  String get dsProgressReached;

  /// Progress 막대의 이름 — "식비 예산 400,000원 중 350,000원"
  ///
  /// In ko, this message translates to:
  /// **'{label} {max} 중 {current}'**
  String dsProgressSemantics(String label, String max, String current);

  /// Field — 한 화면 칸의 2/3 이상이 필수일 때 선택 칸의 라벨 뒤에 붙는 글(field.yaml optionalIndicator — 글은 정해져 있다)
  ///
  /// In ko, this message translates to:
  /// **'선택'**
  String get dsFieldOptional;

  /// Field — 꼬리의 글자 수(보이는 글은 "4/12")를 화면 읽기 프로그램이 읽는 글
  ///
  /// In ko, this message translates to:
  /// **'{max}자 중 {count}자'**
  String dsFieldCountSemantics(int count, int max);

  /// Input — 값을 한 번에 지우는 버튼(원 X 아이콘)의 이름
  ///
  /// In ko, this message translates to:
  /// **'지우기'**
  String get dsInputClear;

  /// No description provided for @fixedSwitchExpense.
  ///
  /// In ko, this message translates to:
  /// **'고정 지출'**
  String get fixedSwitchExpense;

  /// No description provided for @fixedSwitchIncome.
  ///
  /// In ko, this message translates to:
  /// **'고정 수입'**
  String get fixedSwitchIncome;

  /// No description provided for @fixedHintExpense.
  ///
  /// In ko, this message translates to:
  /// **'월세·통신비처럼 매달 나가는 돈이에요. 통계에서 따로 나눠 볼 수 있어요.'**
  String get fixedHintExpense;

  /// No description provided for @fixedHintIncome.
  ///
  /// In ko, this message translates to:
  /// **'월급처럼 매달 들어오는 돈이에요. 통계에서 따로 나눠 볼 수 있어요.'**
  String get fixedHintIncome;

  /// No description provided for @fixedBadge.
  ///
  /// In ko, this message translates to:
  /// **'고정'**
  String get fixedBadge;

  /// No description provided for @recurringFixedSub.
  ///
  /// In ko, this message translates to:
  /// **'이 반복이 앞으로 만드는 거래가 고정으로 기록돼요'**
  String get recurringFixedSub;

  /// No description provided for @presetFixedTitleExpense.
  ///
  /// In ko, this message translates to:
  /// **'고정 지출로 기록'**
  String get presetFixedTitleExpense;

  /// No description provided for @presetFixedTitleIncome.
  ///
  /// In ko, this message translates to:
  /// **'고정 수입으로 기록'**
  String get presetFixedTitleIncome;

  /// No description provided for @presetFixedDesc.
  ///
  /// In ko, this message translates to:
  /// **'이 프리셋으로 만든 거래가 통계의 고정 항목으로 잡혀요.'**
  String get presetFixedDesc;

  /// No description provided for @hideCardStatsFixed.
  ///
  /// In ko, this message translates to:
  /// **'고정·변동 탭'**
  String get hideCardStatsFixed;

  /// No description provided for @statsTabFixed.
  ///
  /// In ko, this message translates to:
  /// **'고정·변동'**
  String get statsTabFixed;

  /// No description provided for @statsFixedViewAria.
  ///
  /// In ko, this message translates to:
  /// **'보기 방식'**
  String get statsFixedViewAria;

  /// No description provided for @statsFixedViewAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get statsFixedViewAll;

  /// No description provided for @statsFixedViewVariable.
  ///
  /// In ko, this message translates to:
  /// **'고정 제외'**
  String get statsFixedViewVariable;

  /// No description provided for @statsFixedViewFixed.
  ///
  /// In ko, this message translates to:
  /// **'고정만'**
  String get statsFixedViewFixed;

  /// No description provided for @statsDonutCenterVariable.
  ///
  /// In ko, this message translates to:
  /// **'고정 제외 지출'**
  String get statsDonutCenterVariable;

  /// No description provided for @statsDonutCenterFixed.
  ///
  /// In ko, this message translates to:
  /// **'고정 지출'**
  String get statsDonutCenterFixed;

  /// No description provided for @statsFixedExpenseTitle.
  ///
  /// In ko, this message translates to:
  /// **'지출 — 고정과 변동'**
  String get statsFixedExpenseTitle;

  /// No description provided for @statsFixedIncomeTitle.
  ///
  /// In ko, this message translates to:
  /// **'수입 — 고정과 변동'**
  String get statsFixedIncomeTitle;

  /// No description provided for @statsFixedExpenseNone.
  ///
  /// In ko, this message translates to:
  /// **'이 기간에는 지출이 없어요.'**
  String get statsFixedExpenseNone;

  /// No description provided for @statsFixedIncomeNone.
  ///
  /// In ko, this message translates to:
  /// **'이 기간에는 수입이 없어요.'**
  String get statsFixedIncomeNone;

  /// No description provided for @statsFixedTotalExpense.
  ///
  /// In ko, this message translates to:
  /// **'전체 지출'**
  String get statsFixedTotalExpense;

  /// No description provided for @statsFixedTotalIncome.
  ///
  /// In ko, this message translates to:
  /// **'전체 수입'**
  String get statsFixedTotalIncome;

  /// No description provided for @statsFixedFixedExpense.
  ///
  /// In ko, this message translates to:
  /// **'고정 지출'**
  String get statsFixedFixedExpense;

  /// No description provided for @statsFixedFixedIncome.
  ///
  /// In ko, this message translates to:
  /// **'고정 수입'**
  String get statsFixedFixedIncome;

  /// No description provided for @statsFixedVariableExpense.
  ///
  /// In ko, this message translates to:
  /// **'고정 제외 지출'**
  String get statsFixedVariableExpense;

  /// No description provided for @statsFixedVariableIncome.
  ///
  /// In ko, this message translates to:
  /// **'고정 제외 수입'**
  String get statsFixedVariableIncome;

  /// No description provided for @statsFixedBarSemantics.
  ///
  /// In ko, this message translates to:
  /// **'{kind} 중 고정 {fixed}%, 변동 {variable}%'**
  String statsFixedBarSemantics(String kind, int fixed, int variable);

  /// No description provided for @statsFixedInsightExpense.
  ///
  /// In ko, this message translates to:
  /// **'지출의 {pct}%가 고정이에요. 고정을 뺀 지출은'**
  String statsFixedInsightExpense(int pct);

  /// No description provided for @statsFixedInsightIncome.
  ///
  /// In ko, this message translates to:
  /// **'수입의 {pct}%가 고정이에요. 고정을 뺀 수입은'**
  String statsFixedInsightIncome(int pct);

  /// No description provided for @statsFixedInsightTail.
  ///
  /// In ko, this message translates to:
  /// **'이에요.'**
  String get statsFixedInsightTail;

  /// No description provided for @statsFixedEmptyDesc.
  ///
  /// In ko, this message translates to:
  /// **'월세·통신비·월급처럼 매달 정해진 거래를 고정으로 표시하면 여기서 따로 볼 수 있어요.'**
  String get statsFixedEmptyDesc;

  /// No description provided for @statsFixedManage.
  ///
  /// In ko, this message translates to:
  /// **'거래를 고정으로 정리하기'**
  String get statsFixedManage;

  /// No description provided for @statsFixedManageHint.
  ///
  /// In ko, this message translates to:
  /// **'매달 같은 이름으로 나가는 돈은 한 번에 정리할 수 있어요'**
  String get statsFixedManageHint;

  /// No description provided for @statsFixedTrendTitle.
  ///
  /// In ko, this message translates to:
  /// **'월별 고정·변동 추이'**
  String get statsFixedTrendTitle;

  /// No description provided for @statsFixedTrendKindAria.
  ///
  /// In ko, this message translates to:
  /// **'지출 또는 수입'**
  String get statsFixedTrendKindAria;

  /// No description provided for @statsFixedTrendRecent.
  ///
  /// In ko, this message translates to:
  /// **'최근 6개월'**
  String get statsFixedTrendRecent;

  /// No description provided for @statsFixedKindExpense.
  ///
  /// In ko, this message translates to:
  /// **'지출'**
  String get statsFixedKindExpense;

  /// No description provided for @statsFixedKindIncome.
  ///
  /// In ko, this message translates to:
  /// **'수입'**
  String get statsFixedKindIncome;

  /// No description provided for @statsFixedLegendFixed.
  ///
  /// In ko, this message translates to:
  /// **'고정'**
  String get statsFixedLegendFixed;

  /// No description provided for @statsFixedLegendVariable.
  ///
  /// In ko, this message translates to:
  /// **'변동'**
  String get statsFixedLegendVariable;

  /// No description provided for @statsFixedCategoryTitle.
  ///
  /// In ko, this message translates to:
  /// **'카테고리별 고정·변동'**
  String get statsFixedCategoryTitle;

  /// No description provided for @statsFixedCategoryFixedPart.
  ///
  /// In ko, this message translates to:
  /// **'그중 고정 {pct}%'**
  String statsFixedCategoryFixedPart(int pct);

  /// No description provided for @statsFixedBulkTitle.
  ///
  /// In ko, this message translates to:
  /// **'거래를 고정으로 정리하기'**
  String get statsFixedBulkTitle;

  /// No description provided for @statsFixedBulkDesc.
  ///
  /// In ko, this message translates to:
  /// **'{start} ~ {end} 기간의 거래예요. 매달 같은 이름으로 나가는 돈은 한 줄로 묶여 있어요. 돈이나 잔액은 달라지지 않고 통계의 분류만 바뀌어요.'**
  String statsFixedBulkDesc(String start, String end);

  /// No description provided for @statsFixedBulkUntitled.
  ///
  /// In ko, this message translates to:
  /// **'이름 없는 거래'**
  String get statsFixedBulkUntitled;

  /// No description provided for @statsFixedBulkTargetAria.
  ///
  /// In ko, this message translates to:
  /// **'바꿀 방향'**
  String get statsFixedBulkTargetAria;

  /// No description provided for @statsFixedBulkToFixed.
  ///
  /// In ko, this message translates to:
  /// **'고정으로 표시'**
  String get statsFixedBulkToFixed;

  /// No description provided for @statsFixedBulkToVariable.
  ///
  /// In ko, this message translates to:
  /// **'변동으로 되돌리기'**
  String get statsFixedBulkToVariable;

  /// No description provided for @statsFixedBulkGroupSub.
  ///
  /// In ko, this message translates to:
  /// **'{count}건'**
  String statsFixedBulkGroupSub(int count);

  /// No description provided for @statsFixedBulkBadgeAll.
  ///
  /// In ko, this message translates to:
  /// **'고정'**
  String get statsFixedBulkBadgeAll;

  /// No description provided for @statsFixedBulkBadgeSome.
  ///
  /// In ko, this message translates to:
  /// **'고정 {fixed}/{count}'**
  String statsFixedBulkBadgeSome(int fixed, int count);

  /// No description provided for @statsFixedBulkEmpty.
  ///
  /// In ko, this message translates to:
  /// **'이 기간에는 정리할 거래가 없어요.'**
  String get statsFixedBulkEmpty;

  /// No description provided for @statsFixedBulkApply.
  ///
  /// In ko, this message translates to:
  /// **'{count}건 적용'**
  String statsFixedBulkApply(int count);

  /// No description provided for @statsFixedBulkDoneFixed.
  ///
  /// In ko, this message translates to:
  /// **'{count}건을 고정으로 바꿨어요.'**
  String statsFixedBulkDoneFixed(int count);

  /// No description provided for @statsFixedBulkDoneVariable.
  ///
  /// In ko, this message translates to:
  /// **'{count}건을 변동으로 되돌렸어요.'**
  String statsFixedBulkDoneVariable(int count);

  /// No description provided for @statsFixedBulkFailed.
  ///
  /// In ko, this message translates to:
  /// **'고정 표시를 바꾸지 못했어요.'**
  String get statsFixedBulkFailed;

  /// 하단 탭 바의 이름(낭독) — Bottom Navigation
  ///
  /// In ko, this message translates to:
  /// **'주 메뉴'**
  String get navMainMenu;

  /// 안 읽은 알림이 있을 때 벨 버튼의 이름
  ///
  /// In ko, this message translates to:
  /// **'알림, 새 알림 있음'**
  String get navNotificationsNew;

  /// 알림 점이 있는 탭 · 칸의 이름 뒤에 붙는 글
  ///
  /// In ko, this message translates to:
  /// **'새 소식'**
  String get dsNotificationBadge;

  /// Quantity Picker — 줄이는 버튼의 기본 이름
  ///
  /// In ko, this message translates to:
  /// **'줄이기'**
  String get dsQuantityDecrease;

  /// Quantity Picker — 늘리는 버튼의 기본 이름
  ///
  /// In ko, this message translates to:
  /// **'늘리기'**
  String get dsQuantityIncrease;

  /// Slider 범위 — 작은 손잡이의 기본 이름
  ///
  /// In ko, this message translates to:
  /// **'최소'**
  String get dsSliderMin;

  /// Slider 범위 — 큰 손잡이의 기본 이름
  ///
  /// In ko, this message translates to:
  /// **'최대'**
  String get dsSliderMax;

  /// ds 컴포넌트 문구
  ///
  /// In ko, this message translates to:
  /// **'{n}번째 항목을 들었어요.'**
  String dsAttachLifted(int n);

  /// ds 컴포넌트 문구
  ///
  /// In ko, this message translates to:
  /// **'사진 {n}장을 붙였어요.'**
  String dsAttachAddedPhotos(int n);

  /// ds 컴포넌트 문구
  ///
  /// In ko, this message translates to:
  /// **'파일 {n}개를 붙였어요.'**
  String dsAttachAddedFiles(int n);

  /// ds 컴포넌트 문구
  ///
  /// In ko, this message translates to:
  /// **'{n}개를 붙였어요.'**
  String dsAttachAddedItems(int n);

  /// ds 컴포넌트 문구
  ///
  /// In ko, this message translates to:
  /// **'{n}개를 올렸어요.'**
  String dsAttachUploaded(int n);

  /// ds 컴포넌트 문구
  ///
  /// In ko, this message translates to:
  /// **'{n}개는 올리지 못했어요.'**
  String dsAttachFailedCount(int n);

  /// No description provided for @dsAttachTitle.
  ///
  /// In ko, this message translates to:
  /// **'첨부'**
  String get dsAttachTitle;

  /// No description provided for @dsAttachCamera.
  ///
  /// In ko, this message translates to:
  /// **'사진 찍기'**
  String get dsAttachCamera;

  /// No description provided for @dsAttachGallery.
  ///
  /// In ko, this message translates to:
  /// **'앨범에서 고르기'**
  String get dsAttachGallery;

  /// No description provided for @dsAttachFiles.
  ///
  /// In ko, this message translates to:
  /// **'파일 고르기'**
  String get dsAttachFiles;

  /// ds 컴포넌트 문구
  ///
  /// In ko, this message translates to:
  /// **'{n}번째 자리로 옮겼어요.'**
  String dsAttachMoved(int n);

  /// No description provided for @dsAttachPreviewImage.
  ///
  /// In ko, this message translates to:
  /// **'크게 보기'**
  String get dsAttachPreviewImage;

  /// No description provided for @dsAttachOpen.
  ///
  /// In ko, this message translates to:
  /// **'열기'**
  String get dsAttachOpen;

  /// No description provided for @dsAttachMakeCover.
  ///
  /// In ko, this message translates to:
  /// **'대표로 정하기'**
  String get dsAttachMakeCover;

  /// No description provided for @dsAttachMoveForward.
  ///
  /// In ko, this message translates to:
  /// **'앞으로 옮기기'**
  String get dsAttachMoveForward;

  /// No description provided for @dsAttachMoveBack.
  ///
  /// In ko, this message translates to:
  /// **'뒤로 옮기기'**
  String get dsAttachMoveBack;

  /// No description provided for @dsAttachUploading.
  ///
  /// In ko, this message translates to:
  /// **'올리는 중'**
  String get dsAttachUploading;

  /// ds 컴포넌트 문구
  ///
  /// In ko, this message translates to:
  /// **'올리는 중 {percent}%'**
  String dsAttachUploadingPercent(int percent);

  /// No description provided for @dsAttachUploadFailed.
  ///
  /// In ko, this message translates to:
  /// **'올리지 못했어요'**
  String get dsAttachUploadFailed;

  /// No description provided for @dsAttachDefaultLabel.
  ///
  /// In ko, this message translates to:
  /// **'파일'**
  String get dsAttachDefaultLabel;

  /// No description provided for @dsAttachSuffix.
  ///
  /// In ko, this message translates to:
  /// **'첨부'**
  String get dsAttachSuffix;

  /// ds 컴포넌트 문구
  ///
  /// In ko, this message translates to:
  /// **'첨부, {count}'**
  String dsAttachSuffixCount(String count);

  /// No description provided for @dsAttachPickFiles.
  ///
  /// In ko, this message translates to:
  /// **'파일 선택'**
  String get dsAttachPickFiles;

  /// ds 컴포넌트 문구
  ///
  /// In ko, this message translates to:
  /// **'{name} 다시 시도'**
  String dsAttachRetryNamed(String name);

  /// No description provided for @dsAttachRetry.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get dsAttachRetry;

  /// ds 컴포넌트 문구
  ///
  /// In ko, this message translates to:
  /// **'{name} 지우기'**
  String dsAttachRemoveNamed(String name);

  /// No description provided for @dsAvatarUploading.
  ///
  /// In ko, this message translates to:
  /// **'프로필 사진 올리는 중'**
  String get dsAvatarUploading;

  /// No description provided for @dsDeltaNoChangeSentence.
  ///
  /// In ko, this message translates to:
  /// **'변화가 없어요'**
  String get dsDeltaNoChangeSentence;

  /// No description provided for @dsDeltaIncreased.
  ///
  /// In ko, this message translates to:
  /// **'늘었어요'**
  String get dsDeltaIncreased;

  /// No description provided for @dsDeltaDecreased.
  ///
  /// In ko, this message translates to:
  /// **'줄었어요'**
  String get dsDeltaDecreased;

  /// No description provided for @dsDeltaNone.
  ///
  /// In ko, this message translates to:
  /// **'변화 없음'**
  String get dsDeltaNone;

  /// No description provided for @dsChartHeatValue.
  ///
  /// In ko, this message translates to:
  /// **'지출'**
  String get dsChartHeatValue;

  /// No description provided for @dsChartHeatNone.
  ///
  /// In ko, this message translates to:
  /// **'없음'**
  String get dsChartHeatNone;

  /// No description provided for @dsChartLegend.
  ///
  /// In ko, this message translates to:
  /// **'범례'**
  String get dsChartLegend;

  /// ds 컴포넌트 문구
  ///
  /// In ko, this message translates to:
  /// **'{row} 더보기'**
  String dsSwipeMore(String row);

  /// No description provided for @dsColorRed.
  ///
  /// In ko, this message translates to:
  /// **'빨강'**
  String get dsColorRed;

  /// No description provided for @dsColorOrange.
  ///
  /// In ko, this message translates to:
  /// **'주황'**
  String get dsColorOrange;

  /// No description provided for @dsColorYellow.
  ///
  /// In ko, this message translates to:
  /// **'노랑'**
  String get dsColorYellow;

  /// No description provided for @dsColorGreen.
  ///
  /// In ko, this message translates to:
  /// **'초록'**
  String get dsColorGreen;

  /// No description provided for @dsColorBlue.
  ///
  /// In ko, this message translates to:
  /// **'파랑'**
  String get dsColorBlue;

  /// No description provided for @dsColorIndigo.
  ///
  /// In ko, this message translates to:
  /// **'남색'**
  String get dsColorIndigo;

  /// No description provided for @dsColorViolet.
  ///
  /// In ko, this message translates to:
  /// **'보라'**
  String get dsColorViolet;

  /// No description provided for @dsColorPink.
  ///
  /// In ko, this message translates to:
  /// **'분홍'**
  String get dsColorPink;

  /// No description provided for @dsColorBrown.
  ///
  /// In ko, this message translates to:
  /// **'갈색'**
  String get dsColorBrown;

  /// No description provided for @dsColorGray.
  ///
  /// In ko, this message translates to:
  /// **'회색'**
  String get dsColorGray;

  /// No description provided for @dsColorCurrent.
  ///
  /// In ko, this message translates to:
  /// **'지금 색'**
  String get dsColorCurrent;

  /// No description provided for @dsColorAuto.
  ///
  /// In ko, this message translates to:
  /// **'자동'**
  String get dsColorAuto;

  /// No description provided for @dsIconTitle.
  ///
  /// In ko, this message translates to:
  /// **'아이콘'**
  String get dsIconTitle;

  /// No description provided for @dsIconSearch.
  ///
  /// In ko, this message translates to:
  /// **'아이콘 검색'**
  String get dsIconSearch;

  /// No description provided for @dsIconSearchPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'아이콘 이름 검색'**
  String get dsIconSearchPlaceholder;

  /// No description provided for @dsIconCurrent.
  ///
  /// In ko, this message translates to:
  /// **'지금 아이콘'**
  String get dsIconCurrent;

  /// No description provided for @dsIconEmptyDescription.
  ///
  /// In ko, this message translates to:
  /// **'다른 말로 찾거나 묶음에서 골라주세요.'**
  String get dsIconEmptyDescription;

  /// ds 컴포넌트 문구
  ///
  /// In ko, this message translates to:
  /// **'\'{query}\'에 대한 아이콘이 없어요'**
  String dsIconEmptyTitle(String query);

  /// ds 컴포넌트 문구
  ///
  /// In ko, this message translates to:
  /// **'검색 결과 {count}개'**
  String dsIconCount(int count);

  /// No description provided for @dsIconTagFallback.
  ///
  /// In ko, this message translates to:
  /// **'태그'**
  String get dsIconTagFallback;

  /// No description provided for @dsTimeTitle.
  ///
  /// In ko, this message translates to:
  /// **'시간 선택'**
  String get dsTimeTitle;

  /// No description provided for @dsTimePeriod.
  ///
  /// In ko, this message translates to:
  /// **'오전/오후'**
  String get dsTimePeriod;

  /// No description provided for @dsTimeHour.
  ///
  /// In ko, this message translates to:
  /// **'시'**
  String get dsTimeHour;

  /// No description provided for @dsTimeMinute.
  ///
  /// In ko, this message translates to:
  /// **'분'**
  String get dsTimeMinute;

  /// No description provided for @dsTimeAm.
  ///
  /// In ko, this message translates to:
  /// **'오전'**
  String get dsTimeAm;

  /// No description provided for @dsTimePm.
  ///
  /// In ko, this message translates to:
  /// **'오후'**
  String get dsTimePm;

  /// No description provided for @dsDateRoot.
  ///
  /// In ko, this message translates to:
  /// **'날짜 선택'**
  String get dsDateRoot;

  /// No description provided for @dsDatePrevMonth.
  ///
  /// In ko, this message translates to:
  /// **'이전 달'**
  String get dsDatePrevMonth;

  /// No description provided for @dsDateNextMonth.
  ///
  /// In ko, this message translates to:
  /// **'다음 달'**
  String get dsDateNextMonth;

  /// No description provided for @dsDateYear.
  ///
  /// In ko, this message translates to:
  /// **'연도'**
  String get dsDateYear;

  /// No description provided for @dsDateMonth.
  ///
  /// In ko, this message translates to:
  /// **'월'**
  String get dsDateMonth;

  /// No description provided for @dsDateReadOnlyStart.
  ///
  /// In ko, this message translates to:
  /// **'읽기 전용 시작일'**
  String get dsDateReadOnlyStart;

  /// No description provided for @dsDatePresets.
  ///
  /// In ko, this message translates to:
  /// **'빠른 기간'**
  String get dsDatePresets;

  /// No description provided for @dsDateToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get dsDateToday;

  /// 탭 이름 뒤에 붙는 자리 — 안드로이드 · iOS 는 tab 역할을 전달하지 않아 이름으로 알린다(Material TabBar 와 같다)
  ///
  /// In ko, this message translates to:
  /// **'탭 {index}/{count}'**
  String dsTabPosition(int index, int count);

  /// No description provided for @dsDatePresetThisWeek.
  ///
  /// In ko, this message translates to:
  /// **'이번 주'**
  String get dsDatePresetThisWeek;

  /// No description provided for @dsDatePresetThisMonth.
  ///
  /// In ko, this message translates to:
  /// **'이번 달'**
  String get dsDatePresetThisMonth;

  /// No description provided for @dsDatePresetLastMonth.
  ///
  /// In ko, this message translates to:
  /// **'지난 달'**
  String get dsDatePresetLastMonth;

  /// No description provided for @dsDatePresetLast7.
  ///
  /// In ko, this message translates to:
  /// **'최근 7일'**
  String get dsDatePresetLast7;

  /// No description provided for @dsDatePresetLast30.
  ///
  /// In ko, this message translates to:
  /// **'최근 30일'**
  String get dsDatePresetLast30;

  /// No description provided for @dsDatePresetLast3M.
  ///
  /// In ko, this message translates to:
  /// **'최근 3개월'**
  String get dsDatePresetLast3M;

  /// No description provided for @dsDatePresetLast6M.
  ///
  /// In ko, this message translates to:
  /// **'최근 6개월'**
  String get dsDatePresetLast6M;

  /// No description provided for @dsDatePresetLast1Y.
  ///
  /// In ko, this message translates to:
  /// **'최근 1년'**
  String get dsDatePresetLast1Y;

  /// No description provided for @dsDatePresetThisYear.
  ///
  /// In ko, this message translates to:
  /// **'올해'**
  String get dsDatePresetThisYear;

  /// No description provided for @apiErrorServer.
  ///
  /// In ko, this message translates to:
  /// **'요청을 처리하지 못했어요. 잠시 뒤 다시 시도해주세요.'**
  String get apiErrorServer;

  /// 목록 끝(Infinite List)에서 다음 쪽을 못 받았을 때 글 — 이미 받은 줄은 그대로 두고 다시 시도 버튼이 붙는다
  ///
  /// In ko, this message translates to:
  /// **'더 불러오지 못했어요.'**
  String get dsInfiniteListError;

  /// 목록 끝(Infinite List)에서 더 받을 쪽이 없을 때 기본 글 — 목록마다 "카드를 모두 봤어요." 처럼 바꿀 수 있다
  ///
  /// In ko, this message translates to:
  /// **'모두 봤어요.'**
  String get dsInfiniteListEnd;

  /// 당겨서 새로 고침(Pull To Refresh)이 새로 고치는 동안만 읽히는 진행 표시의 이름 — 쉬는 동안 · 당기는 동안은 지시자를 숨긴다
  ///
  /// In ko, this message translates to:
  /// **'새로 고치는 중'**
  String get dsPullToRefreshLabel;

  /// 당겨서 새로 고침이 실패했을 때 Snackbar 한 문장 — 보던 내용은 그대로 두고 알린다. [다시 시도] 없음(다시 당기면 된다), 공용 queryRefreshFailed 와 같은 글
  ///
  /// In ko, this message translates to:
  /// **'새로 고치지 못했어요.'**
  String get dsPullToRefreshFailed;

  /// ds 부품이 다시 하기 단추에 쓰는 공용 글 — 웹 ds.common.retry 와 짝
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get dsCommonRetry;

  /// 카드 혜택 목록 첫 쪽을 못 불러왔을 때 Result Section 제목 — 예외 · 서버 글을 붙이지 않는다
  ///
  /// In ko, this message translates to:
  /// **'카드를 불러오지 못했어요'**
  String get cardListLoadFailed;

  /// 카드 혜택 목록 끝 자리의 끝 글(Infinite List) — 한 쪽이 넘게 받았을 때만
  ///
  /// In ko, this message translates to:
  /// **'카드를 모두 봤어요.'**
  String get cardListEnd;

  /// No description provided for @apiErrorNetwork.
  ///
  /// In ko, this message translates to:
  /// **'네트워크 연결이 불안정해요. 잠시 뒤 다시 시도해주세요.'**
  String get apiErrorNetwork;

  /// No description provided for @txmCalendarToggle.
  ///
  /// In ko, this message translates to:
  /// **'월 달력'**
  String get txmCalendarToggle;

  /// No description provided for @expFilteredEmpty.
  ///
  /// In ko, this message translates to:
  /// **'조건에 맞는 거래가 없어요'**
  String get expFilteredEmpty;

  /// No description provided for @expFilteredEmptyDesc.
  ///
  /// In ko, this message translates to:
  /// **'조건을 바꾸거나 지워보세요.'**
  String get expFilteredEmptyDesc;

  /// No description provided for @expFilterMatchAllDesc.
  ///
  /// In ko, this message translates to:
  /// **'걸린 조건을 모두 만족하는 거래만'**
  String get expFilterMatchAllDesc;

  /// No description provided for @expFilterMatchAnyDesc.
  ///
  /// In ko, this message translates to:
  /// **'걸린 조건 중 하나라도 만족하면'**
  String get expFilterMatchAnyDesc;

  /// No description provided for @expFilterModeInclude.
  ///
  /// In ko, this message translates to:
  /// **'고른 것만'**
  String get expFilterModeInclude;

  /// No description provided for @expFilterModeExclude.
  ///
  /// In ko, this message translates to:
  /// **'고른 것 빼고'**
  String get expFilterModeExclude;

  /// No description provided for @expFilterPeriodPick.
  ///
  /// In ko, this message translates to:
  /// **'기간 선택'**
  String get expFilterPeriodPick;

  /// No description provided for @expFilterClearOne.
  ///
  /// In ko, this message translates to:
  /// **'{name} 지우기'**
  String expFilterClearOne(String name);

  /// No description provided for @expFilterModeGroup.
  ///
  /// In ko, this message translates to:
  /// **'{name} 고르는 방식'**
  String expFilterModeGroup(String name);

  /// No description provided for @expLoadErrorDesc.
  ///
  /// In ko, this message translates to:
  /// **'잠시 뒤 다시 시도해주세요.'**
  String get expLoadErrorDesc;

  /// No description provided for @statsNoMonthlyData.
  ///
  /// In ko, this message translates to:
  /// **'월별 데이터가 없어요.'**
  String get statsNoMonthlyData;

  /// No description provided for @statsLoadFailedCategory.
  ///
  /// In ko, this message translates to:
  /// **'카테고리별 지출을 불러오지 못했어요'**
  String get statsLoadFailedCategory;

  /// No description provided for @statsLoadFailedMerchant.
  ///
  /// In ko, this message translates to:
  /// **'가맹점 순위를 불러오지 못했어요'**
  String get statsLoadFailedMerchant;

  /// No description provided for @statsLoadFailedHeatmap.
  ///
  /// In ko, this message translates to:
  /// **'요일 · 시간대 지출을 불러오지 못했어요'**
  String get statsLoadFailedHeatmap;

  /// No description provided for @statsLoadFailedHighlights.
  ///
  /// In ko, this message translates to:
  /// **'요약을 불러오지 못했어요'**
  String get statsLoadFailedHighlights;

  /// No description provided for @statsLoadFailedTrend.
  ///
  /// In ko, this message translates to:
  /// **'추이를 불러오지 못했어요'**
  String get statsLoadFailedTrend;

  /// No description provided for @statsLoadFailedCompare.
  ///
  /// In ko, this message translates to:
  /// **'비교할 내용을 불러오지 못했어요'**
  String get statsLoadFailedCompare;

  /// No description provided for @statsLoadFailedWeekday.
  ///
  /// In ko, this message translates to:
  /// **'요일별 지출을 불러오지 못했어요'**
  String get statsLoadFailedWeekday;

  /// No description provided for @statsLoadFailedFixed.
  ///
  /// In ko, this message translates to:
  /// **'고정 · 변동 내용을 불러오지 못했어요'**
  String get statsLoadFailedFixed;

  /// No description provided for @statsFixedBulkLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'거래를 불러오지 못했어요'**
  String get statsFixedBulkLoadFailed;

  /// No description provided for @statsCompareSame.
  ///
  /// In ko, this message translates to:
  /// **'지난 기간과 같아요.'**
  String get statsCompareSame;

  /// No description provided for @statsChartDonutName.
  ///
  /// In ko, this message translates to:
  /// **'{period} 카테고리별 지출, 합계 {total}'**
  String statsChartDonutName(String period, String total);

  /// No description provided for @statsChartHeatName.
  ///
  /// In ko, this message translates to:
  /// **'{period} 요일 · 시간대별 지출, 합계 {total}'**
  String statsChartHeatName(String period, String total);

  /// No description provided for @statsChartHeatValue.
  ///
  /// In ko, this message translates to:
  /// **'지출'**
  String get statsChartHeatValue;

  /// No description provided for @statsChartTrendName.
  ///
  /// In ko, this message translates to:
  /// **'{period} 수입 · 지출 추이, 수입 {income} · 지출 {expense}'**
  String statsChartTrendName(String period, String income, String expense);

  /// No description provided for @statsChartSavingsName.
  ///
  /// In ko, this message translates to:
  /// **'{period} {unit}'**
  String statsChartSavingsName(String period, String unit);

  /// No description provided for @statsChartCatTrendName.
  ///
  /// In ko, this message translates to:
  /// **'{period} 주요 카테고리 월별 지출 추이'**
  String statsChartCatTrendName(String period);

  /// No description provided for @statsChartWeekdayName.
  ///
  /// In ko, this message translates to:
  /// **'{period} 요일별 지출 비교'**
  String statsChartWeekdayName(String period);

  /// No description provided for @statsChartFixedName.
  ///
  /// In ko, this message translates to:
  /// **'{kind} 월별 고정 · 변동 추이'**
  String statsChartFixedName(String kind);

  /// No description provided for @statsTableDate.
  ///
  /// In ko, this message translates to:
  /// **'날짜'**
  String get statsTableDate;

  /// No description provided for @statsTableMonth.
  ///
  /// In ko, this message translates to:
  /// **'월'**
  String get statsTableMonth;

  /// No description provided for @statsTableTime.
  ///
  /// In ko, this message translates to:
  /// **'시간대'**
  String get statsTableTime;

  /// No description provided for @statsTableWeekday.
  ///
  /// In ko, this message translates to:
  /// **'요일'**
  String get statsTableWeekday;

  /// No description provided for @statsPeriodButtonAria.
  ///
  /// In ko, this message translates to:
  /// **'기간 {period} 바꾸기'**
  String statsPeriodButtonAria(String period);

  /// No description provided for @statsTabsAria.
  ///
  /// In ko, this message translates to:
  /// **'통계 보기'**
  String get statsTabsAria;

  /// No description provided for @tdmFilterOn.
  ///
  /// In ko, this message translates to:
  /// **'필터, 조건 걸림'**
  String get tdmFilterOn;

  /// No description provided for @todoCheckName.
  ///
  /// In ko, this message translates to:
  /// **'{title} 완료'**
  String todoCheckName(String title);

  /// No description provided for @todoCheckNameOverdue.
  ///
  /// In ko, this message translates to:
  /// **'{title} 완료, 마감 지남'**
  String todoCheckNameOverdue(String title);

  /// No description provided for @todoMemoTag.
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get todoMemoTag;

  /// No description provided for @tdmCellLeft.
  ///
  /// In ko, this message translates to:
  /// **'{date}, 남은 할 일 {count}개'**
  String tdmCellLeft(String date, int count);

  /// No description provided for @tdmCellCollected.
  ///
  /// In ko, this message translates to:
  /// **'{date}, 별자리 수집'**
  String tdmCellCollected(String date);

  /// No description provided for @tdmCellMissed.
  ///
  /// In ko, this message translates to:
  /// **'{date}, 놓친 날'**
  String tdmCellMissed(String date);

  /// No description provided for @tdmCellDone.
  ///
  /// In ko, this message translates to:
  /// **'{date}, 다 끝냄'**
  String tdmCellDone(String date);

  /// No description provided for @tdmLoadFailedDesc.
  ///
  /// In ko, this message translates to:
  /// **'잠시 후 다시 시도해주세요.'**
  String get tdmLoadFailedDesc;

  /// No description provided for @todoToggleFailed.
  ///
  /// In ko, this message translates to:
  /// **'할 일 상태를 바꾸지 못했어요.'**
  String get todoToggleFailed;

  /// No description provided for @todoDetailOverdue.
  ///
  /// In ko, this message translates to:
  /// **'마감 지남'**
  String get todoDetailOverdue;

  /// No description provided for @todoDueDatePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'마감일 선택'**
  String get todoDueDatePlaceholder;

  /// No description provided for @todoTagEmptyHint.
  ///
  /// In ko, this message translates to:
  /// **'태그는 설정 › 할 일 태그에서 만들어요.'**
  String get todoTagEmptyHint;

  /// No description provided for @ttagEmptyHint.
  ///
  /// In ko, this message translates to:
  /// **'{label} 버튼으로 첫 태그를 만들어보세요.'**
  String ttagEmptyHint(String label);

  /// No description provided for @todoDueClear.
  ///
  /// In ko, this message translates to:
  /// **'마감일 지우기'**
  String get todoDueClear;

  /// No description provided for @ttagNameRequired.
  ///
  /// In ko, this message translates to:
  /// **'이름을 입력해주세요.'**
  String get ttagNameRequired;

  /// No description provided for @ttagNameTooLong.
  ///
  /// In ko, this message translates to:
  /// **'이름은 12자 이내로 입력해주세요.'**
  String get ttagNameTooLong;

  /// No description provided for @ttagNameDuplicate.
  ///
  /// In ko, this message translates to:
  /// **'같은 이름의 태그가 이미 있어요.'**
  String get ttagNameDuplicate;

  /// No description provided for @assetPickInstitutionTitle.
  ///
  /// In ko, this message translates to:
  /// **'기관 고르기'**
  String get assetPickInstitutionTitle;

  /// No description provided for @assetPickBrokerTitle.
  ///
  /// In ko, this message translates to:
  /// **'증권사 고르기'**
  String get assetPickBrokerTitle;

  /// No description provided for @assetInstitutionPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'기관 선택'**
  String get assetInstitutionPlaceholder;

  /// No description provided for @assetCardPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'카드 선택'**
  String get assetCardPlaceholder;

  /// No description provided for @assetPickCardTitle.
  ///
  /// In ko, this message translates to:
  /// **'카드 상품 고르기'**
  String get assetPickCardTitle;

  /// No description provided for @assetCardEmptyHint.
  ///
  /// In ko, this message translates to:
  /// **'카드사 이름으로도 찾아보세요.'**
  String get assetCardEmptyHint;

  /// No description provided for @assetSearchEmpty.
  ///
  /// In ko, this message translates to:
  /// **'\'{query}\'에 대한 검색 결과가 없어요'**
  String assetSearchEmpty(String query);

  /// No description provided for @assetSearchFailed.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과를 불러오지 못했어요'**
  String get assetSearchFailed;

  /// No description provided for @assetAddStock.
  ///
  /// In ko, this message translates to:
  /// **'종목 추가'**
  String get assetAddStock;

  /// No description provided for @assetFormFirstTitle.
  ///
  /// In ko, this message translates to:
  /// **'무엇을 추가할까요?'**
  String get assetFormFirstTitle;

  /// No description provided for @assetFormPickKindError.
  ///
  /// In ko, this message translates to:
  /// **'추가할 종류를 골라주세요.'**
  String get assetFormPickKindError;

  /// No description provided for @assetFormTitleAdd.
  ///
  /// In ko, this message translates to:
  /// **'{kind} 추가'**
  String assetFormTitleAdd(String kind);

  /// No description provided for @assetFormTitleEdit.
  ///
  /// In ko, this message translates to:
  /// **'{kind} 수정'**
  String assetFormTitleEdit(String kind);

  /// No description provided for @assetFormKindLabel.
  ///
  /// In ko, this message translates to:
  /// **'종류'**
  String get assetFormKindLabel;

  /// No description provided for @assetFormRulesGroup.
  ///
  /// In ko, this message translates to:
  /// **'표시 설정'**
  String get assetFormRulesGroup;

  /// No description provided for @assetMemo.
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get assetMemo;

  /// No description provided for @assetOverLimitHelp.
  ///
  /// In ko, this message translates to:
  /// **'한도보다 {amount} 많아요. 저장은 되지만 한도나 사용액을 다시 확인해주세요.'**
  String assetOverLimitHelp(String amount);

  /// No description provided for @assetBalanceAutoHelp.
  ///
  /// In ko, this message translates to:
  /// **'보유 종목 합계로 자동 계산돼요. 연동 종목은 시세 확보 시 반영돼요.'**
  String get assetBalanceAutoHelp;

  /// No description provided for @assetHoldingQuantity.
  ///
  /// In ko, this message translates to:
  /// **'수량'**
  String get assetHoldingQuantity;

  /// No description provided for @assetHoldingValueLabel.
  ///
  /// In ko, this message translates to:
  /// **'평가액'**
  String get assetHoldingValueLabel;

  /// No description provided for @assetHoldingItemName.
  ///
  /// In ko, this message translates to:
  /// **'항목 이름'**
  String get assetHoldingItemName;

  /// No description provided for @assetHoldingRemoveOf.
  ///
  /// In ko, this message translates to:
  /// **'{name} 지우기'**
  String assetHoldingRemoveOf(String name);

  /// No description provided for @unlockVerifyFailed.
  ///
  /// In ko, this message translates to:
  /// **'확인하지 못했어요. 잠시 뒤 다시 시도해주세요.'**
  String get unlockVerifyFailed;

  /// No description provided for @unlockViewAmounts.
  ///
  /// In ko, this message translates to:
  /// **'금액 보기'**
  String get unlockViewAmounts;

  /// No description provided for @assetPaymentDayChangeAsk.
  ///
  /// In ko, this message translates to:
  /// **'결제일을 바꿀까요?'**
  String get assetPaymentDayChangeAsk;

  /// No description provided for @assetFormErrCard.
  ///
  /// In ko, this message translates to:
  /// **'카드 상품을 골라주세요.'**
  String get assetFormErrCard;

  /// No description provided for @assetFormErrPaymentDay.
  ///
  /// In ko, this message translates to:
  /// **'결제일을 골라주세요.'**
  String get assetFormErrPaymentDay;

  /// No description provided for @assetNoPaymentAccount.
  ///
  /// In ko, this message translates to:
  /// **'결제 출금계좌 없음'**
  String get assetNoPaymentAccount;

  /// No description provided for @assetNoLinkedAccount.
  ///
  /// In ko, this message translates to:
  /// **'연결 계좌 없음'**
  String get assetNoLinkedAccount;

  /// No description provided for @unlockPasswordRequired.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호를 입력해주세요.'**
  String get unlockPasswordRequired;

  /// No description provided for @stocksNoWatchlistDesc.
  ///
  /// In ko, this message translates to:
  /// **'종목을 찾아 ☆ 를 눌러 보세요.'**
  String get stocksNoWatchlistDesc;

  /// No description provided for @stocksSectionMarket.
  ///
  /// In ko, this message translates to:
  /// **'시장'**
  String get stocksSectionMarket;

  /// No description provided for @stocksSectionStocks.
  ///
  /// In ko, this message translates to:
  /// **'종목'**
  String get stocksSectionStocks;

  /// No description provided for @stocksOrderbookTrades.
  ///
  /// In ko, this message translates to:
  /// **'호가 · 체결'**
  String get stocksOrderbookTrades;

  /// No description provided for @stocksVsPurchase.
  ///
  /// In ko, this message translates to:
  /// **'매입금액보다'**
  String get stocksVsPurchase;

  /// No description provided for @stocksWatchGroupTitle.
  ///
  /// In ko, this message translates to:
  /// **'{name} · {count}'**
  String stocksWatchGroupTitle(String name, int count);

  /// No description provided for @stocksWatchGroupRenameItem.
  ///
  /// In ko, this message translates to:
  /// **'이름 바꾸기'**
  String get stocksWatchGroupRenameItem;

  /// No description provided for @stocksWatchGroupMore.
  ///
  /// In ko, this message translates to:
  /// **'{name} 더보기'**
  String stocksWatchGroupMore(String name);

  /// No description provided for @stocksWatchGroupEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 담은 종목이 없어요'**
  String get stocksWatchGroupEmpty;

  /// No description provided for @stocksWatchGroupDeleteConfirmCount.
  ///
  /// In ko, this message translates to:
  /// **'\"{name}\" 그룹과 담긴 종목 {count}개가 함께 삭제돼요. 삭제한 그룹은 되돌릴 수 없어요.'**
  String stocksWatchGroupDeleteConfirmCount(String name, int count);

  /// No description provided for @stocksWatchGroupDeleteConfirmEmpty.
  ///
  /// In ko, this message translates to:
  /// **'\"{name}\" 그룹을 삭제해요. 삭제한 그룹은 되돌릴 수 없어요.'**
  String stocksWatchGroupDeleteConfirmEmpty(String name);

  /// No description provided for @stocksWatchPickGroup.
  ///
  /// In ko, this message translates to:
  /// **'담을 관심 그룹'**
  String get stocksWatchPickGroup;

  /// No description provided for @stocksWatchToggleLabel.
  ///
  /// In ko, this message translates to:
  /// **'관심 등록'**
  String get stocksWatchToggleLabel;

  /// No description provided for @stocksPortfolioTitle.
  ///
  /// In ko, this message translates to:
  /// **'포트폴리오 구성'**
  String get stocksPortfolioTitle;

  /// No description provided for @stocksPortfolioSub.
  ///
  /// In ko, this message translates to:
  /// **'종목별 비중 · 통화별 합계'**
  String get stocksPortfolioSub;

  /// No description provided for @stocksPortfolioCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}종목'**
  String stocksPortfolioCount(int count);

  /// No description provided for @stocksPortfolioNeedsFx.
  ///
  /// In ko, this message translates to:
  /// **'환율을 불러오면 구성 비중을 볼 수 있어요'**
  String get stocksPortfolioNeedsFx;

  /// No description provided for @stocksFailInvest.
  ///
  /// In ko, this message translates to:
  /// **'내 투자를 불러오지 못했어요'**
  String get stocksFailInvest;

  /// No description provided for @stocksFailMarket.
  ///
  /// In ko, this message translates to:
  /// **'시장 정보를 불러오지 못했어요'**
  String get stocksFailMarket;

  /// No description provided for @stocksFailHoldings.
  ///
  /// In ko, this message translates to:
  /// **'보유 종목을 불러오지 못했어요'**
  String get stocksFailHoldings;

  /// No description provided for @stocksFailWatch.
  ///
  /// In ko, this message translates to:
  /// **'관심 종목을 불러오지 못했어요'**
  String get stocksFailWatch;

  /// No description provided for @stocksFailRanking.
  ///
  /// In ko, this message translates to:
  /// **'순위를 불러오지 못했어요'**
  String get stocksFailRanking;

  /// No description provided for @stocksFailDaily.
  ///
  /// In ko, this message translates to:
  /// **'일별 시세를 불러오지 못했어요'**
  String get stocksFailDaily;

  /// No description provided for @stocksFailSearch.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과를 불러오지 못했어요'**
  String get stocksFailSearch;

  /// No description provided for @stocksFailDesc.
  ///
  /// In ko, this message translates to:
  /// **'잠시 뒤 다시 시도해주세요.'**
  String get stocksFailDesc;

  /// No description provided for @stocksSourceNotice.
  ///
  /// In ko, this message translates to:
  /// **'토스증권 Open API · 시세 지연 표시'**
  String get stocksSourceNotice;

  /// No description provided for @stocksDisclaimerLine1.
  ///
  /// In ko, this message translates to:
  /// **'토스증권 Open API 연동 시 실시간 호가·체결가가 반영돼요.'**
  String get stocksDisclaimerLine1;

  /// No description provided for @stocksDisclaimerLine2.
  ///
  /// In ko, this message translates to:
  /// **'시세는 투자 참고용이에요. 실제 주문은 약관에 동의한 뒤 할 수 있어요.'**
  String get stocksDisclaimerLine2;

  /// No description provided for @stocksDailyVolume.
  ///
  /// In ko, this message translates to:
  /// **'거래량 {volume}'**
  String stocksDailyVolume(String volume);

  /// No description provided for @stocksFxBasis.
  ///
  /// In ko, this message translates to:
  /// **'매매기준율'**
  String get stocksFxBasis;

  /// No description provided for @stocksDailyDate.
  ///
  /// In ko, this message translates to:
  /// **'{month}월 {day}일'**
  String stocksDailyDate(int month, int day);

  /// No description provided for @stocksTradeSoon.
  ///
  /// In ko, this message translates to:
  /// **'주문은 곧 열려요.'**
  String get stocksTradeSoon;

  /// No description provided for @stocksFailOrderbook.
  ///
  /// In ko, this message translates to:
  /// **'호가를 불러오지 못했어요'**
  String get stocksFailOrderbook;

  /// No description provided for @stocksFailTrades.
  ///
  /// In ko, this message translates to:
  /// **'체결 내역을 불러오지 못했어요'**
  String get stocksFailTrades;

  /// No description provided for @stocksFailInfo.
  ///
  /// In ko, this message translates to:
  /// **'기본 정보를 불러오지 못했어요'**
  String get stocksFailInfo;

  /// No description provided for @stocksRowAsk.
  ///
  /// In ko, this message translates to:
  /// **'매도 {price}, 잔량 {qty}'**
  String stocksRowAsk(String price, String qty);

  /// No description provided for @stocksRowBid.
  ///
  /// In ko, this message translates to:
  /// **'매수 {price}, 잔량 {qty}'**
  String stocksRowBid(String price, String qty);

  /// No description provided for @stocksRowTrade.
  ///
  /// In ko, this message translates to:
  /// **'{time}, {price}, 수량 {qty}'**
  String stocksRowTrade(String time, String price, String qty);

  /// No description provided for @stocksOrderbookTableName.
  ///
  /// In ko, this message translates to:
  /// **'호가 표'**
  String get stocksOrderbookTableName;

  /// No description provided for @stocksTradesTableName.
  ///
  /// In ko, this message translates to:
  /// **'체결 표'**
  String get stocksTradesTableName;

  /// No description provided for @stocksConnectEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'증권사를 연결해주세요'**
  String get stocksConnectEmptyTitle;

  /// No description provided for @stocksConnectEmptyDesc.
  ///
  /// In ko, this message translates to:
  /// **'토스증권 · 나무증권 키를 연결하면 시세와 보유 종목을 볼 수 있어요.'**
  String get stocksConnectEmptyDesc;

  /// No description provided for @stocksConnectEmptyAction.
  ///
  /// In ko, this message translates to:
  /// **'증권사 연결하기'**
  String get stocksConnectEmptyAction;

  /// No description provided for @stockMarketKrEtc.
  ///
  /// In ko, this message translates to:
  /// **'국내 기타'**
  String get stockMarketKrEtc;

  /// No description provided for @stockMarketUsEtc.
  ///
  /// In ko, this message translates to:
  /// **'미국 기타'**
  String get stockMarketUsEtc;

  /// No description provided for @stocksFailPrice.
  ///
  /// In ko, this message translates to:
  /// **'시세를 불러오지 못했어요'**
  String get stocksFailPrice;

  /// No description provided for @namuKrwTotal.
  ///
  /// In ko, this message translates to:
  /// **'원화 환산 합계'**
  String get namuKrwTotal;

  /// No description provided for @namuFxApplied.
  ///
  /// In ko, this message translates to:
  /// **'환율 {rate} 적용'**
  String namuFxApplied(String rate);

  /// No description provided for @namuDomesticValue.
  ///
  /// In ko, this message translates to:
  /// **'국내 평가금액'**
  String get namuDomesticValue;

  /// No description provided for @namuOverseasValue.
  ///
  /// In ko, this message translates to:
  /// **'해외 평가금액'**
  String get namuOverseasValue;

  /// No description provided for @namuCountSplit.
  ///
  /// In ko, this message translates to:
  /// **'국내 {kr} · 해외 {us}'**
  String namuCountSplit(int kr, int us);

  /// No description provided for @namuFilterAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get namuFilterAll;

  /// No description provided for @namuFilterAria.
  ///
  /// In ko, this message translates to:
  /// **'보유 시장'**
  String get namuFilterAria;

  /// No description provided for @namuFilterEmpty.
  ///
  /// In ko, this message translates to:
  /// **'이 시장에 보유 종목이 없어요'**
  String get namuFilterEmpty;

  /// No description provided for @namuFailDesc.
  ///
  /// In ko, this message translates to:
  /// **'계좌가 없거나 조회 권한이 없을 수 있어요.'**
  String get namuFailDesc;

  /// No description provided for @namuDataNotice.
  ///
  /// In ko, this message translates to:
  /// **'나무증권 Open API · 시세 지연 표시'**
  String get namuDataNotice;

  /// No description provided for @namuDonutNeedsFx.
  ///
  /// In ko, this message translates to:
  /// **'환율을 못 받아 구성 비중을 낼 수 없어요'**
  String get namuDonutNeedsFx;

  /// No description provided for @stocksBuyingPowerKrw.
  ///
  /// In ko, this message translates to:
  /// **'주문 가능 · 원화'**
  String get stocksBuyingPowerKrw;

  /// No description provided for @stocksBuyingPowerUsd.
  ///
  /// In ko, this message translates to:
  /// **'주문 가능 · 달러'**
  String get stocksBuyingPowerUsd;

  /// No description provided for @namuDepositUsd.
  ///
  /// In ko, this message translates to:
  /// **'예수금 · 달러'**
  String get namuDepositUsd;

  /// No description provided for @stocksTodayQuote.
  ///
  /// In ko, this message translates to:
  /// **'오늘 시세'**
  String get stocksTodayQuote;

  /// No description provided for @stocksOpenPrice.
  ///
  /// In ko, this message translates to:
  /// **'시가'**
  String get stocksOpenPrice;

  /// No description provided for @stocksHighPrice.
  ///
  /// In ko, this message translates to:
  /// **'고가'**
  String get stocksHighPrice;

  /// No description provided for @stocksLowPrice.
  ///
  /// In ko, this message translates to:
  /// **'저가'**
  String get stocksLowPrice;

  /// No description provided for @stocksInvestorTitle.
  ///
  /// In ko, this message translates to:
  /// **'투자자별 매매동향'**
  String get stocksInvestorTitle;

  /// No description provided for @stocksInvestorUnit.
  ///
  /// In ko, this message translates to:
  /// **'▲ 순매수 · ▼ 순매도 · 주'**
  String get stocksInvestorUnit;

  /// No description provided for @stocksInvestorIndividual.
  ///
  /// In ko, this message translates to:
  /// **'개인'**
  String get stocksInvestorIndividual;

  /// No description provided for @stocksInvestorForeigner.
  ///
  /// In ko, this message translates to:
  /// **'외국인'**
  String get stocksInvestorForeigner;

  /// No description provided for @stocksInvestorInstitution.
  ///
  /// In ko, this message translates to:
  /// **'기관'**
  String get stocksInvestorInstitution;

  /// No description provided for @stocksInvestorEmpty.
  ///
  /// In ko, this message translates to:
  /// **'집계된 매매동향이 없어요'**
  String get stocksInvestorEmpty;

  /// No description provided for @stocksSector.
  ///
  /// In ko, this message translates to:
  /// **'업종'**
  String get stocksSector;

  /// No description provided for @stocksListedShares.
  ///
  /// In ko, this message translates to:
  /// **'상장주식수'**
  String get stocksListedShares;

  /// No description provided for @stocksWarningInvestmentAttention.
  ///
  /// In ko, this message translates to:
  /// **'투자유의'**
  String get stocksWarningInvestmentAttention;

  /// No description provided for @stocksMarketPre.
  ///
  /// In ko, this message translates to:
  /// **'프리마켓'**
  String get stocksMarketPre;

  /// No description provided for @stocksMarketAfter.
  ///
  /// In ko, this message translates to:
  /// **'애프터마켓'**
  String get stocksMarketAfter;

  /// No description provided for @stocksMarketDaytime.
  ///
  /// In ko, this message translates to:
  /// **'주간거래'**
  String get stocksMarketDaytime;

  /// No description provided for @stocksMarketSinglePrice.
  ///
  /// In ko, this message translates to:
  /// **'단일가'**
  String get stocksMarketSinglePrice;

  /// No description provided for @stocksMarketHalted.
  ///
  /// In ko, this message translates to:
  /// **'일시 마감'**
  String get stocksMarketHalted;

  /// No description provided for @stocksMarketBeforeOpen.
  ///
  /// In ko, this message translates to:
  /// **'개장 전'**
  String get stocksMarketBeforeOpen;

  /// No description provided for @stocksFailQuote.
  ///
  /// In ko, this message translates to:
  /// **'시세를 불러오지 못했어요'**
  String get stocksFailQuote;

  /// No description provided for @stocksFailToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘 시세를 불러오지 못했어요'**
  String get stocksFailToday;

  /// No description provided for @stocksFailInvestor.
  ///
  /// In ko, this message translates to:
  /// **'투자자별 매매동향을 불러오지 못했어요'**
  String get stocksFailInvestor;

  /// No description provided for @namuFxUnavailableShort.
  ///
  /// In ko, this message translates to:
  /// **'환율 없음'**
  String get namuFxUnavailableShort;

  /// No description provided for @recDefaultTitle.
  ///
  /// In ko, this message translates to:
  /// **'반복 거래'**
  String get recDefaultTitle;

  /// No description provided for @recGroupTitle.
  ///
  /// In ko, this message translates to:
  /// **'{kind} {count}개'**
  String recGroupTitle(String kind, int count);

  /// No description provided for @recMonthLead.
  ///
  /// In ko, this message translates to:
  /// **'이번 달'**
  String get recMonthLead;

  /// No description provided for @recRowNext.
  ///
  /// In ko, this message translates to:
  /// **'다음 {date}'**
  String recRowNext(String date);

  /// No description provided for @recRowPaused.
  ///
  /// In ko, this message translates to:
  /// **'쉬는 중'**
  String get recRowPaused;

  /// No description provided for @recRowFinished.
  ///
  /// In ko, this message translates to:
  /// **'끝남'**
  String get recRowFinished;

  /// No description provided for @recCycleDaily.
  ///
  /// In ko, this message translates to:
  /// **'매일'**
  String get recCycleDaily;

  /// No description provided for @recCycleWeekly.
  ///
  /// In ko, this message translates to:
  /// **'매주 {day}요일'**
  String recCycleWeekly(String day);

  /// No description provided for @recCycleMonthly.
  ///
  /// In ko, this message translates to:
  /// **'매월 {day}일'**
  String recCycleMonthly(int day);

  /// No description provided for @recCycleYearly.
  ///
  /// In ko, this message translates to:
  /// **'매년 {month}월 {day}일'**
  String recCycleYearly(int month, int day);

  /// No description provided for @recCountOf.
  ///
  /// In ko, this message translates to:
  /// **'{total}번 중 {done}번'**
  String recCountOf(int total, int done);

  /// No description provided for @recUntilMonth.
  ///
  /// In ko, this message translates to:
  /// **'{year}년 {month}월까지'**
  String recUntilMonth(int year, int month);

  /// No description provided for @recDowShort0.
  ///
  /// In ko, this message translates to:
  /// **'일'**
  String get recDowShort0;

  /// No description provided for @recDowShort1.
  ///
  /// In ko, this message translates to:
  /// **'월'**
  String get recDowShort1;

  /// No description provided for @recDowShort2.
  ///
  /// In ko, this message translates to:
  /// **'화'**
  String get recDowShort2;

  /// No description provided for @recDowShort3.
  ///
  /// In ko, this message translates to:
  /// **'수'**
  String get recDowShort3;

  /// No description provided for @recDowShort4.
  ///
  /// In ko, this message translates to:
  /// **'목'**
  String get recDowShort4;

  /// No description provided for @recDowShort5.
  ///
  /// In ko, this message translates to:
  /// **'금'**
  String get recDowShort5;

  /// No description provided for @recDowShort6.
  ///
  /// In ko, this message translates to:
  /// **'토'**
  String get recDowShort6;

  /// No description provided for @recDowLong0.
  ///
  /// In ko, this message translates to:
  /// **'일요일'**
  String get recDowLong0;

  /// No description provided for @recDowLong1.
  ///
  /// In ko, this message translates to:
  /// **'월요일'**
  String get recDowLong1;

  /// No description provided for @recDowLong2.
  ///
  /// In ko, this message translates to:
  /// **'화요일'**
  String get recDowLong2;

  /// No description provided for @recDowLong3.
  ///
  /// In ko, this message translates to:
  /// **'수요일'**
  String get recDowLong3;

  /// No description provided for @recDowLong4.
  ///
  /// In ko, this message translates to:
  /// **'목요일'**
  String get recDowLong4;

  /// No description provided for @recDowLong5.
  ///
  /// In ko, this message translates to:
  /// **'금요일'**
  String get recDowLong5;

  /// No description provided for @recDowLong6.
  ///
  /// In ko, this message translates to:
  /// **'토요일'**
  String get recDowLong6;

  /// No description provided for @recDetailTitle.
  ///
  /// In ko, this message translates to:
  /// **'반복 거래 상세'**
  String get recDetailTitle;

  /// No description provided for @recEndSentenceNone.
  ///
  /// In ko, this message translates to:
  /// **'끝나는 날 없이 반복해요'**
  String get recEndSentenceNone;

  /// No description provided for @recEndSentenceDate.
  ///
  /// In ko, this message translates to:
  /// **'{date}까지 반복해요'**
  String recEndSentenceDate(String date);

  /// No description provided for @recEndSentenceCount.
  ///
  /// In ko, this message translates to:
  /// **'{total}번 반복해요({done}번 했어요)'**
  String recEndSentenceCount(int total, int done);

  /// No description provided for @recSentenceLead.
  ///
  /// In ko, this message translates to:
  /// **'{cycle}, {end}.'**
  String recSentenceLead(String cycle, String end);

  /// No description provided for @recSentenceNextPre.
  ///
  /// In ko, this message translates to:
  /// **'다음은 '**
  String get recSentenceNextPre;

  /// No description provided for @recSentenceNextPost.
  ///
  /// In ko, this message translates to:
  /// **'예요.'**
  String get recSentenceNextPost;

  /// No description provided for @recSentencePausedPre.
  ///
  /// In ko, this message translates to:
  /// **'지금은 쉬고 있어요. 다시 켜면 쉬는 동안 지난 회차는 건너뛰고 '**
  String get recSentencePausedPre;

  /// No description provided for @recSentencePausedBold.
  ///
  /// In ko, this message translates to:
  /// **'다음 회차부터'**
  String get recSentencePausedBold;

  /// No description provided for @recSentencePausedPost.
  ///
  /// In ko, this message translates to:
  /// **' 기록해요.'**
  String get recSentencePausedPost;

  /// No description provided for @recSentenceFinished.
  ///
  /// In ko, this message translates to:
  /// **'정한 회차를 모두 기록했어요.'**
  String get recSentenceFinished;

  /// No description provided for @recOn.
  ///
  /// In ko, this message translates to:
  /// **'켬'**
  String get recOn;

  /// No description provided for @recOff.
  ///
  /// In ko, this message translates to:
  /// **'끔'**
  String get recOff;

  /// No description provided for @recOnWithCount.
  ///
  /// In ko, this message translates to:
  /// **'켬 · {count}번 기록'**
  String recOnWithCount(int count);

  /// No description provided for @recAutoLog.
  ///
  /// In ko, this message translates to:
  /// **'자동 기록'**
  String get recAutoLog;

  /// No description provided for @recAutoLogSub.
  ///
  /// In ko, this message translates to:
  /// **'그날 거래를 저절로 추가해요.'**
  String get recAutoLogSub;

  /// No description provided for @recNotifyDayBefore.
  ///
  /// In ko, this message translates to:
  /// **'하루 전 알림'**
  String get recNotifyDayBefore;

  /// No description provided for @recNotifyDayBeforeSub.
  ///
  /// In ko, this message translates to:
  /// **'예정일 전날 알려 드려요.'**
  String get recNotifyDayBeforeSub;

  /// No description provided for @recNextDatesTitle.
  ///
  /// In ko, this message translates to:
  /// **'다음 예정일'**
  String get recNextDatesTitle;

  /// No description provided for @recNextDatesLine.
  ///
  /// In ko, this message translates to:
  /// **'다음 예정일 — {dates}'**
  String recNextDatesLine(String dates);

  /// No description provided for @recPause.
  ///
  /// In ko, this message translates to:
  /// **'일시정지'**
  String get recPause;

  /// No description provided for @recResume.
  ///
  /// In ko, this message translates to:
  /// **'다시 켜기'**
  String get recResume;

  /// No description provided for @recPausedBadge.
  ///
  /// In ko, this message translates to:
  /// **'일시정지'**
  String get recPausedBadge;

  /// No description provided for @recMoreOf.
  ///
  /// In ko, this message translates to:
  /// **'{name} 더보기'**
  String recMoreOf(String name);

  /// No description provided for @recToastPaused.
  ///
  /// In ko, this message translates to:
  /// **'{name} 반복을 멈췄어요'**
  String recToastPaused(String name);

  /// No description provided for @recToastResumed.
  ///
  /// In ko, this message translates to:
  /// **'{name} 반복을 다시 켰어요'**
  String recToastResumed(String name);

  /// No description provided for @recToastDeleted.
  ///
  /// In ko, this message translates to:
  /// **'{name} 반복 설정을 삭제했어요'**
  String recToastDeleted(String name);

  /// No description provided for @recPauseFailed.
  ///
  /// In ko, this message translates to:
  /// **'반복을 멈추지 못했어요.'**
  String get recPauseFailed;

  /// No description provided for @recResumeFailed.
  ///
  /// In ko, this message translates to:
  /// **'반복을 다시 켜지 못했어요.'**
  String get recResumeFailed;

  /// No description provided for @recDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'반복 설정을 삭제하지 못했어요.'**
  String get recDeleteFailed;

  /// No description provided for @recLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'반복 거래를 불러오지 못했어요'**
  String get recLoadFailed;

  /// No description provided for @recEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'반복 거래가 없어요'**
  String get recEmptyTitle;

  /// No description provided for @recEmptyDesc.
  ///
  /// In ko, this message translates to:
  /// **'구독 · 월세처럼 정해진 날 오가는 돈을 등록해 두면 그날 저절로 기록해요.'**
  String get recEmptyDesc;

  /// No description provided for @recAddButton.
  ///
  /// In ko, this message translates to:
  /// **'반복 거래 추가'**
  String get recAddButton;

  /// No description provided for @recTypeLabel.
  ///
  /// In ko, this message translates to:
  /// **'유형'**
  String get recTypeLabel;

  /// No description provided for @recMerchantPlaceholderExpense.
  ///
  /// In ko, this message translates to:
  /// **'예: 관리비'**
  String get recMerchantPlaceholderExpense;

  /// No description provided for @recMerchantPlaceholderIncome.
  ///
  /// In ko, this message translates to:
  /// **'예: 월급'**
  String get recMerchantPlaceholderIncome;

  /// No description provided for @recMemoPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'메모를 적어주세요'**
  String get recMemoPlaceholder;

  /// No description provided for @recRepeatRow.
  ///
  /// In ko, this message translates to:
  /// **'반복'**
  String get recRepeatRow;

  /// No description provided for @recStartDay.
  ///
  /// In ko, this message translates to:
  /// **'시작일'**
  String get recStartDay;

  /// No description provided for @recEndRow.
  ///
  /// In ko, this message translates to:
  /// **'끝'**
  String get recEndRow;

  /// No description provided for @recEndDay.
  ///
  /// In ko, this message translates to:
  /// **'끝나는 날'**
  String get recEndDay;

  /// No description provided for @recNoneValue.
  ///
  /// In ko, this message translates to:
  /// **'없음'**
  String get recNoneValue;

  /// No description provided for @recEndNoneRadio.
  ///
  /// In ko, this message translates to:
  /// **'끝 없음'**
  String get recEndNoneRadio;

  /// No description provided for @recEndUntilDate.
  ///
  /// In ko, this message translates to:
  /// **'날짜까지'**
  String get recEndUntilDate;

  /// No description provided for @recEndCountTimes.
  ///
  /// In ko, this message translates to:
  /// **'횟수만큼'**
  String get recEndCountTimes;

  /// No description provided for @recEndCountLabel.
  ///
  /// In ko, this message translates to:
  /// **'횟수'**
  String get recEndCountLabel;

  /// No description provided for @recTimesUnit.
  ///
  /// In ko, this message translates to:
  /// **'번'**
  String get recTimesUnit;

  /// No description provided for @recEndValueDate.
  ///
  /// In ko, this message translates to:
  /// **'{date}까지'**
  String recEndValueDate(String date);

  /// No description provided for @recEndValueCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}번'**
  String recEndValueCount(int count);

  /// No description provided for @recOnWhichDay.
  ///
  /// In ko, this message translates to:
  /// **'며칠에'**
  String get recOnWhichDay;

  /// No description provided for @recOnWhichWeekday.
  ///
  /// In ko, this message translates to:
  /// **'무슨 요일에'**
  String get recOnWhichWeekday;

  /// No description provided for @recAtWhatTime.
  ///
  /// In ko, this message translates to:
  /// **'몇 시에'**
  String get recAtWhatTime;

  /// No description provided for @recYearlyHint.
  ///
  /// In ko, this message translates to:
  /// **'시작일과 같은 날에 해마다 기록해요.'**
  String get recYearlyHint;

  /// No description provided for @recMonthDayNote.
  ///
  /// In ko, this message translates to:
  /// **'{day}일이 없는 달은 그달 마지막 날에 기록해요.'**
  String recMonthDayNote(int day);

  /// No description provided for @recDayN.
  ///
  /// In ko, this message translates to:
  /// **'{day}일'**
  String recDayN(int day);

  /// No description provided for @recFreqDaily.
  ///
  /// In ko, this message translates to:
  /// **'매일'**
  String get recFreqDaily;

  /// No description provided for @recFreqWeekly.
  ///
  /// In ko, this message translates to:
  /// **'매주'**
  String get recFreqWeekly;

  /// No description provided for @recFreqMonthly.
  ///
  /// In ko, this message translates to:
  /// **'매월'**
  String get recFreqMonthly;

  /// No description provided for @recFreqYearly.
  ///
  /// In ko, this message translates to:
  /// **'매년'**
  String get recFreqYearly;

  /// No description provided for @recErrAmount.
  ///
  /// In ko, this message translates to:
  /// **'금액을 입력해주세요.'**
  String get recErrAmount;

  /// No description provided for @recErrCategory.
  ///
  /// In ko, this message translates to:
  /// **'카테고리를 골라주세요.'**
  String get recErrCategory;

  /// No description provided for @recErrFrom.
  ///
  /// In ko, this message translates to:
  /// **'보내는 계좌를 골라주세요.'**
  String get recErrFrom;

  /// No description provided for @recErrTo.
  ///
  /// In ko, this message translates to:
  /// **'받는 계좌를 골라주세요.'**
  String get recErrTo;

  /// No description provided for @recErrEndBeforeStart.
  ///
  /// In ko, this message translates to:
  /// **'끝나는 날이 시작일보다 빨라요.'**
  String get recErrEndBeforeStart;

  /// No description provided for @recErrCountMax.
  ///
  /// In ko, this message translates to:
  /// **'{max}번까지 입력할 수 있어요.'**
  String recErrCountMax(int max);

  /// No description provided for @recErrInterestTooBig.
  ///
  /// In ko, this message translates to:
  /// **'이자는 금액보다 클 수 없어요.'**
  String get recErrInterestTooBig;

  /// No description provided for @recSelectOf.
  ///
  /// In ko, this message translates to:
  /// **'{field} 선택'**
  String recSelectOf(String field);

  /// No description provided for @recNoneOf.
  ///
  /// In ko, this message translates to:
  /// **'{field} 없음'**
  String recNoneOf(String field);

  /// No description provided for @recTransferFrom.
  ///
  /// In ko, this message translates to:
  /// **'보내는 계좌'**
  String get recTransferFrom;

  /// No description provided for @recTransferTo.
  ///
  /// In ko, this message translates to:
  /// **'받는 계좌'**
  String get recTransferTo;

  /// No description provided for @recErrCountMin.
  ///
  /// In ko, this message translates to:
  /// **'1번 이상 입력해주세요.'**
  String get recErrCountMin;

  /// No description provided for @recSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'저장하지 못했어요. 잠시 뒤 다시 시도해주세요.'**
  String get recSaveFailed;

  /// No description provided for @recNoAssets.
  ///
  /// In ko, this message translates to:
  /// **'고를 수 있는 계좌가 없어요.'**
  String get recNoAssets;

  /// No description provided for @recNoCategoryOfKind.
  ///
  /// In ko, this message translates to:
  /// **'이 종류의 카테고리가 없어요.'**
  String get recNoCategoryOfKind;

  /// No description provided for @recFromAccount.
  ///
  /// In ko, this message translates to:
  /// **'출금 계좌'**
  String get recFromAccount;

  /// No description provided for @recDepositAccount.
  ///
  /// In ko, this message translates to:
  /// **'입금 계좌'**
  String get recDepositAccount;

  /// No description provided for @recIncomeMethod.
  ///
  /// In ko, this message translates to:
  /// **'수입 방식'**
  String get recIncomeMethod;

  /// No description provided for @recClearValue.
  ///
  /// In ko, this message translates to:
  /// **'값 지우기'**
  String get recClearValue;

  /// No description provided for @expDetailMore.
  ///
  /// In ko, this message translates to:
  /// **'더 하기'**
  String get expDetailMore;

  /// No description provided for @expSplitValue.
  ///
  /// In ko, this message translates to:
  /// **'{count}개로 나눔'**
  String expSplitValue(int count);

  /// No description provided for @expSplitHeader.
  ///
  /// In ko, this message translates to:
  /// **'내역 분할 {count}개'**
  String expSplitHeader(int count);

  /// No description provided for @expMerchantMonth.
  ///
  /// In ko, this message translates to:
  /// **'이 가맹점 이번 달'**
  String get expMerchantMonth;

  /// No description provided for @expRecentOnly.
  ///
  /// In ko, this message translates to:
  /// **'최근 5건만 보여요'**
  String get expRecentOnly;

  /// No description provided for @expLinked.
  ///
  /// In ko, this message translates to:
  /// **'연결됨'**
  String get expLinked;

  /// No description provided for @expSplitLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'나눈 내역을 불러오지 못했어요'**
  String get expSplitLoadFailed;

  /// No description provided for @expSplitLoadFailedDesc.
  ///
  /// In ko, this message translates to:
  /// **'잠시 뒤 다시 시도해주세요.'**
  String get expSplitLoadFailedDesc;

  /// 거래 상세 "이 가맹점 이번 달" 구역을 처음 받지 못했을 때 Result Section 제목 — 웹 query.failedNamed(name: txDetail.historyName)
  ///
  /// In ko, this message translates to:
  /// **'이전 거래 정보를 불러오지 못했어요'**
  String get txHistoryLoadFailed;

  /// No description provided for @expRefundDateToday.
  ///
  /// In ko, this message translates to:
  /// **'{date} · 오늘'**
  String expRefundDateToday(String date);

  /// No description provided for @expRefundDateHint.
  ///
  /// In ko, this message translates to:
  /// **'거래한 날({date})부터 오늘까지 고를 수 있어요.'**
  String expRefundDateHint(String date);

  /// No description provided for @expRefundFailed.
  ///
  /// In ko, this message translates to:
  /// **'환불하지 못했어요. 잠시 뒤에 다시 시도해주세요.'**
  String get expRefundFailed;

  /// No description provided for @expRefundCancelFailed.
  ///
  /// In ko, this message translates to:
  /// **'환불을 취소하지 못했어요.'**
  String get expRefundCancelFailed;

  /// No description provided for @expTxDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'거래를 삭제하지 못했어요.'**
  String get expTxDeleteFailed;

  /// No description provided for @transferDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'이체를 삭제하지 못했어요.'**
  String get transferDeleteFailed;

  /// No description provided for @transferDetailTitle.
  ///
  /// In ko, this message translates to:
  /// **'이체 상세'**
  String get transferDetailTitle;

  /// No description provided for @transferFromLabel.
  ///
  /// In ko, this message translates to:
  /// **'보내는 계좌'**
  String get transferFromLabel;

  /// No description provided for @transferToLabel.
  ///
  /// In ko, this message translates to:
  /// **'받는 계좌'**
  String get transferToLabel;

  /// No description provided for @txfStepMeta.
  ///
  /// In ko, this message translates to:
  /// **'{current} / {total}단계'**
  String txfStepMeta(String current, String total);

  /// No description provided for @txfTypeGroup.
  ///
  /// In ko, this message translates to:
  /// **'거래 종류'**
  String get txfTypeGroup;

  /// No description provided for @txfEntryRequired.
  ///
  /// In ko, this message translates to:
  /// **'금액을 입력해주세요.'**
  String get txfEntryRequired;

  /// No description provided for @txfAmountTooLarge.
  ///
  /// In ko, this message translates to:
  /// **'금액은 100억원까지 입력할 수 있어요.'**
  String get txfAmountTooLarge;

  /// No description provided for @txfCurrencyChip.
  ///
  /// In ko, this message translates to:
  /// **'통화, {code}'**
  String txfCurrencyChip(String code);

  /// No description provided for @txfPresetsTitle.
  ///
  /// In ko, this message translates to:
  /// **'프리셋'**
  String get txfPresetsTitle;

  /// No description provided for @txfPresetApplied.
  ///
  /// In ko, this message translates to:
  /// **'{name} 적용됨'**
  String txfPresetApplied(String name);

  /// No description provided for @txfNoPresets.
  ///
  /// In ko, this message translates to:
  /// **'저장된 프리셋이 없어요. 값을 넣고 “현재 입력값 저장” 을 누르면 만들어져요.'**
  String get txfNoPresets;

  /// No description provided for @txfPresetLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'프리셋을 불러오지 못했어요.'**
  String get txfPresetLoadFailed;

  /// No description provided for @txfEmptyPresetHint.
  ///
  /// In ko, this message translates to:
  /// **'“{name}” 프리셋은 금액이 비어 있어요. 금액을 넣고 [다음]을 눌러주세요.'**
  String txfEmptyPresetHint(String name);

  /// No description provided for @txfReceiveAmount.
  ///
  /// In ko, this message translates to:
  /// **'받는 금액 약 {amount}'**
  String txfReceiveAmount(String amount);

  /// No description provided for @txfPresetAllTitle.
  ///
  /// In ko, this message translates to:
  /// **'프리셋 고르기'**
  String get txfPresetAllTitle;

  /// No description provided for @txfShowAll.
  ///
  /// In ko, this message translates to:
  /// **'모두 보기'**
  String get txfShowAll;

  /// No description provided for @txfNone.
  ///
  /// In ko, this message translates to:
  /// **'없음'**
  String get txfNone;

  /// No description provided for @txfNoAccountOption.
  ///
  /// In ko, this message translates to:
  /// **'계좌·카드 없음'**
  String get txfNoAccountOption;

  /// No description provided for @txfNoMethodOption.
  ///
  /// In ko, this message translates to:
  /// **'결제 수단 없음'**
  String get txfNoMethodOption;

  /// No description provided for @txfErrCategory.
  ///
  /// In ko, this message translates to:
  /// **'카테고리를 골라주세요.'**
  String get txfErrCategory;

  /// No description provided for @txfErrFrom.
  ///
  /// In ko, this message translates to:
  /// **'보내는 계좌를 골라주세요.'**
  String get txfErrFrom;

  /// No description provided for @txfErrTo.
  ///
  /// In ko, this message translates to:
  /// **'받는 계좌를 골라주세요.'**
  String get txfErrTo;

  /// No description provided for @txfErrFx.
  ///
  /// In ko, this message translates to:
  /// **'환율을 입력하거나 원화 금액을 넣어주세요.'**
  String get txfErrFx;

  /// No description provided for @txfErrInterest.
  ///
  /// In ko, this message translates to:
  /// **'이자는 금액보다 클 수 없어요.'**
  String get txfErrInterest;

  /// No description provided for @txfSplitsLoading.
  ///
  /// In ko, this message translates to:
  /// **'나눈 내역을 불러오는 중이에요. 잠시 뒤 다시 눌러주세요.'**
  String get txfSplitsLoading;

  /// No description provided for @txfSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'저장하지 못했어요. 잠시 뒤 다시 시도해주세요.'**
  String get txfSaveFailed;

  /// No description provided for @txfCategoryLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'카테고리를 불러오지 못했어요'**
  String get txfCategoryLoadFailed;

  /// No description provided for @txfAssetLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'계좌·카드를 불러오지 못했어요'**
  String get txfAssetLoadFailed;

  /// No description provided for @txfNoCategoryOfType.
  ///
  /// In ko, this message translates to:
  /// **'이 종류의 카테고리가 없어요.'**
  String get txfNoCategoryOfType;

  /// No description provided for @txfNoPickableAsset.
  ///
  /// In ko, this message translates to:
  /// **'이 결제 수단에 맞는 계좌·카드가 없어요.'**
  String get txfNoPickableAsset;

  /// No description provided for @txfFxHint.
  ///
  /// In ko, this message translates to:
  /// **'{local} {code} × {rate} = {krw}원'**
  String txfFxHint(String local, String code, String rate, String krw);

  /// No description provided for @txfKrwAmount.
  ///
  /// In ko, this message translates to:
  /// **'원화 금액'**
  String get txfKrwAmount;

  /// No description provided for @txfInstallmentValue.
  ///
  /// In ko, this message translates to:
  /// **'{months}개월 · 매달 약 {amount}원'**
  String txfInstallmentValue(String months, String amount);

  /// No description provided for @txfSplitMismatchTitle.
  ///
  /// In ko, this message translates to:
  /// **'나눈 내역과 금액이 달라요'**
  String get txfSplitMismatchTitle;

  /// No description provided for @txfSplitMismatchBody.
  ///
  /// In ko, this message translates to:
  /// **'새 총액 {total}원 · 나눈 합계 {sum}원 — {diffText}'**
  String txfSplitMismatchBody(String total, String sum, String diffText);

  /// No description provided for @txfSplitOver.
  ///
  /// In ko, this message translates to:
  /// **'{diff}원 넘쳐요.'**
  String txfSplitOver(String diff);

  /// No description provided for @txfSplitShort.
  ///
  /// In ko, this message translates to:
  /// **'{diff}원 모자라요.'**
  String txfSplitShort(String diff);

  /// No description provided for @txfMatchSplits.
  ///
  /// In ko, this message translates to:
  /// **'나눈 내역 맞추기'**
  String get txfMatchSplits;

  /// No description provided for @txfSaveSplitAndSave.
  ///
  /// In ko, this message translates to:
  /// **'나눈 내역 맞추고 저장'**
  String get txfSaveSplitAndSave;

  /// No description provided for @txfSmsStepTitle.
  ///
  /// In ko, this message translates to:
  /// **'결제 문자 붙여넣기'**
  String get txfSmsStepTitle;

  /// No description provided for @txfSmsHelp.
  ///
  /// In ko, this message translates to:
  /// **'카드사에서 온 결제 문자를 그대로 붙여넣어주세요. 읽은 금액 · 가맹점 · 시각이 칸에 채워져요.'**
  String get txfSmsHelp;

  /// No description provided for @txfPresetAmountEmpty.
  ///
  /// In ko, this message translates to:
  /// **'비워 둠'**
  String get txfPresetAmountEmpty;

  /// No description provided for @txfPresetAmountHint.
  ///
  /// In ko, this message translates to:
  /// **'비워 두면 불러올 때 금액을 직접 넣어요.'**
  String get txfPresetAmountHint;

  /// No description provided for @txfPresetNameRequired.
  ///
  /// In ko, this message translates to:
  /// **'프리셋 이름을 입력해주세요.'**
  String get txfPresetNameRequired;

  /// No description provided for @txfPresetNeedParties.
  ///
  /// In ko, this message translates to:
  /// **'보내는 계좌와 받는 계좌를 먼저 골라주세요.'**
  String get txfPresetNeedParties;

  /// No description provided for @txfPresetNeedCategory.
  ///
  /// In ko, this message translates to:
  /// **'카테고리를 먼저 골라주세요.'**
  String get txfPresetNeedCategory;

  /// No description provided for @txfPresetNoMerchant.
  ///
  /// In ko, this message translates to:
  /// **'내역 없음'**
  String get txfPresetNoMerchant;

  /// No description provided for @txfPresetSaved.
  ///
  /// In ko, this message translates to:
  /// **'{name} 프리셋을 저장했어요.'**
  String txfPresetSaved(String name);

  /// No description provided for @txfPresetNameTooLong.
  ///
  /// In ko, this message translates to:
  /// **'이름은 12자 이내로 입력해주세요.'**
  String get txfPresetNameTooLong;

  /// No description provided for @txfMemoStepTitle.
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get txfMemoStepTitle;

  /// No description provided for @txfTimeTitle.
  ///
  /// In ko, this message translates to:
  /// **'시각'**
  String get txfTimeTitle;

  /// No description provided for @txfNoCategory.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 없음'**
  String get txfNoCategory;

  /// No description provided for @txfNoDepositAccount.
  ///
  /// In ko, this message translates to:
  /// **'입금 계좌 없음'**
  String get txfNoDepositAccount;

  /// No description provided for @txfNoIncomeMethod.
  ///
  /// In ko, this message translates to:
  /// **'수입 방식 없음'**
  String get txfNoIncomeMethod;

  /// No description provided for @txfSelectFrom.
  ///
  /// In ko, this message translates to:
  /// **'보내는 계좌 선택'**
  String get txfSelectFrom;

  /// No description provided for @txfSelectTo.
  ///
  /// In ko, this message translates to:
  /// **'받는 계좌 선택'**
  String get txfSelectTo;

  /// No description provided for @txfDeletedAsset.
  ///
  /// In ko, this message translates to:
  /// **'지운 계좌'**
  String get txfDeletedAsset;

  /// No description provided for @txfDeletedCategory.
  ///
  /// In ko, this message translates to:
  /// **'지운 카테고리'**
  String get txfDeletedCategory;

  /// No description provided for @expSplitSourceNote.
  ///
  /// In ko, this message translates to:
  /// **'원 거래'**
  String get expSplitSourceNote;

  /// No description provided for @expSplitOldTotal.
  ///
  /// In ko, this message translates to:
  /// **'옛 총액 {amount}'**
  String expSplitOldTotal(String amount);

  /// No description provided for @expSplitItemsHeader.
  ///
  /// In ko, this message translates to:
  /// **'나눈 내역 {count}개'**
  String expSplitItemsHeader(int count);

  /// No description provided for @expSplitItemTitle.
  ///
  /// In ko, this message translates to:
  /// **'항목 {n}'**
  String expSplitItemTitle(int n);

  /// No description provided for @expSplitAddItem.
  ///
  /// In ko, this message translates to:
  /// **'항목 추가'**
  String get expSplitAddItem;

  /// No description provided for @expSplitDropItem.
  ///
  /// In ko, this message translates to:
  /// **'이 항목 지우기'**
  String get expSplitDropItem;

  /// No description provided for @expSplitItemName.
  ///
  /// In ko, this message translates to:
  /// **'이름'**
  String get expSplitItemName;

  /// No description provided for @expSplitItemNamePh.
  ///
  /// In ko, this message translates to:
  /// **'항목 이름'**
  String get expSplitItemNamePh;

  /// No description provided for @expSplitItemHelp.
  ///
  /// In ko, this message translates to:
  /// **'나머지 항목 합 {rest} · 총액 {total}'**
  String expSplitItemHelp(String rest, String total);

  /// No description provided for @expSplitRemaining.
  ///
  /// In ko, this message translates to:
  /// **'남은 금액'**
  String get expSplitRemaining;

  /// No description provided for @expSplitShortBy.
  ///
  /// In ko, this message translates to:
  /// **'{amount} 모자라요'**
  String expSplitShortBy(String amount);

  /// No description provided for @expSplitOverBy.
  ///
  /// In ko, this message translates to:
  /// **'{amount} 넘쳐요'**
  String expSplitOverBy(String amount);

  /// No description provided for @expSplitReconcileTitle.
  ///
  /// In ko, this message translates to:
  /// **'총액이 바뀌어 나눈 금액을 맞춰야 해요'**
  String get expSplitReconcileTitle;

  /// No description provided for @expSplitReconcileShort.
  ///
  /// In ko, this message translates to:
  /// **'나눈 합계 {sum} · 새 총액 {total} — {diff} 모자라요.'**
  String expSplitReconcileShort(String sum, String total, String diff);

  /// No description provided for @expSplitReconcileOver.
  ///
  /// In ko, this message translates to:
  /// **'나눈 합계 {sum} · 새 총액 {total} — {diff} 넘쳐요.'**
  String expSplitReconcileOver(String sum, String total, String diff);

  /// No description provided for @expSplitActProportional.
  ///
  /// In ko, this message translates to:
  /// **'비례 배분'**
  String get expSplitActProportional;

  /// No description provided for @expSplitActLargest.
  ///
  /// In ko, this message translates to:
  /// **'큰 항목 반영'**
  String get expSplitActLargest;

  /// No description provided for @expSplitActAdjust.
  ///
  /// In ko, this message translates to:
  /// **'조정 항목'**
  String get expSplitActAdjust;

  /// No description provided for @expSplitErrRemain.
  ///
  /// In ko, this message translates to:
  /// **'남은 금액을 0원으로 맞춰주세요.'**
  String get expSplitErrRemain;

  /// No description provided for @expSplitErrCount.
  ///
  /// In ko, this message translates to:
  /// **'항목을 둘 이상 넣어주세요.'**
  String get expSplitErrCount;

  /// No description provided for @expSplitRemoveAll.
  ///
  /// In ko, this message translates to:
  /// **'내역 분할 풀기'**
  String get expSplitRemoveAll;

  /// No description provided for @expSplitRemoveTitle.
  ///
  /// In ko, this message translates to:
  /// **'내역 분할을 풀까요?'**
  String get expSplitRemoveTitle;

  /// No description provided for @expSplitRemoveBody.
  ///
  /// In ko, this message translates to:
  /// **'나눈 항목이 모두 지워지고 거래 하나로 돌아가요.'**
  String get expSplitRemoveBody;

  /// No description provided for @expSplitRemoveAction.
  ///
  /// In ko, this message translates to:
  /// **'풀기'**
  String get expSplitRemoveAction;

  /// No description provided for @expSplitRemoveFailed.
  ///
  /// In ko, this message translates to:
  /// **'내역 분할을 풀지 못했어요.'**
  String get expSplitRemoveFailed;

  /// No description provided for @expSplitSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'저장하지 못했어요. 잠시 뒤 다시 시도해주세요.'**
  String get expSplitSaveFailed;

  /// No description provided for @dutchMeIncludeTitle.
  ///
  /// In ko, this message translates to:
  /// **'나도 포함해서 나누기'**
  String get dutchMeIncludeTitle;

  /// No description provided for @dutchMeIncludeOn.
  ///
  /// In ko, this message translates to:
  /// **'내 몫도 계산돼요'**
  String get dutchMeIncludeOn;

  /// No description provided for @dutchParticipantsLabel.
  ///
  /// In ko, this message translates to:
  /// **'참여자 {count}명'**
  String dutchParticipantsLabel(int count);

  /// No description provided for @dutchChipRemove.
  ///
  /// In ko, this message translates to:
  /// **'{name} 빼기'**
  String dutchChipRemove(String name);

  /// No description provided for @dutchNameEmptyErr.
  ///
  /// In ko, this message translates to:
  /// **'이름을 입력해주세요.'**
  String get dutchNameEmptyErr;

  /// No description provided for @dutchMethodHeader.
  ///
  /// In ko, this message translates to:
  /// **'나누는 법'**
  String get dutchMethodHeader;

  /// No description provided for @dutchEqualSub.
  ///
  /// In ko, this message translates to:
  /// **'똑같이'**
  String get dutchEqualSub;

  /// No description provided for @dutchRatioSub.
  ///
  /// In ko, this message translates to:
  /// **'사람마다 몫 수'**
  String get dutchRatioSub;

  /// No description provided for @dutchSharesHeader.
  ///
  /// In ko, this message translates to:
  /// **'몫'**
  String get dutchSharesHeader;

  /// No description provided for @dutchSharesTotal.
  ///
  /// In ko, this message translates to:
  /// **'합계 {amount}'**
  String dutchSharesTotal(String amount);

  /// No description provided for @dutchPayerShort.
  ///
  /// In ko, this message translates to:
  /// **'결제'**
  String get dutchPayerShort;

  /// No description provided for @dutchRemainIncluded.
  ///
  /// In ko, this message translates to:
  /// **'남는 {amount} 포함'**
  String dutchRemainIncluded(String amount);

  /// No description provided for @dutchShareUnit.
  ///
  /// In ko, this message translates to:
  /// **'몫'**
  String get dutchShareUnit;

  /// No description provided for @dutchNoteTitle.
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get dutchNoteTitle;

  /// No description provided for @dutchNotePh.
  ///
  /// In ko, this message translates to:
  /// **'정산에 같이 남길 한마디'**
  String get dutchNotePh;

  /// No description provided for @dutchPerPersonMe.
  ///
  /// In ko, this message translates to:
  /// **'{amount} · {rest}은 나'**
  String dutchPerPersonMe(String amount, String rest);

  /// No description provided for @dutchErrNoOthers.
  ///
  /// In ko, this message translates to:
  /// **'함께 나눌 사람을 넣어주세요.'**
  String get dutchErrNoOthers;

  /// No description provided for @dutchSharesShortErr.
  ///
  /// In ko, this message translates to:
  /// **'몫을 합하면 {amount} 모자라요.'**
  String dutchSharesShortErr(String amount);

  /// No description provided for @dutchSharesOverErr.
  ///
  /// In ko, this message translates to:
  /// **'몫을 합하면 {amount} 넘쳐요.'**
  String dutchSharesOverErr(String amount);

  /// No description provided for @dutchSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'정산을 만들지 못했어요. 잠시 뒤 다시 시도해주세요.'**
  String get dutchSaveFailed;

  /// No description provided for @expSplitErrRow.
  ///
  /// In ko, this message translates to:
  /// **'모든 항목에 카테고리와 0원보다 큰 금액을 넣어주세요.'**
  String get expSplitErrRow;

  /// No description provided for @dutchErrRatio.
  ///
  /// In ko, this message translates to:
  /// **'몫은 0보다 큰 수로 넣어주세요.'**
  String get dutchErrRatio;

  /// No description provided for @dutchErrCustomEmpty.
  ///
  /// In ko, this message translates to:
  /// **'모든 참여자의 금액을 넣어주세요.'**
  String get dutchErrCustomEmpty;

  /// No description provided for @expRecurringOpenFailed.
  ///
  /// In ko, this message translates to:
  /// **'반복 설정을 열지 못했어요.'**
  String get expRecurringOpenFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
