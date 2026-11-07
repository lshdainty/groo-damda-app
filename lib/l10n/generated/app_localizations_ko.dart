// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '그루 담다';

  @override
  String get actionSave => '저장';

  @override
  String get actionCancel => '취소';

  @override
  String get actionDelete => '삭제';

  @override
  String get actionEdit => '수정';

  @override
  String get actionCreate => '생성';

  @override
  String get actionConfirm => '확인';

  @override
  String get actionClose => '닫기';

  @override
  String get actionRetry => '다시 시도';

  @override
  String get queryRefreshFailed => '새로 고치지 못했어요.';

  @override
  String get queryReferenceFailed => '일부 정보를 불러오지 못했어요.';

  @override
  String get saveUnconfirmed => '저장됐는지 확인하지 못했어요. 목록에서 확인해주세요.';

  @override
  String get payUnconfirmed => '결제됐는지 확인하지 못했어요. 청구 내역에서 확인해주세요.';

  @override
  String get stocksStaleLastPrice => '보이는 값은 마지막으로 받은 시세예요.';

  @override
  String get stocksStaleLastBalance => '보이는 값은 시세가 아닌 마지막 잔액이에요.';

  @override
  String get securitiesLeaveBody => '작성한 내용이 사라져요.';

  @override
  String get withdrawUnconfirmed => '해지됐는지 확인하지 못했어요. 앱을 다시 열어 확인해주세요.';

  @override
  String get unconfirmedSave => '저장됐는지 확인하지 못했어요.';

  @override
  String get unconfirmedDelete => '삭제됐는지 확인하지 못했어요.';

  @override
  String get unconfirmedDisconnect => '해제됐는지 확인하지 못했어요.';

  @override
  String get unconfirmedProcess => '처리됐는지 확인하지 못했어요.';

  @override
  String get unconfirmedToggle => '바뀌었는지 확인하지 못했어요.';

  @override
  String get unconfirmedConnect => '연결됐는지 확인하지 못했어요.';

  @override
  String get actionApply => '적용';

  @override
  String get actionReset => '초기화';

  @override
  String get actionSearch => '검색';

  @override
  String get actionLoading => '로딩 중...';

  @override
  String get actionDone => '완료';

  @override
  String get actionBack => '뒤로';

  @override
  String get actionNext => '다음';

  @override
  String get pickDate => '날짜 선택';

  @override
  String get pickTime => '시간 선택';

  @override
  String get searchResultsEmpty => '검색 결과가 없어요';

  @override
  String get unlockTitle => '금액 보기 인증';

  @override
  String get unlockBody => '금액을 다시 보려면 비밀번호로 본인 확인이 필요해요.';

  @override
  String get unlockBiometricReason => '금액을 다시 보려면 본인 확인이 필요해요.';

  @override
  String get unlockPasswordLabel => '비밀번호';

  @override
  String get unlockMismatch => '비밀번호가 일치하지 않아요.';

  @override
  String get appLockTitle => '앱 잠금';

  @override
  String get appLockRowDesc => '앱을 열 때 Face ID · 지문으로 본인 확인을 해요.';

  @override
  String get appLockLockedDesc => '잠금을 해제하려면 본인 확인이 필요해요.';

  @override
  String get appLockUnlockAction => '잠금 해제';

  @override
  String get appLockPromptReason => '앱을 열려면 본인 확인이 필요해요.';

  @override
  String get appLockUnavailable =>
      '이 기기에서는 생체 인증을 쓸 수 없어요. 기기에 화면 잠금을 설정하면 쓸 수 있어요.';

  @override
  String get stateEmpty => '표시할 항목이 없어요';

  @override
  String nameTooLong(int max) {
    return '이름은 $max자 이내로 입력해주세요.';
  }

  @override
  String get languageKorean => '한국어';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSystem => '시스템';

  @override
  String get settingsLanguage => '언어';

  @override
  String get navDashboard => '대시보드';

  @override
  String get navTodo => '할 일';

  @override
  String get navCalendar => '캘린더';

  @override
  String get navMemo => '메모';

  @override
  String get navTimer => '타이머';

  @override
  String get navExpense => '가계부';

  @override
  String get navAsset => '자산';

  @override
  String get navDutchPay => '더치페이';

  @override
  String get navPostit => '포스트잇';

  @override
  String get navGroup => '그룹';

  @override
  String get navSettings => '설정';

  @override
  String get navMore => '전체';

  @override
  String get navMenu => '메뉴';

  @override
  String get navHome => '홈';

  @override
  String get navStats => '통계';

  @override
  String get navSearch => '검색';

  @override
  String get navNotifications => '알림';

  @override
  String get navBudget => '예산';

  @override
  String get navRecurring => '반복 거래 관리';

  @override
  String get navCategories => '카테고리';

  @override
  String get navPresets => '프리셋';

  @override
  String get navCards => '카드 관리';

  @override
  String get navSavingGoals => '저축 목표';

  @override
  String get navExport => '내보내기';

  @override
  String get navLogout => '로그아웃';

  @override
  String get navChangePassword => '비밀번호 변경';

  @override
  String get notiTitle => '알림';

  @override
  String get notiEmpty => '아직 알림이 없어요';

  @override
  String get notiMarkAllRead => '모두 읽음';

  @override
  String notiUnreadHead(String count) {
    return '읽지 않은 알림 $count개';
  }

  @override
  String get notiLoadFailed => '알림을 불러오지 못했어요';

  @override
  String get notiLoadFailedDesc => '잠시 뒤 다시 시도해주세요.';

  @override
  String get notiDeleteFailed => '알림을 삭제하지 못했어요.';

  @override
  String get notiUnreadMark => '안 읽음';

  @override
  String get notiMarkReadFailed => '알림을 읽음으로 바꾸지 못했어요.';

  @override
  String get notiMarkAllFailed => '알림을 모두 읽음으로 바꾸지 못했어요.';

  @override
  String get notiPrefsSaveFailed => '알림 설정을 저장하지 못했어요. 잠시 뒤 다시 시도해주세요.';

  @override
  String get notiSettingsLoadFailedDesc => '잠시 뒤 다시 시도해주세요.';

  @override
  String get notiThresholdLabel => '경고로 표시할 사용률';

  @override
  String get notiThresholdDesc =>
      '이 값을 넘으면 경고로 표시되고 알림을 받아요. 100%를 넘으면 초과 알림이 따로 와요.';

  @override
  String notiMore(String title) {
    return '$title 더보기';
  }

  @override
  String get notiDeleteTitle => '알림 삭제';

  @override
  String get notiDeleteDescription => '삭제한 알림은 되돌릴 수 없어요.';

  @override
  String get notiTypeEventReminder => '일정 알림';

  @override
  String get notiTypeBudgetAlert => '예산 알림';

  @override
  String get notiTypeTodoReminder => '할 일 알림';

  @override
  String get notiTypeSystem => '시스템 알림';

  @override
  String get notiConnectionLost => '알림 연결이 끊어졌어요';

  @override
  String get notiConnectionRestored => '알림 연결이 다시 이어졌어요';

  @override
  String get notiNew => '새 알림';

  @override
  String get assetTitle => '자산 관리';

  @override
  String get assetSummaryTotalBalance => '총 자산';

  @override
  String get assetCreateFirst => '첫 번째 자산을 등록해보세요';

  @override
  String get assetAdd => '자산 추가';

  @override
  String get assetEdit => '자산 수정';

  @override
  String get assetTransferAdd => '이체 추가';

  @override
  String get assetFee => '수수료';

  @override
  String get assetTypeBankAccount => '입출금';

  @override
  String get assetTypeSavings => '예적금';

  @override
  String get assetTypeCash => '현금';

  @override
  String get assetTypeCreditCard => '신용카드';

  @override
  String get assetTypeCheckCard => '체크카드';

  @override
  String get assetTypeInvestment => '투자';

  @override
  String get assetTypeLoan => '대출';

  @override
  String get assetGroupAccount => '계좌 · 예금';

  @override
  String get assetGroupCard => '카드';

  @override
  String get assetGroupInvestment => '투자';

  @override
  String get assetGroupDebt => '대출';

  @override
  String get assetCatAccount => '계좌';

  @override
  String get assetSubtypeInstallment => '적금';

  @override
  String get assetSubtypeDeposit => '예금';

  @override
  String get assetSubtypeOverdraft => '마이너스 통장';

  @override
  String get assetEmptyState => '아직 등록된 자산이 없어요';

  @override
  String get assetEmptyHint => '설정 → 계좌 · 카드 관리에서 추가할 수 있어요.';

  @override
  String get assetSummaryColAccounts => '계좌 · 예금';

  @override
  String get assetSummaryColCards => '카드값';

  @override
  String get assetTotalNetWorth => '총 순자산';

  @override
  String get assetVsLastMonth => '지난달 대비';

  @override
  String get assetGroupEmpty => '등록된 항목이 없어요.';

  @override
  String assetPaymentDayInfo(int day) {
    return '$day일 결제';
  }

  @override
  String get assetExcludedFromTotal => '총액 제외';

  @override
  String get assetAmountHiddenBadge => '금액 숨김';

  @override
  String get assetHideThisAmount => '금액 가리기';

  @override
  String get assetHideThisAmountDesc => '이 자산의 금액만 가려요. 합계는 그대로 보여요.';

  @override
  String get assetManageTitle => '계좌 · 카드 관리';

  @override
  String get assetManageAdd => '추가';

  @override
  String get assetManageEmptyHint => '[추가]를 눌러 첫 계좌나 카드를 등록해보세요.';

  @override
  String get assetManageLoadFailed => '계좌 · 카드를 불러오지 못했어요';

  @override
  String assetHoldingsCount(int count) {
    return '보유 $count종목';
  }

  @override
  String get assetIncludeInTotal => '전체 자산 합계에 포함';

  @override
  String get assetIncludeInTotalDesc => '순자산 · 총자산 계산에 반영돼요.';

  @override
  String get assetTrendLoadError => '추이를 불러오지 못했어요';

  @override
  String get assetTrendEmpty => '추이 데이터가 없어요.';

  @override
  String get assetNetWorth => '순자산';

  @override
  String assetCardLimitName(String name) {
    return '$name 한도';
  }

  @override
  String assetChartNetWorthName(String amount) {
    return '최근 12개월 순자산 추이 — 이번 달 $amount';
  }

  @override
  String get assetChartTableMonth => '달';

  @override
  String get assetChartTableWeek => '주';

  @override
  String get assetTxLoadFailed => '내역을 불러오지 못했어요';

  @override
  String get assetTradesLoadFailed => '거래 기록 정보를 불러오지 못했어요';

  @override
  String get assetMonthTx => '이번 달 내역';

  @override
  String get assetHoldingLinkedPending => '시세 연동 대기';

  @override
  String get assetPeriodAria => '추이 기간';

  @override
  String get assetLoadFailedSummary => '순자산을 불러오지 못했어요';

  @override
  String get assetLoadFailedTrend => '순자산 추이를 불러오지 못했어요';

  @override
  String get assetLoadFailedAssets => '자산을 불러오지 못했어요';

  @override
  String get assetLoadFailedGoals => '저축 목표를 불러오지 못했어요';

  @override
  String get assetEmptyCta => '계좌 · 카드 관리로 가기';

  @override
  String get assetAccountDelete => '계좌 삭제';

  @override
  String assetAccountDeleteConfirm(String name) {
    return '\"$name\"을(를) 목록에서 삭제해요. 연결된 거래 내역은 그대로 남아요. 삭제한 자산은 되돌릴 수 없어요.';
  }

  @override
  String get assetActionFailed => '실패';

  @override
  String get assetDeleteFailed => '삭제 실패';

  @override
  String get assetInstitutionBrand => '기관';

  @override
  String get assetBankSearchHint => '기관 이름 검색';

  @override
  String get assetNickname => '별칭';

  @override
  String get assetNicknamePlaceholder => '예: 생활비 통장';

  @override
  String get assetNicknameRequired => '별칭을 입력해주세요.';

  @override
  String get assetNicknameDuplicate => '같은 별칭의 자산이 이미 있어요.';

  @override
  String get assetBalanceLabel => '잔액';

  @override
  String get assetBalanceEditHint =>
      '잔액을 바꾸면 지금 이전의 내역은 이 잔액에 이미 들어 있는 것으로 보고 이후 내역만 더해져요.';

  @override
  String get assetOverdraftUsedLabel => '사용 중인 금액';

  @override
  String get assetLoanRemainingLabel => '남은 대출 금액';

  @override
  String get assetOverdraftLimitLabel => '약정 한도';

  @override
  String get assetOverdraftHint => '쓴 만큼을 양수로 넣어주세요. 빚으로 계산돼요.';

  @override
  String get assetLoanHint => '아직 갚지 않은 금액을 적어주세요.';

  @override
  String get assetCurrency => '통화';

  @override
  String get assetExchangeRate => '환율';

  @override
  String assetExchangeRateHint(String code) {
    return '$code 1당 원화';
  }

  @override
  String get assetExchangeRateDesc => '외화 잔액 · 예수금을 원화로 바꿀 때 써요.';

  @override
  String get assetExchangeRateRequired => '환율을 입력해주세요.';

  @override
  String get assetMemoPlaceholder => '예: 계좌번호 뒷자리 1234';

  @override
  String get assetCreditLimitLabel => '신용한도';

  @override
  String get assetPaymentDayLabel => '결제일';

  @override
  String get assetPaymentDaySelect => '결제일 선택';

  @override
  String get assetPaymentDay => '결제일';

  @override
  String get assetLinkedAccountLabel => '연결 계좌';

  @override
  String get assetLinkedAccountSelect => '연결 계좌 선택';

  @override
  String get assetLinkedAccountHint => '이 카드로 결제하면 이 계좌에서 바로 빠져나가요.';

  @override
  String get assetPaymentAccountLabel => '결제 출금계좌';

  @override
  String get assetNoBankAccounts => '입출금 계좌가 없어요';

  @override
  String get assetPaymentAccountSelect => '결제 출금계좌 선택';

  @override
  String get assetPaymentAccountHint => '결제일에 이 계좌에서 청구액이 빠져요.';

  @override
  String get assetCardDelete => '카드 삭제';

  @override
  String assetCardDeleteConfirm(String name) {
    return '\"$name\"을(를) 목록에서 삭제해요. 연결된 거래 내역은 그대로 남아요. 삭제한 자산은 되돌릴 수 없어요.';
  }

  @override
  String get assetCardProduct => '카드 상품';

  @override
  String get assetIncludeDiscontinued => '단종 카드도 보기';

  @override
  String get assetCardSearchHint => '카드 이름 검색';

  @override
  String get assetCardNicknamePlaceholder => '예: 생활 카드';

  @override
  String get assetCurrentUsage => '이전 미결제 사용액';

  @override
  String get assetCurrentUsageHint => '아직 결제되지 않은 사용액을 적어주세요.';

  @override
  String assetOutstandingNow(String amount) {
    return '지금 미결제 잔액 $amount';
  }

  @override
  String get assetCarryoverLocked => '결제가 끝나 고칠 수 없어요.';

  @override
  String assetDueCarryoverLabel(String date) {
    return '$date에 결제될 금액';
  }

  @override
  String get assetDueCarryoverHint =>
      '카드사 앱에 \'결제 예정 금액\'으로 보이는 금액이에요. 그날 결제계좌에서 빠져요.';

  @override
  String get assetCarryoverAfterLabel => '그 뒤 쓴 금액';

  @override
  String assetCarryoverAfterHint(String date) {
    return '지난 청구 뒤로 쓴 금액이에요. $date에 결제돼요.';
  }

  @override
  String get assetCarryoverAfterHintNoDate => '지난 청구 뒤로 쓴 금액이에요.';

  @override
  String assetPaymentDayChangeConfirm(int month, String date) {
    return '바꾼 결제일은 다음 회차부터 적용돼요. $month월분은 $date에 결제돼요.';
  }

  @override
  String get assetNewCard => '새 카드';

  @override
  String get assetAnnualFee => '연회비';

  @override
  String get assetCardShortCredit => '신용';

  @override
  String get assetCardShortCheck => '체크';

  @override
  String get assetDiscontinued => '단종';

  @override
  String get assetInvestDelete => '투자 삭제';

  @override
  String assetInvestDeleteConfirm(String name) {
    return '\"$name\"을(를) 목록에서 삭제해요. 연결된 거래 내역은 그대로 남아요. 삭제한 자산은 되돌릴 수 없어요.';
  }

  @override
  String get assetBrokerExchange => '증권사 · 거래소';

  @override
  String get assetInvestSearchHint => '증권사 이름 검색';

  @override
  String get assetProductPlaceholder => '예: 연금저축, 금 보유분';

  @override
  String get assetValuation => '평가액 (원)';

  @override
  String get assetNewInvestment => '새 투자 상품';

  @override
  String get assetCryptoExchange => '가상자산거래소';

  @override
  String get assetCategoryCommercialBank => '시중은행';

  @override
  String get assetCategoryInternetBank => '인터넷은행';

  @override
  String get assetCategoryLocalBank => '지방은행';

  @override
  String get assetCategorySpecialBank => '특수은행';

  @override
  String get assetCategorySavingsInstitution => '저축기관';

  @override
  String get assetCategoryForeignBank => '외국계';

  @override
  String get assetCategoryOther => '기타';

  @override
  String get assetCategoryBrokerage => '증권사';

  @override
  String get assetCategoryCommodityExchange => '상품거래소';

  @override
  String get assetCategoryCryptoExchange => '가상자산거래소';

  @override
  String get assetCardDetail => '카드 상세';

  @override
  String get assetInvestDetail => '투자 상세';

  @override
  String get assetAccountDetail => '계좌 상세';

  @override
  String get assetHideAmount => '금액 가리기';

  @override
  String get assetPeriod3m => '3개월';

  @override
  String get assetPeriod6m => '6개월';

  @override
  String get assetPeriod1y => '1년';

  @override
  String assetWeeksCount(int weeks) {
    return '$weeks주';
  }

  @override
  String get assetTrendKindUsage => '사용 추이';

  @override
  String get assetTrendKindValuation => '평가액 추이';

  @override
  String get assetTrendKindBalance => '잔액 추이';

  @override
  String assetTrendRecent(String weeks, String kind) {
    return '최근 $weeks $kind';
  }

  @override
  String get assetValueLabelCard => '이번 달 결제 예정';

  @override
  String get assetValueLabelCheckCard => '이번 달 사용액';

  @override
  String get assetCheckCardMonthLabel => '이번 달 사용';

  @override
  String assetMonthTxCount(int count) {
    return '이번 달 내역 · $count';
  }

  @override
  String get assetValuationShort => '평가액';

  @override
  String get assetSeriesUsage => '사용';

  @override
  String assetRecentTxCount(int count) {
    return '최근 거래 · $count';
  }

  @override
  String get assetViewAll => '전체 보기';

  @override
  String get assetTossLinkStarted => '토스 시세 연동을 시작했어요';

  @override
  String get assetLinkFailed => '연결 실패';

  @override
  String get assetTossUnlinked => '토스 연결을 해제했어요';

  @override
  String get assetUnlinkFailed => '해제 실패';

  @override
  String get assetQtyUpdated => '보유 수량을 수정했어요';

  @override
  String get assetUpdateFailed => '수정 실패';

  @override
  String get assetTossLinked => '토스 연동 중';

  @override
  String get assetHoldings => '보유 종목';

  @override
  String get tradeTitle => '매수 · 매도';

  @override
  String get tradeBuy => '매수';

  @override
  String get tradeSell => '매도';

  @override
  String get tradeBought => '매수를 기록했어요';

  @override
  String get tradeSold => '매도를 기록했어요';

  @override
  String get tradeHolding => '종목';

  @override
  String get tradeHoldingType => '종목 유형';

  @override
  String get tradeNoHolding => '보유 종목이 없어요';

  @override
  String get tradeAddNewHolding => '새 종목 사기';

  @override
  String get tradePickExisting => '보유 종목에서 고르기';

  @override
  String get tradeNewHoldingPlaceholder => '종목명을 적어주세요';

  @override
  String get tradeQuantity => '수량';

  @override
  String get tradeAmount => '거래대금 (원)';

  @override
  String get tradeAmountHelp => '수수료를 뺀 금액이에요. 수수료는 아래에 따로 적어주세요.';

  @override
  String get tradeFee => '수수료 · 세금 (원)';

  @override
  String get tradeMemo => '메모';

  @override
  String get tradeMemoPlaceholder => '선택 입력';

  @override
  String get tradeSettlement => '결제 계좌';

  @override
  String get tradeSettlementCash => '증권계좌 예수금';

  @override
  String get tradeSettlementCashHelp => '증권계좌 예수금에서 결제해요. 모자라면 예수금이 마이너스로 남아요.';

  @override
  String get tradeSettlementAccountHelp => '예수금이 모자라면 이 계좌에서 부족분만큼 자동으로 이체돼요.';

  @override
  String get tradeSettlementDelta => '결제 계좌 변동';

  @override
  String get tradeCashAfter => '거래 후 예수금';

  @override
  String get tradeRealizedPreview => '실현손익';

  @override
  String tradeFundingNotice(String amount) {
    return '예수금이 모자라 결제 계좌에서 $amount만큼 옮겨요';
  }

  @override
  String get tradeInsufficientCash => '예수금이 마이너스가 돼요. 그대로 기록돼요.';

  @override
  String get tradeInsufficientQty => '보유 수량보다 많이 팔 수 없어요.';

  @override
  String get tradeQtyRequired => '수량을 넣어주세요.';

  @override
  String get tradeAmountRequired => '거래대금을 넣어주세요.';

  @override
  String get tradePreview => '거래 후 미리보기';

  @override
  String get tradeHistory => '거래 기록';

  @override
  String get tradeDeleted => '거래를 취소했어요.';

  @override
  String get tradeDeleteTitle => '거래 취소';

  @override
  String get tradeDeleteConfirm => '이 거래를 취소하시겠어요? 예수금과 보유 수량이 거래 전으로 돌아가요.';

  @override
  String get assetDetailTitle => '자산 상세';

  @override
  String get assetNotFoundTitle => '자산을 찾을 수 없어요';

  @override
  String get assetDetailDeleteFailed => '자산을 삭제하지 못했어요.';

  @override
  String get assetNotFoundDesc => '지웠거나 없는 자산이에요.';

  @override
  String get assetNotFoundAction => '자산으로';

  @override
  String get assetLoadFailTitle => '자산을 불러오지 못했어요';

  @override
  String assetMoreOf(String name) {
    return '$name 더보기';
  }

  @override
  String get tradeDetailTitle => '거래 기록';

  @override
  String get tradeKind => '종류';

  @override
  String get tradeHoldingLabel => '종목';

  @override
  String get tradeUnitPrice => '단가';

  @override
  String get tradeAmountLabel => '거래대금';

  @override
  String get tradeFeeLabel => '수수료 · 세금';

  @override
  String get tradeDateTime => '거래 일시';

  @override
  String tradeDeleteConfirmTarget(
    String date,
    String name,
    String qty,
    String kind,
  ) {
    return '$date $name $qty $kind 거래를 취소할까요? 예수금과 보유 수량이 거래 전으로 돌아가요.';
  }

  @override
  String get tradeCancelFailed => '거래를 취소하지 못했어요.';

  @override
  String get holdingTypeStock => '주식';

  @override
  String get holdingTypeGold => '금';

  @override
  String get holdingTypeCrypto => '코인';

  @override
  String get holdingAvgPrice => '평단가';

  @override
  String holdingAvgPriceInline(String avg) {
    return '평단가 $avg';
  }

  @override
  String get holdingTotalCost => '매수원가';

  @override
  String tradeHeldSummary(String qty, String avg) {
    return '보유 $qty · 평단가 $avg';
  }

  @override
  String get assetCashBalance => '예수금';

  @override
  String get assetHoldingKrwInputHint => '원화로 입력해요';

  @override
  String fxApproxKrw(String amount) {
    return '약 $amount';
  }

  @override
  String get assetHoldingBalance => '평가금액';

  @override
  String assetHoldingsSummaryUnknown(int count) {
    return '$count종목 · —';
  }

  @override
  String assetHoldingsSummary(int count, String amount) {
    return '$count종목 · $amount원';
  }

  @override
  String assetHoldingRep(String name, int count) {
    return '$name 외 $count종목';
  }

  @override
  String get assetNoHoldings => '보유 종목 없음';

  @override
  String get assetHoldingLinkedBadge => '연동';

  @override
  String assetHoldingLinkedSub(String price) {
    return '현재가 $price × 수량';
  }

  @override
  String get assetHoldingManualSub => '평가액 직접 입력';

  @override
  String assetHoldingLinkedDetail(String qty, String price) {
    return '$qty주 · 현재가 $price 연동';
  }

  @override
  String get assetHoldingManualDetail => '직접 입력';

  @override
  String get assetHoldingsEmptyEdit =>
      '검색으로 보유 종목을 더할 수 있어요. 연동 종목은 현재가 × 수량으로 평가액이 자동 계산돼요.';

  @override
  String get assetHoldingsEmptyManual =>
      '위 버튼으로 보유분을 더할 수 있어요. 시세 연동이 없어 평가액은 직접 입력해요.';

  @override
  String get assetHoldingsEmptyDetail => '보유 종목이 없어요';

  @override
  String get assetHoldingSearchHint => '종목 이름 검색';

  @override
  String assetHoldingAddManual(String name) {
    return '\"$name\" 직접 추가 — 평가액 입력';
  }

  @override
  String get assetSharesUnit => '주';

  @override
  String get assetHoldingTypeStock => '주식';

  @override
  String get assetHoldingTypeGold => '금';

  @override
  String get assetHoldingTypeCrypto => '코인';

  @override
  String get assetHoldingAddGold => '금 추가';

  @override
  String get assetHoldingAddCrypto => '코인 추가';

  @override
  String get assetHoldingUnitGram => 'g';

  @override
  String get assetHoldingUnitCount => '개';

  @override
  String get assetHoldingNamePlaceholder => '항목 이름';

  @override
  String assetHoldingQtyUnit(String qty, String unit) {
    return '$qty$unit';
  }

  @override
  String assetInvestHoldingsSub(int count) {
    return '투자 · 보유 $count종목';
  }

  @override
  String assetTodayChange(String amount) {
    return '오늘 $amount원';
  }

  @override
  String assetSharesCount(String n) {
    return '$n주';
  }

  @override
  String get assetHoldingQty => '보유 수량';

  @override
  String get assetEditQty => '수량 수정';

  @override
  String get assetUnlink => '연결 해제';

  @override
  String get assetTossRealtimeTitle => '토스 시세로 실시간 평가';

  @override
  String get assetTapToChange => '변경하려면 탭';

  @override
  String get stockSecurityTypeIndex => '지수';

  @override
  String get stockSecurityTypeWarrant => '워런트';

  @override
  String get stockMarketKospi => '코스피';

  @override
  String get stockMarketKosdaq => '코스닥';

  @override
  String get stockMarketKonex => '코넥스';

  @override
  String get stockMarketKrxIdx => 'KRX 지수';

  @override
  String get stockMarketNas => '나스닥';

  @override
  String get stockMarketNys => '뉴욕';

  @override
  String get stockMarketAms => '아멕스';

  @override
  String get stockMarketShs => '상해';

  @override
  String get stockMarketShi => '상해지수';

  @override
  String get stockMarketSzs => '심천';

  @override
  String get stockMarketSzi => '심천지수';

  @override
  String get stockMarketTse => '도쿄';

  @override
  String get stockMarketHks => '홍콩';

  @override
  String get stockMarketHnx => '하노이';

  @override
  String get stockMarketHsx => '호치민';

  @override
  String assetLinkByCode(String code) {
    return '「$code」 코드로 연결';
  }

  @override
  String get assetLink => '연결';

  @override
  String get assetChartNoData => '표시할 데이터가 없어요';

  @override
  String get assetNoLinkedTx => '연결된 거래 내역이 없어요.';

  @override
  String get assetTxFallback => '거래';

  @override
  String assetPayConfirmMessage(String amount) {
    return '결제 예정액 $amount을 지금 결제할까요?';
  }

  @override
  String assetPayConfirmDateSuffix(String date) {
    return ' $date 결제 예정분이에요.';
  }

  @override
  String get assetCancelPayment => '결제 취소';

  @override
  String assetCancelPaymentConfirm(String amount, String date) {
    return '$date에 낸 $amount원을 되돌려요. 통장 잔액과 카드 청구가 결제 전으로 돌아가요.';
  }

  @override
  String get assetPaymentCancelled => '결제를 취소했어요';

  @override
  String get assetInstallmentPayoff => '남은 할부 한 번에 정리';

  @override
  String assetInstallmentPayoffConfirm(String amount) {
    return '남은 할부 $amount원을 이번 결제 예정액에 한 번에 넣을까요? 다음 회차부터는 청구되지 않아요.';
  }

  @override
  String get assetInstallmentPayoffUndo => '되돌리기';

  @override
  String get assetInstallmentPayoffUndoConfirm =>
      '남은 원금 정리를 취소하고 원래 회차대로 나눠 낼까요?';

  @override
  String get assetInstallmentPaidOffBadge => '남은 원금 정리됨';

  @override
  String assetInstallmentBadge(int months) {
    return '할부 $months개월';
  }

  @override
  String assetInstallmentSeq(int seq, int total) {
    return '$seq/$total회차';
  }

  @override
  String assetInstallmentPrincipal(String amount) {
    return '원금 $amount';
  }

  @override
  String get assetInstallmentFallback => '할부';

  @override
  String get assetLumpSumLabel => '일시불';

  @override
  String get assetAlreadyPaidLabel => '선결제 차감';

  @override
  String get assetPayNow => '지금 결제';

  @override
  String get assetPayFailed => '결제하지 못했어요. 잠시 뒤 다시 시도해주세요.';

  @override
  String get assetInstallmentPayoffFailed => '할부를 정리하지 못했어요.';

  @override
  String get assetInstallmentPayoffUndoFailed => '할부 정리를 되돌리지 못했어요.';

  @override
  String get assetCancelPaymentFailed => '결제를 취소하지 못했어요.';

  @override
  String get assetPayAction => '결제하기';

  @override
  String get assetPayAmount => '결제 금액';

  @override
  String assetPayRemainder(String amount) {
    return '남은 $amount은 결제일에 빠져요.';
  }

  @override
  String assetPayMoveNote(String amount) {
    return '계좌에서는 사용액으로 잡힌 $amount만 빠져요. 나머지는 청구 기록으로만 남아요.';
  }

  @override
  String get assetPayNoAccountNote => '연결된 결제 계좌가 없어 이체 없이 사용액만 정리돼요.';

  @override
  String get assetBillingLoadError => '청구 정보를 불러오지 못했어요';

  @override
  String get assetUpcomingPayment => '결제 예정';

  @override
  String get assetScheduledTag => '예정';

  @override
  String get assetPaidDone => '결제 완료';

  @override
  String get assetLimitUsage => '한도 사용';

  @override
  String assetLimitPctUsed(int pct) {
    return '$pct% 사용';
  }

  @override
  String assetLimitOf(String used, String limit) {
    return '$used / 한도 $limit';
  }

  @override
  String assetLimitRemain(String amount) {
    return '잔여 $amount';
  }

  @override
  String assetPerfRemain(String amount) {
    return '실적까지 $amount';
  }

  @override
  String get assetUsageHistory => '이용 내역';

  @override
  String get assetSortRecent => '최근순';

  @override
  String get assetSortAmount => '고액순';

  @override
  String get assetSortCategory => '카테고리별';

  @override
  String assetDueOn(String date) {
    return '$date 결제';
  }

  @override
  String get assetDueThisMonth => '이번 달 결제 예정';

  @override
  String get assetUsagePeriodLabel => '카드 이용 기간';

  @override
  String get assetCycleMix => '이번 회차 구성';

  @override
  String assetPerfTitle(String month) {
    return '$month월 실적';
  }

  @override
  String get assetPerfAchieved => '실적 달성';

  @override
  String get assetPayAmountEmpty => '결제 금액을 넣어주세요.';

  @override
  String assetPayAmountOver(String amount) {
    return '결제 금액은 $amount까지예요.';
  }

  @override
  String assetYearLabel(String year) {
    return '$year년';
  }

  @override
  String get assetSortAria => '이용 내역 정렬';

  @override
  String get assetPeriodPick => '결제 회차';

  @override
  String get assetNoUsage => '이용 내역이 없어요.';

  @override
  String assetMonthlyPaymentDay(int day) {
    return '매월 $day일';
  }

  @override
  String get assetBillingHistory => '청구 이력';

  @override
  String get assetStatusPending => '대기';

  @override
  String get assetStatusSkipped => '건너뜀';

  @override
  String get todoTitle => '할 일';

  @override
  String get todoCreateFirst => '첫 번째 할 일을 만들어보세요';

  @override
  String get todoQuickAddHint => '+ 빠른 할 일 추가';

  @override
  String get todoStatusAll => '전체';

  @override
  String get todoStatusCompleted => '완료';

  @override
  String get todoPriorityAll => '전체';

  @override
  String get todoPriorityHigh => '높음';

  @override
  String get todoPriorityMedium => '보통';

  @override
  String get todoPriorityLow => '낮음';

  @override
  String get todoTagMgmt => '태그 관리';

  @override
  String get memoTitle => '메모';

  @override
  String get memoEmpty => '메모가 없어요';

  @override
  String get memoSearchEmpty => '결과가 없어요';

  @override
  String get memoSearchHint => '메모 검색';

  @override
  String get memoPin => '고정';

  @override
  String get memoUnpin => '고정 해제';

  @override
  String get calTitle => '캘린더';

  @override
  String get calToday => '오늘';

  @override
  String get calMonthView => '월';

  @override
  String get calWeekView => '주';

  @override
  String get calDayView => '일';

  @override
  String get calYearView => '연';

  @override
  String get calAgendaView => '안건';

  @override
  String get calEventAdd => '일정 추가';

  @override
  String get calEventEdit => '일정 수정';

  @override
  String get calEventDelete => '일정 삭제';

  @override
  String get calLabelMgmt => '라벨 관리';

  @override
  String get calMyCalendars => '내 캘린더';

  @override
  String get calAllDay => '종일';

  @override
  String get calRepeat => '반복';

  @override
  String get calRepeatNone => '안 함';

  @override
  String get calRepeatDaily => '매일';

  @override
  String get calRepeatWeekly => '매주';

  @override
  String get calRepeatMonthly => '매월';

  @override
  String get calRepeatYearly => '매년';

  @override
  String get calLocation => '장소';

  @override
  String get calMemo => '메모';

  @override
  String get calStartDate => '시작';

  @override
  String get calEndDate => '종료';

  @override
  String get calFieldTitle => '제목';

  @override
  String get calFieldDescription => '설명';

  @override
  String get calFieldCalendar => '캘린더';

  @override
  String get calFieldLabel => '라벨';

  @override
  String get calFieldColor => '색상';

  @override
  String get calFieldName => '이름';

  @override
  String get calFieldReminder => '알림';

  @override
  String get calFieldStartDate => '시작일';

  @override
  String get calFieldEndDate => '종료일';

  @override
  String get calTitlePlaceholder => '예: 치과 정기 검진';

  @override
  String get calDescriptionPlaceholder => '예: 준비물과 안내 사항';

  @override
  String get calLocationPlaceholder => '예: 본사 3층 회의실';

  @override
  String get calSelectCalendar => '캘린더 선택';

  @override
  String get calNoLabel => '라벨 없음';

  @override
  String get calLabelNamePlaceholder => '예: 중요, 마감일, 회의';

  @override
  String get calCalendarNamePlaceholder => '예: 가족, 업무, 운동 일정';

  @override
  String get calCalendarNameFieldPlaceholder => '캘린더 이름';

  @override
  String get calInviteCodePlaceholder => '예: 3F9A1C2B';

  @override
  String get calRecurrenceNone => '반복 안 함';

  @override
  String get calFormNone => '없음';

  @override
  String get calFormNoReminder => '알림 없음';

  @override
  String get calFormCalendarLoadFailed => '불러오지 못했어요';

  @override
  String get calFormLabelHint => '라벨은 설정의 캘린더 라벨에서 만들어요';

  @override
  String get calFormStartDay => '시작 날짜';

  @override
  String get calFormStartTime => '시작 시각';

  @override
  String get calFormEndDay => '종료 날짜';

  @override
  String get calFormEndTime => '종료 시각';

  @override
  String get calFormEndBeforeStart => '종료가 시작보다 빠를 수 없어요';

  @override
  String get calFormTitleRequired => '제목을 입력해주세요';

  @override
  String get calFormRows => '일정 정보';

  @override
  String get calFormRowsMore => '반복 · 알림 · 장소 · 설명';

  @override
  String get calFormSaveFailed => '일정을 저장하지 못했어요. 잠시 뒤 다시 시도해주세요.';

  @override
  String get calFormDeleteFailed => '일정을 삭제하지 못했어요.';

  @override
  String calReminderMinutesBefore(int n) {
    return '$n분 전';
  }

  @override
  String get calReminderHourBefore => '1시간 전';

  @override
  String get calReminderDayBefore => '1일 전';

  @override
  String calEventDeleteConfirm(String title) {
    return '\"$title\" 일정을 삭제할까요? 삭제한 일정은 되돌릴 수 없어요.';
  }

  @override
  String calEventDeleteConfirmRecurring(String title) {
    return '\"$title\" 은 반복 일정이라 모든 회차가 함께 삭제돼요. 삭제한 일정은 되돌릴 수 없어요.';
  }

  @override
  String get calLabelsTitle => '캘린더 라벨';

  @override
  String calAllLabelsCount(int count) {
    return '전체 라벨 · $count';
  }

  @override
  String get calLabelsEmpty => '라벨이 없어요';

  @override
  String get calLabelsEmptyHint => '위 \'라벨 추가\' 로 만들어요';

  @override
  String get calLabelsIntro => '모든 캘린더에서 같이 쓰는 라벨이에요. 일정을 만들 때 골라요.';

  @override
  String get calNewLabel => '라벨 추가';

  @override
  String get calEditLabel => '라벨 수정';

  @override
  String get calPreview => '미리보기';

  @override
  String get calDeleteLabelTitle => '라벨 삭제';

  @override
  String calDeleteLabelConfirm(String name) {
    return '\"$name\" 라벨을 삭제할까요? 이 라벨이 붙은 일정은 라벨 없이 남아요. 삭제한 라벨은 되돌릴 수 없어요.';
  }

  @override
  String get calDatePicker => '월 선택';

  @override
  String calFilterChipName(int count) {
    return '캘린더 $count개 보는 중';
  }

  @override
  String calMoreEvents(int count) {
    return '+$count개';
  }

  @override
  String get calEventsLoadFailed => '일정을 불러오지 못했어요';

  @override
  String calCalendarChipCount(int count) {
    return '$count개';
  }

  @override
  String get calNoCalendars => '캘린더가 없어요.';

  @override
  String get calOtherSources => '기타 소스';

  @override
  String get calHolidays => '공휴일';

  @override
  String get calManageShareSettings => '캘린더 관리 · 공유 설정';

  @override
  String get calNoEventsThisDay => '이 날에 일정이 없어요.';

  @override
  String calEventTotalCount(int count) {
    return '$count건';
  }

  @override
  String get calManageShareTitle => '캘린더 관리 · 공유';

  @override
  String get calJoinByCode => '초대 코드로 참여';

  @override
  String get calShareIntro => '캘린더를 만들고 멤버를 초대해 가족 · 친구와 함께 일정을 관리해요.';

  @override
  String get calJoinSectionTitle => '초대 코드';

  @override
  String get calRoleOwner => '소유자';

  @override
  String get calRoleEditor => '편집 가능';

  @override
  String get calRoleViewer => '읽기 전용';

  @override
  String get calNewCalendar => '캘린더 추가';

  @override
  String calMyCalendarsCount(int count) {
    return '내 캘린더 · $count';
  }

  @override
  String get calNoOwnedCalendars => '소유한 캘린더가 없어요';

  @override
  String calSharedCalendarsCount(int count) {
    return '공유받은 캘린더 · $count';
  }

  @override
  String get calNoSharedCalendars => '공유받은 캘린더가 없어요';

  @override
  String get calDefault => '기본';

  @override
  String get calOnlyMe => '나만 사용';

  @override
  String calMemberCount(int count) {
    return '멤버 $count명';
  }

  @override
  String get calJoinCardBody => '공유받은 초대 코드를 넣으면 그 캘린더에 들어가요.';

  @override
  String get calJoin => '참여';

  @override
  String get calCreate => '만들기';

  @override
  String calJoinedCalendar(String name) {
    return '\"$name\" 캘린더에 참여했어요.';
  }

  @override
  String get calInviteCode => '초대 코드';

  @override
  String get calDeleteCalendar => '캘린더 삭제';

  @override
  String get calCalendarUpdated => '캘린더를 수정했어요';

  @override
  String get calInviteCodeRegenerated => '초대 코드를 새로 만들었어요.';

  @override
  String get calInviteCodeCopied => '초대 코드를 복사했어요.';

  @override
  String get calRemoveMember => '멤버 내보내기';

  @override
  String calRemoveMemberConfirm(String name) {
    return '\"$name\" 님을 캘린더에서 내보낼까요?';
  }

  @override
  String get calRemove => '내보내기';

  @override
  String calDeleteCalendarConfirm(String name) {
    return '\"$name\" 캘린더를 삭제할까요? 일정은 기본 캘린더로 옮겨지고, 멤버는 이 캘린더를 더 볼 수 없어요. 삭제한 캘린더는 되돌릴 수 없어요.';
  }

  @override
  String get calDeleteCalendarFailed => '캘린더를 삭제하지 못했어요.';

  @override
  String get calLabelDeleteFailed => '라벨을 삭제하지 못했어요.';

  @override
  String get calCopy => '복사';

  @override
  String get calRegenerate => '새로 만들기';

  @override
  String get calMembers => '멤버';

  @override
  String calMembersCount(int count) {
    return '멤버 · $count';
  }

  @override
  String get calMemberLoadFailed => '멤버를 불러오지 못했어요';

  @override
  String get calManageNameTitle => '캘린더 이름';

  @override
  String get calNameRequired => '캘린더 이름을 입력해주세요.';

  @override
  String get calInviteHint => '이 코드를 공유하면 다른 사람이 캘린더에 참여할 수 있어요.';

  @override
  String get calManageSaveFailed => '저장하지 못했어요. 잠시 뒤 다시 시도해주세요.';

  @override
  String get calCreateFailed => '저장하지 못했어요. 잠시 뒤 다시 시도해주세요.';

  @override
  String get calJoinInvalidCode => '초대 코드를 확인해주세요.';

  @override
  String get calJoinAlreadyMember => '이미 참여한 캘린더예요.';

  @override
  String get calRemoveMemberFailed => '멤버를 내보내지 못했어요.';

  @override
  String get calColorChangeFailed => '색을 바꾸지 못했어요. 잠시 뒤 다시 시도해주세요.';

  @override
  String get calRoleChangeFailed => '권한을 바꾸지 못했어요.';

  @override
  String get calRegenerateFailed => '초대 코드를 새로 만들지 못했어요.';

  @override
  String get calInviteNone => '초대 코드 없음';

  @override
  String get calJoinCodeRequired => '초대 코드를 입력해주세요.';

  @override
  String get calLabelNameRequired => '라벨 이름을 입력해주세요.';

  @override
  String get calLabelNameDuplicate => '같은 이름의 라벨이 이미 있어요.';

  @override
  String get calLabelSaveFailed => '저장하지 못했어요. 잠시 뒤 다시 시도해주세요.';

  @override
  String get calMeSuffix => '(나)';

  @override
  String calMemberManage(String name) {
    return '$name 관리';
  }

  @override
  String get calChangeToEditor => '편집 가능으로';

  @override
  String get calChangeToViewer => '읽기 전용으로';

  @override
  String get calAdd => '추가';

  @override
  String get calActionFailed => '실패';

  @override
  String get calSaveFailed => '저장 실패';

  @override
  String get calDeleteFailed => '삭제 실패';

  @override
  String get calJoinFailed => '참여하지 못했어요. 잠시 뒤 다시 시도해주세요.';

  @override
  String get calUpdateFailed => '캘린더 표시를 바꾸지 못했어요. 잠시 뒤 다시 시도해주세요.';

  @override
  String get importExecuteFailed => '가져오지 못했어요.';

  @override
  String get calCalendarLoadError => '캘린더를 불러오지 못했어요';

  @override
  String get calLabelLoadError => '라벨을 불러오지 못했어요';

  @override
  String get dashTitle => '홈';

  @override
  String get dashGreeting => '오늘도 좋은 하루 되세요';

  @override
  String get dashTotalAssets => '총 자산';

  @override
  String get dashChange => '변화';

  @override
  String get dashThisMonthExpense => '이번 달 지출';

  @override
  String get dashThisMonthIncome => '이번 달 수입';

  @override
  String get dashRecent => '최근 거래';

  @override
  String get dashUpcoming => '다가오는 일정';

  @override
  String get dashRecentTodos => '최근 할 일';

  @override
  String dashOverdue(int count) {
    return '연체 $count';
  }

  @override
  String dashOverdueRead(int count) {
    return '연체 $count건';
  }

  @override
  String get dashTrendTitle => '최근 6개월';

  @override
  String get dashAddTx => '거래 추가';

  @override
  String get dashTodayLabel => '오늘';

  @override
  String get dashTomorrowLabel => '내일';

  @override
  String dashDaysLeft(int n) {
    return 'D-$n';
  }

  @override
  String get dashVsLastMonth => '지난달 대비';

  @override
  String get dashLiabilities => '부채';

  @override
  String dashMonthLedger(int month) {
    return '$month월 가계부';
  }

  @override
  String get dashDailyAvgPrefix => '하루 평균 ';

  @override
  String get dashSpentMasked => ' 썼어요.';

  @override
  String get dashSpentUnit => '원 썼어요.';

  @override
  String get dashVsPrevPrefix => ' 전월 대비 ';

  @override
  String get dashSaving => ' 절약 중이에요.';

  @override
  String get dashSpentMore => ' 더 썼어요.';

  @override
  String get dashSame => ' 동일해요.';

  @override
  String get dashNoCategoryData => '이번 달 지출이 없어요';

  @override
  String get dashNoBudget => '등록된 예산이 없어요';

  @override
  String get dashTodaySpend => '오늘 쓴 돈';

  @override
  String get dashNoTodaySpend => '오늘은 아직 쓴 돈이 없어요';

  @override
  String get dashViewAll => '전체 보기';

  @override
  String get dashHideAmountsSettings => '금액 가리기 설정';

  @override
  String get dashNoLastMonth => '지난달 기록 없음';

  @override
  String dashBudgetOf(String name) {
    return '$name 예산';
  }

  @override
  String get dashBudgetTotal => '총 예산';

  @override
  String dashCategoryChartLabel(int month, String total) {
    return '$month월 카테고리별 지출, 합계 $total';
  }

  @override
  String get dashCategoryOthers => '기타';

  @override
  String get dashTableShare => '비율';

  @override
  String get dashTableAmount => '금액';

  @override
  String get dashFailNetWorth => '순자산을 불러오지 못했어요';

  @override
  String get dashFailMonth => '이번 달 가계부를 불러오지 못했어요';

  @override
  String get dashFailCategory => '카테고리를 불러오지 못했어요';

  @override
  String get dashFailBudget => '예산을 불러오지 못했어요';

  @override
  String get dashFailUpcoming => '다가오는 일정을 불러오지 못했어요';

  @override
  String get dashFailTodos => '최근 할 일을 불러오지 못했어요';

  @override
  String get dashFailToday => '오늘 쓴 돈을 불러오지 못했어요';

  @override
  String get dashFailDesc => '잠시 뒤 다시 시도해주세요.';

  @override
  String get expTitle => '가계부';

  @override
  String get expFilterAll => '전체';

  @override
  String get expFilterIncome => '수입';

  @override
  String get expFilterExpense => '지출';

  @override
  String get expFilterTransfer => '이체';

  @override
  String get expEmptyDescription => '새 거래를 추가해서 가계부를 시작하세요';

  @override
  String get expAdd => '거래 추가';

  @override
  String get expEdit => '거래 수정';

  @override
  String get expDelete => '거래 삭제';

  @override
  String get expAmount => '금액';

  @override
  String get expCategory => '카테고리';

  @override
  String get expAsset => '자산';

  @override
  String get expDate => '날짜';

  @override
  String get expMerchant => '가맹점';

  @override
  String get expPaymentMethod => '결제 수단';

  @override
  String get expForeignPayment => '해외 결제';

  @override
  String get expCurrency => '통화';

  @override
  String get expOriginalAmount => '현지 금액';

  @override
  String get expExchangeRate => '환율';

  @override
  String expFxHint(String original, String krw) {
    return '$original → $krw';
  }

  @override
  String get expInstallment => '할부';

  @override
  String get expRefund => '환불';

  @override
  String get expRefundConfirmTitle => '환불 처리';

  @override
  String expRefundConfirmBody(String amount, String asset) {
    return '이 거래를 환불로 표시해요. 합계에서 빠지고 $amount이 $asset에 돌아가요.';
  }

  @override
  String get expRefundConfirmBodyRecordOnly => '이 거래를 환불로 표시해요. 합계에서 빠져요.';

  @override
  String get expRefundConfirmBodyCardNoAccount => '결제계좌가 없어 카드 잔액만 정리돼요.';

  @override
  String get expRefundDate => '환불일';

  @override
  String get expRefundConfirm => '환불 처리';

  @override
  String expRefundedAt(String date) {
    return '환불됨 · $date — 합계에서 빠져 있어요.';
  }

  @override
  String get expRefundCancel => '환불 취소';

  @override
  String get expRefundCancelConfirm =>
      '환불 표시를 지울까요? 이 거래가 합계에 다시 들어가고, 환급된 금액도 되돌아가요.';

  @override
  String get expRefundCancelConfirmPlain => '환불 표시를 지울까요? 이 거래가 합계에 다시 들어가요.';

  @override
  String get expRefundedBadge => '환불됨';

  @override
  String expRefundedToast(String amount) {
    return '미리 낸 돈 중 $amount이 계좌로 돌아왔어요.';
  }

  @override
  String get expLumpSum => '일시불';

  @override
  String expInstallmentMonths(int months) {
    return '$months개월';
  }

  @override
  String expInstallmentHint(String perMonth, int months) {
    return '매달 약 $perMonth원씩 $months회 청구돼요';
  }

  @override
  String get expDescription => '메모';

  @override
  String get expTypeIncome => '수입';

  @override
  String get expTypeExpense => '지출';

  @override
  String get transferFeePrefix => '수수료';

  @override
  String transferReceivedTag(String amount) {
    return '받는 금액 $amount';
  }

  @override
  String get transferReceived => '받는 금액';

  @override
  String get transferPrincipal => '원금';

  @override
  String get transferWithdrawn => '출금 합계';

  @override
  String get transferDeleted => '이체를 삭제했어요';

  @override
  String get transferDeleteConfirm =>
      '이 이체를 삭제할까요? 양쪽 계좌 잔액이 이체 전으로 돌아가요. 삭제한 이체는 되돌릴 수 없어요.';

  @override
  String get transferDeleteTitle => '이체 삭제';

  @override
  String get transferAutoTradeSettlement =>
      '주식을 살 때 예수금이 모자라 자동으로 만들어진 이체예요. 매수를 취소하면 함께 사라져요.';

  @override
  String get transferAutoCardPayment =>
      '카드 자동결제로 만들어진 이체예요. 청구 회차와 묶여 있어 따로 고칠 수 없어요.';

  @override
  String get transferAutoCardRefund =>
      '카드에 남은 과납금을 결제계좌로 돌려준 이체예요. 카드 잔액을 직접 보정하면 다음 날 자동으로 다시 맞춰져요.';

  @override
  String get transferAutoDefault => '자동으로 만들어진 이체예요. 원래 거래를 지우면 함께 사라져요.';

  @override
  String updateAvailable(String version) {
    return '$version 버전이 나왔어요';
  }

  @override
  String get updateAvailableDesc => '눌러서 내려받아 설치하세요';

  @override
  String get updateAvailableDescIos => '눌러서 AltStore 에서 받으세요';

  @override
  String updateSheetTitle(String version) {
    return '$version 버전이 나왔어요';
  }

  @override
  String get updateSheetSubtitle => '새 버전이 준비됐어요. 아래에서 바로 받을 수 있어요.';

  @override
  String get updateSheetChanges => '이번에 달라진 점';

  @override
  String get updateSheetNoNotes => '이번 버전의 변경 내용은 따로 정리되지 않았어요.';

  @override
  String get updateSheetLater => '나중에';

  @override
  String get updateSheetNow => '업데이트';

  @override
  String get updateSheetRetry => '다시 시도';

  @override
  String get updateSheetDownloading => '받는 중이에요';

  @override
  String get updateSheetOpening => '설치 화면을 여는 중이에요';

  @override
  String get updateSheetFailed => '앱에서 받지 못해 브라우저로 열어요.';

  @override
  String get updateTitle => '업데이트';

  @override
  String updateGateTitle(String version) {
    return '새 버전 $version이 나왔어요';
  }

  @override
  String get updateGateInstall => '설치';

  @override
  String get updateGateForcedCancelBody => '꼭 필요한 업데이트가 들어 있어요.';

  @override
  String get updateCheckFailedTitle => '업데이트를 확인하지 못했어요';

  @override
  String get updateUpToDate => '최신 버전이에요';

  @override
  String updateCurrentBuild(String build) {
    return '지금 빌드 $build';
  }

  @override
  String get updateCheckFailed => '새 버전을 확인하지 못했어요.';

  @override
  String get updateRequiredDesc => '이번 버전부터 꼭 업데이트해야 해요. 받기 전에는 앱을 쓸 수 없어요.';

  @override
  String get expScheduled => '예정';

  @override
  String get expTypeTransfer => '이체';

  @override
  String get expTransferFrom => '보낼 자산';

  @override
  String get expTransferTo => '받을 자산';

  @override
  String get expFee => '수수료';

  @override
  String get expFilter => '필터';

  @override
  String get expFilterMin => '최소';

  @override
  String get expFilterMax => '최대';

  @override
  String get expFilterPeriod => '기간';

  @override
  String get expSplit => '내역 분할';

  @override
  String get expConvertDutch => '더치페이로';

  @override
  String get expConvertRecurring => '반복 설정';

  @override
  String get expExport => '내보내기';

  @override
  String get expExportCsv => 'CSV 내보내기';

  @override
  String get expSummaryTitle => '월간 요약';

  @override
  String get expSummaryIncome => '수입';

  @override
  String get expSummaryExpense => '지출';

  @override
  String get expSummaryBalance => '잔액';

  @override
  String get budgetCategoryAdd => '카테고리 예산 추가';

  @override
  String get budgetCategoryEdit => '카테고리 예산 수정';

  @override
  String get budgetSubmitAdd => '추가';

  @override
  String get budgetFormAmountLabel => '예산';

  @override
  String get budgetFormCategoryPlaceholder => '카테고리 선택';

  @override
  String get budgetFormQuickAmounts => '빠른 금액';

  @override
  String get budgetFormErrCategory => '카테고리를 골라주세요.';

  @override
  String get budgetFormErrTotal => '총 예산을 입력해주세요.';

  @override
  String get budgetFormErrAmount => '예산을 입력해주세요.';

  @override
  String get amountTooLarge => '금액은 100억원까지 입력할 수 있어요.';

  @override
  String amountTooLargeAt(String limit) {
    return '금액은 $limit까지 입력할 수 있어요.';
  }

  @override
  String get amountLimitBalance => '1,000억원';

  @override
  String get budgetPickUsed => '이번 달 예산이 있어요';

  @override
  String get budgetPickAllBudgeted => '모든 지출 카테고리에 이미 예산이 있어요.';

  @override
  String get budgetPickNoCategory => '예산을 줄 지출 카테고리가 없어요.';

  @override
  String get budgetPickLoadFailTitle => '카테고리를 불러오지 못했어요';

  @override
  String get budgetPickLoadFailDesc => '잠시 뒤 다시 시도해주세요.';

  @override
  String get budgetActionFailed => '실패';

  @override
  String budgetDeleteTitle(String name) {
    return '\"$name\" 예산을 삭제할까요?';
  }

  @override
  String get budgetDeleteConfirm => '삭제한 예산은 되돌릴 수 없어요.';

  @override
  String get budgetDeleteFailed => '예산을 삭제하지 못했어요.';

  @override
  String get budgetSaveFailed => '예산을 저장하지 못했어요.';

  @override
  String get assetSaveFailed => '자산을 저장하지 못했어요.';

  @override
  String get assetSaveCardForeign => '카드는 원화로만 등록할 수 있어요.';

  @override
  String get assetSaveRateRequired => '외화 자산은 환율을 입력해야 저장할 수 있어요.';

  @override
  String get tradeSaveFailed => '매매를 처리하지 못했어요.';

  @override
  String get tradeSaveInsufficientQty => '보유 수량이 부족해요.';

  @override
  String get budgetMonthlyLimit => '월 예산 한도';

  @override
  String get budgetSelectMonth => '월 선택';

  @override
  String budgetMonthOverallCap(int month) {
    return '$month월 총 예산';
  }

  @override
  String get budgetOverallCapDesc => '이번 달 전체 지출의 상한이에요 (카테고리 예산이 없는 지출도 포함).';

  @override
  String get budgetOverallCapEmptyHint =>
      '총 예산이 아직 없어요. 설정에서 이번 달 최대 지출 한도를 정할 수 있어요.';

  @override
  String budgetEmptyMonthTitle(int month) {
    return '$month월 예산이 아직 없어요';
  }

  @override
  String get budgetEmptyMonthDesc => '예산을 정하면 쓴 돈과 남은 돈을 한눈에 볼 수 있어요.';

  @override
  String get budgetFailCompliance => '예산 이행률을 불러오지 못했어요';

  @override
  String get budgetManagerLoadFailed => '예산을 불러오지 못했어요';

  @override
  String budgetCategoryCount(int count) {
    return '$count 카테고리';
  }

  @override
  String budgetOverLimit(String amount) {
    return '한도 초과 $amount';
  }

  @override
  String get budgetTableMonth => '달';

  @override
  String get budgetCurrentCategorySum => '현재 카테고리 한도 합계';

  @override
  String budgetPercentUsed(String pct) {
    return '$pct% 사용';
  }

  @override
  String budgetRemaining(String amount) {
    return '남은 예산 $amount';
  }

  @override
  String budgetOverBy(String amount) {
    return '한도 $amount 초과';
  }

  @override
  String get budgetOverallCapLabel => '총 예산';

  @override
  String get budgetCategoryAllocated => '카테고리 할당';

  @override
  String get budgetAllocatable => '할당 가능';

  @override
  String budgetOverAllocatedWarning(String amount) {
    return '카테고리 한도 합이 총 예산을 $amount 초과했어요. 총 예산을 올리거나 카테고리 한도를 줄여주세요.';
  }

  @override
  String get budgetSpendingPace => '지출 페이스';

  @override
  String get budgetPaceBarName => '이번 달 지출 페이스';

  @override
  String budgetPaceBarValue(String used, String elapsed) {
    return '$used% 사용 · 이번 달 $elapsed% 지남';
  }

  @override
  String get budgetPaceOnTrack => '정상 속도';

  @override
  String get budgetPaceFast => '빠른 속도';

  @override
  String budgetMonthElapsed(String pct) {
    return '이번 달 $pct% 경과 ↑';
  }

  @override
  String get budgetDailyAvg => '일평균 지출';

  @override
  String get budgetDailyRecommended => '남은 일 권장 지출';

  @override
  String get budgetStatusTitle => '예산 현황';

  @override
  String get budgetOver => '초과';

  @override
  String get budgetHealthy => '여유';

  @override
  String get budgetByCategory => '카테고리별 예산';

  @override
  String budgetCountSet(int count) {
    return '$count개 설정됨';
  }

  @override
  String get budgetNoCategoryBudgets => '카테고리별 예산이 없어요';

  @override
  String get budgetGoToSettings => '예산 설정하러 가기';

  @override
  String budgetCategoryFallback(int id) {
    return '카테고리 #$id';
  }

  @override
  String get budgetComplianceTitle => '최근 6개월 예산 이행률';

  @override
  String get budgetComplianceSubtitle => '한도 대비 지출 %';

  @override
  String get budgetNoComplianceData => '아직 이행률 데이터가 없어요';

  @override
  String get budgetVsLimit => '한도 대비';

  @override
  String get budgetLimit => '한도';

  @override
  String get budgetSetup => '예산 설정';

  @override
  String get budgetCopyLastMonth => '지난달 예산을 복사할까요?';

  @override
  String budgetCopyOverwriteMessage(int count) {
    return '이번 달 예산 $count개가 지난달 예산으로 바뀌어요. 바꾼 뒤에는 되돌릴 수 없어요.';
  }

  @override
  String budgetCopyPartialFailed(int count) {
    return '가져오지 못한 예산이 $count개 있어요.';
  }

  @override
  String get budgetCopiedDone => '지난달 예산을 가져왔어요.';

  @override
  String get budgetCopyUndo => '되돌리기';

  @override
  String budgetCopyUndoPartial(int count) {
    return '되돌리지 못한 예산이 $count개 남았어요.';
  }

  @override
  String get budgetCopyLastMonthBtn => '지난달 복사';

  @override
  String budgetMonthTotal(int month) {
    return '$month월 총 예산';
  }

  @override
  String get budgetNotSet => '설정 안 됨';

  @override
  String get budgetUsed => '사용';

  @override
  String get budgetAllocated => '할당됨';

  @override
  String budgetByCategoryCount(int count) {
    return '카테고리별 예산 · $count개';
  }

  @override
  String get budgetAdd => '예산 추가';

  @override
  String get budgetNoCategorySet => '설정된 카테고리 예산이 없어요';

  @override
  String get cardBenefitTypeDiscount => '할인';

  @override
  String get cardBenefitTypePoint => '적립';

  @override
  String get cardBenefitTypeMileage => '마일리지';

  @override
  String get cardBenefitsTitle => '카드 혜택';

  @override
  String get cardSelectTitle => '카드 선택';

  @override
  String get cardSearchHintFull => '카드 이름, 카드사로 검색';

  @override
  String get cardSearchHintNameCompany => '카드명 / 회사 검색';

  @override
  String get cardDetailLoadError => '카드 정보를 불러오지 못했어요';

  @override
  String get cardSearchError => '카드 검색 실패';

  @override
  String get cardAddFailed => '추가 실패';

  @override
  String get cardDeleteFailed => '삭제 실패';

  @override
  String get cardLastMonthPerf => '전월 실적';

  @override
  String get cardKeyBenefitTags => '주요 혜택 태그';

  @override
  String cardBenefitDetailCount(int count) {
    return '혜택 $count개';
  }

  @override
  String get cardExpandAll => '모두 펼치기';

  @override
  String get cardCollapseAll => '모두 접기';

  @override
  String get cardCautions => '유의사항';

  @override
  String get cardNone => '없음';

  @override
  String get cardFeeUnknown => '정보 없음';

  @override
  String get cardFeeFree => '무료';

  @override
  String get cardPerfNone => '실적 없음';

  @override
  String cardFeeDomesticOnly(String amount) {
    return '국내전용 $amount';
  }

  @override
  String cardPerfMin(String amount) {
    return '$amount 이상';
  }

  @override
  String cardPerfMonthly(String amount) {
    return '실적 $amount';
  }

  @override
  String cardPerfMonthTitle(String month) {
    return '$month 실적';
  }

  @override
  String get cardPerfAchieved => '달성';

  @override
  String cardPerfRemaining(String amount) {
    return '남은 $amount';
  }

  @override
  String get cardIncludeDiscontinued => '단종 카드 포함';

  @override
  String cardTotalCount(String count) {
    return '총 $count장';
  }

  @override
  String get cardNoResults => '찾는 카드가 없어요';

  @override
  String get cardNoResultsHint => '다른 검색어나 조건으로 찾아보세요.';

  @override
  String cardRowFeeAmount(String amount) {
    return '연회비 $amount';
  }

  @override
  String cardRowFeeLabel(String label) {
    return '연회비 $label';
  }

  @override
  String get cardRowFeeNone => '연회비 없음';

  @override
  String get cardRowFeeUnknown => '연회비 정보 없음';

  @override
  String get cardTypeChip => '카드 종류';

  @override
  String get cardBenefitChip => '혜택';

  @override
  String get cardFilterBar => '카드 거르기';

  @override
  String get cardFilterClear => '조건 모두 지우기';

  @override
  String get cardFailDesc => '잠시 뒤 다시 시도해주세요.';

  @override
  String get cardBrands => '브랜드';

  @override
  String get cardNoBenefits => '등록된 혜택이 없어요.';

  @override
  String get categoryManageTitle => '카테고리 관리';

  @override
  String get categorySearchHint => '카테고리 검색';

  @override
  String get categoryLoadError => '카테고리 로드 실패';

  @override
  String get categoryNoResults => '찾는 카테고리가 없어요.';

  @override
  String get categoryEmpty => '카테고리가 없어요.';

  @override
  String get categoryAdd => '카테고리 추가';

  @override
  String get categoryAddAction => '추가';

  @override
  String get recurringAddAction => '추가';

  @override
  String get presetAddAction => '추가';

  @override
  String categoryListTitleExpense(int count) {
    return '지출 카테고리 $count개';
  }

  @override
  String categoryListTitleIncome(int count) {
    return '수입 카테고리 $count개';
  }

  @override
  String get categoryEdit => '카테고리 수정';

  @override
  String get categoryNameRequired => '이름을 입력해주세요.';

  @override
  String get categoryNameTooLong => '이름은 12자 이내로 입력해주세요.';

  @override
  String get categoryNameDuplicate => '같은 자리에 같은 이름의 카테고리가 있어요.';

  @override
  String get categoryParent => '상위 카테고리';

  @override
  String get categoryBudgetExceedTitle => '예산 초과 확인';

  @override
  String categoryBudgetExceedMessage(String parent, String amount) {
    return '옮기면 \"$parent\" 예산을 $amount 넘어요. 그래도 옮길까요?';
  }

  @override
  String get categoryMove => '옮기기';

  @override
  String get categoryActionFailed => '실패';

  @override
  String get categoryDeleteBlockedTitle => '삭제할 수 없어요';

  @override
  String categoryDeleteHasChildren(String name) {
    return '\"$name\" 카테고리에 하위 카테고리가 있어 삭제할 수 없어요. 먼저 하위 카테고리를 정리해주세요.';
  }

  @override
  String categoryDeleteConfirm(String name) {
    return '\"$name\" 카테고리를 삭제할까요?';
  }

  @override
  String get categoryDeleteFailed => '카테고리를 삭제하지 못했어요.';

  @override
  String get categorySaveFailed => '카테고리를 저장하지 못했어요.';

  @override
  String get categoryMoveTxFailed => '거래를 옮기지 못했어요.';

  @override
  String get categoryReorderFailed => '순서를 바꾸지 못했어요. 잠시 뒤 다시 시도해주세요.';

  @override
  String get todoSaveFailed => '할 일을 저장하지 못했어요.';

  @override
  String get categoryParentMoveHint => '최상위로 올리려면 새 최상위를 만들어 거래를 옮겨주세요.';

  @override
  String get categoryMakeRoot => '최상위';

  @override
  String get categoryNamePlaceholder => '예: 반려동물, 부수입';

  @override
  String get categoryIconLabel => '아이콘';

  @override
  String get categoryLoadFailed => '카테고리를 불러오지 못했어요';

  @override
  String get categoryDeleteMessage =>
      '이미 기록된 거래는 삭제되지 않고 그대로 남아요. 이 카테고리에 걸린 예산은 함께 삭제돼요.';

  @override
  String categoryDeleteRecurring(int count) {
    return '이 카테고리를 쓰는 반복 거래 $count개는 계속 이 카테고리로 기록돼요.';
  }

  @override
  String categoryExpandOf(String name) {
    return '$name 하위 카테고리';
  }

  @override
  String categoryMoreOf(String name) {
    return '$name 더보기';
  }

  @override
  String categoryDragReorderOf(String name) {
    return '$name 순서 바꾸기';
  }

  @override
  String get categoryKindLabel => '종류';

  @override
  String get categorySubmitAdd => '추가';

  @override
  String get categoryAddSub => '하위 카테고리 추가';

  @override
  String get authLoginPrompt => '그루 계정으로 로그인해주세요.';

  @override
  String get authSsoLogin => '그루 계정으로 로그인';

  @override
  String get authLoginTitle => '로그인';

  @override
  String get authLoginFailed => '로그인하지 못했어요.';

  @override
  String get authLoginExpired => '로그인 시간이 지났어요. 다시 로그인해주세요.';

  @override
  String get authLoginError => '로그인을 처리하지 못했어요.';

  @override
  String get authSecurityNotHttps => '로그인 서버와 안전하게 연결되지 않았어요.';

  @override
  String get authStateMismatch => '보안 검증에 실패했어요 (state 불일치). 다시 시도해주세요.';

  @override
  String get authNoAuthCode => '인가코드를 받지 못했어요. 다시 시도해주세요.';

  @override
  String get authPageLoadError => '로그인 페이지를 불러오지 못했어요.';

  @override
  String get dutchSendRequest => '요청';

  @override
  String dutchSendRequestOf(String name) {
    return '$name님에게 송금 요청';
  }

  @override
  String get dutchRequestSoon => '송금 요청은 곧 열려요.';

  @override
  String dutchStepLabel(int step, int total) {
    return '$step / $total단계';
  }

  @override
  String get dutchInfoTitle => '정산 정보';

  @override
  String get dutchTitleRequired => '정산 이름을 입력해주세요.';

  @override
  String get dutchAmountRequired => '총 금액을 입력해주세요.';

  @override
  String get dutchNeedOne => '함께 정산할 사람을 한 명 이상 더해주세요.';

  @override
  String dutchPaidProgress(int paid, int total) {
    return '$paid/$total명 냈어요';
  }

  @override
  String get dutchAllPaid => '모두 냈어요';

  @override
  String dutchPerPersonOf(String amount) {
    return '1인당 $amount';
  }

  @override
  String dutchPerPersonRestOf(String amount, String rest, String name) {
    return '1인당 $amount · $rest은 $name';
  }

  @override
  String dutchSummaryLine(int count, String amount) {
    return '$count명 · 1인당 $amount';
  }

  @override
  String get dutchPayerPaid => '결제했어요';

  @override
  String dutchPayerPaidShare(String amount) {
    return '결제했어요 · 몫 $amount';
  }

  @override
  String dutchShareDone(String amount) {
    return '$amount 냈어요';
  }

  @override
  String dutchShareDue(String amount) {
    return '$amount 보낼 차례';
  }

  @override
  String get dutchBadgePaid => '냈어요';

  @override
  String get dutchMarkReceived => '받음';

  @override
  String dutchMarkReceivedOf(String name) {
    return '$name 받음 처리';
  }

  @override
  String get dutchSettleAll => '모두 받음';

  @override
  String dutchParticipantsHeader(int count) {
    return '참여자 · $count';
  }

  @override
  String get dutchSuggestHeader => '함께 정산했던 사람';

  @override
  String dutchSuggestChip(String name) {
    return '+ $name';
  }

  @override
  String get dutchPayerSelect => '결제한 사람';

  @override
  String get dutchLoadFailedTitle => '더치페이를 불러오지 못했어요';

  @override
  String get dutchLoadFailedDesc => '잠시 뒤 다시 시도해주세요.';

  @override
  String get dutchNoReceivable => '받을 돈 없음';

  @override
  String get dutchMarkFailed => '받음 처리를 하지 못했어요.';

  @override
  String get dutchTitle => '더치페이';

  @override
  String get dutchCreate => '정산 만들기';

  @override
  String get dutchTabActive => '진행 중';

  @override
  String get dutchTabPast => '완료';

  @override
  String get dutchTabFriends => '친구';

  @override
  String get dutchEmptyActiveTitle => '진행 중인 정산이 없어요';

  @override
  String get dutchEmptyActiveSub => '오른쪽 아래 + 버튼으로 새 정산을 만들어보세요.';

  @override
  String get dutchEmptyPastTitle => '완료된 정산이 없어요';

  @override
  String get dutchEmptyPastSub => '정산을 마치면 여기에 모여요.';

  @override
  String get dutchEmptyFriendsTitle => '함께 정산한 친구가 없어요';

  @override
  String get dutchEmptyFriendsSub => '정산에 친구를 더하면 여기에 모여요.';

  @override
  String get dutchActionFailed => '실패';

  @override
  String get dutchSettleFailed => '모두 받음 처리를 하지 못했어요.';

  @override
  String get dutchDeleteFailed => '정산을 삭제하지 못했어요.';

  @override
  String get dutchToReceive => '받을 돈';

  @override
  String get dutchToSend => '보낼 돈';

  @override
  String dutchFromPeople(int count) {
    return '$count명에게서';
  }

  @override
  String dutchToPeople(int count) {
    return '$count명에게';
  }

  @override
  String get dutchPerPersonLabel => '1인당';

  @override
  String dutchNPeople(int count) {
    return '$count명';
  }

  @override
  String dutchSettledTogetherCount(int count) {
    return '$count회 함께 정산';
  }

  @override
  String get dutchSettled => '정산 완료';

  @override
  String get dutchMe => '나';

  @override
  String get dutchPayer => '결제자';

  @override
  String get dutchNameLabel => '정산 이름';

  @override
  String get dutchNamePlaceholder => '예: 팀 저녁 회식';

  @override
  String get dutchPlaceLabel => '장소';

  @override
  String get dutchPlacePlaceholder => '장소 또는 상호명';

  @override
  String get dutchTotalLabel => '총 금액';

  @override
  String get dutchDateLabel => '날짜';

  @override
  String get dutchAddNamePlaceholder => '이름 입력 후 추가';

  @override
  String get dutchNameAlreadyAdded => '이미 넣은 이름이에요.';

  @override
  String get dutchAdd => '추가';

  @override
  String get dutchNext => '다음';

  @override
  String get dutchPrev => '이전';

  @override
  String get dutchParticipant => '참여자';

  @override
  String get dutchDeleteTitle => '더치페이 삭제';

  @override
  String dutchDeleteConfirm(String title) {
    return '\"$title\" 더치페이를 삭제할까요? 삭제한 더치페이는 되돌릴 수 없어요.';
  }

  @override
  String get dutchRequestAll => '일괄 요청';

  @override
  String get dutchNoName => '(이름 없음)';

  @override
  String get dutchStartTitle => '더치페이 시작';

  @override
  String get dutchSplitMethod => '분배 방식';

  @override
  String get dutchSplitEqualTitle => 'N분의 1';

  @override
  String get dutchSplitEqualSub => '균등 분배';

  @override
  String get dutchSplitRatioTitle => '비율';

  @override
  String get dutchSplitRatioSub => '인원수 · 기준';

  @override
  String get dutchSplitCustomTitle => '개별 금액';

  @override
  String get dutchSplitCustomSub => '각자 다르게';

  @override
  String get dutchIncludeMyself => '나도 포함해서 분배';

  @override
  String get dutchIncludeMyselfOffDesc => '내가 전액 결제, 다른 사람 몫만 받아요';

  @override
  String get dutchSourceSub => '참여자에게 송금 요청';

  @override
  String get dutchRequestMsgLabel => '요청 메시지 (선택)';

  @override
  String get dutchRequestMsgPlaceholder => '참여자에게 함께 보낼 한마디를 적어주세요';

  @override
  String get dutchCreated => '정산이 만들어졌어요';

  @override
  String get expLoadError => '거래를 불러오지 못했어요';

  @override
  String get expTransfersLoadError => '이체 내역을 불러오지 못했어요.';

  @override
  String get expEmptyDay => '이 날의 거래가 없어요';

  @override
  String get expTotal => '합계';

  @override
  String get expFiltering => '필터 중';

  @override
  String expFilteringBy(String name) {
    return '$name 필터 중';
  }

  @override
  String get expViewList => '목록';

  @override
  String get expViewCalendar => '달력';

  @override
  String expTxCount(int count) {
    return '$count건';
  }

  @override
  String get expAddShort => '추가';

  @override
  String get expActionFailed => '실패';

  @override
  String expDeleteConfirm(String name) {
    return '\"$name\" 거래를 삭제할까요? 연결된 자산 잔액이 함께 바뀌어요. 삭제한 거래는 되돌릴 수 없어요.';
  }

  @override
  String get expSplitMismatch => '분할 내역과 금액이 달라요';

  @override
  String expSplitDiff(String total, String sum, String diff) {
    return '새 총액 $total원 · 분할 합계 $sum원 · $diff원 차이';
  }

  @override
  String get expSplitReconcile => '분할 내역 맞추기';

  @override
  String get expPresetLoad => '프리셋 불러오기';

  @override
  String get expPresetApplied => '적용됨';

  @override
  String get expPresetSaveCurrent => '현재 입력값 저장';

  @override
  String get expPresetEmpty =>
      '저장된 프리셋이 없어요. 자주 쓰는 내역을 입력 후 “현재 입력값 저장”을 눌러보세요.';

  @override
  String get expPresetFilled => '프리셋 값이 채워졌어요. 금액 · 내역만 수정해서 저장하세요.';

  @override
  String get expClear => '해제';

  @override
  String get expSaveFailed => '저장 실패';

  @override
  String get expPresetSaveTitle => '프리셋으로 저장';

  @override
  String get expPresetNamePlaceholder => '예: 점심 도시락';

  @override
  String get presetNameDuplicate => '같은 이름의 프리셋이 이미 있어요.';

  @override
  String expPresetLockAmount(String amount) {
    return '금액 잠금 — 적용 시 $amount원 자동 채움';
  }

  @override
  String get expPayCash => '현금';

  @override
  String get expPayCard => '카드';

  @override
  String get expPayTransfer => '계좌이체';

  @override
  String get expPayOther => '기타';

  @override
  String get expAutoLock => '자동 생성';

  @override
  String get expAutoSourceTradeRealized =>
      '주식을 팔아 생긴 실현손익이에요. 금액은 매매 내역에서 계산돼요.';

  @override
  String get expAutoSourceTransferInterest => '이체에 붙은 이자예요. 금액은 이체 내역에서 계산돼요.';

  @override
  String get expAutoSourceCardCarryover =>
      '카드를 등록할 때 적은 이전 미결제 사용액이에요. 금액은 카드 수정에서 바꿔요.';

  @override
  String get expAutoSourceDefault => '자동으로 만들어진 거래예요. 원래 거래를 지우면 함께 사라져요.';

  @override
  String get expPresetLock => '프리셋 잠금';

  @override
  String get expSubcategory => '세부 카테고리';

  @override
  String expTopCategorySuffix(String name) {
    return '$name (상위)';
  }

  @override
  String get expIncomeSource => '수입처';

  @override
  String get expPayee => '거래처';

  @override
  String get expIncomeSourcePlaceholder => '예: 월급';

  @override
  String get expPayeePlaceholder => '예: 회사 앞 도시락';

  @override
  String get expIncomeMethod => '수입 방식';

  @override
  String get expNone => '선택 안 함';

  @override
  String get expDepositAccount => '입금 계좌';

  @override
  String get expAccountCard => '계좌 · 카드';

  @override
  String get expAssetLoadError => '자산 로드 실패';

  @override
  String get expWithdrawAccount => '보내는 계좌';

  @override
  String get expTransferToAccount => '받는 계좌';

  @override
  String get expSelect => '선택';

  @override
  String get expTransferSameAsset => '보낼/받을 자산은 달라야 해요.';

  @override
  String get expFeeOptional => '수수료 (선택)';

  @override
  String get expInterest => '이자';

  @override
  String get expInterestHint => '상환액 중 이자 몫 — 부채는 이자를 뺀 만큼만 줄어들어요';

  @override
  String expInterestSplit(String principal, String interest) {
    return '원금 $principal원 · 이자 $interest원';
  }

  @override
  String get expDateTime => '날짜 · 시간';

  @override
  String get expMemoPlaceholder => '예: 점심, 회식 등';

  @override
  String get expIncomeDetail => '수입 상세';

  @override
  String get expExpenseDetail => '지출 상세';

  @override
  String get expTxFallback => '거래';

  @override
  String get expUncategorized => '미분류';

  @override
  String get expNotSelected => '미선택';

  @override
  String get expThisMonth => '이번 달';

  @override
  String expTimesCount(int count) {
    return '$count회';
  }

  @override
  String get expItem => '항목';

  @override
  String get expFilterApply => '필터 적용';

  @override
  String expNSelected(int count) {
    return '$count개 선택';
  }

  @override
  String get expPeriodCustom => '직접 선택';

  @override
  String get expDateRangeError => '시작일이 종료일보다 늦을 수 없어요.';

  @override
  String get expTxType => '거래 종류';

  @override
  String get expAmountRange => '금액 범위';

  @override
  String get expMinAmount => '최소 금액';

  @override
  String get expMaxAmount => '최대 금액';

  @override
  String get expSplitSave => '분할 저장';

  @override
  String get expSplitRemove => '분할 해제';

  @override
  String get expSplitLoadError => '분할 내역 로드 실패';

  @override
  String get expAddAmount => '추가 금액';

  @override
  String get expSplitRemoveConfirm => '이 거래의 분할 내역을 모두 지워요. 지운 내역은 되돌릴 수 없어요.';

  @override
  String get expClearFailed => '해제 실패';

  @override
  String get expSplitMatches => '분할 합계가 총액과 일치해요';

  @override
  String get expSplitSum => '분할 합계';

  @override
  String get expTotalAmount => '총액';

  @override
  String get expSplitTotalChanged => '총액이 바뀌어 분할을 맞춰야 해요';

  @override
  String get expSplitMismatchTotal => '분할 합계가 총액과 달라요';

  @override
  String get expSplitCheckItems => '분할 항목을 확인해주세요';

  @override
  String get expShort => '부족';

  @override
  String get expOver => '초과';

  @override
  String get expQuickAdjust => '빠르게 맞추기';

  @override
  String get expProrate => '비례 배분';

  @override
  String get expProrateDesc => '비중대로 자동 조정';

  @override
  String get expApplyToLargest => '큰 항목 반영';

  @override
  String get expApplyToLargestDesc => '가장 큰 항목에 차액';

  @override
  String get expAdjustItem => '조정 항목';

  @override
  String get expAdjustItemDesc => '부족분을 새 항목으로';

  @override
  String get expRecommended => '추천';

  @override
  String get expOriginalTx => '원 거래';

  @override
  String get expAddItem => '항목 추가';

  @override
  String get expSplitEven => '균등 분배';

  @override
  String get expSplitRatio => '분할 비율';

  @override
  String get expDeleteItem => '항목 삭제';

  @override
  String get expItemNamePlaceholder => '항목 이름 (선택)';

  @override
  String get exportTitle => '데이터 내보내기';

  @override
  String exportShareText(String range) {
    return '데이터 내보내기 ($range)';
  }

  @override
  String get exportSuccess => '내보냈어요.';

  @override
  String get exportTypeExpense => '거래 내역';

  @override
  String get exportTypeAsset => '자산 · 계좌';

  @override
  String get exportTypeBudget => '예산 설정';

  @override
  String get exportTypeCategory => '카테고리';

  @override
  String get exportTypeMemo => '메모';

  @override
  String get exportTypeCalendar => '캘린더 일정';

  @override
  String get exportTypeTodo => '할 일';

  @override
  String get exportFormatCsvDesc => '엑셀 · 구글 시트';

  @override
  String get exportFormatExcelDesc => 'Microsoft Excel';

  @override
  String get exportFormatJsonDesc => '개발자 · 백업';

  @override
  String get exportPeriodThisMonth => '이번 달';

  @override
  String get exportPeriodLastMonth => '지난 달';

  @override
  String get exportPeriodLast3Months => '최근 3개월';

  @override
  String get exportPeriodThisYear => '올해';

  @override
  String get exportPeriodCustom => '사용자 지정';

  @override
  String get exportPeriodTitle => '기간 선택';

  @override
  String get exportDateRangeError => '시작일이 종료일보다 늦을 수 없어요.';

  @override
  String exportTypesTitle(int count) {
    return '데이터 종류 — $count개 선택됨';
  }

  @override
  String get exportTypesDesc => '내보낼 데이터를 골라주세요. 여러 종류는 ZIP으로 묶어요.';

  @override
  String exportCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString건';
  }

  @override
  String get exportFormatTitle => '파일 형식';

  @override
  String get exportMaskLabel => '민감 정보 가리기 (잔액 · 금액 · 기관)';

  @override
  String get exportPreview => '미리보기';

  @override
  String get exportRun => '내보내기';

  @override
  String get exportEmpty => '이 기간에 내보낼 데이터가 없어요.';

  @override
  String exportPreviewRows(int count) {
    return '상위 $count행 미리보기';
  }

  @override
  String get fileAttachTitle => '첨부 파일';

  @override
  String get fileTooltipGallery => '갤러리';

  @override
  String get fileTooltipCamera => '카메라';

  @override
  String get fileTooltipFile => '파일';

  @override
  String fileUploadComplete(String name) {
    return '$name 파일을 올렸어요.';
  }

  @override
  String get fileUploadFailed => '파일을 올리지 못했어요.';

  @override
  String get fileDeleteTitle => '파일 삭제';

  @override
  String fileDeleteConfirm(String name) {
    return '\"$name\" 파일을 삭제할까요? 삭제한 파일은 되돌릴 수 없어요.';
  }

  @override
  String get fileDeleteFailed => '파일을 삭제하지 못했어요.';

  @override
  String get fileLoadError => '첨부 로드 실패';

  @override
  String get fileEmpty => '첨부된 파일 없음';

  @override
  String get moreGroupMoney => '돈 관리';

  @override
  String get moreGroupDaily => '일상';

  @override
  String get moreGroupPersonal => '개인화';

  @override
  String get moreGroupSystem => '계정 · 시스템';

  @override
  String get moreItemStocks => '증권';

  @override
  String get moreItemStats => '통계';

  @override
  String get moreItemRecurring => '반복 거래';

  @override
  String get moreItemAccountCard => '계좌 · 카드 관리';

  @override
  String get moreItemCardBenefits => '카드 혜택';

  @override
  String get moreItemDisplay => '표시 설정';

  @override
  String get moreItemAccount => '계정';

  @override
  String get moreDescExpense => '지출 · 수입 · 이체';

  @override
  String get moreDescAsset => '계좌 · 카드 · 투자 · 부채';

  @override
  String get moreDescStocks => '시세 · 보유 · 관심 · 호가';

  @override
  String get moreDescBudget => '월간 예산 · 카테고리별 한도';

  @override
  String get moreDescSavingGoal => '목표 · 진행률';

  @override
  String get moreDescStats => '카테고리 · 추이 · 비교';

  @override
  String get moreDescRecurring => '구독 · 고정비';

  @override
  String get moreDescAccountCard => '계좌 · 카드 관리';

  @override
  String get moreDescCalendar => '일정 · 반복 · 알림';

  @override
  String get moreDescTodo => '마감 · 우선순위 · 태그';

  @override
  String get moreDescMemo => '분류 · 고정 · 검색';

  @override
  String get moreDescDutchPay => '정산 · 친구 · 송금 요청';

  @override
  String get moreDescCardBenefits => '신용 · 체크 카드 검색';

  @override
  String get moreDescCategories => '지출 · 수입';

  @override
  String get moreDescPresets => '자주 쓰는 내역';

  @override
  String get moreDescDisplay => '테마 · 언어 · 통화';

  @override
  String get moreDescSettings => '전체 설정 메뉴';

  @override
  String get moreDescNotifications => '푸시 · 이메일 · 방해 금지';

  @override
  String get moreDescExport => 'CSV · Excel · JSON';

  @override
  String get moreDescAccount => '프로필 · 보안 · 구독';

  @override
  String get settingsDescCategory => '지출 · 수입 카테고리 추가 · 수정 · 삭제';

  @override
  String get settingsDescAccountCard => '계좌 · 카드 관리';

  @override
  String get settingsDescBudget => '월간 예산 · 카테고리별 한도';

  @override
  String get settingsDescSavingGoal => '목표 추가 · 수정 · 삭제 및 진행률 관리';

  @override
  String get settingsDescRecurring => '구독 · 고정 결제 · 정기 수입을 한곳에서';

  @override
  String get settingsDescPreset => '자주 쓰는 내역을 한 번 탭으로 채우기';

  @override
  String get settingsDescTodoTag => '할 일 태그 이름 · 색 관리';

  @override
  String get settingsDescMemoTag => '메모 태그 이름 · 색 관리';

  @override
  String get settingsDescCalendarLabel => '전 캘린더 공용 라벨 관리';

  @override
  String get settingsDescCalendarShare => '다중 캘린더 생성과 멤버 공유 설정';

  @override
  String get settingsDescAppearance => '테마 · 언어 · 기준 지역 · 기본 통화';

  @override
  String get settingsDescNotifications => '결제 예정 · 예산 초과 알림';

  @override
  String get settingsDescExport => 'CSV · Excel · JSON으로 데이터 백업';

  @override
  String get settingsDescAccount => '프로필 · 보안 · 로그아웃';

  @override
  String get settingsDescPrivacyPolicy => '수집 항목 · 보유기간 · 권리 안내';

  @override
  String get settingsDescGuide => '화면별 사용법과 자주 묻는 질문';

  @override
  String get moreSearchHint => '메뉴 검색';

  @override
  String get moreSearchEmpty => '검색 결과가 없어요';

  @override
  String get settingsGroupDataMgmt => '데이터 관리';

  @override
  String get settingsMenuCategory => '카테고리 관리';

  @override
  String get settingsMenuAccountCard => '계좌 · 카드 관리';

  @override
  String get settingsMenuBudget => '예산 설정';

  @override
  String get settingsMenuRecurring => '반복 거래 관리';

  @override
  String get settingsMenuPreset => '프리셋 관리';

  @override
  String get settingsGroupTagsLabels => '태그 · 라벨';

  @override
  String get settingsGroupShare => '공유';

  @override
  String get settingsMenuCalendarShare => '캘린더 관리 · 공유';

  @override
  String get settingsMenuCalendarLabel => '캘린더 라벨';

  @override
  String get settingsGroupApp => '앱 환경';

  @override
  String get settingsMenuAppearance => '표시 설정';

  @override
  String get settingsGroupData => '데이터';

  @override
  String get settingsGroupAccount => '계정';

  @override
  String get settingsMenuAccountMgmt => '계정 관리';

  @override
  String get settingsMenuPrivacyPolicy => '개인정보 처리방침';

  @override
  String get settingsPrivacyOpenFailed => '처리방침을 열지 못했어요. 잠시 뒤 다시 시도해주세요.';

  @override
  String get settingsGroupHelp => '도움말';

  @override
  String get settingsMenuGuide => '설명서';

  @override
  String get settingsGuideOpenFailed => '설명서를 열지 못했어요. 잠시 뒤 다시 시도해주세요.';

  @override
  String get appearanceTitle => '표시 설정';

  @override
  String get appearanceTheme => '테마';

  @override
  String get appearanceThemeLight => '라이트';

  @override
  String get appearanceThemeLightDesc => '밝은 배경';

  @override
  String get appearanceThemeDark => '다크';

  @override
  String get appearanceThemeDarkDesc => '어두운 배경';

  @override
  String get appearanceThemeSystem => '시스템';

  @override
  String get appearanceThemeSystemDesc => 'OS 설정 따라가기';

  @override
  String get hideAmountsTitle => '금액 가리기';

  @override
  String get hideAmountsSectionDesc => '가릴 카드를 골라 두세요. 저장할 때 한 번만 본인 확인을 해요.';

  @override
  String get hideAmountsTabAll => '전체';

  @override
  String get hideAmountsSelectAll => '모두 선택';

  @override
  String get hideAmountsClearAll => '모두 해제';

  @override
  String hideAmountsScreensCount(int count, int total) {
    return '가릴 화면 · $count / $total';
  }

  @override
  String get hideAmountsSaveFailed => '금액 가리기를 저장하지 못했어요.';

  @override
  String get hideAmountsSaveFailedToast => '금액 가리기를 저장하지 못했어요. 잠시 뒤 다시 시도해주세요.';

  @override
  String get hideAmountsDiscardTitle => '저장하지 않고 나가기';

  @override
  String get hideAmountsDiscardBody => '고른 내용이 사라져요.';

  @override
  String get hideAmountsDiscardConfirm => '나가기';

  @override
  String get hideAmountsKindLabel => '거래 종류';

  @override
  String get hideAmountsKindNote =>
      '화면과 상관없이 그 종류의 거래 금액을 가려요. 수입이나 지출을 가리면 합계 · 잔액도 함께 가려져요.';

  @override
  String get hideAmountsKindHelp => '거래 종류 안내';

  @override
  String get hideAmountsTabsLabel => '화면 고르기';

  @override
  String get hideAmountsScreensTitle => '가릴 화면 · ';

  @override
  String get hideCardKindExpense => '지출 거래';

  @override
  String get hideCardKindIncome => '수입 거래';

  @override
  String get hideCardKindTransfer => '이체 거래';

  @override
  String get hideAmountsPageHome => '홈';

  @override
  String get hideAmountsPageAsset => '자산';

  @override
  String get hideAmountsPageLedger => '가계부';

  @override
  String get hideAmountsPageStats => '통계';

  @override
  String get hideAmountsPageBudget => '예산';

  @override
  String get hideAmountsPageStocks => '증권';

  @override
  String get hideAmountsPageDutchpay => '더치페이';

  @override
  String get hideAmountsPageEtc => '기타';

  @override
  String get hideCardHomeNetWorth => '순자산';

  @override
  String get hideCardHomeMonthExpense => '이번달 수입 · 지출';

  @override
  String get hideCardHomeCategoryDonut => '카테고리 도넛';

  @override
  String get hideCardHomeBudget => '예산 진행';

  @override
  String get hideCardHomeTodaySpend => '오늘 지출';

  @override
  String get hideCardHomeUpcoming => '예정 결제';

  @override
  String get hideCardAssetNetWorth => '총 순자산 · 추이';

  @override
  String get hideCardAssetComposition => '자산 구성';

  @override
  String get hideCardAssetAccounts => '계좌 · 예금';

  @override
  String get hideCardAssetInvestments => '투자';

  @override
  String get hideCardAssetCards => '카드';

  @override
  String get hideCardAssetLoans => '대출';

  @override
  String get hideCardAssetSavingGoals => '저축목표';

  @override
  String get hideCardAssetUpcoming => '예정 결제';

  @override
  String get hideCardAssetDetail => '자산 상세';

  @override
  String get hideCardAssetManage => '계좌 · 카드 관리';

  @override
  String get hideCardLedgerMonthSummary => '월 합계';

  @override
  String get hideCardLedgerCalendar => '캘린더 금액';

  @override
  String get hideCardLedgerTxList => '거래 목록';

  @override
  String get hideCardLedgerTxDetail => '거래 상세';

  @override
  String get hideCardStatsCategory => '카테고리 탭';

  @override
  String get hideCardStatsTrend => '추이 탭';

  @override
  String get hideCardStatsCompare => '비교 탭';

  @override
  String get hideCardBudgetHeader => '예산 요약';

  @override
  String get hideCardBudgetPace => '소비 속도';

  @override
  String get hideCardBudgetStatus => '상태';

  @override
  String get hideCardBudgetCategories => '카테고리별 예산';

  @override
  String get hideCardBudgetCompliance => '준수율';

  @override
  String get hideCardBudgetManage => '예산 관리';

  @override
  String get hideCardStocksSummary => '평가액 요약';

  @override
  String get hideCardStocksHoldings => '보유 종목';

  @override
  String get hideCardStocksDetail => '종목 상세';

  @override
  String get hideCardDutchpaySummary => '더치페이 요약';

  @override
  String get hideCardDutchpaySessions => '정산 목록';

  @override
  String get hideCardEtcSearch => '검색 결과';

  @override
  String get hideCardEtcRecurring => '정기 거래';

  @override
  String get hideCardEtcPreset => '프리셋';

  @override
  String get appearanceHideAmount => '금액 가리기';

  @override
  String get appearanceRegion => '기준 지역';

  @override
  String get appearanceRegionDesc =>
      '\'오늘\'과 통계의 하루를 이 지역 기준으로 계산해요. 화면의 시간은 기기 시간대로 보여요.';

  @override
  String get appearanceCurrency => '기본 통화';

  @override
  String get appearanceCurrencyKrw => '대한민국 원';

  @override
  String get appearanceCurrencyUsd => '미국 달러';

  @override
  String get appearanceCurrencyEur => '유로';

  @override
  String get appearanceCurrencyJpy => '일본 엔';

  @override
  String get appearanceCurrencyDesc => '새 자산 · 거래를 만들 때 이 통화가 먼저 골라져요.';

  @override
  String get appearanceRegionLoadError => '기준 지역을 불러오지 못했어요';

  @override
  String get appearanceCurrencyLoadError => '기본 통화를 불러오지 못했어요';

  @override
  String get appearanceSaveFailed => '설정을 바꾸지 못했어요. 잠시 뒤 다시 시도해주세요.';

  @override
  String get passwordChanged => '비밀번호를 바꿨어요.';

  @override
  String get passwordChangeFailed => '비밀번호를 바꾸지 못했어요. 잠시 뒤 다시 시도해주세요.';

  @override
  String get passwordCurrent => '현재 비밀번호';

  @override
  String get passwordChangeDescription => '현재 비밀번호를 확인한 뒤 새 비밀번호로 바꿔요';

  @override
  String get passwordCurrentInvalid => '현재 비밀번호가 맞지 않아요';

  @override
  String get passwordNew => '새 비밀번호';

  @override
  String get passwordNewConfirm => '새 비밀번호 확인';

  @override
  String get passwordMismatch => '새 비밀번호가 일치하지 않아요';

  @override
  String get passwordMatched => '새 비밀번호가 일치해요';

  @override
  String get passwordRuleLength => '8자 이상';

  @override
  String get passwordRuleSpecial => '특수문자 1자 이상';

  @override
  String get passwordSameAsCurrent => '현재 비밀번호와 다른 비밀번호를 입력해주세요';

  @override
  String get passwordChangeAction => '저장';

  @override
  String get accountTitle => '계정';

  @override
  String get accountDefaultName => '사용자';

  @override
  String accountJoined(String date) {
    return '가입 $date';
  }

  @override
  String get accountEditComingSoon => '프로필 수정은 곧 열려요.';

  @override
  String get accountSecurity => '보안';

  @override
  String get accountPasswordDesc => '주기적으로 바꾸면 안전해요';

  @override
  String get accountTwoFa => '2단계 인증';

  @override
  String get accountDevices => '로그인된 기기';

  @override
  String get accountCurrentDevice => '현재 기기';

  @override
  String get devicesTitle => '로그인된 기기';

  @override
  String get devicesIntro => '이 계정으로 로그인된 기기예요. 낯선 기기가 있으면 로그아웃해주세요.';

  @override
  String get devicesCurrent => '현재 기기';

  @override
  String get devicesUnknown => '알 수 없는 기기';

  @override
  String devicesLastUsed(String when) {
    return '마지막 사용 $when';
  }

  @override
  String get devicesEmpty => '로그인된 기기가 없어요';

  @override
  String get devicesLoadError => '기기 목록을 불러오지 못했어요';

  @override
  String get devicesLoadErrorHint => '잠시 뒤 다시 시도해주세요.';

  @override
  String devicesLogoutLabel(String device) {
    return '$device 로그아웃';
  }

  @override
  String get devicesLogoutFailed => '로그아웃하지 못했어요.';

  @override
  String get devicesLogout => '로그아웃';

  @override
  String devicesLogoutTitle(String device) {
    return '$device에서 로그아웃할까요?';
  }

  @override
  String get devicesLogoutConfirm => '그 기기는 다시 로그인해야 해요.';

  @override
  String get devicesLogoutAll => '모든 기기에서 로그아웃';

  @override
  String get devicesLogoutAllTitle => '모든 기기에서 로그아웃할까요?';

  @override
  String get devicesLogoutAllConfirm => '지금 쓰는 기기도 로그아웃돼요. 다시 로그인해야 해요.';

  @override
  String get accountConnected => '연결된 계정';

  @override
  String get accountNotConnected => '연결 안 됨';

  @override
  String get accountConnect => '연결';

  @override
  String get accountLinked => '연결됨';

  @override
  String get accountDisconnect => '해제';

  @override
  String get accountProvidersError => '연결 상태를 불러오지 못했어요';

  @override
  String get accountLinkError => '계정을 연결하지 못했어요.';

  @override
  String get accountUnlinkError => '연결을 해제하지 못했어요.';

  @override
  String accountLinkedToast(String name) {
    return '$name 계정이 연결됐어요.';
  }

  @override
  String get accountUnlinkedToast => 'Google 연결을 해제했어요.';

  @override
  String get accountSecuritiesDesc => '토스 · 나무 등 증권사 API 키를 연결해요';

  @override
  String get accountBilling => '구독 · 결제';

  @override
  String accountNextBilling(String date) {
    return '다음 결제 $date · ';
  }

  @override
  String get accountProActive => 'Pro 이용 중';

  @override
  String get accountProPromo => '증권 투자는 Pro 전용 · 지금 시작하기';

  @override
  String get accountProStart => 'Pro 시작';

  @override
  String get accountManage => '계정 관리';

  @override
  String get accountLogoutDesc => '이 기기에서만';

  @override
  String get accountWithdraw => '그루 담다 이용 해지';

  @override
  String get accountWithdrawDesc => '복구할 수 없어요';

  @override
  String accountAppVersion(String version) {
    return '앱 버전 $version';
  }

  @override
  String get accountAppVersionLatest => '최신 버전';

  @override
  String accountAppVersionUpdate(String version) {
    return '새 버전 $version';
  }

  @override
  String get accountLogoutConfirm => '이 기기에서 로그아웃할까요?';

  @override
  String get accountWithdrawTitle => '그루 담다 이용 해지';

  @override
  String get withdrawIntro => '이용을 해지하면 바로 로그인이 막히고 되돌릴 수 없어요.';

  @override
  String withdrawImpactCalendarsOwned(int count) {
    return '내가 만든 공유 캘린더 $count개가 삭제되고 멤버도 볼 수 없어요';
  }

  @override
  String withdrawImpactCalendarMemberships(int count) {
    return '참여 중인 캘린더 $count개에서 빠져요';
  }

  @override
  String withdrawImpactDutchPaysOwned(int count) {
    return '내가 만든 정산 $count개가 삭제돼요';
  }

  @override
  String withdrawImpactDutchPayParticipations(int count) {
    return '참여 중인 정산 $count개에 탈퇴한 사용자로 남아요';
  }

  @override
  String get withdrawIrreversibleTitle => '되돌릴 수 없어요';

  @override
  String get withdrawIrreversibleRejoin => '같은 아이디와 이메일로는 다시 가입할 수 없어요.';

  @override
  String get withdrawIrreversibleData => '해지한 뒤에는 기록을 다시 볼 수 없어요.';

  @override
  String get withdrawDataRetention =>
      '가계부 데이터는 개인정보 처리방침에 따라 보관 후 파기돼요. 필요한 자료는 해지 전에 내보내주세요.';

  @override
  String get withdrawReasonLabel => '떠나는 이유';

  @override
  String get withdrawReasonPlaceholder => '알려주면 다음에 더 낫게 만들게요';

  @override
  String get withdrawNext => '계속';

  @override
  String get withdrawConfirm => '해지하기';

  @override
  String get withdrawReauthIntro => '본인이 맞는지 한 번만 더 확인할게요.';

  @override
  String get withdrawUseEmailCode => '비밀번호가 없다면 메일로 코드 받기';

  @override
  String get withdrawUsePassword => '비밀번호로 확인하기';

  @override
  String get withdrawCodeLabel => '인증 코드';

  @override
  String get withdrawCodePlaceholder => '6자리 숫자';

  @override
  String get withdrawSendCode => '코드 받기';

  @override
  String get withdrawResendCode => '다시 받기';

  @override
  String get withdrawCodeSent => '메일로 코드를 보냈어요.';

  @override
  String get withdrawFailed => '해지하지 못했어요. 잠시 뒤 다시 시도해주세요.';

  @override
  String get withdrawBlockedSubscription => '구독이 남아 있어 아직 해지할 수 없어요.';

  @override
  String withdrawBlockedSubscriptionUntil(String date) {
    return '구독이 $date까지 남아 있어 아직 해지할 수 없어요.';
  }

  @override
  String get withdrawBlockedOther => '아직 해지할 수 없는 상태예요.';

  @override
  String get withdrawBlockedHint => '구독을 먼저 해지하면 남은 기간이 끝난 뒤에 이용 해지를 할 수 있어요.';

  @override
  String get withdrawnTitle => '이용 해지가 끝났어요';

  @override
  String get withdrawnBody =>
      '그동안 그루 담다를 써 주셔서 감사했습니다. 남은 데이터는 개인정보 처리방침에 따라 보관 후 파기돼요.';

  @override
  String get withdrawnToLogin => '로그인 화면으로';

  @override
  String get withdrawCodeDescription => '10분 안에 입력해주세요 · 5번 틀리면 다시 받아요.';

  @override
  String get withdrawCodeIncomplete => '인증 코드 6자리를 입력해주세요.';

  @override
  String get withdrawCodeWrong => '코드가 맞지 않거나 시간이 지났어요. 확인하거나 다시 받아주세요.';

  @override
  String withdrawResendCooldown(int seconds) {
    return '다시 받기($seconds초)';
  }

  @override
  String get withdrawBusy => '해지하는 중';

  @override
  String get withdrawLoadFailedTitle => '해지 정보를 불러오지 못했어요';

  @override
  String get sheetLeaveTitle => '작성한 내용이 사라져요';

  @override
  String get sheetLeaveDescription => '나가면 입력한 내용이 저장되지 않아요.';

  @override
  String get sheetLeaveStay => '계속 작성';

  @override
  String get sheetLeaveLeave => '나가기';

  @override
  String get notiSettings => '알림 설정';

  @override
  String get notiSettingsLoadError => '알림 설정을 불러오지 못했어요';

  @override
  String get notiKindTitle => '알림 종류';

  @override
  String get notiPayment => '결제 알림';

  @override
  String get notiPaymentDesc => '결제 예정일 D-1, 결제일 당일 알림';

  @override
  String notiBudgetDesc(int threshold) {
    return '카테고리 예산 $threshold% · 100% 도달';
  }

  @override
  String get notiAutoRecord => '자동 기록 알림';

  @override
  String get notiAutoRecordDesc => '반복 거래가 자동으로 기록되었을 때';

  @override
  String get notiDutchPay => '더치페이 알림';

  @override
  String get notiDutchPayDesc => '송금 요청 / 정산 완료 알림';

  @override
  String get notiCalendarDesc => '캘린더 일정 시작 15분 전';

  @override
  String get notiWeeklyReport => '주간 리포트';

  @override
  String get notiWeeklyReportDesc => '매주 월요일 오전 9시';

  @override
  String get notiMonthlyReport => '월간 리포트';

  @override
  String get notiMonthlyReportDesc => '매월 1일 오전 9시';

  @override
  String get notiPush => '푸시 알림';

  @override
  String get notiPushOn => '모든 알림이 켜져 있어요';

  @override
  String get notiPushOff => '알림이 꺼져 있어요';

  @override
  String get notiThresholdTitle => '예산 알림 기준';

  @override
  String get notiQuietTitle => '방해 금지 시간';

  @override
  String get notiQuietToggle => '방해 금지 사용';

  @override
  String get notiQuietToggleDesc => '시간대를 지정해 자동 무음';

  @override
  String get notiQuietStart => '시작';

  @override
  String get notiQuietEnd => '종료';

  @override
  String get notiSoundTitle => '소리 · 진동';

  @override
  String get notiSound => '알림음';

  @override
  String get notiSoundDesc => '앱 알림 사운드';

  @override
  String get notiSoundChime => '차임';

  @override
  String get notiSoundDefault => '기본';

  @override
  String get notiSoundNone => '무음';

  @override
  String get notiVibration => '진동';

  @override
  String get notiVibrationDesc => '모바일에서 진동 함께 알림';

  @override
  String get notiEmailTitle => '이메일 알림';

  @override
  String get notiEmailToggle => '이메일 받기';

  @override
  String get notiEmailNone => '등록된 이메일이 없어요';

  @override
  String get notiEmailFreq => '발송 주기';

  @override
  String get notiEmailDaily => '매일';

  @override
  String get notiEmailWeekly => '매주';

  @override
  String get notiEmailMonthly => '매월';

  @override
  String get presetManageTitle => '프리셋 관리';

  @override
  String get presetDetailTitle => '프리셋 상세';

  @override
  String get presetTypeLabel => '종류';

  @override
  String get presetDeleteConfirm => '이미 기록된 거래는 그대로 남아요. 삭제한 프리셋은 되돌릴 수 없어요.';

  @override
  String get presetDeleteFailed => '프리셋을 삭제하지 못했어요.';

  @override
  String get presetSortUsed => '많이 쓴 순';

  @override
  String get presetSortRecent => '최근 사용';

  @override
  String get presetSortName => '이름순';

  @override
  String presetListTitle(int count) {
    return '프리셋 $count개';
  }

  @override
  String presetUses(int count) {
    return '$count번';
  }

  @override
  String get presetSortLabel => '정렬';

  @override
  String get presetLoadFailed => '프리셋을 불러오지 못했어요';

  @override
  String get presetCategoryLoadFailed => '카테고리를 불러오지 못했어요';

  @override
  String presetDeleteConfirmTitle(String name) {
    return '\"$name\" 프리셋을 삭제할까요?';
  }

  @override
  String get presetNoteFixed => '고정 금액';

  @override
  String presetNoteUses(int count) {
    return '$count번 썼어요';
  }

  @override
  String get presetNoteUnused => '아직 쓰지 않았어요';

  @override
  String presetNoteLast(int month, int day) {
    return '마지막 $month월 $day일';
  }

  @override
  String get presetFixedOn => '켬';

  @override
  String get presetFixedOff => '끔';

  @override
  String get presetNameRequired => '이름을 입력해주세요.';

  @override
  String get presetNameTooLong => '프리셋 이름은 12자 이내로 입력해주세요.';

  @override
  String get presetCategoryRequired => '카테고리를 골라주세요.';

  @override
  String get presetFromRequired => '보내는 계좌를 골라주세요.';

  @override
  String get presetToRequired => '받는 계좌를 골라주세요.';

  @override
  String get presetSaveFailed => '저장하지 못했어요. 잠시 뒤 다시 시도해주세요.';

  @override
  String get presetAmountLabel => '금액';

  @override
  String get presetFeeLabel => '수수료';

  @override
  String get presetAmountBlank => '비워 둠';

  @override
  String get presetAmountHint => '비워 두면 불러올 때 금액을 직접 넣어요.';

  @override
  String get presetMemoPlaceholder => '선택 사항';

  @override
  String get presetInterestTooLarge => '이자는 금액보다 클 수 없어요.';

  @override
  String presetSelectOf(String field) {
    return '$field 선택';
  }

  @override
  String presetNoneOf(String field) {
    return '$field 없음';
  }

  @override
  String get presetNoneValue => '없음';

  @override
  String get presetMemoNone => '메모 없음';

  @override
  String get presetNoAccount => '계좌 · 카드 없음';

  @override
  String get presetNoPayment => '결제 수단 없음';

  @override
  String get presetNoCategoryOfKind => '이 종류의 카테고리가 없어요.';

  @override
  String get presetFromAccount => '보내는 계좌';

  @override
  String get presetToAccount => '받는 계좌';

  @override
  String get presetShowAll => '모두 보기';

  @override
  String get presetPickTitle => '프리셋 고르기';

  @override
  String get presetSearch => '프리셋 검색';

  @override
  String get presetNoResult => '찾는 프리셋이 없어요.';

  @override
  String get presetAdd => '프리셋 추가';

  @override
  String get presetAmountEmpty => '금액 비움';

  @override
  String get presetNoCategory => '카테고리 없음';

  @override
  String get presetEmptyTitle => '저장된 프리셋이 없어요';

  @override
  String get presetEmptyDesc =>
      '자주 쓰는 내역(점심 · 교통비 등)을 저장해 두면 내역을 추가할 때 한 번 눌러 카테고리 · 계좌 · 내역을 채워요.';

  @override
  String get presetEditTitle => '프리셋 수정';

  @override
  String get presetSubmitAdd => '추가';

  @override
  String get presetName => '프리셋 이름';

  @override
  String get presetMerchant => '기본 내역';

  @override
  String get presetMerchantPlaceholder => '예: 회사 앞 도시락';

  @override
  String get presetAssetCard => '계좌 · 카드';

  @override
  String get recurringToggleFailed => '변경 실패';

  @override
  String get recurringDeleteTitle => '반복 거래 삭제';

  @override
  String recurringDeleteConfirm(String name) {
    return '\"$name\" 반복 설정을 삭제할까요? 이미 기록된 거래는 그대로 남아요. 삭제한 반복 설정은 되돌릴 수 없어요.';
  }

  @override
  String get recurringDeleteFailed => '삭제 실패';

  @override
  String get recurringAllList => '전체 목록';

  @override
  String get recurringAdd => '추가';

  @override
  String recurringFilterAll(int count) {
    return '전체 $count';
  }

  @override
  String recurringFilterExpense(int count) {
    return '지출 $count';
  }

  @override
  String recurringFilterIncome(int count) {
    return '수입 $count';
  }

  @override
  String recurringFilterTransfer(int count) {
    return '이체 $count';
  }

  @override
  String recurringFilterPaused(int count) {
    return '일시정지 $count';
  }

  @override
  String get recurringStatActive => '활성 반복';

  @override
  String recurringCount(int count) {
    return '$count개';
  }

  @override
  String get recurringPaused => '일시정지';

  @override
  String get recurringPauseAction => '정지';

  @override
  String get recurringMonthlyExpense => '매월 고정 지출';

  @override
  String get recurringMonthlyIncome => '매월 고정 수입';

  @override
  String get recurringUpcoming => '다가오는 7일';

  @override
  String recurringUpcomingCount(int count) {
    return '$count건 예정';
  }

  @override
  String get recurringToday => '오늘';

  @override
  String get recurringNoAccount => '계좌 없음';

  @override
  String recurringOccurrences(int executed, int max) {
    return '$executed/$max회';
  }

  @override
  String get recurringNext => '다음';

  @override
  String get recurringStart => '시작';

  @override
  String get recurringEmpty => '해당하는 반복 거래가 없어요';

  @override
  String get recurringIndefinite => '무기한';

  @override
  String get recurringNotifyShort => '알림';

  @override
  String get recurringAddTitle => '반복 거래 추가';

  @override
  String get recurringEditTitle => '반복 거래 수정';

  @override
  String get recurringSaveSubmit => '반복 저장';

  @override
  String get recurringSaveFailed => '저장 실패';

  @override
  String get recurringFrequencyLabel => '반복 주기';

  @override
  String get recurringDayOfWeekLabel => '요일';

  @override
  String get recurringDayOfMonthLabel => '반복 일자';

  @override
  String get recurringEndLabel => '종료';

  @override
  String get recurringExecutionTime => '실행 시각';

  @override
  String get recurringIndefiniteDesc => '중지할 때까지 계속 반복';

  @override
  String get recurringByCount => '횟수 지정';

  @override
  String get recurringTotal => '총';

  @override
  String get recurringTimesUnit => '회';

  @override
  String get recurringByDate => '종료일 지정';

  @override
  String get recurringOptions => '옵션';

  @override
  String get recurringAutoLog => '자동 기록';

  @override
  String get recurringNotifyDayBefore => '하루 전 알림';

  @override
  String get recurringNextDates => '다음 예정일';

  @override
  String get recurringSourceSub => '구독료 · 월세 등 정기 거래에 쓰여요';

  @override
  String recurringStartFrom(String date) {
    return '$date 시작';
  }

  @override
  String get recurringMerchant => '거래처';

  @override
  String get recurringMerchantPlaceholder => '예: 넷플릭스';

  @override
  String get recurringAssetCard => '계좌 · 카드';

  @override
  String get recurringAssetLoadError => '자산 로드 실패';

  @override
  String get recurringSelectNone => '선택 안 함';

  @override
  String get recurringStartDateLabel => '반복 시작일';

  @override
  String recurringParentCategory(String name) {
    return '$name (상위)';
  }

  @override
  String get savingGoalLoadError => '저축 목표 로드 실패';

  @override
  String get savingGoalFailTitle => '저축 목표를 불러오지 못했어요';

  @override
  String get savingGoalOverallProgress => '전체 진행률';

  @override
  String savingGoalListCount(int n) {
    return '목표 목록 · $n개';
  }

  @override
  String get savingGoalAddAction => '목표 추가';

  @override
  String get savingGoalManagePrompt => '설정에서 저축 목표를 추가해보세요.';

  @override
  String get savingGoalManageLink => '관리';

  @override
  String get savingGoalNoDeadline => '기한 없음';

  @override
  String get savingGoalCurrentLabel => '현재 모은 금액';

  @override
  String get savingGoalIconLabel => '아이콘';

  @override
  String get savingGoalEmpty => '아직 저축 목표가 없어요. ‘목표 추가’로 시작해보세요.';

  @override
  String get savingGoalActionFailed => '실패';

  @override
  String get savingGoalAchieved => '달성';

  @override
  String get savingGoalAdd => '저축 목표 추가';

  @override
  String get savingGoalSaveFailed => '저축 목표를 저장하지 못했어요.';

  @override
  String get savingGoalFirstContributeFailed => '목표는 만들었지만 첫 납입을 기록하지 못했어요.';

  @override
  String get savingGoalEdit => '저축 목표 수정';

  @override
  String get savingGoalSubmitAdd => '추가';

  @override
  String savingGoalDeleteTitle(String title) {
    return '\"$title\" 목표를 삭제할까요?';
  }

  @override
  String get savingGoalDeleteConfirm => '삭제한 저축 목표는 되돌릴 수 없어요.';

  @override
  String get savingGoalDeleteFailed => '저축 목표를 삭제하지 못했어요.';

  @override
  String get savingGoalNameLabel => '목표 이름';

  @override
  String get savingGoalNameHint => '예: 유럽 여행';

  @override
  String get savingGoalNameDuplicate => '같은 이름의 목표가 이미 있어요.';

  @override
  String get savingGoalAmountLabel => '목표 금액';

  @override
  String get savingGoalDeadlineLabel => '목표일';

  @override
  String get savingGoalDeadlineHint => '없음';

  @override
  String get savingGoalColorLabel => '색상';

  @override
  String get savingGoalErrName => '목표 이름을 입력해주세요.';

  @override
  String savingGoalErrNameTooLong(int max) {
    return '목표 이름은 $max자 이내로 입력해주세요.';
  }

  @override
  String get savingGoalErrAmount => '목표 금액을 입력해주세요.';

  @override
  String get savingGoalErrAmountTooLarge => '목표 금액은 100억원까지 입력할 수 있어요.';

  @override
  String get savingGoalErrCurrentExceeds => '현재 모은 금액이 목표 금액보다 클 수 없어요.';

  @override
  String get savingGoalDeadlineClear => '목표일 지우기';

  @override
  String get searchAdvancedFilter => '고급 필터';

  @override
  String get searchAdvancedOn => '고급 필터, 적용 중';

  @override
  String get searchHeading => '검색';

  @override
  String get searchHint => '거래 검색';

  @override
  String get searchTypeGroup => '거래 종류';

  @override
  String get searchBadAmount => '최소 금액을 최대 금액보다 작게 해주세요';

  @override
  String get searchFailed => '검색하지 못했어요';

  @override
  String get searchFailedDesc => '잠시 뒤 다시 시도해주세요.';

  @override
  String get searchEmptyHint => '키워드, 가맹점, 메모로 검색해보세요';

  @override
  String get searchNoResults => '결과가 없어요';

  @override
  String get statsTabTrend => '추이';

  @override
  String get statsTabCompare => '비교';

  @override
  String get statsThisQuarter => '이번 분기';

  @override
  String get statsThisYear => '올해';

  @override
  String get statsCustomPeriod => '선택 기간';

  @override
  String get statsLastMonth => '지난 달';

  @override
  String get statsLastQuarter => '지난 분기';

  @override
  String get statsLastYear => '작년';

  @override
  String get statsPrevPeriod => '이전 기간';

  @override
  String statsMomMonth(String prev) {
    return '$prev 대비';
  }

  @override
  String get statsMomPrevMonth => '전월';

  @override
  String get statsMomPrevQuarter => '전분기';

  @override
  String get statsMomPrevYear => '전년';

  @override
  String get statsDailyAvg => '하루 평균';

  @override
  String get statsMonthlyAvg => '월 평균';

  @override
  String get statsPeriodPickerTitle => '기간 선택';

  @override
  String get statsNoData => '데이터가 없어요.';

  @override
  String get statsNoDataShort => '데이터 없음';

  @override
  String get statsUnassigned => '미지정';

  @override
  String statsCategoryDetail(String name) {
    return '$name 세부';
  }

  @override
  String statsPeriodSpending(String period) {
    return '$period 지출';
  }

  @override
  String get statsSpendingByCategory => '카테고리별 지출';

  @override
  String get statsNoCategoryData => '카테고리 데이터가 없어요.';

  @override
  String get statsTopMerchantsTitle => '많이 쓴 가맹점 TOP 5';

  @override
  String get statsNoMerchantData => '가맹점 데이터가 없어요.';

  @override
  String get statsNoName => '(이름 없음)';

  @override
  String get statsTimeMorning => '아침';

  @override
  String get statsTimeLunch => '점심';

  @override
  String get statsTimeAfternoon => '오후';

  @override
  String get statsTimeEvening => '저녁';

  @override
  String get statsTimeLateNight => '심야';

  @override
  String get statsTimeDawn => '새벽';

  @override
  String get statsPatternTitle => '요일 · 시간대 지출 패턴';

  @override
  String get statsPatternDesc => '색이 진할수록 지출이 많은 시간대예요 (단위: 원)';

  @override
  String statsTooFewTx(String period) {
    return '$period 거래가 아직 적어요.';
  }

  @override
  String get statsLegendLow => '적음';

  @override
  String get statsLegendHigh => '많음';

  @override
  String get statsTotalPrefix => '총';

  @override
  String statsDaysTotal(int days) {
    return '$days일 합계';
  }

  @override
  String statsMomCalculating(String prev) {
    return '$prev 대비 계산 중…';
  }

  @override
  String statsMomUnavailable(String prev) {
    return '$prev 비교 불가';
  }

  @override
  String get statsTopCategory => '가장 많이 쓴 카테고리';

  @override
  String get statsTopMerchant => '가장 많이 쓴 가맹점';

  @override
  String get statsIncomeExpenseTrend => '수입 · 지출 추이';

  @override
  String get statsNoTrendData => '추이 데이터가 없어요.';

  @override
  String get statsAvgIncome => '평균 수입';

  @override
  String get statsAvgExpense => '평균 지출';

  @override
  String get statsNetSavings => '순저축';

  @override
  String get statsAvgSavings => '평균 저축';

  @override
  String get statsSavingsRate => '저축률';

  @override
  String statsSavingsInsight(int pct) {
    return '월 평균 수입의 $pct%를 저축하고 있어요';
  }

  @override
  String get statsDailyNetSavings => '일별 순저축';

  @override
  String get statsMonthlyNetSavings => '월별 순저축';

  @override
  String get statsCatTrendTitle => '주요 카테고리 월별 추이';

  @override
  String get statsCatTrendTop3 => '지출 TOP 3';

  @override
  String get statsIncomeMinusExpense => '수입 − 지출';

  @override
  String statsNoDataFor(String period) {
    return '$period 데이터 없음';
  }

  @override
  String statsCategoryByMom(String mom) {
    return '카테고리별 $mom';
  }

  @override
  String get statsCategoryDelta => '카테고리별 증감';

  @override
  String get statsSortByChange => '변화 큰 순';

  @override
  String get statsNoCompareData => '비교할 데이터가 없어요.';

  @override
  String get statsWeekdayTitle => '요일별 지출 비교';

  @override
  String get statsThisMonthShort => '이번 달';

  @override
  String get statsLastMonthShort => '지난 달';

  @override
  String statsWeekdayInsightDown(String prev, String day, String amount) {
    return '$day요일 지출이 $prev보다 $amount 줄었어요.';
  }

  @override
  String statsWeekdayInsightUp(String prev, String day, String amount) {
    return '$day요일 지출이 $prev보다 $amount 늘었어요.';
  }

  @override
  String statsWeekdayInsightSame(String prev) {
    return '$prev 비슷해요.';
  }

  @override
  String statsVsLastPrefix(String prev) {
    return '$prev보다';
  }

  @override
  String get statsVsLastDirLess => '덜';

  @override
  String get statsVsLastDirMore => '더';

  @override
  String statsVsLastSuffix(String prev) {
    return '썼어요';
  }

  @override
  String get statsCompareDailyAvg => '하루 평균';

  @override
  String get statsCompareTxCount => '거래 건수';

  @override
  String get statsComparePerTx => '건당 평균';

  @override
  String statsCountValue(int count) {
    return '$count건';
  }

  @override
  String get stocksChartLoadFailed => '차트를 불러오지 못했어요.';

  @override
  String get stocksSearch => '종목 검색';

  @override
  String get stocksSearchPlaceholder => '종목 검색';

  @override
  String stocksSearchNoResults(String query) {
    return '\'$query\'에 대한 검색 결과가 없어요';
  }

  @override
  String get stocksTabHoldings => '보유';

  @override
  String get stocksTabWatch => '관심';

  @override
  String get stocksTabDiscover => '발견';

  @override
  String get stocksNoHoldings => '보유 중인 종목이 없어요';

  @override
  String stocksSharesHeld(String qty) {
    return '$qty주 보유';
  }

  @override
  String get stocksRange1d => '1일';

  @override
  String get stocksRange1w => '1주';

  @override
  String get stocksRange1m => '1개월';

  @override
  String get stocksRange3m => '3개월';

  @override
  String get stocksRange1y => '1년';

  @override
  String stocksUnitCount(int count) {
    return '$count개';
  }

  @override
  String stocksSharesUnit(String qty) {
    return '$qty주';
  }

  @override
  String get stocksTradingSuspended => '거래정지';

  @override
  String get stocksTradingNormal => '정상';

  @override
  String get stocksWarningLiquidationTrading => '정리매매';

  @override
  String get stocksWarningOverheated => '단기과열';

  @override
  String get stocksWarningShortTermOverheat => '단기과열';

  @override
  String get stocksWarningExcessiveRise => '이상급등';

  @override
  String get stocksWarningInvestmentWarning => '투자경고';

  @override
  String get stocksWarningInvestmentRisk => '투자위험';

  @override
  String get stocksWarningInvestmentCaution => '투자주의';

  @override
  String get stocksWarningVi => 'VI 발동';

  @override
  String get stocksWarningViStatic => '정적 VI';

  @override
  String get stocksWarningViDynamic => '동적 VI';

  @override
  String get stocksWarningStockWarrants => '신주인수권';

  @override
  String get stocksWarningAdministrative => '관리종목';

  @override
  String get stocksWarningAdjustmentOfShares => '주식병합 · 분할';

  @override
  String get stocksNoWatchlist => '관심 종목이 없어요';

  @override
  String get stocksDetailTitle => '종목 상세';

  @override
  String get stocksMarketHoliday => '휴장';

  @override
  String stocksMarketTrading(String time) {
    return '장중 · $time';
  }

  @override
  String stocksMarketOpensAt(String time) {
    return '개장 $time';
  }

  @override
  String get stocksMarketClosed => '장마감';

  @override
  String get stocksMarketKr => '국내';

  @override
  String get stocksMarketUs => '미국';

  @override
  String get stocksMyEval => '내 투자 평가금액';

  @override
  String get stocksPurchaseAmount => '매입금액';

  @override
  String get stocksHoldingsLabel => '보유 종목';

  @override
  String get stocksExchangeRate => '환율(USD)';

  @override
  String get stocksSell => '매도';

  @override
  String get stocksBuy => '매수';

  @override
  String get stocksFeeUs => '미국주식 매매수수료 0.1% · 환전 수수료 별도 적용';

  @override
  String get stocksFeeKr =>
      '국내주식 매매수수료 무료 (2026.6까지) · 이후 KRX 0.015% / NXT 0.014%';

  @override
  String get stocksEvalAmount => '평가금액';

  @override
  String get stocksEvalPnl => '평가손익';

  @override
  String get stocksQuantityHeld => '보유수량';

  @override
  String get stocksReturnRate => '수익률';

  @override
  String get stocksDayPnl => '일간 손익';

  @override
  String get stocksAvgPrice => '평균단가';

  @override
  String get stocksFeesTax => '수수료 · 세금';

  @override
  String get stocksSellable => '매도가능';

  @override
  String get stocksMyHoldings => '내 보유';

  @override
  String get stocksMarket => '시장';

  @override
  String get stocksInstrumentType => '종목 유형';

  @override
  String get stocksInstrumentStock => '주식';

  @override
  String get stocksCurrency => '통화';

  @override
  String get stocksMarketCap => '시가총액';

  @override
  String get stocksUpperLimit => '상한가';

  @override
  String get stocksLowerLimit => '하한가';

  @override
  String get stocksListingDate => '상장일';

  @override
  String get stocksSharesOutstanding => '발행주식수';

  @override
  String get stocksTradingStatus => '거래상태';

  @override
  String get stocksBasicInfo => '기본 정보';

  @override
  String get stocksBidVolume => '매수 잔량';

  @override
  String get stocksAskVolume => '매도 잔량';

  @override
  String get stocksGainers => '급상승';

  @override
  String get stocksLosers => '급하락';

  @override
  String get stocksVolume => '거래량';

  @override
  String get stocksOrderbookLoading => '호가를 불러오는 중이에요';

  @override
  String get stocksOrderbookEmpty => '호가 정보가 없어요';

  @override
  String get stocksTradesLoading => '체결 내역을 불러오는 중이에요';

  @override
  String get stocksTradesEmpty => '체결 내역이 없어요';

  @override
  String get stocksOrderbook => '호가';

  @override
  String get stocksTrades => '체결';

  @override
  String get stocksTradeTime => '체결시각';

  @override
  String get stocksTradePrice => '체결가';

  @override
  String get stocksTradeVolume => '체결량';

  @override
  String get stocksDailyPrices => '일별 시세';

  @override
  String get stocksDailyPricesLoading => '일별 시세를 불러오는 중이에요';

  @override
  String get stocksDailyPricesEmpty => '일별 시세가 없어요';

  @override
  String get stocksDate => '일자';

  @override
  String get stocksClosePrice => '종가';

  @override
  String get stocksChangeRate => '등락률';

  @override
  String get stocksSearchHint => '종목 이름이나 코드 (국내 + 미국 · 중국 · 일본 · 홍콩 · 베트남)';

  @override
  String get stocksPriceUnavailable => '토스 시세 미지원 종목이에요 (국내 · 미국만 제공)';

  @override
  String get stocksRankingLoading => '순위를 불러오는 중이에요';

  @override
  String get stocksRankingEmpty => '집계된 순위가 없어요';

  @override
  String get stocksWatchDefaultGroupName => '관심';

  @override
  String get stocksWatchGroupAdd => '그룹 추가';

  @override
  String get stocksWatchGroupRename => '그룹 이름 바꾸기';

  @override
  String get stocksWatchGroupDelete => '그룹 삭제';

  @override
  String get stocksWatchGroupNamePlaceholder => '그룹 이름';

  @override
  String get stocksWatchGroupSaveFail => '그룹을 저장하지 못했어요.';

  @override
  String get stocksWatchAddFail => '관심 종목에 넣지 못했어요. 잠시 뒤 다시 시도해주세요.';

  @override
  String get stocksWatchGroupDeleteFail => '그룹을 삭제하지 못했어요.';

  @override
  String get stocksWatchRemoveFail => '관심 종목에서 빼지 못했어요. 잠시 뒤 다시 시도해주세요.';

  @override
  String get stocksMarketToggleKr => '국내';

  @override
  String get stocksMarketToggleUs => '미국';

  @override
  String get todoAdd => '할 일 추가';

  @override
  String get todoEditTitle => '할 일 수정';

  @override
  String get todoDeleteTitle => '할 일 삭제';

  @override
  String todoDeleteConfirm(String title) {
    return '\"$title\" 할 일을 삭제할까요? 되돌릴 수 없어요.';
  }

  @override
  String get todoDetail => '자세히';

  @override
  String get todoCompletionRate => '완료율';

  @override
  String get todoQuickAddPlaceholder => '할 일을 입력하고 Enter';

  @override
  String get todoTitlePlaceholder => '할 일을 적어주세요';

  @override
  String get todoTitleRequired => '제목을 입력해주세요.';

  @override
  String get todoDueDate => '마감일';

  @override
  String get todoUnset => '미설정';

  @override
  String get todoTag => '태그';

  @override
  String get todoTagSelect => '태그 선택';

  @override
  String get todoTagNone => '태그 없음';

  @override
  String get todoPriorityLabel => '우선순위';

  @override
  String get todoPriorityImportant => '중요';

  @override
  String get todoPriorityRelaxed => '여유';

  @override
  String get todoContentLabel => '메모';

  @override
  String get todoContentPlaceholder => '예: # 제목 / **굵게** / - 항목 / - [ ] 체크';

  @override
  String get todoEditMode => '편집';

  @override
  String get todoPreview => '미리보기';

  @override
  String get todoNoContent => '없음';

  @override
  String get todoEmptyToday => '오늘 할 일이 없어요';

  @override
  String get todoEmptyWeek => '이번 주는 한가해요';

  @override
  String get todoEmptyDone => '아직 완료된 일이 없어요';

  @override
  String get todoEmptyAll => '할 일이 없어요';

  @override
  String get todoEmptyAddHint => '위 입력칸으로 빠르게 추가해보세요.';

  @override
  String get todoNewProject => '새 프로젝트';

  @override
  String get todoProjectNamePlaceholder => '프로젝트 이름';

  @override
  String get todoDescOptional => '설명 (선택)';

  @override
  String get todoAdding => '추가 중...';

  @override
  String get todoAddProject => '프로젝트 추가';

  @override
  String get todoRegisteredProjects => '등록된 프로젝트';

  @override
  String get todoDeleteProjectTitle => '프로젝트 삭제';

  @override
  String get todoNewTag => '태그 추가';

  @override
  String get todoTagNamePlaceholder => '태그 이름';

  @override
  String get todoRegisteredTags => '등록된 태그';

  @override
  String get todoDeleteTagTitle => '태그 삭제';

  @override
  String todoDeleteTagConfirm(String name, int count) {
    return '\"$name\" 태그를 삭제하면 이 태그를 쓰는 할 일 $count건은 태그 없음으로 남아요. 삭제한 태그는 되돌릴 수 없어요.';
  }

  @override
  String get todoActionFailed => '실패';

  @override
  String get todoAddFailed => '추가 실패';

  @override
  String get todoDeleteFailed => '할 일을 삭제하지 못했어요.';

  @override
  String get todoUpdateFailed => '수정 실패';

  @override
  String get todoStatusChangeFailed => '상태 변경 실패';

  @override
  String get todoMoveFailed => '이동 실패';

  @override
  String get todoLoadError => '할 일을 불러오지 못했어요';

  @override
  String get todoProjectLoadError => '프로젝트 로드 실패';

  @override
  String get todoTagLoadError => '태그를 불러오지 못했어요';

  @override
  String get subManageTitle => '구독 관리';

  @override
  String get subUsingPro => '담다 Pro 이용 중';

  @override
  String get subUsingFree => 'Free 플랜 이용 중';

  @override
  String subNextBilling(String date, String amount) {
    return '다음 결제 $date · $amount';
  }

  @override
  String subProUntil(String date) {
    return '$date까지 이용';
  }

  @override
  String get subFreeLockedDesc => '증권 연동 · 실시간 시세가 잠겨 있어요';

  @override
  String get subSpotlightDesc =>
      '증권 투자는 Pro 전용이에요. 실시간 시세 · 호가, 국내외 종목 검색, 관심종목, 보유 손익까지 — Pro를 구독하면 증권 탭이 바로 열려요.';

  @override
  String get subCycleMonthly => '월간';

  @override
  String get subCycleYearly => '연간';

  @override
  String get subCycleLabel => '결제 주기';

  @override
  String subCycleYearlyOff(int pct) {
    return '연간 $pct%↓';
  }

  @override
  String subYearlyPerMonth(String amount, int pct) {
    return '월 $amount 꼴 · $pct% 절약';
  }

  @override
  String get subMonthlyBilling => '월 단위 결제';

  @override
  String get subFeatureCompare => '기능 비교';

  @override
  String get subCurrentPlan => '현재 플랜';

  @override
  String get subFreeCaption => '기본 가계부 기능';

  @override
  String get subFeatLedger => '가계부 · 자산 관리';

  @override
  String get subFeatBudget => '예산 · 저축 목표 · 캘린더';

  @override
  String get subFeatSecurities => '증권사 연동 · 실시간 시세 · 자산 실시간 금액';

  @override
  String get subStarted => '담다 Pro 구독이 시작됐어요.';

  @override
  String get subFailed => '구독을 시작하지 못했어요.';

  @override
  String get subCancelConfirmTitle => '구독 해지';

  @override
  String subCancelConfirmMsg(String date) {
    return '해지하면 $date부터 Free 플랜으로 전환되고 증권 탭이 잠겨요. 그 전까지는 Pro 기능을 계속 쓸 수 있어요.';
  }

  @override
  String get subCancel => '구독 해지';

  @override
  String get subKeep => '유지하기';

  @override
  String get subCanceled => '구독을 해지했어요.';

  @override
  String get subCancelFailed => '구독을 해지하지 못했어요.';

  @override
  String get subNextBillingDate => '다음 결제일';

  @override
  String get subStartPro => 'Pro 시작하기';

  @override
  String get subLoadFailed => '구독 정보를 불러오지 못했어요';

  @override
  String get subLoadFailedDesc => '잠시 뒤 다시 시도해주세요.';

  @override
  String get secLoadFailed => '증권 정보를 불러오지 못했어요';

  @override
  String subPricePerMonth(String amount) {
    return '$amount / 월';
  }

  @override
  String subPricePerYear(String amount) {
    return '$amount / 년';
  }

  @override
  String subNextBillingNoAmount(String date) {
    return '다음 결제 $date';
  }

  @override
  String get subConnected => '연결됨';

  @override
  String subBrokerStatusConnectedAt(String date) {
    return '연결됨 · $date 확인';
  }

  @override
  String get subBrokerStatusNone => '연결 안 됨';

  @override
  String subBrokerDisconnectConfirmTitle(String broker) {
    return '$broker 연결을 해제할까요?';
  }

  @override
  String get subBrokerDisconnectConfirmBody =>
      '해제하면 이 증권사의 보유 주식과 시세를 더 이상 가져오지 않아요. 다시 연결하려면 키를 새로 입력해야 해요.';

  @override
  String get subConnecting => '연결 중…';

  @override
  String get subConnect => '연결하기';

  @override
  String get subBrokerInvalidCred => '인증정보가 올바르지 않아요.';

  @override
  String get subBrokerConnectFailed => '증권사를 연결하지 못했어요.';

  @override
  String get subDisconnectFailed => '연결을 해제하지 못했어요.';

  @override
  String get memoNew => '메모 추가';

  @override
  String get memoEditTitle => '메모 수정';

  @override
  String get memoLoadError => '메모를 불러오지 못했어요';

  @override
  String memoSectionPinned(int count) {
    return '고정 · $count';
  }

  @override
  String memoSectionAll(int count) {
    return '모든 메모 · $count';
  }

  @override
  String get memoEmptyDesc => '오른쪽 아래 + 버튼으로 첫 메모를 써보세요.';

  @override
  String get memoSearchEmptyDesc => '다른 검색어를 입력해보세요.';

  @override
  String get memoUntitled => '제목 없음';

  @override
  String get memoDeleteTitle => '메모 삭제';

  @override
  String memoDeleteConfirm(String name) {
    return '\"$name\" 메모를 삭제할까요? 삭제한 메모는 되돌릴 수 없어요.';
  }

  @override
  String get memoFieldTitle => '제목';

  @override
  String get memoTitleRequired => '제목을 입력해주세요.';

  @override
  String get memoFieldContent => '내용';

  @override
  String get memoContentPlaceholder => '여기에 메모를 작성해주세요';

  @override
  String get memoFieldTag => '태그';

  @override
  String get memoTagNone => '태그 없음';

  @override
  String get memoTagEmptyHint => '태그는 설정 › 메모 태그에서 만들어요.';

  @override
  String get memoAllChip => '전체';

  @override
  String get memoLoadFailedDesc => '잠시 뒤 다시 시도해주세요.';

  @override
  String get memoTagFilter => '태그로 거르기';

  @override
  String get memoSaved => '저장했어요.';

  @override
  String get memoSaveFailed => '저장하지 못했어요. 잠시 뒤 다시 시도해주세요.';

  @override
  String get memoSaveFailedToast => '저장하지 못했어요.';

  @override
  String get memoDeleteFailed => '삭제하지 못했어요.';

  @override
  String get memoPinFailed => '고정을 바꾸지 못했어요. 잠시 뒤 다시 시도해주세요.';

  @override
  String memoModifiedAt(String time) {
    return '$time 수정';
  }

  @override
  String memoMoreOf(String name) {
    return '$name 더보기';
  }

  @override
  String get memoSwipeUnpin => '해제';

  @override
  String get mtagSaveFailed => '저장하지 못했어요. 잠시 뒤 다시 시도해주세요.';

  @override
  String get mtagDeleteFailed => '삭제하지 못했어요. 잠시 뒤 다시 시도해주세요.';

  @override
  String get ttagSaveFailed => '저장하지 못했어요. 잠시 뒤 다시 시도해주세요.';

  @override
  String get ttagDeleteFailed => '삭제하지 못했어요. 잠시 뒤 다시 시도해주세요.';

  @override
  String get memoNewTag => '태그 추가';

  @override
  String get memoTagNamePlaceholder => '예: 아이디어';

  @override
  String get memoDeleteTagTitle => '태그 삭제';

  @override
  String memoDeleteTagConfirm(String name, int count) {
    return '\"$name\" 태그를 삭제하면 이 태그를 쓰는 메모 $count건은 태그 없음으로 남아요. 삭제한 태그는 되돌릴 수 없어요.';
  }

  @override
  String get memoTagLoadError => '태그를 불러오지 못했어요';

  @override
  String get mtagTitle => '메모 태그';

  @override
  String get mtagDesc =>
      '메모에 붙이는 태그예요. 메모 화면의 거르기에 쓰여요. 태그를 지우면 그 메모는 \'태그 없음\' 으로 남아요.';

  @override
  String get mtagEmpty => '태그가 없어요';

  @override
  String get mtagEditTitle => '태그 수정';

  @override
  String get mtagNameLabel => '이름';

  @override
  String get mtagColorLabel => '색상';

  @override
  String mtagUsage(int count) {
    return '$count건에 사용 중';
  }

  @override
  String get memoPinToTop => '상단에 고정';

  @override
  String get memoFieldColor => '색상';

  @override
  String get dateToday => '오늘';

  @override
  String get dateTomorrow => '내일';

  @override
  String get dateYesterday => '어제';

  @override
  String dateInDays(int n) {
    return '$n일 후';
  }

  @override
  String dateDaysAgo(int n) {
    return '$n일 전';
  }

  @override
  String get dateJustNow => '방금 전';

  @override
  String dateMinutesAgo(int n) {
    return '$n분 전';
  }

  @override
  String dateHoursAgo(int n) {
    return '$n시간 전';
  }

  @override
  String get todoNoDue => '마감일 없음';

  @override
  String todoGroupLabel(String label, int count) {
    return '$label · $count건';
  }

  @override
  String dayN(int d) {
    return '$d일';
  }

  @override
  String weekN(int n) {
    return '$n주';
  }

  @override
  String get countUnit => '건';

  @override
  String get dayUnit => '일';

  @override
  String get constHeroTodayTarget => '오늘의 목표 별자리';

  @override
  String constHeroCollectedBang(String name) {
    return '$name 수집!';
  }

  @override
  String constHeroStarlightCount(int lit, int goal) {
    return '$lit/$goal 별빛';
  }

  @override
  String get constHeroCaptionDone => '도감에 새겨졌어요 · 완료할수록 더 반짝여요';

  @override
  String constHeroCaptionProgress(int count) {
    return '오늘 $count건 완료';
  }

  @override
  String constHeroCaptionMemo(int count) {
    return '메모 별빛 +$count';
  }

  @override
  String constHeroCaptionRemain(int count) {
    return '$count별 남음';
  }

  @override
  String get constHeroCaptionEmpty => '할 일을 완료하면 별이 켜져요';

  @override
  String constHeroStreak(int count) {
    return '연속 관측 $count일';
  }

  @override
  String constHeroGuardInfo(int count) {
    return '보호 $count · 중요 +3 · 보통 +2 · 여유 +1';
  }

  @override
  String get constMySkyTitle => '나의 밤하늘';

  @override
  String constMySkyTotal(int count) {
    return '누적 $count개';
  }

  @override
  String get constMySkySubtitle => '최근 2주 · 흐린 밤도 기록에 남아요';

  @override
  String get constCollectionTitle => '별자리 도감';

  @override
  String constCollectionProgress(int collected, int total) {
    return '$collected/$total 수집';
  }

  @override
  String get constCollectionSubtitle => '별 개수만큼 별빛을 모으면 수집돼요';

  @override
  String get constCollectionTodayBadge => '오늘의 목표';

  @override
  String constCollectionTimes(int count) {
    return '$count회';
  }

  @override
  String get constCollectionNotCollected => '미수집';

  @override
  String get constDetailNotMet => '아직 만나지 못한 별자리예요';

  @override
  String get todoDetailTitle => '할 일 상세';

  @override
  String get todoDetailStatus => '상태';

  @override
  String get todoStatusPending => '대기';

  @override
  String get todoDetailCompletedAt => '완료 일시';

  @override
  String get todoDetailContent => '메모';

  @override
  String get memoDetailNoContent => '내용 없음';

  @override
  String get calEventDetailTitle => '일정 상세';

  @override
  String get calDetailNone => '없음';

  @override
  String get exportTab => '내보내기';

  @override
  String get importTab => '가져오기';

  @override
  String get importSourceTitle => '어떤 앱에서 가져오나요?';

  @override
  String get importSourceDesc => '기존에 쓰던 가계부를 고르면 열 구조를 자동으로 맞춰요.';

  @override
  String get importSourceGroo => '그루 담다';

  @override
  String get importSourceGrooDesc => '그루 담다에서 내보낸 파일';

  @override
  String get importSourceEasybudget => '편한가계부 · 머니매니저';

  @override
  String get importSourceEasybudgetDesc => 'Excel 백업';

  @override
  String get importSourceBanksalad => '뱅크샐러드';

  @override
  String get importSourceBanksaladDesc => '가계부 내역';

  @override
  String get importSourceToss => '토스';

  @override
  String get importSourceTossDesc => '거래내역';

  @override
  String get importSourceCustom => '직접 매핑';

  @override
  String get importSourceCustomDesc => 'CSV · Excel 직접 연결';

  @override
  String get importUploadTitle => '파일 업로드';

  @override
  String get importUploadDesc =>
      'CSV 또는 Excel(.xlsx, .xls) 파일을 올려주세요. 최대 10MB.';

  @override
  String get importDropTitle => '파일 선택';

  @override
  String get importDropHint => '.csv · .xlsx · .xls 지원';

  @override
  String get importAnalyzing => '파일을 분석하는 중';

  @override
  String get importNotice =>
      '가져온 데이터는 기존 거래에 추가되며 덮어쓰지 않아요. 미리보기에서 중복 · 오류를 확인할 수 있어요.';

  @override
  String get importFileTitle => '가져올 파일';

  @override
  String importRowsDetected(int total, int valid) {
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);
    final intl.NumberFormat validNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String validString = validNumberFormat.format(valid);

    return '$totalString개 행 · 유효 $validString건';
  }

  @override
  String get importChange => '변경';

  @override
  String get importMapTitle => '열 매핑';

  @override
  String get importMapDesc => '파일의 열을 가계부 항목에 연결해요. 자동으로 찾은 값을 확인하고 바꿀 수 있어요.';

  @override
  String get importNotMapped => '— 가져오지 않음 —';

  @override
  String get importFieldSubcategory => '소분류';

  @override
  String get importFieldTime => '시간';

  @override
  String get importFieldMerchant => '거래처';

  @override
  String get importFieldPaymentMethod => '결제수단';

  @override
  String importBlockedTitle(String names) {
    return '$names 카테고리에 거래가 직접 등록돼 있어 하위 분류를 만들 수 없어요';
  }

  @override
  String get importBlockedDesc =>
      '해당 대분류를 쓰는 행은 저장에 실패해요. 그 카테고리의 거래를 하위로 옮기거나 파일의 분류를 바꿔주세요.';

  @override
  String get categoryMoveTxAction => '옮기기';

  @override
  String get categoryMoveTxTitle => '거래 옮기기';

  @override
  String get categoryMoveTxEntry => '거래 옮기기';

  @override
  String categoryMoveTxDesc(String name) {
    return '$name에 달린 거래 · 반복 거래 · 나눈 거래를 모두 옮겨요.';
  }

  @override
  String get categoryMoveTxModeNew => '새 하위 만들기';

  @override
  String get categoryMoveTxModeExisting => '기존 카테고리로';

  @override
  String get categoryMoveTxMode => '옮기는 방법';

  @override
  String get categoryMoveTxChildName => '만들 하위 이름';

  @override
  String get categoryMoveTxChildPlaceholder => '예: 강의';

  @override
  String categoryMoveTxNewHint(String name) {
    return '$name 아래에 만들고 거래를 모두 그리로 옮겨요. 그러면 다른 하위도 만들 수 있어요.';
  }

  @override
  String get categoryMoveTxTarget => '옮길 카테고리';

  @override
  String get categoryMoveTxTargetPlaceholder => '카테고리 고르기';

  @override
  String get categoryMoveTxHint => '같은 종류의 맨 아래 카테고리만 고를 수 있어요.';

  @override
  String get categoryMoveTxNoTarget => '옮길 수 있는 카테고리가 없어요. 먼저 하나 만들어주세요.';

  @override
  String get categoryMoveTxErrChildName => '만들 하위 이름을 입력해주세요.';

  @override
  String get categoryMoveTxErrTarget => '옮길 카테고리를 골라주세요.';

  @override
  String categoryMoveTxDone(int count) {
    return '$count건을 옮겼어요.';
  }

  @override
  String get importFieldDate => '날짜';

  @override
  String get importFieldType => '수입 · 지출';

  @override
  String get importFieldAmount => '금액';

  @override
  String get importFieldCategory => '카테고리';

  @override
  String get importFieldAsset => '자산 · 결제수단';

  @override
  String get importFieldMemo => '메모';

  @override
  String importPreviewDesc(int dup) {
    final intl.NumberFormat dupNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String dupString = dupNumberFormat.format(dup);

    return '중복 의심 $dupString건';
  }

  @override
  String get importIncome => '수입';

  @override
  String get importExpense => '지출';

  @override
  String get importDupBadge => '중복?';

  @override
  String get importOptionsTitle => '가져오기 옵션';

  @override
  String get importOptDupSkip => '중복 거래 건너뛰기';

  @override
  String importOptDupSkipDesc(int dup) {
    final intl.NumberFormat dupNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String dupString = dupNumberFormat.format(dup);

    return '날짜 · 금액 · 내용이 같은 $dupString건을 제외해요.';
  }

  @override
  String get importOptAutoCat => '새 카테고리 자동 생성';

  @override
  String get importOptAutoCatDesc => '없는 카테고리는 자동으로 만들어요.';

  @override
  String get importPrev => '이전';

  @override
  String importDoImport(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString건 가져오기';
  }

  @override
  String get importDoneTitle => '가져오기 완료';

  @override
  String importDoneCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString건을 가져왔어요';
  }

  @override
  String importDoneDetail(int skipped, int failed) {
    final intl.NumberFormat skippedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String skippedString = skippedNumberFormat.format(skipped);
    final intl.NumberFormat failedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String failedString = failedNumberFormat.format(failed);

    return '건너뛴 거래 $skippedString건 · 못 가져온 거래 $failedString건.';
  }

  @override
  String get importAnother => '다른 파일 가져오기';

  @override
  String get importStepUpload => '파일 선택';

  @override
  String get importStepMapping => '열 매핑';

  @override
  String get importStepDone => '완료';

  @override
  String get exportTabsLabel => '데이터 내보내기 · 가져오기';

  @override
  String get exportSelectAll => '모두';

  @override
  String get exportCountsFailed => '건수를 불러오지 못했어요.';

  @override
  String get exportPreviewFailed => '미리보기를 불러오지 못했어요.';

  @override
  String get exportRangePlaceholder => '기간 선택';

  @override
  String get exportStalled => '파일을 받는 중에 멈췄어요.';

  @override
  String get exportFailed => '내보내지 못했어요.';

  @override
  String get exportPreviewTabsLabel => '미리보기 데이터 종류';

  @override
  String importStepMeta(int current, int total) {
    return '$current / $total단계';
  }

  @override
  String get importBusy => '가져오는 중';

  @override
  String get withdrawPasswordPlaceholder => '현재 비밀번호를 입력해주세요';

  @override
  String get withdrawLocked => '5번 틀렸어요. 코드를 다시 받아주세요.';

  @override
  String get importStepUploadDesc => '가져올 앱과 파일을 골라주세요.';

  @override
  String get importStepMappingDesc => '열이 맞는지 확인하고 가져올 거래를 점검해주세요.';

  @override
  String get withdrawCodeHint => '메일함에 코드가 안 보이면 스팸함도 확인해주세요.';

  @override
  String get withdrawPasswordWrong => '비밀번호가 맞지 않아요. 다시 확인해주세요.';

  @override
  String get withdrawLoadFailedDescription => '잠시 뒤 다시 시도해주세요.';

  @override
  String exportPreviewFooter(int rows, int types, int total) {
    final intl.NumberFormat rowsNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String rowsString = rowsNumberFormat.format(rows);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '상위 $rowsString행 미리보기 · 선택한 $types종 합계 약 $totalString건';
  }

  @override
  String get exportPreviewEmptyTitle => '미리볼 데이터가 없어요';

  @override
  String importCreatedCatTitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '새로 만든 카테고리 $countString개';
  }

  @override
  String importNewCatMore(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '외 $countString개';
  }

  @override
  String importFailuresTitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '실패한 행 $countString건';
  }

  @override
  String importFailureLine(int line) {
    return '$line행';
  }

  @override
  String importFailuresCapped(int total, int shown) {
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);
    final intl.NumberFormat shownNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String shownString = shownNumberFormat.format(shown);

    return '실패 $totalString건 중 앞의 $shownString건만 보여줘요.';
  }

  @override
  String get importFailReasonDate => '날짜를 읽을 수 없어요';

  @override
  String get importFailReasonAmount => '금액을 읽을 수 없어요';

  @override
  String get importFailReasonType => '수입 · 지출 구분을 읽을 수 없어요';

  @override
  String get importFailReasonParentHasTx =>
      '이 카테고리에는 거래가 직접 달려 있어 하위 분류를 만들 수 없어요';

  @override
  String get importFailReasonResolve => '카테고리나 자산을 찾지 못했어요';

  @override
  String get importFailReasonSave => '저장하는 중에 오류가 나서 가져오지 못했어요';

  @override
  String get importFailReasonUnknown => '알 수 없는 이유로 가져오지 못했어요';

  @override
  String get importFileTooLarge => '파일은 10MB까지 올릴 수 있어요.';

  @override
  String get importFileInvalid => 'CSV 또는 Excel 파일만 올릴 수 있어요.';

  @override
  String get importBadgeError => '오류';

  @override
  String get importBadgeDup => '중복';

  @override
  String get importGoExpense => '가계부로 가기';

  @override
  String get calDetailDday => 'D-DAY';

  @override
  String calDetailDdayLeft(int n) {
    return 'D-$n';
  }

  @override
  String calDetailDdayPast(int n) {
    return '$n일 지남';
  }

  @override
  String calDetailDurationH(int h) {
    return '$h시간';
  }

  @override
  String calDetailDurationHM(int h, int m) {
    return '$h시간 $m분';
  }

  @override
  String calDetailDurationM(int m) {
    return '$m분';
  }

  @override
  String get categoryReorderEdit => '순서 바꾸기';

  @override
  String get categoryReorderHint =>
      '손잡이를 끌어 순서를 바꿔요. 상위는 상위끼리, 하위는 같은 상위 안에서 옮겨요.';

  @override
  String get txmSpendSummary => '소비 요약';

  @override
  String get txmInsightLessPre => '지난달보다 ';

  @override
  String txmInsightLessHl(String amount) {
    return '$amount 덜';
  }

  @override
  String get txmInsightLessPost => ' 쓰는 중';

  @override
  String get txmInsightMorePre => '지난달보다 ';

  @override
  String txmInsightMoreHl(String amount) {
    return '$amount 더';
  }

  @override
  String get txmInsightMorePost => ' 쓰는 중';

  @override
  String get txmInsightSame => '지난달과 비슷하게 쓰고 있어요';

  @override
  String get txmInsightNone => '이 달에는 거래 내역이 없어요';

  @override
  String get txmInsightTopCatPre => '이번 달 ';

  @override
  String get txmInsightTopCatPost => '에 가장 많이 썼어요';

  @override
  String txmPrevMonthBtn(String month) {
    return '$month 이용 내역 보기';
  }

  @override
  String txmEmptyMonth(String month) {
    return '$month 거래가 없어요';
  }

  @override
  String get txmEmptyMonthDesc => '다른 달을 살펴보거나 첫 거래를 추가해보세요.';

  @override
  String get txmToday => '오늘';

  @override
  String get txmYesterday => '어제';

  @override
  String expChipMin(String amount) {
    return '$amount 이상';
  }

  @override
  String expChipMax(String amount) {
    return '$amount 이하';
  }

  @override
  String tdmTodayLeft(int count) {
    return '오늘 할 일 $count개';
  }

  @override
  String get tdmTodayDone => '오늘 할 일 끝!';

  @override
  String get tdmNightSkyBtn => '밤하늘';

  @override
  String tdmStarlightHint(int lit, int goal, int left, String name) {
    return '별빛 $lit/$goal · $left개 더 모으면 $name 수집';
  }

  @override
  String tdmCollectedHint(String name, int streak) {
    return '$name 수집 완료 · 연속 $streak일';
  }

  @override
  String tdmDoneRatio(int done, int total) {
    return '$done/$total 완료';
  }

  @override
  String get tdmFilterTag => '태그';

  @override
  String get tdmHideDone => '완료한 할 일 숨기기';

  @override
  String tdmEmptyMonth(String month) {
    return '$month 할 일이 없어요';
  }

  @override
  String get tdmEmptyMonthDesc => '오른쪽 아래 + 버튼으로 추가해보세요.';

  @override
  String get tdmEmptyFilter => '조건에 맞는 할 일이 없어요';

  @override
  String get tdmEmptyFilterDesc => '조건을 바꾸거나 지워보세요.';

  @override
  String tdmStarToastGain(int gain, int left) {
    return '별빛 $gain개를 받아 별자리까지 $left개 남았어요.';
  }

  @override
  String tdmStarToastCollected(int gain) {
    return '별빛 $gain개를 받아 오늘의 별자리를 수집했어요.';
  }

  @override
  String constHeroLabel(String name, int lit, int goal) {
    return '오늘의 목표 별자리 $name $lit/$goal 별빛';
  }

  @override
  String get constFailToday => '밤하늘을 불러오지 못했어요';

  @override
  String get constFailSky => '나의 밤하늘을 불러오지 못했어요';

  @override
  String get constFailCollection => '별자리 도감을 불러오지 못했어요';

  @override
  String get constLoadFailedDesc => '잠시 뒤 다시 시도해주세요.';

  @override
  String get frpLoadFailed => '관측 리포트를 불러오지 못했어요';

  @override
  String frpRowName(String name) {
    return '관측 리포트, 오늘의 목표 $name';
  }

  @override
  String constMySkyCellToday(String date) {
    return '$date, 오늘';
  }

  @override
  String constMySkyCellCollected(String date, String name) {
    return '$date, 수집 $name';
  }

  @override
  String constMySkyCellCloudy(String date) {
    return '$date, 흐린 밤';
  }

  @override
  String constMySkyCellRest(String date) {
    return '$date, 쉰 밤';
  }

  @override
  String get constCollectionBadgeNew => 'NEW';

  @override
  String constCollectionViewOwnedNamed(String name) {
    return '$name 감상하기';
  }

  @override
  String constCollectionViewLockedNamed(String name) {
    return '$name 미리보기';
  }

  @override
  String constDetailSkyName(String name) {
    return '$name 별자리 그림';
  }

  @override
  String get constDetailStarCountLabel => '별 개수';

  @override
  String constDetailStarCountValue(int count) {
    return '$count개';
  }

  @override
  String get constDetailCollectLabel => '수집';

  @override
  String constDetailCollectValue(int count) {
    return '$count번';
  }

  @override
  String get frpPrevWeek => '이전 주';

  @override
  String get frpNextWeek => '다음 주';

  @override
  String get frpObsWitheredGuard => '흐린 밤 · 구름 보호로 스트릭 유지';

  @override
  String frpPctBang(int pct) {
    return '$pct% 달성!';
  }

  @override
  String frpMissedWeight(int count) {
    return '별빛 +$count';
  }

  @override
  String get frpLegendMemo => '메모 별빛';

  @override
  String get frpBarsName => '요일별 별빛';

  @override
  String frpStampName(int count) {
    return '$count일째 연속 관측';
  }

  @override
  String get constDetailTodayDesc => '오늘의 목표 별자리';

  @override
  String get constDetailTodayProgress => '오늘 모은 별빛';

  @override
  String constDetailTodayPct(int pct) {
    return '$pct%';
  }

  @override
  String constDetailTodayRemain(int lit, int goal, int count) {
    return '$lit/$goal 별빛 · $count별 남음';
  }

  @override
  String constDetailTodayAll(int lit, int goal) {
    return '$lit/$goal 별빛';
  }

  @override
  String get nightSkyTitle => '밤하늘';

  @override
  String get forestReportTitle => '관측 리포트';

  @override
  String get fcolViewCta => '감상하기';

  @override
  String get fcolPreviewCta => '미리보기';

  @override
  String fcolLockedHint(int count) {
    return '별빛 $count개를 하룻밤에 모으면 만날 수 있어요.';
  }

  @override
  String get frpObsResult => '관측 결과';

  @override
  String frpObsToday(String name, int lit, int goal) {
    return '$name $lit/$goal 진행 중';
  }

  @override
  String frpObsCollected(String name) {
    return '$name 수집!';
  }

  @override
  String get frpObsWithered => '흐린 밤';

  @override
  String get frpObsRest => '쉬어간 밤';

  @override
  String frpStampDays(int count) {
    return '$count일째';
  }

  @override
  String get frpStampLabel => '연속 관측!';

  @override
  String get frpStarGather => '별빛 모으기';

  @override
  String frpPctBadge(int pct) {
    return '$pct% 달성';
  }

  @override
  String get frpTileStar => '모은 별빛';

  @override
  String frpTileStarVal(int count) {
    return '$count개';
  }

  @override
  String get frpTileDone => '완료한 할 일';

  @override
  String frpTileDoneVal(int count) {
    return '$count건';
  }

  @override
  String get frpAnalysis => '별빛 분석';

  @override
  String frpLegendItem(String label, int count) {
    return '$label 완료 $count';
  }

  @override
  String get frpMissed => '못다 켠 별';

  @override
  String get frpMissedAllDone => '오늘 하늘의 별을 모두 켰어요. 남은 별빛은 내일 밤으로!';

  @override
  String frpMissedCount(int count) {
    return '$count개';
  }

  @override
  String frpAsOf(String ts) {
    return '$ts 기준';
  }

  @override
  String get settingsMenuTodoTag => '할 일 태그';

  @override
  String get settingsMenuMemoTag => '메모 태그';

  @override
  String ttagUsage(int count) {
    return '$count건에 사용 중';
  }

  @override
  String calLabelUsage(Object count) {
    return '$count건에 사용 중';
  }

  @override
  String get ttagEditTitle => '태그 수정';

  @override
  String get ttagTitle => '할 일 태그';

  @override
  String get ttagDesc =>
      '할 일에 붙이는 태그예요. 할 일 화면의 거르기와 태그별 개수에 쓰여요. 태그를 지우면 그 할 일은 \'태그 없음\'으로 남아요.';

  @override
  String get ttagAddCta => '태그 추가';

  @override
  String get ttagColorLabel => '색상';

  @override
  String get ttagNameLabel => '이름';

  @override
  String get ttagEmpty => '태그가 없어요';

  @override
  String ttagDeleteDesc(int count) {
    return '이 태그를 쓰는 할 일 $count건은 태그 없음으로 남아요.';
  }

  @override
  String get iconPickerTitle => '아이콘 선택';

  @override
  String get iconPickerSearchHint => '아이콘 검색...';

  @override
  String get iconPickerNone => '없음';

  @override
  String iconPickerResultCount(int count) {
    return '$count개 결과';
  }

  @override
  String iconPickerTotalHint(int count) {
    return '전체 $count개 · 스크롤해서 더 보기';
  }

  @override
  String get smsPasteTitle => '결제 문자로 기록';

  @override
  String get smsPasteDesc =>
      '카드사에서 온 결제 문자를 붙여넣으면 금액 · 가맹점 · 일시를 읽어 지출 폼을 채워드려요. 저장 전에 확인할 수 있어요.';

  @override
  String get smsPasteFieldLabel => '결제 문자';

  @override
  String get smsPastePlaceholder => '[Web발신]\n숲빛카드 5,500원\n골목찻집';

  @override
  String get smsPasteAction => '문자 읽기';

  @override
  String get smsPasteFromClipboard => '클립보드에서 붙여넣기';

  @override
  String get smsClipboardEmpty => '클립보드에 텍스트가 없어요.';

  @override
  String get smsParseFailed => '문자를 읽지 못했어요. 잠시 뒤 다시 시도해주세요.';

  @override
  String get smsNotRecognized => '결제 문자로 보이지 않아요. 문자 전체를 붙여넣었는지 확인해주세요.';

  @override
  String get smsCancelNotice =>
      '취소 문자예요. 자동 기록은 지원하지 않아요 — 원래 지출을 찾아 환불로 기록해주세요.';

  @override
  String get smsLowConfidence => '일부 항목을 읽지 못했어요. 확인하고 채워주세요.';

  @override
  String get smsRememberCard => '이 카드를 기억해서 다음부터 자동으로 연결하기';

  @override
  String get moreItemSmsPaste => '결제 문자로 기록';

  @override
  String get moreDescSmsPaste => '카드 결제 문자를 붙여넣어 지출 추가';

  @override
  String get smsClipboardBannerTitle => '복사한 결제 문자가 있어요';

  @override
  String get smsClipboardBannerDesc => '붙여넣어 지출로 기록할 수 있어요.';

  @override
  String get smsInboxTitle => '결제 알림 수신함';

  @override
  String get smsInboxClear => '비우기';

  @override
  String get smsInboxEmpty => '아직 받은 결제 알림이 없어요';

  @override
  String get smsInboxEmptyDesc => '카드 결제가 감지되면 여기에 쌓여요. 눌러서 지출로 기록할 수 있어요.';

  @override
  String get smsInboxRemoveTitle => '문자를 삭제할까요?';

  @override
  String smsInboxRemoveConfirm(String target) {
    return '$target 문자를 목록에서 삭제해요. 기록으로 남기지 않아요.';
  }

  @override
  String smsInboxRemoveLabel(String name) {
    return '$name 삭제';
  }

  @override
  String get smsInboxClearTitle => '문자를 모두 삭제할까요?';

  @override
  String smsInboxClearConfirm(int count) {
    return '수신함의 문자 $count건을 모두 삭제해요. 기록으로 남기지 않아요.';
  }

  @override
  String get smsPermissionOffTitle => '결제를 감지해도 알려드릴 수 없어요';

  @override
  String get smsPermissionOffDesc =>
      '알림 권한을 켜면 결제가 잡힐 때 바로 알려드려요. 꺼둬도 감지는 계속되고 수신함에 쌓여요.';

  @override
  String get moreItemSmsInbox => '결제 알림 수신함';

  @override
  String get moreDescSmsInbox => '감지된 카드 결제를 지출로 기록';

  @override
  String get smsNotiAccessOffTitle => '결제 감지가 꺼져 있어요';

  @override
  String get smsNotiAccessOffDesc =>
      '알림 접근을 켜면 카드사 · 은행 앱 알림과 결제 문자를 읽어 기록할 수 있어요. 읽는 건 결제 알림뿐이고 나머지는 곧바로 버려요.';

  @override
  String get updateAutoBlockerTitle => '삼성 자동 차단을 꺼야 설치돼요';

  @override
  String get updateAutoBlockerDesc =>
      '갤럭시는 스토어 밖에서 받은 앱의 설치를 기본으로 막아요. 이 앱이 위험해서가 아니라 설치 경로를 통째로 막는 기능이라, 꺼두지 않으면 받아도 설치가 되지 않아요.';

  @override
  String get updateAutoBlockerPath =>
      '설정 > 보안 및 개인정보 보호 > 자동 차단에서 꺼주세요. 설치가 끝나면 다시 켜도 괜찮아요.';

  @override
  String get updateAutoBlockerAfterDirect =>
      '자동 차단을 끄고 돌아와서 받기를 눌러주세요. 설치가 끝나면 다시 켜도 괜찮아요.';

  @override
  String get updateAutoBlockerAfterSecurity =>
      '목록에서 자동 차단을 찾아 꺼주세요. 설치가 끝나면 다시 켜도 괜찮아요.';

  @override
  String get updateAutoBlockerOpen => '설정 열기';

  @override
  String get settingsSecuritiesLink => '증권사 연동';

  @override
  String get settingsSecuritiesLinkDesc =>
      '본인 API 키를 등록하면 보유 주식 · 시세를 자동으로 가져와요. 키는 서버에 암호화되어 저장되고 본인만 사용해요.';

  @override
  String get securitiesLoadError => '증권사 목록을 불러오지 못했어요';

  @override
  String get subBrokerSectionTitle => '증권 데이터 연동';

  @override
  String get subBrokerPrimary => '기본';

  @override
  String get subBrokerUseAsPrimary => '기본으로 쓰기';

  @override
  String get subBrokerPrimaryNotice => '가계부 자산은 여기서 고른 증권사 시세로 계산해요.';

  @override
  String get subBrokerPrimaryFailed => '기본 증권사를 바꾸지 못했어요.';

  @override
  String subBrokerConnected(String broker) {
    return '$broker 연결을 마쳤어요.';
  }

  @override
  String get subBrokerDisconnected => '연결을 해제했어요.';

  @override
  String subBrokerPrimaryChanged(String broker) {
    return '이제 $broker 시세로 자산을 평가해요.';
  }

  @override
  String subBrokerKeyNotice(String broker) {
    return '키는 서버에 암호화되어 저장되고 본인만 사용해요. 발급은 $broker 개발자센터에서 받을 수 있어요.';
  }

  @override
  String subBrokerToggleReveal(String field) {
    return '$field 보기';
  }

  @override
  String get brokerToss => '토스증권';

  @override
  String get brokerNamu => '나무증권';

  @override
  String get stocksBrokerUnsupported => '앱이 아직 모르는 증권사예요. 앱을 업데이트하면 볼 수 있어요.';

  @override
  String get namuPriceEmpty => '현재가가 없는 종목이에요';

  @override
  String get namuTabDomestic => '국내';

  @override
  String get namuTabOverseas => '해외';

  @override
  String get namuHoldingsEmpty => '보유 중인 종목이 없어요';

  @override
  String get expFilterMatch => '조건 맞추기';

  @override
  String get expFilterMatchAll => '모두 일치';

  @override
  String get expFilterMatchAny => '하나라도 일치';

  @override
  String get expFilterMatchHint => '조건이 두 개 이상일 때 고를 수 있어요.';

  @override
  String get expFilterAddPeriod => '기간 추가';

  @override
  String get expFilterAddAmountRange => '구간 추가';

  @override
  String get expFilterPeriodAlwaysAnd => '기간은 항상 함께 적용돼요.';

  @override
  String get expFilterRemoveRow => '이 줄 지우기';

  @override
  String expFilterExcluded(int count) {
    return '$count개 빼고';
  }

  @override
  String get expRecordOnlyBadge => '기록만';

  @override
  String get expRecordOnlyNote => '결제가 끝난 회차에 적은 거래라 기록만 남았어요. 계좌에서는 빠지지 않았어요.';

  @override
  String expRecordOnlyPartNote(String amount) {
    return '이 중 $amount은 결제가 끝난 회차분이라 기록만 남았어요. 남은 회차는 정상 청구돼요.';
  }

  @override
  String get expClosedCycleLine => '이미 결제가 끝난 회차예요. 기록만 바뀌고 계좌 잔액은 그대로예요.';

  @override
  String get expClosedCycleToast => '결제가 끝난 회차라 기록만 바뀌고 계좌 잔액은 그대로예요.';

  @override
  String get expClosedCyclePartLine => '지난 회차분은 기록만 남아요.';

  @override
  String get expFixBalance => '잔액 고치기';

  @override
  String get expMoneyLockedNote => '결제가 끝난 거래예요. 금액 · 날짜를 바꾸려면 고쳐 쓰기를 눌러주세요';

  @override
  String get expMoneyLockedPaidOffNote =>
      '결제가 끝난 거래예요. 중도 정리한 할부라 금액 · 날짜를 바꿀 수 없어요.';

  @override
  String get expRewrite => '고쳐 쓰기';

  @override
  String get expRewriteConfirmLead => '원래 거래는 지워지고 새 거래로 바뀌어요.';

  @override
  String get expRewriteConfirmClosed => '기록만 바뀌고 계좌 잔액은 그대로예요.';

  @override
  String expRewriteConfirmOpen(String date) {
    return '새 거래는 $date 결제에 청구돼요. 원래 거래는 이미 결제된 회차에서 기록만 빠져요.';
  }

  @override
  String get expSaveConfirmTitle => '저장할까요?';

  @override
  String get assetPreRegistrationNote => '카드 등록 이전 거래라 실제와 맞지 않을 수 있어요';

  @override
  String get assetRecordCycle => '기록 회차';

  @override
  String assetClosedPaidLine(String paid, String diff) {
    return '계좌에서 나간 돈은 $paid이에요. 나머지 $diff은 기록만 남긴 금액이에요';
  }

  @override
  String assetClosedOverpaidLine(String recorded, String paid) {
    return '기록은 $recorded인데 계좌에서는 $paid이 나갔어요';
  }

  @override
  String get assetPaymentDayMissing => '결제일을 넣어주세요';

  @override
  String get dsProgressCircleLabel => '불러오는 중';

  @override
  String get dsLoadingWaiting => '불러오는 중…';

  @override
  String get dsLoadingSlow => '평소보다 오래 걸리고 있어요.';

  @override
  String dsProgressOver(String amount) {
    return '$amount 초과';
  }

  @override
  String get dsProgressReached => '달성';

  @override
  String dsProgressSemantics(String label, String max, String current) {
    return '$label $max 중 $current';
  }

  @override
  String get dsFieldOptional => '선택';

  @override
  String dsFieldCountSemantics(int count, int max) {
    return '$max자 중 $count자';
  }

  @override
  String get dsInputClear => '지우기';

  @override
  String get fixedSwitchExpense => '고정 지출';

  @override
  String get fixedSwitchIncome => '고정 수입';

  @override
  String get fixedHintExpense => '월세 · 통신비처럼 매달 나가는 돈이에요. 통계에서 따로 나눠 볼 수 있어요.';

  @override
  String get fixedHintIncome => '월급처럼 매달 들어오는 돈이에요. 통계에서 따로 나눠 볼 수 있어요.';

  @override
  String get fixedBadge => '고정';

  @override
  String get recurringFixedSub => '이 반복이 앞으로 만드는 거래가 고정으로 기록돼요';

  @override
  String get presetFixedTitleExpense => '고정 지출로 기록';

  @override
  String get presetFixedTitleIncome => '고정 수입으로 기록';

  @override
  String get presetFixedDesc => '이 프리셋으로 만든 거래가 통계의 고정 항목으로 잡혀요.';

  @override
  String get hideCardStatsFixed => '고정 · 변동 탭';

  @override
  String get statsTabFixed => '고정 · 변동';

  @override
  String get statsFixedViewAria => '보기 방식';

  @override
  String get statsFixedViewAll => '전체';

  @override
  String get statsFixedViewVariable => '고정 제외';

  @override
  String get statsFixedViewFixed => '고정만';

  @override
  String get statsDonutCenterVariable => '고정 제외 지출';

  @override
  String get statsDonutCenterFixed => '고정 지출';

  @override
  String get statsFixedExpenseTitle => '지출 — 고정과 변동';

  @override
  String get statsFixedIncomeTitle => '수입 — 고정과 변동';

  @override
  String get statsFixedExpenseNone => '이 기간에는 지출이 없어요.';

  @override
  String get statsFixedIncomeNone => '이 기간에는 수입이 없어요.';

  @override
  String get statsFixedTotalExpense => '전체 지출';

  @override
  String get statsFixedTotalIncome => '전체 수입';

  @override
  String get statsFixedFixedExpense => '고정 지출';

  @override
  String get statsFixedFixedIncome => '고정 수입';

  @override
  String get statsFixedVariableExpense => '고정 제외 지출';

  @override
  String get statsFixedVariableIncome => '고정 제외 수입';

  @override
  String statsFixedBarSemantics(String kind, String fixed, String variable) {
    return '$kind 중 고정 $fixed, 변동 $variable';
  }

  @override
  String statsFixedInsightExpense(String pct, String josa) {
    return '지출의 $pct$josa 고정이에요. 고정을 뺀 지출은';
  }

  @override
  String statsFixedInsightIncome(String pct, String josa) {
    return '수입의 $pct$josa 고정이에요. 고정을 뺀 수입은';
  }

  @override
  String get statsFixedInsightTail => '이에요.';

  @override
  String get statsFixedEmptyDesc =>
      '월세 · 통신비 · 월급처럼 매달 정해진 거래를 고정으로 표시하면 여기서 따로 볼 수 있어요.';

  @override
  String get statsFixedManage => '거래를 고정으로 정리하기';

  @override
  String get statsFixedManageHint => '매달 같은 이름으로 나가는 돈은 한 번에 정리할 수 있어요';

  @override
  String get statsFixedTrendTitle => '월별 고정 · 변동 추이';

  @override
  String get statsFixedTrendKindAria => '지출 또는 수입';

  @override
  String get statsFixedTrendRecent => '최근 6개월';

  @override
  String get statsFixedKindExpense => '지출';

  @override
  String get statsFixedKindIncome => '수입';

  @override
  String get statsFixedLegendFixed => '고정';

  @override
  String get statsFixedLegendVariable => '변동';

  @override
  String get statsFixedCategoryTitle => '카테고리별 고정 · 변동';

  @override
  String statsFixedCategoryFixedPart(String pct) {
    return '그중 고정 $pct';
  }

  @override
  String get statsFixedBulkTitle => '거래를 고정으로 정리하기';

  @override
  String statsFixedBulkDesc(String range) {
    return '$range 기간의 거래예요. 매달 같은 이름으로 나가는 돈은 한 줄로 묶여 있어요. 돈이나 잔액은 달라지지 않고 통계의 분류만 바뀌어요.';
  }

  @override
  String get statsFixedBulkUntitled => '이름 없는 거래';

  @override
  String get statsFixedBulkTargetAria => '바꿀 방향';

  @override
  String get statsFixedBulkToFixed => '고정으로 표시';

  @override
  String get statsFixedBulkToVariable => '변동으로 되돌리기';

  @override
  String statsFixedBulkGroupSub(int count) {
    return '$count건';
  }

  @override
  String get statsFixedBulkBadgeAll => '고정';

  @override
  String statsFixedBulkBadgeSome(int fixed, int count) {
    return '고정 $fixed/$count';
  }

  @override
  String get statsFixedBulkEmpty => '이 기간에는 정리할 거래가 없어요.';

  @override
  String statsFixedBulkApply(int count) {
    return '$count건 적용';
  }

  @override
  String statsFixedBulkDoneFixed(int count) {
    return '$count건을 고정으로 바꿨어요.';
  }

  @override
  String statsFixedBulkDoneVariable(int count) {
    return '$count건을 변동으로 되돌렸어요.';
  }

  @override
  String get statsFixedBulkFailed => '고정 표시를 바꾸지 못했어요.';

  @override
  String get navMainMenu => '주 메뉴';

  @override
  String get navNotificationsNew => '알림, 새 알림 있음';

  @override
  String get dsNotificationBadge => '새 소식';

  @override
  String get dsQuantityDecrease => '줄이기';

  @override
  String get dsQuantityIncrease => '늘리기';

  @override
  String get dsSliderMin => '최소';

  @override
  String get dsSliderMax => '최대';

  @override
  String dsAttachLifted(int n) {
    return '$n번째 항목을 들었어요.';
  }

  @override
  String dsAttachAddedPhotos(int n) {
    return '사진 $n장을 붙였어요.';
  }

  @override
  String dsAttachAddedFiles(int n) {
    return '파일 $n개를 붙였어요.';
  }

  @override
  String dsAttachAddedItems(int n) {
    return '$n개를 붙였어요.';
  }

  @override
  String dsAttachUploaded(int n) {
    return '$n개를 올렸어요.';
  }

  @override
  String dsAttachFailedCount(int n) {
    return '$n개는 올리지 못했어요.';
  }

  @override
  String get dsAttachTitle => '첨부';

  @override
  String get dsAttachCamera => '사진 찍기';

  @override
  String get dsAttachGallery => '앨범에서 고르기';

  @override
  String get dsAttachFiles => '파일 고르기';

  @override
  String dsAttachMoved(int n) {
    return '$n번째 자리로 옮겼어요.';
  }

  @override
  String get dsAttachPreviewImage => '크게 보기';

  @override
  String get dsAttachOpen => '열기';

  @override
  String get dsAttachMakeCover => '대표로 정하기';

  @override
  String get dsAttachMoveForward => '앞으로 옮기기';

  @override
  String get dsAttachMoveBack => '뒤로 옮기기';

  @override
  String get dsAttachUploading => '올리는 중';

  @override
  String dsAttachUploadingPercent(int percent) {
    return '올리는 중 $percent%';
  }

  @override
  String get dsAttachUploadFailed => '올리지 못했어요';

  @override
  String get dsAttachDefaultLabel => '파일';

  @override
  String get dsAttachSuffix => '첨부';

  @override
  String dsAttachSuffixCount(String count) {
    return '첨부, $count';
  }

  @override
  String get dsAttachPickFiles => '파일 선택';

  @override
  String dsAttachRetryNamed(String name) {
    return '$name 다시 시도';
  }

  @override
  String get dsAttachRetry => '다시 시도';

  @override
  String dsAttachRemoveNamed(String name) {
    return '$name 지우기';
  }

  @override
  String get dsAvatarUploading => '프로필 사진 올리는 중';

  @override
  String get dsDeltaNoChangeSentence => '변화가 없어요';

  @override
  String get dsDeltaIncreased => '늘었어요';

  @override
  String get dsDeltaDecreased => '줄었어요';

  @override
  String get dsDeltaNone => '변화 없음';

  @override
  String get dsChartHeatValue => '지출';

  @override
  String get dsChartHeatNone => '없음';

  @override
  String get dsChartLegend => '범례';

  @override
  String dsSwipeMore(String row) {
    return '$row 더보기';
  }

  @override
  String get dsColorRed => '빨강';

  @override
  String get dsColorOrange => '주황';

  @override
  String get dsColorYellow => '노랑';

  @override
  String get dsColorGreen => '초록';

  @override
  String get dsColorBlue => '파랑';

  @override
  String get dsColorIndigo => '남색';

  @override
  String get dsColorViolet => '보라';

  @override
  String get dsColorPink => '분홍';

  @override
  String get dsColorBrown => '갈색';

  @override
  String get dsColorGray => '회색';

  @override
  String get dsColorCurrent => '지금 색';

  @override
  String get dsColorAuto => '자동';

  @override
  String get dsIconTitle => '아이콘';

  @override
  String get dsIconSearch => '아이콘 검색';

  @override
  String get dsIconSearchPlaceholder => '아이콘 이름 검색';

  @override
  String get dsIconCurrent => '지금 아이콘';

  @override
  String get dsIconEmptyDescription => '다른 말로 찾거나 묶음에서 골라주세요.';

  @override
  String dsIconEmptyTitle(String query) {
    return '\'$query\'에 대한 아이콘이 없어요';
  }

  @override
  String dsIconCount(int count) {
    return '검색 결과 $count개';
  }

  @override
  String get dsIconTagFallback => '태그';

  @override
  String get dsTimeTitle => '시간 선택';

  @override
  String get dsTimePeriod => '오전/오후';

  @override
  String get dsTimeHour => '시';

  @override
  String get dsTimeMinute => '분';

  @override
  String get dsTimeAm => '오전';

  @override
  String get dsTimePm => '오후';

  @override
  String get dsDateRoot => '날짜 선택';

  @override
  String get dsDatePrevMonth => '이전 달';

  @override
  String get dsDateNextMonth => '다음 달';

  @override
  String get dsDateYear => '연도';

  @override
  String get dsDateMonth => '월';

  @override
  String get dsDateReadOnlyStart => '읽기 전용 시작일';

  @override
  String get dsDatePresets => '빠른 기간';

  @override
  String get dsDateToday => '오늘';

  @override
  String dsTabPosition(int index, int count) {
    return '탭 $index/$count';
  }

  @override
  String get dsDatePresetThisWeek => '이번 주';

  @override
  String get dsDatePresetThisMonth => '이번 달';

  @override
  String get dsDatePresetLastMonth => '지난 달';

  @override
  String get dsDatePresetLast7 => '최근 7일';

  @override
  String get dsDatePresetLast30 => '최근 30일';

  @override
  String get dsDatePresetLast3M => '최근 3개월';

  @override
  String get dsDatePresetLast6M => '최근 6개월';

  @override
  String get dsDatePresetLast1Y => '최근 1년';

  @override
  String get dsDatePresetThisYear => '올해';

  @override
  String get apiErrorServer => '요청을 처리하지 못했어요. 잠시 뒤 다시 시도해주세요.';

  @override
  String get dsInfiniteListError => '더 불러오지 못했어요.';

  @override
  String get dsInfiniteListEnd => '모두 봤어요.';

  @override
  String get dsPullToRefreshLabel => '새로 고치는 중';

  @override
  String get dsPullToRefreshFailed => '새로 고치지 못했어요.';

  @override
  String get dsCommonRetry => '다시 시도';

  @override
  String get cardListLoadFailed => '카드를 불러오지 못했어요';

  @override
  String get cardListEnd => '카드를 모두 봤어요.';

  @override
  String get apiErrorNetwork => '네트워크 연결이 불안정해요. 잠시 뒤 다시 시도해주세요.';

  @override
  String get txmCalendarToggle => '월 달력';

  @override
  String get expFilteredEmpty => '조건에 맞는 거래가 없어요';

  @override
  String get expFilteredEmptyDesc => '조건을 바꾸거나 지워보세요.';

  @override
  String get expFilterMatchAllDesc => '걸린 조건을 모두 만족하는 거래만';

  @override
  String get expFilterMatchAnyDesc => '걸린 조건 중 하나라도 만족하면';

  @override
  String get expFilterModeInclude => '고른 것만';

  @override
  String get expFilterModeExclude => '고른 것 빼고';

  @override
  String get expFilterPeriodPick => '기간 선택';

  @override
  String expFilterClearOne(String name) {
    return '$name 지우기';
  }

  @override
  String expFilterModeGroup(String name) {
    return '$name 고르는 방식';
  }

  @override
  String get expLoadErrorDesc => '잠시 뒤 다시 시도해주세요.';

  @override
  String get statsNoMonthlyData => '월별 데이터가 없어요.';

  @override
  String get statsLoadFailedCategory => '카테고리별 지출을 불러오지 못했어요';

  @override
  String get statsLoadFailedMerchant => '가맹점 순위를 불러오지 못했어요';

  @override
  String get statsLoadFailedHeatmap => '요일 · 시간대 지출을 불러오지 못했어요';

  @override
  String get statsLoadFailedHighlights => '요약을 불러오지 못했어요';

  @override
  String get statsLoadFailedTrend => '추이를 불러오지 못했어요';

  @override
  String get statsLoadFailedCompare => '비교할 내용을 불러오지 못했어요';

  @override
  String get statsLoadFailedWeekday => '요일별 지출을 불러오지 못했어요';

  @override
  String get statsLoadFailedFixed => '고정 · 변동 내용을 불러오지 못했어요';

  @override
  String get statsFixedBulkLoadFailed => '거래를 불러오지 못했어요';

  @override
  String get statsCompareSame => '지난 기간과 같아요.';

  @override
  String statsChartDonutName(String period, String total) {
    return '$period 카테고리별 지출, 합계 $total';
  }

  @override
  String statsChartHeatName(String period, String total) {
    return '$period 요일 · 시간대별 지출, 합계 $total';
  }

  @override
  String get statsChartHeatValue => '지출';

  @override
  String statsChartTrendName(String period, String income, String expense) {
    return '$period 수입 · 지출 추이, 수입 $income · 지출 $expense';
  }

  @override
  String statsChartSavingsName(String period, String unit) {
    return '$period $unit';
  }

  @override
  String statsChartCatTrendName(String period) {
    return '$period 주요 카테고리 월별 지출 추이';
  }

  @override
  String statsChartWeekdayName(String period) {
    return '$period 요일별 지출 비교';
  }

  @override
  String statsChartFixedName(String kind) {
    return '$kind 월별 고정 · 변동 추이';
  }

  @override
  String get statsTableDate => '날짜';

  @override
  String get statsTableMonth => '월';

  @override
  String get statsTableTime => '시간대';

  @override
  String get statsTableWeekday => '요일';

  @override
  String statsPeriodButtonAria(String period) {
    return '기간 $period 바꾸기';
  }

  @override
  String get statsTabsAria => '통계 보기';

  @override
  String get tdmFilterOn => '필터, 조건 걸림';

  @override
  String todoCheckName(String title) {
    return '$title 완료';
  }

  @override
  String todoCheckNameOverdue(String title) {
    return '$title 완료, 마감 지남';
  }

  @override
  String get todoMemoTag => '메모';

  @override
  String tdmCellLeft(String date, int count) {
    return '$date, 남은 할 일 $count개';
  }

  @override
  String tdmCellCollected(String date) {
    return '$date, 별자리 수집';
  }

  @override
  String tdmCellMissed(String date) {
    return '$date, 놓친 날';
  }

  @override
  String tdmCellDone(String date) {
    return '$date, 다 끝냄';
  }

  @override
  String get tdmLoadFailedDesc => '잠시 후 다시 시도해주세요.';

  @override
  String get todoToggleFailed => '할 일 상태를 바꾸지 못했어요. 잠시 뒤 다시 시도해주세요.';

  @override
  String get todoDetailOverdue => '마감 지남';

  @override
  String get todoDueDatePlaceholder => '마감일 선택';

  @override
  String get todoTagEmptyHint => '태그는 설정 › 할 일 태그에서 만들어요.';

  @override
  String ttagEmptyHint(String label) {
    return '$label 버튼으로 첫 태그를 만들어보세요.';
  }

  @override
  String get todoDueClear => '마감일 지우기';

  @override
  String get ttagNameRequired => '이름을 입력해주세요.';

  @override
  String get ttagNameTooLong => '이름은 12자 이내로 입력해주세요.';

  @override
  String get ttagNameDuplicate => '같은 이름의 태그가 이미 있어요.';

  @override
  String get assetPickInstitutionTitle => '기관 고르기';

  @override
  String get assetPickBrokerTitle => '증권사 고르기';

  @override
  String get assetInstitutionPlaceholder => '기관 선택';

  @override
  String get assetCardPlaceholder => '카드 선택';

  @override
  String get assetPickCardTitle => '카드 상품 고르기';

  @override
  String get assetCardEmptyHint => '카드사 이름으로도 찾아보세요.';

  @override
  String assetSearchEmpty(String query) {
    return '\'$query\'에 대한 검색 결과가 없어요';
  }

  @override
  String get assetSearchFailed => '검색 결과를 불러오지 못했어요';

  @override
  String get assetAddStock => '종목 추가';

  @override
  String get assetFormFirstTitle => '무엇을 추가할까요?';

  @override
  String get assetFormPickKindError => '추가할 종류를 골라주세요.';

  @override
  String assetFormTitleAdd(String kind) {
    return '$kind 추가';
  }

  @override
  String assetFormTitleEdit(String kind) {
    return '$kind 수정';
  }

  @override
  String get assetFormKindLabel => '종류';

  @override
  String get assetFormRulesGroup => '표시 설정';

  @override
  String get assetMemo => '메모';

  @override
  String assetOverLimitHelp(String amount) {
    return '한도보다 $amount 많아요. 저장은 되지만 한도나 사용액을 다시 확인해주세요.';
  }

  @override
  String get assetBalanceAutoHelp => '보유 종목 합계로 자동 계산돼요. 연동 종목은 시세 확보 시 반영돼요.';

  @override
  String get assetHoldingQuantity => '수량';

  @override
  String get assetHoldingValueLabel => '평가액';

  @override
  String get assetHoldingItemName => '항목 이름';

  @override
  String assetHoldingRemoveOf(String name) {
    return '$name 지우기';
  }

  @override
  String get unlockVerifyFailed => '확인하지 못했어요. 잠시 뒤 다시 시도해주세요.';

  @override
  String get unlockViewAmounts => '금액 보기';

  @override
  String get assetPaymentDayChangeAsk => '결제일을 바꿀까요?';

  @override
  String get assetFormErrCard => '카드 상품을 골라주세요.';

  @override
  String get assetFormErrPaymentDay => '결제일을 골라주세요.';

  @override
  String get assetNoPaymentAccount => '결제 출금계좌 없음';

  @override
  String get assetNoLinkedAccount => '연결 계좌 없음';

  @override
  String get unlockPasswordRequired => '비밀번호를 입력해주세요.';

  @override
  String get stocksNoWatchlistDesc => '종목을 찾아 ☆ 를 눌러 보세요.';

  @override
  String get stocksSectionMarket => '시장';

  @override
  String get stocksSectionStocks => '종목';

  @override
  String get stocksOrderbookTrades => '호가 · 체결';

  @override
  String get stocksVsPurchase => '매입금액보다';

  @override
  String stocksWatchGroupTitle(String name, int count) {
    return '$name · $count';
  }

  @override
  String get stocksWatchGroupRenameItem => '이름 바꾸기';

  @override
  String stocksWatchGroupMore(String name) {
    return '$name 더보기';
  }

  @override
  String get stocksWatchGroupEmpty => '아직 담은 종목이 없어요';

  @override
  String stocksWatchGroupDeleteConfirmCount(String name, int count) {
    return '\"$name\" 그룹과 담긴 종목 $count개가 함께 삭제돼요. 삭제한 그룹은 되돌릴 수 없어요.';
  }

  @override
  String stocksWatchGroupDeleteConfirmEmpty(String name) {
    return '\"$name\" 그룹을 삭제해요. 삭제한 그룹은 되돌릴 수 없어요.';
  }

  @override
  String get stocksWatchPickGroup => '담을 관심 그룹';

  @override
  String get stocksWatchToggleLabel => '관심 등록';

  @override
  String get stocksPortfolioTitle => '포트폴리오 구성';

  @override
  String get stocksPortfolioSub => '종목별 비중 · 통화별 합계';

  @override
  String stocksPortfolioCount(int count) {
    return '$count종목';
  }

  @override
  String get stocksPortfolioNeedsFx => '환율을 불러오면 구성 비중을 볼 수 있어요';

  @override
  String get stocksFailInvest => '내 투자를 불러오지 못했어요';

  @override
  String get stocksFailMarket => '시장 정보를 불러오지 못했어요';

  @override
  String get stocksFailHoldings => '보유 종목을 불러오지 못했어요';

  @override
  String get stocksFailWatch => '관심 종목을 불러오지 못했어요';

  @override
  String get stocksFailRanking => '순위를 불러오지 못했어요';

  @override
  String get stocksFailDaily => '일별 시세를 불러오지 못했어요';

  @override
  String get stocksFailSearch => '검색 결과를 불러오지 못했어요';

  @override
  String get stocksFailDesc => '잠시 뒤 다시 시도해주세요.';

  @override
  String get stocksSourceNotice => '토스증권 Open API · 시세 지연 표시';

  @override
  String get stocksDisclaimerLine1 => '토스증권 Open API 연동 시 실시간 호가 · 체결가가 반영돼요.';

  @override
  String get stocksDisclaimerLine2 =>
      '시세는 투자 참고용이에요. 실제 주문은 약관에 동의한 뒤 할 수 있어요.';

  @override
  String stocksDailyVolume(String volume) {
    return '거래량 $volume';
  }

  @override
  String get stocksFxBasis => '매매기준율';

  @override
  String stocksDailyDate(int month, int day) {
    return '$month월 $day일';
  }

  @override
  String get stocksTradeSoon => '주문은 곧 열려요.';

  @override
  String get stocksFailOrderbook => '호가를 불러오지 못했어요';

  @override
  String get stocksFailTrades => '체결 내역을 불러오지 못했어요';

  @override
  String get stocksFailInfo => '기본 정보를 불러오지 못했어요';

  @override
  String stocksRowAsk(String price, String qty) {
    return '매도 $price, 잔량 $qty';
  }

  @override
  String stocksRowBid(String price, String qty) {
    return '매수 $price, 잔량 $qty';
  }

  @override
  String stocksRowTrade(String time, String price, String qty) {
    return '$time, $price, 수량 $qty';
  }

  @override
  String get stocksOrderbookTableName => '호가 표';

  @override
  String get stocksTradesTableName => '체결 표';

  @override
  String get stocksConnectEmptyTitle => '증권사를 연결해주세요';

  @override
  String get stocksConnectEmptyDesc =>
      '토스증권 · 나무증권 키를 연결하면 시세와 보유 종목을 볼 수 있어요.';

  @override
  String get stocksConnectEmptyAction => '증권사 연결하기';

  @override
  String get stockMarketKrEtc => '국내 기타';

  @override
  String get stockMarketUsEtc => '미국 기타';

  @override
  String get stocksFailPrice => '시세를 불러오지 못했어요';

  @override
  String get namuKrwTotal => '원화 환산 합계';

  @override
  String namuFxApplied(String rate) {
    return '환율 $rate 적용';
  }

  @override
  String get namuDomesticValue => '국내 평가금액';

  @override
  String get namuOverseasValue => '해외 평가금액';

  @override
  String namuCountSplit(int kr, int us) {
    return '국내 $kr · 해외 $us';
  }

  @override
  String get namuFilterAll => '전체';

  @override
  String get namuFilterAria => '보유 시장';

  @override
  String get namuFilterEmpty => '이 시장에 보유 종목이 없어요';

  @override
  String get namuFailDesc => '계좌가 없거나 조회 권한이 없을 수 있어요.';

  @override
  String get namuDataNotice => '나무증권 Open API · 시세 지연 표시';

  @override
  String get namuDonutNeedsFx => '환율을 못 받아 구성 비중을 낼 수 없어요';

  @override
  String get stocksBuyingPowerKrw => '주문 가능 · 원화';

  @override
  String get stocksBuyingPowerUsd => '주문 가능 · 달러';

  @override
  String get namuDepositUsd => '예수금 · 달러';

  @override
  String get stocksTodayQuote => '오늘 시세';

  @override
  String get stocksOpenPrice => '시가';

  @override
  String get stocksHighPrice => '고가';

  @override
  String get stocksLowPrice => '저가';

  @override
  String get stocksInvestorTitle => '투자자별 매매동향';

  @override
  String get stocksInvestorUnit => '▲ 순매수 · ▼ 순매도 · 주';

  @override
  String get stocksInvestorIndividual => '개인';

  @override
  String get stocksInvestorForeigner => '외국인';

  @override
  String get stocksInvestorInstitution => '기관';

  @override
  String get stocksInvestorEmpty => '집계된 매매동향이 없어요';

  @override
  String get stocksSector => '업종';

  @override
  String get stocksListedShares => '상장주식수';

  @override
  String get stocksWarningInvestmentAttention => '투자유의';

  @override
  String get stocksMarketPre => '프리마켓';

  @override
  String get stocksMarketAfter => '애프터마켓';

  @override
  String get stocksMarketDaytime => '주간거래';

  @override
  String get stocksMarketSinglePrice => '단일가';

  @override
  String get stocksMarketHalted => '일시 마감';

  @override
  String get stocksMarketBeforeOpen => '개장 전';

  @override
  String get stocksFailQuote => '시세를 불러오지 못했어요';

  @override
  String get stocksFailToday => '오늘 시세를 불러오지 못했어요';

  @override
  String get stocksFailInvestor => '투자자별 매매동향을 불러오지 못했어요';

  @override
  String get namuFxUnavailableShort => '환율 없음';

  @override
  String get recDefaultTitle => '반복 거래';

  @override
  String recGroupTitle(String kind, int count) {
    return '$kind $count개';
  }

  @override
  String get recMonthLead => '이번 달';

  @override
  String recRowNext(String date) {
    return '다음 $date';
  }

  @override
  String get recRowPaused => '쉬는 중';

  @override
  String get recRowFinished => '끝남';

  @override
  String get recCycleDaily => '매일';

  @override
  String recCycleWeekly(String day) {
    return '매주 $day요일';
  }

  @override
  String recCycleMonthly(int day) {
    return '매월 $day일';
  }

  @override
  String recCycleYearly(int month, int day) {
    return '매년 $month월 $day일';
  }

  @override
  String recCountOf(int total, int done) {
    return '$total번 중 $done번';
  }

  @override
  String recUntilMonth(int year, int month) {
    return '$year년 $month월까지';
  }

  @override
  String get recDowShort0 => '일';

  @override
  String get recDowShort1 => '월';

  @override
  String get recDowShort2 => '화';

  @override
  String get recDowShort3 => '수';

  @override
  String get recDowShort4 => '목';

  @override
  String get recDowShort5 => '금';

  @override
  String get recDowShort6 => '토';

  @override
  String get recDowLong0 => '일요일';

  @override
  String get recDowLong1 => '월요일';

  @override
  String get recDowLong2 => '화요일';

  @override
  String get recDowLong3 => '수요일';

  @override
  String get recDowLong4 => '목요일';

  @override
  String get recDowLong5 => '금요일';

  @override
  String get recDowLong6 => '토요일';

  @override
  String get recDetailTitle => '반복 거래 상세';

  @override
  String get recEndSentenceNone => '끝나는 날 없이 반복해요';

  @override
  String recEndSentenceDate(String date) {
    return '$date까지 반복해요';
  }

  @override
  String recEndSentenceCount(int total, int done) {
    return '$total번 반복해요($done번 했어요)';
  }

  @override
  String recSentenceLead(String cycle, String end) {
    return '$cycle, $end.';
  }

  @override
  String get recSentenceNextPre => '다음은 ';

  @override
  String get recSentenceNextPost => '예요.';

  @override
  String get recSentencePausedPre => '지금은 쉬고 있어요. 다시 켜면 쉬는 동안 지난 회차는 건너뛰고 ';

  @override
  String get recSentencePausedBold => '다음 회차부터';

  @override
  String get recSentencePausedPost => ' 기록해요.';

  @override
  String get recSentenceFinished => '정한 회차를 모두 기록했어요.';

  @override
  String get recOn => '켬';

  @override
  String get recOff => '끔';

  @override
  String recOnWithCount(int count) {
    return '켬 · $count번 기록';
  }

  @override
  String get recAutoLog => '자동 기록';

  @override
  String get recAutoLogSub => '그날 거래를 저절로 추가해요.';

  @override
  String get recNotifyDayBefore => '하루 전 알림';

  @override
  String get recNotifyDayBeforeSub => '예정일 전날 알려 드려요.';

  @override
  String get recNextDatesTitle => '다음 예정일';

  @override
  String recNextDatesLine(String dates) {
    return '다음 예정일 — $dates';
  }

  @override
  String get recPause => '일시정지';

  @override
  String get recResume => '다시 켜기';

  @override
  String get recPausedBadge => '일시정지';

  @override
  String recMoreOf(String name) {
    return '$name 더보기';
  }

  @override
  String recToastPaused(String name) {
    return '$name 반복을 멈췄어요.';
  }

  @override
  String recToastResumed(String name) {
    return '$name 반복을 다시 켰어요.';
  }

  @override
  String recToastDeleted(String name) {
    return '$name 반복 설정을 삭제했어요.';
  }

  @override
  String get recPauseFailed => '반복을 멈추지 못했어요.';

  @override
  String get recResumeFailed => '반복을 다시 켜지 못했어요.';

  @override
  String get recDeleteFailed => '반복 설정을 삭제하지 못했어요.';

  @override
  String get recLoadFailed => '반복 거래를 불러오지 못했어요';

  @override
  String get recEmptyTitle => '반복 거래가 없어요';

  @override
  String get recEmptyDesc => '구독 · 월세처럼 정해진 날 오가는 돈을 등록해 두면 그날 저절로 기록해요.';

  @override
  String get recAddButton => '반복 거래 추가';

  @override
  String get recTypeLabel => '유형';

  @override
  String get recMerchantPlaceholderExpense => '예: 관리비';

  @override
  String get recMerchantPlaceholderIncome => '예: 월급';

  @override
  String get recMemoPlaceholder => '메모를 적어주세요';

  @override
  String get recRepeatRow => '반복';

  @override
  String get recStartDay => '시작일';

  @override
  String get recEndRow => '끝';

  @override
  String get recEndDay => '끝나는 날';

  @override
  String get recNoneValue => '없음';

  @override
  String get recEndNoneRadio => '끝 없음';

  @override
  String get recEndUntilDate => '날짜까지';

  @override
  String get recEndCountTimes => '횟수만큼';

  @override
  String get recEndCountLabel => '횟수';

  @override
  String get recTimesUnit => '번';

  @override
  String recEndValueDate(String date) {
    return '$date까지';
  }

  @override
  String recEndValueCount(int count) {
    return '$count번';
  }

  @override
  String get recOnWhichDay => '며칠에';

  @override
  String get recOnWhichWeekday => '무슨 요일에';

  @override
  String get recAtWhatTime => '몇 시에';

  @override
  String get recYearlyHint => '시작일과 같은 날에 해마다 기록해요.';

  @override
  String recMonthDayNote(int day) {
    return '$day일이 없는 달은 그달 마지막 날에 기록해요.';
  }

  @override
  String recDayN(int day) {
    return '$day일';
  }

  @override
  String get recFreqDaily => '매일';

  @override
  String get recFreqWeekly => '매주';

  @override
  String get recFreqMonthly => '매월';

  @override
  String get recFreqYearly => '매년';

  @override
  String get recErrAmount => '금액을 입력해주세요.';

  @override
  String get recErrCategory => '카테고리를 골라주세요.';

  @override
  String get recErrFrom => '보내는 계좌를 골라주세요.';

  @override
  String get recErrTo => '받는 계좌를 골라주세요.';

  @override
  String get recErrEndBeforeStart => '끝나는 날이 시작일보다 빨라요.';

  @override
  String recErrCountMax(int max) {
    return '$max번까지 입력할 수 있어요.';
  }

  @override
  String get recErrInterestTooBig => '이자는 금액보다 클 수 없어요.';

  @override
  String recSelectOf(String field) {
    return '$field 선택';
  }

  @override
  String recNoneOf(String field) {
    return '$field 없음';
  }

  @override
  String get recTransferFrom => '보내는 계좌';

  @override
  String get recTransferTo => '받는 계좌';

  @override
  String get recErrCountMin => '1번 이상 입력해주세요.';

  @override
  String get recSaveFailed => '저장하지 못했어요. 잠시 뒤 다시 시도해주세요.';

  @override
  String get recNoAssets => '고를 수 있는 계좌가 없어요.';

  @override
  String get recNoCategoryOfKind => '이 종류의 카테고리가 없어요.';

  @override
  String get recFromAccount => '출금 계좌';

  @override
  String get recDepositAccount => '입금 계좌';

  @override
  String get recIncomeMethod => '수입 방식';

  @override
  String get recClearValue => '값 지우기';

  @override
  String get expDetailMore => '더 하기';

  @override
  String expSplitValue(int count) {
    return '$count개로 나눔';
  }

  @override
  String expSplitHeader(int count) {
    return '내역 분할 $count개';
  }

  @override
  String get expMerchantMonth => '이 가맹점 이번 달';

  @override
  String get expRecentOnly => '최근 5건만 보여요';

  @override
  String get expLinked => '연결됨';

  @override
  String get expSplitLoadFailed => '나눈 내역을 불러오지 못했어요';

  @override
  String get expSplitLoadFailedDesc => '잠시 뒤 다시 시도해주세요.';

  @override
  String get txHistoryLoadFailed => '이전 거래 정보를 불러오지 못했어요';

  @override
  String expRefundDateToday(String date) {
    return '$date · 오늘';
  }

  @override
  String expRefundDateHint(String date) {
    return '거래한 날($date)부터 오늘까지 고를 수 있어요.';
  }

  @override
  String get expRefundFailed => '환불하지 못했어요. 잠시 뒤에 다시 시도해주세요.';

  @override
  String get expRefundCancelFailed => '환불을 취소하지 못했어요.';

  @override
  String get expTxDeleteFailed => '거래를 삭제하지 못했어요.';

  @override
  String get transferDeleteFailed => '이체를 삭제하지 못했어요.';

  @override
  String get transferDetailTitle => '이체 상세';

  @override
  String get transferFromLabel => '보내는 계좌';

  @override
  String get transferToLabel => '받는 계좌';

  @override
  String txfStepMeta(String current, String total) {
    return '$current / $total단계';
  }

  @override
  String get txfTypeGroup => '거래 종류';

  @override
  String get txfEntryRequired => '금액을 입력해주세요.';

  @override
  String txfCurrencyChip(String code) {
    return '통화, $code';
  }

  @override
  String get txfPresetsTitle => '프리셋';

  @override
  String txfPresetApplied(String name) {
    return '$name 적용됨';
  }

  @override
  String get txfNoPresets => '저장된 프리셋이 없어요. 값을 넣고 “현재 입력값 저장” 을 누르면 만들어져요.';

  @override
  String get txfPresetLoadFailed => '프리셋을 불러오지 못했어요.';

  @override
  String txfEmptyPresetHint(String name) {
    return '“$name” 프리셋은 금액이 비어 있어요. 금액을 넣고 [다음]을 눌러주세요.';
  }

  @override
  String txfReceiveAmount(String amount) {
    return '받는 금액 약 $amount';
  }

  @override
  String get txfPresetAllTitle => '프리셋 고르기';

  @override
  String get txfShowAll => '모두 보기';

  @override
  String get txfNone => '없음';

  @override
  String get txfNoAccountOption => '계좌 · 카드 없음';

  @override
  String get txfNoMethodOption => '결제 수단 없음';

  @override
  String get txfErrCategory => '카테고리를 골라주세요.';

  @override
  String get txfErrFrom => '보내는 계좌를 골라주세요.';

  @override
  String get txfErrTo => '받는 계좌를 골라주세요.';

  @override
  String get txfErrFx => '환율을 입력하거나 원화 금액을 넣어주세요.';

  @override
  String get txfErrInterest => '이자는 금액보다 클 수 없어요.';

  @override
  String get txfSplitsLoading => '나눈 내역을 불러오는 중이에요. 잠시 뒤 다시 눌러주세요.';

  @override
  String get txfSaveFailed => '저장하지 못했어요. 잠시 뒤 다시 시도해주세요.';

  @override
  String get txfCategoryLoadFailed => '카테고리를 불러오지 못했어요';

  @override
  String get txfAssetLoadFailed => '계좌 · 카드를 불러오지 못했어요';

  @override
  String get txfNoCategoryOfType => '이 종류의 카테고리가 없어요.';

  @override
  String get txfNoPickableAsset => '이 결제 수단에 맞는 계좌 · 카드가 없어요.';

  @override
  String txfFxHint(String local, String code, String rate, String krw) {
    return '$local $code × $rate = $krw원';
  }

  @override
  String get txfKrwAmount => '원화 금액';

  @override
  String txfInstallmentValue(String months, String amount) {
    return '$months개월 · 매달 약 $amount원';
  }

  @override
  String get txfSplitMismatchTitle => '나눈 내역과 금액이 달라요';

  @override
  String txfSplitMismatchBody(String total, String sum, String diffText) {
    return '새 총액 $total원 · 나눈 합계 $sum원 — $diffText';
  }

  @override
  String txfSplitOver(String diff) {
    return '$diff원 넘쳐요.';
  }

  @override
  String txfSplitShort(String diff) {
    return '$diff원 모자라요.';
  }

  @override
  String get txfMatchSplits => '나눈 내역 맞추기';

  @override
  String get txfSaveSplitAndSave => '나눈 내역 맞추고 저장';

  @override
  String get txfSmsStepTitle => '결제 문자 붙여넣기';

  @override
  String get txfSmsHelp =>
      '카드사에서 온 결제 문자를 그대로 붙여넣어주세요. 읽은 금액 · 가맹점 · 시각이 칸에 채워져요.';

  @override
  String get txfPresetAmountEmpty => '비워 둠';

  @override
  String get txfPresetAmountHint => '비워 두면 불러올 때 금액을 직접 넣어요.';

  @override
  String get txfPresetNameRequired => '프리셋 이름을 입력해주세요.';

  @override
  String get txfPresetNeedParties => '보내는 계좌와 받는 계좌를 먼저 골라주세요.';

  @override
  String get txfPresetNeedCategory => '카테고리를 먼저 골라주세요.';

  @override
  String get txfPresetNoMerchant => '내역 없음';

  @override
  String txfPresetSaved(String name) {
    return '$name 프리셋을 저장했어요.';
  }

  @override
  String get txfPresetNameTooLong => '이름은 12자 이내로 입력해주세요.';

  @override
  String get txfMemoStepTitle => '메모';

  @override
  String get txfTimeTitle => '시각';

  @override
  String get txfNoCategory => '카테고리 없음';

  @override
  String get txfNoDepositAccount => '입금 계좌 없음';

  @override
  String get txfNoIncomeMethod => '수입 방식 없음';

  @override
  String get txfSelectFrom => '보내는 계좌 선택';

  @override
  String get txfSelectTo => '받는 계좌 선택';

  @override
  String get txfDeletedAsset => '지운 계좌';

  @override
  String get txfDeletedCategory => '지운 카테고리';

  @override
  String get expSplitSourceNote => '원 거래';

  @override
  String expSplitOldTotal(String amount) {
    return '옛 총액 $amount';
  }

  @override
  String expSplitItemsHeader(int count) {
    return '나눈 내역 $count개';
  }

  @override
  String expSplitItemTitle(int n) {
    return '항목 $n';
  }

  @override
  String get expSplitAddItem => '항목 추가';

  @override
  String get expSplitDropItem => '이 항목 지우기';

  @override
  String get expSplitItemName => '이름';

  @override
  String get expSplitItemNamePh => '항목 이름';

  @override
  String expSplitItemHelp(String rest, String total) {
    return '나머지 항목 합 $rest · 총액 $total';
  }

  @override
  String get expSplitRemaining => '남은 금액';

  @override
  String expSplitShortBy(String amount) {
    return '$amount 모자라요';
  }

  @override
  String expSplitOverBy(String amount) {
    return '$amount 넘쳐요';
  }

  @override
  String get expSplitReconcileTitle => '총액이 바뀌어 나눈 금액을 맞춰야 해요';

  @override
  String expSplitReconcileShort(String sum, String total, String diff) {
    return '나눈 합계 $sum · 새 총액 $total — $diff 모자라요.';
  }

  @override
  String expSplitReconcileOver(String sum, String total, String diff) {
    return '나눈 합계 $sum · 새 총액 $total — $diff 넘쳐요.';
  }

  @override
  String get expSplitActProportional => '비례 배분';

  @override
  String get expSplitActLargest => '큰 항목 반영';

  @override
  String get expSplitActAdjust => '조정 항목';

  @override
  String get expSplitErrRemain => '남은 금액을 0원으로 맞춰주세요.';

  @override
  String get expSplitErrCount => '항목을 둘 이상 넣어주세요.';

  @override
  String get expSplitRemoveAll => '내역 분할 풀기';

  @override
  String get expSplitRemoveTitle => '내역 분할을 풀까요?';

  @override
  String get expSplitRemoveBody => '나눈 항목이 모두 지워지고 거래 하나로 돌아가요.';

  @override
  String get expSplitRemoveAction => '풀기';

  @override
  String get expSplitRemoveFailed => '내역 분할을 풀지 못했어요.';

  @override
  String get expSplitSaveFailed => '저장하지 못했어요. 잠시 뒤 다시 시도해주세요.';

  @override
  String get dutchMeIncludeTitle => '나도 포함해서 나누기';

  @override
  String get dutchMeIncludeOn => '내 몫도 계산돼요';

  @override
  String dutchParticipantsLabel(int count) {
    return '참여자 $count명';
  }

  @override
  String dutchChipRemove(String name) {
    return '$name 빼기';
  }

  @override
  String get dutchNameEmptyErr => '이름을 입력해주세요.';

  @override
  String get dutchMethodHeader => '나누는 법';

  @override
  String get dutchEqualSub => '똑같이';

  @override
  String get dutchRatioSub => '사람마다 몫 수';

  @override
  String get dutchSharesHeader => '몫';

  @override
  String dutchSharesTotal(String amount) {
    return '합계 $amount';
  }

  @override
  String get dutchPayerShort => '결제';

  @override
  String dutchRemainIncluded(String amount) {
    return '남는 $amount 포함';
  }

  @override
  String get dutchShareUnit => '몫';

  @override
  String get dutchNoteTitle => '메모';

  @override
  String get dutchNotePh => '정산에 같이 남길 한마디';

  @override
  String dutchPerPersonMe(String amount, String rest) {
    return '$amount · $rest은 나';
  }

  @override
  String get dutchErrNoOthers => '함께 나눌 사람을 넣어주세요.';

  @override
  String dutchSharesShortErr(String amount) {
    return '몫을 합하면 $amount 모자라요.';
  }

  @override
  String dutchSharesOverErr(String amount) {
    return '몫을 합하면 $amount 넘쳐요.';
  }

  @override
  String get dutchSaveFailed => '정산을 만들지 못했어요. 잠시 뒤 다시 시도해주세요.';

  @override
  String get expSplitErrRow => '모든 항목에 카테고리와 0원보다 큰 금액을 넣어주세요.';

  @override
  String get dutchErrRatio => '몫은 0보다 큰 수로 넣어주세요.';

  @override
  String get dutchErrCustomEmpty => '모든 참여자의 금액을 넣어주세요.';

  @override
  String get expRecurringOpenFailed => '반복 설정을 열지 못했어요.';

  @override
  String get dateRangeSeparator => '~';

  @override
  String get percentUnderTenth => '0.1% 미만';

  @override
  String expCellLabel(String date, String parts) {
    return '$date, $parts';
  }

  @override
  String expCellOutPart(String amount) {
    return '지출 $amount';
  }

  @override
  String expCellInPart(String amount) {
    return '수입 $amount';
  }

  @override
  String get expCellHidden => '금액 가림';
}
