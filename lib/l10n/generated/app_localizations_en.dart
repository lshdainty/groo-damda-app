// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => '그루 담다';

  @override
  String get actionSave => 'Save';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionCreate => 'Create';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get actionClose => 'Close';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionApply => 'Apply';

  @override
  String get actionReset => 'Reset';

  @override
  String get actionSearch => 'Search';

  @override
  String get actionLoading => 'Loading...';

  @override
  String get actionDone => 'Done';

  @override
  String get actionBack => 'Back';

  @override
  String get actionNext => 'Next';

  @override
  String get pickDate => 'Select date';

  @override
  String get pickTime => 'Select time';

  @override
  String get searchResultsEmpty => 'No results';

  @override
  String get unlockTitle => 'Verify to view amounts';

  @override
  String get unlockBody => 'Enter your password to view amounts again.';

  @override
  String get unlockBiometricReason => 'Verify it\'s you to view amounts again.';

  @override
  String get unlockPasswordLabel => 'Password';

  @override
  String get unlockPasswordHint => 'Enter password';

  @override
  String get unlockMismatch => 'Password doesn\'t match.';

  @override
  String get appLockTitle => 'App Lock';

  @override
  String get appLockRowDesc =>
      'Verify with Face ID or fingerprint when opening the app.';

  @override
  String get appLockLockedDesc => 'Verify it\'s you to unlock.';

  @override
  String get appLockUnlockAction => 'Unlock';

  @override
  String get appLockPromptReason => 'Verify it\'s you to open the app.';

  @override
  String get appLockUnavailable =>
      'Biometrics or screen lock isn\'t available on this device.';

  @override
  String get stateNoData => 'No data';

  @override
  String get stateError => 'Something went wrong';

  @override
  String get stateEmpty => 'Nothing to show';

  @override
  String nameTooLong(int max) {
    return 'Keep the name to $max characters or fewer.';
  }

  @override
  String get languageKorean => '한국어';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSystem => 'System';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navTodo => 'Todo';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get navMemo => 'Memo';

  @override
  String get navTimer => 'Timer';

  @override
  String get navExpense => 'Expense';

  @override
  String get navAsset => 'Assets';

  @override
  String get navDutchPay => 'Dutch Pay';

  @override
  String get navPostit => 'Post-it';

  @override
  String get navGroup => 'Groups';

  @override
  String get navSettings => 'Settings';

  @override
  String get navMore => 'More';

  @override
  String get navMenu => 'Menu';

  @override
  String get navHome => 'Home';

  @override
  String get navStats => 'Stats';

  @override
  String get navSearch => 'Search';

  @override
  String get navNotifications => 'Notifications';

  @override
  String get navBudget => 'Budget';

  @override
  String get navRecurring => 'Manage recurring';

  @override
  String get navCategories => 'Categories';

  @override
  String get navPresets => 'Presets';

  @override
  String get navCards => 'Cards';

  @override
  String get navSavingGoals => 'Saving goals';

  @override
  String get navExport => 'Export';

  @override
  String get navLogout => 'Log out';

  @override
  String get navChangePassword => 'Change password';

  @override
  String get notiTitle => 'Notifications';

  @override
  String get notiEmpty => 'No notifications';

  @override
  String get notiMarkAllRead => 'Read all';

  @override
  String notiMore(String title) {
    return 'More for $title';
  }

  @override
  String get notiDeleteTitle => 'Delete notification';

  @override
  String get notiDeleteDescription =>
      'Deleted notifications can\'t be restored.';

  @override
  String get notiTypeEventReminder => 'Event Reminder';

  @override
  String get notiTypeBudgetAlert => 'Budget Alert';

  @override
  String get notiTypeTodoReminder => 'Todo Reminder';

  @override
  String get notiTypeSystem => 'System';

  @override
  String get notiConnectionLost => 'Notification connection lost';

  @override
  String get notiConnectionRestored => 'Notification connection restored';

  @override
  String get notiNew => 'New notification';

  @override
  String get assetTitle => 'Assets';

  @override
  String get assetSummaryTotalBalance => 'Total Balance';

  @override
  String get assetEmpty => 'No assets registered';

  @override
  String get assetCreateFirst => 'Register your first asset';

  @override
  String get assetAdd => 'Add Asset';

  @override
  String get assetEdit => 'Edit Asset';

  @override
  String get assetTransferAdd => 'Add Transfer';

  @override
  String get assetTransferEmpty => 'No transfers yet';

  @override
  String get assetFee => 'Fee';

  @override
  String get assetTypeBankAccount => 'Bank Account';

  @override
  String get assetTypeSavings => 'Savings';

  @override
  String get assetTypeCash => 'Cash';

  @override
  String get assetTypeCreditCard => 'Credit Card';

  @override
  String get assetTypeCheckCard => 'Check Card';

  @override
  String get assetTypeInvestment => 'Investment';

  @override
  String get assetTypeLoan => 'Loan';

  @override
  String get assetGroupAccount => 'Accounts';

  @override
  String get assetGroupCard => 'Cards';

  @override
  String get assetGroupInvestment => 'Investments';

  @override
  String get assetGroupDebt => 'Loans';

  @override
  String get assetCatAccount => 'Account';

  @override
  String get assetSubtypeInstallment => 'Installment';

  @override
  String get assetSubtypeDeposit => 'Deposit';

  @override
  String get assetSubtypeOverdraft => 'Overdraft account';

  @override
  String get assetLoadError => 'Couldn\'t load assets';

  @override
  String get assetEmptyState => 'No assets yet';

  @override
  String get assetEmptyHint =>
      'You can add one from Settings → Account & Card Management.';

  @override
  String get assetSummaryColAccounts => 'Accounts';

  @override
  String get assetSummaryColCards => 'Card debt';

  @override
  String get assetTotalNetWorth => 'Total net worth';

  @override
  String get assetVsLastMonth => 'vs. last month';

  @override
  String get assetGroupEmpty => 'No items registered.';

  @override
  String assetPaymentDayInfo(int day) {
    return 'Pays on day $day';
  }

  @override
  String get assetExcludedFromTotal => 'Excluded from total';

  @override
  String get assetAmountHiddenBadge => 'Amount hidden';

  @override
  String get assetHideThisAmount => 'Hide amount';

  @override
  String get assetHideThisAmountDesc =>
      'Masks only this asset\'s balance. Totals stay visible.';

  @override
  String get assetManageTitle => 'Manage accounts & cards';

  @override
  String get assetManageAdd => 'Add';

  @override
  String get assetManageEmptyHint =>
      'Tap [Add] to register your first account or card.';

  @override
  String get assetManageLoadFailed => 'Couldn\'t load accounts and cards';

  @override
  String assetHoldingsCount(int count) {
    return '$count holdings';
  }

  @override
  String get assetIncludeInTotal => 'Include in total assets';

  @override
  String get assetIncludeInTotalDesc =>
      'Counts toward net worth and total assets.';

  @override
  String get assetTrendLoadError => 'Couldn\'t load trend data';

  @override
  String get assetTrendEmpty => 'No trend data.';

  @override
  String get assetNetWorth => 'Net worth';

  @override
  String assetCardLimitName(String name) {
    return '$name limit';
  }

  @override
  String assetChartNetWorthName(String amount) {
    return 'Net worth over the last 12 months — this month $amount';
  }

  @override
  String get assetChartTableMonth => 'Month';

  @override
  String get assetLoadFailedSummary => 'Couldn\'t load net worth';

  @override
  String get assetLoadFailedTrend => 'Couldn\'t load the net worth trend';

  @override
  String get assetLoadFailedAssets => 'Couldn\'t load your assets';

  @override
  String get assetLoadFailedGoals => 'Couldn\'t load saving goals';

  @override
  String get assetEmptyCta => 'Go to manage accounts & cards';

  @override
  String get assetAccountAdded => 'Account added';

  @override
  String get assetAccountUpdated => 'Account updated';

  @override
  String get assetAccountDeleted => 'Account deleted';

  @override
  String get assetAccountDelete => 'Delete account';

  @override
  String assetAccountDeleteConfirm(String name) {
    return '\"$name\" will be removed from the list. Linked transactions are kept. A deleted asset cannot be restored.';
  }

  @override
  String get assetActionFailed => 'Failed';

  @override
  String get assetDeleteFailed => 'Delete failed';

  @override
  String get assetInstitutionBrand => 'Institution';

  @override
  String get assetBankSearchHint => 'Search institution name';

  @override
  String get assetNickname => 'Nickname';

  @override
  String get assetNicknamePlaceholder => 'e.g. Living expenses account';

  @override
  String get assetNicknameRequired => 'Enter a nickname.';

  @override
  String get assetNicknameDuplicate =>
      'An asset with this alias already exists.';

  @override
  String get assetBalanceLabel => 'Balance';

  @override
  String get assetBalanceEditHint =>
      'Changing the balance treats everything before now as already included. Only later transactions are added.';

  @override
  String get assetOverdraftUsedLabel => 'Amount used';

  @override
  String get assetLoanRemainingLabel => 'Remaining loan amount';

  @override
  String get assetOverdraftLimitLabel => 'Credit line';

  @override
  String get assetOverdraftHint =>
      'Enter the amount used as a positive number. It counts as debt.';

  @override
  String get assetLoanHint => 'Enter the amount you still owe.';

  @override
  String get assetCurrency => 'Currency';

  @override
  String get assetExchangeRate => 'Exchange rate';

  @override
  String assetExchangeRateHint(String code) {
    return 'KRW per 1 $code';
  }

  @override
  String get assetExchangeRateDesc =>
      'Net worth converts balance × rate. Left empty it is added without conversion.';

  @override
  String get assetMemoPlaceholder => 'e.g. Last digits 1234';

  @override
  String get assetCreditLimitLabel => 'Credit limit';

  @override
  String get assetPaymentDayLabel => 'Payment day';

  @override
  String get assetPaymentDaySelect => 'Select payment day';

  @override
  String get assetPaymentDay => 'Payment day';

  @override
  String get assetLinkedAccountLabel => 'Linked account';

  @override
  String get assetLinkedAccountSelect => 'Select linked account';

  @override
  String get assetLinkedAccountHint =>
      'Spending on this card is deducted from this account right away.';

  @override
  String get assetPaymentAccountLabel => 'Payment account';

  @override
  String get assetNoBankAccounts => 'No checking account';

  @override
  String get assetPaymentAccountSelect => 'Select payment account';

  @override
  String get assetPaymentAccountHint =>
      'The bill is withdrawn from this account on the payment day.';

  @override
  String get assetCardAdded => 'Card added';

  @override
  String get assetCardUpdated => 'Card updated';

  @override
  String get assetCardDelete => 'Delete card';

  @override
  String assetCardDeleteConfirm(String name) {
    return '\"$name\" will be removed from the list. Linked transactions are kept. A deleted asset cannot be restored.';
  }

  @override
  String get assetCardDeleted => 'Card deleted';

  @override
  String get assetCardProduct => 'Card product';

  @override
  String get assetIncludeDiscontinued => 'Show discontinued cards';

  @override
  String get assetCardSearchHint => 'Search card name';

  @override
  String get assetCardNicknamePlaceholder => 'e.g. Everyday card';

  @override
  String get assetCurrentUsage => 'Unpaid balance';

  @override
  String get assetCurrentUsageHint => 'Enter the amount not yet paid.';

  @override
  String assetOutstandingNow(String amount) {
    return 'Unpaid balance now $amount';
  }

  @override
  String get assetCarryoverLocked => 'Already paid, so it can\'t be changed.';

  @override
  String assetDueCarryoverLabel(String date) {
    return 'Due on $date';
  }

  @override
  String get assetDueCarryoverHint =>
      'The amount your card app shows as due. It leaves your payment account that day.';

  @override
  String get assetCarryoverAfterLabel => 'Spent since then';

  @override
  String assetCarryoverAfterHint(String date) {
    return 'Spent after the last statement. Paid on $date.';
  }

  @override
  String get assetCarryoverAfterHintNoDate => 'Spent after the last statement.';

  @override
  String assetPaymentDayChangeConfirm(int month, String date) {
    return 'The new payment day applies from the next cycle. Month $month charges are still paid on $date.';
  }

  @override
  String get assetNewCard => 'New card';

  @override
  String get assetAnnualFee => 'Annual fee';

  @override
  String get assetCardShortCredit => 'Credit';

  @override
  String get assetCardShortCheck => 'Check';

  @override
  String get assetDiscontinued => 'Discontinued';

  @override
  String get assetInvestAdded => 'Investment added';

  @override
  String get assetInvestUpdated => 'Investment updated';

  @override
  String get assetInvestDeleted => 'Investment deleted';

  @override
  String get assetInvestDelete => 'Delete investment';

  @override
  String assetInvestDeleteConfirm(String name) {
    return '\"$name\" will be removed from the list. Linked transactions are kept. A deleted asset cannot be restored.';
  }

  @override
  String get assetBrokerExchange => 'Brokerage / exchange';

  @override
  String get assetInvestSearchHint => 'Search brokerage name';

  @override
  String get assetProductPlaceholder => 'e.g. Pension savings, Gold holdings';

  @override
  String get assetValuation => 'Valuation (KRW)';

  @override
  String get assetNewInvestment => 'New investment';

  @override
  String get assetCryptoExchange => 'Crypto exchange';

  @override
  String get assetCategoryCommercialBank => 'Commercial bank';

  @override
  String get assetCategoryInternetBank => 'Internet bank';

  @override
  String get assetCategoryLocalBank => 'Local bank';

  @override
  String get assetCategorySpecialBank => 'Special bank';

  @override
  String get assetCategorySavingsInstitution => 'Savings institution';

  @override
  String get assetCategoryForeignBank => 'Foreign bank';

  @override
  String get assetCategoryOther => 'Other';

  @override
  String get assetCategoryBrokerage => 'Brokerage';

  @override
  String get assetCategoryCommodityExchange => 'Commodity exchange';

  @override
  String get assetCategoryCryptoExchange => 'Crypto exchange';

  @override
  String get assetCardDetail => 'Card details';

  @override
  String get assetInvestDetail => 'Investment details';

  @override
  String get assetAccountDetail => 'Account details';

  @override
  String get assetHideAmount => 'Hide amount';

  @override
  String get assetPeriod3m => '3 months';

  @override
  String get assetPeriod6m => '6 months';

  @override
  String get assetPeriod1y => '1 year';

  @override
  String assetWeeksCount(int weeks) {
    return '$weeks weeks';
  }

  @override
  String get assetTrendKindUsage => 'usage trend';

  @override
  String get assetTrendKindValuation => 'valuation trend';

  @override
  String get assetTrendKindBalance => 'balance trend';

  @override
  String assetTrendRecent(String weeks, String kind) {
    return 'Last $weeks $kind';
  }

  @override
  String get assetValueLabelCard => 'Due this month';

  @override
  String get assetValueLabelCheckCard => 'Spent this month';

  @override
  String get assetCheckCardMonthLabel => 'Used this month';

  @override
  String assetMonthTxCount(int count) {
    return 'This month ($count)';
  }

  @override
  String get assetValuationShort => 'Valuation';

  @override
  String get assetSeriesUsage => 'Usage';

  @override
  String assetRecentTxCount(int count) {
    return 'Recent transactions ($count)';
  }

  @override
  String get assetViewAll => 'View all';

  @override
  String get assetTossLinkStarted => 'Started Toss price sync';

  @override
  String get assetLinkFailed => 'Link failed';

  @override
  String get assetTossUnlinked => 'Unlinked from Toss';

  @override
  String get assetUnlinkFailed => 'Unlink failed';

  @override
  String get assetQtyUpdated => 'Updated quantity';

  @override
  String get assetUpdateFailed => 'Update failed';

  @override
  String get assetTossLinked => 'Toss linked';

  @override
  String get assetHoldings => 'Holdings';

  @override
  String get tradeTitle => 'Buy / Sell';

  @override
  String get tradeBuy => 'Buy';

  @override
  String get tradeSell => 'Sell';

  @override
  String get tradeBought => 'Buy recorded';

  @override
  String get tradeSold => 'Sell recorded';

  @override
  String get tradeHolding => 'Holding';

  @override
  String get tradeHoldingType => 'Holding type';

  @override
  String get tradeNoHolding => 'No holdings yet';

  @override
  String get tradeAddNewHolding => 'Buy a new holding';

  @override
  String get tradePickExisting => 'Pick from holdings';

  @override
  String get tradeNewHoldingPlaceholder => 'Enter a holding name';

  @override
  String get tradeQuantity => 'Quantity';

  @override
  String get tradeAmount => 'Trade amount (KRW)';

  @override
  String get tradeAmountHelp => 'Excluding fees. Enter fees separately below.';

  @override
  String get tradeFee => 'Fees & tax (KRW)';

  @override
  String get tradeMemo => 'Memo';

  @override
  String get tradeMemoPlaceholder => 'Optional';

  @override
  String get tradeSettlement => 'Settlement account';

  @override
  String get tradeSettlementCash => 'Brokerage cash';

  @override
  String get tradeSettlementCashHelp =>
      'Paid from the brokerage cash balance. It may go negative.';

  @override
  String get tradeSettlementAccountHelp =>
      'A transfer covers any shortfall from this account.';

  @override
  String get tradeSettlementDelta => 'Settlement account change';

  @override
  String get tradeCashAfter => 'Cash after trade';

  @override
  String get tradeRealizedPreview => 'Realized P/L';

  @override
  String tradeFundingNotice(String amount) {
    return '$amount moves from the settlement account to cover the shortfall';
  }

  @override
  String get tradeInsufficientCash =>
      'Cash will go negative. It is recorded as is.';

  @override
  String get tradeInsufficientQty => 'Cannot sell more than you hold.';

  @override
  String get tradeHistory => 'Trade history';

  @override
  String get tradeDeleted => 'Trade cancelled';

  @override
  String get tradeDeleteTitle => 'Cancel trade';

  @override
  String get tradeDeleteConfirm =>
      'Cancel this trade? Cash and quantity return to their pre-trade state.';

  @override
  String get assetDetailTitle => 'Asset details';

  @override
  String get assetNotFoundTitle => 'Asset not found';

  @override
  String get assetDetailDeleteFailed => 'Couldn\'t delete the asset.';

  @override
  String get assetNotFoundDesc => 'It was deleted or doesn\'t exist.';

  @override
  String get assetNotFoundAction => 'Go to assets';

  @override
  String get assetLoadFailTitle => 'Couldn\'t load the asset';

  @override
  String assetMoreOf(String name) {
    return 'More for $name';
  }

  @override
  String get tradeDetailTitle => 'Trade record';

  @override
  String get tradeKind => 'Type';

  @override
  String get tradeHoldingLabel => 'Holding';

  @override
  String get tradeUnitPrice => 'Unit price';

  @override
  String get tradeAmountLabel => 'Trade amount';

  @override
  String get tradeFeeLabel => 'Fees & tax';

  @override
  String get tradeDateTime => 'Trade date';

  @override
  String tradeOpenRow(String date, String name) {
    return '$name trade record on $date';
  }

  @override
  String tradeDeleteConfirmTarget(
    String date,
    String name,
    String qty,
    String kind,
  ) {
    return 'Cancel the $kind of $qty $name on $date? Cash and quantity return to their pre-trade state.';
  }

  @override
  String get tradeCancelFailed => 'Couldn\'t cancel the trade.';

  @override
  String get holdingTypeStock => 'Stock';

  @override
  String get holdingTypeGold => 'Gold';

  @override
  String get holdingTypeCrypto => 'Crypto';

  @override
  String get holdingAvgPrice => 'Avg price';

  @override
  String holdingAvgPriceInline(String avg) {
    return 'avg $avg';
  }

  @override
  String get holdingTotalCost => 'Cost basis';

  @override
  String tradeHeldSummary(String qty, String avg) {
    return 'Holding $qty · avg $avg';
  }

  @override
  String get assetCashBalance => 'Cash';

  @override
  String get assetHoldingBalance => 'Holdings';

  @override
  String assetHoldingsSummary(int count, String amount) {
    return '$count holdings · ₩$amount';
  }

  @override
  String assetHoldingRep(String name, int count) {
    return '$name +$count more';
  }

  @override
  String get assetNoHoldings => 'No holdings';

  @override
  String get assetHoldingLinkedBadge => 'Linked';

  @override
  String assetHoldingLinkedSub(String price) {
    return 'Price $price × qty';
  }

  @override
  String get assetHoldingManualSub => 'Manual value';

  @override
  String assetHoldingLinkedDetail(String qty, String price) {
    return '$qty shares · linked at $price';
  }

  @override
  String get assetHoldingManualDetail => 'Manual entry';

  @override
  String get assetHoldingsEmptyEdit =>
      'Add holdings via search. Linked items are valued automatically at live price × quantity.';

  @override
  String get assetHoldingsEmptyManual =>
      'Add your holdings with the button above. No live price — enter the value yourself.';

  @override
  String get assetHoldingsEmptyDetail => 'No holdings yet. Add them from Edit.';

  @override
  String get assetHoldingSearchHint => 'Search stock name';

  @override
  String assetHoldingAddManual(String name) {
    return 'Add \"$name\" manually — enter value';
  }

  @override
  String get assetSharesUnit => 'sh';

  @override
  String get assetHoldingTypeStock => 'Stocks';

  @override
  String get assetHoldingTypeGold => 'Gold';

  @override
  String get assetHoldingTypeCrypto => 'Crypto';

  @override
  String get assetHoldingAddGold => 'Add gold';

  @override
  String get assetHoldingAddCrypto => 'Add crypto';

  @override
  String get assetHoldingUnitGram => 'g';

  @override
  String get assetHoldingUnitCount => 'units';

  @override
  String get assetHoldingNamePlaceholder => 'Item name';

  @override
  String assetHoldingQtyUnit(String qty, String unit) {
    return '$qty $unit';
  }

  @override
  String assetInvestHoldingsSub(int count) {
    return 'Investment · $count holdings';
  }

  @override
  String assetTodayChange(String amount) {
    return 'Today $amount';
  }

  @override
  String assetSharesCount(String n) {
    return '$n shares';
  }

  @override
  String assetTossValuationFormula(int qty) {
    return 'Valuation updates in real time as Toss price × $qty shares.';
  }

  @override
  String get assetHoldingQty => 'Holdings';

  @override
  String get assetEditQty => 'Edit quantity';

  @override
  String get assetUnlink => 'Unlink';

  @override
  String get assetTossRealtimeTitle => 'Real-time valuation via Toss';

  @override
  String get assetTossRealtimeDesc =>
      'Register a ticker and quantity to reflect valuation live as Toss price × quantity.';

  @override
  String get assetTapToChange => 'Tap to change';

  @override
  String get assetStockSearchHint =>
      'Search ticker or code (e.g. Samsung Elec, 005930)';

  @override
  String get stockSecurityTypeIndex => 'Index';

  @override
  String get stockSecurityTypeWarrant => 'Warrant';

  @override
  String get stockMarketKospi => 'KOSPI';

  @override
  String get stockMarketKosdaq => 'KOSDAQ';

  @override
  String get stockMarketKonex => 'KONEX';

  @override
  String get stockMarketKrxIdx => 'KRX Index';

  @override
  String get stockMarketNas => 'NASDAQ';

  @override
  String get stockMarketNys => 'NYSE';

  @override
  String get stockMarketAms => 'AMEX';

  @override
  String get stockMarketShs => 'Shanghai';

  @override
  String get stockMarketShi => 'SSE Index';

  @override
  String get stockMarketSzs => 'Shenzhen';

  @override
  String get stockMarketSzi => 'SZSE Index';

  @override
  String get stockMarketTse => 'Tokyo';

  @override
  String get stockMarketHks => 'Hong Kong';

  @override
  String get stockMarketHnx => 'Hanoi';

  @override
  String get stockMarketHsx => 'Ho Chi Minh';

  @override
  String assetLinkByCode(String code) {
    return 'Link by code \"$code\"';
  }

  @override
  String get assetLink => 'Link';

  @override
  String get assetChartNoData => 'No data to show';

  @override
  String get assetNoLinkedTx => 'No linked transactions.';

  @override
  String get assetTxFallback => 'Transaction';

  @override
  String assetPayConfirmMessage(String amount) {
    return 'Pay the upcoming amount of $amount KRW now?';
  }

  @override
  String assetPayConfirmDateSuffix(String date) {
    return ' The payment date is $date.';
  }

  @override
  String get assetCancelPayment => 'Cancel payment';

  @override
  String assetCancelPaymentConfirm(String amount, String date) {
    return 'Reverts the $amount KRW paid on $date. The account balance and card billing return to the state before payment.';
  }

  @override
  String get assetPaymentCancelled => 'Payment cancelled';

  @override
  String get assetInstallmentPayoff => 'Pay off remaining';

  @override
  String assetInstallmentPayoffConfirm(String amount) {
    return 'Add the remaining ₩$amount to this billing cycle? No further installments will be charged.';
  }

  @override
  String get assetInstallmentPayoffUndo => 'Undo';

  @override
  String get assetInstallmentPayoffUndoConfirm =>
      'Cancel the payoff and return to the original installment schedule?';

  @override
  String get assetInstallmentPaidOffBadge => 'Paid off';

  @override
  String assetInstallmentBadge(int months) {
    return '$months-mo installment';
  }

  @override
  String assetInstallmentSeq(int seq, int total) {
    return 'Payment $seq of $total';
  }

  @override
  String assetInstallmentPrincipal(String amount) {
    return 'Principal $amount';
  }

  @override
  String get assetInstallmentFallback => 'Installment';

  @override
  String get assetLumpSumLabel => 'One-time';

  @override
  String get assetAlreadyPaidLabel => 'Prepaid';

  @override
  String get assetPayNow => 'Pay now';

  @override
  String get assetPayFailed =>
      'Couldn\'t process the payment. Please try again in a moment.';

  @override
  String get assetInstallmentPayoffFailed =>
      'Couldn\'t pay off the installment.';

  @override
  String get assetInstallmentPayoffUndoFailed =>
      'Couldn\'t undo the installment payoff.';

  @override
  String get assetCancelPaymentFailed => 'Couldn\'t cancel the payment.';

  @override
  String get assetPayAction => 'Pay';

  @override
  String get assetPayAmount => 'Payment amount';

  @override
  String assetPayRemainder(String amount) {
    return '$amount remaining will be paid on the payment date';
  }

  @override
  String assetPayMoveNote(String amount) {
    return 'Only $amount counted as card usage will leave the account. The rest is recorded as billed only.';
  }

  @override
  String get assetPayNoAccountNote =>
      'No payment account is linked, so the usage is settled without a transfer.';

  @override
  String get assetPaymentRecorded => 'Payment recorded';

  @override
  String get assetBillingLoadError => 'Couldn\'t load billing info';

  @override
  String get assetUpcomingPayment => 'Upcoming payment';

  @override
  String get assetScheduledTag => 'Upcoming';

  @override
  String get assetPaidDone => 'Paid';

  @override
  String assetUsagePeriod(String period) {
    return 'Card usage period $period';
  }

  @override
  String get assetLimitSettings => 'Limit · payment';

  @override
  String get assetLimitUsage => 'Limit usage';

  @override
  String assetLimitPctUsed(int pct) {
    return '$pct% used';
  }

  @override
  String assetLimitOf(String used, String limit) {
    return '$used / Limit $limit';
  }

  @override
  String assetLimitRemain(String amount) {
    return 'Remaining $amount';
  }

  @override
  String get assetLimitEdit => 'Edit limit · payment day';

  @override
  String get assetPerfDone => 'Monthly target met';

  @override
  String assetPerfRemain(String amount) {
    return '$amount to target';
  }

  @override
  String get assetUsageHistory => 'Usage history';

  @override
  String get assetSortRecent => 'Recent';

  @override
  String get assetSortAmount => 'Amount';

  @override
  String get assetSortCategory => 'Category';

  @override
  String get assetPeriodPick => 'Select period';

  @override
  String get assetNoUsage => 'No usage history yet.';

  @override
  String assetBillingPeriod(String start, String end) {
    return 'Usage $start–$end';
  }

  @override
  String assetMonthlyPaymentDay(int day) {
    return 'Paid on day $day each month';
  }

  @override
  String get assetBillingHistory => 'Billing history';

  @override
  String get assetStatusPending => 'Pending';

  @override
  String get assetStatusSkipped => 'Skipped';

  @override
  String get todoTitle => 'Todos';

  @override
  String get todoEmpty => 'No todos';

  @override
  String get todoCreateFirst => 'Create your first todo';

  @override
  String get todoQuickAddHint => '+ Quick add';

  @override
  String get todoStatusAll => 'All';

  @override
  String get todoStatusCompleted => 'Completed';

  @override
  String get todoPriorityAll => 'All';

  @override
  String get todoPriorityHigh => 'High';

  @override
  String get todoPriorityMedium => 'Medium';

  @override
  String get todoPriorityLow => 'Low';

  @override
  String get todoTagMgmt => 'Tags';

  @override
  String get memoTitle => 'Memos';

  @override
  String get memoEmpty => 'No memos';

  @override
  String get memoSearchEmpty => 'No matching memos';

  @override
  String get memoSearchHint => 'Search memos';

  @override
  String get memoPin => 'Pin';

  @override
  String get memoUnpin => 'Unpin';

  @override
  String get calTitle => 'Calendar';

  @override
  String get calToday => 'Today';

  @override
  String get calMonthView => 'Month';

  @override
  String get calWeekView => 'Week';

  @override
  String get calDayView => 'Day';

  @override
  String get calYearView => 'Year';

  @override
  String get calAgendaView => 'Agenda';

  @override
  String get calNoEvents => 'No events';

  @override
  String get calEventAdd => 'Add event';

  @override
  String get calEventEdit => 'Edit event';

  @override
  String get calEventDelete => 'Delete event';

  @override
  String get calLabelMgmt => 'Labels';

  @override
  String get calMyCalendars => 'My calendars';

  @override
  String get calAllDay => 'All day';

  @override
  String get calRepeat => 'Repeat';

  @override
  String get calRepeatNone => 'None';

  @override
  String get calRepeatDaily => 'Daily';

  @override
  String get calRepeatWeekly => 'Weekly';

  @override
  String get calRepeatMonthly => 'Monthly';

  @override
  String get calRepeatYearly => 'Yearly';

  @override
  String get calLocation => 'Location';

  @override
  String get calMemo => 'Notes';

  @override
  String get calStartDate => 'Start';

  @override
  String get calEndDate => 'End';

  @override
  String get calFieldTitle => 'Title';

  @override
  String get calFieldDescription => 'Description';

  @override
  String get calFieldCalendar => 'Calendar';

  @override
  String get calFieldLabel => 'Label';

  @override
  String get calFieldColor => 'Color';

  @override
  String get calFieldName => 'Name';

  @override
  String get calFieldReminder => 'Reminders';

  @override
  String get calFieldStartDate => 'Start date';

  @override
  String get calFieldEndDate => 'End date';

  @override
  String get calTitlePlaceholder => 'e.g. Dental checkup';

  @override
  String get calDescriptionPlaceholder => 'e.g. What to bring';

  @override
  String get calLocationPlaceholder => 'e.g. 3rd floor meeting room';

  @override
  String get calSelectCalendar => 'Select calendar';

  @override
  String get calNoLabel => 'No label';

  @override
  String get calLabelNamePlaceholder => 'e.g. Important, Deadline, Meeting';

  @override
  String get calCalendarNamePlaceholder => 'e.g. Family, Work, Workouts';

  @override
  String get calCalendarNameFieldPlaceholder => 'Calendar name';

  @override
  String get calInviteCodePlaceholder => 'e.g. ABC123';

  @override
  String get calRecurrenceNone => 'Does not repeat';

  @override
  String get calFormNone => 'None';

  @override
  String get calFormNoReminder => 'No reminder';

  @override
  String get calFormCalendarLoadFailed => 'Could not load';

  @override
  String get calFormLabelHint =>
      'Create labels in Settings under Calendar labels';

  @override
  String get calFormStartDay => 'Start date';

  @override
  String get calFormStartTime => 'Start time';

  @override
  String get calFormEndDay => 'End date';

  @override
  String get calFormEndTime => 'End time';

  @override
  String get calFormEndBeforeStart => 'End cannot be before the start';

  @override
  String get calFormTitleRequired => 'Enter a title';

  @override
  String get calFormRows => 'Event details';

  @override
  String get calFormRowsMore => 'Repeat, reminder, location and description';

  @override
  String get calFormSaveFailed =>
      'Couldn\'t save the event. Please try again in a moment.';

  @override
  String get calFormDeleteFailed => 'Couldn\'t delete the event.';

  @override
  String calReminderMinutesBefore(int n) {
    return '$n min before';
  }

  @override
  String get calReminderHourBefore => '1 hour before';

  @override
  String get calReminderDayBefore => '1 day before';

  @override
  String calEventDeleteConfirm(String title) {
    return 'Delete the \"$title\" event? A deleted event cannot be restored.';
  }

  @override
  String calEventDeleteConfirmRecurring(String title) {
    return '\"$title\" is a repeating event, so every occurrence will be deleted. This action cannot be undone.';
  }

  @override
  String get calEventAdded => 'Event added';

  @override
  String get calEventUpdated => 'Event updated';

  @override
  String get calLabelsTitle => 'Calendar labels';

  @override
  String calAllLabelsCount(int count) {
    return 'All labels · $count';
  }

  @override
  String get calLabelsEmpty => 'No labels yet';

  @override
  String get calLabelsEmptyHint =>
      'Create one with the \"New label\" button above';

  @override
  String get calLabelsIntro =>
      'These labels are shared across all your calendars. You can pick one when creating an event.';

  @override
  String get calNewLabel => 'Add label';

  @override
  String get calEditLabel => 'Edit label';

  @override
  String get calPreview => 'Preview';

  @override
  String get calDeleteLabelTitle => 'Delete label';

  @override
  String calDeleteLabelConfirm(String name) {
    return 'Delete the \"$name\" label? Events with this label will become unlabeled. A deleted label cannot be restored.';
  }

  @override
  String get calDatePicker => 'Select month';

  @override
  String calFilterChipName(int count) {
    return 'Showing $count calendars';
  }

  @override
  String calMoreEvents(int count) {
    return '+$count';
  }

  @override
  String get calEventsLoadFailed => 'Couldn\'t load events';

  @override
  String calCalendarChipCount(int count) {
    return '$count';
  }

  @override
  String get calNoCalendars => 'No calendars.';

  @override
  String get calOtherSources => 'Other sources';

  @override
  String get calHolidays => 'Holidays';

  @override
  String get calManageShareSettings => 'Manage & share calendars';

  @override
  String get calNoEventsThisDay => 'No events on this day.';

  @override
  String calEventTotalCount(int count) {
    return '$count';
  }

  @override
  String get calManageShareTitle => 'Manage & share';

  @override
  String get calJoinByCode => 'Join with invite code';

  @override
  String get calRoleOwner => 'Owner';

  @override
  String get calRoleEditor => 'Can edit';

  @override
  String get calRoleViewer => 'View only';

  @override
  String get calShareIntroTitle => 'Share with family & friends';

  @override
  String get calShareIntroBody =>
      'Create a calendar and invite members to manage events together.';

  @override
  String get calNewCalendar => 'Add calendar';

  @override
  String calMyCalendarsCount(int count) {
    return 'My calendars · $count';
  }

  @override
  String get calNoOwnedCalendars => 'You don\'t own any calendars yet';

  @override
  String calSharedCalendarsCount(int count) {
    return 'Shared calendars · $count';
  }

  @override
  String get calNoSharedCalendars => 'No shared calendars';

  @override
  String get calDefault => 'Default';

  @override
  String get calOnlyMe => 'Only me';

  @override
  String calMemberCount(int count) {
    return '$count members';
  }

  @override
  String get calJoinCardBody =>
      'Enter an invite code you received to join a calendar.';

  @override
  String get calJoin => 'Join';

  @override
  String get calCreate => 'Create';

  @override
  String calJoinedCalendar(String name) {
    return 'Joined \"$name\"';
  }

  @override
  String get calInviteCode => 'Invite code';

  @override
  String calManageTitle(String name) {
    return '$name · Manage';
  }

  @override
  String get calDeleteCalendar => 'Delete calendar';

  @override
  String get calCalendarUpdated => 'Calendar updated';

  @override
  String get calInviteCodeRegenerated => 'Generated a new invite code';

  @override
  String get calInviteCodeCopied => 'Invite code copied';

  @override
  String get calRemoveMember => 'Remove member';

  @override
  String calRemoveMemberConfirm(String name) {
    return 'Remove \"$name\" from this calendar?';
  }

  @override
  String get calRemove => 'Remove';

  @override
  String calDeleteCalendarConfirm(String name) {
    return 'Delete the \"$name\" calendar? Events move to the default calendar and all members lose access. A deleted calendar cannot be restored.';
  }

  @override
  String get calDeleteCalendarAction => 'Delete permanently';

  @override
  String get calCopy => 'Copy';

  @override
  String get calRegenerate => 'Regenerate';

  @override
  String get calMembers => 'Members';

  @override
  String get calMeSuffix => '(me)';

  @override
  String get calChangeToEditor => 'Change to editor';

  @override
  String get calChangeToViewer => 'Change to viewer';

  @override
  String get calAdd => 'Add';

  @override
  String get calActionFailed => 'Failed';

  @override
  String get calSaveFailed => 'Save failed';

  @override
  String get calDeleteFailed => 'Delete failed';

  @override
  String get calJoinFailed => 'Failed to join';

  @override
  String get calUpdateFailed => 'Update failed';

  @override
  String get calCalendarLoadError => 'Failed to load calendars';

  @override
  String get calLabelLoadError => 'Failed to load labels';

  @override
  String get calMemberLoadError => 'Failed to load members';

  @override
  String get dashTitle => 'Home';

  @override
  String get dashGreeting => 'Have a great day';

  @override
  String get dashTotalAssets => 'Total assets';

  @override
  String get dashChange => 'Change';

  @override
  String get dashThisMonthExpense => 'This month\'s expense';

  @override
  String get dashThisMonthIncome => 'This month\'s income';

  @override
  String get dashRecent => 'Recent transactions';

  @override
  String get dashUpcoming => 'Upcoming events';

  @override
  String get dashRecentTodos => 'Recent todos';

  @override
  String dashOverdue(int count) {
    return 'Overdue $count';
  }

  @override
  String dashOverdueRead(int count) {
    return 'Overdue $count';
  }

  @override
  String get dashTrendTitle => 'Last 6 months';

  @override
  String get dashEmptyTransactions => 'No recent transactions';

  @override
  String get dashEmptyEvents => 'No upcoming events';

  @override
  String get dashEmptyTodos => 'No pending todos';

  @override
  String get dashAddTx => 'Add transaction';

  @override
  String get dashTodayLabel => 'Today';

  @override
  String get dashTomorrowLabel => 'Tomorrow';

  @override
  String dashDaysLeft(int n) {
    return '${n}d';
  }

  @override
  String get dashVsLastMonth => 'vs. last month';

  @override
  String get dashLiabilities => 'Liabilities';

  @override
  String dashMonthLedger(int month) {
    return '$month ledger';
  }

  @override
  String get dashDailyAvgPrefix => 'Daily average ';

  @override
  String get dashSpentMasked => ' spent.';

  @override
  String get dashSpentUnit => ' spent.';

  @override
  String get dashVsPrevPrefix => ', vs last month ';

  @override
  String get dashSaving => ' saved.';

  @override
  String get dashSpentMore => ' more.';

  @override
  String get dashSame => ' the same.';

  @override
  String get dashNoCategoryData => 'No spending this month';

  @override
  String get dashNoBudget => 'No budgets set';

  @override
  String get dashTodaySpend => 'Spent today';

  @override
  String get dashNoTodaySpend => 'Nothing spent today yet';

  @override
  String get dashViewAll => 'View all';

  @override
  String get dashHideAmountsSettings => 'Hide amounts settings';

  @override
  String get dashNoLastMonth => 'No record for last month';

  @override
  String dashBudgetOf(String name) {
    return '$name budget';
  }

  @override
  String get dashBudgetTotal => 'Total budget';

  @override
  String dashCategoryChartLabel(int month, String total) {
    return 'Spending by category in month $month, total $total';
  }

  @override
  String get dashCategoryOthers => 'Others';

  @override
  String get dashTableShare => 'Share';

  @override
  String get dashTableAmount => 'Amount';

  @override
  String get dashFailNetWorth => 'Couldn\'t load net worth';

  @override
  String get dashFailMonth => 'Couldn\'t load this month\'s ledger';

  @override
  String get dashFailCategory => 'Couldn\'t load categories';

  @override
  String get dashFailBudget => 'Couldn\'t load budgets';

  @override
  String get dashFailUpcoming => 'Couldn\'t load upcoming events';

  @override
  String get dashFailTodos => 'Couldn\'t load recent todos';

  @override
  String get dashFailToday => 'Couldn\'t load today\'s spending';

  @override
  String get dashFailDesc => 'Please try again in a moment.';

  @override
  String get expTitle => 'Expenses';

  @override
  String get expFilterAll => 'All';

  @override
  String get expFilterIncome => 'Income';

  @override
  String get expFilterExpense => 'Expense';

  @override
  String get expFilterTransfer => 'Transfer';

  @override
  String get expEmpty => 'No transactions';

  @override
  String get expEmptyDescription => 'Add your first transaction to get started';

  @override
  String get expAdd => 'Add transaction';

  @override
  String get expEdit => 'Edit transaction';

  @override
  String get expDelete => 'Delete transaction';

  @override
  String get expAmount => 'Amount';

  @override
  String get expCategory => 'Category';

  @override
  String get expAsset => 'Asset';

  @override
  String get expDate => 'Date';

  @override
  String get expMerchant => 'Merchant';

  @override
  String get expPaymentMethod => 'Payment';

  @override
  String get expForeignPayment => 'Foreign payment';

  @override
  String get expCurrency => 'Currency';

  @override
  String get expOriginalAmount => 'Local amount';

  @override
  String get expExchangeRate => 'Rate';

  @override
  String expFxHint(String original, String krw) {
    return '$original → $krw';
  }

  @override
  String get expInstallment => 'Installment';

  @override
  String get expRefund => 'Refund';

  @override
  String get expRefundConfirmTitle => 'Mark as refunded';

  @override
  String expRefundConfirmBody(String amount, String asset) {
    return 'Marks this transaction as refunded. It leaves your totals, and $amount returns to $asset.';
  }

  @override
  String get expRefundConfirmBodyRecordOnly =>
      'Marks this transaction as refunded. It leaves your totals.';

  @override
  String get expRefundConfirmBodyCardNoAccount =>
      'No payment account is linked, so only the card balance is adjusted.';

  @override
  String get expRefundDate => 'Refund date';

  @override
  String get expRefundConfirm => 'Mark refunded';

  @override
  String expRefundedAt(String date) {
    return 'Refunded · $date — left out of your totals.';
  }

  @override
  String get expRefundCancel => 'Undo refund';

  @override
  String get expRefundCancelConfirm =>
      'Remove the refund mark? This transaction counts in your totals again, and any refunded amount is reversed.';

  @override
  String get expRefundCancelConfirmPlain =>
      'Remove the refund mark? This transaction counts in your totals again.';

  @override
  String get expRefundedBadge => 'Refunded';

  @override
  String expRefundedToast(String amount) {
    return '$amount you paid in advance went back to your account';
  }

  @override
  String get expLumpSum => 'Lump sum';

  @override
  String expInstallmentMonths(int months) {
    return '$months months';
  }

  @override
  String expInstallmentHint(String perMonth, int months) {
    return 'About $perMonth per month for $months months';
  }

  @override
  String get expDescription => 'Note';

  @override
  String get expTypeIncome => 'Income';

  @override
  String get expTypeExpense => 'Expense';

  @override
  String get transferFeePrefix => 'Fee';

  @override
  String get transferPrincipal => 'Principal';

  @override
  String get transferWithdrawn => 'Total withdrawn';

  @override
  String get transferDeleted => 'Transfer deleted';

  @override
  String get transferDeleteConfirm =>
      'Delete this transfer? Both accounts\' balances go back to before the transfer. A deleted transfer can\'t be restored.';

  @override
  String get transferDeleteTitle => 'Delete transfer';

  @override
  String get transferAutoTradeSettlement =>
      'Created automatically to cover a shortfall when buying. It disappears when the purchase is cancelled.';

  @override
  String get transferAutoCardPayment =>
      'Created by a card auto-payment. It is tied to the billing cycle and cannot be edited separately.';

  @override
  String get transferAutoCardRefund =>
      'Created to return a card overpayment to the payment account. Adjust the card balance directly and it reconciles automatically the next day.';

  @override
  String get transferAutoDefault =>
      'Created automatically. It disappears when the original is deleted.';

  @override
  String updateAvailable(String version) {
    return 'Version $version is available';
  }

  @override
  String get updateAvailableDesc => 'Tap to download and install';

  @override
  String get updateAvailableDescIos => 'Tap to get it from AltStore';

  @override
  String updateSheetTitle(String version) {
    return 'Version $version is available';
  }

  @override
  String get updateSheetSubtitle =>
      'A new version is ready. You can get it right below.';

  @override
  String get updateSheetChanges => 'What\'s new';

  @override
  String get updateSheetNoNotes =>
      'No change notes were prepared for this version.';

  @override
  String get updateSheetLater => 'Later';

  @override
  String get updateSheetNow => 'Update';

  @override
  String get updateSheetRetry => 'Try again';

  @override
  String get updateSheetDownloading => 'Downloading';

  @override
  String get updateSheetOpening => 'Opening the installer';

  @override
  String get updateSheetFailed =>
      'Could not download in the app. Opening your browser instead.';

  @override
  String get updateTitle => 'Update';

  @override
  String updateGateTitle(String version) {
    return 'Version $version is here';
  }

  @override
  String get updateGateInstall => 'Install';

  @override
  String get updateGateForcedCancelBody =>
      'This update includes changes you must install.';

  @override
  String get updateCheckFailedTitle => 'Couldn\'t check for updates';

  @override
  String get updateUpToDate => 'You\'re up to date';

  @override
  String updateCurrentBuild(String build) {
    return 'Current build $build';
  }

  @override
  String get updateCheckFailed => 'Couldn\'t check for a new version.';

  @override
  String get updateRequiredDesc =>
      'This update is required. You can\'t use the app until you install it.';

  @override
  String get expScheduled => 'Scheduled';

  @override
  String get expTypeTransfer => 'Transfer';

  @override
  String get expTransferFrom => 'From';

  @override
  String get expTransferTo => 'To';

  @override
  String get expFee => 'Fee';

  @override
  String get expFilter => 'Filter';

  @override
  String get expFilterMin => 'Min';

  @override
  String get expFilterMax => 'Max';

  @override
  String get expFilterPeriod => 'Period';

  @override
  String get expSplit => 'Split transaction';

  @override
  String get expConvertDutch => 'To Dutch Pay';

  @override
  String get expConvertRecurring => 'To Recurring';

  @override
  String get expExport => 'Export';

  @override
  String get expExportCsv => 'Export CSV';

  @override
  String get expSummaryTitle => 'Monthly summary';

  @override
  String get expSummaryIncome => 'Income';

  @override
  String get expSummaryExpense => 'Expense';

  @override
  String get expSummaryBalance => 'Balance';

  @override
  String get budgetCategoryAdd => 'Add category budget';

  @override
  String get budgetCategoryEdit => 'Edit category budget';

  @override
  String get budgetSubmitAdd => 'Add';

  @override
  String get budgetFormAmountLabel => 'Budget';

  @override
  String get budgetFormCategoryPlaceholder => 'Select category';

  @override
  String get budgetFormQuickAmounts => 'Quick amounts';

  @override
  String get budgetFormErrCategory => 'Select a category.';

  @override
  String get budgetFormErrTotal => 'Enter the total budget.';

  @override
  String get budgetFormErrAmount => 'Enter the budget.';

  @override
  String get amountTooLarge => 'Enter an amount up to 10 billion won.';

  @override
  String get budgetPickUsed => 'Already has a budget this month';

  @override
  String get budgetPickAllBudgeted =>
      'Every expense category already has a budget.';

  @override
  String get budgetPickNoCategory =>
      'There are no expense categories to budget.';

  @override
  String get budgetPickLoadFailTitle => 'Couldn\'t load the categories';

  @override
  String get budgetPickLoadFailDesc => 'Please try again in a moment.';

  @override
  String get budgetUpdated => 'Budget updated';

  @override
  String get budgetAdded => 'Budget added';

  @override
  String get budgetActionFailed => 'Failed';

  @override
  String budgetDeleteTitle(String name) {
    return 'Delete the \"$name\" budget?';
  }

  @override
  String get budgetDeleteConfirm => 'A deleted budget can\'t be restored.';

  @override
  String get budgetDeleteFailed => 'Couldn\'t delete the budget.';

  @override
  String get budgetMonthlyLimit => 'Monthly budget limit';

  @override
  String get budgetLoadError => 'Couldn\'t load budget';

  @override
  String get budgetSelectMonth => 'Select month';

  @override
  String budgetMonthOverallCap(int month) {
    return 'Month $month total budget';
  }

  @override
  String get budgetOverallCapDesc =>
      'The cap for this month\'s total spending (including spending without a category budget).';

  @override
  String get budgetOverallCapEmptyHint =>
      'There is no total budget yet. You can set this month\'s spending limit in settings.';

  @override
  String budgetEmptyMonthTitle(int month) {
    return 'No budget for month $month yet';
  }

  @override
  String get budgetEmptyMonthDesc =>
      'Set a budget to see what you spent and what is left at a glance.';

  @override
  String get budgetFailCompliance => 'Couldn\'t load the budget compliance';

  @override
  String get budgetManagerLoadFailed => 'Couldn\'t load budgets';

  @override
  String budgetCategoryCount(int count) {
    return '$count categories';
  }

  @override
  String budgetOverLimit(String amount) {
    return 'Over limit by $amount';
  }

  @override
  String get budgetTableMonth => 'Month';

  @override
  String get budgetCurrentCategorySum => 'Current category limit total';

  @override
  String budgetPercentUsed(String pct) {
    return '$pct% used';
  }

  @override
  String budgetRemaining(String amount) {
    return 'Remaining $amount';
  }

  @override
  String budgetOverBy(String amount) {
    return 'Over by $amount';
  }

  @override
  String get budgetOverallCapLabel => 'Total budget';

  @override
  String get budgetCategoryAllocated => 'Category allocated';

  @override
  String get budgetAllocatable => 'Allocatable';

  @override
  String budgetOverAllocatedWarning(String amount) {
    return 'Category limits exceed the total budget by $amount. Raise the total budget or lower the category limits.';
  }

  @override
  String get budgetSpendingPace => 'Spending pace';

  @override
  String get budgetPaceBarName => 'Spending pace this month';

  @override
  String budgetPaceBarValue(String used, String elapsed) {
    return '$used% used · $elapsed% of the month passed';
  }

  @override
  String get budgetPaceOnTrack => 'On pace';

  @override
  String get budgetPaceFast => 'Too fast';

  @override
  String budgetMonthElapsed(String pct) {
    return '$pct% of month elapsed ↑';
  }

  @override
  String get budgetDailyAvg => 'Daily average';

  @override
  String get budgetDailyRecommended => 'Recommended per remaining day';

  @override
  String get budgetStatusTitle => 'Budget status';

  @override
  String get budgetOver => 'Over';

  @override
  String get budgetHealthy => 'On track';

  @override
  String get budgetByCategory => 'Budget by category';

  @override
  String budgetCountSet(int count) {
    return '$count set';
  }

  @override
  String get budgetNoCategoryBudgets => 'No category budgets';

  @override
  String get budgetGoToSettings => 'Go set a budget';

  @override
  String budgetCategoryFallback(int id) {
    return 'Category #$id';
  }

  @override
  String get budgetComplianceTitle => 'Last 6 months compliance';

  @override
  String get budgetComplianceSubtitle => 'Spending vs limit %';

  @override
  String get budgetNoComplianceData => 'No compliance data yet';

  @override
  String get budgetVsLimit => 'vs limit';

  @override
  String get budgetLimit => 'Limit';

  @override
  String get budgetSetup => 'Budget settings';

  @override
  String get budgetCopyLastMonth => 'Copy last month\'s budget?';

  @override
  String budgetCopyOverwriteMessage(int count) {
    return '$count budgets this month will be replaced with last month\'s. This can\'t be undone once it\'s changed.';
  }

  @override
  String budgetCopyPartialFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count budgets couldn\'t be copied.',
      one: '1 budget couldn\'t be copied.',
    );
    return '$_temp0';
  }

  @override
  String get budgetCopiedDone => 'Last month\'s budget was copied.';

  @override
  String get budgetCopyUndo => 'Undo';

  @override
  String budgetCopyUndoPartial(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count budgets couldn\'t be undone.',
      one: '1 budget couldn\'t be undone.',
    );
    return '$_temp0';
  }

  @override
  String get budgetCopyLastMonthBtn => 'Copy last month';

  @override
  String budgetMonthTotal(int month) {
    return 'Month $month Total Budget';
  }

  @override
  String get budgetNotSet => 'Not set';

  @override
  String get budgetUsed => 'Used';

  @override
  String get budgetAllocated => 'Allocated';

  @override
  String budgetByCategoryCount(int count) {
    return 'Budget by category · $count';
  }

  @override
  String get budgetAdd => 'Add budget';

  @override
  String get budgetNoCategorySet => 'No category budgets set';

  @override
  String get cardBenefitTypeAll => 'All benefits';

  @override
  String get cardBenefitTypeDiscount => 'Discount';

  @override
  String get cardBenefitTypePoint => 'Points';

  @override
  String get cardBenefitTypeCashback => 'Cashback';

  @override
  String get cardBenefitTypeMileage => 'Mileage';

  @override
  String get cardBenefitsTitle => 'Card benefits';

  @override
  String get cardSelectTitle => 'Select card';

  @override
  String get cardSearchHintFull => 'Search by name, brand, or benefit';

  @override
  String get cardSearchHintNameCompany => 'Search card / issuer';

  @override
  String get cardDetailLoadError => 'Failed to load card details';

  @override
  String get cardSearchError => 'Card search failed';

  @override
  String get cardAddFailed => 'Failed to add';

  @override
  String get cardDeleteFailed => 'Failed to delete';

  @override
  String get cardLastMonthPerf => 'Last month spend';

  @override
  String get cardKeyBenefitTags => 'Key benefit tags';

  @override
  String cardBenefitDetailCount(int count) {
    return 'Benefit details · $count';
  }

  @override
  String get cardExpandAll => 'Expand all';

  @override
  String get cardCollapseAll => 'Collapse all';

  @override
  String get cardCautions => 'Notes';

  @override
  String get cardNone => 'None';

  @override
  String get cardFeeUnknown => 'Unknown';

  @override
  String get cardFeeFree => 'Free';

  @override
  String get cardPerfNone => 'No spend requirement';

  @override
  String cardFeeDomesticOnly(String amount) {
    return 'Domestic only $amount';
  }

  @override
  String cardPerfMin(String amount) {
    return '$amount or more';
  }

  @override
  String cardPerfMonthly(String amount) {
    return 'Spend $amount/mo';
  }

  @override
  String cardAnnualFeeValue(String fee) {
    return 'Annual fee $fee';
  }

  @override
  String cardPerfMonthTitle(String month) {
    return '$month spend';
  }

  @override
  String get cardPerfAchieved => 'Achieved';

  @override
  String cardPerfRemaining(String amount) {
    return '$amount left';
  }

  @override
  String get cardIncludeDiscontinued => 'Include discontinued cards';

  @override
  String cardTotalCount(int count) {
    return '$count total';
  }

  @override
  String get cardNoResults => 'No results';

  @override
  String get cardNoResultsHint => 'Try a different search term';

  @override
  String get cardPickerNoMatch => 'No matching cards';

  @override
  String get categoryManageTitle => 'Manage categories';

  @override
  String get categorySearchHint => 'Search categories';

  @override
  String get categoryLoadError => 'Failed to load categories';

  @override
  String get categoryNoResults => 'No matching categories.';

  @override
  String get categoryEmpty => 'No categories yet.';

  @override
  String get categoryAdd => 'Add category';

  @override
  String get categoryAddAction => 'Add';

  @override
  String get recurringAddAction => 'Add';

  @override
  String get presetAddAction => 'Add';

  @override
  String categoryListTitleExpense(int count) {
    return '$count expense categories';
  }

  @override
  String categoryListTitleIncome(int count) {
    return '$count income categories';
  }

  @override
  String get categoryEdit => 'Edit category';

  @override
  String get categoryNameRequired => 'Please enter a name.';

  @override
  String get categoryNameTooLong => 'Name must be 12 characters or fewer.';

  @override
  String get categoryNameDuplicate =>
      'A category with this name already exists in this spot.';

  @override
  String get categoryParent => 'Parent category';

  @override
  String get categoryBudgetExceedTitle => 'Budget exceeded';

  @override
  String categoryBudgetExceedMessage(String parent, String amount) {
    return 'Moving it will put \"$parent\" $amount over budget. Move anyway?';
  }

  @override
  String get categoryMove => 'Move';

  @override
  String get categoryUpdated => 'Category updated';

  @override
  String get categoryAdded => 'Category added';

  @override
  String get categoryActionFailed => 'Failed';

  @override
  String get categoryDeleteBlockedTitle => 'Can\'t delete';

  @override
  String categoryDeleteHasChildren(String name) {
    return 'The \"$name\" category has subcategories and cannot be deleted. Clear them first.';
  }

  @override
  String categoryDeleteConfirm(String name) {
    return 'Delete the \"$name\" category?';
  }

  @override
  String get categoryDeleteFailed => 'Delete failed';

  @override
  String get categoryParentMoveHint =>
      'To make it top level, create a new top-level category and move its transactions.';

  @override
  String get categoryMakeRoot => 'Top level';

  @override
  String get categoryNamePlaceholder => 'e.g., Pets, Side income';

  @override
  String get categoryIconLabel => 'Icon';

  @override
  String get categoryLoadFailed => 'Couldn\'t load the categories';

  @override
  String get categoryDeleteMessage =>
      'Recorded transactions stay as they are. Budgets set for this category are deleted too.';

  @override
  String categoryDeleteRecurring(int count) {
    return '$count recurring transactions that use this category keep being recorded under it.';
  }

  @override
  String categoryExpandOf(String name) {
    return '$name subcategories';
  }

  @override
  String categoryMoreOf(String name) {
    return 'More for $name';
  }

  @override
  String categoryDragReorderOf(String name) {
    return 'Reorder $name';
  }

  @override
  String get categoryKindLabel => 'Type';

  @override
  String get categorySubmitAdd => 'Add';

  @override
  String get categoryAddSub => 'Add subcategory';

  @override
  String get authLoginPrompt => 'Sign in with your 그루 account.';

  @override
  String get authSsoLogin => 'Sign in with 그루';

  @override
  String get authLoginTitle => 'Login';

  @override
  String get authLoginFailed => 'Could not sign in.';

  @override
  String get authLoginExpired =>
      'Your sign-in timed out. Please sign in again.';

  @override
  String get authLoginError => 'Could not complete sign-in.';

  @override
  String get authSecurityNotHttps =>
      'The connection to the sign-in server is not secure.';

  @override
  String get authStateMismatch =>
      'Security check failed (state mismatch). Please try again.';

  @override
  String get authNoAuthCode =>
      'Couldn\'t get the authorization code. Please try again.';

  @override
  String get authPageLoadError => 'Couldn\'t load the login page.';

  @override
  String get dutchTitle => 'Dutch Pay';

  @override
  String get dutchCreate => 'Create settlement';

  @override
  String dutchStepTitle(String title, int step, int total) {
    return '$title ($step/$total)';
  }

  @override
  String get dutchLoadFailed => 'Failed to load Dutch Pay';

  @override
  String get dutchTabActive => 'Active';

  @override
  String get dutchTabPast => 'Done';

  @override
  String get dutchTabFriends => 'Friends';

  @override
  String get dutchEmptyActiveTitle => 'No active settlements';

  @override
  String get dutchEmptyActiveSub => 'Tap + to create a new settlement.';

  @override
  String get dutchEmptyPastTitle => 'No completed settlements';

  @override
  String get dutchEmptyPastSub => 'Completed settlements appear here.';

  @override
  String get dutchEmptyFriendsTitle => 'No friends yet';

  @override
  String get dutchEmptyFriendsSub =>
      'Add participants to a settlement to see them here.';

  @override
  String get dutchActionFailed => 'Failed';

  @override
  String get dutchSettleFailed => 'Settlement failed';

  @override
  String get dutchDeleteFailed => 'Delete failed';

  @override
  String get dutchToReceive => 'To receive';

  @override
  String get dutchToSend => 'To send';

  @override
  String dutchFromPeople(int count) {
    return 'from $count people';
  }

  @override
  String dutchToPeople(int count) {
    return 'to $count people';
  }

  @override
  String get dutchPerPersonLabel => 'Per person';

  @override
  String dutchNPeople(int count) {
    return '$count people';
  }

  @override
  String dutchSettledTogetherCount(int count) {
    return 'Settled together $count times';
  }

  @override
  String get dutchSettled => 'Settled';

  @override
  String get dutchMe => 'Me';

  @override
  String get dutchPayer => 'Payer';

  @override
  String get dutchSetPayer => 'Set as payer';

  @override
  String get dutchNameLabel => 'Settlement name';

  @override
  String get dutchNamePlaceholder => 'e.g. Team dinner';

  @override
  String get dutchPlaceLabel => 'Place (optional)';

  @override
  String get dutchPlacePlaceholder => 'Place or merchant';

  @override
  String get dutchTotalLabel => 'Total amount';

  @override
  String get dutchDateLabel => 'Date';

  @override
  String get dutchSelectParticipants => 'Select participants';

  @override
  String dutchNSelected(int count) {
    return '$count selected';
  }

  @override
  String get dutchAddNamePlaceholder => 'Enter a name to add';

  @override
  String get dutchNameAlreadyAdded => 'That name is already added.';

  @override
  String get dutchAdd => 'Add';

  @override
  String get dutchNext => 'Next';

  @override
  String get dutchPrev => 'Back';

  @override
  String get dutchDetailTitle => 'Settlement details';

  @override
  String get dutchParticipant => 'Participant';

  @override
  String get dutchSettleAction => 'Mark as settled';

  @override
  String get dutchDeleteTitle => 'Delete Dutch Pay';

  @override
  String dutchDeleteConfirm(String title) {
    return 'Delete the \"$title\" Dutch Pay? A deleted Dutch Pay cannot be restored.';
  }

  @override
  String get dutchRequestAll => 'Request all';

  @override
  String dutchRequestSent(String name) {
    return 'Payment request sent to $name (KakaoTalk/SMS coming soon)';
  }

  @override
  String dutchRequestSentBulk(int count) {
    return 'Payment request sent to $count people (KakaoTalk/SMS coming soon)';
  }

  @override
  String get dutchAllSettled => 'All participants have already settled';

  @override
  String dutchNeedsPayment(String amount) {
    return 'Send $amount원';
  }

  @override
  String get dutchNoName => '(No name)';

  @override
  String get dutchMarkPaid => 'Mark as paid';

  @override
  String get dutchRequest => 'Request';

  @override
  String get dutchUnsettled => 'Unsettled';

  @override
  String get dutchStartTitle => 'Start Dutch Pay';

  @override
  String get dutchFromTxDesc =>
      'Create a Dutch Pay settlement from this transaction. Send payment requests to participants and track settlement progress.';

  @override
  String get dutchSplitMethod => 'Split method';

  @override
  String get dutchSplitEqualTitle => '1/N';

  @override
  String get dutchSplitEqualSub => 'Equal split';

  @override
  String get dutchSplitRatioTitle => 'Ratio';

  @override
  String get dutchSplitRatioSub => 'By weight';

  @override
  String get dutchSplitCustomTitle => 'Custom amount';

  @override
  String get dutchSplitCustomSub => 'Each differently';

  @override
  String get dutchIncludeMyself => 'Include myself in the split';

  @override
  String get dutchIncludeMyselfDesc => 'Your share is calculated too';

  @override
  String get dutchIncludeMyselfOffDesc =>
      'You paid in full, collect only others\' shares';

  @override
  String get dutchSourceSub => 'Request payments from participants';

  @override
  String get dutchRequestMsgLabel => 'Request message (optional)';

  @override
  String get dutchRequestMsgPlaceholder => 'Add a note to send to participants';

  @override
  String dutchShortBy(String amount) {
    return 'The total is $amount원 short.';
  }

  @override
  String dutchOverBy(String amount) {
    return 'The total exceeds by $amount원.';
  }

  @override
  String get dutchCreated => 'Settlement created';

  @override
  String get expLoadError => 'Couldn\'t load transactions';

  @override
  String get expEmptyMonth => 'No transactions this month';

  @override
  String get expEmptyDay => 'No transactions on this day';

  @override
  String get expTotal => 'Total';

  @override
  String get expFiltering => 'Filtering';

  @override
  String expFilteringBy(String name) {
    return 'Filtering: $name';
  }

  @override
  String get expViewList => 'List';

  @override
  String get expViewCalendar => 'Calendar';

  @override
  String expTxCount(int count) {
    return '$count items';
  }

  @override
  String get expAddShort => 'Add';

  @override
  String get expTransferDone => 'Transfer completed';

  @override
  String get expActionFailed => 'Failed';

  @override
  String get expUpdated => 'Transaction updated';

  @override
  String get expAdded => 'Transaction added';

  @override
  String expDeleteConfirm(String name) {
    return 'Delete the \"$name\" transaction? The linked asset balance will be adjusted too. A deleted transaction cannot be restored.';
  }

  @override
  String get expDeleted => 'Transaction deleted';

  @override
  String get expSplitMismatch => 'Split doesn\'t match the amount';

  @override
  String expSplitDiff(String total, String sum, String diff) {
    return 'New total $total원 · Split sum $sum원 · $diff원 diff';
  }

  @override
  String get expSplitReconcile => 'Reconcile split';

  @override
  String get expPresetLoad => 'Load preset';

  @override
  String get expPresetApplied => 'Applied';

  @override
  String get expPresetSaveCurrent => 'Save current input';

  @override
  String get expPresetEmpty =>
      'No saved presets yet. Enter a transaction you use often, then tap “Save current input”.';

  @override
  String get expPresetFilled =>
      'Preset values filled in. Adjust the amount and note, then save.';

  @override
  String get expClear => 'Clear';

  @override
  String get expSaveFailed => 'Save failed';

  @override
  String get expPresetSaveTitle => 'Save as preset';

  @override
  String get expPresetNamePlaceholder => 'e.g. Lunch box';

  @override
  String get presetNameDuplicate => 'A preset with this name already exists.';

  @override
  String expPresetLockAmount(String amount) {
    return 'Lock amount — auto-fills $amount원 when applied';
  }

  @override
  String get expPayCash => 'Cash';

  @override
  String get expPayCard => 'Card';

  @override
  String get expPayTransfer => 'Bank transfer';

  @override
  String get expPayOther => 'Other';

  @override
  String get expAutoLock => 'Auto';

  @override
  String get expAutoSourceTradeRealized =>
      'Realized P/L from a sale. The amount is calculated from the trade.';

  @override
  String get expAutoSourceTransferInterest =>
      'Interest on a transfer. The amount is calculated from the transfer.';

  @override
  String get expAutoSourceCardCarryover =>
      'This is the unpaid usage you entered when adding the card. Change the amount by editing the card.';

  @override
  String get expAutoSourceDefault =>
      'Created automatically. It disappears when the original is deleted.';

  @override
  String get expPresetLock => 'Preset lock';

  @override
  String get expNoCategoryForType => 'No categories for this type';

  @override
  String get expSubcategory => 'Subcategory';

  @override
  String expTopCategorySuffix(String name) {
    return '$name (parent)';
  }

  @override
  String get expIncomeSource => 'Income source';

  @override
  String get expPayee => 'Merchant';

  @override
  String get expIncomeSourcePlaceholder => 'e.g. Salary';

  @override
  String get expPayeePlaceholder => 'e.g. Lunch near the office';

  @override
  String get expIncomeMethod => 'Income method';

  @override
  String get expNone => 'None';

  @override
  String get expDepositAccount => 'Deposit account';

  @override
  String get expAccountCard => 'Account/Card';

  @override
  String get expAssetLoadError => 'Failed to load assets';

  @override
  String get expWithdrawAccount => 'From account';

  @override
  String get expSelect => 'Select';

  @override
  String get expTransferSameAsset => 'From and to assets must differ';

  @override
  String get expFeeOptional => 'Fee (optional)';

  @override
  String get expInterest => 'Interest';

  @override
  String get expInterestHint =>
      'The interest portion — debt decreases only by the rest';

  @override
  String expInterestSplit(String principal, String interest) {
    return 'Principal $principal · Interest $interest';
  }

  @override
  String get expDateTime => 'Date & time';

  @override
  String get expMemoPlaceholder => 'e.g. Lunch, dinner';

  @override
  String get expIncomeDetail => 'Income details';

  @override
  String get expExpenseDetail => 'Expense details';

  @override
  String get expTxFallback => 'Transaction';

  @override
  String get expUncategorized => 'Uncategorized';

  @override
  String get expNotSelected => 'Not selected';

  @override
  String get expThisMonth => 'This month';

  @override
  String expTimesCount(int count) {
    return '$count×';
  }

  @override
  String get expItem => 'Item';

  @override
  String get expFilterApply => 'Apply filter';

  @override
  String expNSelected(int count) {
    return '$count selected';
  }

  @override
  String get expPeriodCustom => 'Custom';

  @override
  String get expDateRangeError => 'Start date can\'t be after end date.';

  @override
  String get expTxType => 'Transaction type';

  @override
  String get expAmountRange => 'Amount range';

  @override
  String get expMinAmount => 'Min amount';

  @override
  String get expMaxAmount => 'Max amount';

  @override
  String get expSplitSave => 'Save split';

  @override
  String get expSplitRemove => 'Remove split';

  @override
  String get expSplitLoadError => 'Failed to load split';

  @override
  String get expAddAmount => 'Extra amount';

  @override
  String get expSplitSaved => 'Split saved';

  @override
  String get expSplitRemoveConfirm =>
      'This clears all split items for this transaction. Cleared items cannot be restored.';

  @override
  String get expClearFailed => 'Failed to clear';

  @override
  String get expSplitMatches => 'Split sum matches the total';

  @override
  String get expSplitSum => 'Split sum';

  @override
  String get expTotalAmount => 'Total';

  @override
  String get expSplitTotalChanged => 'The total changed — reconcile the split';

  @override
  String get expSplitMismatchTotal => 'Split sum doesn\'t match the total';

  @override
  String get expSplitCheckItems => 'Check the split items';

  @override
  String get expShort => 'Short';

  @override
  String get expOver => 'Over';

  @override
  String get expQuickAdjust => 'Quick adjust';

  @override
  String get expProrate => 'Prorate';

  @override
  String get expProrateDesc => 'Auto-adjust by weight';

  @override
  String get expApplyToLargest => 'Apply to largest';

  @override
  String get expApplyToLargestDesc => 'Difference to the largest item';

  @override
  String get expAdjustItem => 'Adjustment item';

  @override
  String get expAdjustItemDesc => 'Shortfall as a new item';

  @override
  String get expRecommended => 'Recommended';

  @override
  String get expSplitDesc =>
      'Record one payment split by category and item. e.g. Groceries and household items bought together at a mart.';

  @override
  String get expOriginalTx => 'Original transaction';

  @override
  String get expAddItem => 'Add item';

  @override
  String get expSplitEven => 'Split evenly';

  @override
  String get expSplitRatio => 'Split ratio';

  @override
  String get expDeleteItem => 'Delete item';

  @override
  String get expItemNamePlaceholder => 'Item name (optional)';

  @override
  String get exportTitle => 'Export data';

  @override
  String exportShareText(String start, String end) {
    return 'Data export ($start ~ $end)';
  }

  @override
  String get exportSuccess => 'Exported.';

  @override
  String get exportTypeExpense => 'Transactions';

  @override
  String get exportTypeAsset => 'Assets & accounts';

  @override
  String get exportTypeBudget => 'Budget settings';

  @override
  String get exportTypeCategory => 'Categories';

  @override
  String get exportTypeMemo => 'Memos';

  @override
  String get exportTypeCalendar => 'Calendar events';

  @override
  String get exportTypeTodo => 'To-dos';

  @override
  String get exportFormatCsvDesc => 'Excel · Google Sheets';

  @override
  String get exportFormatExcelDesc => 'Microsoft Excel';

  @override
  String get exportFormatJsonDesc => 'Developers & backup';

  @override
  String get exportPeriodThisMonth => 'This month';

  @override
  String get exportPeriodLastMonth => 'Last month';

  @override
  String get exportPeriodLast3Months => 'Last 3 months';

  @override
  String get exportPeriodThisYear => 'This year';

  @override
  String get exportPeriodCustom => 'Custom';

  @override
  String get exportPeriodTitle => 'Select period';

  @override
  String get exportDateRangeError =>
      'Start date can\'t be later than the end date.';

  @override
  String exportTypesTitle(int count) {
    return 'Data types — $count selected';
  }

  @override
  String get exportTypesDesc =>
      'Choose the data to export. Multiple types are bundled into a ZIP.';

  @override
  String exportCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString';
  }

  @override
  String get exportFormatTitle => 'File format';

  @override
  String get exportMaskLabel =>
      'Hide sensitive info (balance, amount, institution)';

  @override
  String get exportPreview => 'Preview';

  @override
  String get exportRun => 'Export';

  @override
  String get exportEmpty => 'No data to export for this period.';

  @override
  String exportPreviewRows(int count) {
    return 'Top $count rows';
  }

  @override
  String get fileAttachTitle => 'Attachments';

  @override
  String get fileTooltipGallery => 'Gallery';

  @override
  String get fileTooltipCamera => 'Camera';

  @override
  String get fileTooltipFile => 'File';

  @override
  String fileUploadComplete(String name) {
    return '$name uploaded';
  }

  @override
  String get fileUploadFailed => 'Upload failed';

  @override
  String get fileDeleteTitle => 'Delete file';

  @override
  String fileDeleteConfirm(String name) {
    return 'Delete \"$name\"? A deleted file cannot be restored.';
  }

  @override
  String get fileDeleteFailed => 'Delete failed';

  @override
  String get fileLoadError => 'Failed to load attachments';

  @override
  String get fileEmpty => 'No attachments';

  @override
  String get moreGroupMoney => 'Money';

  @override
  String get moreGroupDaily => 'Daily';

  @override
  String get moreGroupPersonal => 'Personalization';

  @override
  String get moreGroupSystem => 'Account & System';

  @override
  String get moreItemStocks => 'Stocks';

  @override
  String get moreItemStats => 'Stats';

  @override
  String get moreItemRecurring => 'Recurring';

  @override
  String get moreItemAccountCard => 'Account & Card Management';

  @override
  String get moreItemCardBenefits => 'Card Benefits';

  @override
  String get moreItemDisplay => 'Display';

  @override
  String get moreItemAccount => 'Account';

  @override
  String get moreDescExpense => 'Expense · Income · Transfer';

  @override
  String get moreDescAsset => 'Accounts · Cards · Investments · Debt';

  @override
  String get moreDescStocks => 'Quotes · Holdings · Watchlist · Orders';

  @override
  String get moreDescBudget => 'Monthly · By category';

  @override
  String get moreDescSavingGoal => 'Goals · Progress';

  @override
  String get moreDescStats => 'Category · Trends · Comparison';

  @override
  String get moreDescRecurring => 'Subscriptions · Fixed costs';

  @override
  String get moreDescAccountCard => 'Add · Edit accounts & cards';

  @override
  String get moreDescCalendar => 'Events · Recurring · Reminders';

  @override
  String get moreDescTodo => 'Due · Priority · Tags';

  @override
  String get moreDescMemo => 'Category · Pin · Search';

  @override
  String get moreDescDutchPay => 'Settle · Friends · Payment requests';

  @override
  String get moreDescCardBenefits => 'Search credit & check cards';

  @override
  String get moreDescCategories => 'Expense · Income';

  @override
  String get moreDescPresets => 'Frequently used entries';

  @override
  String get moreDescDisplay => 'Theme · Language · Currency';

  @override
  String get moreDescSettings => 'All settings menu';

  @override
  String get moreDescNotifications => 'Push · Do not disturb';

  @override
  String get moreDescExport => 'CSV · Excel · JSON';

  @override
  String get moreDescAccount => 'Profile · Security · Subscription';

  @override
  String get moreSearchHint => 'Search menu';

  @override
  String get moreSearchEmpty => 'No results found';

  @override
  String get settingsGroupDataMgmt => 'Data Management';

  @override
  String get settingsMenuCategory => 'Category Management';

  @override
  String get settingsMenuAccountCard => 'Account & Card Management';

  @override
  String get settingsMenuBudget => 'Budget Settings';

  @override
  String get settingsMenuRecurring => 'Recurring Management';

  @override
  String get settingsMenuPreset => 'Preset Management';

  @override
  String get settingsGroupTagsLabels => 'Tags · Labels';

  @override
  String get settingsGroupShare => 'Sharing';

  @override
  String get settingsMenuCalendarShare => 'Calendar Management & Sharing';

  @override
  String get settingsMenuCalendarLabel => 'Calendar Labels';

  @override
  String get settingsGroupApp => 'App Environment';

  @override
  String get settingsMenuAppearance => 'Display settings';

  @override
  String get settingsGroupData => 'Data';

  @override
  String get settingsGroupAccount => 'Account';

  @override
  String get settingsMenuAccountMgmt => 'Account Management';

  @override
  String get settingsMenuPrivacyPolicy => 'Privacy Policy';

  @override
  String get settingsPrivacyOpenFailed => 'Couldn\'t open the privacy policy.';

  @override
  String get settingsGroupHelp => 'Help';

  @override
  String get settingsMenuGuide => 'User guide';

  @override
  String get settingsGuideOpenFailed => 'Couldn\'t open the user guide.';

  @override
  String get appearanceTitle => 'Display settings';

  @override
  String get appearanceTheme => 'Theme';

  @override
  String get appearanceThemeLight => 'Light';

  @override
  String get appearanceThemeLightDesc => 'Light background';

  @override
  String get appearanceThemeDark => 'Dark';

  @override
  String get appearanceThemeDarkDesc => 'Dark background';

  @override
  String get appearanceThemeSystem => 'System';

  @override
  String get appearanceThemeSystemDesc => 'Follow OS setting';

  @override
  String hideAmountsLockAllDesc(int total, int count) {
    return 'Hiding $count of $total cards';
  }

  @override
  String get hideAmountsTitle => 'Hide amounts';

  @override
  String get hideAmountsSectionDesc =>
      'Pick the cards to hide. You\'ll verify once when you save.';

  @override
  String get hideAmountsLockAll => 'Lock everything';

  @override
  String get hideAmountsTabAll => 'All';

  @override
  String get hideAmountsSelectAll => 'Select all';

  @override
  String get hideAmountsClearAll => 'Clear all';

  @override
  String hideAmountsSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get hideAmountsDiscardTitle => 'Leave without saving';

  @override
  String get hideAmountsDiscardBody => 'Your selection will be discarded.';

  @override
  String get hideAmountsDiscardConfirm => 'Leave';

  @override
  String get hideAmountsSaved => 'Saved';

  @override
  String get hideAmountsKindLabel => 'Transaction type';

  @override
  String get hideAmountsKindNote =>
      'Hides amounts of that transaction type on every screen. Hiding income or expense also hides totals.';

  @override
  String get hideCardKindExpense => 'Expense';

  @override
  String get hideCardKindIncome => 'Income';

  @override
  String get hideCardKindTransfer => 'Transfers';

  @override
  String get hideAmountsPageHome => 'Home';

  @override
  String get hideAmountsPageAsset => 'Assets';

  @override
  String get hideAmountsPageLedger => 'Ledger';

  @override
  String get hideAmountsPageStats => 'Stats';

  @override
  String get hideAmountsPageBudget => 'Budget';

  @override
  String get hideAmountsPageStocks => 'Stocks';

  @override
  String get hideAmountsPageDutchpay => 'Dutch Pay';

  @override
  String get hideAmountsPageEtc => 'Other';

  @override
  String get hideCardHomeNetWorth => 'Net worth';

  @override
  String get hideCardHomeMonthExpense => 'This month income & spending';

  @override
  String get hideCardHomeCategoryDonut => 'Category donut';

  @override
  String get hideCardHomeBudget => 'Budget progress';

  @override
  String get hideCardHomeTodaySpend => 'Today\'s spending';

  @override
  String get hideCardHomeUpcoming => 'Upcoming payments';

  @override
  String get hideCardAssetNetWorth => 'Net worth & trend';

  @override
  String get hideCardAssetComposition => 'Asset composition';

  @override
  String get hideCardAssetAccounts => 'Accounts & deposits';

  @override
  String get hideCardAssetInvestments => 'Investments';

  @override
  String get hideCardAssetCards => 'Cards';

  @override
  String get hideCardAssetLoans => 'Loans';

  @override
  String get hideCardAssetSavingGoals => 'Saving goals';

  @override
  String get hideCardAssetUpcoming => 'Upcoming payments';

  @override
  String get hideCardAssetDetail => 'Asset detail';

  @override
  String get hideCardAssetManage => 'Manage accounts & cards';

  @override
  String get hideCardLedgerMonthSummary => 'Monthly total';

  @override
  String get hideCardLedgerCalendar => 'Calendar amounts';

  @override
  String get hideCardLedgerTxList => 'Transaction list';

  @override
  String get hideCardLedgerTxDetail => 'Transaction detail';

  @override
  String get hideCardStatsCategory => 'Category tab';

  @override
  String get hideCardStatsTrend => 'Trend tab';

  @override
  String get hideCardStatsCompare => 'Compare tab';

  @override
  String get hideCardBudgetHeader => 'Budget summary';

  @override
  String get hideCardBudgetPace => 'Spending pace';

  @override
  String get hideCardBudgetStatus => 'Status';

  @override
  String get hideCardBudgetCategories => 'Budget by category';

  @override
  String get hideCardBudgetCompliance => 'Compliance';

  @override
  String get hideCardBudgetManage => 'Manage budgets';

  @override
  String get hideCardStocksSummary => 'Valuation summary';

  @override
  String get hideCardStocksHoldings => 'Holdings';

  @override
  String get hideCardStocksDetail => 'Stock detail';

  @override
  String get hideCardDutchpaySummary => 'Dutch pay summary';

  @override
  String get hideCardDutchpaySessions => 'Settlements';

  @override
  String get hideCardEtcSearch => 'Search results';

  @override
  String get hideCardEtcRecurring => 'Recurring';

  @override
  String get hideCardEtcPreset => 'Presets';

  @override
  String get appearanceHideAmount => 'Hide amounts';

  @override
  String get appearanceHideAmountDesc => 'Display all amounts as ••••';

  @override
  String get appearanceRegion => 'Region';

  @override
  String get appearanceRegionDesc =>
      'Days for \'today\' and statistics are calculated in this region. On-screen times follow your device\'s time zone.';

  @override
  String get appearanceCurrency => 'Default currency';

  @override
  String get appearanceCurrencyKrw => 'South Korean Won';

  @override
  String get appearanceCurrencyUsd => 'US Dollar';

  @override
  String get appearanceCurrencyEur => 'Euro';

  @override
  String get appearanceCurrencyJpy => 'Japanese Yen';

  @override
  String get appearanceCurrencyDesc =>
      'New assets and transactions start with this currency.';

  @override
  String get appearanceRegionLoadError => 'Couldn\'t load the region';

  @override
  String get appearanceCurrencyLoadError =>
      'Couldn\'t load the default currency';

  @override
  String get appearanceSaveFailed => 'Couldn\'t change the setting.';

  @override
  String get passwordChanged => 'Password changed';

  @override
  String get passwordChangeFailed =>
      'Couldn\'t change your password. Please try again shortly.';

  @override
  String get passwordCurrent => 'Current password';

  @override
  String get passwordChangeDescription =>
      'Verify your current password and set a new one';

  @override
  String get passwordCurrentInvalid => 'That current password doesn\'t match';

  @override
  String get passwordNew => 'New password';

  @override
  String get passwordNewConfirm => 'Confirm new password';

  @override
  String get passwordMismatch => 'New passwords do not match';

  @override
  String get passwordMatched => 'New passwords match';

  @override
  String get passwordRuleLength => 'At least 8 characters';

  @override
  String get passwordRuleSpecial => 'At least 1 special character';

  @override
  String get passwordSameAsCurrent =>
      'New password must be different from the current one';

  @override
  String get passwordChangeAction => 'Save';

  @override
  String get accountTitle => 'Account';

  @override
  String get accountDefaultName => 'User';

  @override
  String accountJoined(String date) {
    return 'Joined $date';
  }

  @override
  String get accountEditComingSoon => 'Profile editing is coming soon.';

  @override
  String get accountSecurity => 'Security';

  @override
  String get accountPasswordDesc => 'Change it regularly to stay secure';

  @override
  String get accountTwoFa => 'Two-factor authentication';

  @override
  String get accountDevices => 'Logged-in devices';

  @override
  String get accountCurrentDevice => 'Current device';

  @override
  String get devicesTitle => 'Logged-in devices';

  @override
  String get devicesIntro =>
      'These devices are signed in to your account. Log out any you don\'t recognize.';

  @override
  String get devicesCurrent => 'Current device';

  @override
  String get devicesUnknown => 'Unknown device';

  @override
  String devicesLastUsed(String when) {
    return 'Last used $when';
  }

  @override
  String get devicesEmpty => 'No devices are signed in';

  @override
  String get devicesLoadError => 'Couldn\'t load your devices';

  @override
  String get devicesLoadErrorHint => 'Try again in a moment.';

  @override
  String devicesLogoutLabel(String device) {
    return 'Log out of $device';
  }

  @override
  String get devicesLogoutFailed => 'Couldn\'t log out. Try again in a moment.';

  @override
  String get devicesLogout => 'Log out';

  @override
  String devicesLogoutTitle(String device) {
    return 'Log out of $device?';
  }

  @override
  String get devicesLogoutConfirm => 'It will need to sign in again.';

  @override
  String get devicesLogoutAll => 'Log out all devices';

  @override
  String get devicesLogoutAllTitle => 'Log out of all devices?';

  @override
  String get devicesLogoutAllConfirm =>
      'This device will be logged out too. You\'ll need to sign in again.';

  @override
  String get accountConnected => 'Connected accounts';

  @override
  String get accountNotConnected => 'Not connected';

  @override
  String get accountConnect => 'Connect';

  @override
  String get accountLinked => 'Connected';

  @override
  String get accountDisconnect => 'Disconnect';

  @override
  String get accountProvidersError => 'Couldn\'t load the connection status';

  @override
  String get accountLinkError => 'Couldn\'t connect the account.';

  @override
  String get accountUnlinkError => 'Couldn\'t disconnect the account.';

  @override
  String accountLinkedToast(String name) {
    return '$name account connected';
  }

  @override
  String get accountUnlinkedToast => 'Google account disconnected';

  @override
  String get accountSecuritiesDesc =>
      'Connect API keys for Toss, Namu, and more';

  @override
  String get accountBilling => 'Subscription & Billing';

  @override
  String accountNextBilling(String date) {
    return 'Next billing $date · ';
  }

  @override
  String get accountProActive => 'Pro active';

  @override
  String get accountProPromo => 'Securities investing is Pro-only · Start now';

  @override
  String get accountPerMonth => '/ mo';

  @override
  String get accountProStart => 'Start Pro';

  @override
  String get accountManage => 'Account Management';

  @override
  String get accountLogoutDesc => 'This device only';

  @override
  String get accountWithdraw => 'Stop using 그루 담다';

  @override
  String get accountWithdrawDesc => 'Cannot be undone';

  @override
  String accountAppVersion(String version) {
    return 'App version $version';
  }

  @override
  String get accountAppVersionLatest => 'Up to date';

  @override
  String accountAppVersionUpdate(String version) {
    return 'New version $version';
  }

  @override
  String get accountLogoutConfirm => 'Log out of this device?';

  @override
  String get accountWithdrawTitle => 'Stop using 그루 담다';

  @override
  String get withdrawIntro =>
      'Stopping 그루 담다 signs you out immediately and cannot be undone.';

  @override
  String withdrawImpactCalendarsOwned(int count) {
    return '$count shared calendar(s) you created will be deleted — members lose access too';
  }

  @override
  String withdrawImpactCalendarMemberships(int count) {
    return 'You will be removed from $count calendar(s) you joined';
  }

  @override
  String withdrawImpactDutchPaysOwned(int count) {
    return '$count settlement(s) you created will be deleted';
  }

  @override
  String withdrawImpactDutchPayParticipations(int count) {
    return 'You will appear as \"a former member\" in $count settlement(s) you joined';
  }

  @override
  String get withdrawIrreversibleTitle => 'This cannot be undone';

  @override
  String get withdrawIrreversibleRejoin =>
      'You cannot sign up again with the same ID or email address.';

  @override
  String get withdrawIrreversibleData =>
      'You will not be able to see your records again.';

  @override
  String get withdrawDataRetention =>
      'Your records are kept and then destroyed under our privacy policy. Export anything you need before you stop.';

  @override
  String get withdrawReasonLabel => 'Why are you leaving?';

  @override
  String get withdrawReasonPlaceholder =>
      'Tell us and we will do better next time';

  @override
  String get withdrawNext => 'Continue';

  @override
  String get withdrawConfirm => 'Stop using 그루 담다';

  @override
  String get withdrawReauthIntro => 'Just once more, let us confirm it is you.';

  @override
  String get withdrawUseEmailCode => 'No password? Get a code by email';

  @override
  String get withdrawUsePassword => 'Use my password instead';

  @override
  String get withdrawCodeLabel => 'Verification code';

  @override
  String get withdrawCodePlaceholder => '6 digits';

  @override
  String get withdrawSendCode => 'Send code';

  @override
  String get withdrawResendCode => 'Send again';

  @override
  String get withdrawCodeSent => 'We sent a code to your email.';

  @override
  String get withdrawFailed =>
      'Could not stop your 그루 담다 account. Please try again shortly.';

  @override
  String get withdrawBlockedSubscription =>
      'You still have an active subscription, so you cannot stop using 그루 담다 yet.';

  @override
  String withdrawBlockedSubscriptionUntil(String date) {
    return 'Your subscription runs until $date, so you cannot stop using 그루 담다 yet.';
  }

  @override
  String get withdrawBlockedOther =>
      'Your account cannot be stopped right now.';

  @override
  String get withdrawBlockedHint =>
      'Cancel your subscription first — you can stop using 그루 담다 once the paid period ends.';

  @override
  String get withdrawnTitle => 'Your 그루 담다 account is closed';

  @override
  String get withdrawnBody =>
      'Thank you for using 그루 담다. Remaining data is kept and then destroyed under our privacy policy.';

  @override
  String get withdrawnToLogin => 'Go to sign in';

  @override
  String get withdrawCodeDescription =>
      'Enter it within 10 minutes · after 5 wrong tries, request a new one.';

  @override
  String get withdrawCodeIncomplete => 'Enter the 6-digit verification code.';

  @override
  String get withdrawCodeWrong =>
      'The code is wrong or has expired. Check it or request a new one.';

  @override
  String withdrawResendCooldown(int seconds) {
    return 'Send again (${seconds}s)';
  }

  @override
  String get withdrawBusy => 'Closing your account';

  @override
  String get withdrawLoadFailedTitle => 'Couldn\'t load your account details';

  @override
  String get sheetLeaveTitle => 'Your changes will be lost';

  @override
  String get sheetLeaveDescription =>
      'If you leave, what you entered won\'t be saved.';

  @override
  String get sheetLeaveStay => 'Keep editing';

  @override
  String get sheetLeaveLeave => 'Leave';

  @override
  String get notiUnreadPrefix => '';

  @override
  String get notiUnreadSuffix => ' unread';

  @override
  String get notiSettings => 'Notification settings';

  @override
  String get notiSettingsLoadError => 'Failed to load settings';

  @override
  String get notiKindTitle => 'Notification types';

  @override
  String get notiKindSubtitle => 'Keep only the alerts you need.';

  @override
  String get notiPayment => 'Payment alerts';

  @override
  String get notiPaymentDesc => 'D-1 before due date, and on the payment day';

  @override
  String notiBudgetDesc(int threshold) {
    return 'Category budget reaches $threshold%·100%';
  }

  @override
  String get notiAutoRecord => 'Auto-record alerts';

  @override
  String get notiAutoRecordDesc =>
      'When a recurring transaction is auto-recorded';

  @override
  String get notiDutchPay => 'Dutch pay alerts';

  @override
  String get notiDutchPayDesc => 'Payment requests / settlement complete';

  @override
  String get notiCalendarDesc => '15 minutes before a calendar event';

  @override
  String get notiWeeklyReport => 'Weekly report';

  @override
  String get notiWeeklyReportDesc => 'Every Monday at 9 AM';

  @override
  String get notiMonthlyReport => 'Monthly report';

  @override
  String get notiMonthlyReportDesc => 'On the 1st of each month at 9 AM';

  @override
  String get notiPush => 'Push notifications';

  @override
  String get notiPushOn => 'All notifications are enabled';

  @override
  String get notiPushOff => 'Notifications are off';

  @override
  String get notiThresholdTitle => 'Budget alert threshold';

  @override
  String get notiThresholdCurrent => 'Current ';

  @override
  String get notiThresholdDesc1 => 'When usage exceeds this, a ';

  @override
  String get notiThresholdWarning => 'Warning';

  @override
  String get notiThresholdDesc2 =>
      ' state is shown and you get an alert. At 100%, an ';

  @override
  String get notiThresholdOver => 'Over';

  @override
  String get notiThresholdDesc3 => ' alert is sent separately.';

  @override
  String get notiQuietTitle => 'Do not disturb hours';

  @override
  String get notiQuietSubtitle =>
      'During these hours, alerts show without sound or vibration.';

  @override
  String get notiQuietToggle => 'Use do not disturb';

  @override
  String get notiQuietToggleDesc => 'Auto-mute during a set time range';

  @override
  String get notiQuietStart => 'Start';

  @override
  String get notiQuietEnd => 'End';

  @override
  String get notiSoundTitle => 'Sound & vibration';

  @override
  String get notiSound => 'Notification sound';

  @override
  String get notiSoundDesc => 'In-app notification sound';

  @override
  String get notiSoundChime => 'Chime';

  @override
  String get notiSoundDefault => 'Default';

  @override
  String get notiSoundNone => 'Silent';

  @override
  String get notiVibration => 'Vibration';

  @override
  String get notiVibrationDesc => 'Vibrate with notifications on mobile';

  @override
  String get notiEmailTitle => 'Email notifications';

  @override
  String get notiEmailSubtitle =>
      'Get summaries by email even if you rarely open the app.';

  @override
  String get notiEmailToggle => 'Receive emails';

  @override
  String get notiEmailNone => 'No email registered';

  @override
  String get notiEmailFreq => 'Frequency';

  @override
  String get notiEmailDaily => 'Daily';

  @override
  String get notiEmailWeekly => 'Weekly';

  @override
  String get notiEmailMonthly => 'Monthly';

  @override
  String get presetManageTitle => 'Manage presets';

  @override
  String get presetDetailTitle => 'Preset detail';

  @override
  String get presetTypeLabel => 'Type';

  @override
  String get presetDeleteConfirm =>
      'Transactions already recorded stay as they are. A deleted preset cannot be restored.';

  @override
  String get presetDeleteFailed => 'Could not delete the preset';

  @override
  String get presetSortUsed => 'Frequent';

  @override
  String get presetSortRecent => 'Recent';

  @override
  String get presetSortName => 'By name';

  @override
  String presetListTitle(int count) {
    return '$count presets';
  }

  @override
  String presetUses(int count) {
    return '$count uses';
  }

  @override
  String get presetSortLabel => 'Sort';

  @override
  String get presetLoadFailed => 'Could not load presets';

  @override
  String get presetCategoryLoadFailed => 'Could not load categories';

  @override
  String presetDeleteConfirmTitle(String name) {
    return 'Delete the \"$name\" preset?';
  }

  @override
  String get presetNoteFixed => 'Fixed amount';

  @override
  String presetNoteUses(int count) {
    return 'Used $count times';
  }

  @override
  String get presetNoteUnused => 'Not used yet';

  @override
  String presetNoteLast(int month, int day) {
    return 'Last used $month/$day';
  }

  @override
  String get presetFixedOn => 'On';

  @override
  String get presetFixedOff => 'Off';

  @override
  String get presetNameRequired => 'Enter a name.';

  @override
  String get presetNameTooLong =>
      'Keep the preset name to 12 characters or fewer.';

  @override
  String get presetCategoryRequired => 'Choose a category.';

  @override
  String get presetFromRequired => 'Choose the sending account.';

  @override
  String get presetToRequired => 'Choose the receiving account.';

  @override
  String get presetSaveFailed =>
      'Could not save. Please try again in a moment.';

  @override
  String get presetAmountLabel => 'Amount';

  @override
  String get presetFeeLabel => 'Fee';

  @override
  String get presetAmountBlank => 'Left blank';

  @override
  String get presetAmountHint =>
      'If left blank, you enter the amount when you load it.';

  @override
  String get presetMemoPlaceholder => 'Optional';

  @override
  String get presetInterestTooLarge =>
      'Interest can\'t be more than the amount.';

  @override
  String presetSelectOf(String field) {
    return 'Select $field';
  }

  @override
  String presetNoneOf(String field) {
    return 'No $field';
  }

  @override
  String get presetNoneValue => 'None';

  @override
  String get presetMemoNone => 'No memo';

  @override
  String get presetNoAccount => 'No account or card';

  @override
  String get presetNoPayment => 'No payment method';

  @override
  String get presetNoCategoryOfKind => 'There are no categories of this type.';

  @override
  String get presetFromAccount => 'Sending account';

  @override
  String get presetToAccount => 'Receiving account';

  @override
  String get presetShowAll => 'Show all';

  @override
  String get presetPickTitle => 'Choose a preset';

  @override
  String get presetSearch => 'Search presets';

  @override
  String get presetNoResult => 'No presets found.';

  @override
  String get presetAdd => 'Add preset';

  @override
  String get presetAmountEmpty => 'No amount';

  @override
  String get presetNoCategory => 'No category';

  @override
  String get presetEmptyTitle => 'No saved presets';

  @override
  String get presetEmptyDesc =>
      'Save frequent entries (lunch, transit, etc.) and fill the category, account, and details with one tap when adding an entry.';

  @override
  String get presetEditTitle => 'Edit preset';

  @override
  String get presetSubmitAdd => 'Add';

  @override
  String get presetName => 'Preset name';

  @override
  String get presetMerchant => 'Default details';

  @override
  String get presetMerchantPlaceholder => 'e.g. Office lunch box';

  @override
  String get presetAssetCard => 'Account / Card';

  @override
  String get recurringToggleFailed => 'Change failed';

  @override
  String get recurringDeleteTitle => 'Delete recurring transaction';

  @override
  String recurringDeleteConfirm(String name) {
    return 'Delete the \"$name\" recurring setting? Already-recorded transactions remain. A deleted recurring setting cannot be restored.';
  }

  @override
  String get recurringDeleteFailed => 'Delete failed';

  @override
  String get recurringLoadError => 'Failed to load recurring transactions';

  @override
  String get recurringAllList => 'All';

  @override
  String get recurringAdd => 'Add';

  @override
  String recurringFilterAll(int count) {
    return 'All $count';
  }

  @override
  String recurringFilterExpense(int count) {
    return 'Expense $count';
  }

  @override
  String recurringFilterIncome(int count) {
    return 'Income $count';
  }

  @override
  String recurringFilterTransfer(int count) {
    return 'Transfer $count';
  }

  @override
  String recurringFilterPaused(int count) {
    return 'Paused $count';
  }

  @override
  String get recurringStatActive => 'Active';

  @override
  String recurringCount(int count) {
    return '$count';
  }

  @override
  String get recurringPaused => 'Paused';

  @override
  String get recurringPauseAction => 'Pause';

  @override
  String get recurringMonthlyExpense => 'Monthly fixed expense';

  @override
  String get recurringMonthlyIncome => 'Monthly fixed income';

  @override
  String get recurringUpcoming => 'Next 7 days';

  @override
  String recurringUpcomingCount(int count) {
    return '$count upcoming';
  }

  @override
  String get recurringToday => 'Today';

  @override
  String get recurringNoAccount => 'No account';

  @override
  String recurringOccurrences(int executed, int max) {
    return '$executed/$max';
  }

  @override
  String get recurringNext => 'Next';

  @override
  String get recurringStart => 'Start';

  @override
  String get recurringEmpty => 'No matching recurring transactions';

  @override
  String get recurringIndefinite => 'Indefinite';

  @override
  String get recurringNotifyShort => 'Alert';

  @override
  String get recurringAddTitle => 'Add recurring transaction';

  @override
  String get recurringEditTitle => 'Edit recurring transaction';

  @override
  String get recurringSaveSubmit => 'Save recurring';

  @override
  String get recurringUpdated => 'Recurring setting updated';

  @override
  String get recurringSaved => 'Recurring setting saved';

  @override
  String get recurringSaveFailed => 'Save failed';

  @override
  String get recurringIntro =>
      'Automatically repeat this transaction on a set cycle. Great for subscriptions, rent, regular donations, etc.';

  @override
  String get recurringFrequencyLabel => 'Frequency';

  @override
  String get recurringDayOfWeekLabel => 'Day of week';

  @override
  String get recurringDayOfMonthLabel => 'Day of month';

  @override
  String get recurringDayNote =>
      'Months without this day are handled on the last day';

  @override
  String get recurringEndLabel => 'End';

  @override
  String get recurringExecutionTime => 'Execution time';

  @override
  String get recurringIndefiniteDesc => 'Repeat until stopped';

  @override
  String get recurringByCount => 'By count';

  @override
  String get recurringTotal => 'Total';

  @override
  String get recurringTimesUnit => 'times';

  @override
  String get recurringByDate => 'By end date';

  @override
  String get recurringOptions => 'Options';

  @override
  String get recurringAutoLog => 'Auto-record';

  @override
  String get recurringAutoLogDesc =>
      'Automatically add the transaction on the date';

  @override
  String get recurringNotifyDayBefore => 'Day-before alert';

  @override
  String get recurringNotifyDesc =>
      'Send an alert the day before the payment/transfer';

  @override
  String get recurringNextDates => 'Next dates';

  @override
  String get recurringSourceSub =>
      'For subscriptions·rent and other regular payments';

  @override
  String recurringStartFrom(String date) {
    return 'Starts $date';
  }

  @override
  String get recurringMerchant => 'Merchant';

  @override
  String get recurringMerchantPlaceholder => 'e.g. Netflix';

  @override
  String get recurringAssetCard => 'Account / Card';

  @override
  String get recurringAssetLoadError => 'Failed to load assets';

  @override
  String get recurringSelectNone => 'None';

  @override
  String get recurringStartDateLabel => 'Start date';

  @override
  String recurringParentCategory(String name) {
    return '$name (parent)';
  }

  @override
  String get savingGoalLoadError => 'Failed to load saving goals';

  @override
  String get savingGoalFailTitle => 'Couldn\'t load the saving goals';

  @override
  String get savingGoalOverallProgress => 'Overall progress';

  @override
  String savingGoalListCount(int n) {
    return 'Goals · $n';
  }

  @override
  String get savingGoalAddAction => 'Add goal';

  @override
  String get savingGoalManagePrompt => 'Add saving goals in Settings.';

  @override
  String get savingGoalManageLink => 'Manage';

  @override
  String get savingGoalNoDeadline => 'No deadline';

  @override
  String get savingGoalCurrentLabel => 'Amount saved';

  @override
  String get savingGoalIconLabel => 'Icon';

  @override
  String get savingGoalEmpty => 'No saving goals yet. Start with ‘Add goal’.';

  @override
  String get savingGoalActionFailed => 'Failed';

  @override
  String get savingGoalAchieved => 'Achieved';

  @override
  String get savingGoalAdd => 'Add saving goal';

  @override
  String get savingGoalEdit => 'Edit saving goal';

  @override
  String get savingGoalSubmitAdd => 'Add';

  @override
  String savingGoalDeleteTitle(String title) {
    return 'Delete the \"$title\" goal?';
  }

  @override
  String get savingGoalDeleteConfirm =>
      'A deleted saving goal can\'t be restored.';

  @override
  String get savingGoalDeleteFailed => 'Couldn\'t delete the saving goal.';

  @override
  String get savingGoalNameLabel => 'Goal name';

  @override
  String get savingGoalNameHint => 'e.g. Trip to Europe';

  @override
  String get savingGoalNameDuplicate => 'A goal with this name already exists.';

  @override
  String get savingGoalAmountLabel => 'Target amount';

  @override
  String get savingGoalDeadlineLabel => 'Target date';

  @override
  String get savingGoalDeadlineHint => 'None';

  @override
  String get savingGoalColorLabel => 'Color';

  @override
  String get savingGoalErrName => 'Enter a goal name.';

  @override
  String savingGoalErrNameTooLong(int max) {
    return 'Goal name can be up to $max characters.';
  }

  @override
  String get savingGoalErrAmount => 'Enter the target amount.';

  @override
  String get savingGoalErrAmountTooLarge =>
      'The target amount can be up to 10 billion won.';

  @override
  String get savingGoalErrCurrentExceeds =>
      'The amount saved can\'t be more than the target amount.';

  @override
  String get savingGoalDeadlineClear => 'Clear target date';

  @override
  String get searchAdvancedFilter => 'Advanced filter';

  @override
  String get searchHint => 'Search transactions...';

  @override
  String get searchStartHint => 'Start';

  @override
  String get searchEndHint => 'End';

  @override
  String get searchFailed => 'Search failed';

  @override
  String get searchEmptyHint => 'Search by keyword, merchant, or note';

  @override
  String get searchNoResults => 'No results';

  @override
  String get statsTabTrend => 'Trend';

  @override
  String get statsTabCompare => 'Compare';

  @override
  String get statsThisQuarter => 'This quarter';

  @override
  String get statsThisYear => 'This year';

  @override
  String get statsCustomPeriod => 'Selected period';

  @override
  String get statsLastMonth => 'Last month';

  @override
  String get statsLastQuarter => 'Last quarter';

  @override
  String get statsLastYear => 'Last year';

  @override
  String get statsPrevPeriod => 'Previous period';

  @override
  String statsMomMonth(String prev) {
    return 'vs. $prev';
  }

  @override
  String get statsMomPrevMonth => 'Last month';

  @override
  String get statsMomPrevQuarter => 'Last quarter';

  @override
  String get statsMomPrevYear => 'Last year';

  @override
  String get statsDailyAvg => 'Daily average';

  @override
  String get statsMonthlyAvg => 'Monthly average';

  @override
  String get statsPeriodPickerTitle => 'Select period';

  @override
  String get statsNoData => 'No data';

  @override
  String get statsNoDataShort => 'No data';

  @override
  String get statsUnassigned => 'Unassigned';

  @override
  String statsCategoryDetail(String name) {
    return '$name detail';
  }

  @override
  String statsPeriodSpending(String period) {
    return '$period spending';
  }

  @override
  String get statsSpendingByCategory => 'Spending by category';

  @override
  String get statsNoCategoryData => 'No category data';

  @override
  String get statsTopMerchantsTitle => 'Top 5 merchants';

  @override
  String get statsNoMerchantData => 'No merchant data';

  @override
  String get statsNoName => '(No name)';

  @override
  String get statsTimeMorning => 'Morning';

  @override
  String get statsTimeLunch => 'Lunch';

  @override
  String get statsTimeAfternoon => 'Afternoon';

  @override
  String get statsTimeEvening => 'Evening';

  @override
  String get statsTimeLateNight => 'Late night';

  @override
  String get statsTimeDawn => 'Dawn';

  @override
  String get statsPatternTitle => 'Spending pattern by day & time';

  @override
  String get statsPatternDesc =>
      'Darker cells mean more spending in that time slot (unit: KRW)';

  @override
  String statsTooFewTx(String period) {
    return 'Too few transactions in $period';
  }

  @override
  String get statsLegendLow => 'Low';

  @override
  String get statsLegendHigh => 'High';

  @override
  String get statsTotalPrefix => 'Total';

  @override
  String statsDaysTotal(int days) {
    return '$days-day total';
  }

  @override
  String statsMomCalculating(String prev) {
    return 'Calculating vs. $prev…';
  }

  @override
  String statsMomUnavailable(String prev) {
    return 'No comparison with $prev';
  }

  @override
  String get statsTopCategory => 'Top spending category';

  @override
  String get statsTopMerchant => 'Top merchant';

  @override
  String get statsIncomeExpenseTrend => 'Income & expense trend';

  @override
  String get statsNoTrendData => 'No trend data';

  @override
  String get statsAvgIncome => 'Avg income';

  @override
  String get statsAvgExpense => 'Avg expense';

  @override
  String get statsNetSavings => 'Net savings';

  @override
  String get statsAvgSavings => 'Avg savings';

  @override
  String get statsSavingsRate => 'Savings rate';

  @override
  String statsSavingsInsight(int pct) {
    return 'You\'re saving $pct% of your average income';
  }

  @override
  String get statsDailyNetSavings => 'Daily net savings';

  @override
  String get statsMonthlyNetSavings => 'Monthly net savings';

  @override
  String get statsCatTrendTitle => 'Top categories over time';

  @override
  String get statsCatTrendTop3 => 'Top 3 spending';

  @override
  String get statsIncomeMinusExpense => 'Income − Expense';

  @override
  String statsNoDataFor(String period) {
    return 'No data for $period';
  }

  @override
  String statsCategoryByMom(String mom) {
    return 'By category, $mom';
  }

  @override
  String get statsCategoryDelta => 'Change by category';

  @override
  String get statsSortByChange => 'Biggest changes';

  @override
  String get statsNoCompareData => 'No data to compare';

  @override
  String get statsWeekdayTitle => 'Spending by weekday';

  @override
  String get statsThisMonthShort => 'This month';

  @override
  String get statsLastMonthShort => 'Last month';

  @override
  String statsWeekdayInsightDown(String prev, String day, String amount) {
    return '$day spending dropped by $amount vs $prev.';
  }

  @override
  String statsWeekdayInsightUp(String prev, String day, String amount) {
    return '$day spending rose by $amount vs $prev.';
  }

  @override
  String statsWeekdayInsightSame(String prev) {
    return 'Similar to $prev.';
  }

  @override
  String statsVsLastPrefix(String prev) {
    return 'You spent';
  }

  @override
  String get statsVsLastDirLess => 'less';

  @override
  String get statsVsLastDirMore => 'more';

  @override
  String statsVsLastSuffix(String prev) {
    return 'than $prev';
  }

  @override
  String get statsCompareDailyAvg => 'Daily average';

  @override
  String get statsCompareTxCount => 'Transactions';

  @override
  String get statsComparePerTx => 'Per transaction';

  @override
  String statsCountValue(int count) {
    return '$count';
  }

  @override
  String get stocksChartTokenFailed => 'Failed to issue token';

  @override
  String get stocksChartHttpsError =>
      'Security error: chart WebView is not HTTPS';

  @override
  String get stocksChartInitFailed => 'Chart initialization failed';

  @override
  String get stocksChartLoadFailed => 'Couldn\'t load chart';

  @override
  String get stocksSearch => 'Search stocks';

  @override
  String get stocksSearchPlaceholder => 'Search stocks';

  @override
  String stocksSearchNoResults(String query) {
    return 'No results for \'$query\'';
  }

  @override
  String get stocksTabHoldings => 'Holdings';

  @override
  String get stocksTabWatch => 'Watchlist';

  @override
  String get stocksTabDiscover => 'Discover';

  @override
  String get stocksNoHoldings => 'No holdings yet';

  @override
  String stocksSharesHeld(String qty) {
    return 'Holding $qty shares';
  }

  @override
  String get stocksRange1d => '1D';

  @override
  String get stocksRange1w => '1W';

  @override
  String get stocksRange1m => '1M';

  @override
  String get stocksRange3m => '3M';

  @override
  String get stocksRange1y => '1Y';

  @override
  String stocksUnitCount(int count) {
    return '$count';
  }

  @override
  String stocksSharesUnit(String qty) {
    return '$qty shares';
  }

  @override
  String get stocksTradingSuspended => 'Suspended';

  @override
  String get stocksTradingNormal => 'Normal';

  @override
  String get stocksWarningLiquidationTrading => 'Liquidation trading';

  @override
  String get stocksWarningOverheated => 'Overheated';

  @override
  String get stocksWarningShortTermOverheat => 'Short-term overheat';

  @override
  String get stocksWarningExcessiveRise => 'Excessive rise';

  @override
  String get stocksWarningInvestmentWarning => 'Investment warning';

  @override
  String get stocksWarningInvestmentRisk => 'Investment risk';

  @override
  String get stocksWarningInvestmentCaution => 'Investment caution';

  @override
  String get stocksWarningVi => 'Volatility interruption';

  @override
  String get stocksWarningViStatic => 'Static VI';

  @override
  String get stocksWarningViDynamic => 'Dynamic VI';

  @override
  String get stocksWarningStockWarrants => 'Stock warrants';

  @override
  String get stocksWarningAdministrative => 'Administrative issue';

  @override
  String get stocksWarningAdjustmentOfShares => 'Share adjustment';

  @override
  String get stocksNoWatchlist => 'No watchlist stocks yet';

  @override
  String get stocksDetailTitle => 'Stock details';

  @override
  String get stocksMarketHoliday => 'Holiday';

  @override
  String stocksMarketTrading(String time) {
    return 'Open · $time';
  }

  @override
  String stocksMarketOpensAt(String time) {
    return 'Opens $time';
  }

  @override
  String get stocksMarketClosed => 'Closed';

  @override
  String get stocksMarketKr => 'Domestic';

  @override
  String get stocksMarketUs => 'US';

  @override
  String get stocksMyEval => 'My portfolio value';

  @override
  String get stocksPurchaseAmount => 'Cost basis';

  @override
  String get stocksHoldingsLabel => 'Holdings';

  @override
  String get stocksExchangeRate => 'Exchange rate (USD)';

  @override
  String get stocksSell => 'Sell';

  @override
  String get stocksBuy => 'Buy';

  @override
  String get stocksFeeUs =>
      'US stock trading fee 0.1% · FX fee applies separately';

  @override
  String get stocksFeeKr =>
      'Domestic stock trading free (until Jun 2026) · then KRX 0.015% / NXT 0.014%';

  @override
  String get stocksEvalAmount => 'Market value';

  @override
  String get stocksEvalPnl => 'Unrealized P&L';

  @override
  String get stocksQuantityHeld => 'Quantity held';

  @override
  String get stocksReturnRate => 'Return';

  @override
  String get stocksDayPnl => 'Daily P&L';

  @override
  String get stocksAvgPrice => 'Average price';

  @override
  String get stocksFeesTax => 'Fees & taxes';

  @override
  String get stocksSellable => 'Sellable';

  @override
  String get stocksMyHoldings => 'My holdings';

  @override
  String get stocksMarket => 'Market';

  @override
  String get stocksInstrumentType => 'Instrument type';

  @override
  String get stocksInstrumentStock => 'Stock';

  @override
  String get stocksCurrency => 'Currency';

  @override
  String get stocksMarketCap => 'Market cap';

  @override
  String get stocksUpperLimit => 'Upper limit';

  @override
  String get stocksLowerLimit => 'Lower limit';

  @override
  String get stocksListingDate => 'Listing date';

  @override
  String get stocksSharesOutstanding => 'Shares outstanding';

  @override
  String get stocksTradingStatus => 'Trading status';

  @override
  String get stocksBasicInfo => 'Basic info';

  @override
  String get stocksBidVolume => 'Bid volume';

  @override
  String get stocksAskVolume => 'Ask volume';

  @override
  String get stocksGainers => 'Top gainers';

  @override
  String get stocksLosers => 'Top losers';

  @override
  String get stocksVolume => 'Volume';

  @override
  String get stocksOrderbookLoading => 'Loading order book…';

  @override
  String get stocksOrderbookEmpty => 'No order book data';

  @override
  String get stocksTradesLoading => 'Loading trades…';

  @override
  String get stocksTradesEmpty => 'No trades';

  @override
  String get stocksOrderbook => 'Order book';

  @override
  String get stocksTrades => 'Trades';

  @override
  String get stocksTradeTime => 'Time';

  @override
  String get stocksTradePrice => 'Price';

  @override
  String get stocksTradeVolume => 'Volume';

  @override
  String get stocksDailyPrices => 'Daily prices';

  @override
  String get stocksDailyPricesLoading => 'Loading daily prices…';

  @override
  String get stocksDailyPricesEmpty => 'No daily prices';

  @override
  String get stocksDate => 'Date';

  @override
  String get stocksClosePrice => 'Close';

  @override
  String get stocksChangeRate => 'Change';

  @override
  String get stocksSearchHint =>
      'Search by name or symbol (KR + US·CN·JP·HK·VN)';

  @override
  String get stocksPriceUnavailable =>
      'Price unavailable via Toss (KR·US only)';

  @override
  String get stocksRankingLoading => 'Loading rankings';

  @override
  String get stocksRankingEmpty => 'No rankings yet';

  @override
  String get stocksWatchDefaultGroupName => 'Watchlist';

  @override
  String get stocksWatchGroupAdd => 'Add group';

  @override
  String get stocksWatchGroupRename => 'Rename group';

  @override
  String get stocksWatchGroupDelete => 'Delete group';

  @override
  String get stocksWatchGroupNamePlaceholder => 'Group name';

  @override
  String get stocksWatchGroupSaveFail => 'Couldn\'t save the watch group.';

  @override
  String get stocksWatchAddFail => 'Failed to add to watchlist';

  @override
  String get stocksMarketToggleKr => 'KR';

  @override
  String get stocksMarketToggleUs => 'US';

  @override
  String get todoAdd => 'Add todo';

  @override
  String get todoEditTitle => 'Edit todo';

  @override
  String get todoDeleteTitle => 'Delete todo';

  @override
  String todoDeleteConfirm(String title) {
    return 'Delete the \"$title\" to-do? This can\'t be undone.';
  }

  @override
  String get todoDetail => 'Details';

  @override
  String get todoCompletionRate => 'Completion rate';

  @override
  String get todoQuickAddPlaceholder => 'Type a todo and press Enter';

  @override
  String get todoTitlePlaceholder => 'Write a todo';

  @override
  String get todoTitleRequired => 'Title is required.';

  @override
  String get todoDueDate => 'Due date';

  @override
  String get todoUnset => 'Not set';

  @override
  String get todoTag => 'Tag';

  @override
  String get todoTagSelect => 'Select tag';

  @override
  String get todoTagNone => 'No tag';

  @override
  String get todoPriorityLabel => 'Priority';

  @override
  String get todoPriorityImportant => 'High';

  @override
  String get todoPriorityRelaxed => 'Low';

  @override
  String get todoContentLabel => 'Note';

  @override
  String get todoContentPlaceholder =>
      'e.g. # Heading / **bold** / - item / - [ ] check';

  @override
  String get todoEditMode => 'Edit';

  @override
  String get todoPreview => 'Preview';

  @override
  String get todoNoContent => 'None';

  @override
  String get todoEmptyToday => 'Nothing due today';

  @override
  String get todoEmptyWeek => 'A light week ahead';

  @override
  String get todoEmptyDone => 'Nothing completed yet';

  @override
  String get todoEmptyAll => 'No todos';

  @override
  String get todoEmptyDoneHint => 'Completed todos appear here.';

  @override
  String get todoEmptyAddHint => 'Add one quickly using the field above.';

  @override
  String get todoNewProject => 'New project';

  @override
  String get todoProjectNamePlaceholder => 'Project name';

  @override
  String get todoDescOptional => 'Description (optional)';

  @override
  String get todoAdding => 'Adding…';

  @override
  String get todoAddProject => 'Add project';

  @override
  String get todoRegisteredProjects => 'Projects';

  @override
  String get todoNoProjects => 'No projects';

  @override
  String get todoDeleteProjectTitle => 'Delete project';

  @override
  String todoDeleteProjectConfirm(String name) {
    return 'Delete project \"$name\"? Linked todos will be set to no project.';
  }

  @override
  String get todoNewTag => 'Add tag';

  @override
  String get todoTagNamePlaceholder => 'Tag name';

  @override
  String get todoRegisteredTags => 'Tags';

  @override
  String get todoNoTags => 'No tags';

  @override
  String get todoDeleteTagTitle => 'Delete tag';

  @override
  String todoDeleteTagConfirm(String name, int count) {
    return 'Deleting \"$name\" will leave $count todos using it untagged. A deleted tag cannot be restored.';
  }

  @override
  String get todoActionFailed => 'Failed';

  @override
  String get todoAddFailed => 'Add failed';

  @override
  String get todoDeleteFailed => 'Delete failed';

  @override
  String get todoUpdateFailed => 'Update failed';

  @override
  String get todoStatusChangeFailed => 'Status change failed';

  @override
  String get todoMoveFailed => 'Move failed';

  @override
  String get todoLoadError => 'Couldn\'t load your to-dos';

  @override
  String get todoProjectLoadError => 'Failed to load projects';

  @override
  String get todoTagLoadError => 'Couldn\'t load tags';

  @override
  String get subManageTitle => 'Manage subscription';

  @override
  String get subUsingPro => 'On 담다 Pro';

  @override
  String get subUsingFree => 'On the Free plan';

  @override
  String subNextBilling(String date, String amount) {
    return 'Next billing $date · $amount';
  }

  @override
  String subProUntil(String date) {
    return 'Access until $date';
  }

  @override
  String get subFreeLockedDesc =>
      'Securities link and real-time quotes are locked';

  @override
  String get subSpotlightTitle => 'Securities investing is Pro-only';

  @override
  String get subSpotlightDesc =>
      'Real-time quotes and order book, domestic and overseas ticker search, watchlists, and holding P&L — subscribe to Pro and the Securities tab opens right away.';

  @override
  String get subCycleMonthly => 'Monthly';

  @override
  String subCycleYearlyOff(int pct) {
    return 'Yearly $pct% off';
  }

  @override
  String get subUnitMonth => 'mo';

  @override
  String get subUnitYear => 'yr';

  @override
  String subYearlyPerMonth(String amount, int pct) {
    return '≈ $amount/mo · Save $pct%';
  }

  @override
  String get subMonthlyBilling => 'Billed monthly';

  @override
  String get subFeatureCompare => 'Feature comparison';

  @override
  String get subCurrentPlan => 'Current plan';

  @override
  String get subFreeCaption => 'Basic ledger features';

  @override
  String get subFeatureColumn => 'Feature';

  @override
  String get subFeatLedger => 'Ledger · asset management';

  @override
  String get subFeatBudget => 'Budget · savings goals · calendar';

  @override
  String get subFeatSecurities =>
      'Securities link · real-time quotes · real-time asset value';

  @override
  String get subStarted => 'Your 담다 Pro subscription is active';

  @override
  String get subFailed => 'Couldn\'t start the subscription';

  @override
  String get subCancelConfirmTitle => 'Cancel subscription';

  @override
  String subCancelConfirmMsg(String date) {
    return 'If you cancel, you will switch to the Free plan from $date and the Securities tab will lock. You can keep using Pro features until then.';
  }

  @override
  String get subCancel => 'Cancel subscription';

  @override
  String get subKeep => 'Keep';

  @override
  String get subCanceled => 'Subscription canceled';

  @override
  String get subCancelFailed => 'Couldn\'t cancel';

  @override
  String get subNextBillingDate => 'Next billing date';

  @override
  String get subProcessing => 'Processing…';

  @override
  String get subStartPro => 'Start Pro';

  @override
  String get subConnected => 'Connected';

  @override
  String subBrokerLastVerified(String date) {
    return 'Last verified · $date';
  }

  @override
  String get subBrokerCollecting => 'Auto-collecting holdings and prices';

  @override
  String get subConnecting => 'Connecting…';

  @override
  String get subConnect => 'Connect';

  @override
  String get subBrokerInvalidCred => 'Those credentials aren\'t valid';

  @override
  String get subDisconnectFailed => 'Couldn\'t disconnect';

  @override
  String get memoNew => 'Add memo';

  @override
  String get memoEditTitle => 'Edit memo';

  @override
  String get memoLoadError => 'Could not load memos';

  @override
  String memoSectionPinned(int count) {
    return 'Pinned · $count';
  }

  @override
  String memoSectionAll(int count) {
    return 'All memos · $count';
  }

  @override
  String get memoEmptyDesc =>
      'Tap the + button at the bottom right to write your first memo.';

  @override
  String get memoSearchEmptyDesc => 'Try a different search term.';

  @override
  String get memoUntitled => 'Untitled';

  @override
  String get memoDeleteTitle => 'Delete memo';

  @override
  String memoDeleteConfirm(String name) {
    return 'Delete the \"$name\" memo? A deleted memo cannot be restored.';
  }

  @override
  String get memoFieldTitle => 'Title';

  @override
  String get memoTitleRequired => 'Please enter a title.';

  @override
  String get memoFieldContent => 'Content';

  @override
  String get memoContentPlaceholder => 'Write your memo here';

  @override
  String get memoFieldTag => 'Tag';

  @override
  String get memoTagNone => 'No tag';

  @override
  String get memoTagEmptyHint => 'Create tags in Settings › Memo tags.';

  @override
  String get memoAllChip => 'All';

  @override
  String get memoLoadFailedDesc => 'Please try again in a moment.';

  @override
  String get memoTagFilter => 'Filter by tag';

  @override
  String get memoSaved => 'Saved.';

  @override
  String get memoSaveFailed => 'Could not save. Please try again in a moment.';

  @override
  String get memoDeleteFailed =>
      'Could not delete. Please try again in a moment.';

  @override
  String get memoPinFailed =>
      'Could not change the pin. Please try again in a moment.';

  @override
  String memoModifiedAt(String time) {
    return 'Edited $time';
  }

  @override
  String memoMoreOf(String name) {
    return 'More for $name';
  }

  @override
  String get memoSwipeUnpin => 'Unpin';

  @override
  String get mtagSaveFailed => 'Could not save. Please try again in a moment.';

  @override
  String get mtagDeleteFailed =>
      'Could not delete. Please try again in a moment.';

  @override
  String get ttagSaveFailed => 'Could not save. Please try again in a moment.';

  @override
  String get ttagDeleteFailed =>
      'Could not delete. Please try again in a moment.';

  @override
  String get memoNewTag => 'Add tag';

  @override
  String get memoTagNamePlaceholder => 'e.g. Ideas';

  @override
  String get memoDeleteTagTitle => 'Delete tag';

  @override
  String memoDeleteTagConfirm(String name, int count) {
    return 'Deleting \"$name\" will leave $count memos using it untagged. A deleted tag cannot be restored.';
  }

  @override
  String get memoTagLoadError => 'Could not load tags';

  @override
  String get mtagTitle => 'Memo tags';

  @override
  String get mtagDesc =>
      'Tags you attach to memos. They are used to filter the memo screen. If you delete a tag, its memos stay as \'No tag\'.';

  @override
  String get mtagEmpty => 'No tags yet';

  @override
  String get mtagEditTitle => 'Edit tag';

  @override
  String get mtagNameLabel => 'Name';

  @override
  String get mtagColorLabel => 'Color';

  @override
  String mtagUsage(int count) {
    return 'Used by $count memos';
  }

  @override
  String get memoPinToTop => 'Pin to top';

  @override
  String get memoFieldColor => 'Color';

  @override
  String get dateToday => 'Today';

  @override
  String get dateTomorrow => 'Tomorrow';

  @override
  String get dateYesterday => 'Yesterday';

  @override
  String dateInDays(int n) {
    return 'in $n days';
  }

  @override
  String dateDaysAgo(int n) {
    return '$n days ago';
  }

  @override
  String get dateJustNow => 'Just now';

  @override
  String dateMinutesAgo(int n) {
    return '$n min ago';
  }

  @override
  String dateHoursAgo(int n) {
    return '$n hr ago';
  }

  @override
  String get todoNoDue => 'No due date';

  @override
  String todoGroupLabel(String label, int count) {
    return '$label · $count';
  }

  @override
  String dayN(int d) {
    return 'Day $d';
  }

  @override
  String weekN(int n) {
    return 'W$n';
  }

  @override
  String get countUnit => '';

  @override
  String get dayUnit => 'day';

  @override
  String get constHeroTodayTarget => 'Today\'s constellation';

  @override
  String constHeroCollectedBang(String name) {
    return '$name collected!';
  }

  @override
  String constHeroStarlightCount(int lit, int goal) {
    return '$lit/$goal starlight';
  }

  @override
  String get constHeroCaptionDone =>
      'Etched in your collection · shines brighter as you complete more';

  @override
  String constHeroCaptionProgress(int count) {
    return '$count done today';
  }

  @override
  String constHeroCaptionMemo(int count) {
    return 'Memo starlight +$count';
  }

  @override
  String constHeroCaptionRemain(int count) {
    return '$count stars to go';
  }

  @override
  String get constHeroCaptionEmpty => 'Complete todos to light up the stars';

  @override
  String constHeroStreak(int count) {
    return '$count-day streak';
  }

  @override
  String constHeroGuardInfo(int count) {
    return 'Guard $count · High +3 · Medium +2 · Low +1';
  }

  @override
  String get constMySkyTitle => 'My Night Sky';

  @override
  String constMySkyTotal(int count) {
    return '$count collected';
  }

  @override
  String get constMySkySubtitle => 'Last 2 weeks · cloudy nights count too';

  @override
  String get constCollectionTitle => 'Constellation collection';

  @override
  String constCollectionProgress(int collected, int total) {
    return '$collected/$total collected';
  }

  @override
  String get constCollectionSubtitle =>
      'Gather starlight equal to the stars to collect';

  @override
  String get constCollectionTodayBadge => 'Today\'s goal';

  @override
  String constCollectionTimes(int count) {
    return '$count×';
  }

  @override
  String get constCollectionNotCollected => 'Not yet';

  @override
  String get constDetailNotMet => 'A constellation you haven\'t met yet';

  @override
  String get todoDetailTitle => 'Todo details';

  @override
  String get todoDetailStatus => 'Status';

  @override
  String get todoStatusPending => 'Pending';

  @override
  String get todoDetailCompletedAt => 'Completed at';

  @override
  String get todoDetailContent => 'Note';

  @override
  String get memoDetailNoContent => 'No content';

  @override
  String get calEventDetailTitle => 'Event details';

  @override
  String get calDetailNone => 'None';

  @override
  String get exportTab => 'Export';

  @override
  String get importTab => 'Import';

  @override
  String get importSourceTitle => 'Which app are you importing from?';

  @override
  String get importSourceDesc =>
      'Pick your previous app and we\'ll auto-map the columns';

  @override
  String get importSourceGroo => '그루 담다';

  @override
  String get importSourceGrooDesc => 'File exported from 그루 담다';

  @override
  String get importSourceEasybudget => 'EasyBudget · Money Manager';

  @override
  String get importSourceEasybudgetDesc => 'Excel backup';

  @override
  String get importSourceBanksalad => 'Banksalad';

  @override
  String get importSourceBanksaladDesc => 'Ledger export';

  @override
  String get importSourceToss => 'Toss';

  @override
  String get importSourceTossDesc => 'Transactions';

  @override
  String get importSourceCustom => 'Custom';

  @override
  String get importSourceCustomDesc => 'Map CSV/Excel yourself';

  @override
  String get importUploadTitle => 'Upload file';

  @override
  String get importUploadDesc =>
      'Upload a CSV or Excel (.xlsx, .xls) file. Up to 10MB.';

  @override
  String get importDropTitle => 'Choose a file';

  @override
  String get importDropHint => '.csv · .xlsx · .xls supported';

  @override
  String get importAnalyzing => 'Analyzing…';

  @override
  String get importNotice =>
      'Imported data is added to existing transactions without overwriting. Check duplicates and errors in the preview.';

  @override
  String get importFileTitle => 'File to import';

  @override
  String importRowsDetected(int total, int valid) {
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);
    final intl.NumberFormat validNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String validString = validNumberFormat.format(valid);

    return '$totalString rows · $validString valid';
  }

  @override
  String get importChange => 'Change';

  @override
  String get importMapTitle => 'Column mapping';

  @override
  String get importMapDesc =>
      'Connect file columns to ledger fields. Review auto-detected values and adjust.';

  @override
  String get importNotMapped => '— Don\'t import —';

  @override
  String get importFieldSubcategory => 'Subcategory';

  @override
  String get importFieldTime => 'Time';

  @override
  String get importFieldMerchant => 'Merchant';

  @override
  String get importFieldPaymentMethod => 'Payment method';

  @override
  String importBlockedTitle(String names) {
    return 'Cannot create subcategories under $names — it already has transactions';
  }

  @override
  String get importBlockedDesc =>
      'Rows using it will fail. Move its transactions into a subcategory or change the category in the file.';

  @override
  String get categoryMoveTxAction => 'Move';

  @override
  String get categoryMoveTxTitle => 'Move transactions';

  @override
  String get categoryMoveTxEntry => 'Move transactions';

  @override
  String categoryMoveTxDesc(String name) {
    return 'Moves all transactions, recurring transactions and split transactions from $name.';
  }

  @override
  String get categoryMoveTxModeNew => 'Create subcategory';

  @override
  String get categoryMoveTxModeExisting => 'Move to existing';

  @override
  String get categoryMoveTxMode => 'How to move';

  @override
  String get categoryMoveTxChildName => 'New subcategory name';

  @override
  String get categoryMoveTxChildPlaceholder => 'e.g. Lectures';

  @override
  String categoryMoveTxNewHint(String name) {
    return 'Creates it under $name and moves all transactions there, so you can add more subcategories.';
  }

  @override
  String get categoryMoveTxTarget => 'Target category';

  @override
  String get categoryMoveTxTargetPlaceholder => 'Choose a category';

  @override
  String get categoryMoveTxHint =>
      'Only bottom-level categories of the same type can be chosen.';

  @override
  String get categoryMoveTxNoTarget =>
      'No category to move to. Please create one first.';

  @override
  String get categoryMoveTxErrChildName =>
      'Please enter a name for the new subcategory.';

  @override
  String get categoryMoveTxErrTarget => 'Please choose a category to move to.';

  @override
  String categoryMoveTxDone(int count) {
    return 'Moved $count items';
  }

  @override
  String get importFieldDate => 'Date';

  @override
  String get importFieldType => 'Income/Expense';

  @override
  String get importFieldAmount => 'Amount';

  @override
  String get importFieldCategory => 'Category';

  @override
  String get importFieldAsset => 'Asset/Method';

  @override
  String get importFieldMemo => 'Memo';

  @override
  String importPreviewDesc(int dup) {
    final intl.NumberFormat dupNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String dupString = dupNumberFormat.format(dup);

    return '$dupString possible duplicates';
  }

  @override
  String get importIncome => 'Income';

  @override
  String get importExpense => 'Expense';

  @override
  String get importDupBadge => 'Dup?';

  @override
  String get importOptionsTitle => 'Import options';

  @override
  String get importOptDupSkip => 'Skip duplicate transactions';

  @override
  String importOptDupSkipDesc(int dup) {
    final intl.NumberFormat dupNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String dupString = dupNumberFormat.format(dup);

    return 'Excludes $dupString rows with the same date, amount, and content.';
  }

  @override
  String get importOptAutoCat => 'Auto-create new categories';

  @override
  String get importOptAutoCatDesc =>
      'Missing categories are created automatically.';

  @override
  String get importPrev => 'Back';

  @override
  String importDoImport(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Import $countString';
  }

  @override
  String get importDoneTitle => 'Import complete';

  @override
  String importDoneCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Imported $countString transactions';
  }

  @override
  String importDoneDetail(int skipped, int failed) {
    final intl.NumberFormat skippedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String skippedString = skippedNumberFormat.format(skipped);
    final intl.NumberFormat failedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String failedString = failedNumberFormat.format(failed);

    return '$skippedString skipped · $failedString not imported.';
  }

  @override
  String get importAnother => 'Import another file';

  @override
  String get importStepUpload => 'Choose file';

  @override
  String get importStepMapping => 'Map columns';

  @override
  String get importStepDone => 'Done';

  @override
  String get exportTabsLabel => 'Export and import data';

  @override
  String get exportSelectAll => 'All';

  @override
  String get exportCountsFailed => 'Couldn\'t load the counts.';

  @override
  String get exportRangePlaceholder => 'Select a range';

  @override
  String get exportStalled => 'The download stopped.';

  @override
  String get exportFailed => 'Couldn\'t export.';

  @override
  String get exportPreviewTabsLabel => 'Preview data type';

  @override
  String importStepMeta(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get importBusy => 'Importing';

  @override
  String get withdrawPasswordPlaceholder => 'Enter your current password';

  @override
  String get withdrawLocked =>
      'You got it wrong 5 times. Please request a new code.';

  @override
  String get importStepUploadDesc => 'Choose the app and the file to import.';

  @override
  String get importStepMappingDesc =>
      'Check the columns and review the transactions before importing.';

  @override
  String get withdrawCodeHint =>
      'If you do not see it, check your spam folder.';

  @override
  String get withdrawPasswordWrong =>
      'The password is wrong. Please check it again.';

  @override
  String get withdrawLoadFailedDescription => 'Please try again in a moment.';

  @override
  String exportPreviewFooter(int rows, int types, int total) {
    final intl.NumberFormat rowsNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String rowsString = rowsNumberFormat.format(rows);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Top $rowsString rows · $types selected types, about $totalString in total';
  }

  @override
  String get exportPreviewEmptyTitle => 'Nothing to preview';

  @override
  String importCreatedCatTitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString categories created';
  }

  @override
  String importNewCatMore(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '+$countString more';
  }

  @override
  String importFailuresTitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString failed rows';
  }

  @override
  String importFailureLine(int line) {
    return 'Line $line';
  }

  @override
  String importFailuresCapped(int total, int shown) {
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);
    final intl.NumberFormat shownNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String shownString = shownNumberFormat.format(shown);

    return 'Showing the first $shownString of $totalString failures.';
  }

  @override
  String get importFailReasonDate => 'Couldn\'t read the date';

  @override
  String get importFailReasonAmount => 'Couldn\'t read the amount';

  @override
  String get importFailReasonType => 'Couldn\'t tell income from expense';

  @override
  String get importFailReasonParentHasTx =>
      'This category has its own transactions so no subcategory can be created';

  @override
  String get importFailReasonResolve => 'Couldn\'t match the category or asset';

  @override
  String get importFailReasonSave => 'Something went wrong while saving';

  @override
  String get importFailReasonUnknown => 'Failed for an unknown reason';

  @override
  String get importFileTooLarge => 'Files up to 10MB can be uploaded.';

  @override
  String get importFileInvalid => 'Only CSV or Excel files can be uploaded.';

  @override
  String get importBadgeError => 'Error';

  @override
  String get importBadgeDup => 'Duplicate';

  @override
  String get importGoExpense => 'Go to ledger';

  @override
  String get calDetailDday => 'D-DAY';

  @override
  String calDetailDdayLeft(int n) {
    return 'D-$n';
  }

  @override
  String calDetailDdayPast(int n) {
    return '${n}d ago';
  }

  @override
  String calDetailDurationH(int h) {
    return '${h}h';
  }

  @override
  String calDetailDurationHM(int h, int m) {
    return '${h}h ${m}m';
  }

  @override
  String calDetailDurationM(int m) {
    return '${m}m';
  }

  @override
  String get categoryReorderEdit => 'Reorder';

  @override
  String get categoryReorderHint =>
      'Drag the handle to reorder. Parents move among parents; subcategories move within their parent.';

  @override
  String get txmSpendSummary => 'Spending summary';

  @override
  String get txmInsightLessPre => 'Spending ';

  @override
  String txmInsightLessHl(String amount) {
    return '$amount less';
  }

  @override
  String get txmInsightLessPost => ' than last month';

  @override
  String get txmInsightMorePre => 'Spending ';

  @override
  String txmInsightMoreHl(String amount) {
    return '$amount more';
  }

  @override
  String get txmInsightMorePost => ' than last month';

  @override
  String get txmInsightSame => 'Spending about the same as last month';

  @override
  String get txmInsightNone => 'No transactions this month';

  @override
  String get txmInsightTopCatPre => 'Spent the most on ';

  @override
  String get txmInsightTopCatPost => ' this month';

  @override
  String txmPrevMonthBtn(String month) {
    return 'View $month history';
  }

  @override
  String txmEmptyMonth(String month) {
    return 'No transactions in $month';
  }

  @override
  String get txmEmptyMonthDesc =>
      'Browse another month or add your first transaction.';

  @override
  String get txmToday => 'Today';

  @override
  String get txmYesterday => 'Yesterday';

  @override
  String expChipMin(String amount) {
    return 'Min $amount';
  }

  @override
  String expChipMax(String amount) {
    return 'Max $amount';
  }

  @override
  String tdmTodayLeft(int count) {
    return '$count to-dos today';
  }

  @override
  String get tdmTodayDone => 'All done for today!';

  @override
  String get tdmNightSkyBtn => 'Night sky';

  @override
  String tdmStarlightHint(int lit, int goal, int left, String name) {
    return 'Starlight $lit/$goal · $left more to collect $name';
  }

  @override
  String tdmCollectedHint(String name, int streak) {
    return '$name collected · $streak-day streak';
  }

  @override
  String tdmDoneRatio(int done, int total) {
    return '$done/$total done';
  }

  @override
  String get tdmFilterTag => 'Tags';

  @override
  String get tdmHideDone => 'Hide completed';

  @override
  String tdmEmptyMonth(String month) {
    return 'No to-dos in $month';
  }

  @override
  String get tdmEmptyMonthDesc => 'Add one with the + button below.';

  @override
  String get tdmEmptyFilter => 'No to-dos match the filters';

  @override
  String get tdmEmptyFilterDesc => 'Change or clear the conditions.';

  @override
  String tdmStarToastGain(int gain, int left) {
    return 'Starlight +$gain · $left to collect';
  }

  @override
  String tdmStarToastCollected(int gain) {
    return 'Starlight +$gain · today\'s constellation collected!';
  }

  @override
  String constHeroLabel(String name, int lit, int goal) {
    return 'Today\'s constellation $name $lit/$goal starlight';
  }

  @override
  String get constFailToday => 'Couldn\'t load the night sky';

  @override
  String get constFailSky => 'Couldn\'t load your night sky';

  @override
  String get constFailCollection =>
      'Couldn\'t load the constellation collection';

  @override
  String get constLoadFailedDesc => 'Please try again in a moment.';

  @override
  String get frpLoadFailed => 'Couldn\'t load the observation report';

  @override
  String frpRowName(String name) {
    return 'Observation report, today\'s constellation $name';
  }

  @override
  String constMySkyCellToday(String date) {
    return '$date, today';
  }

  @override
  String constMySkyCellCollected(String date, String name) {
    return '$date, collected $name';
  }

  @override
  String constMySkyCellCloudy(String date) {
    return '$date, cloudy night';
  }

  @override
  String constMySkyCellRest(String date) {
    return '$date, rest night';
  }

  @override
  String get constCollectionBadgeNew => 'NEW';

  @override
  String constCollectionViewOwnedNamed(String name) {
    return 'View $name';
  }

  @override
  String constCollectionViewLockedNamed(String name) {
    return 'Preview $name';
  }

  @override
  String constDetailSkyName(String name) {
    return 'Constellation $name drawing';
  }

  @override
  String get constDetailStarCountLabel => 'Stars';

  @override
  String constDetailStarCountValue(int count) {
    return '$count';
  }

  @override
  String get constDetailCollectLabel => 'Collected';

  @override
  String constDetailCollectValue(int count) {
    return '$count times';
  }

  @override
  String get frpPrevWeek => 'Previous week';

  @override
  String get frpNextWeek => 'Next week';

  @override
  String get frpObsWitheredGuard => 'Cloudy night · streak kept by cloud guard';

  @override
  String frpPctBang(int pct) {
    return '$pct% achieved!';
  }

  @override
  String frpMissedWeight(int count) {
    return 'Starlight +$count';
  }

  @override
  String get frpLegendMemo => 'Memo starlight';

  @override
  String get frpBarsName => 'Starlight by weekday';

  @override
  String frpStampName(int count) {
    return 'Day $count of your streak';
  }

  @override
  String get constDetailTodayDesc => 'Today\'s constellation';

  @override
  String get constDetailTodayProgress => 'Starlight gathered today';

  @override
  String constDetailTodayPct(int pct) {
    return '$pct%';
  }

  @override
  String constDetailTodayRemain(int lit, int goal, int count) {
    return '$lit/$goal starlight · $count to go';
  }

  @override
  String constDetailTodayAll(int lit, int goal) {
    return '$lit/$goal starlight';
  }

  @override
  String get nightSkyTitle => 'Night sky';

  @override
  String get forestReportTitle => 'Observation report';

  @override
  String get fcolViewCta => 'View';

  @override
  String get fcolPreviewCta => 'Preview';

  @override
  String fcolLockedHint(int count) {
    return 'Gather $count starlight in one night to meet it.';
  }

  @override
  String get frpObsResult => 'Observation result';

  @override
  String frpObsToday(String name, int lit, int goal) {
    return '$name $lit/$goal in progress';
  }

  @override
  String frpObsCollected(String name) {
    return '$name collected!';
  }

  @override
  String get frpObsWithered => 'Cloudy night';

  @override
  String get frpObsRest => 'A restful night';

  @override
  String frpStampDays(int count) {
    return 'Day $count';
  }

  @override
  String get frpStampLabel => 'streak!';

  @override
  String get frpStarGather => 'Starlight gathering';

  @override
  String frpPctBadge(int pct) {
    return '$pct% achieved';
  }

  @override
  String get frpTileStar => 'Starlight gathered';

  @override
  String frpTileStarVal(int count) {
    return '$count';
  }

  @override
  String get frpTileDone => 'To-dos completed';

  @override
  String frpTileDoneVal(int count) {
    return '$count';
  }

  @override
  String get frpAnalysis => 'Starlight analysis';

  @override
  String frpLegendItem(String label, int count) {
    return '$label done $count';
  }

  @override
  String get frpMissed => 'Stars left unlit';

  @override
  String get frpMissedAllDone =>
      'You lit every star tonight. The rest waits for tomorrow!';

  @override
  String frpMissedCount(int count) {
    return '$count';
  }

  @override
  String frpAsOf(String ts) {
    return 'as of $ts';
  }

  @override
  String get settingsMenuTodoTag => 'To-do tags';

  @override
  String get settingsMenuMemoTag => 'Memo tags';

  @override
  String ttagUsage(int count) {
    return 'Used by $count to-dos';
  }

  @override
  String calLabelUsage(Object count) {
    return 'Used by $count events';
  }

  @override
  String get ttagEditTitle => 'Edit tag';

  @override
  String get ttagTitle => 'Todo tags';

  @override
  String get ttagDesc =>
      'Tags you attach to to-dos. They are used for filtering and counts on the to-do screen. If you delete a tag, its to-dos stay as \'No tag\'.';

  @override
  String get ttagAddCta => 'Add tag';

  @override
  String get ttagColorLabel => 'Color';

  @override
  String get ttagNameLabel => 'Name';

  @override
  String get ttagEmpty => 'No tags yet';

  @override
  String ttagDeleteDesc(int count) {
    return '$count to-dos using this tag will become untagged.';
  }

  @override
  String get iconPickerTitle => 'Select icon';

  @override
  String get iconPickerSearchHint => 'Search icons...';

  @override
  String get iconPickerNone => 'None';

  @override
  String get iconPickerNoResults => 'No results found';

  @override
  String iconPickerResultCount(int count) {
    return '$count results';
  }

  @override
  String iconPickerTotalHint(int count) {
    return '$count total · scroll for more';
  }

  @override
  String get smsPasteTitle => 'Record from payment text';

  @override
  String get smsPasteDesc =>
      'Paste a card payment text and we will read the amount, merchant and time to fill in the expense form. You can review it before saving.';

  @override
  String get smsPasteFieldLabel => 'Payment text';

  @override
  String get smsPastePlaceholder => '[Web발신]\n숲빛카드 5,500원\n골목찻집';

  @override
  String get smsPasteAction => 'Read text';

  @override
  String get smsPasteFromClipboard => 'Paste from clipboard';

  @override
  String get smsClipboardEmpty => 'No text in the clipboard.';

  @override
  String get smsParseFailed =>
      'We could not read the text. Please try again in a moment.';

  @override
  String get smsNotRecognized =>
      'This doesn\'t look like a payment text. Please check that the whole message was pasted.';

  @override
  String get smsCancelNotice =>
      'This is a cancellation text. Automatic recording is not supported — find the original expense and record it as a refund.';

  @override
  String get smsLowConfidence =>
      'Some fields could not be read. Please review and fill them in.';

  @override
  String get smsRememberCard =>
      'Remember this card and link it automatically next time';

  @override
  String get moreItemSmsPaste => 'Record from payment text';

  @override
  String get moreDescSmsPaste => 'Paste a card payment text to add an expense';

  @override
  String get smsClipboardBannerTitle => 'You have a copied payment text';

  @override
  String get smsClipboardBannerDesc => 'Paste it to record as an expense.';

  @override
  String get smsInboxTitle => 'Payment inbox';

  @override
  String get smsInboxClear => 'Clear';

  @override
  String get smsInboxEmpty => 'No payment notifications yet';

  @override
  String get smsInboxEmptyDesc =>
      'Detected card payments collect here. Tap one to record it as an expense.';

  @override
  String get smsInboxRemoveTitle => 'Delete this message?';

  @override
  String smsInboxRemoveConfirm(String target) {
    return '$target will be removed from the list. It won\'t be recorded.';
  }

  @override
  String smsInboxRemoveLabel(String name) {
    return 'Delete $name';
  }

  @override
  String get smsInboxClearTitle => 'Delete all messages?';

  @override
  String smsInboxClearConfirm(int count) {
    return 'All $count messages in the inbox will be removed. They won\'t be recorded.';
  }

  @override
  String get smsPermissionOffTitle =>
      'We can\'t notify you about detected payments';

  @override
  String get smsPermissionOffDesc =>
      'Turn on the notification permission and we will tell you as soon as a payment is detected. Detection keeps working either way and results collect in the inbox.';

  @override
  String get moreItemSmsInbox => 'Payment inbox';

  @override
  String get moreDescSmsInbox => 'Record detected card payments as expenses';

  @override
  String get smsNotiAccessOffTitle => 'Payment detection is off';

  @override
  String get smsNotiAccessOffDesc =>
      'Turn on notification access to read payment notifications from card and bank apps as well as payment texts. Only payment notifications are read — everything else is discarded immediately.';

  @override
  String get updateAutoBlockerTitle =>
      'Turn off Samsung Auto Blocker to install';

  @override
  String get updateAutoBlockerDesc =>
      'Galaxy devices block installing apps from outside the store by default. It is not that this app is unsafe — the feature blocks the install path itself, so the download will not install while it is on.';

  @override
  String get updateAutoBlockerPath =>
      'Turn it off in Settings > Security and privacy > Auto Blocker. You can turn it back on after installing.';

  @override
  String get updateAutoBlockerAfterDirect =>
      'Turn off Auto Blocker, come back, and tap download. You can turn it back on after installing.';

  @override
  String get updateAutoBlockerAfterSecurity =>
      'Find Auto Blocker in the list and turn it off. You can turn it back on after installing.';

  @override
  String get updateAutoBlockerOpen => 'Open settings';

  @override
  String get settingsSecuritiesLink => 'Securities links';

  @override
  String get settingsSecuritiesLinkDesc =>
      'Register your own API key to auto-import holdings and prices. Keys are stored encrypted on the server and used only by you.';

  @override
  String get securitiesLoadError => 'Couldn\'t load the securities list';

  @override
  String get subBrokerSectionTitle => 'Securities data link';

  @override
  String get subBrokerConnectDesc =>
      'Register your API key to import holdings and prices';

  @override
  String get subBrokerPrimary => 'Primary';

  @override
  String get subBrokerUseAsPrimary => 'Value assets with this provider';

  @override
  String get subBrokerPrimaryNotice =>
      'Your assets are valued using the provider selected here.';

  @override
  String get subBrokerPrimaryFailed => 'Couldn\'t change the primary provider';

  @override
  String subBrokerKeyConnected(String broker) {
    return '$broker API key connected';
  }

  @override
  String subBrokerConnected(String broker) {
    return 'Connected your $broker account';
  }

  @override
  String subBrokerDisconnected(String broker) {
    return 'Disconnected from $broker';
  }

  @override
  String subBrokerPrimaryChanged(String broker) {
    return 'Assets are now valued with $broker';
  }

  @override
  String subBrokerKeyNotice(String broker) {
    return 'Your key is stored encrypted on the server and used only by you. Issue one at the $broker developer center.';
  }

  @override
  String subBrokerToggleReveal(String field) {
    return 'Toggle $field visibility';
  }

  @override
  String get brokerToss => 'Toss Securities';

  @override
  String get brokerNamu => 'NAMUH Securities';

  @override
  String get stocksBrokerUnsupported =>
      'This app doesn\'t know that provider yet. Update the app to see it.';

  @override
  String get namuPriceEmpty => 'No current price for this instrument';

  @override
  String get namuTabDomestic => 'Domestic';

  @override
  String get namuTabOverseas => 'Overseas';

  @override
  String get namuHoldingsEmpty => 'No holdings yet';

  @override
  String get expFilterMatch => 'Condition matching';

  @override
  String get expFilterMatchAll => 'Match all';

  @override
  String get expFilterMatchAny => 'Match any';

  @override
  String get expFilterMatchHint =>
      'You can choose this once two or more conditions are set.';

  @override
  String get expFilterAddPeriod => 'Add period';

  @override
  String get expFilterAddAmountRange => 'Add range';

  @override
  String get expFilterPeriodAlwaysAnd =>
      'Periods always apply on top of the other conditions.';

  @override
  String get expFilterRemoveRow => 'Remove this row';

  @override
  String expFilterExcluded(int count) {
    return '$count excluded';
  }

  @override
  String get expRecordOnlyBadge => 'Record only';

  @override
  String get expRecordOnlyNote =>
      'This was added to a cycle that was already paid, so it is kept as a record only. It was not taken from your account.';

  @override
  String expRecordOnlyPartNote(String amount) {
    return '$amount of this belongs to cycles that were already paid, so it is kept as a record only. The remaining installments are billed as usual.';
  }

  @override
  String get expClosedCycleLine =>
      'This cycle has already been paid. Only the record changes, and your account balance stays the same.';

  @override
  String get expClosedCyclePartLine =>
      'Installments from past cycles stay as records only.';

  @override
  String get expFixBalance => 'Fix balance';

  @override
  String get expMoneyLockedNote =>
      'This transaction has already been paid. To change the amount or date, tap Rewrite';

  @override
  String get expMoneyLockedPaidOffNote =>
      'This transaction has already been paid. It is a paid-off installment, so the amount and date can\'t be changed.';

  @override
  String get expRewrite => 'Rewrite';

  @override
  String get expRewriteConfirmLead =>
      'The original transaction is deleted and replaced with a new one.';

  @override
  String get expRewriteConfirmClosed =>
      'Only the record changes, and your account balance stays the same.';

  @override
  String expRewriteConfirmOpen(String date) {
    return 'The new transaction is billed on the $date payment. The original is removed from the paid cycle as a record only.';
  }

  @override
  String get expSaveConfirmTitle => 'Save this?';

  @override
  String get assetPreRegistrationNote =>
      'These transactions are from before the card was added, so they may not match your actual statement';

  @override
  String get assetRecordCycle => 'Record-only cycle';

  @override
  String assetClosedPaidLine(String paid, String diff) {
    return '$paid left your account. The other $diff is kept as a record only';
  }

  @override
  String assetClosedOverpaidLine(String recorded, String paid) {
    return 'The record shows $recorded, but $paid left your account';
  }

  @override
  String get assetPaymentDayMissing => 'Please set a payment day';

  @override
  String get dsProgressCircleLabel => 'Loading';

  @override
  String get dsLoadingWaiting => 'Loading…';

  @override
  String get dsLoadingSlow => 'This is taking longer than usual.';

  @override
  String dsProgressOver(String amount) {
    return '$amount over';
  }

  @override
  String get dsProgressReached => 'Reached';

  @override
  String dsProgressSemantics(String label, String max, String current) {
    return '$label: $current of $max';
  }

  @override
  String get dsFieldOptional => 'Optional';

  @override
  String dsFieldCountSemantics(int count, int max) {
    return '$count of $max characters';
  }

  @override
  String get dsInputClear => 'Clear';

  @override
  String get fixedSwitchExpense => 'Fixed expense';

  @override
  String get fixedSwitchIncome => 'Fixed income';

  @override
  String get fixedHintExpense =>
      'Money that goes out every month like rent or phone bills. You can view it separately in statistics.';

  @override
  String get fixedHintIncome =>
      'Money that comes in every month like a salary. You can view it separately in statistics.';

  @override
  String get fixedBadge => 'Fixed';

  @override
  String get recurringFixedSub =>
      'Transactions this schedule creates from now on are recorded as fixed';

  @override
  String get presetFixedTitleExpense => 'Record as fixed expense';

  @override
  String get presetFixedTitleIncome => 'Record as fixed income';

  @override
  String get presetFixedDesc =>
      'Transactions made from this preset count as fixed in statistics.';

  @override
  String get hideCardStatsFixed => 'Fixed vs. variable tab';

  @override
  String get statsTabFixed => 'Fixed vs. variable';

  @override
  String get statsFixedViewAria => 'View';

  @override
  String get statsFixedViewAll => 'All';

  @override
  String get statsFixedViewVariable => 'Excl. fixed';

  @override
  String get statsFixedViewFixed => 'Fixed only';

  @override
  String get statsDonutCenterVariable => 'Excl. fixed';

  @override
  String get statsDonutCenterFixed => 'Fixed';

  @override
  String get statsFixedExpenseTitle => 'Spending: fixed vs. variable';

  @override
  String get statsFixedIncomeTitle => 'Income: fixed vs. variable';

  @override
  String get statsFixedExpenseNone => 'No spending in this period';

  @override
  String get statsFixedIncomeNone => 'No income in this period';

  @override
  String get statsFixedTotalExpense => 'Total spending';

  @override
  String get statsFixedTotalIncome => 'Total income';

  @override
  String get statsFixedFixedExpense => 'Fixed spending';

  @override
  String get statsFixedFixedIncome => 'Fixed income';

  @override
  String get statsFixedVariableExpense => 'Spending excl. fixed';

  @override
  String get statsFixedVariableIncome => 'Income excl. fixed';

  @override
  String statsFixedBarSemantics(String kind, int fixed, int variable) {
    return '$fixed% fixed, $variable% variable of $kind';
  }

  @override
  String statsFixedInsightExpense(int pct) {
    return '$pct% of spending is fixed. Spending excluding fixed is';
  }

  @override
  String statsFixedInsightIncome(int pct) {
    return '$pct% of income is fixed. Income excluding fixed is';
  }

  @override
  String get statsFixedInsightTail => '.';

  @override
  String get statsFixedEmptyDesc =>
      'Mark monthly items like rent or salary as fixed to see them separately here';

  @override
  String get statsFixedManage => 'Organize fixed items';

  @override
  String get statsFixedManageHint =>
      'Items with the same name every month can be set in one go';

  @override
  String get statsFixedTrendTitle => 'Monthly fixed vs. variable';

  @override
  String get statsFixedTrendKindAria => 'Spending or income';

  @override
  String get statsFixedTrendRecent => 'Last 6 months';

  @override
  String get statsFixedKindExpense => 'Spending';

  @override
  String get statsFixedKindIncome => 'Income';

  @override
  String get statsFixedLegendFixed => 'Fixed';

  @override
  String get statsFixedLegendVariable => 'Variable';

  @override
  String get statsFixedCategoryTitle => 'Fixed vs. variable by category';

  @override
  String statsFixedCategoryFixedPart(int pct) {
    return 'Fixed $pct%';
  }

  @override
  String get statsFixedBulkTitle => 'Organize fixed items';

  @override
  String statsFixedBulkDesc(String start, String end) {
    return 'Transactions from $start to $end. Items with the same name are grouped. Balances don\'t change, only how statistics classify them.';
  }

  @override
  String get statsFixedBulkUntitled => 'Untitled';

  @override
  String get statsFixedBulkTargetAria => 'Change to';

  @override
  String get statsFixedBulkToFixed => 'Mark as fixed';

  @override
  String get statsFixedBulkToVariable => 'Back to variable';

  @override
  String statsFixedBulkGroupSub(int count) {
    return '$count items';
  }

  @override
  String get statsFixedBulkBadgeAll => 'Fixed';

  @override
  String statsFixedBulkBadgeSome(int fixed, int count) {
    return 'Fixed $fixed/$count';
  }

  @override
  String get statsFixedBulkEmpty =>
      'No transactions to organize in this period';

  @override
  String statsFixedBulkApply(int count) {
    return 'Apply to $count';
  }

  @override
  String statsFixedBulkDoneFixed(int count) {
    return 'Marked $count as fixed';
  }

  @override
  String statsFixedBulkDoneVariable(int count) {
    return 'Changed $count back to variable';
  }

  @override
  String get navMainMenu => 'Main menu';

  @override
  String get navNotificationsNew => 'Notifications, new notifications';

  @override
  String get dsNotificationBadge => 'New updates';

  @override
  String get dsQuantityDecrease => 'Decrease';

  @override
  String get dsQuantityIncrease => 'Increase';

  @override
  String get dsSliderMin => 'Minimum';

  @override
  String get dsSliderMax => 'Maximum';

  @override
  String dsAttachLifted(int n) {
    return 'Picked up item $n.';
  }

  @override
  String dsAttachAddedPhotos(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n photos',
      one: '1 photo',
    );
    return 'Attached $_temp0.';
  }

  @override
  String dsAttachAddedFiles(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n files',
      one: '1 file',
    );
    return 'Attached $_temp0.';
  }

  @override
  String dsAttachAddedItems(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n items',
      one: '1 item',
    );
    return 'Attached $_temp0.';
  }

  @override
  String dsAttachUploaded(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n items',
      one: '1 item',
    );
    return 'Uploaded $_temp0.';
  }

  @override
  String dsAttachFailedCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n items',
      one: '1 item',
    );
    return '$_temp0 could not be uploaded.';
  }

  @override
  String get dsAttachTitle => 'Attachments';

  @override
  String get dsAttachCamera => 'Take a photo';

  @override
  String get dsAttachGallery => 'Choose from album';

  @override
  String get dsAttachFiles => 'Choose files';

  @override
  String dsAttachMoved(int n) {
    return 'Moved to position $n.';
  }

  @override
  String get dsAttachPreviewImage => 'View larger';

  @override
  String get dsAttachOpen => 'Open';

  @override
  String get dsAttachMakeCover => 'Set as cover';

  @override
  String get dsAttachMoveForward => 'Move earlier';

  @override
  String get dsAttachMoveBack => 'Move later';

  @override
  String get dsAttachUploading => 'Uploading';

  @override
  String dsAttachUploadingPercent(int percent) {
    return 'Uploading $percent%';
  }

  @override
  String get dsAttachUploadFailed => 'Upload failed';

  @override
  String get dsAttachDefaultLabel => 'Files';

  @override
  String get dsAttachSuffix => 'attachments';

  @override
  String dsAttachSuffixCount(String count) {
    return 'attachments, $count';
  }

  @override
  String get dsAttachPickFiles => 'Choose files';

  @override
  String dsAttachRetryNamed(String name) {
    return 'Retry $name';
  }

  @override
  String get dsAttachRetry => 'Retry';

  @override
  String dsAttachRemoveNamed(String name) {
    return 'Remove $name';
  }

  @override
  String get dsAvatarUploading => 'Uploading profile photo';

  @override
  String get dsDeltaNoChangeSentence => 'No change';

  @override
  String get dsDeltaIncreased => 'increased';

  @override
  String get dsDeltaDecreased => 'decreased';

  @override
  String get dsDeltaNone => 'No change';

  @override
  String get dsChartHeatValue => 'Spending';

  @override
  String get dsChartHeatNone => 'None';

  @override
  String get dsChartLegend => 'Legend';

  @override
  String dsSwipeMore(String row) {
    return 'More for $row';
  }

  @override
  String get dsColorRed => 'Red';

  @override
  String get dsColorOrange => 'Orange';

  @override
  String get dsColorYellow => 'Yellow';

  @override
  String get dsColorGreen => 'Green';

  @override
  String get dsColorBlue => 'Blue';

  @override
  String get dsColorIndigo => 'Indigo';

  @override
  String get dsColorViolet => 'Violet';

  @override
  String get dsColorPink => 'Pink';

  @override
  String get dsColorBrown => 'Brown';

  @override
  String get dsColorGray => 'Gray';

  @override
  String get dsColorCurrent => 'Current color';

  @override
  String get dsColorAuto => 'Auto';

  @override
  String get dsIconTitle => 'Icon';

  @override
  String get dsIconSearch => 'Search icons';

  @override
  String get dsIconSearchPlaceholder => 'Search icon names';

  @override
  String get dsIconCurrent => 'Current icon';

  @override
  String get dsIconEmptyDescription => 'Try another word or pick from a group.';

  @override
  String dsIconEmptyTitle(String query) {
    return 'No icons for \'$query\'';
  }

  @override
  String dsIconCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
    );
    return '$_temp0';
  }

  @override
  String get dsIconTagFallback => 'Tag';

  @override
  String get dsTimeTitle => 'Select time';

  @override
  String get dsTimePeriod => 'AM/PM';

  @override
  String get dsTimeHour => 'Hour';

  @override
  String get dsTimeMinute => 'Minute';

  @override
  String get dsTimeAm => 'AM';

  @override
  String get dsTimePm => 'PM';

  @override
  String get dsDateRoot => 'Select date';

  @override
  String get dsDatePrevMonth => 'Previous month';

  @override
  String get dsDateNextMonth => 'Next month';

  @override
  String get dsDateYear => 'Year';

  @override
  String get dsDateMonth => 'Month';

  @override
  String get dsDateReadOnlyStart => 'Read-only start date';

  @override
  String get dsDatePresets => 'Quick ranges';

  @override
  String get dsDateToday => 'today';

  @override
  String dsTabPosition(int index, int count) {
    return 'Tab $index of $count';
  }

  @override
  String get dsDatePresetThisWeek => 'This week';

  @override
  String get dsDatePresetThisMonth => 'This month';

  @override
  String get dsDatePresetLastMonth => 'Last month';

  @override
  String get dsDatePresetLast7 => 'Last 7 days';

  @override
  String get dsDatePresetLast30 => 'Last 30 days';

  @override
  String get dsDatePresetLast3M => 'Last 3 months';

  @override
  String get dsDatePresetLast6M => 'Last 6 months';

  @override
  String get dsDatePresetLast1Y => 'Last year';

  @override
  String get dsDatePresetThisYear => 'This year';

  @override
  String calMemberMore(String name) {
    return 'More for $name';
  }

  @override
  String get apiErrorServer =>
      'We couldn\'t complete the request. Please try again in a moment.';

  @override
  String get dsInfiniteListError => 'Couldn\'t load more.';

  @override
  String get dsInfiniteListEnd => 'You\'ve reached the end.';

  @override
  String get dsPullToRefreshLabel => 'Refreshing';

  @override
  String get dsPullToRefreshFailed => 'Couldn\'t refresh.';

  @override
  String get dsCommonRetry => 'Try again';

  @override
  String get cardListLoadFailed => 'Couldn\'t load cards';

  @override
  String get cardListEnd => 'You\'ve seen all the cards.';

  @override
  String get apiErrorNetwork =>
      'The network connection is unstable. Please try again in a moment.';

  @override
  String get txmCalendarToggle => 'Month calendar';

  @override
  String get expFilteredEmpty => 'No transactions match';

  @override
  String get expFilteredEmptyDesc => 'Change or clear the filters.';

  @override
  String get expFilterMatchAllDesc =>
      'Only transactions that meet every active filter';

  @override
  String get expFilterMatchAnyDesc =>
      'Transactions that meet any active filter';

  @override
  String get expFilterModeInclude => 'Only selected';

  @override
  String get expFilterModeExclude => 'All except selected';

  @override
  String get expFilterPeriodPick => 'Pick a period';

  @override
  String expFilterClearOne(String name) {
    return 'Clear $name';
  }

  @override
  String expFilterModeGroup(String name) {
    return 'How to pick $name';
  }

  @override
  String get expLoadErrorDesc => 'Please try again in a moment.';

  @override
  String get statsNoMonthlyData => 'No monthly data';

  @override
  String get statsLoadFailedCategory => 'Couldn\'t load spending by category';

  @override
  String get statsLoadFailedMerchant => 'Couldn\'t load top merchants';

  @override
  String get statsLoadFailedHeatmap =>
      'Couldn\'t load spending by day and time';

  @override
  String get statsLoadFailedHighlights => 'Couldn\'t load the summary';

  @override
  String get statsLoadFailedTrend => 'Couldn\'t load the trend';

  @override
  String get statsLoadFailedCompare => 'Couldn\'t load the comparison';

  @override
  String get statsLoadFailedWeekday => 'Couldn\'t load spending by weekday';

  @override
  String get statsLoadFailedFixed =>
      'Couldn\'t load fixed and variable spending';

  @override
  String get statsFixedBulkLoadFailed => 'Couldn\'t load transactions';

  @override
  String get statsCompareSame => 'Same as the previous period.';

  @override
  String statsChartDonutName(String period, String total) {
    return '$period spending by category, total $total';
  }

  @override
  String statsChartHeatName(String period, String total) {
    return '$period spending by day and time, total $total';
  }

  @override
  String get statsChartHeatValue => 'Spending';

  @override
  String statsChartTrendName(String period, String income, String expense) {
    return '$period income and spending trend, income $income · spending $expense';
  }

  @override
  String statsChartSavingsName(String period, String unit) {
    return '$period $unit';
  }

  @override
  String statsChartCatTrendName(String period) {
    return '$period monthly spending of top categories';
  }

  @override
  String statsChartWeekdayName(String period) {
    return '$period spending by weekday compared';
  }

  @override
  String statsChartFixedName(String kind) {
    return 'Monthly fixed and variable $kind';
  }

  @override
  String get statsTableDate => 'Date';

  @override
  String get statsTableMonth => 'Month';

  @override
  String get statsTableTime => 'Time of day';

  @override
  String get statsTableWeekday => 'Weekday';

  @override
  String statsPeriodButtonAria(String period) {
    return 'Change period ($period)';
  }

  @override
  String get statsTabsAria => 'Statistics views';

  @override
  String get tdmFilterOn => 'Filter, applied';

  @override
  String todoCheckName(String title) {
    return 'Complete $title';
  }

  @override
  String todoCheckNameOverdue(String title) {
    return 'Complete $title, overdue';
  }

  @override
  String get todoMemoTag => 'Note';

  @override
  String tdmCellLeft(String date, int count) {
    return '$date, $count to do';
  }

  @override
  String tdmCellCollected(String date) {
    return '$date, constellation collected';
  }

  @override
  String tdmCellMissed(String date) {
    return '$date, missed day';
  }

  @override
  String tdmCellDone(String date) {
    return '$date, all done';
  }

  @override
  String get tdmLoadFailedDesc => 'Please try again in a moment.';

  @override
  String get todoToggleFailed =>
      'Couldn\'t update the to-do. Please try again in a moment.';

  @override
  String get todoDetailOverdue => 'Overdue';

  @override
  String get todoDueDatePlaceholder => 'Select due date';

  @override
  String get todoTagEmptyHint => 'Create tags in Settings › Todo tags.';

  @override
  String ttagEmptyHint(String label) {
    return 'Create your first tag with $label.';
  }

  @override
  String get todoDueClear => 'Clear due date';

  @override
  String get ttagNameRequired => 'Please enter a name.';

  @override
  String get ttagNameTooLong => 'Keep the name under 12 characters.';

  @override
  String get ttagNameDuplicate => 'A tag with that name already exists.';

  @override
  String get assetPickInstitutionTitle => 'Choose institution';

  @override
  String get assetPickBrokerTitle => 'Choose brokerage';

  @override
  String get assetInstitutionPlaceholder => 'Select institution';

  @override
  String get assetCardPlaceholder => 'Select card';

  @override
  String get assetPickCardTitle => 'Choose card';

  @override
  String get assetCardEmptyHint => 'Try searching by issuer name too.';

  @override
  String assetSearchEmpty(String query) {
    return 'No results for \'$query\'';
  }

  @override
  String get assetSearchFailed => 'Couldn\'t load search results';

  @override
  String get assetAddStock => 'Add stock';

  @override
  String get assetFormFirstTitle => 'What would you like to add?';

  @override
  String get assetFormPickKindError => 'Choose what to add.';

  @override
  String assetFormTitleAdd(String kind) {
    return 'Add $kind';
  }

  @override
  String assetFormTitleEdit(String kind) {
    return 'Edit $kind';
  }

  @override
  String get assetFormKindLabel => 'Type';

  @override
  String get assetFormRulesGroup => 'Display settings';

  @override
  String get assetMemo => 'Memo';

  @override
  String assetOverLimitHelp(String amount) {
    return '$amount over the limit. It still saves — check the limit or the amount.';
  }

  @override
  String get assetBalanceAutoHelp =>
      'Calculated from holdings. Linked items reflect live prices when available.';

  @override
  String get assetHoldingQuantity => 'Quantity';

  @override
  String get assetHoldingValueLabel => 'Value';

  @override
  String get assetHoldingItemName => 'Item name';

  @override
  String assetHoldingRemoveOf(String name) {
    return 'Remove $name';
  }

  @override
  String get unlockVerifyFailed =>
      'Could not verify. Please try again in a moment.';

  @override
  String get unlockViewAmounts => 'View amounts';

  @override
  String get assetPaymentDayChangeAsk => 'Change the payment day?';

  @override
  String get assetFormErrCard => 'Choose a card.';

  @override
  String get assetFormErrPaymentDay => 'Choose a payment day.';

  @override
  String get assetNoPaymentAccount => 'No payment account';

  @override
  String get assetNoLinkedAccount => 'No linked account';

  @override
  String get unlockPasswordRequired => 'Enter your password.';

  @override
  String get stocksNoWatchlistDesc => 'Find a stock and tap the star.';

  @override
  String get stocksSectionMarket => 'Market';

  @override
  String get stocksSectionStocks => 'Stocks';

  @override
  String get stocksOrderbookTrades => 'Order book · Trades';

  @override
  String get stocksVsPurchase => 'vs. purchase';

  @override
  String stocksWatchGroupTitle(String name, int count) {
    return '$name · $count';
  }

  @override
  String get stocksWatchGroupRenameItem => 'Rename';

  @override
  String stocksWatchGroupMore(String name) {
    return 'More for $name';
  }

  @override
  String get stocksWatchGroupEmpty => 'No stocks added yet';

  @override
  String stocksWatchGroupDeleteConfirmCount(String name, int count) {
    return '\"$name\" and its $count stocks will be deleted together. A deleted group cannot be restored.';
  }

  @override
  String stocksWatchGroupDeleteConfirmEmpty(String name) {
    return '\"$name\" will be deleted. A deleted group cannot be restored.';
  }

  @override
  String get stocksWatchPickGroup => 'Add to which group';

  @override
  String get stocksWatchToggleLabel => 'Add to watchlist';

  @override
  String get stocksPortfolioTitle => 'Portfolio breakdown';

  @override
  String get stocksPortfolioSub => 'Weight by stock · totals by currency';

  @override
  String stocksPortfolioCount(int count) {
    return '$count stocks';
  }

  @override
  String get stocksPortfolioNeedsFx =>
      'Load the exchange rate to see the breakdown';

  @override
  String get stocksFailInvest => 'Couldn\'t load your investments';

  @override
  String get stocksFailMarket => 'Couldn\'t load market info';

  @override
  String get stocksFailHoldings => 'Couldn\'t load your holdings';

  @override
  String get stocksFailWatch => 'Couldn\'t load your watchlist';

  @override
  String get stocksFailRanking => 'Couldn\'t load rankings';

  @override
  String get stocksFailDaily => 'Couldn\'t load daily prices';

  @override
  String get stocksFailSearch => 'Couldn\'t load search results';

  @override
  String get stocksFailDesc => 'Please try again in a moment.';

  @override
  String get stocksSourceNotice =>
      'Toss Securities Open API · quotes may be delayed';

  @override
  String get stocksDisclaimerLine1 =>
      'Real-time quotes and prices apply once Toss Securities Open API is connected.';

  @override
  String get stocksDisclaimerLine2 =>
      'Quotes are for reference only. Actual orders require agreeing to the terms.';

  @override
  String stocksDailyVolume(String volume) {
    return 'Volume $volume';
  }

  @override
  String get stocksFxBasis => 'Base rate';

  @override
  String stocksDailyDate(int month, int day) {
    return '$month/$day';
  }

  @override
  String get stocksTradeSoon => 'Ordering will open soon.';

  @override
  String get stocksFailOrderbook => 'Couldn\'t load the order book';

  @override
  String get stocksFailTrades => 'Couldn\'t load trades';

  @override
  String get stocksFailInfo => 'Couldn\'t load basic info';

  @override
  String stocksRowAsk(String price, String qty) {
    return 'Ask $price, volume $qty';
  }

  @override
  String stocksRowBid(String price, String qty) {
    return 'Bid $price, volume $qty';
  }

  @override
  String stocksRowTrade(String time, String price, String qty) {
    return '$time, $price, quantity $qty';
  }

  @override
  String get stocksOrderbookTableName => 'Order book table';

  @override
  String get stocksTradesTableName => 'Trades table';

  @override
  String get stocksConnectEmptyTitle => 'Connect a brokerage';

  @override
  String get stocksConnectEmptyDesc =>
      'Connect your Toss Securities or Namu Securities key to see quotes and your holdings.';

  @override
  String get stocksConnectEmptyAction => 'Connect a brokerage';

  @override
  String get stockMarketKrEtc => 'Other (KR)';

  @override
  String get stockMarketUsEtc => 'Other (US)';

  @override
  String get stocksFailPrice => 'Couldn\'t load the price';

  @override
  String get namuKrwTotal => 'Total in KRW';

  @override
  String namuFxApplied(String rate) {
    return 'At FX $rate';
  }

  @override
  String get namuDomesticValue => 'Domestic value';

  @override
  String get namuOverseasValue => 'Overseas value';

  @override
  String namuCountSplit(int kr, int us) {
    return 'KR $kr · US $us';
  }

  @override
  String get namuFilterAll => 'All';

  @override
  String get namuFilterAria => 'Holdings market';

  @override
  String get namuFilterEmpty => 'No holdings in this market';

  @override
  String get namuFailDesc => 'There may be no account or no query permission.';

  @override
  String get namuDataNotice =>
      'Namu Securities Open API · quotes may be delayed';

  @override
  String get namuDonutNeedsFx => 'Cannot compute weights without an FX rate';

  @override
  String get stocksBuyingPowerKrw => 'Orderable · KRW';

  @override
  String get stocksBuyingPowerUsd => 'Orderable · USD';

  @override
  String get namuDepositUsd => 'Deposit · USD';

  @override
  String get stocksTodayQuote => 'Today\'s quotes';

  @override
  String get stocksOpenPrice => 'Open';

  @override
  String get stocksHighPrice => 'High';

  @override
  String get stocksLowPrice => 'Low';

  @override
  String get stocksInvestorTitle => 'Net buying by investor';

  @override
  String get stocksInvestorUnit => '▲ Net buy · ▼ Net sell · shares';

  @override
  String get stocksInvestorIndividual => 'Individual';

  @override
  String get stocksInvestorForeigner => 'Foreign';

  @override
  String get stocksInvestorInstitution => 'Institution';

  @override
  String get stocksInvestorEmpty => 'No investor trading data';

  @override
  String get stocksSector => 'Sector';

  @override
  String get stocksListedShares => 'Listed shares';

  @override
  String get stocksWarningInvestmentAttention => 'Investment attention';

  @override
  String get stocksMarketPre => 'Pre-market';

  @override
  String get stocksMarketAfter => 'After-market';

  @override
  String get stocksMarketDaytime => 'Daytime trading';

  @override
  String get stocksMarketSinglePrice => 'Single-price session';

  @override
  String get stocksMarketHalted => 'Temporarily closed';

  @override
  String get stocksMarketBeforeOpen => 'Before open';

  @override
  String get stocksFailQuote => 'Couldn\'t load the price';

  @override
  String get stocksFailToday => 'Couldn\'t load today\'s quotes';

  @override
  String get stocksFailInvestor => 'Couldn\'t load investor trading';

  @override
  String get namuFxUnavailableShort => 'No FX rate';

  @override
  String get expDetailMore => 'More';

  @override
  String expSplitValue(int count) {
    return 'Split into $count';
  }

  @override
  String expSplitHeader(int count) {
    return 'Split into $count';
  }

  @override
  String get expMerchantMonth => 'This month at this merchant';

  @override
  String get expRecentOnly => 'Showing the latest 5 only';

  @override
  String get expLinked => 'Linked';

  @override
  String get expSplitLoadFailed => 'Could not load the split items';

  @override
  String get expSplitLoadFailedDesc => 'Please try again in a moment.';

  @override
  String expRefundDateToday(String date) {
    return '$date · Today';
  }

  @override
  String expRefundDateHint(String date) {
    return 'You can pick a day from the transaction day ($date) to today.';
  }

  @override
  String get expRefundFailed =>
      'Couldn\'t mark it as refunded. Please try again in a moment.';

  @override
  String get expRefundCancelFailed => 'Couldn\'t undo the refund.';

  @override
  String get expTxDeleteFailed => 'Couldn\'t delete the transaction.';

  @override
  String get transferDeleteFailed => 'Couldn\'t delete the transfer.';

  @override
  String get transferDetailTitle => 'Transfer details';

  @override
  String get transferFromLabel => 'From account';

  @override
  String get transferToLabel => 'To account';

  @override
  String txfStepMeta(String current, String total) {
    return 'Step $current of $total';
  }

  @override
  String get txfTypeGroup => 'Transaction type';

  @override
  String get txfEntryRequired => 'Enter an amount.';

  @override
  String get txfAmountTooLarge => 'Amount can be up to 10 billion won.';

  @override
  String txfCurrencyChip(String code) {
    return 'Currency, $code';
  }

  @override
  String get txfPresetsTitle => 'Presets';

  @override
  String txfPresetApplied(String name) {
    return '$name applied';
  }

  @override
  String get txfNoPresets =>
      'No saved presets yet. Enter values and tap “Save current input” to create one.';

  @override
  String get txfPresetLoadFailed => 'Couldn\'t load presets.';

  @override
  String txfEmptyPresetHint(String name) {
    return 'The “$name” preset has no amount. Enter one and press Next.';
  }

  @override
  String get txfPresetAllTitle => 'Choose a preset';

  @override
  String get txfShowAll => 'See all';

  @override
  String get txfNone => 'None';

  @override
  String get txfNoAccountOption => 'No account or card';

  @override
  String get txfNoMethodOption => 'No payment method';

  @override
  String get txfErrCategory => 'Choose a category.';

  @override
  String get txfErrFrom => 'Choose the account to send from.';

  @override
  String get txfErrTo => 'Choose the account to send to.';

  @override
  String get txfErrFx => 'Enter the exchange rate or the amount in won.';

  @override
  String get txfErrInterest => 'Interest can\'t be more than the amount.';

  @override
  String get txfSplitsLoading =>
      'Loading the split items. Try again in a moment.';

  @override
  String get txfSaveFailed => 'Couldn\'t save. Please try again in a moment.';

  @override
  String get txfCategoryLoadFailed => 'Couldn\'t load categories';

  @override
  String get txfAssetLoadFailed => 'Couldn\'t load accounts and cards';

  @override
  String get txfNoCategoryOfType => 'There are no categories of this kind.';

  @override
  String get txfNoPickableAsset =>
      'No account or card fits this payment method.';

  @override
  String txfFxHint(String local, String code, String rate, String krw) {
    return '$local $code × $rate = $krw';
  }

  @override
  String get txfKrwAmount => 'Amount in won';

  @override
  String txfInstallmentValue(String months, String amount) {
    return '$months months · about $amount a month';
  }

  @override
  String get txfSplitMismatchTitle => 'The split items don\'t match the amount';

  @override
  String txfSplitMismatchBody(String total, String sum, String diffText) {
    return 'New total $total · split total $sum — $diffText';
  }

  @override
  String txfSplitOver(String diff) {
    return '$diff over.';
  }

  @override
  String txfSplitShort(String diff) {
    return '$diff short.';
  }

  @override
  String get txfMatchSplits => 'Adjust split items';

  @override
  String get txfSaveSplitAndSave => 'Adjust split items & save';

  @override
  String get txfSmsStepTitle => 'Paste a payment text';

  @override
  String get txfSmsHelp =>
      'Paste the payment text from your card company as it is. The amount, merchant and time it finds are filled in.';

  @override
  String get txfPresetAmountEmpty => 'Left empty';

  @override
  String get txfPresetAmountHint =>
      'If left empty, you enter the amount each time you use it.';

  @override
  String get txfPresetNameRequired => 'Enter a preset name.';

  @override
  String get txfPresetNeedParties =>
      'Choose the sending and receiving accounts first.';

  @override
  String get txfPresetNeedCategory => 'Choose a category first.';

  @override
  String get txfPresetNoMerchant => 'No details';

  @override
  String txfPresetSaved(String name) {
    return 'Saved the $name preset';
  }

  @override
  String get txfPresetNameTooLong => 'Keep the name within 12 characters.';

  @override
  String get txfMemoStepTitle => 'Memo';

  @override
  String get txfTimeTitle => 'Time';

  @override
  String get txfNoCategory => 'No category';

  @override
  String get txfNoDepositAccount => 'No deposit account';

  @override
  String get txfNoIncomeMethod => 'No income method';

  @override
  String get txfSelectFrom => 'Select the sending account';

  @override
  String get txfSelectTo => 'Select the receiving account';

  @override
  String get txfDeletedAsset => 'Deleted account';

  @override
  String get txfDeletedCategory => 'Deleted category';
}
