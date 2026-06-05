// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $BankAccountsTable extends BankAccounts
    with TableInfo<$BankAccountsTable, BankAccount> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BankAccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _bankNameMeta = const VerificationMeta(
    'bankName',
  );
  @override
  late final GeneratedColumn<String> bankName = GeneratedColumn<String>(
    'bank_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountNameMeta = const VerificationMeta(
    'accountName',
  );
  @override
  late final GeneratedColumn<String> accountName = GeneratedColumn<String>(
    'account_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountTypeMeta = const VerificationMeta(
    'accountType',
  );
  @override
  late final GeneratedColumn<String> accountType = GeneratedColumn<String>(
    'account_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _last4Meta = const VerificationMeta('last4');
  @override
  late final GeneratedColumn<String> last4 = GeneratedColumn<String>(
    'last4',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 4,
      maxTextLength: 4,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currentBalanceMeta = const VerificationMeta(
    'currentBalance',
  );
  @override
  late final GeneratedColumn<double> currentBalance = GeneratedColumn<double>(
    'current_balance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _colorOrIconMeta = const VerificationMeta(
    'colorOrIcon',
  );
  @override
  late final GeneratedColumn<String> colorOrIcon = GeneratedColumn<String>(
    'color_or_icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bankName,
    accountName,
    accountType,
    last4,
    currentBalance,
    colorOrIcon,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bank_accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<BankAccount> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('bank_name')) {
      context.handle(
        _bankNameMeta,
        bankName.isAcceptableOrUnknown(data['bank_name']!, _bankNameMeta),
      );
    } else if (isInserting) {
      context.missing(_bankNameMeta);
    }
    if (data.containsKey('account_name')) {
      context.handle(
        _accountNameMeta,
        accountName.isAcceptableOrUnknown(
          data['account_name']!,
          _accountNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accountNameMeta);
    }
    if (data.containsKey('account_type')) {
      context.handle(
        _accountTypeMeta,
        accountType.isAcceptableOrUnknown(
          data['account_type']!,
          _accountTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accountTypeMeta);
    }
    if (data.containsKey('last4')) {
      context.handle(
        _last4Meta,
        last4.isAcceptableOrUnknown(data['last4']!, _last4Meta),
      );
    }
    if (data.containsKey('current_balance')) {
      context.handle(
        _currentBalanceMeta,
        currentBalance.isAcceptableOrUnknown(
          data['current_balance']!,
          _currentBalanceMeta,
        ),
      );
    }
    if (data.containsKey('color_or_icon')) {
      context.handle(
        _colorOrIconMeta,
        colorOrIcon.isAcceptableOrUnknown(
          data['color_or_icon']!,
          _colorOrIconMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BankAccount map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BankAccount(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      bankName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank_name'],
      )!,
      accountName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_name'],
      )!,
      accountType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_type'],
      )!,
      last4: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last4'],
      ),
      currentBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}current_balance'],
      )!,
      colorOrIcon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_or_icon'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BankAccountsTable createAlias(String alias) {
    return $BankAccountsTable(attachedDatabase, alias);
  }
}

class BankAccount extends DataClass implements Insertable<BankAccount> {
  final int id;
  final String bankName;
  final String accountName;
  final String accountType;
  final String? last4;
  final double currentBalance;
  final String? colorOrIcon;
  final DateTime createdAt;
  final DateTime updatedAt;
  const BankAccount({
    required this.id,
    required this.bankName,
    required this.accountName,
    required this.accountType,
    this.last4,
    required this.currentBalance,
    this.colorOrIcon,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['bank_name'] = Variable<String>(bankName);
    map['account_name'] = Variable<String>(accountName);
    map['account_type'] = Variable<String>(accountType);
    if (!nullToAbsent || last4 != null) {
      map['last4'] = Variable<String>(last4);
    }
    map['current_balance'] = Variable<double>(currentBalance);
    if (!nullToAbsent || colorOrIcon != null) {
      map['color_or_icon'] = Variable<String>(colorOrIcon);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BankAccountsCompanion toCompanion(bool nullToAbsent) {
    return BankAccountsCompanion(
      id: Value(id),
      bankName: Value(bankName),
      accountName: Value(accountName),
      accountType: Value(accountType),
      last4: last4 == null && nullToAbsent
          ? const Value.absent()
          : Value(last4),
      currentBalance: Value(currentBalance),
      colorOrIcon: colorOrIcon == null && nullToAbsent
          ? const Value.absent()
          : Value(colorOrIcon),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory BankAccount.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BankAccount(
      id: serializer.fromJson<int>(json['id']),
      bankName: serializer.fromJson<String>(json['bankName']),
      accountName: serializer.fromJson<String>(json['accountName']),
      accountType: serializer.fromJson<String>(json['accountType']),
      last4: serializer.fromJson<String?>(json['last4']),
      currentBalance: serializer.fromJson<double>(json['currentBalance']),
      colorOrIcon: serializer.fromJson<String?>(json['colorOrIcon']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'bankName': serializer.toJson<String>(bankName),
      'accountName': serializer.toJson<String>(accountName),
      'accountType': serializer.toJson<String>(accountType),
      'last4': serializer.toJson<String?>(last4),
      'currentBalance': serializer.toJson<double>(currentBalance),
      'colorOrIcon': serializer.toJson<String?>(colorOrIcon),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BankAccount copyWith({
    int? id,
    String? bankName,
    String? accountName,
    String? accountType,
    Value<String?> last4 = const Value.absent(),
    double? currentBalance,
    Value<String?> colorOrIcon = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => BankAccount(
    id: id ?? this.id,
    bankName: bankName ?? this.bankName,
    accountName: accountName ?? this.accountName,
    accountType: accountType ?? this.accountType,
    last4: last4.present ? last4.value : this.last4,
    currentBalance: currentBalance ?? this.currentBalance,
    colorOrIcon: colorOrIcon.present ? colorOrIcon.value : this.colorOrIcon,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BankAccount copyWithCompanion(BankAccountsCompanion data) {
    return BankAccount(
      id: data.id.present ? data.id.value : this.id,
      bankName: data.bankName.present ? data.bankName.value : this.bankName,
      accountName: data.accountName.present
          ? data.accountName.value
          : this.accountName,
      accountType: data.accountType.present
          ? data.accountType.value
          : this.accountType,
      last4: data.last4.present ? data.last4.value : this.last4,
      currentBalance: data.currentBalance.present
          ? data.currentBalance.value
          : this.currentBalance,
      colorOrIcon: data.colorOrIcon.present
          ? data.colorOrIcon.value
          : this.colorOrIcon,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BankAccount(')
          ..write('id: $id, ')
          ..write('bankName: $bankName, ')
          ..write('accountName: $accountName, ')
          ..write('accountType: $accountType, ')
          ..write('last4: $last4, ')
          ..write('currentBalance: $currentBalance, ')
          ..write('colorOrIcon: $colorOrIcon, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    bankName,
    accountName,
    accountType,
    last4,
    currentBalance,
    colorOrIcon,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BankAccount &&
          other.id == this.id &&
          other.bankName == this.bankName &&
          other.accountName == this.accountName &&
          other.accountType == this.accountType &&
          other.last4 == this.last4 &&
          other.currentBalance == this.currentBalance &&
          other.colorOrIcon == this.colorOrIcon &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BankAccountsCompanion extends UpdateCompanion<BankAccount> {
  final Value<int> id;
  final Value<String> bankName;
  final Value<String> accountName;
  final Value<String> accountType;
  final Value<String?> last4;
  final Value<double> currentBalance;
  final Value<String?> colorOrIcon;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const BankAccountsCompanion({
    this.id = const Value.absent(),
    this.bankName = const Value.absent(),
    this.accountName = const Value.absent(),
    this.accountType = const Value.absent(),
    this.last4 = const Value.absent(),
    this.currentBalance = const Value.absent(),
    this.colorOrIcon = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  BankAccountsCompanion.insert({
    this.id = const Value.absent(),
    required String bankName,
    required String accountName,
    required String accountType,
    this.last4 = const Value.absent(),
    this.currentBalance = const Value.absent(),
    this.colorOrIcon = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : bankName = Value(bankName),
       accountName = Value(accountName),
       accountType = Value(accountType);
  static Insertable<BankAccount> custom({
    Expression<int>? id,
    Expression<String>? bankName,
    Expression<String>? accountName,
    Expression<String>? accountType,
    Expression<String>? last4,
    Expression<double>? currentBalance,
    Expression<String>? colorOrIcon,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bankName != null) 'bank_name': bankName,
      if (accountName != null) 'account_name': accountName,
      if (accountType != null) 'account_type': accountType,
      if (last4 != null) 'last4': last4,
      if (currentBalance != null) 'current_balance': currentBalance,
      if (colorOrIcon != null) 'color_or_icon': colorOrIcon,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  BankAccountsCompanion copyWith({
    Value<int>? id,
    Value<String>? bankName,
    Value<String>? accountName,
    Value<String>? accountType,
    Value<String?>? last4,
    Value<double>? currentBalance,
    Value<String?>? colorOrIcon,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return BankAccountsCompanion(
      id: id ?? this.id,
      bankName: bankName ?? this.bankName,
      accountName: accountName ?? this.accountName,
      accountType: accountType ?? this.accountType,
      last4: last4 ?? this.last4,
      currentBalance: currentBalance ?? this.currentBalance,
      colorOrIcon: colorOrIcon ?? this.colorOrIcon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (bankName.present) {
      map['bank_name'] = Variable<String>(bankName.value);
    }
    if (accountName.present) {
      map['account_name'] = Variable<String>(accountName.value);
    }
    if (accountType.present) {
      map['account_type'] = Variable<String>(accountType.value);
    }
    if (last4.present) {
      map['last4'] = Variable<String>(last4.value);
    }
    if (currentBalance.present) {
      map['current_balance'] = Variable<double>(currentBalance.value);
    }
    if (colorOrIcon.present) {
      map['color_or_icon'] = Variable<String>(colorOrIcon.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BankAccountsCompanion(')
          ..write('id: $id, ')
          ..write('bankName: $bankName, ')
          ..write('accountName: $accountName, ')
          ..write('accountType: $accountType, ')
          ..write('last4: $last4, ')
          ..write('currentBalance: $currentBalance, ')
          ..write('colorOrIcon: $colorOrIcon, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $CashWalletsTable extends CashWallets
    with TableInfo<$CashWalletsTable, CashWallet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CashWalletsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _walletNameMeta = const VerificationMeta(
    'walletName',
  );
  @override
  late final GeneratedColumn<String> walletName = GeneratedColumn<String>(
    'wallet_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _walletTypeMeta = const VerificationMeta(
    'walletType',
  );
  @override
  late final GeneratedColumn<String> walletType = GeneratedColumn<String>(
    'wallet_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('cash'),
  );
  static const VerificationMeta _currentBalanceMeta = const VerificationMeta(
    'currentBalance',
  );
  @override
  late final GeneratedColumn<double> currentBalance = GeneratedColumn<double>(
    'current_balance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    walletName,
    walletType,
    currentBalance,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cash_wallets';
  @override
  VerificationContext validateIntegrity(
    Insertable<CashWallet> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('wallet_name')) {
      context.handle(
        _walletNameMeta,
        walletName.isAcceptableOrUnknown(data['wallet_name']!, _walletNameMeta),
      );
    } else if (isInserting) {
      context.missing(_walletNameMeta);
    }
    if (data.containsKey('wallet_type')) {
      context.handle(
        _walletTypeMeta,
        walletType.isAcceptableOrUnknown(data['wallet_type']!, _walletTypeMeta),
      );
    }
    if (data.containsKey('current_balance')) {
      context.handle(
        _currentBalanceMeta,
        currentBalance.isAcceptableOrUnknown(
          data['current_balance']!,
          _currentBalanceMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CashWallet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CashWallet(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      walletName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wallet_name'],
      )!,
      walletType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wallet_type'],
      )!,
      currentBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}current_balance'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CashWalletsTable createAlias(String alias) {
    return $CashWalletsTable(attachedDatabase, alias);
  }
}

class CashWallet extends DataClass implements Insertable<CashWallet> {
  final int id;
  final String walletName;
  final String walletType;
  final double currentBalance;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CashWallet({
    required this.id,
    required this.walletName,
    required this.walletType,
    required this.currentBalance,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['wallet_name'] = Variable<String>(walletName);
    map['wallet_type'] = Variable<String>(walletType);
    map['current_balance'] = Variable<double>(currentBalance);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CashWalletsCompanion toCompanion(bool nullToAbsent) {
    return CashWalletsCompanion(
      id: Value(id),
      walletName: Value(walletName),
      walletType: Value(walletType),
      currentBalance: Value(currentBalance),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CashWallet.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CashWallet(
      id: serializer.fromJson<int>(json['id']),
      walletName: serializer.fromJson<String>(json['walletName']),
      walletType: serializer.fromJson<String>(json['walletType']),
      currentBalance: serializer.fromJson<double>(json['currentBalance']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'walletName': serializer.toJson<String>(walletName),
      'walletType': serializer.toJson<String>(walletType),
      'currentBalance': serializer.toJson<double>(currentBalance),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CashWallet copyWith({
    int? id,
    String? walletName,
    String? walletType,
    double? currentBalance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CashWallet(
    id: id ?? this.id,
    walletName: walletName ?? this.walletName,
    walletType: walletType ?? this.walletType,
    currentBalance: currentBalance ?? this.currentBalance,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CashWallet copyWithCompanion(CashWalletsCompanion data) {
    return CashWallet(
      id: data.id.present ? data.id.value : this.id,
      walletName: data.walletName.present
          ? data.walletName.value
          : this.walletName,
      walletType: data.walletType.present
          ? data.walletType.value
          : this.walletType,
      currentBalance: data.currentBalance.present
          ? data.currentBalance.value
          : this.currentBalance,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CashWallet(')
          ..write('id: $id, ')
          ..write('walletName: $walletName, ')
          ..write('walletType: $walletType, ')
          ..write('currentBalance: $currentBalance, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    walletName,
    walletType,
    currentBalance,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CashWallet &&
          other.id == this.id &&
          other.walletName == this.walletName &&
          other.walletType == this.walletType &&
          other.currentBalance == this.currentBalance &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CashWalletsCompanion extends UpdateCompanion<CashWallet> {
  final Value<int> id;
  final Value<String> walletName;
  final Value<String> walletType;
  final Value<double> currentBalance;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const CashWalletsCompanion({
    this.id = const Value.absent(),
    this.walletName = const Value.absent(),
    this.walletType = const Value.absent(),
    this.currentBalance = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CashWalletsCompanion.insert({
    this.id = const Value.absent(),
    required String walletName,
    this.walletType = const Value.absent(),
    this.currentBalance = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : walletName = Value(walletName);
  static Insertable<CashWallet> custom({
    Expression<int>? id,
    Expression<String>? walletName,
    Expression<String>? walletType,
    Expression<double>? currentBalance,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (walletName != null) 'wallet_name': walletName,
      if (walletType != null) 'wallet_type': walletType,
      if (currentBalance != null) 'current_balance': currentBalance,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CashWalletsCompanion copyWith({
    Value<int>? id,
    Value<String>? walletName,
    Value<String>? walletType,
    Value<double>? currentBalance,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return CashWalletsCompanion(
      id: id ?? this.id,
      walletName: walletName ?? this.walletName,
      walletType: walletType ?? this.walletType,
      currentBalance: currentBalance ?? this.currentBalance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (walletName.present) {
      map['wallet_name'] = Variable<String>(walletName.value);
    }
    if (walletType.present) {
      map['wallet_type'] = Variable<String>(walletType.value);
    }
    if (currentBalance.present) {
      map['current_balance'] = Variable<double>(currentBalance.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CashWalletsCompanion(')
          ..write('id: $id, ')
          ..write('walletName: $walletName, ')
          ..write('walletType: $walletType, ')
          ..write('currentBalance: $currentBalance, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $CreditCardsTable extends CreditCards
    with TableInfo<$CreditCardsTable, CreditCard> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CreditCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _bankNameMeta = const VerificationMeta(
    'bankName',
  );
  @override
  late final GeneratedColumn<String> bankName = GeneratedColumn<String>(
    'bank_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nicknameMeta = const VerificationMeta(
    'nickname',
  );
  @override
  late final GeneratedColumn<String> nickname = GeneratedColumn<String>(
    'nickname',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _last4Meta = const VerificationMeta('last4');
  @override
  late final GeneratedColumn<String> last4 = GeneratedColumn<String>(
    'last4',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 4,
      maxTextLength: 4,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _maskedNumberMeta = const VerificationMeta(
    'maskedNumber',
  );
  @override
  late final GeneratedColumn<String> maskedNumber = GeneratedColumn<String>(
    'masked_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _creditLimitMeta = const VerificationMeta(
    'creditLimit',
  );
  @override
  late final GeneratedColumn<double> creditLimit = GeneratedColumn<double>(
    'credit_limit',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _billingDayMeta = const VerificationMeta(
    'billingDay',
  );
  @override
  late final GeneratedColumn<int> billingDay = GeneratedColumn<int>(
    'billing_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueDayMeta = const VerificationMeta('dueDay');
  @override
  late final GeneratedColumn<int> dueDay = GeneratedColumn<int>(
    'due_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentOutstandingMeta =
      const VerificationMeta('currentOutstanding');
  @override
  late final GeneratedColumn<double> currentOutstanding =
      GeneratedColumn<double>(
        'current_outstanding',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bankName,
    nickname,
    last4,
    maskedNumber,
    creditLimit,
    billingDay,
    dueDay,
    currentOutstanding,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'credit_cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<CreditCard> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('bank_name')) {
      context.handle(
        _bankNameMeta,
        bankName.isAcceptableOrUnknown(data['bank_name']!, _bankNameMeta),
      );
    } else if (isInserting) {
      context.missing(_bankNameMeta);
    }
    if (data.containsKey('nickname')) {
      context.handle(
        _nicknameMeta,
        nickname.isAcceptableOrUnknown(data['nickname']!, _nicknameMeta),
      );
    } else if (isInserting) {
      context.missing(_nicknameMeta);
    }
    if (data.containsKey('last4')) {
      context.handle(
        _last4Meta,
        last4.isAcceptableOrUnknown(data['last4']!, _last4Meta),
      );
    } else if (isInserting) {
      context.missing(_last4Meta);
    }
    if (data.containsKey('masked_number')) {
      context.handle(
        _maskedNumberMeta,
        maskedNumber.isAcceptableOrUnknown(
          data['masked_number']!,
          _maskedNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_maskedNumberMeta);
    }
    if (data.containsKey('credit_limit')) {
      context.handle(
        _creditLimitMeta,
        creditLimit.isAcceptableOrUnknown(
          data['credit_limit']!,
          _creditLimitMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_creditLimitMeta);
    }
    if (data.containsKey('billing_day')) {
      context.handle(
        _billingDayMeta,
        billingDay.isAcceptableOrUnknown(data['billing_day']!, _billingDayMeta),
      );
    } else if (isInserting) {
      context.missing(_billingDayMeta);
    }
    if (data.containsKey('due_day')) {
      context.handle(
        _dueDayMeta,
        dueDay.isAcceptableOrUnknown(data['due_day']!, _dueDayMeta),
      );
    } else if (isInserting) {
      context.missing(_dueDayMeta);
    }
    if (data.containsKey('current_outstanding')) {
      context.handle(
        _currentOutstandingMeta,
        currentOutstanding.isAcceptableOrUnknown(
          data['current_outstanding']!,
          _currentOutstandingMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CreditCard map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CreditCard(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      bankName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank_name'],
      )!,
      nickname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nickname'],
      )!,
      last4: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last4'],
      )!,
      maskedNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}masked_number'],
      )!,
      creditLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}credit_limit'],
      )!,
      billingDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}billing_day'],
      )!,
      dueDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_day'],
      )!,
      currentOutstanding: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}current_outstanding'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CreditCardsTable createAlias(String alias) {
    return $CreditCardsTable(attachedDatabase, alias);
  }
}

class CreditCard extends DataClass implements Insertable<CreditCard> {
  final int id;
  final String bankName;
  final String nickname;
  final String last4;
  final String maskedNumber;
  final double creditLimit;
  final int billingDay;
  final int dueDay;
  final double currentOutstanding;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CreditCard({
    required this.id,
    required this.bankName,
    required this.nickname,
    required this.last4,
    required this.maskedNumber,
    required this.creditLimit,
    required this.billingDay,
    required this.dueDay,
    required this.currentOutstanding,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['bank_name'] = Variable<String>(bankName);
    map['nickname'] = Variable<String>(nickname);
    map['last4'] = Variable<String>(last4);
    map['masked_number'] = Variable<String>(maskedNumber);
    map['credit_limit'] = Variable<double>(creditLimit);
    map['billing_day'] = Variable<int>(billingDay);
    map['due_day'] = Variable<int>(dueDay);
    map['current_outstanding'] = Variable<double>(currentOutstanding);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CreditCardsCompanion toCompanion(bool nullToAbsent) {
    return CreditCardsCompanion(
      id: Value(id),
      bankName: Value(bankName),
      nickname: Value(nickname),
      last4: Value(last4),
      maskedNumber: Value(maskedNumber),
      creditLimit: Value(creditLimit),
      billingDay: Value(billingDay),
      dueDay: Value(dueDay),
      currentOutstanding: Value(currentOutstanding),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CreditCard.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CreditCard(
      id: serializer.fromJson<int>(json['id']),
      bankName: serializer.fromJson<String>(json['bankName']),
      nickname: serializer.fromJson<String>(json['nickname']),
      last4: serializer.fromJson<String>(json['last4']),
      maskedNumber: serializer.fromJson<String>(json['maskedNumber']),
      creditLimit: serializer.fromJson<double>(json['creditLimit']),
      billingDay: serializer.fromJson<int>(json['billingDay']),
      dueDay: serializer.fromJson<int>(json['dueDay']),
      currentOutstanding: serializer.fromJson<double>(
        json['currentOutstanding'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'bankName': serializer.toJson<String>(bankName),
      'nickname': serializer.toJson<String>(nickname),
      'last4': serializer.toJson<String>(last4),
      'maskedNumber': serializer.toJson<String>(maskedNumber),
      'creditLimit': serializer.toJson<double>(creditLimit),
      'billingDay': serializer.toJson<int>(billingDay),
      'dueDay': serializer.toJson<int>(dueDay),
      'currentOutstanding': serializer.toJson<double>(currentOutstanding),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CreditCard copyWith({
    int? id,
    String? bankName,
    String? nickname,
    String? last4,
    String? maskedNumber,
    double? creditLimit,
    int? billingDay,
    int? dueDay,
    double? currentOutstanding,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CreditCard(
    id: id ?? this.id,
    bankName: bankName ?? this.bankName,
    nickname: nickname ?? this.nickname,
    last4: last4 ?? this.last4,
    maskedNumber: maskedNumber ?? this.maskedNumber,
    creditLimit: creditLimit ?? this.creditLimit,
    billingDay: billingDay ?? this.billingDay,
    dueDay: dueDay ?? this.dueDay,
    currentOutstanding: currentOutstanding ?? this.currentOutstanding,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CreditCard copyWithCompanion(CreditCardsCompanion data) {
    return CreditCard(
      id: data.id.present ? data.id.value : this.id,
      bankName: data.bankName.present ? data.bankName.value : this.bankName,
      nickname: data.nickname.present ? data.nickname.value : this.nickname,
      last4: data.last4.present ? data.last4.value : this.last4,
      maskedNumber: data.maskedNumber.present
          ? data.maskedNumber.value
          : this.maskedNumber,
      creditLimit: data.creditLimit.present
          ? data.creditLimit.value
          : this.creditLimit,
      billingDay: data.billingDay.present
          ? data.billingDay.value
          : this.billingDay,
      dueDay: data.dueDay.present ? data.dueDay.value : this.dueDay,
      currentOutstanding: data.currentOutstanding.present
          ? data.currentOutstanding.value
          : this.currentOutstanding,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CreditCard(')
          ..write('id: $id, ')
          ..write('bankName: $bankName, ')
          ..write('nickname: $nickname, ')
          ..write('last4: $last4, ')
          ..write('maskedNumber: $maskedNumber, ')
          ..write('creditLimit: $creditLimit, ')
          ..write('billingDay: $billingDay, ')
          ..write('dueDay: $dueDay, ')
          ..write('currentOutstanding: $currentOutstanding, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    bankName,
    nickname,
    last4,
    maskedNumber,
    creditLimit,
    billingDay,
    dueDay,
    currentOutstanding,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CreditCard &&
          other.id == this.id &&
          other.bankName == this.bankName &&
          other.nickname == this.nickname &&
          other.last4 == this.last4 &&
          other.maskedNumber == this.maskedNumber &&
          other.creditLimit == this.creditLimit &&
          other.billingDay == this.billingDay &&
          other.dueDay == this.dueDay &&
          other.currentOutstanding == this.currentOutstanding &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CreditCardsCompanion extends UpdateCompanion<CreditCard> {
  final Value<int> id;
  final Value<String> bankName;
  final Value<String> nickname;
  final Value<String> last4;
  final Value<String> maskedNumber;
  final Value<double> creditLimit;
  final Value<int> billingDay;
  final Value<int> dueDay;
  final Value<double> currentOutstanding;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const CreditCardsCompanion({
    this.id = const Value.absent(),
    this.bankName = const Value.absent(),
    this.nickname = const Value.absent(),
    this.last4 = const Value.absent(),
    this.maskedNumber = const Value.absent(),
    this.creditLimit = const Value.absent(),
    this.billingDay = const Value.absent(),
    this.dueDay = const Value.absent(),
    this.currentOutstanding = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CreditCardsCompanion.insert({
    this.id = const Value.absent(),
    required String bankName,
    required String nickname,
    required String last4,
    required String maskedNumber,
    required double creditLimit,
    required int billingDay,
    required int dueDay,
    this.currentOutstanding = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : bankName = Value(bankName),
       nickname = Value(nickname),
       last4 = Value(last4),
       maskedNumber = Value(maskedNumber),
       creditLimit = Value(creditLimit),
       billingDay = Value(billingDay),
       dueDay = Value(dueDay);
  static Insertable<CreditCard> custom({
    Expression<int>? id,
    Expression<String>? bankName,
    Expression<String>? nickname,
    Expression<String>? last4,
    Expression<String>? maskedNumber,
    Expression<double>? creditLimit,
    Expression<int>? billingDay,
    Expression<int>? dueDay,
    Expression<double>? currentOutstanding,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bankName != null) 'bank_name': bankName,
      if (nickname != null) 'nickname': nickname,
      if (last4 != null) 'last4': last4,
      if (maskedNumber != null) 'masked_number': maskedNumber,
      if (creditLimit != null) 'credit_limit': creditLimit,
      if (billingDay != null) 'billing_day': billingDay,
      if (dueDay != null) 'due_day': dueDay,
      if (currentOutstanding != null) 'current_outstanding': currentOutstanding,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CreditCardsCompanion copyWith({
    Value<int>? id,
    Value<String>? bankName,
    Value<String>? nickname,
    Value<String>? last4,
    Value<String>? maskedNumber,
    Value<double>? creditLimit,
    Value<int>? billingDay,
    Value<int>? dueDay,
    Value<double>? currentOutstanding,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return CreditCardsCompanion(
      id: id ?? this.id,
      bankName: bankName ?? this.bankName,
      nickname: nickname ?? this.nickname,
      last4: last4 ?? this.last4,
      maskedNumber: maskedNumber ?? this.maskedNumber,
      creditLimit: creditLimit ?? this.creditLimit,
      billingDay: billingDay ?? this.billingDay,
      dueDay: dueDay ?? this.dueDay,
      currentOutstanding: currentOutstanding ?? this.currentOutstanding,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (bankName.present) {
      map['bank_name'] = Variable<String>(bankName.value);
    }
    if (nickname.present) {
      map['nickname'] = Variable<String>(nickname.value);
    }
    if (last4.present) {
      map['last4'] = Variable<String>(last4.value);
    }
    if (maskedNumber.present) {
      map['masked_number'] = Variable<String>(maskedNumber.value);
    }
    if (creditLimit.present) {
      map['credit_limit'] = Variable<double>(creditLimit.value);
    }
    if (billingDay.present) {
      map['billing_day'] = Variable<int>(billingDay.value);
    }
    if (dueDay.present) {
      map['due_day'] = Variable<int>(dueDay.value);
    }
    if (currentOutstanding.present) {
      map['current_outstanding'] = Variable<double>(currentOutstanding.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CreditCardsCompanion(')
          ..write('id: $id, ')
          ..write('bankName: $bankName, ')
          ..write('nickname: $nickname, ')
          ..write('last4: $last4, ')
          ..write('maskedNumber: $maskedNumber, ')
          ..write('creditLimit: $creditLimit, ')
          ..write('billingDay: $billingDay, ')
          ..write('dueDay: $dueDay, ')
          ..write('currentOutstanding: $currentOutstanding, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, Transaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transactionDateMeta = const VerificationMeta(
    'transactionDate',
  );
  @override
  late final GeneratedColumn<DateTime> transactionDate =
      GeneratedColumn<DateTime>(
        'transaction_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _paymentSourceTypeMeta = const VerificationMeta(
    'paymentSourceType',
  );
  @override
  late final GeneratedColumn<String> paymentSourceType =
      GeneratedColumn<String>(
        'payment_source_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _paymentSourceIdMeta = const VerificationMeta(
    'paymentSourceId',
  );
  @override
  late final GeneratedColumn<int> paymentSourceId = GeneratedColumn<int>(
    'payment_source_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cashbackAmountMeta = const VerificationMeta(
    'cashbackAmount',
  );
  @override
  late final GeneratedColumn<double> cashbackAmount = GeneratedColumn<double>(
    'cashback_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isForOthersMeta = const VerificationMeta(
    'isForOthers',
  );
  @override
  late final GeneratedColumn<bool> isForOthers = GeneratedColumn<bool>(
    'is_for_others',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_for_others" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _recoverableAmountMeta = const VerificationMeta(
    'recoverableAmount',
  );
  @override
  late final GeneratedColumn<double> recoverableAmount =
      GeneratedColumn<double>(
        'recoverable_amount',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _recoverableBaseAmountMeta =
      const VerificationMeta('recoverableBaseAmount');
  @override
  late final GeneratedColumn<double> recoverableBaseAmount =
      GeneratedColumn<double>(
        'recoverable_base_amount',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _recoveredAmountMeta = const VerificationMeta(
    'recoveredAmount',
  );
  @override
  late final GeneratedColumn<double> recoveredAmount = GeneratedColumn<double>(
    'recovered_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _recoverablePartyNameMeta =
      const VerificationMeta('recoverablePartyName');
  @override
  late final GeneratedColumn<String> recoverablePartyName =
      GeneratedColumn<String>(
        'recoverable_party_name',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _recoverablePartyNotesMeta =
      const VerificationMeta('recoverablePartyNotes');
  @override
  late final GeneratedColumn<String> recoverablePartyNotes =
      GeneratedColumn<String>(
        'recoverable_party_notes',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _recoverablePartyPhoneMeta =
      const VerificationMeta('recoverablePartyPhone');
  @override
  late final GeneratedColumn<String> recoverablePartyPhone =
      GeneratedColumn<String>(
        'recoverable_party_phone',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _recoverableStatusMeta = const VerificationMeta(
    'recoverableStatus',
  );
  @override
  late final GeneratedColumn<String> recoverableStatus =
      GeneratedColumn<String>(
        'recoverable_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('unpaid'),
      );
  static const VerificationMeta _recoveredAtMeta = const VerificationMeta(
    'recoveredAt',
  );
  @override
  late final GeneratedColumn<DateTime> recoveredAt = GeneratedColumn<DateTime>(
    'recovered_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _confirmedMeta = const VerificationMeta(
    'confirmed',
  );
  @override
  late final GeneratedColumn<bool> confirmed = GeneratedColumn<bool>(
    'confirmed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("confirmed" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _detectedSourceTypeMeta =
      const VerificationMeta('detectedSourceType');
  @override
  late final GeneratedColumn<String> detectedSourceType =
      GeneratedColumn<String>(
        'detected_source_type',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _cardBillIdMeta = const VerificationMeta(
    'cardBillId',
  );
  @override
  late final GeneratedColumn<int> cardBillId = GeneratedColumn<int>(
    'card_bill_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transferGroupIdMeta = const VerificationMeta(
    'transferGroupId',
  );
  @override
  late final GeneratedColumn<String> transferGroupId = GeneratedColumn<String>(
    'transfer_group_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceAccountIdMeta = const VerificationMeta(
    'sourceAccountId',
  );
  @override
  late final GeneratedColumn<int> sourceAccountId = GeneratedColumn<int>(
    'source_account_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _destinationAccountIdMeta =
      const VerificationMeta('destinationAccountId');
  @override
  late final GeneratedColumn<int> destinationAccountId = GeneratedColumn<int>(
    'destination_account_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _linkedSplitExpenseIdMeta =
      const VerificationMeta('linkedSplitExpenseId');
  @override
  late final GeneratedColumn<int> linkedSplitExpenseId = GeneratedColumn<int>(
    'linked_split_expense_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _personalShareAmountMeta =
      const VerificationMeta('personalShareAmount');
  @override
  late final GeneratedColumn<double> personalShareAmount =
      GeneratedColumn<double>(
        'personal_share_amount',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _splitGroupIdMeta = const VerificationMeta(
    'splitGroupId',
  );
  @override
  late final GeneratedColumn<int> splitGroupId = GeneratedColumn<int>(
    'split_group_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transactionImpactTypeMeta =
      const VerificationMeta('transactionImpactType');
  @override
  late final GeneratedColumn<String> transactionImpactType =
      GeneratedColumn<String>(
        'transaction_impact_type',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _cashbackDestinationTypeMeta =
      const VerificationMeta('cashbackDestinationType');
  @override
  late final GeneratedColumn<String> cashbackDestinationType =
      GeneratedColumn<String>(
        'cashback_destination_type',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _cashbackDestinationIdMeta =
      const VerificationMeta('cashbackDestinationId');
  @override
  late final GeneratedColumn<int> cashbackDestinationId = GeneratedColumn<int>(
    'cashback_destination_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _relatedTransactionIdMeta =
      const VerificationMeta('relatedTransactionId');
  @override
  late final GeneratedColumn<int> relatedTransactionId = GeneratedColumn<int>(
    'related_transaction_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    amount,
    title,
    category,
    notes,
    transactionDate,
    paymentSourceType,
    paymentSourceId,
    cashbackAmount,
    isForOthers,
    recoverableAmount,
    recoverableBaseAmount,
    recoveredAmount,
    recoverablePartyName,
    recoverablePartyNotes,
    recoverablePartyPhone,
    recoverableStatus,
    recoveredAt,
    confirmed,
    detectedSourceType,
    cardBillId,
    transferGroupId,
    sourceAccountId,
    destinationAccountId,
    linkedSplitExpenseId,
    personalShareAmount,
    splitGroupId,
    transactionImpactType,
    cashbackDestinationType,
    cashbackDestinationId,
    relatedTransactionId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Transaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('transaction_date')) {
      context.handle(
        _transactionDateMeta,
        transactionDate.isAcceptableOrUnknown(
          data['transaction_date']!,
          _transactionDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionDateMeta);
    }
    if (data.containsKey('payment_source_type')) {
      context.handle(
        _paymentSourceTypeMeta,
        paymentSourceType.isAcceptableOrUnknown(
          data['payment_source_type']!,
          _paymentSourceTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paymentSourceTypeMeta);
    }
    if (data.containsKey('payment_source_id')) {
      context.handle(
        _paymentSourceIdMeta,
        paymentSourceId.isAcceptableOrUnknown(
          data['payment_source_id']!,
          _paymentSourceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paymentSourceIdMeta);
    }
    if (data.containsKey('cashback_amount')) {
      context.handle(
        _cashbackAmountMeta,
        cashbackAmount.isAcceptableOrUnknown(
          data['cashback_amount']!,
          _cashbackAmountMeta,
        ),
      );
    }
    if (data.containsKey('is_for_others')) {
      context.handle(
        _isForOthersMeta,
        isForOthers.isAcceptableOrUnknown(
          data['is_for_others']!,
          _isForOthersMeta,
        ),
      );
    }
    if (data.containsKey('recoverable_amount')) {
      context.handle(
        _recoverableAmountMeta,
        recoverableAmount.isAcceptableOrUnknown(
          data['recoverable_amount']!,
          _recoverableAmountMeta,
        ),
      );
    }
    if (data.containsKey('recoverable_base_amount')) {
      context.handle(
        _recoverableBaseAmountMeta,
        recoverableBaseAmount.isAcceptableOrUnknown(
          data['recoverable_base_amount']!,
          _recoverableBaseAmountMeta,
        ),
      );
    }
    if (data.containsKey('recovered_amount')) {
      context.handle(
        _recoveredAmountMeta,
        recoveredAmount.isAcceptableOrUnknown(
          data['recovered_amount']!,
          _recoveredAmountMeta,
        ),
      );
    }
    if (data.containsKey('recoverable_party_name')) {
      context.handle(
        _recoverablePartyNameMeta,
        recoverablePartyName.isAcceptableOrUnknown(
          data['recoverable_party_name']!,
          _recoverablePartyNameMeta,
        ),
      );
    }
    if (data.containsKey('recoverable_party_notes')) {
      context.handle(
        _recoverablePartyNotesMeta,
        recoverablePartyNotes.isAcceptableOrUnknown(
          data['recoverable_party_notes']!,
          _recoverablePartyNotesMeta,
        ),
      );
    }
    if (data.containsKey('recoverable_party_phone')) {
      context.handle(
        _recoverablePartyPhoneMeta,
        recoverablePartyPhone.isAcceptableOrUnknown(
          data['recoverable_party_phone']!,
          _recoverablePartyPhoneMeta,
        ),
      );
    }
    if (data.containsKey('recoverable_status')) {
      context.handle(
        _recoverableStatusMeta,
        recoverableStatus.isAcceptableOrUnknown(
          data['recoverable_status']!,
          _recoverableStatusMeta,
        ),
      );
    }
    if (data.containsKey('recovered_at')) {
      context.handle(
        _recoveredAtMeta,
        recoveredAt.isAcceptableOrUnknown(
          data['recovered_at']!,
          _recoveredAtMeta,
        ),
      );
    }
    if (data.containsKey('confirmed')) {
      context.handle(
        _confirmedMeta,
        confirmed.isAcceptableOrUnknown(data['confirmed']!, _confirmedMeta),
      );
    }
    if (data.containsKey('detected_source_type')) {
      context.handle(
        _detectedSourceTypeMeta,
        detectedSourceType.isAcceptableOrUnknown(
          data['detected_source_type']!,
          _detectedSourceTypeMeta,
        ),
      );
    }
    if (data.containsKey('card_bill_id')) {
      context.handle(
        _cardBillIdMeta,
        cardBillId.isAcceptableOrUnknown(
          data['card_bill_id']!,
          _cardBillIdMeta,
        ),
      );
    }
    if (data.containsKey('transfer_group_id')) {
      context.handle(
        _transferGroupIdMeta,
        transferGroupId.isAcceptableOrUnknown(
          data['transfer_group_id']!,
          _transferGroupIdMeta,
        ),
      );
    }
    if (data.containsKey('source_account_id')) {
      context.handle(
        _sourceAccountIdMeta,
        sourceAccountId.isAcceptableOrUnknown(
          data['source_account_id']!,
          _sourceAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('destination_account_id')) {
      context.handle(
        _destinationAccountIdMeta,
        destinationAccountId.isAcceptableOrUnknown(
          data['destination_account_id']!,
          _destinationAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('linked_split_expense_id')) {
      context.handle(
        _linkedSplitExpenseIdMeta,
        linkedSplitExpenseId.isAcceptableOrUnknown(
          data['linked_split_expense_id']!,
          _linkedSplitExpenseIdMeta,
        ),
      );
    }
    if (data.containsKey('personal_share_amount')) {
      context.handle(
        _personalShareAmountMeta,
        personalShareAmount.isAcceptableOrUnknown(
          data['personal_share_amount']!,
          _personalShareAmountMeta,
        ),
      );
    }
    if (data.containsKey('split_group_id')) {
      context.handle(
        _splitGroupIdMeta,
        splitGroupId.isAcceptableOrUnknown(
          data['split_group_id']!,
          _splitGroupIdMeta,
        ),
      );
    }
    if (data.containsKey('transaction_impact_type')) {
      context.handle(
        _transactionImpactTypeMeta,
        transactionImpactType.isAcceptableOrUnknown(
          data['transaction_impact_type']!,
          _transactionImpactTypeMeta,
        ),
      );
    }
    if (data.containsKey('cashback_destination_type')) {
      context.handle(
        _cashbackDestinationTypeMeta,
        cashbackDestinationType.isAcceptableOrUnknown(
          data['cashback_destination_type']!,
          _cashbackDestinationTypeMeta,
        ),
      );
    }
    if (data.containsKey('cashback_destination_id')) {
      context.handle(
        _cashbackDestinationIdMeta,
        cashbackDestinationId.isAcceptableOrUnknown(
          data['cashback_destination_id']!,
          _cashbackDestinationIdMeta,
        ),
      );
    }
    if (data.containsKey('related_transaction_id')) {
      context.handle(
        _relatedTransactionIdMeta,
        relatedTransactionId.isAcceptableOrUnknown(
          data['related_transaction_id']!,
          _relatedTransactionIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Transaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      transactionDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}transaction_date'],
      )!,
      paymentSourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_source_type'],
      )!,
      paymentSourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}payment_source_id'],
      )!,
      cashbackAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cashback_amount'],
      )!,
      isForOthers: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_for_others'],
      )!,
      recoverableAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}recoverable_amount'],
      ),
      recoverableBaseAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}recoverable_base_amount'],
      ),
      recoveredAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}recovered_amount'],
      )!,
      recoverablePartyName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recoverable_party_name'],
      ),
      recoverablePartyNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recoverable_party_notes'],
      ),
      recoverablePartyPhone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recoverable_party_phone'],
      ),
      recoverableStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recoverable_status'],
      )!,
      recoveredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recovered_at'],
      ),
      confirmed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}confirmed'],
      )!,
      detectedSourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detected_source_type'],
      ),
      cardBillId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}card_bill_id'],
      ),
      transferGroupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transfer_group_id'],
      ),
      sourceAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_account_id'],
      ),
      destinationAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}destination_account_id'],
      ),
      linkedSplitExpenseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}linked_split_expense_id'],
      ),
      personalShareAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}personal_share_amount'],
      ),
      splitGroupId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}split_group_id'],
      ),
      transactionImpactType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_impact_type'],
      ),
      cashbackDestinationType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cashback_destination_type'],
      ),
      cashbackDestinationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cashback_destination_id'],
      ),
      relatedTransactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}related_transaction_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class Transaction extends DataClass implements Insertable<Transaction> {
  final int id;
  final String type;
  final double amount;
  final String title;
  final String category;
  final String? notes;
  final DateTime transactionDate;
  final String paymentSourceType;
  final int paymentSourceId;
  final double cashbackAmount;
  final bool isForOthers;
  final double? recoverableAmount;
  final double? recoverableBaseAmount;
  final double recoveredAmount;
  final String? recoverablePartyName;
  final String? recoverablePartyNotes;
  final String? recoverablePartyPhone;
  final String recoverableStatus;
  final DateTime? recoveredAt;
  final bool confirmed;
  final String? detectedSourceType;
  final int? cardBillId;
  final String? transferGroupId;
  final int? sourceAccountId;
  final int? destinationAccountId;
  final int? linkedSplitExpenseId;
  final double? personalShareAmount;
  final int? splitGroupId;
  final String? transactionImpactType;
  final String? cashbackDestinationType;
  final int? cashbackDestinationId;
  final int? relatedTransactionId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.title,
    required this.category,
    this.notes,
    required this.transactionDate,
    required this.paymentSourceType,
    required this.paymentSourceId,
    required this.cashbackAmount,
    required this.isForOthers,
    this.recoverableAmount,
    this.recoverableBaseAmount,
    required this.recoveredAmount,
    this.recoverablePartyName,
    this.recoverablePartyNotes,
    this.recoverablePartyPhone,
    required this.recoverableStatus,
    this.recoveredAt,
    required this.confirmed,
    this.detectedSourceType,
    this.cardBillId,
    this.transferGroupId,
    this.sourceAccountId,
    this.destinationAccountId,
    this.linkedSplitExpenseId,
    this.personalShareAmount,
    this.splitGroupId,
    this.transactionImpactType,
    this.cashbackDestinationType,
    this.cashbackDestinationId,
    this.relatedTransactionId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['type'] = Variable<String>(type);
    map['amount'] = Variable<double>(amount);
    map['title'] = Variable<String>(title);
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['transaction_date'] = Variable<DateTime>(transactionDate);
    map['payment_source_type'] = Variable<String>(paymentSourceType);
    map['payment_source_id'] = Variable<int>(paymentSourceId);
    map['cashback_amount'] = Variable<double>(cashbackAmount);
    map['is_for_others'] = Variable<bool>(isForOthers);
    if (!nullToAbsent || recoverableAmount != null) {
      map['recoverable_amount'] = Variable<double>(recoverableAmount);
    }
    if (!nullToAbsent || recoverableBaseAmount != null) {
      map['recoverable_base_amount'] = Variable<double>(recoverableBaseAmount);
    }
    map['recovered_amount'] = Variable<double>(recoveredAmount);
    if (!nullToAbsent || recoverablePartyName != null) {
      map['recoverable_party_name'] = Variable<String>(recoverablePartyName);
    }
    if (!nullToAbsent || recoverablePartyNotes != null) {
      map['recoverable_party_notes'] = Variable<String>(recoverablePartyNotes);
    }
    if (!nullToAbsent || recoverablePartyPhone != null) {
      map['recoverable_party_phone'] = Variable<String>(recoverablePartyPhone);
    }
    map['recoverable_status'] = Variable<String>(recoverableStatus);
    if (!nullToAbsent || recoveredAt != null) {
      map['recovered_at'] = Variable<DateTime>(recoveredAt);
    }
    map['confirmed'] = Variable<bool>(confirmed);
    if (!nullToAbsent || detectedSourceType != null) {
      map['detected_source_type'] = Variable<String>(detectedSourceType);
    }
    if (!nullToAbsent || cardBillId != null) {
      map['card_bill_id'] = Variable<int>(cardBillId);
    }
    if (!nullToAbsent || transferGroupId != null) {
      map['transfer_group_id'] = Variable<String>(transferGroupId);
    }
    if (!nullToAbsent || sourceAccountId != null) {
      map['source_account_id'] = Variable<int>(sourceAccountId);
    }
    if (!nullToAbsent || destinationAccountId != null) {
      map['destination_account_id'] = Variable<int>(destinationAccountId);
    }
    if (!nullToAbsent || linkedSplitExpenseId != null) {
      map['linked_split_expense_id'] = Variable<int>(linkedSplitExpenseId);
    }
    if (!nullToAbsent || personalShareAmount != null) {
      map['personal_share_amount'] = Variable<double>(personalShareAmount);
    }
    if (!nullToAbsent || splitGroupId != null) {
      map['split_group_id'] = Variable<int>(splitGroupId);
    }
    if (!nullToAbsent || transactionImpactType != null) {
      map['transaction_impact_type'] = Variable<String>(transactionImpactType);
    }
    if (!nullToAbsent || cashbackDestinationType != null) {
      map['cashback_destination_type'] = Variable<String>(
        cashbackDestinationType,
      );
    }
    if (!nullToAbsent || cashbackDestinationId != null) {
      map['cashback_destination_id'] = Variable<int>(cashbackDestinationId);
    }
    if (!nullToAbsent || relatedTransactionId != null) {
      map['related_transaction_id'] = Variable<int>(relatedTransactionId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      type: Value(type),
      amount: Value(amount),
      title: Value(title),
      category: Value(category),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      transactionDate: Value(transactionDate),
      paymentSourceType: Value(paymentSourceType),
      paymentSourceId: Value(paymentSourceId),
      cashbackAmount: Value(cashbackAmount),
      isForOthers: Value(isForOthers),
      recoverableAmount: recoverableAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(recoverableAmount),
      recoverableBaseAmount: recoverableBaseAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(recoverableBaseAmount),
      recoveredAmount: Value(recoveredAmount),
      recoverablePartyName: recoverablePartyName == null && nullToAbsent
          ? const Value.absent()
          : Value(recoverablePartyName),
      recoverablePartyNotes: recoverablePartyNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(recoverablePartyNotes),
      recoverablePartyPhone: recoverablePartyPhone == null && nullToAbsent
          ? const Value.absent()
          : Value(recoverablePartyPhone),
      recoverableStatus: Value(recoverableStatus),
      recoveredAt: recoveredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(recoveredAt),
      confirmed: Value(confirmed),
      detectedSourceType: detectedSourceType == null && nullToAbsent
          ? const Value.absent()
          : Value(detectedSourceType),
      cardBillId: cardBillId == null && nullToAbsent
          ? const Value.absent()
          : Value(cardBillId),
      transferGroupId: transferGroupId == null && nullToAbsent
          ? const Value.absent()
          : Value(transferGroupId),
      sourceAccountId: sourceAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceAccountId),
      destinationAccountId: destinationAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(destinationAccountId),
      linkedSplitExpenseId: linkedSplitExpenseId == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedSplitExpenseId),
      personalShareAmount: personalShareAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(personalShareAmount),
      splitGroupId: splitGroupId == null && nullToAbsent
          ? const Value.absent()
          : Value(splitGroupId),
      transactionImpactType: transactionImpactType == null && nullToAbsent
          ? const Value.absent()
          : Value(transactionImpactType),
      cashbackDestinationType: cashbackDestinationType == null && nullToAbsent
          ? const Value.absent()
          : Value(cashbackDestinationType),
      cashbackDestinationId: cashbackDestinationId == null && nullToAbsent
          ? const Value.absent()
          : Value(cashbackDestinationId),
      relatedTransactionId: relatedTransactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(relatedTransactionId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Transaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transaction(
      id: serializer.fromJson<int>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      amount: serializer.fromJson<double>(json['amount']),
      title: serializer.fromJson<String>(json['title']),
      category: serializer.fromJson<String>(json['category']),
      notes: serializer.fromJson<String?>(json['notes']),
      transactionDate: serializer.fromJson<DateTime>(json['transactionDate']),
      paymentSourceType: serializer.fromJson<String>(json['paymentSourceType']),
      paymentSourceId: serializer.fromJson<int>(json['paymentSourceId']),
      cashbackAmount: serializer.fromJson<double>(json['cashbackAmount']),
      isForOthers: serializer.fromJson<bool>(json['isForOthers']),
      recoverableAmount: serializer.fromJson<double?>(
        json['recoverableAmount'],
      ),
      recoverableBaseAmount: serializer.fromJson<double?>(
        json['recoverableBaseAmount'],
      ),
      recoveredAmount: serializer.fromJson<double>(json['recoveredAmount']),
      recoverablePartyName: serializer.fromJson<String?>(
        json['recoverablePartyName'],
      ),
      recoverablePartyNotes: serializer.fromJson<String?>(
        json['recoverablePartyNotes'],
      ),
      recoverablePartyPhone: serializer.fromJson<String?>(
        json['recoverablePartyPhone'],
      ),
      recoverableStatus: serializer.fromJson<String>(json['recoverableStatus']),
      recoveredAt: serializer.fromJson<DateTime?>(json['recoveredAt']),
      confirmed: serializer.fromJson<bool>(json['confirmed']),
      detectedSourceType: serializer.fromJson<String?>(
        json['detectedSourceType'],
      ),
      cardBillId: serializer.fromJson<int?>(json['cardBillId']),
      transferGroupId: serializer.fromJson<String?>(json['transferGroupId']),
      sourceAccountId: serializer.fromJson<int?>(json['sourceAccountId']),
      destinationAccountId: serializer.fromJson<int?>(
        json['destinationAccountId'],
      ),
      linkedSplitExpenseId: serializer.fromJson<int?>(
        json['linkedSplitExpenseId'],
      ),
      personalShareAmount: serializer.fromJson<double?>(
        json['personalShareAmount'],
      ),
      splitGroupId: serializer.fromJson<int?>(json['splitGroupId']),
      transactionImpactType: serializer.fromJson<String?>(
        json['transactionImpactType'],
      ),
      cashbackDestinationType: serializer.fromJson<String?>(
        json['cashbackDestinationType'],
      ),
      cashbackDestinationId: serializer.fromJson<int?>(
        json['cashbackDestinationId'],
      ),
      relatedTransactionId: serializer.fromJson<int?>(
        json['relatedTransactionId'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(type),
      'amount': serializer.toJson<double>(amount),
      'title': serializer.toJson<String>(title),
      'category': serializer.toJson<String>(category),
      'notes': serializer.toJson<String?>(notes),
      'transactionDate': serializer.toJson<DateTime>(transactionDate),
      'paymentSourceType': serializer.toJson<String>(paymentSourceType),
      'paymentSourceId': serializer.toJson<int>(paymentSourceId),
      'cashbackAmount': serializer.toJson<double>(cashbackAmount),
      'isForOthers': serializer.toJson<bool>(isForOthers),
      'recoverableAmount': serializer.toJson<double?>(recoverableAmount),
      'recoverableBaseAmount': serializer.toJson<double?>(
        recoverableBaseAmount,
      ),
      'recoveredAmount': serializer.toJson<double>(recoveredAmount),
      'recoverablePartyName': serializer.toJson<String?>(recoverablePartyName),
      'recoverablePartyNotes': serializer.toJson<String?>(
        recoverablePartyNotes,
      ),
      'recoverablePartyPhone': serializer.toJson<String?>(
        recoverablePartyPhone,
      ),
      'recoverableStatus': serializer.toJson<String>(recoverableStatus),
      'recoveredAt': serializer.toJson<DateTime?>(recoveredAt),
      'confirmed': serializer.toJson<bool>(confirmed),
      'detectedSourceType': serializer.toJson<String?>(detectedSourceType),
      'cardBillId': serializer.toJson<int?>(cardBillId),
      'transferGroupId': serializer.toJson<String?>(transferGroupId),
      'sourceAccountId': serializer.toJson<int?>(sourceAccountId),
      'destinationAccountId': serializer.toJson<int?>(destinationAccountId),
      'linkedSplitExpenseId': serializer.toJson<int?>(linkedSplitExpenseId),
      'personalShareAmount': serializer.toJson<double?>(personalShareAmount),
      'splitGroupId': serializer.toJson<int?>(splitGroupId),
      'transactionImpactType': serializer.toJson<String?>(
        transactionImpactType,
      ),
      'cashbackDestinationType': serializer.toJson<String?>(
        cashbackDestinationType,
      ),
      'cashbackDestinationId': serializer.toJson<int?>(cashbackDestinationId),
      'relatedTransactionId': serializer.toJson<int?>(relatedTransactionId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Transaction copyWith({
    int? id,
    String? type,
    double? amount,
    String? title,
    String? category,
    Value<String?> notes = const Value.absent(),
    DateTime? transactionDate,
    String? paymentSourceType,
    int? paymentSourceId,
    double? cashbackAmount,
    bool? isForOthers,
    Value<double?> recoverableAmount = const Value.absent(),
    Value<double?> recoverableBaseAmount = const Value.absent(),
    double? recoveredAmount,
    Value<String?> recoverablePartyName = const Value.absent(),
    Value<String?> recoverablePartyNotes = const Value.absent(),
    Value<String?> recoverablePartyPhone = const Value.absent(),
    String? recoverableStatus,
    Value<DateTime?> recoveredAt = const Value.absent(),
    bool? confirmed,
    Value<String?> detectedSourceType = const Value.absent(),
    Value<int?> cardBillId = const Value.absent(),
    Value<String?> transferGroupId = const Value.absent(),
    Value<int?> sourceAccountId = const Value.absent(),
    Value<int?> destinationAccountId = const Value.absent(),
    Value<int?> linkedSplitExpenseId = const Value.absent(),
    Value<double?> personalShareAmount = const Value.absent(),
    Value<int?> splitGroupId = const Value.absent(),
    Value<String?> transactionImpactType = const Value.absent(),
    Value<String?> cashbackDestinationType = const Value.absent(),
    Value<int?> cashbackDestinationId = const Value.absent(),
    Value<int?> relatedTransactionId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Transaction(
    id: id ?? this.id,
    type: type ?? this.type,
    amount: amount ?? this.amount,
    title: title ?? this.title,
    category: category ?? this.category,
    notes: notes.present ? notes.value : this.notes,
    transactionDate: transactionDate ?? this.transactionDate,
    paymentSourceType: paymentSourceType ?? this.paymentSourceType,
    paymentSourceId: paymentSourceId ?? this.paymentSourceId,
    cashbackAmount: cashbackAmount ?? this.cashbackAmount,
    isForOthers: isForOthers ?? this.isForOthers,
    recoverableAmount: recoverableAmount.present
        ? recoverableAmount.value
        : this.recoverableAmount,
    recoverableBaseAmount: recoverableBaseAmount.present
        ? recoverableBaseAmount.value
        : this.recoverableBaseAmount,
    recoveredAmount: recoveredAmount ?? this.recoveredAmount,
    recoverablePartyName: recoverablePartyName.present
        ? recoverablePartyName.value
        : this.recoverablePartyName,
    recoverablePartyNotes: recoverablePartyNotes.present
        ? recoverablePartyNotes.value
        : this.recoverablePartyNotes,
    recoverablePartyPhone: recoverablePartyPhone.present
        ? recoverablePartyPhone.value
        : this.recoverablePartyPhone,
    recoverableStatus: recoverableStatus ?? this.recoverableStatus,
    recoveredAt: recoveredAt.present ? recoveredAt.value : this.recoveredAt,
    confirmed: confirmed ?? this.confirmed,
    detectedSourceType: detectedSourceType.present
        ? detectedSourceType.value
        : this.detectedSourceType,
    cardBillId: cardBillId.present ? cardBillId.value : this.cardBillId,
    transferGroupId: transferGroupId.present
        ? transferGroupId.value
        : this.transferGroupId,
    sourceAccountId: sourceAccountId.present
        ? sourceAccountId.value
        : this.sourceAccountId,
    destinationAccountId: destinationAccountId.present
        ? destinationAccountId.value
        : this.destinationAccountId,
    linkedSplitExpenseId: linkedSplitExpenseId.present
        ? linkedSplitExpenseId.value
        : this.linkedSplitExpenseId,
    personalShareAmount: personalShareAmount.present
        ? personalShareAmount.value
        : this.personalShareAmount,
    splitGroupId: splitGroupId.present ? splitGroupId.value : this.splitGroupId,
    transactionImpactType: transactionImpactType.present
        ? transactionImpactType.value
        : this.transactionImpactType,
    cashbackDestinationType: cashbackDestinationType.present
        ? cashbackDestinationType.value
        : this.cashbackDestinationType,
    cashbackDestinationId: cashbackDestinationId.present
        ? cashbackDestinationId.value
        : this.cashbackDestinationId,
    relatedTransactionId: relatedTransactionId.present
        ? relatedTransactionId.value
        : this.relatedTransactionId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Transaction copyWithCompanion(TransactionsCompanion data) {
    return Transaction(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      amount: data.amount.present ? data.amount.value : this.amount,
      title: data.title.present ? data.title.value : this.title,
      category: data.category.present ? data.category.value : this.category,
      notes: data.notes.present ? data.notes.value : this.notes,
      transactionDate: data.transactionDate.present
          ? data.transactionDate.value
          : this.transactionDate,
      paymentSourceType: data.paymentSourceType.present
          ? data.paymentSourceType.value
          : this.paymentSourceType,
      paymentSourceId: data.paymentSourceId.present
          ? data.paymentSourceId.value
          : this.paymentSourceId,
      cashbackAmount: data.cashbackAmount.present
          ? data.cashbackAmount.value
          : this.cashbackAmount,
      isForOthers: data.isForOthers.present
          ? data.isForOthers.value
          : this.isForOthers,
      recoverableAmount: data.recoverableAmount.present
          ? data.recoverableAmount.value
          : this.recoverableAmount,
      recoverableBaseAmount: data.recoverableBaseAmount.present
          ? data.recoverableBaseAmount.value
          : this.recoverableBaseAmount,
      recoveredAmount: data.recoveredAmount.present
          ? data.recoveredAmount.value
          : this.recoveredAmount,
      recoverablePartyName: data.recoverablePartyName.present
          ? data.recoverablePartyName.value
          : this.recoverablePartyName,
      recoverablePartyNotes: data.recoverablePartyNotes.present
          ? data.recoverablePartyNotes.value
          : this.recoverablePartyNotes,
      recoverablePartyPhone: data.recoverablePartyPhone.present
          ? data.recoverablePartyPhone.value
          : this.recoverablePartyPhone,
      recoverableStatus: data.recoverableStatus.present
          ? data.recoverableStatus.value
          : this.recoverableStatus,
      recoveredAt: data.recoveredAt.present
          ? data.recoveredAt.value
          : this.recoveredAt,
      confirmed: data.confirmed.present ? data.confirmed.value : this.confirmed,
      detectedSourceType: data.detectedSourceType.present
          ? data.detectedSourceType.value
          : this.detectedSourceType,
      cardBillId: data.cardBillId.present
          ? data.cardBillId.value
          : this.cardBillId,
      transferGroupId: data.transferGroupId.present
          ? data.transferGroupId.value
          : this.transferGroupId,
      sourceAccountId: data.sourceAccountId.present
          ? data.sourceAccountId.value
          : this.sourceAccountId,
      destinationAccountId: data.destinationAccountId.present
          ? data.destinationAccountId.value
          : this.destinationAccountId,
      linkedSplitExpenseId: data.linkedSplitExpenseId.present
          ? data.linkedSplitExpenseId.value
          : this.linkedSplitExpenseId,
      personalShareAmount: data.personalShareAmount.present
          ? data.personalShareAmount.value
          : this.personalShareAmount,
      splitGroupId: data.splitGroupId.present
          ? data.splitGroupId.value
          : this.splitGroupId,
      transactionImpactType: data.transactionImpactType.present
          ? data.transactionImpactType.value
          : this.transactionImpactType,
      cashbackDestinationType: data.cashbackDestinationType.present
          ? data.cashbackDestinationType.value
          : this.cashbackDestinationType,
      cashbackDestinationId: data.cashbackDestinationId.present
          ? data.cashbackDestinationId.value
          : this.cashbackDestinationId,
      relatedTransactionId: data.relatedTransactionId.present
          ? data.relatedTransactionId.value
          : this.relatedTransactionId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transaction(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('notes: $notes, ')
          ..write('transactionDate: $transactionDate, ')
          ..write('paymentSourceType: $paymentSourceType, ')
          ..write('paymentSourceId: $paymentSourceId, ')
          ..write('cashbackAmount: $cashbackAmount, ')
          ..write('isForOthers: $isForOthers, ')
          ..write('recoverableAmount: $recoverableAmount, ')
          ..write('recoverableBaseAmount: $recoverableBaseAmount, ')
          ..write('recoveredAmount: $recoveredAmount, ')
          ..write('recoverablePartyName: $recoverablePartyName, ')
          ..write('recoverablePartyNotes: $recoverablePartyNotes, ')
          ..write('recoverablePartyPhone: $recoverablePartyPhone, ')
          ..write('recoverableStatus: $recoverableStatus, ')
          ..write('recoveredAt: $recoveredAt, ')
          ..write('confirmed: $confirmed, ')
          ..write('detectedSourceType: $detectedSourceType, ')
          ..write('cardBillId: $cardBillId, ')
          ..write('transferGroupId: $transferGroupId, ')
          ..write('sourceAccountId: $sourceAccountId, ')
          ..write('destinationAccountId: $destinationAccountId, ')
          ..write('linkedSplitExpenseId: $linkedSplitExpenseId, ')
          ..write('personalShareAmount: $personalShareAmount, ')
          ..write('splitGroupId: $splitGroupId, ')
          ..write('transactionImpactType: $transactionImpactType, ')
          ..write('cashbackDestinationType: $cashbackDestinationType, ')
          ..write('cashbackDestinationId: $cashbackDestinationId, ')
          ..write('relatedTransactionId: $relatedTransactionId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    type,
    amount,
    title,
    category,
    notes,
    transactionDate,
    paymentSourceType,
    paymentSourceId,
    cashbackAmount,
    isForOthers,
    recoverableAmount,
    recoverableBaseAmount,
    recoveredAmount,
    recoverablePartyName,
    recoverablePartyNotes,
    recoverablePartyPhone,
    recoverableStatus,
    recoveredAt,
    confirmed,
    detectedSourceType,
    cardBillId,
    transferGroupId,
    sourceAccountId,
    destinationAccountId,
    linkedSplitExpenseId,
    personalShareAmount,
    splitGroupId,
    transactionImpactType,
    cashbackDestinationType,
    cashbackDestinationId,
    relatedTransactionId,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transaction &&
          other.id == this.id &&
          other.type == this.type &&
          other.amount == this.amount &&
          other.title == this.title &&
          other.category == this.category &&
          other.notes == this.notes &&
          other.transactionDate == this.transactionDate &&
          other.paymentSourceType == this.paymentSourceType &&
          other.paymentSourceId == this.paymentSourceId &&
          other.cashbackAmount == this.cashbackAmount &&
          other.isForOthers == this.isForOthers &&
          other.recoverableAmount == this.recoverableAmount &&
          other.recoverableBaseAmount == this.recoverableBaseAmount &&
          other.recoveredAmount == this.recoveredAmount &&
          other.recoverablePartyName == this.recoverablePartyName &&
          other.recoverablePartyNotes == this.recoverablePartyNotes &&
          other.recoverablePartyPhone == this.recoverablePartyPhone &&
          other.recoverableStatus == this.recoverableStatus &&
          other.recoveredAt == this.recoveredAt &&
          other.confirmed == this.confirmed &&
          other.detectedSourceType == this.detectedSourceType &&
          other.cardBillId == this.cardBillId &&
          other.transferGroupId == this.transferGroupId &&
          other.sourceAccountId == this.sourceAccountId &&
          other.destinationAccountId == this.destinationAccountId &&
          other.linkedSplitExpenseId == this.linkedSplitExpenseId &&
          other.personalShareAmount == this.personalShareAmount &&
          other.splitGroupId == this.splitGroupId &&
          other.transactionImpactType == this.transactionImpactType &&
          other.cashbackDestinationType == this.cashbackDestinationType &&
          other.cashbackDestinationId == this.cashbackDestinationId &&
          other.relatedTransactionId == this.relatedTransactionId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TransactionsCompanion extends UpdateCompanion<Transaction> {
  final Value<int> id;
  final Value<String> type;
  final Value<double> amount;
  final Value<String> title;
  final Value<String> category;
  final Value<String?> notes;
  final Value<DateTime> transactionDate;
  final Value<String> paymentSourceType;
  final Value<int> paymentSourceId;
  final Value<double> cashbackAmount;
  final Value<bool> isForOthers;
  final Value<double?> recoverableAmount;
  final Value<double?> recoverableBaseAmount;
  final Value<double> recoveredAmount;
  final Value<String?> recoverablePartyName;
  final Value<String?> recoverablePartyNotes;
  final Value<String?> recoverablePartyPhone;
  final Value<String> recoverableStatus;
  final Value<DateTime?> recoveredAt;
  final Value<bool> confirmed;
  final Value<String?> detectedSourceType;
  final Value<int?> cardBillId;
  final Value<String?> transferGroupId;
  final Value<int?> sourceAccountId;
  final Value<int?> destinationAccountId;
  final Value<int?> linkedSplitExpenseId;
  final Value<double?> personalShareAmount;
  final Value<int?> splitGroupId;
  final Value<String?> transactionImpactType;
  final Value<String?> cashbackDestinationType;
  final Value<int?> cashbackDestinationId;
  final Value<int?> relatedTransactionId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.amount = const Value.absent(),
    this.title = const Value.absent(),
    this.category = const Value.absent(),
    this.notes = const Value.absent(),
    this.transactionDate = const Value.absent(),
    this.paymentSourceType = const Value.absent(),
    this.paymentSourceId = const Value.absent(),
    this.cashbackAmount = const Value.absent(),
    this.isForOthers = const Value.absent(),
    this.recoverableAmount = const Value.absent(),
    this.recoverableBaseAmount = const Value.absent(),
    this.recoveredAmount = const Value.absent(),
    this.recoverablePartyName = const Value.absent(),
    this.recoverablePartyNotes = const Value.absent(),
    this.recoverablePartyPhone = const Value.absent(),
    this.recoverableStatus = const Value.absent(),
    this.recoveredAt = const Value.absent(),
    this.confirmed = const Value.absent(),
    this.detectedSourceType = const Value.absent(),
    this.cardBillId = const Value.absent(),
    this.transferGroupId = const Value.absent(),
    this.sourceAccountId = const Value.absent(),
    this.destinationAccountId = const Value.absent(),
    this.linkedSplitExpenseId = const Value.absent(),
    this.personalShareAmount = const Value.absent(),
    this.splitGroupId = const Value.absent(),
    this.transactionImpactType = const Value.absent(),
    this.cashbackDestinationType = const Value.absent(),
    this.cashbackDestinationId = const Value.absent(),
    this.relatedTransactionId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  TransactionsCompanion.insert({
    this.id = const Value.absent(),
    required String type,
    required double amount,
    required String title,
    required String category,
    this.notes = const Value.absent(),
    required DateTime transactionDate,
    required String paymentSourceType,
    required int paymentSourceId,
    this.cashbackAmount = const Value.absent(),
    this.isForOthers = const Value.absent(),
    this.recoverableAmount = const Value.absent(),
    this.recoverableBaseAmount = const Value.absent(),
    this.recoveredAmount = const Value.absent(),
    this.recoverablePartyName = const Value.absent(),
    this.recoverablePartyNotes = const Value.absent(),
    this.recoverablePartyPhone = const Value.absent(),
    this.recoverableStatus = const Value.absent(),
    this.recoveredAt = const Value.absent(),
    this.confirmed = const Value.absent(),
    this.detectedSourceType = const Value.absent(),
    this.cardBillId = const Value.absent(),
    this.transferGroupId = const Value.absent(),
    this.sourceAccountId = const Value.absent(),
    this.destinationAccountId = const Value.absent(),
    this.linkedSplitExpenseId = const Value.absent(),
    this.personalShareAmount = const Value.absent(),
    this.splitGroupId = const Value.absent(),
    this.transactionImpactType = const Value.absent(),
    this.cashbackDestinationType = const Value.absent(),
    this.cashbackDestinationId = const Value.absent(),
    this.relatedTransactionId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : type = Value(type),
       amount = Value(amount),
       title = Value(title),
       category = Value(category),
       transactionDate = Value(transactionDate),
       paymentSourceType = Value(paymentSourceType),
       paymentSourceId = Value(paymentSourceId);
  static Insertable<Transaction> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<double>? amount,
    Expression<String>? title,
    Expression<String>? category,
    Expression<String>? notes,
    Expression<DateTime>? transactionDate,
    Expression<String>? paymentSourceType,
    Expression<int>? paymentSourceId,
    Expression<double>? cashbackAmount,
    Expression<bool>? isForOthers,
    Expression<double>? recoverableAmount,
    Expression<double>? recoverableBaseAmount,
    Expression<double>? recoveredAmount,
    Expression<String>? recoverablePartyName,
    Expression<String>? recoverablePartyNotes,
    Expression<String>? recoverablePartyPhone,
    Expression<String>? recoverableStatus,
    Expression<DateTime>? recoveredAt,
    Expression<bool>? confirmed,
    Expression<String>? detectedSourceType,
    Expression<int>? cardBillId,
    Expression<String>? transferGroupId,
    Expression<int>? sourceAccountId,
    Expression<int>? destinationAccountId,
    Expression<int>? linkedSplitExpenseId,
    Expression<double>? personalShareAmount,
    Expression<int>? splitGroupId,
    Expression<String>? transactionImpactType,
    Expression<String>? cashbackDestinationType,
    Expression<int>? cashbackDestinationId,
    Expression<int>? relatedTransactionId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (amount != null) 'amount': amount,
      if (title != null) 'title': title,
      if (category != null) 'category': category,
      if (notes != null) 'notes': notes,
      if (transactionDate != null) 'transaction_date': transactionDate,
      if (paymentSourceType != null) 'payment_source_type': paymentSourceType,
      if (paymentSourceId != null) 'payment_source_id': paymentSourceId,
      if (cashbackAmount != null) 'cashback_amount': cashbackAmount,
      if (isForOthers != null) 'is_for_others': isForOthers,
      if (recoverableAmount != null) 'recoverable_amount': recoverableAmount,
      if (recoverableBaseAmount != null)
        'recoverable_base_amount': recoverableBaseAmount,
      if (recoveredAmount != null) 'recovered_amount': recoveredAmount,
      if (recoverablePartyName != null)
        'recoverable_party_name': recoverablePartyName,
      if (recoverablePartyNotes != null)
        'recoverable_party_notes': recoverablePartyNotes,
      if (recoverablePartyPhone != null)
        'recoverable_party_phone': recoverablePartyPhone,
      if (recoverableStatus != null) 'recoverable_status': recoverableStatus,
      if (recoveredAt != null) 'recovered_at': recoveredAt,
      if (confirmed != null) 'confirmed': confirmed,
      if (detectedSourceType != null)
        'detected_source_type': detectedSourceType,
      if (cardBillId != null) 'card_bill_id': cardBillId,
      if (transferGroupId != null) 'transfer_group_id': transferGroupId,
      if (sourceAccountId != null) 'source_account_id': sourceAccountId,
      if (destinationAccountId != null)
        'destination_account_id': destinationAccountId,
      if (linkedSplitExpenseId != null)
        'linked_split_expense_id': linkedSplitExpenseId,
      if (personalShareAmount != null)
        'personal_share_amount': personalShareAmount,
      if (splitGroupId != null) 'split_group_id': splitGroupId,
      if (transactionImpactType != null)
        'transaction_impact_type': transactionImpactType,
      if (cashbackDestinationType != null)
        'cashback_destination_type': cashbackDestinationType,
      if (cashbackDestinationId != null)
        'cashback_destination_id': cashbackDestinationId,
      if (relatedTransactionId != null)
        'related_transaction_id': relatedTransactionId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  TransactionsCompanion copyWith({
    Value<int>? id,
    Value<String>? type,
    Value<double>? amount,
    Value<String>? title,
    Value<String>? category,
    Value<String?>? notes,
    Value<DateTime>? transactionDate,
    Value<String>? paymentSourceType,
    Value<int>? paymentSourceId,
    Value<double>? cashbackAmount,
    Value<bool>? isForOthers,
    Value<double?>? recoverableAmount,
    Value<double?>? recoverableBaseAmount,
    Value<double>? recoveredAmount,
    Value<String?>? recoverablePartyName,
    Value<String?>? recoverablePartyNotes,
    Value<String?>? recoverablePartyPhone,
    Value<String>? recoverableStatus,
    Value<DateTime?>? recoveredAt,
    Value<bool>? confirmed,
    Value<String?>? detectedSourceType,
    Value<int?>? cardBillId,
    Value<String?>? transferGroupId,
    Value<int?>? sourceAccountId,
    Value<int?>? destinationAccountId,
    Value<int?>? linkedSplitExpenseId,
    Value<double?>? personalShareAmount,
    Value<int?>? splitGroupId,
    Value<String?>? transactionImpactType,
    Value<String?>? cashbackDestinationType,
    Value<int?>? cashbackDestinationId,
    Value<int?>? relatedTransactionId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      title: title ?? this.title,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      transactionDate: transactionDate ?? this.transactionDate,
      paymentSourceType: paymentSourceType ?? this.paymentSourceType,
      paymentSourceId: paymentSourceId ?? this.paymentSourceId,
      cashbackAmount: cashbackAmount ?? this.cashbackAmount,
      isForOthers: isForOthers ?? this.isForOthers,
      recoverableAmount: recoverableAmount ?? this.recoverableAmount,
      recoverableBaseAmount:
          recoverableBaseAmount ?? this.recoverableBaseAmount,
      recoveredAmount: recoveredAmount ?? this.recoveredAmount,
      recoverablePartyName: recoverablePartyName ?? this.recoverablePartyName,
      recoverablePartyNotes:
          recoverablePartyNotes ?? this.recoverablePartyNotes,
      recoverablePartyPhone:
          recoverablePartyPhone ?? this.recoverablePartyPhone,
      recoverableStatus: recoverableStatus ?? this.recoverableStatus,
      recoveredAt: recoveredAt ?? this.recoveredAt,
      confirmed: confirmed ?? this.confirmed,
      detectedSourceType: detectedSourceType ?? this.detectedSourceType,
      cardBillId: cardBillId ?? this.cardBillId,
      transferGroupId: transferGroupId ?? this.transferGroupId,
      sourceAccountId: sourceAccountId ?? this.sourceAccountId,
      destinationAccountId: destinationAccountId ?? this.destinationAccountId,
      linkedSplitExpenseId: linkedSplitExpenseId ?? this.linkedSplitExpenseId,
      personalShareAmount: personalShareAmount ?? this.personalShareAmount,
      splitGroupId: splitGroupId ?? this.splitGroupId,
      transactionImpactType:
          transactionImpactType ?? this.transactionImpactType,
      cashbackDestinationType:
          cashbackDestinationType ?? this.cashbackDestinationType,
      cashbackDestinationId:
          cashbackDestinationId ?? this.cashbackDestinationId,
      relatedTransactionId: relatedTransactionId ?? this.relatedTransactionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (transactionDate.present) {
      map['transaction_date'] = Variable<DateTime>(transactionDate.value);
    }
    if (paymentSourceType.present) {
      map['payment_source_type'] = Variable<String>(paymentSourceType.value);
    }
    if (paymentSourceId.present) {
      map['payment_source_id'] = Variable<int>(paymentSourceId.value);
    }
    if (cashbackAmount.present) {
      map['cashback_amount'] = Variable<double>(cashbackAmount.value);
    }
    if (isForOthers.present) {
      map['is_for_others'] = Variable<bool>(isForOthers.value);
    }
    if (recoverableAmount.present) {
      map['recoverable_amount'] = Variable<double>(recoverableAmount.value);
    }
    if (recoverableBaseAmount.present) {
      map['recoverable_base_amount'] = Variable<double>(
        recoverableBaseAmount.value,
      );
    }
    if (recoveredAmount.present) {
      map['recovered_amount'] = Variable<double>(recoveredAmount.value);
    }
    if (recoverablePartyName.present) {
      map['recoverable_party_name'] = Variable<String>(
        recoverablePartyName.value,
      );
    }
    if (recoverablePartyNotes.present) {
      map['recoverable_party_notes'] = Variable<String>(
        recoverablePartyNotes.value,
      );
    }
    if (recoverablePartyPhone.present) {
      map['recoverable_party_phone'] = Variable<String>(
        recoverablePartyPhone.value,
      );
    }
    if (recoverableStatus.present) {
      map['recoverable_status'] = Variable<String>(recoverableStatus.value);
    }
    if (recoveredAt.present) {
      map['recovered_at'] = Variable<DateTime>(recoveredAt.value);
    }
    if (confirmed.present) {
      map['confirmed'] = Variable<bool>(confirmed.value);
    }
    if (detectedSourceType.present) {
      map['detected_source_type'] = Variable<String>(detectedSourceType.value);
    }
    if (cardBillId.present) {
      map['card_bill_id'] = Variable<int>(cardBillId.value);
    }
    if (transferGroupId.present) {
      map['transfer_group_id'] = Variable<String>(transferGroupId.value);
    }
    if (sourceAccountId.present) {
      map['source_account_id'] = Variable<int>(sourceAccountId.value);
    }
    if (destinationAccountId.present) {
      map['destination_account_id'] = Variable<int>(destinationAccountId.value);
    }
    if (linkedSplitExpenseId.present) {
      map['linked_split_expense_id'] = Variable<int>(
        linkedSplitExpenseId.value,
      );
    }
    if (personalShareAmount.present) {
      map['personal_share_amount'] = Variable<double>(
        personalShareAmount.value,
      );
    }
    if (splitGroupId.present) {
      map['split_group_id'] = Variable<int>(splitGroupId.value);
    }
    if (transactionImpactType.present) {
      map['transaction_impact_type'] = Variable<String>(
        transactionImpactType.value,
      );
    }
    if (cashbackDestinationType.present) {
      map['cashback_destination_type'] = Variable<String>(
        cashbackDestinationType.value,
      );
    }
    if (cashbackDestinationId.present) {
      map['cashback_destination_id'] = Variable<int>(
        cashbackDestinationId.value,
      );
    }
    if (relatedTransactionId.present) {
      map['related_transaction_id'] = Variable<int>(relatedTransactionId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('notes: $notes, ')
          ..write('transactionDate: $transactionDate, ')
          ..write('paymentSourceType: $paymentSourceType, ')
          ..write('paymentSourceId: $paymentSourceId, ')
          ..write('cashbackAmount: $cashbackAmount, ')
          ..write('isForOthers: $isForOthers, ')
          ..write('recoverableAmount: $recoverableAmount, ')
          ..write('recoverableBaseAmount: $recoverableBaseAmount, ')
          ..write('recoveredAmount: $recoveredAmount, ')
          ..write('recoverablePartyName: $recoverablePartyName, ')
          ..write('recoverablePartyNotes: $recoverablePartyNotes, ')
          ..write('recoverablePartyPhone: $recoverablePartyPhone, ')
          ..write('recoverableStatus: $recoverableStatus, ')
          ..write('recoveredAt: $recoveredAt, ')
          ..write('confirmed: $confirmed, ')
          ..write('detectedSourceType: $detectedSourceType, ')
          ..write('cardBillId: $cardBillId, ')
          ..write('transferGroupId: $transferGroupId, ')
          ..write('sourceAccountId: $sourceAccountId, ')
          ..write('destinationAccountId: $destinationAccountId, ')
          ..write('linkedSplitExpenseId: $linkedSplitExpenseId, ')
          ..write('personalShareAmount: $personalShareAmount, ')
          ..write('splitGroupId: $splitGroupId, ')
          ..write('transactionImpactType: $transactionImpactType, ')
          ..write('cashbackDestinationType: $cashbackDestinationType, ')
          ..write('cashbackDestinationId: $cashbackDestinationId, ')
          ..write('relatedTransactionId: $relatedTransactionId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $PendingTransactionsTable extends PendingTransactions
    with TableInfo<$PendingTransactionsTable, PendingTransaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingTransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _merchantMeta = const VerificationMeta(
    'merchant',
  );
  @override
  late final GeneratedColumn<String> merchant = GeneratedColumn<String>(
    'merchant',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categorySuggestionMeta =
      const VerificationMeta('categorySuggestion');
  @override
  late final GeneratedColumn<String> categorySuggestion =
      GeneratedColumn<String>(
        'category_suggestion',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _paymentSourceTypeSuggestionMeta =
      const VerificationMeta('paymentSourceTypeSuggestion');
  @override
  late final GeneratedColumn<String> paymentSourceTypeSuggestion =
      GeneratedColumn<String>(
        'payment_source_type_suggestion',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _paymentSourceIdSuggestionMeta =
      const VerificationMeta('paymentSourceIdSuggestion');
  @override
  late final GeneratedColumn<int> paymentSourceIdSuggestion =
      GeneratedColumn<int>(
        'payment_source_id_suggestion',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _detectedAtMeta = const VerificationMeta(
    'detectedAt',
  );
  @override
  late final GeneratedColumn<DateTime> detectedAt = GeneratedColumn<DateTime>(
    'detected_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transactionDateMeta = const VerificationMeta(
    'transactionDate',
  );
  @override
  late final GeneratedColumn<DateTime> transactionDate =
      GeneratedColumn<DateTime>(
        'transaction_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawTextMeta = const VerificationMeta(
    'rawText',
  );
  @override
  late final GeneratedColumn<String> rawText = GeneratedColumn<String>(
    'raw_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _confidenceScoreMeta = const VerificationMeta(
    'confidenceScore',
  );
  @override
  late final GeneratedColumn<double> confidenceScore = GeneratedColumn<double>(
    'confidence_score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _cashbackAmountMeta = const VerificationMeta(
    'cashbackAmount',
  );
  @override
  late final GeneratedColumn<double> cashbackAmount = GeneratedColumn<double>(
    'cashback_amount',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isForOthersMeta = const VerificationMeta(
    'isForOthers',
  );
  @override
  late final GeneratedColumn<bool> isForOthers = GeneratedColumn<bool>(
    'is_for_others',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_for_others" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _recoverableAmountMeta = const VerificationMeta(
    'recoverableAmount',
  );
  @override
  late final GeneratedColumn<double> recoverableAmount =
      GeneratedColumn<double>(
        'recoverable_amount',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _recoverableBaseAmountMeta =
      const VerificationMeta('recoverableBaseAmount');
  @override
  late final GeneratedColumn<double> recoverableBaseAmount =
      GeneratedColumn<double>(
        'recoverable_base_amount',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _recoveredAmountMeta = const VerificationMeta(
    'recoveredAmount',
  );
  @override
  late final GeneratedColumn<double> recoveredAmount = GeneratedColumn<double>(
    'recovered_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _recoverablePartyNameMeta =
      const VerificationMeta('recoverablePartyName');
  @override
  late final GeneratedColumn<String> recoverablePartyName =
      GeneratedColumn<String>(
        'recoverable_party_name',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _recoverablePartyNotesMeta =
      const VerificationMeta('recoverablePartyNotes');
  @override
  late final GeneratedColumn<String> recoverablePartyNotes =
      GeneratedColumn<String>(
        'recoverable_party_notes',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _recoverablePartyPhoneMeta =
      const VerificationMeta('recoverablePartyPhone');
  @override
  late final GeneratedColumn<String> recoverablePartyPhone =
      GeneratedColumn<String>(
        'recoverable_party_phone',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _duplicateOfTransactionIdMeta =
      const VerificationMeta('duplicateOfTransactionId');
  @override
  late final GeneratedColumn<int> duplicateOfTransactionId =
      GeneratedColumn<int>(
        'duplicate_of_transaction_id',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    amount,
    merchant,
    categorySuggestion,
    paymentSourceTypeSuggestion,
    paymentSourceIdSuggestion,
    detectedAt,
    transactionDate,
    sourceType,
    rawText,
    confidenceScore,
    status,
    cashbackAmount,
    isForOthers,
    recoverableAmount,
    recoverableBaseAmount,
    recoveredAmount,
    recoverablePartyName,
    recoverablePartyNotes,
    recoverablePartyPhone,
    notes,
    duplicateOfTransactionId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingTransaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('merchant')) {
      context.handle(
        _merchantMeta,
        merchant.isAcceptableOrUnknown(data['merchant']!, _merchantMeta),
      );
    } else if (isInserting) {
      context.missing(_merchantMeta);
    }
    if (data.containsKey('category_suggestion')) {
      context.handle(
        _categorySuggestionMeta,
        categorySuggestion.isAcceptableOrUnknown(
          data['category_suggestion']!,
          _categorySuggestionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_categorySuggestionMeta);
    }
    if (data.containsKey('payment_source_type_suggestion')) {
      context.handle(
        _paymentSourceTypeSuggestionMeta,
        paymentSourceTypeSuggestion.isAcceptableOrUnknown(
          data['payment_source_type_suggestion']!,
          _paymentSourceTypeSuggestionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paymentSourceTypeSuggestionMeta);
    }
    if (data.containsKey('payment_source_id_suggestion')) {
      context.handle(
        _paymentSourceIdSuggestionMeta,
        paymentSourceIdSuggestion.isAcceptableOrUnknown(
          data['payment_source_id_suggestion']!,
          _paymentSourceIdSuggestionMeta,
        ),
      );
    }
    if (data.containsKey('detected_at')) {
      context.handle(
        _detectedAtMeta,
        detectedAt.isAcceptableOrUnknown(data['detected_at']!, _detectedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_detectedAtMeta);
    }
    if (data.containsKey('transaction_date')) {
      context.handle(
        _transactionDateMeta,
        transactionDate.isAcceptableOrUnknown(
          data['transaction_date']!,
          _transactionDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionDateMeta);
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceTypeMeta);
    }
    if (data.containsKey('raw_text')) {
      context.handle(
        _rawTextMeta,
        rawText.isAcceptableOrUnknown(data['raw_text']!, _rawTextMeta),
      );
    } else if (isInserting) {
      context.missing(_rawTextMeta);
    }
    if (data.containsKey('confidence_score')) {
      context.handle(
        _confidenceScoreMeta,
        confidenceScore.isAcceptableOrUnknown(
          data['confidence_score']!,
          _confidenceScoreMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_confidenceScoreMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('cashback_amount')) {
      context.handle(
        _cashbackAmountMeta,
        cashbackAmount.isAcceptableOrUnknown(
          data['cashback_amount']!,
          _cashbackAmountMeta,
        ),
      );
    }
    if (data.containsKey('is_for_others')) {
      context.handle(
        _isForOthersMeta,
        isForOthers.isAcceptableOrUnknown(
          data['is_for_others']!,
          _isForOthersMeta,
        ),
      );
    }
    if (data.containsKey('recoverable_amount')) {
      context.handle(
        _recoverableAmountMeta,
        recoverableAmount.isAcceptableOrUnknown(
          data['recoverable_amount']!,
          _recoverableAmountMeta,
        ),
      );
    }
    if (data.containsKey('recoverable_base_amount')) {
      context.handle(
        _recoverableBaseAmountMeta,
        recoverableBaseAmount.isAcceptableOrUnknown(
          data['recoverable_base_amount']!,
          _recoverableBaseAmountMeta,
        ),
      );
    }
    if (data.containsKey('recovered_amount')) {
      context.handle(
        _recoveredAmountMeta,
        recoveredAmount.isAcceptableOrUnknown(
          data['recovered_amount']!,
          _recoveredAmountMeta,
        ),
      );
    }
    if (data.containsKey('recoverable_party_name')) {
      context.handle(
        _recoverablePartyNameMeta,
        recoverablePartyName.isAcceptableOrUnknown(
          data['recoverable_party_name']!,
          _recoverablePartyNameMeta,
        ),
      );
    }
    if (data.containsKey('recoverable_party_notes')) {
      context.handle(
        _recoverablePartyNotesMeta,
        recoverablePartyNotes.isAcceptableOrUnknown(
          data['recoverable_party_notes']!,
          _recoverablePartyNotesMeta,
        ),
      );
    }
    if (data.containsKey('recoverable_party_phone')) {
      context.handle(
        _recoverablePartyPhoneMeta,
        recoverablePartyPhone.isAcceptableOrUnknown(
          data['recoverable_party_phone']!,
          _recoverablePartyPhoneMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('duplicate_of_transaction_id')) {
      context.handle(
        _duplicateOfTransactionIdMeta,
        duplicateOfTransactionId.isAcceptableOrUnknown(
          data['duplicate_of_transaction_id']!,
          _duplicateOfTransactionIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingTransaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingTransaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      merchant: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merchant'],
      )!,
      categorySuggestion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_suggestion'],
      )!,
      paymentSourceTypeSuggestion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_source_type_suggestion'],
      )!,
      paymentSourceIdSuggestion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}payment_source_id_suggestion'],
      ),
      detectedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}detected_at'],
      )!,
      transactionDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}transaction_date'],
      )!,
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      )!,
      rawText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_text'],
      )!,
      confidenceScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence_score'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      cashbackAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cashback_amount'],
      ),
      isForOthers: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_for_others'],
      )!,
      recoverableAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}recoverable_amount'],
      ),
      recoverableBaseAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}recoverable_base_amount'],
      ),
      recoveredAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}recovered_amount'],
      )!,
      recoverablePartyName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recoverable_party_name'],
      ),
      recoverablePartyNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recoverable_party_notes'],
      ),
      recoverablePartyPhone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recoverable_party_phone'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      duplicateOfTransactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duplicate_of_transaction_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PendingTransactionsTable createAlias(String alias) {
    return $PendingTransactionsTable(attachedDatabase, alias);
  }
}

class PendingTransaction extends DataClass
    implements Insertable<PendingTransaction> {
  final int id;
  final double amount;
  final String merchant;
  final String categorySuggestion;
  final String paymentSourceTypeSuggestion;
  final int? paymentSourceIdSuggestion;
  final DateTime detectedAt;
  final DateTime transactionDate;
  final String sourceType;
  final String rawText;
  final double confidenceScore;
  final String status;
  final double? cashbackAmount;
  final bool isForOthers;
  final double? recoverableAmount;
  final double? recoverableBaseAmount;
  final double recoveredAmount;
  final String? recoverablePartyName;
  final String? recoverablePartyNotes;
  final String? recoverablePartyPhone;
  final String? notes;
  final int? duplicateOfTransactionId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PendingTransaction({
    required this.id,
    required this.amount,
    required this.merchant,
    required this.categorySuggestion,
    required this.paymentSourceTypeSuggestion,
    this.paymentSourceIdSuggestion,
    required this.detectedAt,
    required this.transactionDate,
    required this.sourceType,
    required this.rawText,
    required this.confidenceScore,
    required this.status,
    this.cashbackAmount,
    required this.isForOthers,
    this.recoverableAmount,
    this.recoverableBaseAmount,
    required this.recoveredAmount,
    this.recoverablePartyName,
    this.recoverablePartyNotes,
    this.recoverablePartyPhone,
    this.notes,
    this.duplicateOfTransactionId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['amount'] = Variable<double>(amount);
    map['merchant'] = Variable<String>(merchant);
    map['category_suggestion'] = Variable<String>(categorySuggestion);
    map['payment_source_type_suggestion'] = Variable<String>(
      paymentSourceTypeSuggestion,
    );
    if (!nullToAbsent || paymentSourceIdSuggestion != null) {
      map['payment_source_id_suggestion'] = Variable<int>(
        paymentSourceIdSuggestion,
      );
    }
    map['detected_at'] = Variable<DateTime>(detectedAt);
    map['transaction_date'] = Variable<DateTime>(transactionDate);
    map['source_type'] = Variable<String>(sourceType);
    map['raw_text'] = Variable<String>(rawText);
    map['confidence_score'] = Variable<double>(confidenceScore);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || cashbackAmount != null) {
      map['cashback_amount'] = Variable<double>(cashbackAmount);
    }
    map['is_for_others'] = Variable<bool>(isForOthers);
    if (!nullToAbsent || recoverableAmount != null) {
      map['recoverable_amount'] = Variable<double>(recoverableAmount);
    }
    if (!nullToAbsent || recoverableBaseAmount != null) {
      map['recoverable_base_amount'] = Variable<double>(recoverableBaseAmount);
    }
    map['recovered_amount'] = Variable<double>(recoveredAmount);
    if (!nullToAbsent || recoverablePartyName != null) {
      map['recoverable_party_name'] = Variable<String>(recoverablePartyName);
    }
    if (!nullToAbsent || recoverablePartyNotes != null) {
      map['recoverable_party_notes'] = Variable<String>(recoverablePartyNotes);
    }
    if (!nullToAbsent || recoverablePartyPhone != null) {
      map['recoverable_party_phone'] = Variable<String>(recoverablePartyPhone);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || duplicateOfTransactionId != null) {
      map['duplicate_of_transaction_id'] = Variable<int>(
        duplicateOfTransactionId,
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PendingTransactionsCompanion toCompanion(bool nullToAbsent) {
    return PendingTransactionsCompanion(
      id: Value(id),
      amount: Value(amount),
      merchant: Value(merchant),
      categorySuggestion: Value(categorySuggestion),
      paymentSourceTypeSuggestion: Value(paymentSourceTypeSuggestion),
      paymentSourceIdSuggestion:
          paymentSourceIdSuggestion == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentSourceIdSuggestion),
      detectedAt: Value(detectedAt),
      transactionDate: Value(transactionDate),
      sourceType: Value(sourceType),
      rawText: Value(rawText),
      confidenceScore: Value(confidenceScore),
      status: Value(status),
      cashbackAmount: cashbackAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(cashbackAmount),
      isForOthers: Value(isForOthers),
      recoverableAmount: recoverableAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(recoverableAmount),
      recoverableBaseAmount: recoverableBaseAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(recoverableBaseAmount),
      recoveredAmount: Value(recoveredAmount),
      recoverablePartyName: recoverablePartyName == null && nullToAbsent
          ? const Value.absent()
          : Value(recoverablePartyName),
      recoverablePartyNotes: recoverablePartyNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(recoverablePartyNotes),
      recoverablePartyPhone: recoverablePartyPhone == null && nullToAbsent
          ? const Value.absent()
          : Value(recoverablePartyPhone),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      duplicateOfTransactionId: duplicateOfTransactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(duplicateOfTransactionId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PendingTransaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingTransaction(
      id: serializer.fromJson<int>(json['id']),
      amount: serializer.fromJson<double>(json['amount']),
      merchant: serializer.fromJson<String>(json['merchant']),
      categorySuggestion: serializer.fromJson<String>(
        json['categorySuggestion'],
      ),
      paymentSourceTypeSuggestion: serializer.fromJson<String>(
        json['paymentSourceTypeSuggestion'],
      ),
      paymentSourceIdSuggestion: serializer.fromJson<int?>(
        json['paymentSourceIdSuggestion'],
      ),
      detectedAt: serializer.fromJson<DateTime>(json['detectedAt']),
      transactionDate: serializer.fromJson<DateTime>(json['transactionDate']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      rawText: serializer.fromJson<String>(json['rawText']),
      confidenceScore: serializer.fromJson<double>(json['confidenceScore']),
      status: serializer.fromJson<String>(json['status']),
      cashbackAmount: serializer.fromJson<double?>(json['cashbackAmount']),
      isForOthers: serializer.fromJson<bool>(json['isForOthers']),
      recoverableAmount: serializer.fromJson<double?>(
        json['recoverableAmount'],
      ),
      recoverableBaseAmount: serializer.fromJson<double?>(
        json['recoverableBaseAmount'],
      ),
      recoveredAmount: serializer.fromJson<double>(json['recoveredAmount']),
      recoverablePartyName: serializer.fromJson<String?>(
        json['recoverablePartyName'],
      ),
      recoverablePartyNotes: serializer.fromJson<String?>(
        json['recoverablePartyNotes'],
      ),
      recoverablePartyPhone: serializer.fromJson<String?>(
        json['recoverablePartyPhone'],
      ),
      notes: serializer.fromJson<String?>(json['notes']),
      duplicateOfTransactionId: serializer.fromJson<int?>(
        json['duplicateOfTransactionId'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'amount': serializer.toJson<double>(amount),
      'merchant': serializer.toJson<String>(merchant),
      'categorySuggestion': serializer.toJson<String>(categorySuggestion),
      'paymentSourceTypeSuggestion': serializer.toJson<String>(
        paymentSourceTypeSuggestion,
      ),
      'paymentSourceIdSuggestion': serializer.toJson<int?>(
        paymentSourceIdSuggestion,
      ),
      'detectedAt': serializer.toJson<DateTime>(detectedAt),
      'transactionDate': serializer.toJson<DateTime>(transactionDate),
      'sourceType': serializer.toJson<String>(sourceType),
      'rawText': serializer.toJson<String>(rawText),
      'confidenceScore': serializer.toJson<double>(confidenceScore),
      'status': serializer.toJson<String>(status),
      'cashbackAmount': serializer.toJson<double?>(cashbackAmount),
      'isForOthers': serializer.toJson<bool>(isForOthers),
      'recoverableAmount': serializer.toJson<double?>(recoverableAmount),
      'recoverableBaseAmount': serializer.toJson<double?>(
        recoverableBaseAmount,
      ),
      'recoveredAmount': serializer.toJson<double>(recoveredAmount),
      'recoverablePartyName': serializer.toJson<String?>(recoverablePartyName),
      'recoverablePartyNotes': serializer.toJson<String?>(
        recoverablePartyNotes,
      ),
      'recoverablePartyPhone': serializer.toJson<String?>(
        recoverablePartyPhone,
      ),
      'notes': serializer.toJson<String?>(notes),
      'duplicateOfTransactionId': serializer.toJson<int?>(
        duplicateOfTransactionId,
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PendingTransaction copyWith({
    int? id,
    double? amount,
    String? merchant,
    String? categorySuggestion,
    String? paymentSourceTypeSuggestion,
    Value<int?> paymentSourceIdSuggestion = const Value.absent(),
    DateTime? detectedAt,
    DateTime? transactionDate,
    String? sourceType,
    String? rawText,
    double? confidenceScore,
    String? status,
    Value<double?> cashbackAmount = const Value.absent(),
    bool? isForOthers,
    Value<double?> recoverableAmount = const Value.absent(),
    Value<double?> recoverableBaseAmount = const Value.absent(),
    double? recoveredAmount,
    Value<String?> recoverablePartyName = const Value.absent(),
    Value<String?> recoverablePartyNotes = const Value.absent(),
    Value<String?> recoverablePartyPhone = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<int?> duplicateOfTransactionId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PendingTransaction(
    id: id ?? this.id,
    amount: amount ?? this.amount,
    merchant: merchant ?? this.merchant,
    categorySuggestion: categorySuggestion ?? this.categorySuggestion,
    paymentSourceTypeSuggestion:
        paymentSourceTypeSuggestion ?? this.paymentSourceTypeSuggestion,
    paymentSourceIdSuggestion: paymentSourceIdSuggestion.present
        ? paymentSourceIdSuggestion.value
        : this.paymentSourceIdSuggestion,
    detectedAt: detectedAt ?? this.detectedAt,
    transactionDate: transactionDate ?? this.transactionDate,
    sourceType: sourceType ?? this.sourceType,
    rawText: rawText ?? this.rawText,
    confidenceScore: confidenceScore ?? this.confidenceScore,
    status: status ?? this.status,
    cashbackAmount: cashbackAmount.present
        ? cashbackAmount.value
        : this.cashbackAmount,
    isForOthers: isForOthers ?? this.isForOthers,
    recoverableAmount: recoverableAmount.present
        ? recoverableAmount.value
        : this.recoverableAmount,
    recoverableBaseAmount: recoverableBaseAmount.present
        ? recoverableBaseAmount.value
        : this.recoverableBaseAmount,
    recoveredAmount: recoveredAmount ?? this.recoveredAmount,
    recoverablePartyName: recoverablePartyName.present
        ? recoverablePartyName.value
        : this.recoverablePartyName,
    recoverablePartyNotes: recoverablePartyNotes.present
        ? recoverablePartyNotes.value
        : this.recoverablePartyNotes,
    recoverablePartyPhone: recoverablePartyPhone.present
        ? recoverablePartyPhone.value
        : this.recoverablePartyPhone,
    notes: notes.present ? notes.value : this.notes,
    duplicateOfTransactionId: duplicateOfTransactionId.present
        ? duplicateOfTransactionId.value
        : this.duplicateOfTransactionId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PendingTransaction copyWithCompanion(PendingTransactionsCompanion data) {
    return PendingTransaction(
      id: data.id.present ? data.id.value : this.id,
      amount: data.amount.present ? data.amount.value : this.amount,
      merchant: data.merchant.present ? data.merchant.value : this.merchant,
      categorySuggestion: data.categorySuggestion.present
          ? data.categorySuggestion.value
          : this.categorySuggestion,
      paymentSourceTypeSuggestion: data.paymentSourceTypeSuggestion.present
          ? data.paymentSourceTypeSuggestion.value
          : this.paymentSourceTypeSuggestion,
      paymentSourceIdSuggestion: data.paymentSourceIdSuggestion.present
          ? data.paymentSourceIdSuggestion.value
          : this.paymentSourceIdSuggestion,
      detectedAt: data.detectedAt.present
          ? data.detectedAt.value
          : this.detectedAt,
      transactionDate: data.transactionDate.present
          ? data.transactionDate.value
          : this.transactionDate,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      rawText: data.rawText.present ? data.rawText.value : this.rawText,
      confidenceScore: data.confidenceScore.present
          ? data.confidenceScore.value
          : this.confidenceScore,
      status: data.status.present ? data.status.value : this.status,
      cashbackAmount: data.cashbackAmount.present
          ? data.cashbackAmount.value
          : this.cashbackAmount,
      isForOthers: data.isForOthers.present
          ? data.isForOthers.value
          : this.isForOthers,
      recoverableAmount: data.recoverableAmount.present
          ? data.recoverableAmount.value
          : this.recoverableAmount,
      recoverableBaseAmount: data.recoverableBaseAmount.present
          ? data.recoverableBaseAmount.value
          : this.recoverableBaseAmount,
      recoveredAmount: data.recoveredAmount.present
          ? data.recoveredAmount.value
          : this.recoveredAmount,
      recoverablePartyName: data.recoverablePartyName.present
          ? data.recoverablePartyName.value
          : this.recoverablePartyName,
      recoverablePartyNotes: data.recoverablePartyNotes.present
          ? data.recoverablePartyNotes.value
          : this.recoverablePartyNotes,
      recoverablePartyPhone: data.recoverablePartyPhone.present
          ? data.recoverablePartyPhone.value
          : this.recoverablePartyPhone,
      notes: data.notes.present ? data.notes.value : this.notes,
      duplicateOfTransactionId: data.duplicateOfTransactionId.present
          ? data.duplicateOfTransactionId.value
          : this.duplicateOfTransactionId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingTransaction(')
          ..write('id: $id, ')
          ..write('amount: $amount, ')
          ..write('merchant: $merchant, ')
          ..write('categorySuggestion: $categorySuggestion, ')
          ..write('paymentSourceTypeSuggestion: $paymentSourceTypeSuggestion, ')
          ..write('paymentSourceIdSuggestion: $paymentSourceIdSuggestion, ')
          ..write('detectedAt: $detectedAt, ')
          ..write('transactionDate: $transactionDate, ')
          ..write('sourceType: $sourceType, ')
          ..write('rawText: $rawText, ')
          ..write('confidenceScore: $confidenceScore, ')
          ..write('status: $status, ')
          ..write('cashbackAmount: $cashbackAmount, ')
          ..write('isForOthers: $isForOthers, ')
          ..write('recoverableAmount: $recoverableAmount, ')
          ..write('recoverableBaseAmount: $recoverableBaseAmount, ')
          ..write('recoveredAmount: $recoveredAmount, ')
          ..write('recoverablePartyName: $recoverablePartyName, ')
          ..write('recoverablePartyNotes: $recoverablePartyNotes, ')
          ..write('recoverablePartyPhone: $recoverablePartyPhone, ')
          ..write('notes: $notes, ')
          ..write('duplicateOfTransactionId: $duplicateOfTransactionId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    amount,
    merchant,
    categorySuggestion,
    paymentSourceTypeSuggestion,
    paymentSourceIdSuggestion,
    detectedAt,
    transactionDate,
    sourceType,
    rawText,
    confidenceScore,
    status,
    cashbackAmount,
    isForOthers,
    recoverableAmount,
    recoverableBaseAmount,
    recoveredAmount,
    recoverablePartyName,
    recoverablePartyNotes,
    recoverablePartyPhone,
    notes,
    duplicateOfTransactionId,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingTransaction &&
          other.id == this.id &&
          other.amount == this.amount &&
          other.merchant == this.merchant &&
          other.categorySuggestion == this.categorySuggestion &&
          other.paymentSourceTypeSuggestion ==
              this.paymentSourceTypeSuggestion &&
          other.paymentSourceIdSuggestion == this.paymentSourceIdSuggestion &&
          other.detectedAt == this.detectedAt &&
          other.transactionDate == this.transactionDate &&
          other.sourceType == this.sourceType &&
          other.rawText == this.rawText &&
          other.confidenceScore == this.confidenceScore &&
          other.status == this.status &&
          other.cashbackAmount == this.cashbackAmount &&
          other.isForOthers == this.isForOthers &&
          other.recoverableAmount == this.recoverableAmount &&
          other.recoverableBaseAmount == this.recoverableBaseAmount &&
          other.recoveredAmount == this.recoveredAmount &&
          other.recoverablePartyName == this.recoverablePartyName &&
          other.recoverablePartyNotes == this.recoverablePartyNotes &&
          other.recoverablePartyPhone == this.recoverablePartyPhone &&
          other.notes == this.notes &&
          other.duplicateOfTransactionId == this.duplicateOfTransactionId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PendingTransactionsCompanion extends UpdateCompanion<PendingTransaction> {
  final Value<int> id;
  final Value<double> amount;
  final Value<String> merchant;
  final Value<String> categorySuggestion;
  final Value<String> paymentSourceTypeSuggestion;
  final Value<int?> paymentSourceIdSuggestion;
  final Value<DateTime> detectedAt;
  final Value<DateTime> transactionDate;
  final Value<String> sourceType;
  final Value<String> rawText;
  final Value<double> confidenceScore;
  final Value<String> status;
  final Value<double?> cashbackAmount;
  final Value<bool> isForOthers;
  final Value<double?> recoverableAmount;
  final Value<double?> recoverableBaseAmount;
  final Value<double> recoveredAmount;
  final Value<String?> recoverablePartyName;
  final Value<String?> recoverablePartyNotes;
  final Value<String?> recoverablePartyPhone;
  final Value<String?> notes;
  final Value<int?> duplicateOfTransactionId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const PendingTransactionsCompanion({
    this.id = const Value.absent(),
    this.amount = const Value.absent(),
    this.merchant = const Value.absent(),
    this.categorySuggestion = const Value.absent(),
    this.paymentSourceTypeSuggestion = const Value.absent(),
    this.paymentSourceIdSuggestion = const Value.absent(),
    this.detectedAt = const Value.absent(),
    this.transactionDate = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.rawText = const Value.absent(),
    this.confidenceScore = const Value.absent(),
    this.status = const Value.absent(),
    this.cashbackAmount = const Value.absent(),
    this.isForOthers = const Value.absent(),
    this.recoverableAmount = const Value.absent(),
    this.recoverableBaseAmount = const Value.absent(),
    this.recoveredAmount = const Value.absent(),
    this.recoverablePartyName = const Value.absent(),
    this.recoverablePartyNotes = const Value.absent(),
    this.recoverablePartyPhone = const Value.absent(),
    this.notes = const Value.absent(),
    this.duplicateOfTransactionId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PendingTransactionsCompanion.insert({
    this.id = const Value.absent(),
    required double amount,
    required String merchant,
    required String categorySuggestion,
    required String paymentSourceTypeSuggestion,
    this.paymentSourceIdSuggestion = const Value.absent(),
    required DateTime detectedAt,
    required DateTime transactionDate,
    required String sourceType,
    required String rawText,
    required double confidenceScore,
    this.status = const Value.absent(),
    this.cashbackAmount = const Value.absent(),
    this.isForOthers = const Value.absent(),
    this.recoverableAmount = const Value.absent(),
    this.recoverableBaseAmount = const Value.absent(),
    this.recoveredAmount = const Value.absent(),
    this.recoverablePartyName = const Value.absent(),
    this.recoverablePartyNotes = const Value.absent(),
    this.recoverablePartyPhone = const Value.absent(),
    this.notes = const Value.absent(),
    this.duplicateOfTransactionId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : amount = Value(amount),
       merchant = Value(merchant),
       categorySuggestion = Value(categorySuggestion),
       paymentSourceTypeSuggestion = Value(paymentSourceTypeSuggestion),
       detectedAt = Value(detectedAt),
       transactionDate = Value(transactionDate),
       sourceType = Value(sourceType),
       rawText = Value(rawText),
       confidenceScore = Value(confidenceScore);
  static Insertable<PendingTransaction> custom({
    Expression<int>? id,
    Expression<double>? amount,
    Expression<String>? merchant,
    Expression<String>? categorySuggestion,
    Expression<String>? paymentSourceTypeSuggestion,
    Expression<int>? paymentSourceIdSuggestion,
    Expression<DateTime>? detectedAt,
    Expression<DateTime>? transactionDate,
    Expression<String>? sourceType,
    Expression<String>? rawText,
    Expression<double>? confidenceScore,
    Expression<String>? status,
    Expression<double>? cashbackAmount,
    Expression<bool>? isForOthers,
    Expression<double>? recoverableAmount,
    Expression<double>? recoverableBaseAmount,
    Expression<double>? recoveredAmount,
    Expression<String>? recoverablePartyName,
    Expression<String>? recoverablePartyNotes,
    Expression<String>? recoverablePartyPhone,
    Expression<String>? notes,
    Expression<int>? duplicateOfTransactionId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (amount != null) 'amount': amount,
      if (merchant != null) 'merchant': merchant,
      if (categorySuggestion != null) 'category_suggestion': categorySuggestion,
      if (paymentSourceTypeSuggestion != null)
        'payment_source_type_suggestion': paymentSourceTypeSuggestion,
      if (paymentSourceIdSuggestion != null)
        'payment_source_id_suggestion': paymentSourceIdSuggestion,
      if (detectedAt != null) 'detected_at': detectedAt,
      if (transactionDate != null) 'transaction_date': transactionDate,
      if (sourceType != null) 'source_type': sourceType,
      if (rawText != null) 'raw_text': rawText,
      if (confidenceScore != null) 'confidence_score': confidenceScore,
      if (status != null) 'status': status,
      if (cashbackAmount != null) 'cashback_amount': cashbackAmount,
      if (isForOthers != null) 'is_for_others': isForOthers,
      if (recoverableAmount != null) 'recoverable_amount': recoverableAmount,
      if (recoverableBaseAmount != null)
        'recoverable_base_amount': recoverableBaseAmount,
      if (recoveredAmount != null) 'recovered_amount': recoveredAmount,
      if (recoverablePartyName != null)
        'recoverable_party_name': recoverablePartyName,
      if (recoverablePartyNotes != null)
        'recoverable_party_notes': recoverablePartyNotes,
      if (recoverablePartyPhone != null)
        'recoverable_party_phone': recoverablePartyPhone,
      if (notes != null) 'notes': notes,
      if (duplicateOfTransactionId != null)
        'duplicate_of_transaction_id': duplicateOfTransactionId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PendingTransactionsCompanion copyWith({
    Value<int>? id,
    Value<double>? amount,
    Value<String>? merchant,
    Value<String>? categorySuggestion,
    Value<String>? paymentSourceTypeSuggestion,
    Value<int?>? paymentSourceIdSuggestion,
    Value<DateTime>? detectedAt,
    Value<DateTime>? transactionDate,
    Value<String>? sourceType,
    Value<String>? rawText,
    Value<double>? confidenceScore,
    Value<String>? status,
    Value<double?>? cashbackAmount,
    Value<bool>? isForOthers,
    Value<double?>? recoverableAmount,
    Value<double?>? recoverableBaseAmount,
    Value<double>? recoveredAmount,
    Value<String?>? recoverablePartyName,
    Value<String?>? recoverablePartyNotes,
    Value<String?>? recoverablePartyPhone,
    Value<String?>? notes,
    Value<int?>? duplicateOfTransactionId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return PendingTransactionsCompanion(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      merchant: merchant ?? this.merchant,
      categorySuggestion: categorySuggestion ?? this.categorySuggestion,
      paymentSourceTypeSuggestion:
          paymentSourceTypeSuggestion ?? this.paymentSourceTypeSuggestion,
      paymentSourceIdSuggestion:
          paymentSourceIdSuggestion ?? this.paymentSourceIdSuggestion,
      detectedAt: detectedAt ?? this.detectedAt,
      transactionDate: transactionDate ?? this.transactionDate,
      sourceType: sourceType ?? this.sourceType,
      rawText: rawText ?? this.rawText,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      status: status ?? this.status,
      cashbackAmount: cashbackAmount ?? this.cashbackAmount,
      isForOthers: isForOthers ?? this.isForOthers,
      recoverableAmount: recoverableAmount ?? this.recoverableAmount,
      recoverableBaseAmount:
          recoverableBaseAmount ?? this.recoverableBaseAmount,
      recoveredAmount: recoveredAmount ?? this.recoveredAmount,
      recoverablePartyName: recoverablePartyName ?? this.recoverablePartyName,
      recoverablePartyNotes:
          recoverablePartyNotes ?? this.recoverablePartyNotes,
      recoverablePartyPhone:
          recoverablePartyPhone ?? this.recoverablePartyPhone,
      notes: notes ?? this.notes,
      duplicateOfTransactionId:
          duplicateOfTransactionId ?? this.duplicateOfTransactionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (merchant.present) {
      map['merchant'] = Variable<String>(merchant.value);
    }
    if (categorySuggestion.present) {
      map['category_suggestion'] = Variable<String>(categorySuggestion.value);
    }
    if (paymentSourceTypeSuggestion.present) {
      map['payment_source_type_suggestion'] = Variable<String>(
        paymentSourceTypeSuggestion.value,
      );
    }
    if (paymentSourceIdSuggestion.present) {
      map['payment_source_id_suggestion'] = Variable<int>(
        paymentSourceIdSuggestion.value,
      );
    }
    if (detectedAt.present) {
      map['detected_at'] = Variable<DateTime>(detectedAt.value);
    }
    if (transactionDate.present) {
      map['transaction_date'] = Variable<DateTime>(transactionDate.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (rawText.present) {
      map['raw_text'] = Variable<String>(rawText.value);
    }
    if (confidenceScore.present) {
      map['confidence_score'] = Variable<double>(confidenceScore.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (cashbackAmount.present) {
      map['cashback_amount'] = Variable<double>(cashbackAmount.value);
    }
    if (isForOthers.present) {
      map['is_for_others'] = Variable<bool>(isForOthers.value);
    }
    if (recoverableAmount.present) {
      map['recoverable_amount'] = Variable<double>(recoverableAmount.value);
    }
    if (recoverableBaseAmount.present) {
      map['recoverable_base_amount'] = Variable<double>(
        recoverableBaseAmount.value,
      );
    }
    if (recoveredAmount.present) {
      map['recovered_amount'] = Variable<double>(recoveredAmount.value);
    }
    if (recoverablePartyName.present) {
      map['recoverable_party_name'] = Variable<String>(
        recoverablePartyName.value,
      );
    }
    if (recoverablePartyNotes.present) {
      map['recoverable_party_notes'] = Variable<String>(
        recoverablePartyNotes.value,
      );
    }
    if (recoverablePartyPhone.present) {
      map['recoverable_party_phone'] = Variable<String>(
        recoverablePartyPhone.value,
      );
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (duplicateOfTransactionId.present) {
      map['duplicate_of_transaction_id'] = Variable<int>(
        duplicateOfTransactionId.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingTransactionsCompanion(')
          ..write('id: $id, ')
          ..write('amount: $amount, ')
          ..write('merchant: $merchant, ')
          ..write('categorySuggestion: $categorySuggestion, ')
          ..write('paymentSourceTypeSuggestion: $paymentSourceTypeSuggestion, ')
          ..write('paymentSourceIdSuggestion: $paymentSourceIdSuggestion, ')
          ..write('detectedAt: $detectedAt, ')
          ..write('transactionDate: $transactionDate, ')
          ..write('sourceType: $sourceType, ')
          ..write('rawText: $rawText, ')
          ..write('confidenceScore: $confidenceScore, ')
          ..write('status: $status, ')
          ..write('cashbackAmount: $cashbackAmount, ')
          ..write('isForOthers: $isForOthers, ')
          ..write('recoverableAmount: $recoverableAmount, ')
          ..write('recoverableBaseAmount: $recoverableBaseAmount, ')
          ..write('recoveredAmount: $recoveredAmount, ')
          ..write('recoverablePartyName: $recoverablePartyName, ')
          ..write('recoverablePartyNotes: $recoverablePartyNotes, ')
          ..write('recoverablePartyPhone: $recoverablePartyPhone, ')
          ..write('notes: $notes, ')
          ..write('duplicateOfTransactionId: $duplicateOfTransactionId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $CardBillsTable extends CardBills
    with TableInfo<$CardBillsTable, CardBill> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CardBillsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<int> cardId = GeneratedColumn<int>(
    'card_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cycleStartDateMeta = const VerificationMeta(
    'cycleStartDate',
  );
  @override
  late final GeneratedColumn<DateTime> cycleStartDate =
      GeneratedColumn<DateTime>(
        'cycle_start_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  static const VerificationMeta _cycleEndDateMeta = const VerificationMeta(
    'cycleEndDate',
  );
  @override
  late final GeneratedColumn<DateTime> cycleEndDate = GeneratedColumn<DateTime>(
    'cycle_end_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _billingDateMeta = const VerificationMeta(
    'billingDate',
  );
  @override
  late final GeneratedColumn<DateTime> billingDate = GeneratedColumn<DateTime>(
    'billing_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _billedAmountMeta = const VerificationMeta(
    'billedAmount',
  );
  @override
  late final GeneratedColumn<double> billedAmount = GeneratedColumn<double>(
    'billed_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paidAmountMeta = const VerificationMeta(
    'paidAmount',
  );
  @override
  late final GeneratedColumn<double> paidAmount = GeneratedColumn<double>(
    'paid_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
    'due_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('upcoming'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _paidAtMeta = const VerificationMeta('paidAt');
  @override
  late final GeneratedColumn<DateTime> paidAt = GeneratedColumn<DateTime>(
    'paid_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cardId,
    cycleStartDate,
    cycleEndDate,
    billingDate,
    billedAmount,
    paidAmount,
    dueDate,
    status,
    createdAt,
    paidAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'card_bills';
  @override
  VerificationContext validateIntegrity(
    Insertable<CardBill> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('card_id')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    if (data.containsKey('cycle_start_date')) {
      context.handle(
        _cycleStartDateMeta,
        cycleStartDate.isAcceptableOrUnknown(
          data['cycle_start_date']!,
          _cycleStartDateMeta,
        ),
      );
    }
    if (data.containsKey('cycle_end_date')) {
      context.handle(
        _cycleEndDateMeta,
        cycleEndDate.isAcceptableOrUnknown(
          data['cycle_end_date']!,
          _cycleEndDateMeta,
        ),
      );
    }
    if (data.containsKey('billing_date')) {
      context.handle(
        _billingDateMeta,
        billingDate.isAcceptableOrUnknown(
          data['billing_date']!,
          _billingDateMeta,
        ),
      );
    }
    if (data.containsKey('billed_amount')) {
      context.handle(
        _billedAmountMeta,
        billedAmount.isAcceptableOrUnknown(
          data['billed_amount']!,
          _billedAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_billedAmountMeta);
    }
    if (data.containsKey('paid_amount')) {
      context.handle(
        _paidAmountMeta,
        paidAmount.isAcceptableOrUnknown(data['paid_amount']!, _paidAmountMeta),
      );
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('paid_at')) {
      context.handle(
        _paidAtMeta,
        paidAt.isAcceptableOrUnknown(data['paid_at']!, _paidAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CardBill map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CardBill(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}card_id'],
      )!,
      cycleStartDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cycle_start_date'],
      )!,
      cycleEndDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cycle_end_date'],
      )!,
      billingDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}billing_date'],
      )!,
      billedAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}billed_amount'],
      )!,
      paidAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}paid_amount'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_date'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      paidAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}paid_at'],
      ),
    );
  }

  @override
  $CardBillsTable createAlias(String alias) {
    return $CardBillsTable(attachedDatabase, alias);
  }
}

class CardBill extends DataClass implements Insertable<CardBill> {
  final int id;
  final int cardId;
  final DateTime cycleStartDate;
  final DateTime cycleEndDate;
  final DateTime billingDate;
  final double billedAmount;
  final double paidAmount;
  final DateTime dueDate;
  final String status;
  final DateTime createdAt;
  final DateTime? paidAt;
  const CardBill({
    required this.id,
    required this.cardId,
    required this.cycleStartDate,
    required this.cycleEndDate,
    required this.billingDate,
    required this.billedAmount,
    required this.paidAmount,
    required this.dueDate,
    required this.status,
    required this.createdAt,
    this.paidAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['card_id'] = Variable<int>(cardId);
    map['cycle_start_date'] = Variable<DateTime>(cycleStartDate);
    map['cycle_end_date'] = Variable<DateTime>(cycleEndDate);
    map['billing_date'] = Variable<DateTime>(billingDate);
    map['billed_amount'] = Variable<double>(billedAmount);
    map['paid_amount'] = Variable<double>(paidAmount);
    map['due_date'] = Variable<DateTime>(dueDate);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || paidAt != null) {
      map['paid_at'] = Variable<DateTime>(paidAt);
    }
    return map;
  }

  CardBillsCompanion toCompanion(bool nullToAbsent) {
    return CardBillsCompanion(
      id: Value(id),
      cardId: Value(cardId),
      cycleStartDate: Value(cycleStartDate),
      cycleEndDate: Value(cycleEndDate),
      billingDate: Value(billingDate),
      billedAmount: Value(billedAmount),
      paidAmount: Value(paidAmount),
      dueDate: Value(dueDate),
      status: Value(status),
      createdAt: Value(createdAt),
      paidAt: paidAt == null && nullToAbsent
          ? const Value.absent()
          : Value(paidAt),
    );
  }

  factory CardBill.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CardBill(
      id: serializer.fromJson<int>(json['id']),
      cardId: serializer.fromJson<int>(json['cardId']),
      cycleStartDate: serializer.fromJson<DateTime>(json['cycleStartDate']),
      cycleEndDate: serializer.fromJson<DateTime>(json['cycleEndDate']),
      billingDate: serializer.fromJson<DateTime>(json['billingDate']),
      billedAmount: serializer.fromJson<double>(json['billedAmount']),
      paidAmount: serializer.fromJson<double>(json['paidAmount']),
      dueDate: serializer.fromJson<DateTime>(json['dueDate']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      paidAt: serializer.fromJson<DateTime?>(json['paidAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cardId': serializer.toJson<int>(cardId),
      'cycleStartDate': serializer.toJson<DateTime>(cycleStartDate),
      'cycleEndDate': serializer.toJson<DateTime>(cycleEndDate),
      'billingDate': serializer.toJson<DateTime>(billingDate),
      'billedAmount': serializer.toJson<double>(billedAmount),
      'paidAmount': serializer.toJson<double>(paidAmount),
      'dueDate': serializer.toJson<DateTime>(dueDate),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'paidAt': serializer.toJson<DateTime?>(paidAt),
    };
  }

  CardBill copyWith({
    int? id,
    int? cardId,
    DateTime? cycleStartDate,
    DateTime? cycleEndDate,
    DateTime? billingDate,
    double? billedAmount,
    double? paidAmount,
    DateTime? dueDate,
    String? status,
    DateTime? createdAt,
    Value<DateTime?> paidAt = const Value.absent(),
  }) => CardBill(
    id: id ?? this.id,
    cardId: cardId ?? this.cardId,
    cycleStartDate: cycleStartDate ?? this.cycleStartDate,
    cycleEndDate: cycleEndDate ?? this.cycleEndDate,
    billingDate: billingDate ?? this.billingDate,
    billedAmount: billedAmount ?? this.billedAmount,
    paidAmount: paidAmount ?? this.paidAmount,
    dueDate: dueDate ?? this.dueDate,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    paidAt: paidAt.present ? paidAt.value : this.paidAt,
  );
  CardBill copyWithCompanion(CardBillsCompanion data) {
    return CardBill(
      id: data.id.present ? data.id.value : this.id,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      cycleStartDate: data.cycleStartDate.present
          ? data.cycleStartDate.value
          : this.cycleStartDate,
      cycleEndDate: data.cycleEndDate.present
          ? data.cycleEndDate.value
          : this.cycleEndDate,
      billingDate: data.billingDate.present
          ? data.billingDate.value
          : this.billingDate,
      billedAmount: data.billedAmount.present
          ? data.billedAmount.value
          : this.billedAmount,
      paidAmount: data.paidAmount.present
          ? data.paidAmount.value
          : this.paidAmount,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      paidAt: data.paidAt.present ? data.paidAt.value : this.paidAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CardBill(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('cycleStartDate: $cycleStartDate, ')
          ..write('cycleEndDate: $cycleEndDate, ')
          ..write('billingDate: $billingDate, ')
          ..write('billedAmount: $billedAmount, ')
          ..write('paidAmount: $paidAmount, ')
          ..write('dueDate: $dueDate, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('paidAt: $paidAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    cardId,
    cycleStartDate,
    cycleEndDate,
    billingDate,
    billedAmount,
    paidAmount,
    dueDate,
    status,
    createdAt,
    paidAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CardBill &&
          other.id == this.id &&
          other.cardId == this.cardId &&
          other.cycleStartDate == this.cycleStartDate &&
          other.cycleEndDate == this.cycleEndDate &&
          other.billingDate == this.billingDate &&
          other.billedAmount == this.billedAmount &&
          other.paidAmount == this.paidAmount &&
          other.dueDate == this.dueDate &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.paidAt == this.paidAt);
}

class CardBillsCompanion extends UpdateCompanion<CardBill> {
  final Value<int> id;
  final Value<int> cardId;
  final Value<DateTime> cycleStartDate;
  final Value<DateTime> cycleEndDate;
  final Value<DateTime> billingDate;
  final Value<double> billedAmount;
  final Value<double> paidAmount;
  final Value<DateTime> dueDate;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<DateTime?> paidAt;
  const CardBillsCompanion({
    this.id = const Value.absent(),
    this.cardId = const Value.absent(),
    this.cycleStartDate = const Value.absent(),
    this.cycleEndDate = const Value.absent(),
    this.billingDate = const Value.absent(),
    this.billedAmount = const Value.absent(),
    this.paidAmount = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.paidAt = const Value.absent(),
  });
  CardBillsCompanion.insert({
    this.id = const Value.absent(),
    required int cardId,
    this.cycleStartDate = const Value.absent(),
    this.cycleEndDate = const Value.absent(),
    this.billingDate = const Value.absent(),
    required double billedAmount,
    this.paidAmount = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.paidAt = const Value.absent(),
  }) : cardId = Value(cardId),
       billedAmount = Value(billedAmount);
  static Insertable<CardBill> custom({
    Expression<int>? id,
    Expression<int>? cardId,
    Expression<DateTime>? cycleStartDate,
    Expression<DateTime>? cycleEndDate,
    Expression<DateTime>? billingDate,
    Expression<double>? billedAmount,
    Expression<double>? paidAmount,
    Expression<DateTime>? dueDate,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? paidAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cardId != null) 'card_id': cardId,
      if (cycleStartDate != null) 'cycle_start_date': cycleStartDate,
      if (cycleEndDate != null) 'cycle_end_date': cycleEndDate,
      if (billingDate != null) 'billing_date': billingDate,
      if (billedAmount != null) 'billed_amount': billedAmount,
      if (paidAmount != null) 'paid_amount': paidAmount,
      if (dueDate != null) 'due_date': dueDate,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (paidAt != null) 'paid_at': paidAt,
    });
  }

  CardBillsCompanion copyWith({
    Value<int>? id,
    Value<int>? cardId,
    Value<DateTime>? cycleStartDate,
    Value<DateTime>? cycleEndDate,
    Value<DateTime>? billingDate,
    Value<double>? billedAmount,
    Value<double>? paidAmount,
    Value<DateTime>? dueDate,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<DateTime?>? paidAt,
  }) {
    return CardBillsCompanion(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      cycleStartDate: cycleStartDate ?? this.cycleStartDate,
      cycleEndDate: cycleEndDate ?? this.cycleEndDate,
      billingDate: billingDate ?? this.billingDate,
      billedAmount: billedAmount ?? this.billedAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      paidAt: paidAt ?? this.paidAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cardId.present) {
      map['card_id'] = Variable<int>(cardId.value);
    }
    if (cycleStartDate.present) {
      map['cycle_start_date'] = Variable<DateTime>(cycleStartDate.value);
    }
    if (cycleEndDate.present) {
      map['cycle_end_date'] = Variable<DateTime>(cycleEndDate.value);
    }
    if (billingDate.present) {
      map['billing_date'] = Variable<DateTime>(billingDate.value);
    }
    if (billedAmount.present) {
      map['billed_amount'] = Variable<double>(billedAmount.value);
    }
    if (paidAmount.present) {
      map['paid_amount'] = Variable<double>(paidAmount.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (paidAt.present) {
      map['paid_at'] = Variable<DateTime>(paidAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CardBillsCompanion(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('cycleStartDate: $cycleStartDate, ')
          ..write('cycleEndDate: $cycleEndDate, ')
          ..write('billingDate: $billingDate, ')
          ..write('billedAmount: $billedAmount, ')
          ..write('paidAmount: $paidAmount, ')
          ..write('dueDate: $dueDate, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('paidAt: $paidAt')
          ..write(')'))
        .toString();
  }
}

class $SplitGroupsTable extends SplitGroups
    with TableInfo<$SplitGroupsTable, SplitGroup> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SplitGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    createdAt,
    updatedAt,
    archivedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'split_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<SplitGroup> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SplitGroup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SplitGroup(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}archived_at'],
      ),
    );
  }

  @override
  $SplitGroupsTable createAlias(String alias) {
    return $SplitGroupsTable(attachedDatabase, alias);
  }
}

class SplitGroup extends DataClass implements Insertable<SplitGroup> {
  final int id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
  const SplitGroup({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.archivedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    return map;
  }

  SplitGroupsCompanion toCompanion(bool nullToAbsent) {
    return SplitGroupsCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
    );
  }

  factory SplitGroup.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SplitGroup(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
    };
  }

  SplitGroup copyWith({
    int? id,
    String? name,
    Value<String?> description = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> archivedAt = const Value.absent(),
  }) => SplitGroup(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
  );
  SplitGroup copyWithCompanion(SplitGroupsCompanion data) {
    return SplitGroup(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SplitGroup(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('archivedAt: $archivedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, description, createdAt, updatedAt, archivedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SplitGroup &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.archivedAt == this.archivedAt);
}

class SplitGroupsCompanion extends UpdateCompanion<SplitGroup> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> archivedAt;
  const SplitGroupsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
  });
  SplitGroupsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<SplitGroup> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? archivedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (archivedAt != null) 'archived_at': archivedAt,
    });
  }

  SplitGroupsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? archivedAt,
  }) {
    return SplitGroupsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SplitGroupsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('archivedAt: $archivedAt')
          ..write(')'))
        .toString();
  }
}

class $SplitMembersTable extends SplitMembers
    with TableInfo<$SplitMembersTable, SplitMember> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SplitMembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<int> groupId = GeneratedColumn<int>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contactMeta = const VerificationMeta(
    'contact',
  );
  @override
  late final GeneratedColumn<String> contact = GeneratedColumn<String>(
    'contact',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isCurrentUserMeta = const VerificationMeta(
    'isCurrentUser',
  );
  @override
  late final GeneratedColumn<bool> isCurrentUser = GeneratedColumn<bool>(
    'is_current_user',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_current_user" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    groupId,
    name,
    contact,
    isCurrentUser,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'split_members';
  @override
  VerificationContext validateIntegrity(
    Insertable<SplitMember> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('contact')) {
      context.handle(
        _contactMeta,
        contact.isAcceptableOrUnknown(data['contact']!, _contactMeta),
      );
    }
    if (data.containsKey('is_current_user')) {
      context.handle(
        _isCurrentUserMeta,
        isCurrentUser.isAcceptableOrUnknown(
          data['is_current_user']!,
          _isCurrentUserMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SplitMember map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SplitMember(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}group_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      contact: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact'],
      ),
      isCurrentUser: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_current_user'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SplitMembersTable createAlias(String alias) {
    return $SplitMembersTable(attachedDatabase, alias);
  }
}

class SplitMember extends DataClass implements Insertable<SplitMember> {
  final int id;
  final int groupId;
  final String name;
  final String? contact;
  final bool isCurrentUser;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SplitMember({
    required this.id,
    required this.groupId,
    required this.name,
    this.contact,
    required this.isCurrentUser,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['group_id'] = Variable<int>(groupId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || contact != null) {
      map['contact'] = Variable<String>(contact);
    }
    map['is_current_user'] = Variable<bool>(isCurrentUser);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SplitMembersCompanion toCompanion(bool nullToAbsent) {
    return SplitMembersCompanion(
      id: Value(id),
      groupId: Value(groupId),
      name: Value(name),
      contact: contact == null && nullToAbsent
          ? const Value.absent()
          : Value(contact),
      isCurrentUser: Value(isCurrentUser),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SplitMember.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SplitMember(
      id: serializer.fromJson<int>(json['id']),
      groupId: serializer.fromJson<int>(json['groupId']),
      name: serializer.fromJson<String>(json['name']),
      contact: serializer.fromJson<String?>(json['contact']),
      isCurrentUser: serializer.fromJson<bool>(json['isCurrentUser']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'groupId': serializer.toJson<int>(groupId),
      'name': serializer.toJson<String>(name),
      'contact': serializer.toJson<String?>(contact),
      'isCurrentUser': serializer.toJson<bool>(isCurrentUser),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SplitMember copyWith({
    int? id,
    int? groupId,
    String? name,
    Value<String?> contact = const Value.absent(),
    bool? isCurrentUser,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SplitMember(
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    name: name ?? this.name,
    contact: contact.present ? contact.value : this.contact,
    isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SplitMember copyWithCompanion(SplitMembersCompanion data) {
    return SplitMember(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      name: data.name.present ? data.name.value : this.name,
      contact: data.contact.present ? data.contact.value : this.contact,
      isCurrentUser: data.isCurrentUser.present
          ? data.isCurrentUser.value
          : this.isCurrentUser,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SplitMember(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('name: $name, ')
          ..write('contact: $contact, ')
          ..write('isCurrentUser: $isCurrentUser, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    groupId,
    name,
    contact,
    isCurrentUser,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SplitMember &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.name == this.name &&
          other.contact == this.contact &&
          other.isCurrentUser == this.isCurrentUser &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SplitMembersCompanion extends UpdateCompanion<SplitMember> {
  final Value<int> id;
  final Value<int> groupId;
  final Value<String> name;
  final Value<String?> contact;
  final Value<bool> isCurrentUser;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const SplitMembersCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.name = const Value.absent(),
    this.contact = const Value.absent(),
    this.isCurrentUser = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SplitMembersCompanion.insert({
    this.id = const Value.absent(),
    required int groupId,
    required String name,
    this.contact = const Value.absent(),
    this.isCurrentUser = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : groupId = Value(groupId),
       name = Value(name);
  static Insertable<SplitMember> custom({
    Expression<int>? id,
    Expression<int>? groupId,
    Expression<String>? name,
    Expression<String>? contact,
    Expression<bool>? isCurrentUser,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (name != null) 'name': name,
      if (contact != null) 'contact': contact,
      if (isCurrentUser != null) 'is_current_user': isCurrentUser,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SplitMembersCompanion copyWith({
    Value<int>? id,
    Value<int>? groupId,
    Value<String>? name,
    Value<String?>? contact,
    Value<bool>? isCurrentUser,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return SplitMembersCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      contact: contact ?? this.contact,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<int>(groupId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (contact.present) {
      map['contact'] = Variable<String>(contact.value);
    }
    if (isCurrentUser.present) {
      map['is_current_user'] = Variable<bool>(isCurrentUser.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SplitMembersCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('name: $name, ')
          ..write('contact: $contact, ')
          ..write('isCurrentUser: $isCurrentUser, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SplitExpensesTable extends SplitExpenses
    with TableInfo<$SplitExpensesTable, SplitExpense> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SplitExpensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<int> groupId = GeneratedColumn<int>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalAmountMeta = const VerificationMeta(
    'totalAmount',
  );
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
    'total_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paidByMemberIdMeta = const VerificationMeta(
    'paidByMemberId',
  );
  @override
  late final GeneratedColumn<int> paidByMemberId = GeneratedColumn<int>(
    'paid_by_member_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _splitTypeMeta = const VerificationMeta(
    'splitType',
  );
  @override
  late final GeneratedColumn<String> splitType = GeneratedColumn<String>(
    'split_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expenseDateMeta = const VerificationMeta(
    'expenseDate',
  );
  @override
  late final GeneratedColumn<DateTime> expenseDate = GeneratedColumn<DateTime>(
    'expense_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _linkedTransactionIdMeta =
      const VerificationMeta('linkedTransactionId');
  @override
  late final GeneratedColumn<int> linkedTransactionId = GeneratedColumn<int>(
    'linked_transaction_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    groupId,
    title,
    totalAmount,
    paidByMemberId,
    splitType,
    expenseDate,
    category,
    notes,
    linkedTransactionId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'split_expenses';
  @override
  VerificationContext validateIntegrity(
    Insertable<SplitExpense> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('total_amount')) {
      context.handle(
        _totalAmountMeta,
        totalAmount.isAcceptableOrUnknown(
          data['total_amount']!,
          _totalAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalAmountMeta);
    }
    if (data.containsKey('paid_by_member_id')) {
      context.handle(
        _paidByMemberIdMeta,
        paidByMemberId.isAcceptableOrUnknown(
          data['paid_by_member_id']!,
          _paidByMemberIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paidByMemberIdMeta);
    }
    if (data.containsKey('split_type')) {
      context.handle(
        _splitTypeMeta,
        splitType.isAcceptableOrUnknown(data['split_type']!, _splitTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_splitTypeMeta);
    }
    if (data.containsKey('expense_date')) {
      context.handle(
        _expenseDateMeta,
        expenseDate.isAcceptableOrUnknown(
          data['expense_date']!,
          _expenseDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_expenseDateMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('linked_transaction_id')) {
      context.handle(
        _linkedTransactionIdMeta,
        linkedTransactionId.isAcceptableOrUnknown(
          data['linked_transaction_id']!,
          _linkedTransactionIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SplitExpense map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SplitExpense(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}group_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      totalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_amount'],
      )!,
      paidByMemberId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}paid_by_member_id'],
      )!,
      splitType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}split_type'],
      )!,
      expenseDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expense_date'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      linkedTransactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}linked_transaction_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SplitExpensesTable createAlias(String alias) {
    return $SplitExpensesTable(attachedDatabase, alias);
  }
}

class SplitExpense extends DataClass implements Insertable<SplitExpense> {
  final int id;
  final int groupId;
  final String title;
  final double totalAmount;
  final int paidByMemberId;
  final String splitType;
  final DateTime expenseDate;
  final String category;
  final String? notes;
  final int? linkedTransactionId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SplitExpense({
    required this.id,
    required this.groupId,
    required this.title,
    required this.totalAmount,
    required this.paidByMemberId,
    required this.splitType,
    required this.expenseDate,
    required this.category,
    this.notes,
    this.linkedTransactionId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['group_id'] = Variable<int>(groupId);
    map['title'] = Variable<String>(title);
    map['total_amount'] = Variable<double>(totalAmount);
    map['paid_by_member_id'] = Variable<int>(paidByMemberId);
    map['split_type'] = Variable<String>(splitType);
    map['expense_date'] = Variable<DateTime>(expenseDate);
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || linkedTransactionId != null) {
      map['linked_transaction_id'] = Variable<int>(linkedTransactionId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SplitExpensesCompanion toCompanion(bool nullToAbsent) {
    return SplitExpensesCompanion(
      id: Value(id),
      groupId: Value(groupId),
      title: Value(title),
      totalAmount: Value(totalAmount),
      paidByMemberId: Value(paidByMemberId),
      splitType: Value(splitType),
      expenseDate: Value(expenseDate),
      category: Value(category),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      linkedTransactionId: linkedTransactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedTransactionId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SplitExpense.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SplitExpense(
      id: serializer.fromJson<int>(json['id']),
      groupId: serializer.fromJson<int>(json['groupId']),
      title: serializer.fromJson<String>(json['title']),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
      paidByMemberId: serializer.fromJson<int>(json['paidByMemberId']),
      splitType: serializer.fromJson<String>(json['splitType']),
      expenseDate: serializer.fromJson<DateTime>(json['expenseDate']),
      category: serializer.fromJson<String>(json['category']),
      notes: serializer.fromJson<String?>(json['notes']),
      linkedTransactionId: serializer.fromJson<int?>(
        json['linkedTransactionId'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'groupId': serializer.toJson<int>(groupId),
      'title': serializer.toJson<String>(title),
      'totalAmount': serializer.toJson<double>(totalAmount),
      'paidByMemberId': serializer.toJson<int>(paidByMemberId),
      'splitType': serializer.toJson<String>(splitType),
      'expenseDate': serializer.toJson<DateTime>(expenseDate),
      'category': serializer.toJson<String>(category),
      'notes': serializer.toJson<String?>(notes),
      'linkedTransactionId': serializer.toJson<int?>(linkedTransactionId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SplitExpense copyWith({
    int? id,
    int? groupId,
    String? title,
    double? totalAmount,
    int? paidByMemberId,
    String? splitType,
    DateTime? expenseDate,
    String? category,
    Value<String?> notes = const Value.absent(),
    Value<int?> linkedTransactionId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SplitExpense(
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    title: title ?? this.title,
    totalAmount: totalAmount ?? this.totalAmount,
    paidByMemberId: paidByMemberId ?? this.paidByMemberId,
    splitType: splitType ?? this.splitType,
    expenseDate: expenseDate ?? this.expenseDate,
    category: category ?? this.category,
    notes: notes.present ? notes.value : this.notes,
    linkedTransactionId: linkedTransactionId.present
        ? linkedTransactionId.value
        : this.linkedTransactionId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SplitExpense copyWithCompanion(SplitExpensesCompanion data) {
    return SplitExpense(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      title: data.title.present ? data.title.value : this.title,
      totalAmount: data.totalAmount.present
          ? data.totalAmount.value
          : this.totalAmount,
      paidByMemberId: data.paidByMemberId.present
          ? data.paidByMemberId.value
          : this.paidByMemberId,
      splitType: data.splitType.present ? data.splitType.value : this.splitType,
      expenseDate: data.expenseDate.present
          ? data.expenseDate.value
          : this.expenseDate,
      category: data.category.present ? data.category.value : this.category,
      notes: data.notes.present ? data.notes.value : this.notes,
      linkedTransactionId: data.linkedTransactionId.present
          ? data.linkedTransactionId.value
          : this.linkedTransactionId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SplitExpense(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('title: $title, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('paidByMemberId: $paidByMemberId, ')
          ..write('splitType: $splitType, ')
          ..write('expenseDate: $expenseDate, ')
          ..write('category: $category, ')
          ..write('notes: $notes, ')
          ..write('linkedTransactionId: $linkedTransactionId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    groupId,
    title,
    totalAmount,
    paidByMemberId,
    splitType,
    expenseDate,
    category,
    notes,
    linkedTransactionId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SplitExpense &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.title == this.title &&
          other.totalAmount == this.totalAmount &&
          other.paidByMemberId == this.paidByMemberId &&
          other.splitType == this.splitType &&
          other.expenseDate == this.expenseDate &&
          other.category == this.category &&
          other.notes == this.notes &&
          other.linkedTransactionId == this.linkedTransactionId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SplitExpensesCompanion extends UpdateCompanion<SplitExpense> {
  final Value<int> id;
  final Value<int> groupId;
  final Value<String> title;
  final Value<double> totalAmount;
  final Value<int> paidByMemberId;
  final Value<String> splitType;
  final Value<DateTime> expenseDate;
  final Value<String> category;
  final Value<String?> notes;
  final Value<int?> linkedTransactionId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const SplitExpensesCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.title = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.paidByMemberId = const Value.absent(),
    this.splitType = const Value.absent(),
    this.expenseDate = const Value.absent(),
    this.category = const Value.absent(),
    this.notes = const Value.absent(),
    this.linkedTransactionId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SplitExpensesCompanion.insert({
    this.id = const Value.absent(),
    required int groupId,
    required String title,
    required double totalAmount,
    required int paidByMemberId,
    required String splitType,
    required DateTime expenseDate,
    required String category,
    this.notes = const Value.absent(),
    this.linkedTransactionId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : groupId = Value(groupId),
       title = Value(title),
       totalAmount = Value(totalAmount),
       paidByMemberId = Value(paidByMemberId),
       splitType = Value(splitType),
       expenseDate = Value(expenseDate),
       category = Value(category);
  static Insertable<SplitExpense> custom({
    Expression<int>? id,
    Expression<int>? groupId,
    Expression<String>? title,
    Expression<double>? totalAmount,
    Expression<int>? paidByMemberId,
    Expression<String>? splitType,
    Expression<DateTime>? expenseDate,
    Expression<String>? category,
    Expression<String>? notes,
    Expression<int>? linkedTransactionId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (title != null) 'title': title,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (paidByMemberId != null) 'paid_by_member_id': paidByMemberId,
      if (splitType != null) 'split_type': splitType,
      if (expenseDate != null) 'expense_date': expenseDate,
      if (category != null) 'category': category,
      if (notes != null) 'notes': notes,
      if (linkedTransactionId != null)
        'linked_transaction_id': linkedTransactionId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SplitExpensesCompanion copyWith({
    Value<int>? id,
    Value<int>? groupId,
    Value<String>? title,
    Value<double>? totalAmount,
    Value<int>? paidByMemberId,
    Value<String>? splitType,
    Value<DateTime>? expenseDate,
    Value<String>? category,
    Value<String?>? notes,
    Value<int?>? linkedTransactionId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return SplitExpensesCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      title: title ?? this.title,
      totalAmount: totalAmount ?? this.totalAmount,
      paidByMemberId: paidByMemberId ?? this.paidByMemberId,
      splitType: splitType ?? this.splitType,
      expenseDate: expenseDate ?? this.expenseDate,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      linkedTransactionId: linkedTransactionId ?? this.linkedTransactionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<int>(groupId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (paidByMemberId.present) {
      map['paid_by_member_id'] = Variable<int>(paidByMemberId.value);
    }
    if (splitType.present) {
      map['split_type'] = Variable<String>(splitType.value);
    }
    if (expenseDate.present) {
      map['expense_date'] = Variable<DateTime>(expenseDate.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (linkedTransactionId.present) {
      map['linked_transaction_id'] = Variable<int>(linkedTransactionId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SplitExpensesCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('title: $title, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('paidByMemberId: $paidByMemberId, ')
          ..write('splitType: $splitType, ')
          ..write('expenseDate: $expenseDate, ')
          ..write('category: $category, ')
          ..write('notes: $notes, ')
          ..write('linkedTransactionId: $linkedTransactionId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SplitExpenseSharesTable extends SplitExpenseShares
    with TableInfo<$SplitExpenseSharesTable, SplitExpenseShare> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SplitExpenseSharesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _splitExpenseIdMeta = const VerificationMeta(
    'splitExpenseId',
  );
  @override
  late final GeneratedColumn<int> splitExpenseId = GeneratedColumn<int>(
    'split_expense_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<int> memberId = GeneratedColumn<int>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _percentageMeta = const VerificationMeta(
    'percentage',
  );
  @override
  late final GeneratedColumn<double> percentage = GeneratedColumn<double>(
    'percentage',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _exactAmountMeta = const VerificationMeta(
    'exactAmount',
  );
  @override
  late final GeneratedColumn<double> exactAmount = GeneratedColumn<double>(
    'exact_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isSettledMeta = const VerificationMeta(
    'isSettled',
  );
  @override
  late final GeneratedColumn<bool> isSettled = GeneratedColumn<bool>(
    'is_settled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_settled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    splitExpenseId,
    memberId,
    percentage,
    exactAmount,
    isSettled,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'split_expense_shares';
  @override
  VerificationContext validateIntegrity(
    Insertable<SplitExpenseShare> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('split_expense_id')) {
      context.handle(
        _splitExpenseIdMeta,
        splitExpenseId.isAcceptableOrUnknown(
          data['split_expense_id']!,
          _splitExpenseIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_splitExpenseIdMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('percentage')) {
      context.handle(
        _percentageMeta,
        percentage.isAcceptableOrUnknown(data['percentage']!, _percentageMeta),
      );
    }
    if (data.containsKey('exact_amount')) {
      context.handle(
        _exactAmountMeta,
        exactAmount.isAcceptableOrUnknown(
          data['exact_amount']!,
          _exactAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_exactAmountMeta);
    }
    if (data.containsKey('is_settled')) {
      context.handle(
        _isSettledMeta,
        isSettled.isAcceptableOrUnknown(data['is_settled']!, _isSettledMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SplitExpenseShare map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SplitExpenseShare(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      splitExpenseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}split_expense_id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}member_id'],
      )!,
      percentage: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}percentage'],
      ),
      exactAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}exact_amount'],
      )!,
      isSettled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_settled'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SplitExpenseSharesTable createAlias(String alias) {
    return $SplitExpenseSharesTable(attachedDatabase, alias);
  }
}

class SplitExpenseShare extends DataClass
    implements Insertable<SplitExpenseShare> {
  final int id;
  final int splitExpenseId;
  final int memberId;
  final double? percentage;
  final double exactAmount;
  final bool isSettled;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SplitExpenseShare({
    required this.id,
    required this.splitExpenseId,
    required this.memberId,
    this.percentage,
    required this.exactAmount,
    required this.isSettled,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['split_expense_id'] = Variable<int>(splitExpenseId);
    map['member_id'] = Variable<int>(memberId);
    if (!nullToAbsent || percentage != null) {
      map['percentage'] = Variable<double>(percentage);
    }
    map['exact_amount'] = Variable<double>(exactAmount);
    map['is_settled'] = Variable<bool>(isSettled);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SplitExpenseSharesCompanion toCompanion(bool nullToAbsent) {
    return SplitExpenseSharesCompanion(
      id: Value(id),
      splitExpenseId: Value(splitExpenseId),
      memberId: Value(memberId),
      percentage: percentage == null && nullToAbsent
          ? const Value.absent()
          : Value(percentage),
      exactAmount: Value(exactAmount),
      isSettled: Value(isSettled),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SplitExpenseShare.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SplitExpenseShare(
      id: serializer.fromJson<int>(json['id']),
      splitExpenseId: serializer.fromJson<int>(json['splitExpenseId']),
      memberId: serializer.fromJson<int>(json['memberId']),
      percentage: serializer.fromJson<double?>(json['percentage']),
      exactAmount: serializer.fromJson<double>(json['exactAmount']),
      isSettled: serializer.fromJson<bool>(json['isSettled']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'splitExpenseId': serializer.toJson<int>(splitExpenseId),
      'memberId': serializer.toJson<int>(memberId),
      'percentage': serializer.toJson<double?>(percentage),
      'exactAmount': serializer.toJson<double>(exactAmount),
      'isSettled': serializer.toJson<bool>(isSettled),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SplitExpenseShare copyWith({
    int? id,
    int? splitExpenseId,
    int? memberId,
    Value<double?> percentage = const Value.absent(),
    double? exactAmount,
    bool? isSettled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SplitExpenseShare(
    id: id ?? this.id,
    splitExpenseId: splitExpenseId ?? this.splitExpenseId,
    memberId: memberId ?? this.memberId,
    percentage: percentage.present ? percentage.value : this.percentage,
    exactAmount: exactAmount ?? this.exactAmount,
    isSettled: isSettled ?? this.isSettled,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SplitExpenseShare copyWithCompanion(SplitExpenseSharesCompanion data) {
    return SplitExpenseShare(
      id: data.id.present ? data.id.value : this.id,
      splitExpenseId: data.splitExpenseId.present
          ? data.splitExpenseId.value
          : this.splitExpenseId,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      percentage: data.percentage.present
          ? data.percentage.value
          : this.percentage,
      exactAmount: data.exactAmount.present
          ? data.exactAmount.value
          : this.exactAmount,
      isSettled: data.isSettled.present ? data.isSettled.value : this.isSettled,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SplitExpenseShare(')
          ..write('id: $id, ')
          ..write('splitExpenseId: $splitExpenseId, ')
          ..write('memberId: $memberId, ')
          ..write('percentage: $percentage, ')
          ..write('exactAmount: $exactAmount, ')
          ..write('isSettled: $isSettled, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    splitExpenseId,
    memberId,
    percentage,
    exactAmount,
    isSettled,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SplitExpenseShare &&
          other.id == this.id &&
          other.splitExpenseId == this.splitExpenseId &&
          other.memberId == this.memberId &&
          other.percentage == this.percentage &&
          other.exactAmount == this.exactAmount &&
          other.isSettled == this.isSettled &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SplitExpenseSharesCompanion extends UpdateCompanion<SplitExpenseShare> {
  final Value<int> id;
  final Value<int> splitExpenseId;
  final Value<int> memberId;
  final Value<double?> percentage;
  final Value<double> exactAmount;
  final Value<bool> isSettled;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const SplitExpenseSharesCompanion({
    this.id = const Value.absent(),
    this.splitExpenseId = const Value.absent(),
    this.memberId = const Value.absent(),
    this.percentage = const Value.absent(),
    this.exactAmount = const Value.absent(),
    this.isSettled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SplitExpenseSharesCompanion.insert({
    this.id = const Value.absent(),
    required int splitExpenseId,
    required int memberId,
    this.percentage = const Value.absent(),
    required double exactAmount,
    this.isSettled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : splitExpenseId = Value(splitExpenseId),
       memberId = Value(memberId),
       exactAmount = Value(exactAmount);
  static Insertable<SplitExpenseShare> custom({
    Expression<int>? id,
    Expression<int>? splitExpenseId,
    Expression<int>? memberId,
    Expression<double>? percentage,
    Expression<double>? exactAmount,
    Expression<bool>? isSettled,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (splitExpenseId != null) 'split_expense_id': splitExpenseId,
      if (memberId != null) 'member_id': memberId,
      if (percentage != null) 'percentage': percentage,
      if (exactAmount != null) 'exact_amount': exactAmount,
      if (isSettled != null) 'is_settled': isSettled,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SplitExpenseSharesCompanion copyWith({
    Value<int>? id,
    Value<int>? splitExpenseId,
    Value<int>? memberId,
    Value<double?>? percentage,
    Value<double>? exactAmount,
    Value<bool>? isSettled,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return SplitExpenseSharesCompanion(
      id: id ?? this.id,
      splitExpenseId: splitExpenseId ?? this.splitExpenseId,
      memberId: memberId ?? this.memberId,
      percentage: percentage ?? this.percentage,
      exactAmount: exactAmount ?? this.exactAmount,
      isSettled: isSettled ?? this.isSettled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (splitExpenseId.present) {
      map['split_expense_id'] = Variable<int>(splitExpenseId.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<int>(memberId.value);
    }
    if (percentage.present) {
      map['percentage'] = Variable<double>(percentage.value);
    }
    if (exactAmount.present) {
      map['exact_amount'] = Variable<double>(exactAmount.value);
    }
    if (isSettled.present) {
      map['is_settled'] = Variable<bool>(isSettled.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SplitExpenseSharesCompanion(')
          ..write('id: $id, ')
          ..write('splitExpenseId: $splitExpenseId, ')
          ..write('memberId: $memberId, ')
          ..write('percentage: $percentage, ')
          ..write('exactAmount: $exactAmount, ')
          ..write('isSettled: $isSettled, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SplitSettlementsTable extends SplitSettlements
    with TableInfo<$SplitSettlementsTable, SplitSettlement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SplitSettlementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<int> groupId = GeneratedColumn<int>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fromMemberIdMeta = const VerificationMeta(
    'fromMemberId',
  );
  @override
  late final GeneratedColumn<int> fromMemberId = GeneratedColumn<int>(
    'from_member_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toMemberIdMeta = const VerificationMeta(
    'toMemberId',
  );
  @override
  late final GeneratedColumn<int> toMemberId = GeneratedColumn<int>(
    'to_member_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paymentSourceTypeMeta = const VerificationMeta(
    'paymentSourceType',
  );
  @override
  late final GeneratedColumn<String> paymentSourceType =
      GeneratedColumn<String>(
        'payment_source_type',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _paymentSourceIdMeta = const VerificationMeta(
    'paymentSourceId',
  );
  @override
  late final GeneratedColumn<int> paymentSourceId = GeneratedColumn<int>(
    'payment_source_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _settlementDateMeta = const VerificationMeta(
    'settlementDate',
  );
  @override
  late final GeneratedColumn<DateTime> settlementDate =
      GeneratedColumn<DateTime>(
        'settlement_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _linkedTransactionIdMeta =
      const VerificationMeta('linkedTransactionId');
  @override
  late final GeneratedColumn<int> linkedTransactionId = GeneratedColumn<int>(
    'linked_transaction_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    groupId,
    fromMemberId,
    toMemberId,
    amount,
    paymentSourceType,
    paymentSourceId,
    settlementDate,
    linkedTransactionId,
    notes,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'split_settlements';
  @override
  VerificationContext validateIntegrity(
    Insertable<SplitSettlement> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('from_member_id')) {
      context.handle(
        _fromMemberIdMeta,
        fromMemberId.isAcceptableOrUnknown(
          data['from_member_id']!,
          _fromMemberIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fromMemberIdMeta);
    }
    if (data.containsKey('to_member_id')) {
      context.handle(
        _toMemberIdMeta,
        toMemberId.isAcceptableOrUnknown(
          data['to_member_id']!,
          _toMemberIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_toMemberIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('payment_source_type')) {
      context.handle(
        _paymentSourceTypeMeta,
        paymentSourceType.isAcceptableOrUnknown(
          data['payment_source_type']!,
          _paymentSourceTypeMeta,
        ),
      );
    }
    if (data.containsKey('payment_source_id')) {
      context.handle(
        _paymentSourceIdMeta,
        paymentSourceId.isAcceptableOrUnknown(
          data['payment_source_id']!,
          _paymentSourceIdMeta,
        ),
      );
    }
    if (data.containsKey('settlement_date')) {
      context.handle(
        _settlementDateMeta,
        settlementDate.isAcceptableOrUnknown(
          data['settlement_date']!,
          _settlementDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_settlementDateMeta);
    }
    if (data.containsKey('linked_transaction_id')) {
      context.handle(
        _linkedTransactionIdMeta,
        linkedTransactionId.isAcceptableOrUnknown(
          data['linked_transaction_id']!,
          _linkedTransactionIdMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SplitSettlement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SplitSettlement(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}group_id'],
      )!,
      fromMemberId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}from_member_id'],
      )!,
      toMemberId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}to_member_id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      paymentSourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_source_type'],
      ),
      paymentSourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}payment_source_id'],
      ),
      settlementDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}settlement_date'],
      )!,
      linkedTransactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}linked_transaction_id'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SplitSettlementsTable createAlias(String alias) {
    return $SplitSettlementsTable(attachedDatabase, alias);
  }
}

class SplitSettlement extends DataClass implements Insertable<SplitSettlement> {
  final int id;
  final int groupId;
  final int fromMemberId;
  final int toMemberId;
  final double amount;
  final String? paymentSourceType;
  final int? paymentSourceId;
  final DateTime settlementDate;
  final int? linkedTransactionId;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SplitSettlement({
    required this.id,
    required this.groupId,
    required this.fromMemberId,
    required this.toMemberId,
    required this.amount,
    this.paymentSourceType,
    this.paymentSourceId,
    required this.settlementDate,
    this.linkedTransactionId,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['group_id'] = Variable<int>(groupId);
    map['from_member_id'] = Variable<int>(fromMemberId);
    map['to_member_id'] = Variable<int>(toMemberId);
    map['amount'] = Variable<double>(amount);
    if (!nullToAbsent || paymentSourceType != null) {
      map['payment_source_type'] = Variable<String>(paymentSourceType);
    }
    if (!nullToAbsent || paymentSourceId != null) {
      map['payment_source_id'] = Variable<int>(paymentSourceId);
    }
    map['settlement_date'] = Variable<DateTime>(settlementDate);
    if (!nullToAbsent || linkedTransactionId != null) {
      map['linked_transaction_id'] = Variable<int>(linkedTransactionId);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SplitSettlementsCompanion toCompanion(bool nullToAbsent) {
    return SplitSettlementsCompanion(
      id: Value(id),
      groupId: Value(groupId),
      fromMemberId: Value(fromMemberId),
      toMemberId: Value(toMemberId),
      amount: Value(amount),
      paymentSourceType: paymentSourceType == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentSourceType),
      paymentSourceId: paymentSourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentSourceId),
      settlementDate: Value(settlementDate),
      linkedTransactionId: linkedTransactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedTransactionId),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SplitSettlement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SplitSettlement(
      id: serializer.fromJson<int>(json['id']),
      groupId: serializer.fromJson<int>(json['groupId']),
      fromMemberId: serializer.fromJson<int>(json['fromMemberId']),
      toMemberId: serializer.fromJson<int>(json['toMemberId']),
      amount: serializer.fromJson<double>(json['amount']),
      paymentSourceType: serializer.fromJson<String?>(
        json['paymentSourceType'],
      ),
      paymentSourceId: serializer.fromJson<int?>(json['paymentSourceId']),
      settlementDate: serializer.fromJson<DateTime>(json['settlementDate']),
      linkedTransactionId: serializer.fromJson<int?>(
        json['linkedTransactionId'],
      ),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'groupId': serializer.toJson<int>(groupId),
      'fromMemberId': serializer.toJson<int>(fromMemberId),
      'toMemberId': serializer.toJson<int>(toMemberId),
      'amount': serializer.toJson<double>(amount),
      'paymentSourceType': serializer.toJson<String?>(paymentSourceType),
      'paymentSourceId': serializer.toJson<int?>(paymentSourceId),
      'settlementDate': serializer.toJson<DateTime>(settlementDate),
      'linkedTransactionId': serializer.toJson<int?>(linkedTransactionId),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SplitSettlement copyWith({
    int? id,
    int? groupId,
    int? fromMemberId,
    int? toMemberId,
    double? amount,
    Value<String?> paymentSourceType = const Value.absent(),
    Value<int?> paymentSourceId = const Value.absent(),
    DateTime? settlementDate,
    Value<int?> linkedTransactionId = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SplitSettlement(
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    fromMemberId: fromMemberId ?? this.fromMemberId,
    toMemberId: toMemberId ?? this.toMemberId,
    amount: amount ?? this.amount,
    paymentSourceType: paymentSourceType.present
        ? paymentSourceType.value
        : this.paymentSourceType,
    paymentSourceId: paymentSourceId.present
        ? paymentSourceId.value
        : this.paymentSourceId,
    settlementDate: settlementDate ?? this.settlementDate,
    linkedTransactionId: linkedTransactionId.present
        ? linkedTransactionId.value
        : this.linkedTransactionId,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SplitSettlement copyWithCompanion(SplitSettlementsCompanion data) {
    return SplitSettlement(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      fromMemberId: data.fromMemberId.present
          ? data.fromMemberId.value
          : this.fromMemberId,
      toMemberId: data.toMemberId.present
          ? data.toMemberId.value
          : this.toMemberId,
      amount: data.amount.present ? data.amount.value : this.amount,
      paymentSourceType: data.paymentSourceType.present
          ? data.paymentSourceType.value
          : this.paymentSourceType,
      paymentSourceId: data.paymentSourceId.present
          ? data.paymentSourceId.value
          : this.paymentSourceId,
      settlementDate: data.settlementDate.present
          ? data.settlementDate.value
          : this.settlementDate,
      linkedTransactionId: data.linkedTransactionId.present
          ? data.linkedTransactionId.value
          : this.linkedTransactionId,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SplitSettlement(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('fromMemberId: $fromMemberId, ')
          ..write('toMemberId: $toMemberId, ')
          ..write('amount: $amount, ')
          ..write('paymentSourceType: $paymentSourceType, ')
          ..write('paymentSourceId: $paymentSourceId, ')
          ..write('settlementDate: $settlementDate, ')
          ..write('linkedTransactionId: $linkedTransactionId, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    groupId,
    fromMemberId,
    toMemberId,
    amount,
    paymentSourceType,
    paymentSourceId,
    settlementDate,
    linkedTransactionId,
    notes,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SplitSettlement &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.fromMemberId == this.fromMemberId &&
          other.toMemberId == this.toMemberId &&
          other.amount == this.amount &&
          other.paymentSourceType == this.paymentSourceType &&
          other.paymentSourceId == this.paymentSourceId &&
          other.settlementDate == this.settlementDate &&
          other.linkedTransactionId == this.linkedTransactionId &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SplitSettlementsCompanion extends UpdateCompanion<SplitSettlement> {
  final Value<int> id;
  final Value<int> groupId;
  final Value<int> fromMemberId;
  final Value<int> toMemberId;
  final Value<double> amount;
  final Value<String?> paymentSourceType;
  final Value<int?> paymentSourceId;
  final Value<DateTime> settlementDate;
  final Value<int?> linkedTransactionId;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const SplitSettlementsCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.fromMemberId = const Value.absent(),
    this.toMemberId = const Value.absent(),
    this.amount = const Value.absent(),
    this.paymentSourceType = const Value.absent(),
    this.paymentSourceId = const Value.absent(),
    this.settlementDate = const Value.absent(),
    this.linkedTransactionId = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SplitSettlementsCompanion.insert({
    this.id = const Value.absent(),
    required int groupId,
    required int fromMemberId,
    required int toMemberId,
    required double amount,
    this.paymentSourceType = const Value.absent(),
    this.paymentSourceId = const Value.absent(),
    required DateTime settlementDate,
    this.linkedTransactionId = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : groupId = Value(groupId),
       fromMemberId = Value(fromMemberId),
       toMemberId = Value(toMemberId),
       amount = Value(amount),
       settlementDate = Value(settlementDate);
  static Insertable<SplitSettlement> custom({
    Expression<int>? id,
    Expression<int>? groupId,
    Expression<int>? fromMemberId,
    Expression<int>? toMemberId,
    Expression<double>? amount,
    Expression<String>? paymentSourceType,
    Expression<int>? paymentSourceId,
    Expression<DateTime>? settlementDate,
    Expression<int>? linkedTransactionId,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (fromMemberId != null) 'from_member_id': fromMemberId,
      if (toMemberId != null) 'to_member_id': toMemberId,
      if (amount != null) 'amount': amount,
      if (paymentSourceType != null) 'payment_source_type': paymentSourceType,
      if (paymentSourceId != null) 'payment_source_id': paymentSourceId,
      if (settlementDate != null) 'settlement_date': settlementDate,
      if (linkedTransactionId != null)
        'linked_transaction_id': linkedTransactionId,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SplitSettlementsCompanion copyWith({
    Value<int>? id,
    Value<int>? groupId,
    Value<int>? fromMemberId,
    Value<int>? toMemberId,
    Value<double>? amount,
    Value<String?>? paymentSourceType,
    Value<int?>? paymentSourceId,
    Value<DateTime>? settlementDate,
    Value<int?>? linkedTransactionId,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return SplitSettlementsCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      fromMemberId: fromMemberId ?? this.fromMemberId,
      toMemberId: toMemberId ?? this.toMemberId,
      amount: amount ?? this.amount,
      paymentSourceType: paymentSourceType ?? this.paymentSourceType,
      paymentSourceId: paymentSourceId ?? this.paymentSourceId,
      settlementDate: settlementDate ?? this.settlementDate,
      linkedTransactionId: linkedTransactionId ?? this.linkedTransactionId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<int>(groupId.value);
    }
    if (fromMemberId.present) {
      map['from_member_id'] = Variable<int>(fromMemberId.value);
    }
    if (toMemberId.present) {
      map['to_member_id'] = Variable<int>(toMemberId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (paymentSourceType.present) {
      map['payment_source_type'] = Variable<String>(paymentSourceType.value);
    }
    if (paymentSourceId.present) {
      map['payment_source_id'] = Variable<int>(paymentSourceId.value);
    }
    if (settlementDate.present) {
      map['settlement_date'] = Variable<DateTime>(settlementDate.value);
    }
    if (linkedTransactionId.present) {
      map['linked_transaction_id'] = Variable<int>(linkedTransactionId.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SplitSettlementsCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('fromMemberId: $fromMemberId, ')
          ..write('toMemberId: $toMemberId, ')
          ..write('amount: $amount, ')
          ..write('paymentSourceType: $paymentSourceType, ')
          ..write('paymentSourceId: $paymentSourceId, ')
          ..write('settlementDate: $settlementDate, ')
          ..write('linkedTransactionId: $linkedTransactionId, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $LoansTable extends Loans with TableInfo<$LoansTable, Loan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LoansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lenderNameMeta = const VerificationMeta(
    'lenderName',
  );
  @override
  late final GeneratedColumn<String> lenderName = GeneratedColumn<String>(
    'lender_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lenderTypeMeta = const VerificationMeta(
    'lenderType',
  );
  @override
  late final GeneratedColumn<String> lenderType = GeneratedColumn<String>(
    'lender_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _loanTypeMeta = const VerificationMeta(
    'loanType',
  );
  @override
  late final GeneratedColumn<String> loanType = GeneratedColumn<String>(
    'loan_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('other'),
  );
  static const VerificationMeta _principalAmountMeta = const VerificationMeta(
    'principalAmount',
  );
  @override
  late final GeneratedColumn<double> principalAmount = GeneratedColumn<double>(
    'principal_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentOutstandingMeta =
      const VerificationMeta('currentOutstanding');
  @override
  late final GeneratedColumn<double> currentOutstanding =
      GeneratedColumn<double>(
        'current_outstanding',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _interestRateMeta = const VerificationMeta(
    'interestRate',
  );
  @override
  late final GeneratedColumn<double> interestRate = GeneratedColumn<double>(
    'interest_rate',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emiAmountMeta = const VerificationMeta(
    'emiAmount',
  );
  @override
  late final GeneratedColumn<double> emiAmount = GeneratedColumn<double>(
    'emi_amount',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emiDayMeta = const VerificationMeta('emiDay');
  @override
  late final GeneratedColumn<int> emiDay = GeneratedColumn<int>(
    'emi_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tenureMonthsMeta = const VerificationMeta(
    'tenureMonths',
  );
  @override
  late final GeneratedColumn<int> tenureMonths = GeneratedColumn<int>(
    'tenure_months',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
    'end_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _linkedAccountIdMeta = const VerificationMeta(
    'linkedAccountId',
  );
  @override
  late final GeneratedColumn<int> linkedAccountId = GeneratedColumn<int>(
    'linked_account_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _closedAtMeta = const VerificationMeta(
    'closedAt',
  );
  @override
  late final GeneratedColumn<DateTime> closedAt = GeneratedColumn<DateTime>(
    'closed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    lenderName,
    lenderType,
    loanType,
    principalAmount,
    currentOutstanding,
    interestRate,
    emiAmount,
    emiDay,
    tenureMonths,
    startDate,
    endDate,
    linkedAccountId,
    notes,
    createdAt,
    updatedAt,
    closedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'loans';
  @override
  VerificationContext validateIntegrity(
    Insertable<Loan> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('lender_name')) {
      context.handle(
        _lenderNameMeta,
        lenderName.isAcceptableOrUnknown(data['lender_name']!, _lenderNameMeta),
      );
    } else if (isInserting) {
      context.missing(_lenderNameMeta);
    }
    if (data.containsKey('lender_type')) {
      context.handle(
        _lenderTypeMeta,
        lenderType.isAcceptableOrUnknown(data['lender_type']!, _lenderTypeMeta),
      );
    }
    if (data.containsKey('loan_type')) {
      context.handle(
        _loanTypeMeta,
        loanType.isAcceptableOrUnknown(data['loan_type']!, _loanTypeMeta),
      );
    }
    if (data.containsKey('principal_amount')) {
      context.handle(
        _principalAmountMeta,
        principalAmount.isAcceptableOrUnknown(
          data['principal_amount']!,
          _principalAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_principalAmountMeta);
    }
    if (data.containsKey('current_outstanding')) {
      context.handle(
        _currentOutstandingMeta,
        currentOutstanding.isAcceptableOrUnknown(
          data['current_outstanding']!,
          _currentOutstandingMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currentOutstandingMeta);
    }
    if (data.containsKey('interest_rate')) {
      context.handle(
        _interestRateMeta,
        interestRate.isAcceptableOrUnknown(
          data['interest_rate']!,
          _interestRateMeta,
        ),
      );
    }
    if (data.containsKey('emi_amount')) {
      context.handle(
        _emiAmountMeta,
        emiAmount.isAcceptableOrUnknown(data['emi_amount']!, _emiAmountMeta),
      );
    }
    if (data.containsKey('emi_day')) {
      context.handle(
        _emiDayMeta,
        emiDay.isAcceptableOrUnknown(data['emi_day']!, _emiDayMeta),
      );
    }
    if (data.containsKey('tenure_months')) {
      context.handle(
        _tenureMonthsMeta,
        tenureMonths.isAcceptableOrUnknown(
          data['tenure_months']!,
          _tenureMonthsMeta,
        ),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    }
    if (data.containsKey('linked_account_id')) {
      context.handle(
        _linkedAccountIdMeta,
        linkedAccountId.isAcceptableOrUnknown(
          data['linked_account_id']!,
          _linkedAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('closed_at')) {
      context.handle(
        _closedAtMeta,
        closedAt.isAcceptableOrUnknown(data['closed_at']!, _closedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Loan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Loan(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      lenderName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lender_name'],
      )!,
      lenderType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lender_type'],
      ),
      loanType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}loan_type'],
      )!,
      principalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}principal_amount'],
      )!,
      currentOutstanding: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}current_outstanding'],
      )!,
      interestRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}interest_rate'],
      ),
      emiAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}emi_amount'],
      ),
      emiDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}emi_day'],
      ),
      tenureMonths: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tenure_months'],
      ),
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      ),
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_date'],
      ),
      linkedAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}linked_account_id'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      closedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}closed_at'],
      ),
    );
  }

  @override
  $LoansTable createAlias(String alias) {
    return $LoansTable(attachedDatabase, alias);
  }
}

class Loan extends DataClass implements Insertable<Loan> {
  final int id;
  final String title;
  final String lenderName;
  final String? lenderType;
  final String loanType;
  final double principalAmount;
  final double currentOutstanding;
  final double? interestRate;
  final double? emiAmount;
  final int? emiDay;
  final int? tenureMonths;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? linkedAccountId;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? closedAt;
  const Loan({
    required this.id,
    required this.title,
    required this.lenderName,
    this.lenderType,
    required this.loanType,
    required this.principalAmount,
    required this.currentOutstanding,
    this.interestRate,
    this.emiAmount,
    this.emiDay,
    this.tenureMonths,
    this.startDate,
    this.endDate,
    this.linkedAccountId,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.closedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['lender_name'] = Variable<String>(lenderName);
    if (!nullToAbsent || lenderType != null) {
      map['lender_type'] = Variable<String>(lenderType);
    }
    map['loan_type'] = Variable<String>(loanType);
    map['principal_amount'] = Variable<double>(principalAmount);
    map['current_outstanding'] = Variable<double>(currentOutstanding);
    if (!nullToAbsent || interestRate != null) {
      map['interest_rate'] = Variable<double>(interestRate);
    }
    if (!nullToAbsent || emiAmount != null) {
      map['emi_amount'] = Variable<double>(emiAmount);
    }
    if (!nullToAbsent || emiDay != null) {
      map['emi_day'] = Variable<int>(emiDay);
    }
    if (!nullToAbsent || tenureMonths != null) {
      map['tenure_months'] = Variable<int>(tenureMonths);
    }
    if (!nullToAbsent || startDate != null) {
      map['start_date'] = Variable<DateTime>(startDate);
    }
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    if (!nullToAbsent || linkedAccountId != null) {
      map['linked_account_id'] = Variable<int>(linkedAccountId);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || closedAt != null) {
      map['closed_at'] = Variable<DateTime>(closedAt);
    }
    return map;
  }

  LoansCompanion toCompanion(bool nullToAbsent) {
    return LoansCompanion(
      id: Value(id),
      title: Value(title),
      lenderName: Value(lenderName),
      lenderType: lenderType == null && nullToAbsent
          ? const Value.absent()
          : Value(lenderType),
      loanType: Value(loanType),
      principalAmount: Value(principalAmount),
      currentOutstanding: Value(currentOutstanding),
      interestRate: interestRate == null && nullToAbsent
          ? const Value.absent()
          : Value(interestRate),
      emiAmount: emiAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(emiAmount),
      emiDay: emiDay == null && nullToAbsent
          ? const Value.absent()
          : Value(emiDay),
      tenureMonths: tenureMonths == null && nullToAbsent
          ? const Value.absent()
          : Value(tenureMonths),
      startDate: startDate == null && nullToAbsent
          ? const Value.absent()
          : Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      linkedAccountId: linkedAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedAccountId),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      closedAt: closedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(closedAt),
    );
  }

  factory Loan.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Loan(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      lenderName: serializer.fromJson<String>(json['lenderName']),
      lenderType: serializer.fromJson<String?>(json['lenderType']),
      loanType: serializer.fromJson<String>(json['loanType']),
      principalAmount: serializer.fromJson<double>(json['principalAmount']),
      currentOutstanding: serializer.fromJson<double>(
        json['currentOutstanding'],
      ),
      interestRate: serializer.fromJson<double?>(json['interestRate']),
      emiAmount: serializer.fromJson<double?>(json['emiAmount']),
      emiDay: serializer.fromJson<int?>(json['emiDay']),
      tenureMonths: serializer.fromJson<int?>(json['tenureMonths']),
      startDate: serializer.fromJson<DateTime?>(json['startDate']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
      linkedAccountId: serializer.fromJson<int?>(json['linkedAccountId']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      closedAt: serializer.fromJson<DateTime?>(json['closedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'lenderName': serializer.toJson<String>(lenderName),
      'lenderType': serializer.toJson<String?>(lenderType),
      'loanType': serializer.toJson<String>(loanType),
      'principalAmount': serializer.toJson<double>(principalAmount),
      'currentOutstanding': serializer.toJson<double>(currentOutstanding),
      'interestRate': serializer.toJson<double?>(interestRate),
      'emiAmount': serializer.toJson<double?>(emiAmount),
      'emiDay': serializer.toJson<int?>(emiDay),
      'tenureMonths': serializer.toJson<int?>(tenureMonths),
      'startDate': serializer.toJson<DateTime?>(startDate),
      'endDate': serializer.toJson<DateTime?>(endDate),
      'linkedAccountId': serializer.toJson<int?>(linkedAccountId),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'closedAt': serializer.toJson<DateTime?>(closedAt),
    };
  }

  Loan copyWith({
    int? id,
    String? title,
    String? lenderName,
    Value<String?> lenderType = const Value.absent(),
    String? loanType,
    double? principalAmount,
    double? currentOutstanding,
    Value<double?> interestRate = const Value.absent(),
    Value<double?> emiAmount = const Value.absent(),
    Value<int?> emiDay = const Value.absent(),
    Value<int?> tenureMonths = const Value.absent(),
    Value<DateTime?> startDate = const Value.absent(),
    Value<DateTime?> endDate = const Value.absent(),
    Value<int?> linkedAccountId = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> closedAt = const Value.absent(),
  }) => Loan(
    id: id ?? this.id,
    title: title ?? this.title,
    lenderName: lenderName ?? this.lenderName,
    lenderType: lenderType.present ? lenderType.value : this.lenderType,
    loanType: loanType ?? this.loanType,
    principalAmount: principalAmount ?? this.principalAmount,
    currentOutstanding: currentOutstanding ?? this.currentOutstanding,
    interestRate: interestRate.present ? interestRate.value : this.interestRate,
    emiAmount: emiAmount.present ? emiAmount.value : this.emiAmount,
    emiDay: emiDay.present ? emiDay.value : this.emiDay,
    tenureMonths: tenureMonths.present ? tenureMonths.value : this.tenureMonths,
    startDate: startDate.present ? startDate.value : this.startDate,
    endDate: endDate.present ? endDate.value : this.endDate,
    linkedAccountId: linkedAccountId.present
        ? linkedAccountId.value
        : this.linkedAccountId,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    closedAt: closedAt.present ? closedAt.value : this.closedAt,
  );
  Loan copyWithCompanion(LoansCompanion data) {
    return Loan(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      lenderName: data.lenderName.present
          ? data.lenderName.value
          : this.lenderName,
      lenderType: data.lenderType.present
          ? data.lenderType.value
          : this.lenderType,
      loanType: data.loanType.present ? data.loanType.value : this.loanType,
      principalAmount: data.principalAmount.present
          ? data.principalAmount.value
          : this.principalAmount,
      currentOutstanding: data.currentOutstanding.present
          ? data.currentOutstanding.value
          : this.currentOutstanding,
      interestRate: data.interestRate.present
          ? data.interestRate.value
          : this.interestRate,
      emiAmount: data.emiAmount.present ? data.emiAmount.value : this.emiAmount,
      emiDay: data.emiDay.present ? data.emiDay.value : this.emiDay,
      tenureMonths: data.tenureMonths.present
          ? data.tenureMonths.value
          : this.tenureMonths,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      linkedAccountId: data.linkedAccountId.present
          ? data.linkedAccountId.value
          : this.linkedAccountId,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      closedAt: data.closedAt.present ? data.closedAt.value : this.closedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Loan(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('lenderName: $lenderName, ')
          ..write('lenderType: $lenderType, ')
          ..write('loanType: $loanType, ')
          ..write('principalAmount: $principalAmount, ')
          ..write('currentOutstanding: $currentOutstanding, ')
          ..write('interestRate: $interestRate, ')
          ..write('emiAmount: $emiAmount, ')
          ..write('emiDay: $emiDay, ')
          ..write('tenureMonths: $tenureMonths, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('linkedAccountId: $linkedAccountId, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('closedAt: $closedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    lenderName,
    lenderType,
    loanType,
    principalAmount,
    currentOutstanding,
    interestRate,
    emiAmount,
    emiDay,
    tenureMonths,
    startDate,
    endDate,
    linkedAccountId,
    notes,
    createdAt,
    updatedAt,
    closedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Loan &&
          other.id == this.id &&
          other.title == this.title &&
          other.lenderName == this.lenderName &&
          other.lenderType == this.lenderType &&
          other.loanType == this.loanType &&
          other.principalAmount == this.principalAmount &&
          other.currentOutstanding == this.currentOutstanding &&
          other.interestRate == this.interestRate &&
          other.emiAmount == this.emiAmount &&
          other.emiDay == this.emiDay &&
          other.tenureMonths == this.tenureMonths &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.linkedAccountId == this.linkedAccountId &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.closedAt == this.closedAt);
}

class LoansCompanion extends UpdateCompanion<Loan> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> lenderName;
  final Value<String?> lenderType;
  final Value<String> loanType;
  final Value<double> principalAmount;
  final Value<double> currentOutstanding;
  final Value<double?> interestRate;
  final Value<double?> emiAmount;
  final Value<int?> emiDay;
  final Value<int?> tenureMonths;
  final Value<DateTime?> startDate;
  final Value<DateTime?> endDate;
  final Value<int?> linkedAccountId;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> closedAt;
  const LoansCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.lenderName = const Value.absent(),
    this.lenderType = const Value.absent(),
    this.loanType = const Value.absent(),
    this.principalAmount = const Value.absent(),
    this.currentOutstanding = const Value.absent(),
    this.interestRate = const Value.absent(),
    this.emiAmount = const Value.absent(),
    this.emiDay = const Value.absent(),
    this.tenureMonths = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.linkedAccountId = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.closedAt = const Value.absent(),
  });
  LoansCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String lenderName,
    this.lenderType = const Value.absent(),
    this.loanType = const Value.absent(),
    required double principalAmount,
    required double currentOutstanding,
    this.interestRate = const Value.absent(),
    this.emiAmount = const Value.absent(),
    this.emiDay = const Value.absent(),
    this.tenureMonths = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.linkedAccountId = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.closedAt = const Value.absent(),
  }) : title = Value(title),
       lenderName = Value(lenderName),
       principalAmount = Value(principalAmount),
       currentOutstanding = Value(currentOutstanding);
  static Insertable<Loan> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? lenderName,
    Expression<String>? lenderType,
    Expression<String>? loanType,
    Expression<double>? principalAmount,
    Expression<double>? currentOutstanding,
    Expression<double>? interestRate,
    Expression<double>? emiAmount,
    Expression<int>? emiDay,
    Expression<int>? tenureMonths,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<int>? linkedAccountId,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? closedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (lenderName != null) 'lender_name': lenderName,
      if (lenderType != null) 'lender_type': lenderType,
      if (loanType != null) 'loan_type': loanType,
      if (principalAmount != null) 'principal_amount': principalAmount,
      if (currentOutstanding != null) 'current_outstanding': currentOutstanding,
      if (interestRate != null) 'interest_rate': interestRate,
      if (emiAmount != null) 'emi_amount': emiAmount,
      if (emiDay != null) 'emi_day': emiDay,
      if (tenureMonths != null) 'tenure_months': tenureMonths,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (linkedAccountId != null) 'linked_account_id': linkedAccountId,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (closedAt != null) 'closed_at': closedAt,
    });
  }

  LoansCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? lenderName,
    Value<String?>? lenderType,
    Value<String>? loanType,
    Value<double>? principalAmount,
    Value<double>? currentOutstanding,
    Value<double?>? interestRate,
    Value<double?>? emiAmount,
    Value<int?>? emiDay,
    Value<int?>? tenureMonths,
    Value<DateTime?>? startDate,
    Value<DateTime?>? endDate,
    Value<int?>? linkedAccountId,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? closedAt,
  }) {
    return LoansCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      lenderName: lenderName ?? this.lenderName,
      lenderType: lenderType ?? this.lenderType,
      loanType: loanType ?? this.loanType,
      principalAmount: principalAmount ?? this.principalAmount,
      currentOutstanding: currentOutstanding ?? this.currentOutstanding,
      interestRate: interestRate ?? this.interestRate,
      emiAmount: emiAmount ?? this.emiAmount,
      emiDay: emiDay ?? this.emiDay,
      tenureMonths: tenureMonths ?? this.tenureMonths,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      linkedAccountId: linkedAccountId ?? this.linkedAccountId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      closedAt: closedAt ?? this.closedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (lenderName.present) {
      map['lender_name'] = Variable<String>(lenderName.value);
    }
    if (lenderType.present) {
      map['lender_type'] = Variable<String>(lenderType.value);
    }
    if (loanType.present) {
      map['loan_type'] = Variable<String>(loanType.value);
    }
    if (principalAmount.present) {
      map['principal_amount'] = Variable<double>(principalAmount.value);
    }
    if (currentOutstanding.present) {
      map['current_outstanding'] = Variable<double>(currentOutstanding.value);
    }
    if (interestRate.present) {
      map['interest_rate'] = Variable<double>(interestRate.value);
    }
    if (emiAmount.present) {
      map['emi_amount'] = Variable<double>(emiAmount.value);
    }
    if (emiDay.present) {
      map['emi_day'] = Variable<int>(emiDay.value);
    }
    if (tenureMonths.present) {
      map['tenure_months'] = Variable<int>(tenureMonths.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (linkedAccountId.present) {
      map['linked_account_id'] = Variable<int>(linkedAccountId.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (closedAt.present) {
      map['closed_at'] = Variable<DateTime>(closedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LoansCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('lenderName: $lenderName, ')
          ..write('lenderType: $lenderType, ')
          ..write('loanType: $loanType, ')
          ..write('principalAmount: $principalAmount, ')
          ..write('currentOutstanding: $currentOutstanding, ')
          ..write('interestRate: $interestRate, ')
          ..write('emiAmount: $emiAmount, ')
          ..write('emiDay: $emiDay, ')
          ..write('tenureMonths: $tenureMonths, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('linkedAccountId: $linkedAccountId, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('closedAt: $closedAt')
          ..write(')'))
        .toString();
  }
}

class $LoanPaymentsTable extends LoanPayments
    with TableInfo<$LoanPaymentsTable, LoanPayment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LoanPaymentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _loanIdMeta = const VerificationMeta('loanId');
  @override
  late final GeneratedColumn<int> loanId = GeneratedColumn<int>(
    'loan_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paymentDateMeta = const VerificationMeta(
    'paymentDate',
  );
  @override
  late final GeneratedColumn<DateTime> paymentDate = GeneratedColumn<DateTime>(
    'payment_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paymentSourceTypeMeta = const VerificationMeta(
    'paymentSourceType',
  );
  @override
  late final GeneratedColumn<String> paymentSourceType =
      GeneratedColumn<String>(
        'payment_source_type',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _paymentSourceIdMeta = const VerificationMeta(
    'paymentSourceId',
  );
  @override
  late final GeneratedColumn<int> paymentSourceId = GeneratedColumn<int>(
    'payment_source_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _linkedTransactionIdMeta =
      const VerificationMeta('linkedTransactionId');
  @override
  late final GeneratedColumn<int> linkedTransactionId = GeneratedColumn<int>(
    'linked_transaction_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    loanId,
    amount,
    paymentDate,
    paymentSourceType,
    paymentSourceId,
    linkedTransactionId,
    notes,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'loan_payments';
  @override
  VerificationContext validateIntegrity(
    Insertable<LoanPayment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('loan_id')) {
      context.handle(
        _loanIdMeta,
        loanId.isAcceptableOrUnknown(data['loan_id']!, _loanIdMeta),
      );
    } else if (isInserting) {
      context.missing(_loanIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('payment_date')) {
      context.handle(
        _paymentDateMeta,
        paymentDate.isAcceptableOrUnknown(
          data['payment_date']!,
          _paymentDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paymentDateMeta);
    }
    if (data.containsKey('payment_source_type')) {
      context.handle(
        _paymentSourceTypeMeta,
        paymentSourceType.isAcceptableOrUnknown(
          data['payment_source_type']!,
          _paymentSourceTypeMeta,
        ),
      );
    }
    if (data.containsKey('payment_source_id')) {
      context.handle(
        _paymentSourceIdMeta,
        paymentSourceId.isAcceptableOrUnknown(
          data['payment_source_id']!,
          _paymentSourceIdMeta,
        ),
      );
    }
    if (data.containsKey('linked_transaction_id')) {
      context.handle(
        _linkedTransactionIdMeta,
        linkedTransactionId.isAcceptableOrUnknown(
          data['linked_transaction_id']!,
          _linkedTransactionIdMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LoanPayment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LoanPayment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      loanId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}loan_id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      paymentDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}payment_date'],
      )!,
      paymentSourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_source_type'],
      ),
      paymentSourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}payment_source_id'],
      ),
      linkedTransactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}linked_transaction_id'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LoanPaymentsTable createAlias(String alias) {
    return $LoanPaymentsTable(attachedDatabase, alias);
  }
}

class LoanPayment extends DataClass implements Insertable<LoanPayment> {
  final int id;
  final int loanId;
  final double amount;
  final DateTime paymentDate;
  final String? paymentSourceType;
  final int? paymentSourceId;
  final int? linkedTransactionId;
  final String? notes;
  final DateTime createdAt;
  const LoanPayment({
    required this.id,
    required this.loanId,
    required this.amount,
    required this.paymentDate,
    this.paymentSourceType,
    this.paymentSourceId,
    this.linkedTransactionId,
    this.notes,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['loan_id'] = Variable<int>(loanId);
    map['amount'] = Variable<double>(amount);
    map['payment_date'] = Variable<DateTime>(paymentDate);
    if (!nullToAbsent || paymentSourceType != null) {
      map['payment_source_type'] = Variable<String>(paymentSourceType);
    }
    if (!nullToAbsent || paymentSourceId != null) {
      map['payment_source_id'] = Variable<int>(paymentSourceId);
    }
    if (!nullToAbsent || linkedTransactionId != null) {
      map['linked_transaction_id'] = Variable<int>(linkedTransactionId);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LoanPaymentsCompanion toCompanion(bool nullToAbsent) {
    return LoanPaymentsCompanion(
      id: Value(id),
      loanId: Value(loanId),
      amount: Value(amount),
      paymentDate: Value(paymentDate),
      paymentSourceType: paymentSourceType == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentSourceType),
      paymentSourceId: paymentSourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentSourceId),
      linkedTransactionId: linkedTransactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedTransactionId),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory LoanPayment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LoanPayment(
      id: serializer.fromJson<int>(json['id']),
      loanId: serializer.fromJson<int>(json['loanId']),
      amount: serializer.fromJson<double>(json['amount']),
      paymentDate: serializer.fromJson<DateTime>(json['paymentDate']),
      paymentSourceType: serializer.fromJson<String?>(
        json['paymentSourceType'],
      ),
      paymentSourceId: serializer.fromJson<int?>(json['paymentSourceId']),
      linkedTransactionId: serializer.fromJson<int?>(
        json['linkedTransactionId'],
      ),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'loanId': serializer.toJson<int>(loanId),
      'amount': serializer.toJson<double>(amount),
      'paymentDate': serializer.toJson<DateTime>(paymentDate),
      'paymentSourceType': serializer.toJson<String?>(paymentSourceType),
      'paymentSourceId': serializer.toJson<int?>(paymentSourceId),
      'linkedTransactionId': serializer.toJson<int?>(linkedTransactionId),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LoanPayment copyWith({
    int? id,
    int? loanId,
    double? amount,
    DateTime? paymentDate,
    Value<String?> paymentSourceType = const Value.absent(),
    Value<int?> paymentSourceId = const Value.absent(),
    Value<int?> linkedTransactionId = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
  }) => LoanPayment(
    id: id ?? this.id,
    loanId: loanId ?? this.loanId,
    amount: amount ?? this.amount,
    paymentDate: paymentDate ?? this.paymentDate,
    paymentSourceType: paymentSourceType.present
        ? paymentSourceType.value
        : this.paymentSourceType,
    paymentSourceId: paymentSourceId.present
        ? paymentSourceId.value
        : this.paymentSourceId,
    linkedTransactionId: linkedTransactionId.present
        ? linkedTransactionId.value
        : this.linkedTransactionId,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
  );
  LoanPayment copyWithCompanion(LoanPaymentsCompanion data) {
    return LoanPayment(
      id: data.id.present ? data.id.value : this.id,
      loanId: data.loanId.present ? data.loanId.value : this.loanId,
      amount: data.amount.present ? data.amount.value : this.amount,
      paymentDate: data.paymentDate.present
          ? data.paymentDate.value
          : this.paymentDate,
      paymentSourceType: data.paymentSourceType.present
          ? data.paymentSourceType.value
          : this.paymentSourceType,
      paymentSourceId: data.paymentSourceId.present
          ? data.paymentSourceId.value
          : this.paymentSourceId,
      linkedTransactionId: data.linkedTransactionId.present
          ? data.linkedTransactionId.value
          : this.linkedTransactionId,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LoanPayment(')
          ..write('id: $id, ')
          ..write('loanId: $loanId, ')
          ..write('amount: $amount, ')
          ..write('paymentDate: $paymentDate, ')
          ..write('paymentSourceType: $paymentSourceType, ')
          ..write('paymentSourceId: $paymentSourceId, ')
          ..write('linkedTransactionId: $linkedTransactionId, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    loanId,
    amount,
    paymentDate,
    paymentSourceType,
    paymentSourceId,
    linkedTransactionId,
    notes,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LoanPayment &&
          other.id == this.id &&
          other.loanId == this.loanId &&
          other.amount == this.amount &&
          other.paymentDate == this.paymentDate &&
          other.paymentSourceType == this.paymentSourceType &&
          other.paymentSourceId == this.paymentSourceId &&
          other.linkedTransactionId == this.linkedTransactionId &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class LoanPaymentsCompanion extends UpdateCompanion<LoanPayment> {
  final Value<int> id;
  final Value<int> loanId;
  final Value<double> amount;
  final Value<DateTime> paymentDate;
  final Value<String?> paymentSourceType;
  final Value<int?> paymentSourceId;
  final Value<int?> linkedTransactionId;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  const LoanPaymentsCompanion({
    this.id = const Value.absent(),
    this.loanId = const Value.absent(),
    this.amount = const Value.absent(),
    this.paymentDate = const Value.absent(),
    this.paymentSourceType = const Value.absent(),
    this.paymentSourceId = const Value.absent(),
    this.linkedTransactionId = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  LoanPaymentsCompanion.insert({
    this.id = const Value.absent(),
    required int loanId,
    required double amount,
    required DateTime paymentDate,
    this.paymentSourceType = const Value.absent(),
    this.paymentSourceId = const Value.absent(),
    this.linkedTransactionId = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : loanId = Value(loanId),
       amount = Value(amount),
       paymentDate = Value(paymentDate);
  static Insertable<LoanPayment> custom({
    Expression<int>? id,
    Expression<int>? loanId,
    Expression<double>? amount,
    Expression<DateTime>? paymentDate,
    Expression<String>? paymentSourceType,
    Expression<int>? paymentSourceId,
    Expression<int>? linkedTransactionId,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (loanId != null) 'loan_id': loanId,
      if (amount != null) 'amount': amount,
      if (paymentDate != null) 'payment_date': paymentDate,
      if (paymentSourceType != null) 'payment_source_type': paymentSourceType,
      if (paymentSourceId != null) 'payment_source_id': paymentSourceId,
      if (linkedTransactionId != null)
        'linked_transaction_id': linkedTransactionId,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  LoanPaymentsCompanion copyWith({
    Value<int>? id,
    Value<int>? loanId,
    Value<double>? amount,
    Value<DateTime>? paymentDate,
    Value<String?>? paymentSourceType,
    Value<int?>? paymentSourceId,
    Value<int?>? linkedTransactionId,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
  }) {
    return LoanPaymentsCompanion(
      id: id ?? this.id,
      loanId: loanId ?? this.loanId,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentSourceType: paymentSourceType ?? this.paymentSourceType,
      paymentSourceId: paymentSourceId ?? this.paymentSourceId,
      linkedTransactionId: linkedTransactionId ?? this.linkedTransactionId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (loanId.present) {
      map['loan_id'] = Variable<int>(loanId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (paymentDate.present) {
      map['payment_date'] = Variable<DateTime>(paymentDate.value);
    }
    if (paymentSourceType.present) {
      map['payment_source_type'] = Variable<String>(paymentSourceType.value);
    }
    if (paymentSourceId.present) {
      map['payment_source_id'] = Variable<int>(paymentSourceId.value);
    }
    if (linkedTransactionId.present) {
      map['linked_transaction_id'] = Variable<int>(linkedTransactionId.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LoanPaymentsCompanion(')
          ..write('id: $id, ')
          ..write('loanId: $loanId, ')
          ..write('amount: $amount, ')
          ..write('paymentDate: $paymentDate, ')
          ..write('paymentSourceType: $paymentSourceType, ')
          ..write('paymentSourceId: $paymentSourceId, ')
          ..write('linkedTransactionId: $linkedTransactionId, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $AlertsTable extends Alerts with TableInfo<$AlertsTable, Alert> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlertsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _alertTypeMeta = const VerificationMeta(
    'alertType',
  );
  @override
  late final GeneratedColumn<String> alertType = GeneratedColumn<String>(
    'alert_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _scheduledAtMeta = const VerificationMeta(
    'scheduledAt',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledAt = GeneratedColumn<DateTime>(
    'scheduled_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('info'),
  );
  static const VerificationMeta _readAtMeta = const VerificationMeta('readAt');
  @override
  late final GeneratedColumn<DateTime> readAt = GeneratedColumn<DateTime>(
    'read_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actionRouteMeta = const VerificationMeta(
    'actionRoute',
  );
  @override
  late final GeneratedColumn<String> actionRoute = GeneratedColumn<String>(
    'action_route',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dismissedAtMeta = const VerificationMeta(
    'dismissedAt',
  );
  @override
  late final GeneratedColumn<DateTime> dismissedAt = GeneratedColumn<DateTime>(
    'dismissed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dedupeKeyMeta = const VerificationMeta(
    'dedupeKey',
  );
  @override
  late final GeneratedColumn<String> dedupeKey = GeneratedColumn<String>(
    'dedupe_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    alertType,
    title,
    body,
    createdAt,
    scheduledAt,
    priority,
    readAt,
    actionRoute,
    payload,
    dismissedAt,
    dedupeKey,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'alerts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Alert> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('alert_type')) {
      context.handle(
        _alertTypeMeta,
        alertType.isAcceptableOrUnknown(data['alert_type']!, _alertTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_alertTypeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('scheduled_at')) {
      context.handle(
        _scheduledAtMeta,
        scheduledAt.isAcceptableOrUnknown(
          data['scheduled_at']!,
          _scheduledAtMeta,
        ),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('read_at')) {
      context.handle(
        _readAtMeta,
        readAt.isAcceptableOrUnknown(data['read_at']!, _readAtMeta),
      );
    }
    if (data.containsKey('action_route')) {
      context.handle(
        _actionRouteMeta,
        actionRoute.isAcceptableOrUnknown(
          data['action_route']!,
          _actionRouteMeta,
        ),
      );
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    }
    if (data.containsKey('dismissed_at')) {
      context.handle(
        _dismissedAtMeta,
        dismissedAt.isAcceptableOrUnknown(
          data['dismissed_at']!,
          _dismissedAtMeta,
        ),
      );
    }
    if (data.containsKey('dedupe_key')) {
      context.handle(
        _dedupeKeyMeta,
        dedupeKey.isAcceptableOrUnknown(data['dedupe_key']!, _dedupeKeyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Alert map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Alert(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      alertType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alert_type'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      scheduledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_at'],
      ),
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}priority'],
      )!,
      readAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}read_at'],
      ),
      actionRoute: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action_route'],
      ),
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      ),
      dismissedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}dismissed_at'],
      ),
      dedupeKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dedupe_key'],
      ),
    );
  }

  @override
  $AlertsTable createAlias(String alias) {
    return $AlertsTable(attachedDatabase, alias);
  }
}

class Alert extends DataClass implements Insertable<Alert> {
  final int id;
  final String alertType;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime? scheduledAt;
  final String priority;
  final DateTime? readAt;
  final String? actionRoute;
  final String? payload;
  final DateTime? dismissedAt;
  final String? dedupeKey;
  const Alert({
    required this.id,
    required this.alertType,
    required this.title,
    required this.body,
    required this.createdAt,
    this.scheduledAt,
    required this.priority,
    this.readAt,
    this.actionRoute,
    this.payload,
    this.dismissedAt,
    this.dedupeKey,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['alert_type'] = Variable<String>(alertType);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || scheduledAt != null) {
      map['scheduled_at'] = Variable<DateTime>(scheduledAt);
    }
    map['priority'] = Variable<String>(priority);
    if (!nullToAbsent || readAt != null) {
      map['read_at'] = Variable<DateTime>(readAt);
    }
    if (!nullToAbsent || actionRoute != null) {
      map['action_route'] = Variable<String>(actionRoute);
    }
    if (!nullToAbsent || payload != null) {
      map['payload'] = Variable<String>(payload);
    }
    if (!nullToAbsent || dismissedAt != null) {
      map['dismissed_at'] = Variable<DateTime>(dismissedAt);
    }
    if (!nullToAbsent || dedupeKey != null) {
      map['dedupe_key'] = Variable<String>(dedupeKey);
    }
    return map;
  }

  AlertsCompanion toCompanion(bool nullToAbsent) {
    return AlertsCompanion(
      id: Value(id),
      alertType: Value(alertType),
      title: Value(title),
      body: Value(body),
      createdAt: Value(createdAt),
      scheduledAt: scheduledAt == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduledAt),
      priority: Value(priority),
      readAt: readAt == null && nullToAbsent
          ? const Value.absent()
          : Value(readAt),
      actionRoute: actionRoute == null && nullToAbsent
          ? const Value.absent()
          : Value(actionRoute),
      payload: payload == null && nullToAbsent
          ? const Value.absent()
          : Value(payload),
      dismissedAt: dismissedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(dismissedAt),
      dedupeKey: dedupeKey == null && nullToAbsent
          ? const Value.absent()
          : Value(dedupeKey),
    );
  }

  factory Alert.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Alert(
      id: serializer.fromJson<int>(json['id']),
      alertType: serializer.fromJson<String>(json['alertType']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      scheduledAt: serializer.fromJson<DateTime?>(json['scheduledAt']),
      priority: serializer.fromJson<String>(json['priority']),
      readAt: serializer.fromJson<DateTime?>(json['readAt']),
      actionRoute: serializer.fromJson<String?>(json['actionRoute']),
      payload: serializer.fromJson<String?>(json['payload']),
      dismissedAt: serializer.fromJson<DateTime?>(json['dismissedAt']),
      dedupeKey: serializer.fromJson<String?>(json['dedupeKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'alertType': serializer.toJson<String>(alertType),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'scheduledAt': serializer.toJson<DateTime?>(scheduledAt),
      'priority': serializer.toJson<String>(priority),
      'readAt': serializer.toJson<DateTime?>(readAt),
      'actionRoute': serializer.toJson<String?>(actionRoute),
      'payload': serializer.toJson<String?>(payload),
      'dismissedAt': serializer.toJson<DateTime?>(dismissedAt),
      'dedupeKey': serializer.toJson<String?>(dedupeKey),
    };
  }

  Alert copyWith({
    int? id,
    String? alertType,
    String? title,
    String? body,
    DateTime? createdAt,
    Value<DateTime?> scheduledAt = const Value.absent(),
    String? priority,
    Value<DateTime?> readAt = const Value.absent(),
    Value<String?> actionRoute = const Value.absent(),
    Value<String?> payload = const Value.absent(),
    Value<DateTime?> dismissedAt = const Value.absent(),
    Value<String?> dedupeKey = const Value.absent(),
  }) => Alert(
    id: id ?? this.id,
    alertType: alertType ?? this.alertType,
    title: title ?? this.title,
    body: body ?? this.body,
    createdAt: createdAt ?? this.createdAt,
    scheduledAt: scheduledAt.present ? scheduledAt.value : this.scheduledAt,
    priority: priority ?? this.priority,
    readAt: readAt.present ? readAt.value : this.readAt,
    actionRoute: actionRoute.present ? actionRoute.value : this.actionRoute,
    payload: payload.present ? payload.value : this.payload,
    dismissedAt: dismissedAt.present ? dismissedAt.value : this.dismissedAt,
    dedupeKey: dedupeKey.present ? dedupeKey.value : this.dedupeKey,
  );
  Alert copyWithCompanion(AlertsCompanion data) {
    return Alert(
      id: data.id.present ? data.id.value : this.id,
      alertType: data.alertType.present ? data.alertType.value : this.alertType,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      scheduledAt: data.scheduledAt.present
          ? data.scheduledAt.value
          : this.scheduledAt,
      priority: data.priority.present ? data.priority.value : this.priority,
      readAt: data.readAt.present ? data.readAt.value : this.readAt,
      actionRoute: data.actionRoute.present
          ? data.actionRoute.value
          : this.actionRoute,
      payload: data.payload.present ? data.payload.value : this.payload,
      dismissedAt: data.dismissedAt.present
          ? data.dismissedAt.value
          : this.dismissedAt,
      dedupeKey: data.dedupeKey.present ? data.dedupeKey.value : this.dedupeKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Alert(')
          ..write('id: $id, ')
          ..write('alertType: $alertType, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('priority: $priority, ')
          ..write('readAt: $readAt, ')
          ..write('actionRoute: $actionRoute, ')
          ..write('payload: $payload, ')
          ..write('dismissedAt: $dismissedAt, ')
          ..write('dedupeKey: $dedupeKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    alertType,
    title,
    body,
    createdAt,
    scheduledAt,
    priority,
    readAt,
    actionRoute,
    payload,
    dismissedAt,
    dedupeKey,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Alert &&
          other.id == this.id &&
          other.alertType == this.alertType &&
          other.title == this.title &&
          other.body == this.body &&
          other.createdAt == this.createdAt &&
          other.scheduledAt == this.scheduledAt &&
          other.priority == this.priority &&
          other.readAt == this.readAt &&
          other.actionRoute == this.actionRoute &&
          other.payload == this.payload &&
          other.dismissedAt == this.dismissedAt &&
          other.dedupeKey == this.dedupeKey);
}

class AlertsCompanion extends UpdateCompanion<Alert> {
  final Value<int> id;
  final Value<String> alertType;
  final Value<String> title;
  final Value<String> body;
  final Value<DateTime> createdAt;
  final Value<DateTime?> scheduledAt;
  final Value<String> priority;
  final Value<DateTime?> readAt;
  final Value<String?> actionRoute;
  final Value<String?> payload;
  final Value<DateTime?> dismissedAt;
  final Value<String?> dedupeKey;
  const AlertsCompanion({
    this.id = const Value.absent(),
    this.alertType = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.scheduledAt = const Value.absent(),
    this.priority = const Value.absent(),
    this.readAt = const Value.absent(),
    this.actionRoute = const Value.absent(),
    this.payload = const Value.absent(),
    this.dismissedAt = const Value.absent(),
    this.dedupeKey = const Value.absent(),
  });
  AlertsCompanion.insert({
    this.id = const Value.absent(),
    required String alertType,
    required String title,
    required String body,
    this.createdAt = const Value.absent(),
    this.scheduledAt = const Value.absent(),
    this.priority = const Value.absent(),
    this.readAt = const Value.absent(),
    this.actionRoute = const Value.absent(),
    this.payload = const Value.absent(),
    this.dismissedAt = const Value.absent(),
    this.dedupeKey = const Value.absent(),
  }) : alertType = Value(alertType),
       title = Value(title),
       body = Value(body);
  static Insertable<Alert> custom({
    Expression<int>? id,
    Expression<String>? alertType,
    Expression<String>? title,
    Expression<String>? body,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? scheduledAt,
    Expression<String>? priority,
    Expression<DateTime>? readAt,
    Expression<String>? actionRoute,
    Expression<String>? payload,
    Expression<DateTime>? dismissedAt,
    Expression<String>? dedupeKey,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (alertType != null) 'alert_type': alertType,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (createdAt != null) 'created_at': createdAt,
      if (scheduledAt != null) 'scheduled_at': scheduledAt,
      if (priority != null) 'priority': priority,
      if (readAt != null) 'read_at': readAt,
      if (actionRoute != null) 'action_route': actionRoute,
      if (payload != null) 'payload': payload,
      if (dismissedAt != null) 'dismissed_at': dismissedAt,
      if (dedupeKey != null) 'dedupe_key': dedupeKey,
    });
  }

  AlertsCompanion copyWith({
    Value<int>? id,
    Value<String>? alertType,
    Value<String>? title,
    Value<String>? body,
    Value<DateTime>? createdAt,
    Value<DateTime?>? scheduledAt,
    Value<String>? priority,
    Value<DateTime?>? readAt,
    Value<String?>? actionRoute,
    Value<String?>? payload,
    Value<DateTime?>? dismissedAt,
    Value<String?>? dedupeKey,
  }) {
    return AlertsCompanion(
      id: id ?? this.id,
      alertType: alertType ?? this.alertType,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      priority: priority ?? this.priority,
      readAt: readAt ?? this.readAt,
      actionRoute: actionRoute ?? this.actionRoute,
      payload: payload ?? this.payload,
      dismissedAt: dismissedAt ?? this.dismissedAt,
      dedupeKey: dedupeKey ?? this.dedupeKey,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (alertType.present) {
      map['alert_type'] = Variable<String>(alertType.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (scheduledAt.present) {
      map['scheduled_at'] = Variable<DateTime>(scheduledAt.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (readAt.present) {
      map['read_at'] = Variable<DateTime>(readAt.value);
    }
    if (actionRoute.present) {
      map['action_route'] = Variable<String>(actionRoute.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (dismissedAt.present) {
      map['dismissed_at'] = Variable<DateTime>(dismissedAt.value);
    }
    if (dedupeKey.present) {
      map['dedupe_key'] = Variable<String>(dedupeKey.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlertsCompanion(')
          ..write('id: $id, ')
          ..write('alertType: $alertType, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('priority: $priority, ')
          ..write('readAt: $readAt, ')
          ..write('actionRoute: $actionRoute, ')
          ..write('payload: $payload, ')
          ..write('dismissedAt: $dismissedAt, ')
          ..write('dedupeKey: $dedupeKey')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _isDarkModeMeta = const VerificationMeta(
    'isDarkMode',
  );
  @override
  late final GeneratedColumn<bool> isDarkMode = GeneratedColumn<bool>(
    'is_dark_mode',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dark_mode" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _appLockEnabledMeta = const VerificationMeta(
    'appLockEnabled',
  );
  @override
  late final GeneratedColumn<bool> appLockEnabled = GeneratedColumn<bool>(
    'app_lock_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("app_lock_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _notificationDetectionEnabledMeta =
      const VerificationMeta('notificationDetectionEnabled');
  @override
  late final GeneratedColumn<bool> notificationDetectionEnabled =
      GeneratedColumn<bool>(
        'notification_detection_enabled',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("notification_detection_enabled" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  static const VerificationMeta _showDetectionNotificationsMeta =
      const VerificationMeta('showDetectionNotifications');
  @override
  late final GeneratedColumn<bool> showDetectionNotifications =
      GeneratedColumn<bool>(
        'show_detection_notifications',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("show_detection_notifications" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  static const VerificationMeta _reminderEnabledMeta = const VerificationMeta(
    'reminderEnabled',
  );
  @override
  late final GeneratedColumn<bool> reminderEnabled = GeneratedColumn<bool>(
    'reminder_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("reminder_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _dailyReminderEnabledMeta =
      const VerificationMeta('dailyReminderEnabled');
  @override
  late final GeneratedColumn<bool> dailyReminderEnabled = GeneratedColumn<bool>(
    'daily_reminder_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("daily_reminder_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _weeklyReminderEnabledMeta =
      const VerificationMeta('weeklyReminderEnabled');
  @override
  late final GeneratedColumn<bool> weeklyReminderEnabled =
      GeneratedColumn<bool>(
        'weekly_reminder_enabled',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("weekly_reminder_enabled" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _reminderHourMeta = const VerificationMeta(
    'reminderHour',
  );
  @override
  late final GeneratedColumn<int> reminderHour = GeneratedColumn<int>(
    'reminder_hour',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(20),
  );
  static const VerificationMeta _reminderMinuteMeta = const VerificationMeta(
    'reminderMinute',
  );
  @override
  late final GeneratedColumn<int> reminderMinute = GeneratedColumn<int>(
    'reminder_minute',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _weeklyReminderWeekdayMeta =
      const VerificationMeta('weeklyReminderWeekday');
  @override
  late final GeneratedColumn<int> weeklyReminderWeekday = GeneratedColumn<int>(
    'weekly_reminder_weekday',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(DateTime.monday),
  );
  static const VerificationMeta _cardDueReminderEnabledMeta =
      const VerificationMeta('cardDueReminderEnabled');
  @override
  late final GeneratedColumn<bool> cardDueReminderEnabled =
      GeneratedColumn<bool>(
        'card_due_reminder_enabled',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("card_due_reminder_enabled" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  static const VerificationMeta _pendingTransactionReminderEnabledMeta =
      const VerificationMeta('pendingTransactionReminderEnabled');
  @override
  late final GeneratedColumn<bool> pendingTransactionReminderEnabled =
      GeneratedColumn<bool>(
        'pending_transaction_reminder_enabled',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("pending_transaction_reminder_enabled" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  static const VerificationMeta _settlementReminderEnabledMeta =
      const VerificationMeta('settlementReminderEnabled');
  @override
  late final GeneratedColumn<bool> settlementReminderEnabled =
      GeneratedColumn<bool>(
        'settlement_reminder_enabled',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("settlement_reminder_enabled" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _lastReminderShownAtMeta =
      const VerificationMeta('lastReminderShownAt');
  @override
  late final GeneratedColumn<DateTime> lastReminderShownAt =
      GeneratedColumn<DateTime>(
        'last_reminder_shown_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _smsDetectionEnabledMeta =
      const VerificationMeta('smsDetectionEnabled');
  @override
  late final GeneratedColumn<bool> smsDetectionEnabled = GeneratedColumn<bool>(
    'sms_detection_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sms_detection_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _smsPermissionAskedAtMeta =
      const VerificationMeta('smsPermissionAskedAt');
  @override
  late final GeneratedColumn<DateTime> smsPermissionAskedAt =
      GeneratedColumn<DateTime>(
        'sms_permission_asked_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _smsBackfillEnabledMeta =
      const VerificationMeta('smsBackfillEnabled');
  @override
  late final GeneratedColumn<bool> smsBackfillEnabled = GeneratedColumn<bool>(
    'sms_backfill_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sms_backfill_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _smsBackfillDaysMeta = const VerificationMeta(
    'smsBackfillDays',
  );
  @override
  late final GeneratedColumn<int> smsBackfillDays = GeneratedColumn<int>(
    'sms_backfill_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(7),
  );
  static const VerificationMeta _smsLastScannedAtMeta = const VerificationMeta(
    'smsLastScannedAt',
  );
  @override
  late final GeneratedColumn<DateTime> smsLastScannedAt =
      GeneratedColumn<DateTime>(
        'sms_last_scanned_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _hasCompletedOnboardingMeta =
      const VerificationMeta('hasCompletedOnboarding');
  @override
  late final GeneratedColumn<bool> hasCompletedOnboarding =
      GeneratedColumn<bool>(
        'has_completed_onboarding',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("has_completed_onboarding" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _quietHoursStartHourMeta =
      const VerificationMeta('quietHoursStartHour');
  @override
  late final GeneratedColumn<int> quietHoursStartHour = GeneratedColumn<int>(
    'quiet_hours_start_hour',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(22),
  );
  static const VerificationMeta _quietHoursStartMinuteMeta =
      const VerificationMeta('quietHoursStartMinute');
  @override
  late final GeneratedColumn<int> quietHoursStartMinute = GeneratedColumn<int>(
    'quiet_hours_start_minute',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _quietHoursEndHourMeta = const VerificationMeta(
    'quietHoursEndHour',
  );
  @override
  late final GeneratedColumn<int> quietHoursEndHour = GeneratedColumn<int>(
    'quiet_hours_end_hour',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(7),
  );
  static const VerificationMeta _quietHoursEndMinuteMeta =
      const VerificationMeta('quietHoursEndMinute');
  @override
  late final GeneratedColumn<int> quietHoursEndMinute = GeneratedColumn<int>(
    'quiet_hours_end_minute',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _smartAlertsEnabledMeta =
      const VerificationMeta('smartAlertsEnabled');
  @override
  late final GeneratedColumn<bool> smartAlertsEnabled = GeneratedColumn<bool>(
    'smart_alerts_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("smart_alerts_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _lowBalanceAlertsEnabledMeta =
      const VerificationMeta('lowBalanceAlertsEnabled');
  @override
  late final GeneratedColumn<bool> lowBalanceAlertsEnabled =
      GeneratedColumn<bool>(
        'low_balance_alerts_enabled',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("low_balance_alerts_enabled" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  static const VerificationMeta _lowBalanceThresholdMeta =
      const VerificationMeta('lowBalanceThreshold');
  @override
  late final GeneratedColumn<double> lowBalanceThreshold =
      GeneratedColumn<double>(
        'low_balance_threshold',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(2000),
      );
  static const VerificationMeta _largeExpenseAlertsEnabledMeta =
      const VerificationMeta('largeExpenseAlertsEnabled');
  @override
  late final GeneratedColumn<bool> largeExpenseAlertsEnabled =
      GeneratedColumn<bool>(
        'large_expense_alerts_enabled',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("large_expense_alerts_enabled" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  static const VerificationMeta _largeExpenseThresholdMeta =
      const VerificationMeta('largeExpenseThreshold');
  @override
  late final GeneratedColumn<double> largeExpenseThreshold =
      GeneratedColumn<double>(
        'large_expense_threshold',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(10000),
      );
  static const VerificationMeta _unusualSpendingAlertsEnabledMeta =
      const VerificationMeta('unusualSpendingAlertsEnabled');
  @override
  late final GeneratedColumn<bool> unusualSpendingAlertsEnabled =
      GeneratedColumn<bool>(
        'unusual_spending_alerts_enabled',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("unusual_spending_alerts_enabled" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  static const VerificationMeta _unusualSpendingMultiplierMeta =
      const VerificationMeta('unusualSpendingMultiplier');
  @override
  late final GeneratedColumn<double> unusualSpendingMultiplier =
      GeneratedColumn<double>(
        'unusual_spending_multiplier',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(1.8),
      );
  static const VerificationMeta _recurringMerchantAlertsEnabledMeta =
      const VerificationMeta('recurringMerchantAlertsEnabled');
  @override
  late final GeneratedColumn<bool> recurringMerchantAlertsEnabled =
      GeneratedColumn<bool>(
        'recurring_merchant_alerts_enabled',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("recurring_merchant_alerts_enabled" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  static const VerificationMeta _weeklySummaryAlertsEnabledMeta =
      const VerificationMeta('weeklySummaryAlertsEnabled');
  @override
  late final GeneratedColumn<bool> weeklySummaryAlertsEnabled =
      GeneratedColumn<bool>(
        'weekly_summary_alerts_enabled',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("weekly_summary_alerts_enabled" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  static const VerificationMeta _monthlySummaryAlertsEnabledMeta =
      const VerificationMeta('monthlySummaryAlertsEnabled');
  @override
  late final GeneratedColumn<bool> monthlySummaryAlertsEnabled =
      GeneratedColumn<bool>(
        'monthly_summary_alerts_enabled',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("monthly_summary_alerts_enabled" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  static const VerificationMeta _userNameMeta = const VerificationMeta(
    'userName',
  );
  @override
  late final GeneratedColumn<String> userName = GeneratedColumn<String>(
    'user_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _monthlySalaryMeta = const VerificationMeta(
    'monthlySalary',
  );
  @override
  late final GeneratedColumn<double> monthlySalary = GeneratedColumn<double>(
    'monthly_salary',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _salaryCreditDayMeta = const VerificationMeta(
    'salaryCreditDay',
  );
  @override
  late final GeneratedColumn<int> salaryCreditDay = GeneratedColumn<int>(
    'salary_credit_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _companyNameMeta = const VerificationMeta(
    'companyName',
  );
  @override
  late final GeneratedColumn<String> companyName = GeneratedColumn<String>(
    'company_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    isDarkMode,
    appLockEnabled,
    notificationDetectionEnabled,
    showDetectionNotifications,
    reminderEnabled,
    dailyReminderEnabled,
    weeklyReminderEnabled,
    reminderHour,
    reminderMinute,
    weeklyReminderWeekday,
    cardDueReminderEnabled,
    pendingTransactionReminderEnabled,
    settlementReminderEnabled,
    lastReminderShownAt,
    smsDetectionEnabled,
    smsPermissionAskedAt,
    smsBackfillEnabled,
    smsBackfillDays,
    smsLastScannedAt,
    hasCompletedOnboarding,
    quietHoursStartHour,
    quietHoursStartMinute,
    quietHoursEndHour,
    quietHoursEndMinute,
    smartAlertsEnabled,
    lowBalanceAlertsEnabled,
    lowBalanceThreshold,
    largeExpenseAlertsEnabled,
    largeExpenseThreshold,
    unusualSpendingAlertsEnabled,
    unusualSpendingMultiplier,
    recurringMerchantAlertsEnabled,
    weeklySummaryAlertsEnabled,
    monthlySummaryAlertsEnabled,
    userName,
    monthlySalary,
    salaryCreditDay,
    companyName,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('is_dark_mode')) {
      context.handle(
        _isDarkModeMeta,
        isDarkMode.isAcceptableOrUnknown(
          data['is_dark_mode']!,
          _isDarkModeMeta,
        ),
      );
    }
    if (data.containsKey('app_lock_enabled')) {
      context.handle(
        _appLockEnabledMeta,
        appLockEnabled.isAcceptableOrUnknown(
          data['app_lock_enabled']!,
          _appLockEnabledMeta,
        ),
      );
    }
    if (data.containsKey('notification_detection_enabled')) {
      context.handle(
        _notificationDetectionEnabledMeta,
        notificationDetectionEnabled.isAcceptableOrUnknown(
          data['notification_detection_enabled']!,
          _notificationDetectionEnabledMeta,
        ),
      );
    }
    if (data.containsKey('show_detection_notifications')) {
      context.handle(
        _showDetectionNotificationsMeta,
        showDetectionNotifications.isAcceptableOrUnknown(
          data['show_detection_notifications']!,
          _showDetectionNotificationsMeta,
        ),
      );
    }
    if (data.containsKey('reminder_enabled')) {
      context.handle(
        _reminderEnabledMeta,
        reminderEnabled.isAcceptableOrUnknown(
          data['reminder_enabled']!,
          _reminderEnabledMeta,
        ),
      );
    }
    if (data.containsKey('daily_reminder_enabled')) {
      context.handle(
        _dailyReminderEnabledMeta,
        dailyReminderEnabled.isAcceptableOrUnknown(
          data['daily_reminder_enabled']!,
          _dailyReminderEnabledMeta,
        ),
      );
    }
    if (data.containsKey('weekly_reminder_enabled')) {
      context.handle(
        _weeklyReminderEnabledMeta,
        weeklyReminderEnabled.isAcceptableOrUnknown(
          data['weekly_reminder_enabled']!,
          _weeklyReminderEnabledMeta,
        ),
      );
    }
    if (data.containsKey('reminder_hour')) {
      context.handle(
        _reminderHourMeta,
        reminderHour.isAcceptableOrUnknown(
          data['reminder_hour']!,
          _reminderHourMeta,
        ),
      );
    }
    if (data.containsKey('reminder_minute')) {
      context.handle(
        _reminderMinuteMeta,
        reminderMinute.isAcceptableOrUnknown(
          data['reminder_minute']!,
          _reminderMinuteMeta,
        ),
      );
    }
    if (data.containsKey('weekly_reminder_weekday')) {
      context.handle(
        _weeklyReminderWeekdayMeta,
        weeklyReminderWeekday.isAcceptableOrUnknown(
          data['weekly_reminder_weekday']!,
          _weeklyReminderWeekdayMeta,
        ),
      );
    }
    if (data.containsKey('card_due_reminder_enabled')) {
      context.handle(
        _cardDueReminderEnabledMeta,
        cardDueReminderEnabled.isAcceptableOrUnknown(
          data['card_due_reminder_enabled']!,
          _cardDueReminderEnabledMeta,
        ),
      );
    }
    if (data.containsKey('pending_transaction_reminder_enabled')) {
      context.handle(
        _pendingTransactionReminderEnabledMeta,
        pendingTransactionReminderEnabled.isAcceptableOrUnknown(
          data['pending_transaction_reminder_enabled']!,
          _pendingTransactionReminderEnabledMeta,
        ),
      );
    }
    if (data.containsKey('settlement_reminder_enabled')) {
      context.handle(
        _settlementReminderEnabledMeta,
        settlementReminderEnabled.isAcceptableOrUnknown(
          data['settlement_reminder_enabled']!,
          _settlementReminderEnabledMeta,
        ),
      );
    }
    if (data.containsKey('last_reminder_shown_at')) {
      context.handle(
        _lastReminderShownAtMeta,
        lastReminderShownAt.isAcceptableOrUnknown(
          data['last_reminder_shown_at']!,
          _lastReminderShownAtMeta,
        ),
      );
    }
    if (data.containsKey('sms_detection_enabled')) {
      context.handle(
        _smsDetectionEnabledMeta,
        smsDetectionEnabled.isAcceptableOrUnknown(
          data['sms_detection_enabled']!,
          _smsDetectionEnabledMeta,
        ),
      );
    }
    if (data.containsKey('sms_permission_asked_at')) {
      context.handle(
        _smsPermissionAskedAtMeta,
        smsPermissionAskedAt.isAcceptableOrUnknown(
          data['sms_permission_asked_at']!,
          _smsPermissionAskedAtMeta,
        ),
      );
    }
    if (data.containsKey('sms_backfill_enabled')) {
      context.handle(
        _smsBackfillEnabledMeta,
        smsBackfillEnabled.isAcceptableOrUnknown(
          data['sms_backfill_enabled']!,
          _smsBackfillEnabledMeta,
        ),
      );
    }
    if (data.containsKey('sms_backfill_days')) {
      context.handle(
        _smsBackfillDaysMeta,
        smsBackfillDays.isAcceptableOrUnknown(
          data['sms_backfill_days']!,
          _smsBackfillDaysMeta,
        ),
      );
    }
    if (data.containsKey('sms_last_scanned_at')) {
      context.handle(
        _smsLastScannedAtMeta,
        smsLastScannedAt.isAcceptableOrUnknown(
          data['sms_last_scanned_at']!,
          _smsLastScannedAtMeta,
        ),
      );
    }
    if (data.containsKey('has_completed_onboarding')) {
      context.handle(
        _hasCompletedOnboardingMeta,
        hasCompletedOnboarding.isAcceptableOrUnknown(
          data['has_completed_onboarding']!,
          _hasCompletedOnboardingMeta,
        ),
      );
    }
    if (data.containsKey('quiet_hours_start_hour')) {
      context.handle(
        _quietHoursStartHourMeta,
        quietHoursStartHour.isAcceptableOrUnknown(
          data['quiet_hours_start_hour']!,
          _quietHoursStartHourMeta,
        ),
      );
    }
    if (data.containsKey('quiet_hours_start_minute')) {
      context.handle(
        _quietHoursStartMinuteMeta,
        quietHoursStartMinute.isAcceptableOrUnknown(
          data['quiet_hours_start_minute']!,
          _quietHoursStartMinuteMeta,
        ),
      );
    }
    if (data.containsKey('quiet_hours_end_hour')) {
      context.handle(
        _quietHoursEndHourMeta,
        quietHoursEndHour.isAcceptableOrUnknown(
          data['quiet_hours_end_hour']!,
          _quietHoursEndHourMeta,
        ),
      );
    }
    if (data.containsKey('quiet_hours_end_minute')) {
      context.handle(
        _quietHoursEndMinuteMeta,
        quietHoursEndMinute.isAcceptableOrUnknown(
          data['quiet_hours_end_minute']!,
          _quietHoursEndMinuteMeta,
        ),
      );
    }
    if (data.containsKey('smart_alerts_enabled')) {
      context.handle(
        _smartAlertsEnabledMeta,
        smartAlertsEnabled.isAcceptableOrUnknown(
          data['smart_alerts_enabled']!,
          _smartAlertsEnabledMeta,
        ),
      );
    }
    if (data.containsKey('low_balance_alerts_enabled')) {
      context.handle(
        _lowBalanceAlertsEnabledMeta,
        lowBalanceAlertsEnabled.isAcceptableOrUnknown(
          data['low_balance_alerts_enabled']!,
          _lowBalanceAlertsEnabledMeta,
        ),
      );
    }
    if (data.containsKey('low_balance_threshold')) {
      context.handle(
        _lowBalanceThresholdMeta,
        lowBalanceThreshold.isAcceptableOrUnknown(
          data['low_balance_threshold']!,
          _lowBalanceThresholdMeta,
        ),
      );
    }
    if (data.containsKey('large_expense_alerts_enabled')) {
      context.handle(
        _largeExpenseAlertsEnabledMeta,
        largeExpenseAlertsEnabled.isAcceptableOrUnknown(
          data['large_expense_alerts_enabled']!,
          _largeExpenseAlertsEnabledMeta,
        ),
      );
    }
    if (data.containsKey('large_expense_threshold')) {
      context.handle(
        _largeExpenseThresholdMeta,
        largeExpenseThreshold.isAcceptableOrUnknown(
          data['large_expense_threshold']!,
          _largeExpenseThresholdMeta,
        ),
      );
    }
    if (data.containsKey('unusual_spending_alerts_enabled')) {
      context.handle(
        _unusualSpendingAlertsEnabledMeta,
        unusualSpendingAlertsEnabled.isAcceptableOrUnknown(
          data['unusual_spending_alerts_enabled']!,
          _unusualSpendingAlertsEnabledMeta,
        ),
      );
    }
    if (data.containsKey('unusual_spending_multiplier')) {
      context.handle(
        _unusualSpendingMultiplierMeta,
        unusualSpendingMultiplier.isAcceptableOrUnknown(
          data['unusual_spending_multiplier']!,
          _unusualSpendingMultiplierMeta,
        ),
      );
    }
    if (data.containsKey('recurring_merchant_alerts_enabled')) {
      context.handle(
        _recurringMerchantAlertsEnabledMeta,
        recurringMerchantAlertsEnabled.isAcceptableOrUnknown(
          data['recurring_merchant_alerts_enabled']!,
          _recurringMerchantAlertsEnabledMeta,
        ),
      );
    }
    if (data.containsKey('weekly_summary_alerts_enabled')) {
      context.handle(
        _weeklySummaryAlertsEnabledMeta,
        weeklySummaryAlertsEnabled.isAcceptableOrUnknown(
          data['weekly_summary_alerts_enabled']!,
          _weeklySummaryAlertsEnabledMeta,
        ),
      );
    }
    if (data.containsKey('monthly_summary_alerts_enabled')) {
      context.handle(
        _monthlySummaryAlertsEnabledMeta,
        monthlySummaryAlertsEnabled.isAcceptableOrUnknown(
          data['monthly_summary_alerts_enabled']!,
          _monthlySummaryAlertsEnabledMeta,
        ),
      );
    }
    if (data.containsKey('user_name')) {
      context.handle(
        _userNameMeta,
        userName.isAcceptableOrUnknown(data['user_name']!, _userNameMeta),
      );
    }
    if (data.containsKey('monthly_salary')) {
      context.handle(
        _monthlySalaryMeta,
        monthlySalary.isAcceptableOrUnknown(
          data['monthly_salary']!,
          _monthlySalaryMeta,
        ),
      );
    }
    if (data.containsKey('salary_credit_day')) {
      context.handle(
        _salaryCreditDayMeta,
        salaryCreditDay.isAcceptableOrUnknown(
          data['salary_credit_day']!,
          _salaryCreditDayMeta,
        ),
      );
    }
    if (data.containsKey('company_name')) {
      context.handle(
        _companyNameMeta,
        companyName.isAcceptableOrUnknown(
          data['company_name']!,
          _companyNameMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      isDarkMode: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dark_mode'],
      )!,
      appLockEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}app_lock_enabled'],
      )!,
      notificationDetectionEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notification_detection_enabled'],
      )!,
      showDetectionNotifications: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_detection_notifications'],
      )!,
      reminderEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}reminder_enabled'],
      )!,
      dailyReminderEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}daily_reminder_enabled'],
      )!,
      weeklyReminderEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}weekly_reminder_enabled'],
      )!,
      reminderHour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_hour'],
      )!,
      reminderMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_minute'],
      )!,
      weeklyReminderWeekday: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weekly_reminder_weekday'],
      )!,
      cardDueReminderEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}card_due_reminder_enabled'],
      )!,
      pendingTransactionReminderEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending_transaction_reminder_enabled'],
      )!,
      settlementReminderEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}settlement_reminder_enabled'],
      )!,
      lastReminderShownAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_reminder_shown_at'],
      ),
      smsDetectionEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sms_detection_enabled'],
      )!,
      smsPermissionAskedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sms_permission_asked_at'],
      ),
      smsBackfillEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sms_backfill_enabled'],
      )!,
      smsBackfillDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sms_backfill_days'],
      )!,
      smsLastScannedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sms_last_scanned_at'],
      ),
      hasCompletedOnboarding: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_completed_onboarding'],
      )!,
      quietHoursStartHour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quiet_hours_start_hour'],
      )!,
      quietHoursStartMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quiet_hours_start_minute'],
      )!,
      quietHoursEndHour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quiet_hours_end_hour'],
      )!,
      quietHoursEndMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quiet_hours_end_minute'],
      )!,
      smartAlertsEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}smart_alerts_enabled'],
      )!,
      lowBalanceAlertsEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}low_balance_alerts_enabled'],
      )!,
      lowBalanceThreshold: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}low_balance_threshold'],
      )!,
      largeExpenseAlertsEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}large_expense_alerts_enabled'],
      )!,
      largeExpenseThreshold: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}large_expense_threshold'],
      )!,
      unusualSpendingAlertsEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}unusual_spending_alerts_enabled'],
      )!,
      unusualSpendingMultiplier: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}unusual_spending_multiplier'],
      )!,
      recurringMerchantAlertsEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}recurring_merchant_alerts_enabled'],
      )!,
      weeklySummaryAlertsEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}weekly_summary_alerts_enabled'],
      )!,
      monthlySummaryAlertsEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}monthly_summary_alerts_enabled'],
      )!,
      userName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_name'],
      ),
      monthlySalary: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}monthly_salary'],
      ),
      salaryCreditDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}salary_credit_day'],
      ),
      companyName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_name'],
      ),
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final int id;
  final bool isDarkMode;
  final bool appLockEnabled;
  final bool notificationDetectionEnabled;
  final bool showDetectionNotifications;
  final bool reminderEnabled;
  final bool dailyReminderEnabled;
  final bool weeklyReminderEnabled;
  final int reminderHour;
  final int reminderMinute;
  final int weeklyReminderWeekday;
  final bool cardDueReminderEnabled;
  final bool pendingTransactionReminderEnabled;
  final bool settlementReminderEnabled;
  final DateTime? lastReminderShownAt;
  final bool smsDetectionEnabled;
  final DateTime? smsPermissionAskedAt;
  final bool smsBackfillEnabled;
  final int smsBackfillDays;
  final DateTime? smsLastScannedAt;
  final bool hasCompletedOnboarding;
  final int quietHoursStartHour;
  final int quietHoursStartMinute;
  final int quietHoursEndHour;
  final int quietHoursEndMinute;
  final bool smartAlertsEnabled;
  final bool lowBalanceAlertsEnabled;
  final double lowBalanceThreshold;
  final bool largeExpenseAlertsEnabled;
  final double largeExpenseThreshold;
  final bool unusualSpendingAlertsEnabled;
  final double unusualSpendingMultiplier;
  final bool recurringMerchantAlertsEnabled;
  final bool weeklySummaryAlertsEnabled;
  final bool monthlySummaryAlertsEnabled;
  final String? userName;
  final double? monthlySalary;
  final int? salaryCreditDay;
  final String? companyName;
  const AppSetting({
    required this.id,
    required this.isDarkMode,
    required this.appLockEnabled,
    required this.notificationDetectionEnabled,
    required this.showDetectionNotifications,
    required this.reminderEnabled,
    required this.dailyReminderEnabled,
    required this.weeklyReminderEnabled,
    required this.reminderHour,
    required this.reminderMinute,
    required this.weeklyReminderWeekday,
    required this.cardDueReminderEnabled,
    required this.pendingTransactionReminderEnabled,
    required this.settlementReminderEnabled,
    this.lastReminderShownAt,
    required this.smsDetectionEnabled,
    this.smsPermissionAskedAt,
    required this.smsBackfillEnabled,
    required this.smsBackfillDays,
    this.smsLastScannedAt,
    required this.hasCompletedOnboarding,
    required this.quietHoursStartHour,
    required this.quietHoursStartMinute,
    required this.quietHoursEndHour,
    required this.quietHoursEndMinute,
    required this.smartAlertsEnabled,
    required this.lowBalanceAlertsEnabled,
    required this.lowBalanceThreshold,
    required this.largeExpenseAlertsEnabled,
    required this.largeExpenseThreshold,
    required this.unusualSpendingAlertsEnabled,
    required this.unusualSpendingMultiplier,
    required this.recurringMerchantAlertsEnabled,
    required this.weeklySummaryAlertsEnabled,
    required this.monthlySummaryAlertsEnabled,
    this.userName,
    this.monthlySalary,
    this.salaryCreditDay,
    this.companyName,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['is_dark_mode'] = Variable<bool>(isDarkMode);
    map['app_lock_enabled'] = Variable<bool>(appLockEnabled);
    map['notification_detection_enabled'] = Variable<bool>(
      notificationDetectionEnabled,
    );
    map['show_detection_notifications'] = Variable<bool>(
      showDetectionNotifications,
    );
    map['reminder_enabled'] = Variable<bool>(reminderEnabled);
    map['daily_reminder_enabled'] = Variable<bool>(dailyReminderEnabled);
    map['weekly_reminder_enabled'] = Variable<bool>(weeklyReminderEnabled);
    map['reminder_hour'] = Variable<int>(reminderHour);
    map['reminder_minute'] = Variable<int>(reminderMinute);
    map['weekly_reminder_weekday'] = Variable<int>(weeklyReminderWeekday);
    map['card_due_reminder_enabled'] = Variable<bool>(cardDueReminderEnabled);
    map['pending_transaction_reminder_enabled'] = Variable<bool>(
      pendingTransactionReminderEnabled,
    );
    map['settlement_reminder_enabled'] = Variable<bool>(
      settlementReminderEnabled,
    );
    if (!nullToAbsent || lastReminderShownAt != null) {
      map['last_reminder_shown_at'] = Variable<DateTime>(lastReminderShownAt);
    }
    map['sms_detection_enabled'] = Variable<bool>(smsDetectionEnabled);
    if (!nullToAbsent || smsPermissionAskedAt != null) {
      map['sms_permission_asked_at'] = Variable<DateTime>(smsPermissionAskedAt);
    }
    map['sms_backfill_enabled'] = Variable<bool>(smsBackfillEnabled);
    map['sms_backfill_days'] = Variable<int>(smsBackfillDays);
    if (!nullToAbsent || smsLastScannedAt != null) {
      map['sms_last_scanned_at'] = Variable<DateTime>(smsLastScannedAt);
    }
    map['has_completed_onboarding'] = Variable<bool>(hasCompletedOnboarding);
    map['quiet_hours_start_hour'] = Variable<int>(quietHoursStartHour);
    map['quiet_hours_start_minute'] = Variable<int>(quietHoursStartMinute);
    map['quiet_hours_end_hour'] = Variable<int>(quietHoursEndHour);
    map['quiet_hours_end_minute'] = Variable<int>(quietHoursEndMinute);
    map['smart_alerts_enabled'] = Variable<bool>(smartAlertsEnabled);
    map['low_balance_alerts_enabled'] = Variable<bool>(lowBalanceAlertsEnabled);
    map['low_balance_threshold'] = Variable<double>(lowBalanceThreshold);
    map['large_expense_alerts_enabled'] = Variable<bool>(
      largeExpenseAlertsEnabled,
    );
    map['large_expense_threshold'] = Variable<double>(largeExpenseThreshold);
    map['unusual_spending_alerts_enabled'] = Variable<bool>(
      unusualSpendingAlertsEnabled,
    );
    map['unusual_spending_multiplier'] = Variable<double>(
      unusualSpendingMultiplier,
    );
    map['recurring_merchant_alerts_enabled'] = Variable<bool>(
      recurringMerchantAlertsEnabled,
    );
    map['weekly_summary_alerts_enabled'] = Variable<bool>(
      weeklySummaryAlertsEnabled,
    );
    map['monthly_summary_alerts_enabled'] = Variable<bool>(
      monthlySummaryAlertsEnabled,
    );
    if (!nullToAbsent || userName != null) {
      map['user_name'] = Variable<String>(userName);
    }
    if (!nullToAbsent || monthlySalary != null) {
      map['monthly_salary'] = Variable<double>(monthlySalary);
    }
    if (!nullToAbsent || salaryCreditDay != null) {
      map['salary_credit_day'] = Variable<int>(salaryCreditDay);
    }
    if (!nullToAbsent || companyName != null) {
      map['company_name'] = Variable<String>(companyName);
    }
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      isDarkMode: Value(isDarkMode),
      appLockEnabled: Value(appLockEnabled),
      notificationDetectionEnabled: Value(notificationDetectionEnabled),
      showDetectionNotifications: Value(showDetectionNotifications),
      reminderEnabled: Value(reminderEnabled),
      dailyReminderEnabled: Value(dailyReminderEnabled),
      weeklyReminderEnabled: Value(weeklyReminderEnabled),
      reminderHour: Value(reminderHour),
      reminderMinute: Value(reminderMinute),
      weeklyReminderWeekday: Value(weeklyReminderWeekday),
      cardDueReminderEnabled: Value(cardDueReminderEnabled),
      pendingTransactionReminderEnabled: Value(
        pendingTransactionReminderEnabled,
      ),
      settlementReminderEnabled: Value(settlementReminderEnabled),
      lastReminderShownAt: lastReminderShownAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReminderShownAt),
      smsDetectionEnabled: Value(smsDetectionEnabled),
      smsPermissionAskedAt: smsPermissionAskedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(smsPermissionAskedAt),
      smsBackfillEnabled: Value(smsBackfillEnabled),
      smsBackfillDays: Value(smsBackfillDays),
      smsLastScannedAt: smsLastScannedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(smsLastScannedAt),
      hasCompletedOnboarding: Value(hasCompletedOnboarding),
      quietHoursStartHour: Value(quietHoursStartHour),
      quietHoursStartMinute: Value(quietHoursStartMinute),
      quietHoursEndHour: Value(quietHoursEndHour),
      quietHoursEndMinute: Value(quietHoursEndMinute),
      smartAlertsEnabled: Value(smartAlertsEnabled),
      lowBalanceAlertsEnabled: Value(lowBalanceAlertsEnabled),
      lowBalanceThreshold: Value(lowBalanceThreshold),
      largeExpenseAlertsEnabled: Value(largeExpenseAlertsEnabled),
      largeExpenseThreshold: Value(largeExpenseThreshold),
      unusualSpendingAlertsEnabled: Value(unusualSpendingAlertsEnabled),
      unusualSpendingMultiplier: Value(unusualSpendingMultiplier),
      recurringMerchantAlertsEnabled: Value(recurringMerchantAlertsEnabled),
      weeklySummaryAlertsEnabled: Value(weeklySummaryAlertsEnabled),
      monthlySummaryAlertsEnabled: Value(monthlySummaryAlertsEnabled),
      userName: userName == null && nullToAbsent
          ? const Value.absent()
          : Value(userName),
      monthlySalary: monthlySalary == null && nullToAbsent
          ? const Value.absent()
          : Value(monthlySalary),
      salaryCreditDay: salaryCreditDay == null && nullToAbsent
          ? const Value.absent()
          : Value(salaryCreditDay),
      companyName: companyName == null && nullToAbsent
          ? const Value.absent()
          : Value(companyName),
    );
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      id: serializer.fromJson<int>(json['id']),
      isDarkMode: serializer.fromJson<bool>(json['isDarkMode']),
      appLockEnabled: serializer.fromJson<bool>(json['appLockEnabled']),
      notificationDetectionEnabled: serializer.fromJson<bool>(
        json['notificationDetectionEnabled'],
      ),
      showDetectionNotifications: serializer.fromJson<bool>(
        json['showDetectionNotifications'],
      ),
      reminderEnabled: serializer.fromJson<bool>(json['reminderEnabled']),
      dailyReminderEnabled: serializer.fromJson<bool>(
        json['dailyReminderEnabled'],
      ),
      weeklyReminderEnabled: serializer.fromJson<bool>(
        json['weeklyReminderEnabled'],
      ),
      reminderHour: serializer.fromJson<int>(json['reminderHour']),
      reminderMinute: serializer.fromJson<int>(json['reminderMinute']),
      weeklyReminderWeekday: serializer.fromJson<int>(
        json['weeklyReminderWeekday'],
      ),
      cardDueReminderEnabled: serializer.fromJson<bool>(
        json['cardDueReminderEnabled'],
      ),
      pendingTransactionReminderEnabled: serializer.fromJson<bool>(
        json['pendingTransactionReminderEnabled'],
      ),
      settlementReminderEnabled: serializer.fromJson<bool>(
        json['settlementReminderEnabled'],
      ),
      lastReminderShownAt: serializer.fromJson<DateTime?>(
        json['lastReminderShownAt'],
      ),
      smsDetectionEnabled: serializer.fromJson<bool>(
        json['smsDetectionEnabled'],
      ),
      smsPermissionAskedAt: serializer.fromJson<DateTime?>(
        json['smsPermissionAskedAt'],
      ),
      smsBackfillEnabled: serializer.fromJson<bool>(json['smsBackfillEnabled']),
      smsBackfillDays: serializer.fromJson<int>(json['smsBackfillDays']),
      smsLastScannedAt: serializer.fromJson<DateTime?>(
        json['smsLastScannedAt'],
      ),
      hasCompletedOnboarding: serializer.fromJson<bool>(
        json['hasCompletedOnboarding'],
      ),
      quietHoursStartHour: serializer.fromJson<int>(
        json['quietHoursStartHour'],
      ),
      quietHoursStartMinute: serializer.fromJson<int>(
        json['quietHoursStartMinute'],
      ),
      quietHoursEndHour: serializer.fromJson<int>(json['quietHoursEndHour']),
      quietHoursEndMinute: serializer.fromJson<int>(
        json['quietHoursEndMinute'],
      ),
      smartAlertsEnabled: serializer.fromJson<bool>(json['smartAlertsEnabled']),
      lowBalanceAlertsEnabled: serializer.fromJson<bool>(
        json['lowBalanceAlertsEnabled'],
      ),
      lowBalanceThreshold: serializer.fromJson<double>(
        json['lowBalanceThreshold'],
      ),
      largeExpenseAlertsEnabled: serializer.fromJson<bool>(
        json['largeExpenseAlertsEnabled'],
      ),
      largeExpenseThreshold: serializer.fromJson<double>(
        json['largeExpenseThreshold'],
      ),
      unusualSpendingAlertsEnabled: serializer.fromJson<bool>(
        json['unusualSpendingAlertsEnabled'],
      ),
      unusualSpendingMultiplier: serializer.fromJson<double>(
        json['unusualSpendingMultiplier'],
      ),
      recurringMerchantAlertsEnabled: serializer.fromJson<bool>(
        json['recurringMerchantAlertsEnabled'],
      ),
      weeklySummaryAlertsEnabled: serializer.fromJson<bool>(
        json['weeklySummaryAlertsEnabled'],
      ),
      monthlySummaryAlertsEnabled: serializer.fromJson<bool>(
        json['monthlySummaryAlertsEnabled'],
      ),
      userName: serializer.fromJson<String?>(json['userName']),
      monthlySalary: serializer.fromJson<double?>(json['monthlySalary']),
      salaryCreditDay: serializer.fromJson<int?>(json['salaryCreditDay']),
      companyName: serializer.fromJson<String?>(json['companyName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'isDarkMode': serializer.toJson<bool>(isDarkMode),
      'appLockEnabled': serializer.toJson<bool>(appLockEnabled),
      'notificationDetectionEnabled': serializer.toJson<bool>(
        notificationDetectionEnabled,
      ),
      'showDetectionNotifications': serializer.toJson<bool>(
        showDetectionNotifications,
      ),
      'reminderEnabled': serializer.toJson<bool>(reminderEnabled),
      'dailyReminderEnabled': serializer.toJson<bool>(dailyReminderEnabled),
      'weeklyReminderEnabled': serializer.toJson<bool>(weeklyReminderEnabled),
      'reminderHour': serializer.toJson<int>(reminderHour),
      'reminderMinute': serializer.toJson<int>(reminderMinute),
      'weeklyReminderWeekday': serializer.toJson<int>(weeklyReminderWeekday),
      'cardDueReminderEnabled': serializer.toJson<bool>(cardDueReminderEnabled),
      'pendingTransactionReminderEnabled': serializer.toJson<bool>(
        pendingTransactionReminderEnabled,
      ),
      'settlementReminderEnabled': serializer.toJson<bool>(
        settlementReminderEnabled,
      ),
      'lastReminderShownAt': serializer.toJson<DateTime?>(lastReminderShownAt),
      'smsDetectionEnabled': serializer.toJson<bool>(smsDetectionEnabled),
      'smsPermissionAskedAt': serializer.toJson<DateTime?>(
        smsPermissionAskedAt,
      ),
      'smsBackfillEnabled': serializer.toJson<bool>(smsBackfillEnabled),
      'smsBackfillDays': serializer.toJson<int>(smsBackfillDays),
      'smsLastScannedAt': serializer.toJson<DateTime?>(smsLastScannedAt),
      'hasCompletedOnboarding': serializer.toJson<bool>(hasCompletedOnboarding),
      'quietHoursStartHour': serializer.toJson<int>(quietHoursStartHour),
      'quietHoursStartMinute': serializer.toJson<int>(quietHoursStartMinute),
      'quietHoursEndHour': serializer.toJson<int>(quietHoursEndHour),
      'quietHoursEndMinute': serializer.toJson<int>(quietHoursEndMinute),
      'smartAlertsEnabled': serializer.toJson<bool>(smartAlertsEnabled),
      'lowBalanceAlertsEnabled': serializer.toJson<bool>(
        lowBalanceAlertsEnabled,
      ),
      'lowBalanceThreshold': serializer.toJson<double>(lowBalanceThreshold),
      'largeExpenseAlertsEnabled': serializer.toJson<bool>(
        largeExpenseAlertsEnabled,
      ),
      'largeExpenseThreshold': serializer.toJson<double>(largeExpenseThreshold),
      'unusualSpendingAlertsEnabled': serializer.toJson<bool>(
        unusualSpendingAlertsEnabled,
      ),
      'unusualSpendingMultiplier': serializer.toJson<double>(
        unusualSpendingMultiplier,
      ),
      'recurringMerchantAlertsEnabled': serializer.toJson<bool>(
        recurringMerchantAlertsEnabled,
      ),
      'weeklySummaryAlertsEnabled': serializer.toJson<bool>(
        weeklySummaryAlertsEnabled,
      ),
      'monthlySummaryAlertsEnabled': serializer.toJson<bool>(
        monthlySummaryAlertsEnabled,
      ),
      'userName': serializer.toJson<String?>(userName),
      'monthlySalary': serializer.toJson<double?>(monthlySalary),
      'salaryCreditDay': serializer.toJson<int?>(salaryCreditDay),
      'companyName': serializer.toJson<String?>(companyName),
    };
  }

  AppSetting copyWith({
    int? id,
    bool? isDarkMode,
    bool? appLockEnabled,
    bool? notificationDetectionEnabled,
    bool? showDetectionNotifications,
    bool? reminderEnabled,
    bool? dailyReminderEnabled,
    bool? weeklyReminderEnabled,
    int? reminderHour,
    int? reminderMinute,
    int? weeklyReminderWeekday,
    bool? cardDueReminderEnabled,
    bool? pendingTransactionReminderEnabled,
    bool? settlementReminderEnabled,
    Value<DateTime?> lastReminderShownAt = const Value.absent(),
    bool? smsDetectionEnabled,
    Value<DateTime?> smsPermissionAskedAt = const Value.absent(),
    bool? smsBackfillEnabled,
    int? smsBackfillDays,
    Value<DateTime?> smsLastScannedAt = const Value.absent(),
    bool? hasCompletedOnboarding,
    int? quietHoursStartHour,
    int? quietHoursStartMinute,
    int? quietHoursEndHour,
    int? quietHoursEndMinute,
    bool? smartAlertsEnabled,
    bool? lowBalanceAlertsEnabled,
    double? lowBalanceThreshold,
    bool? largeExpenseAlertsEnabled,
    double? largeExpenseThreshold,
    bool? unusualSpendingAlertsEnabled,
    double? unusualSpendingMultiplier,
    bool? recurringMerchantAlertsEnabled,
    bool? weeklySummaryAlertsEnabled,
    bool? monthlySummaryAlertsEnabled,
    Value<String?> userName = const Value.absent(),
    Value<double?> monthlySalary = const Value.absent(),
    Value<int?> salaryCreditDay = const Value.absent(),
    Value<String?> companyName = const Value.absent(),
  }) => AppSetting(
    id: id ?? this.id,
    isDarkMode: isDarkMode ?? this.isDarkMode,
    appLockEnabled: appLockEnabled ?? this.appLockEnabled,
    notificationDetectionEnabled:
        notificationDetectionEnabled ?? this.notificationDetectionEnabled,
    showDetectionNotifications:
        showDetectionNotifications ?? this.showDetectionNotifications,
    reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
    weeklyReminderEnabled: weeklyReminderEnabled ?? this.weeklyReminderEnabled,
    reminderHour: reminderHour ?? this.reminderHour,
    reminderMinute: reminderMinute ?? this.reminderMinute,
    weeklyReminderWeekday: weeklyReminderWeekday ?? this.weeklyReminderWeekday,
    cardDueReminderEnabled:
        cardDueReminderEnabled ?? this.cardDueReminderEnabled,
    pendingTransactionReminderEnabled:
        pendingTransactionReminderEnabled ??
        this.pendingTransactionReminderEnabled,
    settlementReminderEnabled:
        settlementReminderEnabled ?? this.settlementReminderEnabled,
    lastReminderShownAt: lastReminderShownAt.present
        ? lastReminderShownAt.value
        : this.lastReminderShownAt,
    smsDetectionEnabled: smsDetectionEnabled ?? this.smsDetectionEnabled,
    smsPermissionAskedAt: smsPermissionAskedAt.present
        ? smsPermissionAskedAt.value
        : this.smsPermissionAskedAt,
    smsBackfillEnabled: smsBackfillEnabled ?? this.smsBackfillEnabled,
    smsBackfillDays: smsBackfillDays ?? this.smsBackfillDays,
    smsLastScannedAt: smsLastScannedAt.present
        ? smsLastScannedAt.value
        : this.smsLastScannedAt,
    hasCompletedOnboarding:
        hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    quietHoursStartHour: quietHoursStartHour ?? this.quietHoursStartHour,
    quietHoursStartMinute: quietHoursStartMinute ?? this.quietHoursStartMinute,
    quietHoursEndHour: quietHoursEndHour ?? this.quietHoursEndHour,
    quietHoursEndMinute: quietHoursEndMinute ?? this.quietHoursEndMinute,
    smartAlertsEnabled: smartAlertsEnabled ?? this.smartAlertsEnabled,
    lowBalanceAlertsEnabled:
        lowBalanceAlertsEnabled ?? this.lowBalanceAlertsEnabled,
    lowBalanceThreshold: lowBalanceThreshold ?? this.lowBalanceThreshold,
    largeExpenseAlertsEnabled:
        largeExpenseAlertsEnabled ?? this.largeExpenseAlertsEnabled,
    largeExpenseThreshold: largeExpenseThreshold ?? this.largeExpenseThreshold,
    unusualSpendingAlertsEnabled:
        unusualSpendingAlertsEnabled ?? this.unusualSpendingAlertsEnabled,
    unusualSpendingMultiplier:
        unusualSpendingMultiplier ?? this.unusualSpendingMultiplier,
    recurringMerchantAlertsEnabled:
        recurringMerchantAlertsEnabled ?? this.recurringMerchantAlertsEnabled,
    weeklySummaryAlertsEnabled:
        weeklySummaryAlertsEnabled ?? this.weeklySummaryAlertsEnabled,
    monthlySummaryAlertsEnabled:
        monthlySummaryAlertsEnabled ?? this.monthlySummaryAlertsEnabled,
    userName: userName.present ? userName.value : this.userName,
    monthlySalary: monthlySalary.present
        ? monthlySalary.value
        : this.monthlySalary,
    salaryCreditDay: salaryCreditDay.present
        ? salaryCreditDay.value
        : this.salaryCreditDay,
    companyName: companyName.present ? companyName.value : this.companyName,
  );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      id: data.id.present ? data.id.value : this.id,
      isDarkMode: data.isDarkMode.present
          ? data.isDarkMode.value
          : this.isDarkMode,
      appLockEnabled: data.appLockEnabled.present
          ? data.appLockEnabled.value
          : this.appLockEnabled,
      notificationDetectionEnabled: data.notificationDetectionEnabled.present
          ? data.notificationDetectionEnabled.value
          : this.notificationDetectionEnabled,
      showDetectionNotifications: data.showDetectionNotifications.present
          ? data.showDetectionNotifications.value
          : this.showDetectionNotifications,
      reminderEnabled: data.reminderEnabled.present
          ? data.reminderEnabled.value
          : this.reminderEnabled,
      dailyReminderEnabled: data.dailyReminderEnabled.present
          ? data.dailyReminderEnabled.value
          : this.dailyReminderEnabled,
      weeklyReminderEnabled: data.weeklyReminderEnabled.present
          ? data.weeklyReminderEnabled.value
          : this.weeklyReminderEnabled,
      reminderHour: data.reminderHour.present
          ? data.reminderHour.value
          : this.reminderHour,
      reminderMinute: data.reminderMinute.present
          ? data.reminderMinute.value
          : this.reminderMinute,
      weeklyReminderWeekday: data.weeklyReminderWeekday.present
          ? data.weeklyReminderWeekday.value
          : this.weeklyReminderWeekday,
      cardDueReminderEnabled: data.cardDueReminderEnabled.present
          ? data.cardDueReminderEnabled.value
          : this.cardDueReminderEnabled,
      pendingTransactionReminderEnabled:
          data.pendingTransactionReminderEnabled.present
          ? data.pendingTransactionReminderEnabled.value
          : this.pendingTransactionReminderEnabled,
      settlementReminderEnabled: data.settlementReminderEnabled.present
          ? data.settlementReminderEnabled.value
          : this.settlementReminderEnabled,
      lastReminderShownAt: data.lastReminderShownAt.present
          ? data.lastReminderShownAt.value
          : this.lastReminderShownAt,
      smsDetectionEnabled: data.smsDetectionEnabled.present
          ? data.smsDetectionEnabled.value
          : this.smsDetectionEnabled,
      smsPermissionAskedAt: data.smsPermissionAskedAt.present
          ? data.smsPermissionAskedAt.value
          : this.smsPermissionAskedAt,
      smsBackfillEnabled: data.smsBackfillEnabled.present
          ? data.smsBackfillEnabled.value
          : this.smsBackfillEnabled,
      smsBackfillDays: data.smsBackfillDays.present
          ? data.smsBackfillDays.value
          : this.smsBackfillDays,
      smsLastScannedAt: data.smsLastScannedAt.present
          ? data.smsLastScannedAt.value
          : this.smsLastScannedAt,
      hasCompletedOnboarding: data.hasCompletedOnboarding.present
          ? data.hasCompletedOnboarding.value
          : this.hasCompletedOnboarding,
      quietHoursStartHour: data.quietHoursStartHour.present
          ? data.quietHoursStartHour.value
          : this.quietHoursStartHour,
      quietHoursStartMinute: data.quietHoursStartMinute.present
          ? data.quietHoursStartMinute.value
          : this.quietHoursStartMinute,
      quietHoursEndHour: data.quietHoursEndHour.present
          ? data.quietHoursEndHour.value
          : this.quietHoursEndHour,
      quietHoursEndMinute: data.quietHoursEndMinute.present
          ? data.quietHoursEndMinute.value
          : this.quietHoursEndMinute,
      smartAlertsEnabled: data.smartAlertsEnabled.present
          ? data.smartAlertsEnabled.value
          : this.smartAlertsEnabled,
      lowBalanceAlertsEnabled: data.lowBalanceAlertsEnabled.present
          ? data.lowBalanceAlertsEnabled.value
          : this.lowBalanceAlertsEnabled,
      lowBalanceThreshold: data.lowBalanceThreshold.present
          ? data.lowBalanceThreshold.value
          : this.lowBalanceThreshold,
      largeExpenseAlertsEnabled: data.largeExpenseAlertsEnabled.present
          ? data.largeExpenseAlertsEnabled.value
          : this.largeExpenseAlertsEnabled,
      largeExpenseThreshold: data.largeExpenseThreshold.present
          ? data.largeExpenseThreshold.value
          : this.largeExpenseThreshold,
      unusualSpendingAlertsEnabled: data.unusualSpendingAlertsEnabled.present
          ? data.unusualSpendingAlertsEnabled.value
          : this.unusualSpendingAlertsEnabled,
      unusualSpendingMultiplier: data.unusualSpendingMultiplier.present
          ? data.unusualSpendingMultiplier.value
          : this.unusualSpendingMultiplier,
      recurringMerchantAlertsEnabled:
          data.recurringMerchantAlertsEnabled.present
          ? data.recurringMerchantAlertsEnabled.value
          : this.recurringMerchantAlertsEnabled,
      weeklySummaryAlertsEnabled: data.weeklySummaryAlertsEnabled.present
          ? data.weeklySummaryAlertsEnabled.value
          : this.weeklySummaryAlertsEnabled,
      monthlySummaryAlertsEnabled: data.monthlySummaryAlertsEnabled.present
          ? data.monthlySummaryAlertsEnabled.value
          : this.monthlySummaryAlertsEnabled,
      userName: data.userName.present ? data.userName.value : this.userName,
      monthlySalary: data.monthlySalary.present
          ? data.monthlySalary.value
          : this.monthlySalary,
      salaryCreditDay: data.salaryCreditDay.present
          ? data.salaryCreditDay.value
          : this.salaryCreditDay,
      companyName: data.companyName.present
          ? data.companyName.value
          : this.companyName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('id: $id, ')
          ..write('isDarkMode: $isDarkMode, ')
          ..write('appLockEnabled: $appLockEnabled, ')
          ..write(
            'notificationDetectionEnabled: $notificationDetectionEnabled, ',
          )
          ..write('showDetectionNotifications: $showDetectionNotifications, ')
          ..write('reminderEnabled: $reminderEnabled, ')
          ..write('dailyReminderEnabled: $dailyReminderEnabled, ')
          ..write('weeklyReminderEnabled: $weeklyReminderEnabled, ')
          ..write('reminderHour: $reminderHour, ')
          ..write('reminderMinute: $reminderMinute, ')
          ..write('weeklyReminderWeekday: $weeklyReminderWeekday, ')
          ..write('cardDueReminderEnabled: $cardDueReminderEnabled, ')
          ..write(
            'pendingTransactionReminderEnabled: $pendingTransactionReminderEnabled, ',
          )
          ..write('settlementReminderEnabled: $settlementReminderEnabled, ')
          ..write('lastReminderShownAt: $lastReminderShownAt, ')
          ..write('smsDetectionEnabled: $smsDetectionEnabled, ')
          ..write('smsPermissionAskedAt: $smsPermissionAskedAt, ')
          ..write('smsBackfillEnabled: $smsBackfillEnabled, ')
          ..write('smsBackfillDays: $smsBackfillDays, ')
          ..write('smsLastScannedAt: $smsLastScannedAt, ')
          ..write('hasCompletedOnboarding: $hasCompletedOnboarding, ')
          ..write('quietHoursStartHour: $quietHoursStartHour, ')
          ..write('quietHoursStartMinute: $quietHoursStartMinute, ')
          ..write('quietHoursEndHour: $quietHoursEndHour, ')
          ..write('quietHoursEndMinute: $quietHoursEndMinute, ')
          ..write('smartAlertsEnabled: $smartAlertsEnabled, ')
          ..write('lowBalanceAlertsEnabled: $lowBalanceAlertsEnabled, ')
          ..write('lowBalanceThreshold: $lowBalanceThreshold, ')
          ..write('largeExpenseAlertsEnabled: $largeExpenseAlertsEnabled, ')
          ..write('largeExpenseThreshold: $largeExpenseThreshold, ')
          ..write(
            'unusualSpendingAlertsEnabled: $unusualSpendingAlertsEnabled, ',
          )
          ..write('unusualSpendingMultiplier: $unusualSpendingMultiplier, ')
          ..write(
            'recurringMerchantAlertsEnabled: $recurringMerchantAlertsEnabled, ',
          )
          ..write('weeklySummaryAlertsEnabled: $weeklySummaryAlertsEnabled, ')
          ..write('monthlySummaryAlertsEnabled: $monthlySummaryAlertsEnabled, ')
          ..write('userName: $userName, ')
          ..write('monthlySalary: $monthlySalary, ')
          ..write('salaryCreditDay: $salaryCreditDay, ')
          ..write('companyName: $companyName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    isDarkMode,
    appLockEnabled,
    notificationDetectionEnabled,
    showDetectionNotifications,
    reminderEnabled,
    dailyReminderEnabled,
    weeklyReminderEnabled,
    reminderHour,
    reminderMinute,
    weeklyReminderWeekday,
    cardDueReminderEnabled,
    pendingTransactionReminderEnabled,
    settlementReminderEnabled,
    lastReminderShownAt,
    smsDetectionEnabled,
    smsPermissionAskedAt,
    smsBackfillEnabled,
    smsBackfillDays,
    smsLastScannedAt,
    hasCompletedOnboarding,
    quietHoursStartHour,
    quietHoursStartMinute,
    quietHoursEndHour,
    quietHoursEndMinute,
    smartAlertsEnabled,
    lowBalanceAlertsEnabled,
    lowBalanceThreshold,
    largeExpenseAlertsEnabled,
    largeExpenseThreshold,
    unusualSpendingAlertsEnabled,
    unusualSpendingMultiplier,
    recurringMerchantAlertsEnabled,
    weeklySummaryAlertsEnabled,
    monthlySummaryAlertsEnabled,
    userName,
    monthlySalary,
    salaryCreditDay,
    companyName,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.id == this.id &&
          other.isDarkMode == this.isDarkMode &&
          other.appLockEnabled == this.appLockEnabled &&
          other.notificationDetectionEnabled ==
              this.notificationDetectionEnabled &&
          other.showDetectionNotifications == this.showDetectionNotifications &&
          other.reminderEnabled == this.reminderEnabled &&
          other.dailyReminderEnabled == this.dailyReminderEnabled &&
          other.weeklyReminderEnabled == this.weeklyReminderEnabled &&
          other.reminderHour == this.reminderHour &&
          other.reminderMinute == this.reminderMinute &&
          other.weeklyReminderWeekday == this.weeklyReminderWeekday &&
          other.cardDueReminderEnabled == this.cardDueReminderEnabled &&
          other.pendingTransactionReminderEnabled ==
              this.pendingTransactionReminderEnabled &&
          other.settlementReminderEnabled == this.settlementReminderEnabled &&
          other.lastReminderShownAt == this.lastReminderShownAt &&
          other.smsDetectionEnabled == this.smsDetectionEnabled &&
          other.smsPermissionAskedAt == this.smsPermissionAskedAt &&
          other.smsBackfillEnabled == this.smsBackfillEnabled &&
          other.smsBackfillDays == this.smsBackfillDays &&
          other.smsLastScannedAt == this.smsLastScannedAt &&
          other.hasCompletedOnboarding == this.hasCompletedOnboarding &&
          other.quietHoursStartHour == this.quietHoursStartHour &&
          other.quietHoursStartMinute == this.quietHoursStartMinute &&
          other.quietHoursEndHour == this.quietHoursEndHour &&
          other.quietHoursEndMinute == this.quietHoursEndMinute &&
          other.smartAlertsEnabled == this.smartAlertsEnabled &&
          other.lowBalanceAlertsEnabled == this.lowBalanceAlertsEnabled &&
          other.lowBalanceThreshold == this.lowBalanceThreshold &&
          other.largeExpenseAlertsEnabled == this.largeExpenseAlertsEnabled &&
          other.largeExpenseThreshold == this.largeExpenseThreshold &&
          other.unusualSpendingAlertsEnabled ==
              this.unusualSpendingAlertsEnabled &&
          other.unusualSpendingMultiplier == this.unusualSpendingMultiplier &&
          other.recurringMerchantAlertsEnabled ==
              this.recurringMerchantAlertsEnabled &&
          other.weeklySummaryAlertsEnabled == this.weeklySummaryAlertsEnabled &&
          other.monthlySummaryAlertsEnabled ==
              this.monthlySummaryAlertsEnabled &&
          other.userName == this.userName &&
          other.monthlySalary == this.monthlySalary &&
          other.salaryCreditDay == this.salaryCreditDay &&
          other.companyName == this.companyName);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<int> id;
  final Value<bool> isDarkMode;
  final Value<bool> appLockEnabled;
  final Value<bool> notificationDetectionEnabled;
  final Value<bool> showDetectionNotifications;
  final Value<bool> reminderEnabled;
  final Value<bool> dailyReminderEnabled;
  final Value<bool> weeklyReminderEnabled;
  final Value<int> reminderHour;
  final Value<int> reminderMinute;
  final Value<int> weeklyReminderWeekday;
  final Value<bool> cardDueReminderEnabled;
  final Value<bool> pendingTransactionReminderEnabled;
  final Value<bool> settlementReminderEnabled;
  final Value<DateTime?> lastReminderShownAt;
  final Value<bool> smsDetectionEnabled;
  final Value<DateTime?> smsPermissionAskedAt;
  final Value<bool> smsBackfillEnabled;
  final Value<int> smsBackfillDays;
  final Value<DateTime?> smsLastScannedAt;
  final Value<bool> hasCompletedOnboarding;
  final Value<int> quietHoursStartHour;
  final Value<int> quietHoursStartMinute;
  final Value<int> quietHoursEndHour;
  final Value<int> quietHoursEndMinute;
  final Value<bool> smartAlertsEnabled;
  final Value<bool> lowBalanceAlertsEnabled;
  final Value<double> lowBalanceThreshold;
  final Value<bool> largeExpenseAlertsEnabled;
  final Value<double> largeExpenseThreshold;
  final Value<bool> unusualSpendingAlertsEnabled;
  final Value<double> unusualSpendingMultiplier;
  final Value<bool> recurringMerchantAlertsEnabled;
  final Value<bool> weeklySummaryAlertsEnabled;
  final Value<bool> monthlySummaryAlertsEnabled;
  final Value<String?> userName;
  final Value<double?> monthlySalary;
  final Value<int?> salaryCreditDay;
  final Value<String?> companyName;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.isDarkMode = const Value.absent(),
    this.appLockEnabled = const Value.absent(),
    this.notificationDetectionEnabled = const Value.absent(),
    this.showDetectionNotifications = const Value.absent(),
    this.reminderEnabled = const Value.absent(),
    this.dailyReminderEnabled = const Value.absent(),
    this.weeklyReminderEnabled = const Value.absent(),
    this.reminderHour = const Value.absent(),
    this.reminderMinute = const Value.absent(),
    this.weeklyReminderWeekday = const Value.absent(),
    this.cardDueReminderEnabled = const Value.absent(),
    this.pendingTransactionReminderEnabled = const Value.absent(),
    this.settlementReminderEnabled = const Value.absent(),
    this.lastReminderShownAt = const Value.absent(),
    this.smsDetectionEnabled = const Value.absent(),
    this.smsPermissionAskedAt = const Value.absent(),
    this.smsBackfillEnabled = const Value.absent(),
    this.smsBackfillDays = const Value.absent(),
    this.smsLastScannedAt = const Value.absent(),
    this.hasCompletedOnboarding = const Value.absent(),
    this.quietHoursStartHour = const Value.absent(),
    this.quietHoursStartMinute = const Value.absent(),
    this.quietHoursEndHour = const Value.absent(),
    this.quietHoursEndMinute = const Value.absent(),
    this.smartAlertsEnabled = const Value.absent(),
    this.lowBalanceAlertsEnabled = const Value.absent(),
    this.lowBalanceThreshold = const Value.absent(),
    this.largeExpenseAlertsEnabled = const Value.absent(),
    this.largeExpenseThreshold = const Value.absent(),
    this.unusualSpendingAlertsEnabled = const Value.absent(),
    this.unusualSpendingMultiplier = const Value.absent(),
    this.recurringMerchantAlertsEnabled = const Value.absent(),
    this.weeklySummaryAlertsEnabled = const Value.absent(),
    this.monthlySummaryAlertsEnabled = const Value.absent(),
    this.userName = const Value.absent(),
    this.monthlySalary = const Value.absent(),
    this.salaryCreditDay = const Value.absent(),
    this.companyName = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.isDarkMode = const Value.absent(),
    this.appLockEnabled = const Value.absent(),
    this.notificationDetectionEnabled = const Value.absent(),
    this.showDetectionNotifications = const Value.absent(),
    this.reminderEnabled = const Value.absent(),
    this.dailyReminderEnabled = const Value.absent(),
    this.weeklyReminderEnabled = const Value.absent(),
    this.reminderHour = const Value.absent(),
    this.reminderMinute = const Value.absent(),
    this.weeklyReminderWeekday = const Value.absent(),
    this.cardDueReminderEnabled = const Value.absent(),
    this.pendingTransactionReminderEnabled = const Value.absent(),
    this.settlementReminderEnabled = const Value.absent(),
    this.lastReminderShownAt = const Value.absent(),
    this.smsDetectionEnabled = const Value.absent(),
    this.smsPermissionAskedAt = const Value.absent(),
    this.smsBackfillEnabled = const Value.absent(),
    this.smsBackfillDays = const Value.absent(),
    this.smsLastScannedAt = const Value.absent(),
    this.hasCompletedOnboarding = const Value.absent(),
    this.quietHoursStartHour = const Value.absent(),
    this.quietHoursStartMinute = const Value.absent(),
    this.quietHoursEndHour = const Value.absent(),
    this.quietHoursEndMinute = const Value.absent(),
    this.smartAlertsEnabled = const Value.absent(),
    this.lowBalanceAlertsEnabled = const Value.absent(),
    this.lowBalanceThreshold = const Value.absent(),
    this.largeExpenseAlertsEnabled = const Value.absent(),
    this.largeExpenseThreshold = const Value.absent(),
    this.unusualSpendingAlertsEnabled = const Value.absent(),
    this.unusualSpendingMultiplier = const Value.absent(),
    this.recurringMerchantAlertsEnabled = const Value.absent(),
    this.weeklySummaryAlertsEnabled = const Value.absent(),
    this.monthlySummaryAlertsEnabled = const Value.absent(),
    this.userName = const Value.absent(),
    this.monthlySalary = const Value.absent(),
    this.salaryCreditDay = const Value.absent(),
    this.companyName = const Value.absent(),
  });
  static Insertable<AppSetting> custom({
    Expression<int>? id,
    Expression<bool>? isDarkMode,
    Expression<bool>? appLockEnabled,
    Expression<bool>? notificationDetectionEnabled,
    Expression<bool>? showDetectionNotifications,
    Expression<bool>? reminderEnabled,
    Expression<bool>? dailyReminderEnabled,
    Expression<bool>? weeklyReminderEnabled,
    Expression<int>? reminderHour,
    Expression<int>? reminderMinute,
    Expression<int>? weeklyReminderWeekday,
    Expression<bool>? cardDueReminderEnabled,
    Expression<bool>? pendingTransactionReminderEnabled,
    Expression<bool>? settlementReminderEnabled,
    Expression<DateTime>? lastReminderShownAt,
    Expression<bool>? smsDetectionEnabled,
    Expression<DateTime>? smsPermissionAskedAt,
    Expression<bool>? smsBackfillEnabled,
    Expression<int>? smsBackfillDays,
    Expression<DateTime>? smsLastScannedAt,
    Expression<bool>? hasCompletedOnboarding,
    Expression<int>? quietHoursStartHour,
    Expression<int>? quietHoursStartMinute,
    Expression<int>? quietHoursEndHour,
    Expression<int>? quietHoursEndMinute,
    Expression<bool>? smartAlertsEnabled,
    Expression<bool>? lowBalanceAlertsEnabled,
    Expression<double>? lowBalanceThreshold,
    Expression<bool>? largeExpenseAlertsEnabled,
    Expression<double>? largeExpenseThreshold,
    Expression<bool>? unusualSpendingAlertsEnabled,
    Expression<double>? unusualSpendingMultiplier,
    Expression<bool>? recurringMerchantAlertsEnabled,
    Expression<bool>? weeklySummaryAlertsEnabled,
    Expression<bool>? monthlySummaryAlertsEnabled,
    Expression<String>? userName,
    Expression<double>? monthlySalary,
    Expression<int>? salaryCreditDay,
    Expression<String>? companyName,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (isDarkMode != null) 'is_dark_mode': isDarkMode,
      if (appLockEnabled != null) 'app_lock_enabled': appLockEnabled,
      if (notificationDetectionEnabled != null)
        'notification_detection_enabled': notificationDetectionEnabled,
      if (showDetectionNotifications != null)
        'show_detection_notifications': showDetectionNotifications,
      if (reminderEnabled != null) 'reminder_enabled': reminderEnabled,
      if (dailyReminderEnabled != null)
        'daily_reminder_enabled': dailyReminderEnabled,
      if (weeklyReminderEnabled != null)
        'weekly_reminder_enabled': weeklyReminderEnabled,
      if (reminderHour != null) 'reminder_hour': reminderHour,
      if (reminderMinute != null) 'reminder_minute': reminderMinute,
      if (weeklyReminderWeekday != null)
        'weekly_reminder_weekday': weeklyReminderWeekday,
      if (cardDueReminderEnabled != null)
        'card_due_reminder_enabled': cardDueReminderEnabled,
      if (pendingTransactionReminderEnabled != null)
        'pending_transaction_reminder_enabled':
            pendingTransactionReminderEnabled,
      if (settlementReminderEnabled != null)
        'settlement_reminder_enabled': settlementReminderEnabled,
      if (lastReminderShownAt != null)
        'last_reminder_shown_at': lastReminderShownAt,
      if (smsDetectionEnabled != null)
        'sms_detection_enabled': smsDetectionEnabled,
      if (smsPermissionAskedAt != null)
        'sms_permission_asked_at': smsPermissionAskedAt,
      if (smsBackfillEnabled != null)
        'sms_backfill_enabled': smsBackfillEnabled,
      if (smsBackfillDays != null) 'sms_backfill_days': smsBackfillDays,
      if (smsLastScannedAt != null) 'sms_last_scanned_at': smsLastScannedAt,
      if (hasCompletedOnboarding != null)
        'has_completed_onboarding': hasCompletedOnboarding,
      if (quietHoursStartHour != null)
        'quiet_hours_start_hour': quietHoursStartHour,
      if (quietHoursStartMinute != null)
        'quiet_hours_start_minute': quietHoursStartMinute,
      if (quietHoursEndHour != null) 'quiet_hours_end_hour': quietHoursEndHour,
      if (quietHoursEndMinute != null)
        'quiet_hours_end_minute': quietHoursEndMinute,
      if (smartAlertsEnabled != null)
        'smart_alerts_enabled': smartAlertsEnabled,
      if (lowBalanceAlertsEnabled != null)
        'low_balance_alerts_enabled': lowBalanceAlertsEnabled,
      if (lowBalanceThreshold != null)
        'low_balance_threshold': lowBalanceThreshold,
      if (largeExpenseAlertsEnabled != null)
        'large_expense_alerts_enabled': largeExpenseAlertsEnabled,
      if (largeExpenseThreshold != null)
        'large_expense_threshold': largeExpenseThreshold,
      if (unusualSpendingAlertsEnabled != null)
        'unusual_spending_alerts_enabled': unusualSpendingAlertsEnabled,
      if (unusualSpendingMultiplier != null)
        'unusual_spending_multiplier': unusualSpendingMultiplier,
      if (recurringMerchantAlertsEnabled != null)
        'recurring_merchant_alerts_enabled': recurringMerchantAlertsEnabled,
      if (weeklySummaryAlertsEnabled != null)
        'weekly_summary_alerts_enabled': weeklySummaryAlertsEnabled,
      if (monthlySummaryAlertsEnabled != null)
        'monthly_summary_alerts_enabled': monthlySummaryAlertsEnabled,
      if (userName != null) 'user_name': userName,
      if (monthlySalary != null) 'monthly_salary': monthlySalary,
      if (salaryCreditDay != null) 'salary_credit_day': salaryCreditDay,
      if (companyName != null) 'company_name': companyName,
    });
  }

  AppSettingsCompanion copyWith({
    Value<int>? id,
    Value<bool>? isDarkMode,
    Value<bool>? appLockEnabled,
    Value<bool>? notificationDetectionEnabled,
    Value<bool>? showDetectionNotifications,
    Value<bool>? reminderEnabled,
    Value<bool>? dailyReminderEnabled,
    Value<bool>? weeklyReminderEnabled,
    Value<int>? reminderHour,
    Value<int>? reminderMinute,
    Value<int>? weeklyReminderWeekday,
    Value<bool>? cardDueReminderEnabled,
    Value<bool>? pendingTransactionReminderEnabled,
    Value<bool>? settlementReminderEnabled,
    Value<DateTime?>? lastReminderShownAt,
    Value<bool>? smsDetectionEnabled,
    Value<DateTime?>? smsPermissionAskedAt,
    Value<bool>? smsBackfillEnabled,
    Value<int>? smsBackfillDays,
    Value<DateTime?>? smsLastScannedAt,
    Value<bool>? hasCompletedOnboarding,
    Value<int>? quietHoursStartHour,
    Value<int>? quietHoursStartMinute,
    Value<int>? quietHoursEndHour,
    Value<int>? quietHoursEndMinute,
    Value<bool>? smartAlertsEnabled,
    Value<bool>? lowBalanceAlertsEnabled,
    Value<double>? lowBalanceThreshold,
    Value<bool>? largeExpenseAlertsEnabled,
    Value<double>? largeExpenseThreshold,
    Value<bool>? unusualSpendingAlertsEnabled,
    Value<double>? unusualSpendingMultiplier,
    Value<bool>? recurringMerchantAlertsEnabled,
    Value<bool>? weeklySummaryAlertsEnabled,
    Value<bool>? monthlySummaryAlertsEnabled,
    Value<String?>? userName,
    Value<double?>? monthlySalary,
    Value<int?>? salaryCreditDay,
    Value<String?>? companyName,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      notificationDetectionEnabled:
          notificationDetectionEnabled ?? this.notificationDetectionEnabled,
      showDetectionNotifications:
          showDetectionNotifications ?? this.showDetectionNotifications,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      weeklyReminderEnabled:
          weeklyReminderEnabled ?? this.weeklyReminderEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      weeklyReminderWeekday:
          weeklyReminderWeekday ?? this.weeklyReminderWeekday,
      cardDueReminderEnabled:
          cardDueReminderEnabled ?? this.cardDueReminderEnabled,
      pendingTransactionReminderEnabled:
          pendingTransactionReminderEnabled ??
          this.pendingTransactionReminderEnabled,
      settlementReminderEnabled:
          settlementReminderEnabled ?? this.settlementReminderEnabled,
      lastReminderShownAt: lastReminderShownAt ?? this.lastReminderShownAt,
      smsDetectionEnabled: smsDetectionEnabled ?? this.smsDetectionEnabled,
      smsPermissionAskedAt: smsPermissionAskedAt ?? this.smsPermissionAskedAt,
      smsBackfillEnabled: smsBackfillEnabled ?? this.smsBackfillEnabled,
      smsBackfillDays: smsBackfillDays ?? this.smsBackfillDays,
      smsLastScannedAt: smsLastScannedAt ?? this.smsLastScannedAt,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      quietHoursStartHour: quietHoursStartHour ?? this.quietHoursStartHour,
      quietHoursStartMinute:
          quietHoursStartMinute ?? this.quietHoursStartMinute,
      quietHoursEndHour: quietHoursEndHour ?? this.quietHoursEndHour,
      quietHoursEndMinute: quietHoursEndMinute ?? this.quietHoursEndMinute,
      smartAlertsEnabled: smartAlertsEnabled ?? this.smartAlertsEnabled,
      lowBalanceAlertsEnabled:
          lowBalanceAlertsEnabled ?? this.lowBalanceAlertsEnabled,
      lowBalanceThreshold: lowBalanceThreshold ?? this.lowBalanceThreshold,
      largeExpenseAlertsEnabled:
          largeExpenseAlertsEnabled ?? this.largeExpenseAlertsEnabled,
      largeExpenseThreshold:
          largeExpenseThreshold ?? this.largeExpenseThreshold,
      unusualSpendingAlertsEnabled:
          unusualSpendingAlertsEnabled ?? this.unusualSpendingAlertsEnabled,
      unusualSpendingMultiplier:
          unusualSpendingMultiplier ?? this.unusualSpendingMultiplier,
      recurringMerchantAlertsEnabled:
          recurringMerchantAlertsEnabled ?? this.recurringMerchantAlertsEnabled,
      weeklySummaryAlertsEnabled:
          weeklySummaryAlertsEnabled ?? this.weeklySummaryAlertsEnabled,
      monthlySummaryAlertsEnabled:
          monthlySummaryAlertsEnabled ?? this.monthlySummaryAlertsEnabled,
      userName: userName ?? this.userName,
      monthlySalary: monthlySalary ?? this.monthlySalary,
      salaryCreditDay: salaryCreditDay ?? this.salaryCreditDay,
      companyName: companyName ?? this.companyName,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (isDarkMode.present) {
      map['is_dark_mode'] = Variable<bool>(isDarkMode.value);
    }
    if (appLockEnabled.present) {
      map['app_lock_enabled'] = Variable<bool>(appLockEnabled.value);
    }
    if (notificationDetectionEnabled.present) {
      map['notification_detection_enabled'] = Variable<bool>(
        notificationDetectionEnabled.value,
      );
    }
    if (showDetectionNotifications.present) {
      map['show_detection_notifications'] = Variable<bool>(
        showDetectionNotifications.value,
      );
    }
    if (reminderEnabled.present) {
      map['reminder_enabled'] = Variable<bool>(reminderEnabled.value);
    }
    if (dailyReminderEnabled.present) {
      map['daily_reminder_enabled'] = Variable<bool>(
        dailyReminderEnabled.value,
      );
    }
    if (weeklyReminderEnabled.present) {
      map['weekly_reminder_enabled'] = Variable<bool>(
        weeklyReminderEnabled.value,
      );
    }
    if (reminderHour.present) {
      map['reminder_hour'] = Variable<int>(reminderHour.value);
    }
    if (reminderMinute.present) {
      map['reminder_minute'] = Variable<int>(reminderMinute.value);
    }
    if (weeklyReminderWeekday.present) {
      map['weekly_reminder_weekday'] = Variable<int>(
        weeklyReminderWeekday.value,
      );
    }
    if (cardDueReminderEnabled.present) {
      map['card_due_reminder_enabled'] = Variable<bool>(
        cardDueReminderEnabled.value,
      );
    }
    if (pendingTransactionReminderEnabled.present) {
      map['pending_transaction_reminder_enabled'] = Variable<bool>(
        pendingTransactionReminderEnabled.value,
      );
    }
    if (settlementReminderEnabled.present) {
      map['settlement_reminder_enabled'] = Variable<bool>(
        settlementReminderEnabled.value,
      );
    }
    if (lastReminderShownAt.present) {
      map['last_reminder_shown_at'] = Variable<DateTime>(
        lastReminderShownAt.value,
      );
    }
    if (smsDetectionEnabled.present) {
      map['sms_detection_enabled'] = Variable<bool>(smsDetectionEnabled.value);
    }
    if (smsPermissionAskedAt.present) {
      map['sms_permission_asked_at'] = Variable<DateTime>(
        smsPermissionAskedAt.value,
      );
    }
    if (smsBackfillEnabled.present) {
      map['sms_backfill_enabled'] = Variable<bool>(smsBackfillEnabled.value);
    }
    if (smsBackfillDays.present) {
      map['sms_backfill_days'] = Variable<int>(smsBackfillDays.value);
    }
    if (smsLastScannedAt.present) {
      map['sms_last_scanned_at'] = Variable<DateTime>(smsLastScannedAt.value);
    }
    if (hasCompletedOnboarding.present) {
      map['has_completed_onboarding'] = Variable<bool>(
        hasCompletedOnboarding.value,
      );
    }
    if (quietHoursStartHour.present) {
      map['quiet_hours_start_hour'] = Variable<int>(quietHoursStartHour.value);
    }
    if (quietHoursStartMinute.present) {
      map['quiet_hours_start_minute'] = Variable<int>(
        quietHoursStartMinute.value,
      );
    }
    if (quietHoursEndHour.present) {
      map['quiet_hours_end_hour'] = Variable<int>(quietHoursEndHour.value);
    }
    if (quietHoursEndMinute.present) {
      map['quiet_hours_end_minute'] = Variable<int>(quietHoursEndMinute.value);
    }
    if (smartAlertsEnabled.present) {
      map['smart_alerts_enabled'] = Variable<bool>(smartAlertsEnabled.value);
    }
    if (lowBalanceAlertsEnabled.present) {
      map['low_balance_alerts_enabled'] = Variable<bool>(
        lowBalanceAlertsEnabled.value,
      );
    }
    if (lowBalanceThreshold.present) {
      map['low_balance_threshold'] = Variable<double>(
        lowBalanceThreshold.value,
      );
    }
    if (largeExpenseAlertsEnabled.present) {
      map['large_expense_alerts_enabled'] = Variable<bool>(
        largeExpenseAlertsEnabled.value,
      );
    }
    if (largeExpenseThreshold.present) {
      map['large_expense_threshold'] = Variable<double>(
        largeExpenseThreshold.value,
      );
    }
    if (unusualSpendingAlertsEnabled.present) {
      map['unusual_spending_alerts_enabled'] = Variable<bool>(
        unusualSpendingAlertsEnabled.value,
      );
    }
    if (unusualSpendingMultiplier.present) {
      map['unusual_spending_multiplier'] = Variable<double>(
        unusualSpendingMultiplier.value,
      );
    }
    if (recurringMerchantAlertsEnabled.present) {
      map['recurring_merchant_alerts_enabled'] = Variable<bool>(
        recurringMerchantAlertsEnabled.value,
      );
    }
    if (weeklySummaryAlertsEnabled.present) {
      map['weekly_summary_alerts_enabled'] = Variable<bool>(
        weeklySummaryAlertsEnabled.value,
      );
    }
    if (monthlySummaryAlertsEnabled.present) {
      map['monthly_summary_alerts_enabled'] = Variable<bool>(
        monthlySummaryAlertsEnabled.value,
      );
    }
    if (userName.present) {
      map['user_name'] = Variable<String>(userName.value);
    }
    if (monthlySalary.present) {
      map['monthly_salary'] = Variable<double>(monthlySalary.value);
    }
    if (salaryCreditDay.present) {
      map['salary_credit_day'] = Variable<int>(salaryCreditDay.value);
    }
    if (companyName.present) {
      map['company_name'] = Variable<String>(companyName.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('isDarkMode: $isDarkMode, ')
          ..write('appLockEnabled: $appLockEnabled, ')
          ..write(
            'notificationDetectionEnabled: $notificationDetectionEnabled, ',
          )
          ..write('showDetectionNotifications: $showDetectionNotifications, ')
          ..write('reminderEnabled: $reminderEnabled, ')
          ..write('dailyReminderEnabled: $dailyReminderEnabled, ')
          ..write('weeklyReminderEnabled: $weeklyReminderEnabled, ')
          ..write('reminderHour: $reminderHour, ')
          ..write('reminderMinute: $reminderMinute, ')
          ..write('weeklyReminderWeekday: $weeklyReminderWeekday, ')
          ..write('cardDueReminderEnabled: $cardDueReminderEnabled, ')
          ..write(
            'pendingTransactionReminderEnabled: $pendingTransactionReminderEnabled, ',
          )
          ..write('settlementReminderEnabled: $settlementReminderEnabled, ')
          ..write('lastReminderShownAt: $lastReminderShownAt, ')
          ..write('smsDetectionEnabled: $smsDetectionEnabled, ')
          ..write('smsPermissionAskedAt: $smsPermissionAskedAt, ')
          ..write('smsBackfillEnabled: $smsBackfillEnabled, ')
          ..write('smsBackfillDays: $smsBackfillDays, ')
          ..write('smsLastScannedAt: $smsLastScannedAt, ')
          ..write('hasCompletedOnboarding: $hasCompletedOnboarding, ')
          ..write('quietHoursStartHour: $quietHoursStartHour, ')
          ..write('quietHoursStartMinute: $quietHoursStartMinute, ')
          ..write('quietHoursEndHour: $quietHoursEndHour, ')
          ..write('quietHoursEndMinute: $quietHoursEndMinute, ')
          ..write('smartAlertsEnabled: $smartAlertsEnabled, ')
          ..write('lowBalanceAlertsEnabled: $lowBalanceAlertsEnabled, ')
          ..write('lowBalanceThreshold: $lowBalanceThreshold, ')
          ..write('largeExpenseAlertsEnabled: $largeExpenseAlertsEnabled, ')
          ..write('largeExpenseThreshold: $largeExpenseThreshold, ')
          ..write(
            'unusualSpendingAlertsEnabled: $unusualSpendingAlertsEnabled, ',
          )
          ..write('unusualSpendingMultiplier: $unusualSpendingMultiplier, ')
          ..write(
            'recurringMerchantAlertsEnabled: $recurringMerchantAlertsEnabled, ',
          )
          ..write('weeklySummaryAlertsEnabled: $weeklySummaryAlertsEnabled, ')
          ..write('monthlySummaryAlertsEnabled: $monthlySummaryAlertsEnabled, ')
          ..write('userName: $userName, ')
          ..write('monthlySalary: $monthlySalary, ')
          ..write('salaryCreditDay: $salaryCreditDay, ')
          ..write('companyName: $companyName')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $BankAccountsTable bankAccounts = $BankAccountsTable(this);
  late final $CashWalletsTable cashWallets = $CashWalletsTable(this);
  late final $CreditCardsTable creditCards = $CreditCardsTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $PendingTransactionsTable pendingTransactions =
      $PendingTransactionsTable(this);
  late final $CardBillsTable cardBills = $CardBillsTable(this);
  late final $SplitGroupsTable splitGroups = $SplitGroupsTable(this);
  late final $SplitMembersTable splitMembers = $SplitMembersTable(this);
  late final $SplitExpensesTable splitExpenses = $SplitExpensesTable(this);
  late final $SplitExpenseSharesTable splitExpenseShares =
      $SplitExpenseSharesTable(this);
  late final $SplitSettlementsTable splitSettlements = $SplitSettlementsTable(
    this,
  );
  late final $LoansTable loans = $LoansTable(this);
  late final $LoanPaymentsTable loanPayments = $LoanPaymentsTable(this);
  late final $AlertsTable alerts = $AlertsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    bankAccounts,
    cashWallets,
    creditCards,
    transactions,
    pendingTransactions,
    cardBills,
    splitGroups,
    splitMembers,
    splitExpenses,
    splitExpenseShares,
    splitSettlements,
    loans,
    loanPayments,
    alerts,
    appSettings,
  ];
}

typedef $$BankAccountsTableCreateCompanionBuilder =
    BankAccountsCompanion Function({
      Value<int> id,
      required String bankName,
      required String accountName,
      required String accountType,
      Value<String?> last4,
      Value<double> currentBalance,
      Value<String?> colorOrIcon,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$BankAccountsTableUpdateCompanionBuilder =
    BankAccountsCompanion Function({
      Value<int> id,
      Value<String> bankName,
      Value<String> accountName,
      Value<String> accountType,
      Value<String?> last4,
      Value<double> currentBalance,
      Value<String?> colorOrIcon,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$BankAccountsTableFilterComposer
    extends Composer<_$AppDatabase, $BankAccountsTable> {
  $$BankAccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bankName => $composableBuilder(
    column: $table.bankName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountName => $composableBuilder(
    column: $table.accountName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountType => $composableBuilder(
    column: $table.accountType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get last4 => $composableBuilder(
    column: $table.last4,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get currentBalance => $composableBuilder(
    column: $table.currentBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorOrIcon => $composableBuilder(
    column: $table.colorOrIcon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BankAccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $BankAccountsTable> {
  $$BankAccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bankName => $composableBuilder(
    column: $table.bankName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountName => $composableBuilder(
    column: $table.accountName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountType => $composableBuilder(
    column: $table.accountType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get last4 => $composableBuilder(
    column: $table.last4,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get currentBalance => $composableBuilder(
    column: $table.currentBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorOrIcon => $composableBuilder(
    column: $table.colorOrIcon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BankAccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BankAccountsTable> {
  $$BankAccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get bankName =>
      $composableBuilder(column: $table.bankName, builder: (column) => column);

  GeneratedColumn<String> get accountName => $composableBuilder(
    column: $table.accountName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountType => $composableBuilder(
    column: $table.accountType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get last4 =>
      $composableBuilder(column: $table.last4, builder: (column) => column);

  GeneratedColumn<double> get currentBalance => $composableBuilder(
    column: $table.currentBalance,
    builder: (column) => column,
  );

  GeneratedColumn<String> get colorOrIcon => $composableBuilder(
    column: $table.colorOrIcon,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BankAccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BankAccountsTable,
          BankAccount,
          $$BankAccountsTableFilterComposer,
          $$BankAccountsTableOrderingComposer,
          $$BankAccountsTableAnnotationComposer,
          $$BankAccountsTableCreateCompanionBuilder,
          $$BankAccountsTableUpdateCompanionBuilder,
          (
            BankAccount,
            BaseReferences<_$AppDatabase, $BankAccountsTable, BankAccount>,
          ),
          BankAccount,
          PrefetchHooks Function()
        > {
  $$BankAccountsTableTableManager(_$AppDatabase db, $BankAccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BankAccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BankAccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BankAccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> bankName = const Value.absent(),
                Value<String> accountName = const Value.absent(),
                Value<String> accountType = const Value.absent(),
                Value<String?> last4 = const Value.absent(),
                Value<double> currentBalance = const Value.absent(),
                Value<String?> colorOrIcon = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => BankAccountsCompanion(
                id: id,
                bankName: bankName,
                accountName: accountName,
                accountType: accountType,
                last4: last4,
                currentBalance: currentBalance,
                colorOrIcon: colorOrIcon,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String bankName,
                required String accountName,
                required String accountType,
                Value<String?> last4 = const Value.absent(),
                Value<double> currentBalance = const Value.absent(),
                Value<String?> colorOrIcon = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => BankAccountsCompanion.insert(
                id: id,
                bankName: bankName,
                accountName: accountName,
                accountType: accountType,
                last4: last4,
                currentBalance: currentBalance,
                colorOrIcon: colorOrIcon,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BankAccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BankAccountsTable,
      BankAccount,
      $$BankAccountsTableFilterComposer,
      $$BankAccountsTableOrderingComposer,
      $$BankAccountsTableAnnotationComposer,
      $$BankAccountsTableCreateCompanionBuilder,
      $$BankAccountsTableUpdateCompanionBuilder,
      (
        BankAccount,
        BaseReferences<_$AppDatabase, $BankAccountsTable, BankAccount>,
      ),
      BankAccount,
      PrefetchHooks Function()
    >;
typedef $$CashWalletsTableCreateCompanionBuilder =
    CashWalletsCompanion Function({
      Value<int> id,
      required String walletName,
      Value<String> walletType,
      Value<double> currentBalance,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$CashWalletsTableUpdateCompanionBuilder =
    CashWalletsCompanion Function({
      Value<int> id,
      Value<String> walletName,
      Value<String> walletType,
      Value<double> currentBalance,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$CashWalletsTableFilterComposer
    extends Composer<_$AppDatabase, $CashWalletsTable> {
  $$CashWalletsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get walletName => $composableBuilder(
    column: $table.walletName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get walletType => $composableBuilder(
    column: $table.walletType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get currentBalance => $composableBuilder(
    column: $table.currentBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CashWalletsTableOrderingComposer
    extends Composer<_$AppDatabase, $CashWalletsTable> {
  $$CashWalletsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get walletName => $composableBuilder(
    column: $table.walletName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get walletType => $composableBuilder(
    column: $table.walletType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get currentBalance => $composableBuilder(
    column: $table.currentBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CashWalletsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CashWalletsTable> {
  $$CashWalletsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get walletName => $composableBuilder(
    column: $table.walletName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get walletType => $composableBuilder(
    column: $table.walletType,
    builder: (column) => column,
  );

  GeneratedColumn<double> get currentBalance => $composableBuilder(
    column: $table.currentBalance,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CashWalletsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CashWalletsTable,
          CashWallet,
          $$CashWalletsTableFilterComposer,
          $$CashWalletsTableOrderingComposer,
          $$CashWalletsTableAnnotationComposer,
          $$CashWalletsTableCreateCompanionBuilder,
          $$CashWalletsTableUpdateCompanionBuilder,
          (
            CashWallet,
            BaseReferences<_$AppDatabase, $CashWalletsTable, CashWallet>,
          ),
          CashWallet,
          PrefetchHooks Function()
        > {
  $$CashWalletsTableTableManager(_$AppDatabase db, $CashWalletsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CashWalletsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CashWalletsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CashWalletsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> walletName = const Value.absent(),
                Value<String> walletType = const Value.absent(),
                Value<double> currentBalance = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CashWalletsCompanion(
                id: id,
                walletName: walletName,
                walletType: walletType,
                currentBalance: currentBalance,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String walletName,
                Value<String> walletType = const Value.absent(),
                Value<double> currentBalance = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CashWalletsCompanion.insert(
                id: id,
                walletName: walletName,
                walletType: walletType,
                currentBalance: currentBalance,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CashWalletsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CashWalletsTable,
      CashWallet,
      $$CashWalletsTableFilterComposer,
      $$CashWalletsTableOrderingComposer,
      $$CashWalletsTableAnnotationComposer,
      $$CashWalletsTableCreateCompanionBuilder,
      $$CashWalletsTableUpdateCompanionBuilder,
      (
        CashWallet,
        BaseReferences<_$AppDatabase, $CashWalletsTable, CashWallet>,
      ),
      CashWallet,
      PrefetchHooks Function()
    >;
typedef $$CreditCardsTableCreateCompanionBuilder =
    CreditCardsCompanion Function({
      Value<int> id,
      required String bankName,
      required String nickname,
      required String last4,
      required String maskedNumber,
      required double creditLimit,
      required int billingDay,
      required int dueDay,
      Value<double> currentOutstanding,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$CreditCardsTableUpdateCompanionBuilder =
    CreditCardsCompanion Function({
      Value<int> id,
      Value<String> bankName,
      Value<String> nickname,
      Value<String> last4,
      Value<String> maskedNumber,
      Value<double> creditLimit,
      Value<int> billingDay,
      Value<int> dueDay,
      Value<double> currentOutstanding,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$CreditCardsTableFilterComposer
    extends Composer<_$AppDatabase, $CreditCardsTable> {
  $$CreditCardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bankName => $composableBuilder(
    column: $table.bankName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get last4 => $composableBuilder(
    column: $table.last4,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get maskedNumber => $composableBuilder(
    column: $table.maskedNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get billingDay => $composableBuilder(
    column: $table.billingDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueDay => $composableBuilder(
    column: $table.dueDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get currentOutstanding => $composableBuilder(
    column: $table.currentOutstanding,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CreditCardsTableOrderingComposer
    extends Composer<_$AppDatabase, $CreditCardsTable> {
  $$CreditCardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bankName => $composableBuilder(
    column: $table.bankName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get last4 => $composableBuilder(
    column: $table.last4,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get maskedNumber => $composableBuilder(
    column: $table.maskedNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get billingDay => $composableBuilder(
    column: $table.billingDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueDay => $composableBuilder(
    column: $table.dueDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get currentOutstanding => $composableBuilder(
    column: $table.currentOutstanding,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CreditCardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CreditCardsTable> {
  $$CreditCardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get bankName =>
      $composableBuilder(column: $table.bankName, builder: (column) => column);

  GeneratedColumn<String> get nickname =>
      $composableBuilder(column: $table.nickname, builder: (column) => column);

  GeneratedColumn<String> get last4 =>
      $composableBuilder(column: $table.last4, builder: (column) => column);

  GeneratedColumn<String> get maskedNumber => $composableBuilder(
    column: $table.maskedNumber,
    builder: (column) => column,
  );

  GeneratedColumn<double> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => column,
  );

  GeneratedColumn<int> get billingDay => $composableBuilder(
    column: $table.billingDay,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dueDay =>
      $composableBuilder(column: $table.dueDay, builder: (column) => column);

  GeneratedColumn<double> get currentOutstanding => $composableBuilder(
    column: $table.currentOutstanding,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CreditCardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CreditCardsTable,
          CreditCard,
          $$CreditCardsTableFilterComposer,
          $$CreditCardsTableOrderingComposer,
          $$CreditCardsTableAnnotationComposer,
          $$CreditCardsTableCreateCompanionBuilder,
          $$CreditCardsTableUpdateCompanionBuilder,
          (
            CreditCard,
            BaseReferences<_$AppDatabase, $CreditCardsTable, CreditCard>,
          ),
          CreditCard,
          PrefetchHooks Function()
        > {
  $$CreditCardsTableTableManager(_$AppDatabase db, $CreditCardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CreditCardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CreditCardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CreditCardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> bankName = const Value.absent(),
                Value<String> nickname = const Value.absent(),
                Value<String> last4 = const Value.absent(),
                Value<String> maskedNumber = const Value.absent(),
                Value<double> creditLimit = const Value.absent(),
                Value<int> billingDay = const Value.absent(),
                Value<int> dueDay = const Value.absent(),
                Value<double> currentOutstanding = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CreditCardsCompanion(
                id: id,
                bankName: bankName,
                nickname: nickname,
                last4: last4,
                maskedNumber: maskedNumber,
                creditLimit: creditLimit,
                billingDay: billingDay,
                dueDay: dueDay,
                currentOutstanding: currentOutstanding,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String bankName,
                required String nickname,
                required String last4,
                required String maskedNumber,
                required double creditLimit,
                required int billingDay,
                required int dueDay,
                Value<double> currentOutstanding = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CreditCardsCompanion.insert(
                id: id,
                bankName: bankName,
                nickname: nickname,
                last4: last4,
                maskedNumber: maskedNumber,
                creditLimit: creditLimit,
                billingDay: billingDay,
                dueDay: dueDay,
                currentOutstanding: currentOutstanding,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CreditCardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CreditCardsTable,
      CreditCard,
      $$CreditCardsTableFilterComposer,
      $$CreditCardsTableOrderingComposer,
      $$CreditCardsTableAnnotationComposer,
      $$CreditCardsTableCreateCompanionBuilder,
      $$CreditCardsTableUpdateCompanionBuilder,
      (
        CreditCard,
        BaseReferences<_$AppDatabase, $CreditCardsTable, CreditCard>,
      ),
      CreditCard,
      PrefetchHooks Function()
    >;
typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      Value<int> id,
      required String type,
      required double amount,
      required String title,
      required String category,
      Value<String?> notes,
      required DateTime transactionDate,
      required String paymentSourceType,
      required int paymentSourceId,
      Value<double> cashbackAmount,
      Value<bool> isForOthers,
      Value<double?> recoverableAmount,
      Value<double?> recoverableBaseAmount,
      Value<double> recoveredAmount,
      Value<String?> recoverablePartyName,
      Value<String?> recoverablePartyNotes,
      Value<String?> recoverablePartyPhone,
      Value<String> recoverableStatus,
      Value<DateTime?> recoveredAt,
      Value<bool> confirmed,
      Value<String?> detectedSourceType,
      Value<int?> cardBillId,
      Value<String?> transferGroupId,
      Value<int?> sourceAccountId,
      Value<int?> destinationAccountId,
      Value<int?> linkedSplitExpenseId,
      Value<double?> personalShareAmount,
      Value<int?> splitGroupId,
      Value<String?> transactionImpactType,
      Value<String?> cashbackDestinationType,
      Value<int?> cashbackDestinationId,
      Value<int?> relatedTransactionId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<int> id,
      Value<String> type,
      Value<double> amount,
      Value<String> title,
      Value<String> category,
      Value<String?> notes,
      Value<DateTime> transactionDate,
      Value<String> paymentSourceType,
      Value<int> paymentSourceId,
      Value<double> cashbackAmount,
      Value<bool> isForOthers,
      Value<double?> recoverableAmount,
      Value<double?> recoverableBaseAmount,
      Value<double> recoveredAmount,
      Value<String?> recoverablePartyName,
      Value<String?> recoverablePartyNotes,
      Value<String?> recoverablePartyPhone,
      Value<String> recoverableStatus,
      Value<DateTime?> recoveredAt,
      Value<bool> confirmed,
      Value<String?> detectedSourceType,
      Value<int?> cardBillId,
      Value<String?> transferGroupId,
      Value<int?> sourceAccountId,
      Value<int?> destinationAccountId,
      Value<int?> linkedSplitExpenseId,
      Value<double?> personalShareAmount,
      Value<int?> splitGroupId,
      Value<String?> transactionImpactType,
      Value<String?> cashbackDestinationType,
      Value<int?> cashbackDestinationId,
      Value<int?> relatedTransactionId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentSourceType => $composableBuilder(
    column: $table.paymentSourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paymentSourceId => $composableBuilder(
    column: $table.paymentSourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cashbackAmount => $composableBuilder(
    column: $table.cashbackAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isForOthers => $composableBuilder(
    column: $table.isForOthers,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get recoverableAmount => $composableBuilder(
    column: $table.recoverableAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get recoverableBaseAmount => $composableBuilder(
    column: $table.recoverableBaseAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get recoveredAmount => $composableBuilder(
    column: $table.recoveredAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recoverablePartyName => $composableBuilder(
    column: $table.recoverablePartyName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recoverablePartyNotes => $composableBuilder(
    column: $table.recoverablePartyNotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recoverablePartyPhone => $composableBuilder(
    column: $table.recoverablePartyPhone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recoverableStatus => $composableBuilder(
    column: $table.recoverableStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recoveredAt => $composableBuilder(
    column: $table.recoveredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get confirmed => $composableBuilder(
    column: $table.confirmed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detectedSourceType => $composableBuilder(
    column: $table.detectedSourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cardBillId => $composableBuilder(
    column: $table.cardBillId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transferGroupId => $composableBuilder(
    column: $table.transferGroupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sourceAccountId => $composableBuilder(
    column: $table.sourceAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get destinationAccountId => $composableBuilder(
    column: $table.destinationAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get linkedSplitExpenseId => $composableBuilder(
    column: $table.linkedSplitExpenseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get personalShareAmount => $composableBuilder(
    column: $table.personalShareAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get splitGroupId => $composableBuilder(
    column: $table.splitGroupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transactionImpactType => $composableBuilder(
    column: $table.transactionImpactType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cashbackDestinationType => $composableBuilder(
    column: $table.cashbackDestinationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cashbackDestinationId => $composableBuilder(
    column: $table.cashbackDestinationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get relatedTransactionId => $composableBuilder(
    column: $table.relatedTransactionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentSourceType => $composableBuilder(
    column: $table.paymentSourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paymentSourceId => $composableBuilder(
    column: $table.paymentSourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cashbackAmount => $composableBuilder(
    column: $table.cashbackAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isForOthers => $composableBuilder(
    column: $table.isForOthers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get recoverableAmount => $composableBuilder(
    column: $table.recoverableAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get recoverableBaseAmount => $composableBuilder(
    column: $table.recoverableBaseAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get recoveredAmount => $composableBuilder(
    column: $table.recoveredAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recoverablePartyName => $composableBuilder(
    column: $table.recoverablePartyName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recoverablePartyNotes => $composableBuilder(
    column: $table.recoverablePartyNotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recoverablePartyPhone => $composableBuilder(
    column: $table.recoverablePartyPhone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recoverableStatus => $composableBuilder(
    column: $table.recoverableStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recoveredAt => $composableBuilder(
    column: $table.recoveredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get confirmed => $composableBuilder(
    column: $table.confirmed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detectedSourceType => $composableBuilder(
    column: $table.detectedSourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cardBillId => $composableBuilder(
    column: $table.cardBillId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transferGroupId => $composableBuilder(
    column: $table.transferGroupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sourceAccountId => $composableBuilder(
    column: $table.sourceAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get destinationAccountId => $composableBuilder(
    column: $table.destinationAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get linkedSplitExpenseId => $composableBuilder(
    column: $table.linkedSplitExpenseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get personalShareAmount => $composableBuilder(
    column: $table.personalShareAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get splitGroupId => $composableBuilder(
    column: $table.splitGroupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transactionImpactType => $composableBuilder(
    column: $table.transactionImpactType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cashbackDestinationType => $composableBuilder(
    column: $table.cashbackDestinationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cashbackDestinationId => $composableBuilder(
    column: $table.cashbackDestinationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get relatedTransactionId => $composableBuilder(
    column: $table.relatedTransactionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentSourceType => $composableBuilder(
    column: $table.paymentSourceType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get paymentSourceId => $composableBuilder(
    column: $table.paymentSourceId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get cashbackAmount => $composableBuilder(
    column: $table.cashbackAmount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isForOthers => $composableBuilder(
    column: $table.isForOthers,
    builder: (column) => column,
  );

  GeneratedColumn<double> get recoverableAmount => $composableBuilder(
    column: $table.recoverableAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get recoverableBaseAmount => $composableBuilder(
    column: $table.recoverableBaseAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get recoveredAmount => $composableBuilder(
    column: $table.recoveredAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recoverablePartyName => $composableBuilder(
    column: $table.recoverablePartyName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recoverablePartyNotes => $composableBuilder(
    column: $table.recoverablePartyNotes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recoverablePartyPhone => $composableBuilder(
    column: $table.recoverablePartyPhone,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recoverableStatus => $composableBuilder(
    column: $table.recoverableStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get recoveredAt => $composableBuilder(
    column: $table.recoveredAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get confirmed =>
      $composableBuilder(column: $table.confirmed, builder: (column) => column);

  GeneratedColumn<String> get detectedSourceType => $composableBuilder(
    column: $table.detectedSourceType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cardBillId => $composableBuilder(
    column: $table.cardBillId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get transferGroupId => $composableBuilder(
    column: $table.transferGroupId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sourceAccountId => $composableBuilder(
    column: $table.sourceAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get destinationAccountId => $composableBuilder(
    column: $table.destinationAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get linkedSplitExpenseId => $composableBuilder(
    column: $table.linkedSplitExpenseId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get personalShareAmount => $composableBuilder(
    column: $table.personalShareAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get splitGroupId => $composableBuilder(
    column: $table.splitGroupId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get transactionImpactType => $composableBuilder(
    column: $table.transactionImpactType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cashbackDestinationType => $composableBuilder(
    column: $table.cashbackDestinationType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cashbackDestinationId => $composableBuilder(
    column: $table.cashbackDestinationId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get relatedTransactionId => $composableBuilder(
    column: $table.relatedTransactionId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          Transaction,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (
            Transaction,
            BaseReferences<_$AppDatabase, $TransactionsTable, Transaction>,
          ),
          Transaction,
          PrefetchHooks Function()
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> transactionDate = const Value.absent(),
                Value<String> paymentSourceType = const Value.absent(),
                Value<int> paymentSourceId = const Value.absent(),
                Value<double> cashbackAmount = const Value.absent(),
                Value<bool> isForOthers = const Value.absent(),
                Value<double?> recoverableAmount = const Value.absent(),
                Value<double?> recoverableBaseAmount = const Value.absent(),
                Value<double> recoveredAmount = const Value.absent(),
                Value<String?> recoverablePartyName = const Value.absent(),
                Value<String?> recoverablePartyNotes = const Value.absent(),
                Value<String?> recoverablePartyPhone = const Value.absent(),
                Value<String> recoverableStatus = const Value.absent(),
                Value<DateTime?> recoveredAt = const Value.absent(),
                Value<bool> confirmed = const Value.absent(),
                Value<String?> detectedSourceType = const Value.absent(),
                Value<int?> cardBillId = const Value.absent(),
                Value<String?> transferGroupId = const Value.absent(),
                Value<int?> sourceAccountId = const Value.absent(),
                Value<int?> destinationAccountId = const Value.absent(),
                Value<int?> linkedSplitExpenseId = const Value.absent(),
                Value<double?> personalShareAmount = const Value.absent(),
                Value<int?> splitGroupId = const Value.absent(),
                Value<String?> transactionImpactType = const Value.absent(),
                Value<String?> cashbackDestinationType = const Value.absent(),
                Value<int?> cashbackDestinationId = const Value.absent(),
                Value<int?> relatedTransactionId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                type: type,
                amount: amount,
                title: title,
                category: category,
                notes: notes,
                transactionDate: transactionDate,
                paymentSourceType: paymentSourceType,
                paymentSourceId: paymentSourceId,
                cashbackAmount: cashbackAmount,
                isForOthers: isForOthers,
                recoverableAmount: recoverableAmount,
                recoverableBaseAmount: recoverableBaseAmount,
                recoveredAmount: recoveredAmount,
                recoverablePartyName: recoverablePartyName,
                recoverablePartyNotes: recoverablePartyNotes,
                recoverablePartyPhone: recoverablePartyPhone,
                recoverableStatus: recoverableStatus,
                recoveredAt: recoveredAt,
                confirmed: confirmed,
                detectedSourceType: detectedSourceType,
                cardBillId: cardBillId,
                transferGroupId: transferGroupId,
                sourceAccountId: sourceAccountId,
                destinationAccountId: destinationAccountId,
                linkedSplitExpenseId: linkedSplitExpenseId,
                personalShareAmount: personalShareAmount,
                splitGroupId: splitGroupId,
                transactionImpactType: transactionImpactType,
                cashbackDestinationType: cashbackDestinationType,
                cashbackDestinationId: cashbackDestinationId,
                relatedTransactionId: relatedTransactionId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String type,
                required double amount,
                required String title,
                required String category,
                Value<String?> notes = const Value.absent(),
                required DateTime transactionDate,
                required String paymentSourceType,
                required int paymentSourceId,
                Value<double> cashbackAmount = const Value.absent(),
                Value<bool> isForOthers = const Value.absent(),
                Value<double?> recoverableAmount = const Value.absent(),
                Value<double?> recoverableBaseAmount = const Value.absent(),
                Value<double> recoveredAmount = const Value.absent(),
                Value<String?> recoverablePartyName = const Value.absent(),
                Value<String?> recoverablePartyNotes = const Value.absent(),
                Value<String?> recoverablePartyPhone = const Value.absent(),
                Value<String> recoverableStatus = const Value.absent(),
                Value<DateTime?> recoveredAt = const Value.absent(),
                Value<bool> confirmed = const Value.absent(),
                Value<String?> detectedSourceType = const Value.absent(),
                Value<int?> cardBillId = const Value.absent(),
                Value<String?> transferGroupId = const Value.absent(),
                Value<int?> sourceAccountId = const Value.absent(),
                Value<int?> destinationAccountId = const Value.absent(),
                Value<int?> linkedSplitExpenseId = const Value.absent(),
                Value<double?> personalShareAmount = const Value.absent(),
                Value<int?> splitGroupId = const Value.absent(),
                Value<String?> transactionImpactType = const Value.absent(),
                Value<String?> cashbackDestinationType = const Value.absent(),
                Value<int?> cashbackDestinationId = const Value.absent(),
                Value<int?> relatedTransactionId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                type: type,
                amount: amount,
                title: title,
                category: category,
                notes: notes,
                transactionDate: transactionDate,
                paymentSourceType: paymentSourceType,
                paymentSourceId: paymentSourceId,
                cashbackAmount: cashbackAmount,
                isForOthers: isForOthers,
                recoverableAmount: recoverableAmount,
                recoverableBaseAmount: recoverableBaseAmount,
                recoveredAmount: recoveredAmount,
                recoverablePartyName: recoverablePartyName,
                recoverablePartyNotes: recoverablePartyNotes,
                recoverablePartyPhone: recoverablePartyPhone,
                recoverableStatus: recoverableStatus,
                recoveredAt: recoveredAt,
                confirmed: confirmed,
                detectedSourceType: detectedSourceType,
                cardBillId: cardBillId,
                transferGroupId: transferGroupId,
                sourceAccountId: sourceAccountId,
                destinationAccountId: destinationAccountId,
                linkedSplitExpenseId: linkedSplitExpenseId,
                personalShareAmount: personalShareAmount,
                splitGroupId: splitGroupId,
                transactionImpactType: transactionImpactType,
                cashbackDestinationType: cashbackDestinationType,
                cashbackDestinationId: cashbackDestinationId,
                relatedTransactionId: relatedTransactionId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      Transaction,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (
        Transaction,
        BaseReferences<_$AppDatabase, $TransactionsTable, Transaction>,
      ),
      Transaction,
      PrefetchHooks Function()
    >;
typedef $$PendingTransactionsTableCreateCompanionBuilder =
    PendingTransactionsCompanion Function({
      Value<int> id,
      required double amount,
      required String merchant,
      required String categorySuggestion,
      required String paymentSourceTypeSuggestion,
      Value<int?> paymentSourceIdSuggestion,
      required DateTime detectedAt,
      required DateTime transactionDate,
      required String sourceType,
      required String rawText,
      required double confidenceScore,
      Value<String> status,
      Value<double?> cashbackAmount,
      Value<bool> isForOthers,
      Value<double?> recoverableAmount,
      Value<double?> recoverableBaseAmount,
      Value<double> recoveredAmount,
      Value<String?> recoverablePartyName,
      Value<String?> recoverablePartyNotes,
      Value<String?> recoverablePartyPhone,
      Value<String?> notes,
      Value<int?> duplicateOfTransactionId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$PendingTransactionsTableUpdateCompanionBuilder =
    PendingTransactionsCompanion Function({
      Value<int> id,
      Value<double> amount,
      Value<String> merchant,
      Value<String> categorySuggestion,
      Value<String> paymentSourceTypeSuggestion,
      Value<int?> paymentSourceIdSuggestion,
      Value<DateTime> detectedAt,
      Value<DateTime> transactionDate,
      Value<String> sourceType,
      Value<String> rawText,
      Value<double> confidenceScore,
      Value<String> status,
      Value<double?> cashbackAmount,
      Value<bool> isForOthers,
      Value<double?> recoverableAmount,
      Value<double?> recoverableBaseAmount,
      Value<double> recoveredAmount,
      Value<String?> recoverablePartyName,
      Value<String?> recoverablePartyNotes,
      Value<String?> recoverablePartyPhone,
      Value<String?> notes,
      Value<int?> duplicateOfTransactionId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$PendingTransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingTransactionsTable> {
  $$PendingTransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get merchant => $composableBuilder(
    column: $table.merchant,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categorySuggestion => $composableBuilder(
    column: $table.categorySuggestion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentSourceTypeSuggestion => $composableBuilder(
    column: $table.paymentSourceTypeSuggestion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paymentSourceIdSuggestion => $composableBuilder(
    column: $table.paymentSourceIdSuggestion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get detectedAt => $composableBuilder(
    column: $table.detectedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get confidenceScore => $composableBuilder(
    column: $table.confidenceScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cashbackAmount => $composableBuilder(
    column: $table.cashbackAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isForOthers => $composableBuilder(
    column: $table.isForOthers,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get recoverableAmount => $composableBuilder(
    column: $table.recoverableAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get recoverableBaseAmount => $composableBuilder(
    column: $table.recoverableBaseAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get recoveredAmount => $composableBuilder(
    column: $table.recoveredAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recoverablePartyName => $composableBuilder(
    column: $table.recoverablePartyName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recoverablePartyNotes => $composableBuilder(
    column: $table.recoverablePartyNotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recoverablePartyPhone => $composableBuilder(
    column: $table.recoverablePartyPhone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get duplicateOfTransactionId => $composableBuilder(
    column: $table.duplicateOfTransactionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingTransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingTransactionsTable> {
  $$PendingTransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get merchant => $composableBuilder(
    column: $table.merchant,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categorySuggestion => $composableBuilder(
    column: $table.categorySuggestion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentSourceTypeSuggestion => $composableBuilder(
    column: $table.paymentSourceTypeSuggestion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paymentSourceIdSuggestion => $composableBuilder(
    column: $table.paymentSourceIdSuggestion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get detectedAt => $composableBuilder(
    column: $table.detectedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confidenceScore => $composableBuilder(
    column: $table.confidenceScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cashbackAmount => $composableBuilder(
    column: $table.cashbackAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isForOthers => $composableBuilder(
    column: $table.isForOthers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get recoverableAmount => $composableBuilder(
    column: $table.recoverableAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get recoverableBaseAmount => $composableBuilder(
    column: $table.recoverableBaseAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get recoveredAmount => $composableBuilder(
    column: $table.recoveredAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recoverablePartyName => $composableBuilder(
    column: $table.recoverablePartyName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recoverablePartyNotes => $composableBuilder(
    column: $table.recoverablePartyNotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recoverablePartyPhone => $composableBuilder(
    column: $table.recoverablePartyPhone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get duplicateOfTransactionId => $composableBuilder(
    column: $table.duplicateOfTransactionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingTransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingTransactionsTable> {
  $$PendingTransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get merchant =>
      $composableBuilder(column: $table.merchant, builder: (column) => column);

  GeneratedColumn<String> get categorySuggestion => $composableBuilder(
    column: $table.categorySuggestion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentSourceTypeSuggestion => $composableBuilder(
    column: $table.paymentSourceTypeSuggestion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get paymentSourceIdSuggestion => $composableBuilder(
    column: $table.paymentSourceIdSuggestion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get detectedAt => $composableBuilder(
    column: $table.detectedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawText =>
      $composableBuilder(column: $table.rawText, builder: (column) => column);

  GeneratedColumn<double> get confidenceScore => $composableBuilder(
    column: $table.confidenceScore,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get cashbackAmount => $composableBuilder(
    column: $table.cashbackAmount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isForOthers => $composableBuilder(
    column: $table.isForOthers,
    builder: (column) => column,
  );

  GeneratedColumn<double> get recoverableAmount => $composableBuilder(
    column: $table.recoverableAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get recoverableBaseAmount => $composableBuilder(
    column: $table.recoverableBaseAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get recoveredAmount => $composableBuilder(
    column: $table.recoveredAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recoverablePartyName => $composableBuilder(
    column: $table.recoverablePartyName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recoverablePartyNotes => $composableBuilder(
    column: $table.recoverablePartyNotes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recoverablePartyPhone => $composableBuilder(
    column: $table.recoverablePartyPhone,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get duplicateOfTransactionId => $composableBuilder(
    column: $table.duplicateOfTransactionId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PendingTransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingTransactionsTable,
          PendingTransaction,
          $$PendingTransactionsTableFilterComposer,
          $$PendingTransactionsTableOrderingComposer,
          $$PendingTransactionsTableAnnotationComposer,
          $$PendingTransactionsTableCreateCompanionBuilder,
          $$PendingTransactionsTableUpdateCompanionBuilder,
          (
            PendingTransaction,
            BaseReferences<
              _$AppDatabase,
              $PendingTransactionsTable,
              PendingTransaction
            >,
          ),
          PendingTransaction,
          PrefetchHooks Function()
        > {
  $$PendingTransactionsTableTableManager(
    _$AppDatabase db,
    $PendingTransactionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingTransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingTransactionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PendingTransactionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> merchant = const Value.absent(),
                Value<String> categorySuggestion = const Value.absent(),
                Value<String> paymentSourceTypeSuggestion =
                    const Value.absent(),
                Value<int?> paymentSourceIdSuggestion = const Value.absent(),
                Value<DateTime> detectedAt = const Value.absent(),
                Value<DateTime> transactionDate = const Value.absent(),
                Value<String> sourceType = const Value.absent(),
                Value<String> rawText = const Value.absent(),
                Value<double> confidenceScore = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<double?> cashbackAmount = const Value.absent(),
                Value<bool> isForOthers = const Value.absent(),
                Value<double?> recoverableAmount = const Value.absent(),
                Value<double?> recoverableBaseAmount = const Value.absent(),
                Value<double> recoveredAmount = const Value.absent(),
                Value<String?> recoverablePartyName = const Value.absent(),
                Value<String?> recoverablePartyNotes = const Value.absent(),
                Value<String?> recoverablePartyPhone = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> duplicateOfTransactionId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => PendingTransactionsCompanion(
                id: id,
                amount: amount,
                merchant: merchant,
                categorySuggestion: categorySuggestion,
                paymentSourceTypeSuggestion: paymentSourceTypeSuggestion,
                paymentSourceIdSuggestion: paymentSourceIdSuggestion,
                detectedAt: detectedAt,
                transactionDate: transactionDate,
                sourceType: sourceType,
                rawText: rawText,
                confidenceScore: confidenceScore,
                status: status,
                cashbackAmount: cashbackAmount,
                isForOthers: isForOthers,
                recoverableAmount: recoverableAmount,
                recoverableBaseAmount: recoverableBaseAmount,
                recoveredAmount: recoveredAmount,
                recoverablePartyName: recoverablePartyName,
                recoverablePartyNotes: recoverablePartyNotes,
                recoverablePartyPhone: recoverablePartyPhone,
                notes: notes,
                duplicateOfTransactionId: duplicateOfTransactionId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required double amount,
                required String merchant,
                required String categorySuggestion,
                required String paymentSourceTypeSuggestion,
                Value<int?> paymentSourceIdSuggestion = const Value.absent(),
                required DateTime detectedAt,
                required DateTime transactionDate,
                required String sourceType,
                required String rawText,
                required double confidenceScore,
                Value<String> status = const Value.absent(),
                Value<double?> cashbackAmount = const Value.absent(),
                Value<bool> isForOthers = const Value.absent(),
                Value<double?> recoverableAmount = const Value.absent(),
                Value<double?> recoverableBaseAmount = const Value.absent(),
                Value<double> recoveredAmount = const Value.absent(),
                Value<String?> recoverablePartyName = const Value.absent(),
                Value<String?> recoverablePartyNotes = const Value.absent(),
                Value<String?> recoverablePartyPhone = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> duplicateOfTransactionId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => PendingTransactionsCompanion.insert(
                id: id,
                amount: amount,
                merchant: merchant,
                categorySuggestion: categorySuggestion,
                paymentSourceTypeSuggestion: paymentSourceTypeSuggestion,
                paymentSourceIdSuggestion: paymentSourceIdSuggestion,
                detectedAt: detectedAt,
                transactionDate: transactionDate,
                sourceType: sourceType,
                rawText: rawText,
                confidenceScore: confidenceScore,
                status: status,
                cashbackAmount: cashbackAmount,
                isForOthers: isForOthers,
                recoverableAmount: recoverableAmount,
                recoverableBaseAmount: recoverableBaseAmount,
                recoveredAmount: recoveredAmount,
                recoverablePartyName: recoverablePartyName,
                recoverablePartyNotes: recoverablePartyNotes,
                recoverablePartyPhone: recoverablePartyPhone,
                notes: notes,
                duplicateOfTransactionId: duplicateOfTransactionId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingTransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingTransactionsTable,
      PendingTransaction,
      $$PendingTransactionsTableFilterComposer,
      $$PendingTransactionsTableOrderingComposer,
      $$PendingTransactionsTableAnnotationComposer,
      $$PendingTransactionsTableCreateCompanionBuilder,
      $$PendingTransactionsTableUpdateCompanionBuilder,
      (
        PendingTransaction,
        BaseReferences<
          _$AppDatabase,
          $PendingTransactionsTable,
          PendingTransaction
        >,
      ),
      PendingTransaction,
      PrefetchHooks Function()
    >;
typedef $$CardBillsTableCreateCompanionBuilder =
    CardBillsCompanion Function({
      Value<int> id,
      required int cardId,
      Value<DateTime> cycleStartDate,
      Value<DateTime> cycleEndDate,
      Value<DateTime> billingDate,
      required double billedAmount,
      Value<double> paidAmount,
      Value<DateTime> dueDate,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<DateTime?> paidAt,
    });
typedef $$CardBillsTableUpdateCompanionBuilder =
    CardBillsCompanion Function({
      Value<int> id,
      Value<int> cardId,
      Value<DateTime> cycleStartDate,
      Value<DateTime> cycleEndDate,
      Value<DateTime> billingDate,
      Value<double> billedAmount,
      Value<double> paidAmount,
      Value<DateTime> dueDate,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<DateTime?> paidAt,
    });

class $$CardBillsTableFilterComposer
    extends Composer<_$AppDatabase, $CardBillsTable> {
  $$CardBillsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cycleStartDate => $composableBuilder(
    column: $table.cycleStartDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cycleEndDate => $composableBuilder(
    column: $table.cycleEndDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get billingDate => $composableBuilder(
    column: $table.billingDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get billedAmount => $composableBuilder(
    column: $table.billedAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get paidAmount => $composableBuilder(
    column: $table.paidAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get paidAt => $composableBuilder(
    column: $table.paidAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CardBillsTableOrderingComposer
    extends Composer<_$AppDatabase, $CardBillsTable> {
  $$CardBillsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cycleStartDate => $composableBuilder(
    column: $table.cycleStartDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cycleEndDate => $composableBuilder(
    column: $table.cycleEndDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get billingDate => $composableBuilder(
    column: $table.billingDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get billedAmount => $composableBuilder(
    column: $table.billedAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get paidAmount => $composableBuilder(
    column: $table.paidAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get paidAt => $composableBuilder(
    column: $table.paidAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CardBillsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CardBillsTable> {
  $$CardBillsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get cardId =>
      $composableBuilder(column: $table.cardId, builder: (column) => column);

  GeneratedColumn<DateTime> get cycleStartDate => $composableBuilder(
    column: $table.cycleStartDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cycleEndDate => $composableBuilder(
    column: $table.cycleEndDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get billingDate => $composableBuilder(
    column: $table.billingDate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get billedAmount => $composableBuilder(
    column: $table.billedAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get paidAmount => $composableBuilder(
    column: $table.paidAmount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get paidAt =>
      $composableBuilder(column: $table.paidAt, builder: (column) => column);
}

class $$CardBillsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CardBillsTable,
          CardBill,
          $$CardBillsTableFilterComposer,
          $$CardBillsTableOrderingComposer,
          $$CardBillsTableAnnotationComposer,
          $$CardBillsTableCreateCompanionBuilder,
          $$CardBillsTableUpdateCompanionBuilder,
          (CardBill, BaseReferences<_$AppDatabase, $CardBillsTable, CardBill>),
          CardBill,
          PrefetchHooks Function()
        > {
  $$CardBillsTableTableManager(_$AppDatabase db, $CardBillsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CardBillsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CardBillsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CardBillsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> cardId = const Value.absent(),
                Value<DateTime> cycleStartDate = const Value.absent(),
                Value<DateTime> cycleEndDate = const Value.absent(),
                Value<DateTime> billingDate = const Value.absent(),
                Value<double> billedAmount = const Value.absent(),
                Value<double> paidAmount = const Value.absent(),
                Value<DateTime> dueDate = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> paidAt = const Value.absent(),
              }) => CardBillsCompanion(
                id: id,
                cardId: cardId,
                cycleStartDate: cycleStartDate,
                cycleEndDate: cycleEndDate,
                billingDate: billingDate,
                billedAmount: billedAmount,
                paidAmount: paidAmount,
                dueDate: dueDate,
                status: status,
                createdAt: createdAt,
                paidAt: paidAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int cardId,
                Value<DateTime> cycleStartDate = const Value.absent(),
                Value<DateTime> cycleEndDate = const Value.absent(),
                Value<DateTime> billingDate = const Value.absent(),
                required double billedAmount,
                Value<double> paidAmount = const Value.absent(),
                Value<DateTime> dueDate = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> paidAt = const Value.absent(),
              }) => CardBillsCompanion.insert(
                id: id,
                cardId: cardId,
                cycleStartDate: cycleStartDate,
                cycleEndDate: cycleEndDate,
                billingDate: billingDate,
                billedAmount: billedAmount,
                paidAmount: paidAmount,
                dueDate: dueDate,
                status: status,
                createdAt: createdAt,
                paidAt: paidAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CardBillsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CardBillsTable,
      CardBill,
      $$CardBillsTableFilterComposer,
      $$CardBillsTableOrderingComposer,
      $$CardBillsTableAnnotationComposer,
      $$CardBillsTableCreateCompanionBuilder,
      $$CardBillsTableUpdateCompanionBuilder,
      (CardBill, BaseReferences<_$AppDatabase, $CardBillsTable, CardBill>),
      CardBill,
      PrefetchHooks Function()
    >;
typedef $$SplitGroupsTableCreateCompanionBuilder =
    SplitGroupsCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> description,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> archivedAt,
    });
typedef $$SplitGroupsTableUpdateCompanionBuilder =
    SplitGroupsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> description,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> archivedAt,
    });

class $$SplitGroupsTableFilterComposer
    extends Composer<_$AppDatabase, $SplitGroupsTable> {
  $$SplitGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SplitGroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $SplitGroupsTable> {
  $$SplitGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SplitGroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SplitGroupsTable> {
  $$SplitGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );
}

class $$SplitGroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SplitGroupsTable,
          SplitGroup,
          $$SplitGroupsTableFilterComposer,
          $$SplitGroupsTableOrderingComposer,
          $$SplitGroupsTableAnnotationComposer,
          $$SplitGroupsTableCreateCompanionBuilder,
          $$SplitGroupsTableUpdateCompanionBuilder,
          (
            SplitGroup,
            BaseReferences<_$AppDatabase, $SplitGroupsTable, SplitGroup>,
          ),
          SplitGroup,
          PrefetchHooks Function()
        > {
  $$SplitGroupsTableTableManager(_$AppDatabase db, $SplitGroupsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SplitGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SplitGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SplitGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
              }) => SplitGroupsCompanion(
                id: id,
                name: name,
                description: description,
                createdAt: createdAt,
                updatedAt: updatedAt,
                archivedAt: archivedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> description = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
              }) => SplitGroupsCompanion.insert(
                id: id,
                name: name,
                description: description,
                createdAt: createdAt,
                updatedAt: updatedAt,
                archivedAt: archivedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SplitGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SplitGroupsTable,
      SplitGroup,
      $$SplitGroupsTableFilterComposer,
      $$SplitGroupsTableOrderingComposer,
      $$SplitGroupsTableAnnotationComposer,
      $$SplitGroupsTableCreateCompanionBuilder,
      $$SplitGroupsTableUpdateCompanionBuilder,
      (
        SplitGroup,
        BaseReferences<_$AppDatabase, $SplitGroupsTable, SplitGroup>,
      ),
      SplitGroup,
      PrefetchHooks Function()
    >;
typedef $$SplitMembersTableCreateCompanionBuilder =
    SplitMembersCompanion Function({
      Value<int> id,
      required int groupId,
      required String name,
      Value<String?> contact,
      Value<bool> isCurrentUser,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$SplitMembersTableUpdateCompanionBuilder =
    SplitMembersCompanion Function({
      Value<int> id,
      Value<int> groupId,
      Value<String> name,
      Value<String?> contact,
      Value<bool> isCurrentUser,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$SplitMembersTableFilterComposer
    extends Composer<_$AppDatabase, $SplitMembersTable> {
  $$SplitMembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contact => $composableBuilder(
    column: $table.contact,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCurrentUser => $composableBuilder(
    column: $table.isCurrentUser,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SplitMembersTableOrderingComposer
    extends Composer<_$AppDatabase, $SplitMembersTable> {
  $$SplitMembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contact => $composableBuilder(
    column: $table.contact,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCurrentUser => $composableBuilder(
    column: $table.isCurrentUser,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SplitMembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $SplitMembersTable> {
  $$SplitMembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get contact =>
      $composableBuilder(column: $table.contact, builder: (column) => column);

  GeneratedColumn<bool> get isCurrentUser => $composableBuilder(
    column: $table.isCurrentUser,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SplitMembersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SplitMembersTable,
          SplitMember,
          $$SplitMembersTableFilterComposer,
          $$SplitMembersTableOrderingComposer,
          $$SplitMembersTableAnnotationComposer,
          $$SplitMembersTableCreateCompanionBuilder,
          $$SplitMembersTableUpdateCompanionBuilder,
          (
            SplitMember,
            BaseReferences<_$AppDatabase, $SplitMembersTable, SplitMember>,
          ),
          SplitMember,
          PrefetchHooks Function()
        > {
  $$SplitMembersTableTableManager(_$AppDatabase db, $SplitMembersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SplitMembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SplitMembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SplitMembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> groupId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> contact = const Value.absent(),
                Value<bool> isCurrentUser = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SplitMembersCompanion(
                id: id,
                groupId: groupId,
                name: name,
                contact: contact,
                isCurrentUser: isCurrentUser,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int groupId,
                required String name,
                Value<String?> contact = const Value.absent(),
                Value<bool> isCurrentUser = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SplitMembersCompanion.insert(
                id: id,
                groupId: groupId,
                name: name,
                contact: contact,
                isCurrentUser: isCurrentUser,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SplitMembersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SplitMembersTable,
      SplitMember,
      $$SplitMembersTableFilterComposer,
      $$SplitMembersTableOrderingComposer,
      $$SplitMembersTableAnnotationComposer,
      $$SplitMembersTableCreateCompanionBuilder,
      $$SplitMembersTableUpdateCompanionBuilder,
      (
        SplitMember,
        BaseReferences<_$AppDatabase, $SplitMembersTable, SplitMember>,
      ),
      SplitMember,
      PrefetchHooks Function()
    >;
typedef $$SplitExpensesTableCreateCompanionBuilder =
    SplitExpensesCompanion Function({
      Value<int> id,
      required int groupId,
      required String title,
      required double totalAmount,
      required int paidByMemberId,
      required String splitType,
      required DateTime expenseDate,
      required String category,
      Value<String?> notes,
      Value<int?> linkedTransactionId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$SplitExpensesTableUpdateCompanionBuilder =
    SplitExpensesCompanion Function({
      Value<int> id,
      Value<int> groupId,
      Value<String> title,
      Value<double> totalAmount,
      Value<int> paidByMemberId,
      Value<String> splitType,
      Value<DateTime> expenseDate,
      Value<String> category,
      Value<String?> notes,
      Value<int?> linkedTransactionId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$SplitExpensesTableFilterComposer
    extends Composer<_$AppDatabase, $SplitExpensesTable> {
  $$SplitExpensesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paidByMemberId => $composableBuilder(
    column: $table.paidByMemberId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get splitType => $composableBuilder(
    column: $table.splitType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expenseDate => $composableBuilder(
    column: $table.expenseDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get linkedTransactionId => $composableBuilder(
    column: $table.linkedTransactionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SplitExpensesTableOrderingComposer
    extends Composer<_$AppDatabase, $SplitExpensesTable> {
  $$SplitExpensesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paidByMemberId => $composableBuilder(
    column: $table.paidByMemberId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get splitType => $composableBuilder(
    column: $table.splitType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expenseDate => $composableBuilder(
    column: $table.expenseDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get linkedTransactionId => $composableBuilder(
    column: $table.linkedTransactionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SplitExpensesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SplitExpensesTable> {
  $$SplitExpensesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get paidByMemberId => $composableBuilder(
    column: $table.paidByMemberId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get splitType =>
      $composableBuilder(column: $table.splitType, builder: (column) => column);

  GeneratedColumn<DateTime> get expenseDate => $composableBuilder(
    column: $table.expenseDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get linkedTransactionId => $composableBuilder(
    column: $table.linkedTransactionId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SplitExpensesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SplitExpensesTable,
          SplitExpense,
          $$SplitExpensesTableFilterComposer,
          $$SplitExpensesTableOrderingComposer,
          $$SplitExpensesTableAnnotationComposer,
          $$SplitExpensesTableCreateCompanionBuilder,
          $$SplitExpensesTableUpdateCompanionBuilder,
          (
            SplitExpense,
            BaseReferences<_$AppDatabase, $SplitExpensesTable, SplitExpense>,
          ),
          SplitExpense,
          PrefetchHooks Function()
        > {
  $$SplitExpensesTableTableManager(_$AppDatabase db, $SplitExpensesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SplitExpensesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SplitExpensesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SplitExpensesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> groupId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                Value<int> paidByMemberId = const Value.absent(),
                Value<String> splitType = const Value.absent(),
                Value<DateTime> expenseDate = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> linkedTransactionId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SplitExpensesCompanion(
                id: id,
                groupId: groupId,
                title: title,
                totalAmount: totalAmount,
                paidByMemberId: paidByMemberId,
                splitType: splitType,
                expenseDate: expenseDate,
                category: category,
                notes: notes,
                linkedTransactionId: linkedTransactionId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int groupId,
                required String title,
                required double totalAmount,
                required int paidByMemberId,
                required String splitType,
                required DateTime expenseDate,
                required String category,
                Value<String?> notes = const Value.absent(),
                Value<int?> linkedTransactionId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SplitExpensesCompanion.insert(
                id: id,
                groupId: groupId,
                title: title,
                totalAmount: totalAmount,
                paidByMemberId: paidByMemberId,
                splitType: splitType,
                expenseDate: expenseDate,
                category: category,
                notes: notes,
                linkedTransactionId: linkedTransactionId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SplitExpensesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SplitExpensesTable,
      SplitExpense,
      $$SplitExpensesTableFilterComposer,
      $$SplitExpensesTableOrderingComposer,
      $$SplitExpensesTableAnnotationComposer,
      $$SplitExpensesTableCreateCompanionBuilder,
      $$SplitExpensesTableUpdateCompanionBuilder,
      (
        SplitExpense,
        BaseReferences<_$AppDatabase, $SplitExpensesTable, SplitExpense>,
      ),
      SplitExpense,
      PrefetchHooks Function()
    >;
typedef $$SplitExpenseSharesTableCreateCompanionBuilder =
    SplitExpenseSharesCompanion Function({
      Value<int> id,
      required int splitExpenseId,
      required int memberId,
      Value<double?> percentage,
      required double exactAmount,
      Value<bool> isSettled,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$SplitExpenseSharesTableUpdateCompanionBuilder =
    SplitExpenseSharesCompanion Function({
      Value<int> id,
      Value<int> splitExpenseId,
      Value<int> memberId,
      Value<double?> percentage,
      Value<double> exactAmount,
      Value<bool> isSettled,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$SplitExpenseSharesTableFilterComposer
    extends Composer<_$AppDatabase, $SplitExpenseSharesTable> {
  $$SplitExpenseSharesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get splitExpenseId => $composableBuilder(
    column: $table.splitExpenseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get percentage => $composableBuilder(
    column: $table.percentage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get exactAmount => $composableBuilder(
    column: $table.exactAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSettled => $composableBuilder(
    column: $table.isSettled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SplitExpenseSharesTableOrderingComposer
    extends Composer<_$AppDatabase, $SplitExpenseSharesTable> {
  $$SplitExpenseSharesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get splitExpenseId => $composableBuilder(
    column: $table.splitExpenseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get percentage => $composableBuilder(
    column: $table.percentage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get exactAmount => $composableBuilder(
    column: $table.exactAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSettled => $composableBuilder(
    column: $table.isSettled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SplitExpenseSharesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SplitExpenseSharesTable> {
  $$SplitExpenseSharesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get splitExpenseId => $composableBuilder(
    column: $table.splitExpenseId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get memberId =>
      $composableBuilder(column: $table.memberId, builder: (column) => column);

  GeneratedColumn<double> get percentage => $composableBuilder(
    column: $table.percentage,
    builder: (column) => column,
  );

  GeneratedColumn<double> get exactAmount => $composableBuilder(
    column: $table.exactAmount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSettled =>
      $composableBuilder(column: $table.isSettled, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SplitExpenseSharesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SplitExpenseSharesTable,
          SplitExpenseShare,
          $$SplitExpenseSharesTableFilterComposer,
          $$SplitExpenseSharesTableOrderingComposer,
          $$SplitExpenseSharesTableAnnotationComposer,
          $$SplitExpenseSharesTableCreateCompanionBuilder,
          $$SplitExpenseSharesTableUpdateCompanionBuilder,
          (
            SplitExpenseShare,
            BaseReferences<
              _$AppDatabase,
              $SplitExpenseSharesTable,
              SplitExpenseShare
            >,
          ),
          SplitExpenseShare,
          PrefetchHooks Function()
        > {
  $$SplitExpenseSharesTableTableManager(
    _$AppDatabase db,
    $SplitExpenseSharesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SplitExpenseSharesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SplitExpenseSharesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SplitExpenseSharesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> splitExpenseId = const Value.absent(),
                Value<int> memberId = const Value.absent(),
                Value<double?> percentage = const Value.absent(),
                Value<double> exactAmount = const Value.absent(),
                Value<bool> isSettled = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SplitExpenseSharesCompanion(
                id: id,
                splitExpenseId: splitExpenseId,
                memberId: memberId,
                percentage: percentage,
                exactAmount: exactAmount,
                isSettled: isSettled,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int splitExpenseId,
                required int memberId,
                Value<double?> percentage = const Value.absent(),
                required double exactAmount,
                Value<bool> isSettled = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SplitExpenseSharesCompanion.insert(
                id: id,
                splitExpenseId: splitExpenseId,
                memberId: memberId,
                percentage: percentage,
                exactAmount: exactAmount,
                isSettled: isSettled,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SplitExpenseSharesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SplitExpenseSharesTable,
      SplitExpenseShare,
      $$SplitExpenseSharesTableFilterComposer,
      $$SplitExpenseSharesTableOrderingComposer,
      $$SplitExpenseSharesTableAnnotationComposer,
      $$SplitExpenseSharesTableCreateCompanionBuilder,
      $$SplitExpenseSharesTableUpdateCompanionBuilder,
      (
        SplitExpenseShare,
        BaseReferences<
          _$AppDatabase,
          $SplitExpenseSharesTable,
          SplitExpenseShare
        >,
      ),
      SplitExpenseShare,
      PrefetchHooks Function()
    >;
typedef $$SplitSettlementsTableCreateCompanionBuilder =
    SplitSettlementsCompanion Function({
      Value<int> id,
      required int groupId,
      required int fromMemberId,
      required int toMemberId,
      required double amount,
      Value<String?> paymentSourceType,
      Value<int?> paymentSourceId,
      required DateTime settlementDate,
      Value<int?> linkedTransactionId,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$SplitSettlementsTableUpdateCompanionBuilder =
    SplitSettlementsCompanion Function({
      Value<int> id,
      Value<int> groupId,
      Value<int> fromMemberId,
      Value<int> toMemberId,
      Value<double> amount,
      Value<String?> paymentSourceType,
      Value<int?> paymentSourceId,
      Value<DateTime> settlementDate,
      Value<int?> linkedTransactionId,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$SplitSettlementsTableFilterComposer
    extends Composer<_$AppDatabase, $SplitSettlementsTable> {
  $$SplitSettlementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fromMemberId => $composableBuilder(
    column: $table.fromMemberId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get toMemberId => $composableBuilder(
    column: $table.toMemberId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentSourceType => $composableBuilder(
    column: $table.paymentSourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paymentSourceId => $composableBuilder(
    column: $table.paymentSourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get settlementDate => $composableBuilder(
    column: $table.settlementDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get linkedTransactionId => $composableBuilder(
    column: $table.linkedTransactionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SplitSettlementsTableOrderingComposer
    extends Composer<_$AppDatabase, $SplitSettlementsTable> {
  $$SplitSettlementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fromMemberId => $composableBuilder(
    column: $table.fromMemberId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get toMemberId => $composableBuilder(
    column: $table.toMemberId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentSourceType => $composableBuilder(
    column: $table.paymentSourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paymentSourceId => $composableBuilder(
    column: $table.paymentSourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get settlementDate => $composableBuilder(
    column: $table.settlementDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get linkedTransactionId => $composableBuilder(
    column: $table.linkedTransactionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SplitSettlementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SplitSettlementsTable> {
  $$SplitSettlementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<int> get fromMemberId => $composableBuilder(
    column: $table.fromMemberId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get toMemberId => $composableBuilder(
    column: $table.toMemberId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get paymentSourceType => $composableBuilder(
    column: $table.paymentSourceType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get paymentSourceId => $composableBuilder(
    column: $table.paymentSourceId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get settlementDate => $composableBuilder(
    column: $table.settlementDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get linkedTransactionId => $composableBuilder(
    column: $table.linkedTransactionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SplitSettlementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SplitSettlementsTable,
          SplitSettlement,
          $$SplitSettlementsTableFilterComposer,
          $$SplitSettlementsTableOrderingComposer,
          $$SplitSettlementsTableAnnotationComposer,
          $$SplitSettlementsTableCreateCompanionBuilder,
          $$SplitSettlementsTableUpdateCompanionBuilder,
          (
            SplitSettlement,
            BaseReferences<
              _$AppDatabase,
              $SplitSettlementsTable,
              SplitSettlement
            >,
          ),
          SplitSettlement,
          PrefetchHooks Function()
        > {
  $$SplitSettlementsTableTableManager(
    _$AppDatabase db,
    $SplitSettlementsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SplitSettlementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SplitSettlementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SplitSettlementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> groupId = const Value.absent(),
                Value<int> fromMemberId = const Value.absent(),
                Value<int> toMemberId = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String?> paymentSourceType = const Value.absent(),
                Value<int?> paymentSourceId = const Value.absent(),
                Value<DateTime> settlementDate = const Value.absent(),
                Value<int?> linkedTransactionId = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SplitSettlementsCompanion(
                id: id,
                groupId: groupId,
                fromMemberId: fromMemberId,
                toMemberId: toMemberId,
                amount: amount,
                paymentSourceType: paymentSourceType,
                paymentSourceId: paymentSourceId,
                settlementDate: settlementDate,
                linkedTransactionId: linkedTransactionId,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int groupId,
                required int fromMemberId,
                required int toMemberId,
                required double amount,
                Value<String?> paymentSourceType = const Value.absent(),
                Value<int?> paymentSourceId = const Value.absent(),
                required DateTime settlementDate,
                Value<int?> linkedTransactionId = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SplitSettlementsCompanion.insert(
                id: id,
                groupId: groupId,
                fromMemberId: fromMemberId,
                toMemberId: toMemberId,
                amount: amount,
                paymentSourceType: paymentSourceType,
                paymentSourceId: paymentSourceId,
                settlementDate: settlementDate,
                linkedTransactionId: linkedTransactionId,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SplitSettlementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SplitSettlementsTable,
      SplitSettlement,
      $$SplitSettlementsTableFilterComposer,
      $$SplitSettlementsTableOrderingComposer,
      $$SplitSettlementsTableAnnotationComposer,
      $$SplitSettlementsTableCreateCompanionBuilder,
      $$SplitSettlementsTableUpdateCompanionBuilder,
      (
        SplitSettlement,
        BaseReferences<_$AppDatabase, $SplitSettlementsTable, SplitSettlement>,
      ),
      SplitSettlement,
      PrefetchHooks Function()
    >;
typedef $$LoansTableCreateCompanionBuilder =
    LoansCompanion Function({
      Value<int> id,
      required String title,
      required String lenderName,
      Value<String?> lenderType,
      Value<String> loanType,
      required double principalAmount,
      required double currentOutstanding,
      Value<double?> interestRate,
      Value<double?> emiAmount,
      Value<int?> emiDay,
      Value<int?> tenureMonths,
      Value<DateTime?> startDate,
      Value<DateTime?> endDate,
      Value<int?> linkedAccountId,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> closedAt,
    });
typedef $$LoansTableUpdateCompanionBuilder =
    LoansCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String> lenderName,
      Value<String?> lenderType,
      Value<String> loanType,
      Value<double> principalAmount,
      Value<double> currentOutstanding,
      Value<double?> interestRate,
      Value<double?> emiAmount,
      Value<int?> emiDay,
      Value<int?> tenureMonths,
      Value<DateTime?> startDate,
      Value<DateTime?> endDate,
      Value<int?> linkedAccountId,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> closedAt,
    });

class $$LoansTableFilterComposer extends Composer<_$AppDatabase, $LoansTable> {
  $$LoansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lenderName => $composableBuilder(
    column: $table.lenderName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lenderType => $composableBuilder(
    column: $table.lenderType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get loanType => $composableBuilder(
    column: $table.loanType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get principalAmount => $composableBuilder(
    column: $table.principalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get currentOutstanding => $composableBuilder(
    column: $table.currentOutstanding,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get interestRate => $composableBuilder(
    column: $table.interestRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get emiAmount => $composableBuilder(
    column: $table.emiAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get emiDay => $composableBuilder(
    column: $table.emiDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tenureMonths => $composableBuilder(
    column: $table.tenureMonths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get linkedAccountId => $composableBuilder(
    column: $table.linkedAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LoansTableOrderingComposer
    extends Composer<_$AppDatabase, $LoansTable> {
  $$LoansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lenderName => $composableBuilder(
    column: $table.lenderName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lenderType => $composableBuilder(
    column: $table.lenderType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get loanType => $composableBuilder(
    column: $table.loanType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get principalAmount => $composableBuilder(
    column: $table.principalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get currentOutstanding => $composableBuilder(
    column: $table.currentOutstanding,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get interestRate => $composableBuilder(
    column: $table.interestRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get emiAmount => $composableBuilder(
    column: $table.emiAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get emiDay => $composableBuilder(
    column: $table.emiDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tenureMonths => $composableBuilder(
    column: $table.tenureMonths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get linkedAccountId => $composableBuilder(
    column: $table.linkedAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LoansTableAnnotationComposer
    extends Composer<_$AppDatabase, $LoansTable> {
  $$LoansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get lenderName => $composableBuilder(
    column: $table.lenderName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lenderType => $composableBuilder(
    column: $table.lenderType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get loanType =>
      $composableBuilder(column: $table.loanType, builder: (column) => column);

  GeneratedColumn<double> get principalAmount => $composableBuilder(
    column: $table.principalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get currentOutstanding => $composableBuilder(
    column: $table.currentOutstanding,
    builder: (column) => column,
  );

  GeneratedColumn<double> get interestRate => $composableBuilder(
    column: $table.interestRate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get emiAmount =>
      $composableBuilder(column: $table.emiAmount, builder: (column) => column);

  GeneratedColumn<int> get emiDay =>
      $composableBuilder(column: $table.emiDay, builder: (column) => column);

  GeneratedColumn<int> get tenureMonths => $composableBuilder(
    column: $table.tenureMonths,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<int> get linkedAccountId => $composableBuilder(
    column: $table.linkedAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get closedAt =>
      $composableBuilder(column: $table.closedAt, builder: (column) => column);
}

class $$LoansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LoansTable,
          Loan,
          $$LoansTableFilterComposer,
          $$LoansTableOrderingComposer,
          $$LoansTableAnnotationComposer,
          $$LoansTableCreateCompanionBuilder,
          $$LoansTableUpdateCompanionBuilder,
          (Loan, BaseReferences<_$AppDatabase, $LoansTable, Loan>),
          Loan,
          PrefetchHooks Function()
        > {
  $$LoansTableTableManager(_$AppDatabase db, $LoansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LoansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LoansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LoansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> lenderName = const Value.absent(),
                Value<String?> lenderType = const Value.absent(),
                Value<String> loanType = const Value.absent(),
                Value<double> principalAmount = const Value.absent(),
                Value<double> currentOutstanding = const Value.absent(),
                Value<double?> interestRate = const Value.absent(),
                Value<double?> emiAmount = const Value.absent(),
                Value<int?> emiDay = const Value.absent(),
                Value<int?> tenureMonths = const Value.absent(),
                Value<DateTime?> startDate = const Value.absent(),
                Value<DateTime?> endDate = const Value.absent(),
                Value<int?> linkedAccountId = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> closedAt = const Value.absent(),
              }) => LoansCompanion(
                id: id,
                title: title,
                lenderName: lenderName,
                lenderType: lenderType,
                loanType: loanType,
                principalAmount: principalAmount,
                currentOutstanding: currentOutstanding,
                interestRate: interestRate,
                emiAmount: emiAmount,
                emiDay: emiDay,
                tenureMonths: tenureMonths,
                startDate: startDate,
                endDate: endDate,
                linkedAccountId: linkedAccountId,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                closedAt: closedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required String lenderName,
                Value<String?> lenderType = const Value.absent(),
                Value<String> loanType = const Value.absent(),
                required double principalAmount,
                required double currentOutstanding,
                Value<double?> interestRate = const Value.absent(),
                Value<double?> emiAmount = const Value.absent(),
                Value<int?> emiDay = const Value.absent(),
                Value<int?> tenureMonths = const Value.absent(),
                Value<DateTime?> startDate = const Value.absent(),
                Value<DateTime?> endDate = const Value.absent(),
                Value<int?> linkedAccountId = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> closedAt = const Value.absent(),
              }) => LoansCompanion.insert(
                id: id,
                title: title,
                lenderName: lenderName,
                lenderType: lenderType,
                loanType: loanType,
                principalAmount: principalAmount,
                currentOutstanding: currentOutstanding,
                interestRate: interestRate,
                emiAmount: emiAmount,
                emiDay: emiDay,
                tenureMonths: tenureMonths,
                startDate: startDate,
                endDate: endDate,
                linkedAccountId: linkedAccountId,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                closedAt: closedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LoansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LoansTable,
      Loan,
      $$LoansTableFilterComposer,
      $$LoansTableOrderingComposer,
      $$LoansTableAnnotationComposer,
      $$LoansTableCreateCompanionBuilder,
      $$LoansTableUpdateCompanionBuilder,
      (Loan, BaseReferences<_$AppDatabase, $LoansTable, Loan>),
      Loan,
      PrefetchHooks Function()
    >;
typedef $$LoanPaymentsTableCreateCompanionBuilder =
    LoanPaymentsCompanion Function({
      Value<int> id,
      required int loanId,
      required double amount,
      required DateTime paymentDate,
      Value<String?> paymentSourceType,
      Value<int?> paymentSourceId,
      Value<int?> linkedTransactionId,
      Value<String?> notes,
      Value<DateTime> createdAt,
    });
typedef $$LoanPaymentsTableUpdateCompanionBuilder =
    LoanPaymentsCompanion Function({
      Value<int> id,
      Value<int> loanId,
      Value<double> amount,
      Value<DateTime> paymentDate,
      Value<String?> paymentSourceType,
      Value<int?> paymentSourceId,
      Value<int?> linkedTransactionId,
      Value<String?> notes,
      Value<DateTime> createdAt,
    });

class $$LoanPaymentsTableFilterComposer
    extends Composer<_$AppDatabase, $LoanPaymentsTable> {
  $$LoanPaymentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get loanId => $composableBuilder(
    column: $table.loanId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get paymentDate => $composableBuilder(
    column: $table.paymentDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentSourceType => $composableBuilder(
    column: $table.paymentSourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paymentSourceId => $composableBuilder(
    column: $table.paymentSourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get linkedTransactionId => $composableBuilder(
    column: $table.linkedTransactionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LoanPaymentsTableOrderingComposer
    extends Composer<_$AppDatabase, $LoanPaymentsTable> {
  $$LoanPaymentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get loanId => $composableBuilder(
    column: $table.loanId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get paymentDate => $composableBuilder(
    column: $table.paymentDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentSourceType => $composableBuilder(
    column: $table.paymentSourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paymentSourceId => $composableBuilder(
    column: $table.paymentSourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get linkedTransactionId => $composableBuilder(
    column: $table.linkedTransactionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LoanPaymentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LoanPaymentsTable> {
  $$LoanPaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get loanId =>
      $composableBuilder(column: $table.loanId, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<DateTime> get paymentDate => $composableBuilder(
    column: $table.paymentDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentSourceType => $composableBuilder(
    column: $table.paymentSourceType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get paymentSourceId => $composableBuilder(
    column: $table.paymentSourceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get linkedTransactionId => $composableBuilder(
    column: $table.linkedTransactionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LoanPaymentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LoanPaymentsTable,
          LoanPayment,
          $$LoanPaymentsTableFilterComposer,
          $$LoanPaymentsTableOrderingComposer,
          $$LoanPaymentsTableAnnotationComposer,
          $$LoanPaymentsTableCreateCompanionBuilder,
          $$LoanPaymentsTableUpdateCompanionBuilder,
          (
            LoanPayment,
            BaseReferences<_$AppDatabase, $LoanPaymentsTable, LoanPayment>,
          ),
          LoanPayment,
          PrefetchHooks Function()
        > {
  $$LoanPaymentsTableTableManager(_$AppDatabase db, $LoanPaymentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LoanPaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LoanPaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LoanPaymentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> loanId = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<DateTime> paymentDate = const Value.absent(),
                Value<String?> paymentSourceType = const Value.absent(),
                Value<int?> paymentSourceId = const Value.absent(),
                Value<int?> linkedTransactionId = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => LoanPaymentsCompanion(
                id: id,
                loanId: loanId,
                amount: amount,
                paymentDate: paymentDate,
                paymentSourceType: paymentSourceType,
                paymentSourceId: paymentSourceId,
                linkedTransactionId: linkedTransactionId,
                notes: notes,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int loanId,
                required double amount,
                required DateTime paymentDate,
                Value<String?> paymentSourceType = const Value.absent(),
                Value<int?> paymentSourceId = const Value.absent(),
                Value<int?> linkedTransactionId = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => LoanPaymentsCompanion.insert(
                id: id,
                loanId: loanId,
                amount: amount,
                paymentDate: paymentDate,
                paymentSourceType: paymentSourceType,
                paymentSourceId: paymentSourceId,
                linkedTransactionId: linkedTransactionId,
                notes: notes,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LoanPaymentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LoanPaymentsTable,
      LoanPayment,
      $$LoanPaymentsTableFilterComposer,
      $$LoanPaymentsTableOrderingComposer,
      $$LoanPaymentsTableAnnotationComposer,
      $$LoanPaymentsTableCreateCompanionBuilder,
      $$LoanPaymentsTableUpdateCompanionBuilder,
      (
        LoanPayment,
        BaseReferences<_$AppDatabase, $LoanPaymentsTable, LoanPayment>,
      ),
      LoanPayment,
      PrefetchHooks Function()
    >;
typedef $$AlertsTableCreateCompanionBuilder =
    AlertsCompanion Function({
      Value<int> id,
      required String alertType,
      required String title,
      required String body,
      Value<DateTime> createdAt,
      Value<DateTime?> scheduledAt,
      Value<String> priority,
      Value<DateTime?> readAt,
      Value<String?> actionRoute,
      Value<String?> payload,
      Value<DateTime?> dismissedAt,
      Value<String?> dedupeKey,
    });
typedef $$AlertsTableUpdateCompanionBuilder =
    AlertsCompanion Function({
      Value<int> id,
      Value<String> alertType,
      Value<String> title,
      Value<String> body,
      Value<DateTime> createdAt,
      Value<DateTime?> scheduledAt,
      Value<String> priority,
      Value<DateTime?> readAt,
      Value<String?> actionRoute,
      Value<String?> payload,
      Value<DateTime?> dismissedAt,
      Value<String?> dedupeKey,
    });

class $$AlertsTableFilterComposer
    extends Composer<_$AppDatabase, $AlertsTable> {
  $$AlertsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get alertType => $composableBuilder(
    column: $table.alertType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get readAt => $composableBuilder(
    column: $table.readAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actionRoute => $composableBuilder(
    column: $table.actionRoute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dismissedAt => $composableBuilder(
    column: $table.dismissedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dedupeKey => $composableBuilder(
    column: $table.dedupeKey,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AlertsTableOrderingComposer
    extends Composer<_$AppDatabase, $AlertsTable> {
  $$AlertsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get alertType => $composableBuilder(
    column: $table.alertType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get readAt => $composableBuilder(
    column: $table.readAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actionRoute => $composableBuilder(
    column: $table.actionRoute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dismissedAt => $composableBuilder(
    column: $table.dismissedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dedupeKey => $composableBuilder(
    column: $table.dedupeKey,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AlertsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AlertsTable> {
  $$AlertsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get alertType =>
      $composableBuilder(column: $table.alertType, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<DateTime> get readAt =>
      $composableBuilder(column: $table.readAt, builder: (column) => column);

  GeneratedColumn<String> get actionRoute => $composableBuilder(
    column: $table.actionRoute,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get dismissedAt => $composableBuilder(
    column: $table.dismissedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dedupeKey =>
      $composableBuilder(column: $table.dedupeKey, builder: (column) => column);
}

class $$AlertsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AlertsTable,
          Alert,
          $$AlertsTableFilterComposer,
          $$AlertsTableOrderingComposer,
          $$AlertsTableAnnotationComposer,
          $$AlertsTableCreateCompanionBuilder,
          $$AlertsTableUpdateCompanionBuilder,
          (Alert, BaseReferences<_$AppDatabase, $AlertsTable, Alert>),
          Alert,
          PrefetchHooks Function()
        > {
  $$AlertsTableTableManager(_$AppDatabase db, $AlertsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlertsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlertsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlertsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> alertType = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> scheduledAt = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<DateTime?> readAt = const Value.absent(),
                Value<String?> actionRoute = const Value.absent(),
                Value<String?> payload = const Value.absent(),
                Value<DateTime?> dismissedAt = const Value.absent(),
                Value<String?> dedupeKey = const Value.absent(),
              }) => AlertsCompanion(
                id: id,
                alertType: alertType,
                title: title,
                body: body,
                createdAt: createdAt,
                scheduledAt: scheduledAt,
                priority: priority,
                readAt: readAt,
                actionRoute: actionRoute,
                payload: payload,
                dismissedAt: dismissedAt,
                dedupeKey: dedupeKey,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String alertType,
                required String title,
                required String body,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> scheduledAt = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<DateTime?> readAt = const Value.absent(),
                Value<String?> actionRoute = const Value.absent(),
                Value<String?> payload = const Value.absent(),
                Value<DateTime?> dismissedAt = const Value.absent(),
                Value<String?> dedupeKey = const Value.absent(),
              }) => AlertsCompanion.insert(
                id: id,
                alertType: alertType,
                title: title,
                body: body,
                createdAt: createdAt,
                scheduledAt: scheduledAt,
                priority: priority,
                readAt: readAt,
                actionRoute: actionRoute,
                payload: payload,
                dismissedAt: dismissedAt,
                dedupeKey: dedupeKey,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AlertsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AlertsTable,
      Alert,
      $$AlertsTableFilterComposer,
      $$AlertsTableOrderingComposer,
      $$AlertsTableAnnotationComposer,
      $$AlertsTableCreateCompanionBuilder,
      $$AlertsTableUpdateCompanionBuilder,
      (Alert, BaseReferences<_$AppDatabase, $AlertsTable, Alert>),
      Alert,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<bool> isDarkMode,
      Value<bool> appLockEnabled,
      Value<bool> notificationDetectionEnabled,
      Value<bool> showDetectionNotifications,
      Value<bool> reminderEnabled,
      Value<bool> dailyReminderEnabled,
      Value<bool> weeklyReminderEnabled,
      Value<int> reminderHour,
      Value<int> reminderMinute,
      Value<int> weeklyReminderWeekday,
      Value<bool> cardDueReminderEnabled,
      Value<bool> pendingTransactionReminderEnabled,
      Value<bool> settlementReminderEnabled,
      Value<DateTime?> lastReminderShownAt,
      Value<bool> smsDetectionEnabled,
      Value<DateTime?> smsPermissionAskedAt,
      Value<bool> smsBackfillEnabled,
      Value<int> smsBackfillDays,
      Value<DateTime?> smsLastScannedAt,
      Value<bool> hasCompletedOnboarding,
      Value<int> quietHoursStartHour,
      Value<int> quietHoursStartMinute,
      Value<int> quietHoursEndHour,
      Value<int> quietHoursEndMinute,
      Value<bool> smartAlertsEnabled,
      Value<bool> lowBalanceAlertsEnabled,
      Value<double> lowBalanceThreshold,
      Value<bool> largeExpenseAlertsEnabled,
      Value<double> largeExpenseThreshold,
      Value<bool> unusualSpendingAlertsEnabled,
      Value<double> unusualSpendingMultiplier,
      Value<bool> recurringMerchantAlertsEnabled,
      Value<bool> weeklySummaryAlertsEnabled,
      Value<bool> monthlySummaryAlertsEnabled,
      Value<String?> userName,
      Value<double?> monthlySalary,
      Value<int?> salaryCreditDay,
      Value<String?> companyName,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<bool> isDarkMode,
      Value<bool> appLockEnabled,
      Value<bool> notificationDetectionEnabled,
      Value<bool> showDetectionNotifications,
      Value<bool> reminderEnabled,
      Value<bool> dailyReminderEnabled,
      Value<bool> weeklyReminderEnabled,
      Value<int> reminderHour,
      Value<int> reminderMinute,
      Value<int> weeklyReminderWeekday,
      Value<bool> cardDueReminderEnabled,
      Value<bool> pendingTransactionReminderEnabled,
      Value<bool> settlementReminderEnabled,
      Value<DateTime?> lastReminderShownAt,
      Value<bool> smsDetectionEnabled,
      Value<DateTime?> smsPermissionAskedAt,
      Value<bool> smsBackfillEnabled,
      Value<int> smsBackfillDays,
      Value<DateTime?> smsLastScannedAt,
      Value<bool> hasCompletedOnboarding,
      Value<int> quietHoursStartHour,
      Value<int> quietHoursStartMinute,
      Value<int> quietHoursEndHour,
      Value<int> quietHoursEndMinute,
      Value<bool> smartAlertsEnabled,
      Value<bool> lowBalanceAlertsEnabled,
      Value<double> lowBalanceThreshold,
      Value<bool> largeExpenseAlertsEnabled,
      Value<double> largeExpenseThreshold,
      Value<bool> unusualSpendingAlertsEnabled,
      Value<double> unusualSpendingMultiplier,
      Value<bool> recurringMerchantAlertsEnabled,
      Value<bool> weeklySummaryAlertsEnabled,
      Value<bool> monthlySummaryAlertsEnabled,
      Value<String?> userName,
      Value<double?> monthlySalary,
      Value<int?> salaryCreditDay,
      Value<String?> companyName,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDarkMode => $composableBuilder(
    column: $table.isDarkMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get appLockEnabled => $composableBuilder(
    column: $table.appLockEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notificationDetectionEnabled => $composableBuilder(
    column: $table.notificationDetectionEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showDetectionNotifications => $composableBuilder(
    column: $table.showDetectionNotifications,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get reminderEnabled => $composableBuilder(
    column: $table.reminderEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dailyReminderEnabled => $composableBuilder(
    column: $table.dailyReminderEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get weeklyReminderEnabled => $composableBuilder(
    column: $table.weeklyReminderEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderHour => $composableBuilder(
    column: $table.reminderHour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderMinute => $composableBuilder(
    column: $table.reminderMinute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get weeklyReminderWeekday => $composableBuilder(
    column: $table.weeklyReminderWeekday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get cardDueReminderEnabled => $composableBuilder(
    column: $table.cardDueReminderEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendingTransactionReminderEnabled =>
      $composableBuilder(
        column: $table.pendingTransactionReminderEnabled,
        builder: (column) => ColumnFilters(column),
      );

  ColumnFilters<bool> get settlementReminderEnabled => $composableBuilder(
    column: $table.settlementReminderEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastReminderShownAt => $composableBuilder(
    column: $table.lastReminderShownAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get smsDetectionEnabled => $composableBuilder(
    column: $table.smsDetectionEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get smsPermissionAskedAt => $composableBuilder(
    column: $table.smsPermissionAskedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get smsBackfillEnabled => $composableBuilder(
    column: $table.smsBackfillEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get smsBackfillDays => $composableBuilder(
    column: $table.smsBackfillDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get smsLastScannedAt => $composableBuilder(
    column: $table.smsLastScannedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasCompletedOnboarding => $composableBuilder(
    column: $table.hasCompletedOnboarding,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quietHoursStartHour => $composableBuilder(
    column: $table.quietHoursStartHour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quietHoursStartMinute => $composableBuilder(
    column: $table.quietHoursStartMinute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quietHoursEndHour => $composableBuilder(
    column: $table.quietHoursEndHour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quietHoursEndMinute => $composableBuilder(
    column: $table.quietHoursEndMinute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get smartAlertsEnabled => $composableBuilder(
    column: $table.smartAlertsEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get lowBalanceAlertsEnabled => $composableBuilder(
    column: $table.lowBalanceAlertsEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lowBalanceThreshold => $composableBuilder(
    column: $table.lowBalanceThreshold,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get largeExpenseAlertsEnabled => $composableBuilder(
    column: $table.largeExpenseAlertsEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get largeExpenseThreshold => $composableBuilder(
    column: $table.largeExpenseThreshold,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get unusualSpendingAlertsEnabled => $composableBuilder(
    column: $table.unusualSpendingAlertsEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get unusualSpendingMultiplier => $composableBuilder(
    column: $table.unusualSpendingMultiplier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get recurringMerchantAlertsEnabled => $composableBuilder(
    column: $table.recurringMerchantAlertsEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get weeklySummaryAlertsEnabled => $composableBuilder(
    column: $table.weeklySummaryAlertsEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get monthlySummaryAlertsEnabled => $composableBuilder(
    column: $table.monthlySummaryAlertsEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userName => $composableBuilder(
    column: $table.userName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get monthlySalary => $composableBuilder(
    column: $table.monthlySalary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get salaryCreditDay => $composableBuilder(
    column: $table.salaryCreditDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyName => $composableBuilder(
    column: $table.companyName,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDarkMode => $composableBuilder(
    column: $table.isDarkMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get appLockEnabled => $composableBuilder(
    column: $table.appLockEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notificationDetectionEnabled => $composableBuilder(
    column: $table.notificationDetectionEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showDetectionNotifications => $composableBuilder(
    column: $table.showDetectionNotifications,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get reminderEnabled => $composableBuilder(
    column: $table.reminderEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dailyReminderEnabled => $composableBuilder(
    column: $table.dailyReminderEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get weeklyReminderEnabled => $composableBuilder(
    column: $table.weeklyReminderEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderHour => $composableBuilder(
    column: $table.reminderHour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderMinute => $composableBuilder(
    column: $table.reminderMinute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weeklyReminderWeekday => $composableBuilder(
    column: $table.weeklyReminderWeekday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get cardDueReminderEnabled => $composableBuilder(
    column: $table.cardDueReminderEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendingTransactionReminderEnabled =>
      $composableBuilder(
        column: $table.pendingTransactionReminderEnabled,
        builder: (column) => ColumnOrderings(column),
      );

  ColumnOrderings<bool> get settlementReminderEnabled => $composableBuilder(
    column: $table.settlementReminderEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastReminderShownAt => $composableBuilder(
    column: $table.lastReminderShownAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get smsDetectionEnabled => $composableBuilder(
    column: $table.smsDetectionEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get smsPermissionAskedAt => $composableBuilder(
    column: $table.smsPermissionAskedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get smsBackfillEnabled => $composableBuilder(
    column: $table.smsBackfillEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get smsBackfillDays => $composableBuilder(
    column: $table.smsBackfillDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get smsLastScannedAt => $composableBuilder(
    column: $table.smsLastScannedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasCompletedOnboarding => $composableBuilder(
    column: $table.hasCompletedOnboarding,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quietHoursStartHour => $composableBuilder(
    column: $table.quietHoursStartHour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quietHoursStartMinute => $composableBuilder(
    column: $table.quietHoursStartMinute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quietHoursEndHour => $composableBuilder(
    column: $table.quietHoursEndHour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quietHoursEndMinute => $composableBuilder(
    column: $table.quietHoursEndMinute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get smartAlertsEnabled => $composableBuilder(
    column: $table.smartAlertsEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get lowBalanceAlertsEnabled => $composableBuilder(
    column: $table.lowBalanceAlertsEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lowBalanceThreshold => $composableBuilder(
    column: $table.lowBalanceThreshold,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get largeExpenseAlertsEnabled => $composableBuilder(
    column: $table.largeExpenseAlertsEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get largeExpenseThreshold => $composableBuilder(
    column: $table.largeExpenseThreshold,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get unusualSpendingAlertsEnabled => $composableBuilder(
    column: $table.unusualSpendingAlertsEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get unusualSpendingMultiplier => $composableBuilder(
    column: $table.unusualSpendingMultiplier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get recurringMerchantAlertsEnabled =>
      $composableBuilder(
        column: $table.recurringMerchantAlertsEnabled,
        builder: (column) => ColumnOrderings(column),
      );

  ColumnOrderings<bool> get weeklySummaryAlertsEnabled => $composableBuilder(
    column: $table.weeklySummaryAlertsEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get monthlySummaryAlertsEnabled => $composableBuilder(
    column: $table.monthlySummaryAlertsEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userName => $composableBuilder(
    column: $table.userName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get monthlySalary => $composableBuilder(
    column: $table.monthlySalary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get salaryCreditDay => $composableBuilder(
    column: $table.salaryCreditDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyName => $composableBuilder(
    column: $table.companyName,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get isDarkMode => $composableBuilder(
    column: $table.isDarkMode,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get appLockEnabled => $composableBuilder(
    column: $table.appLockEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get notificationDetectionEnabled => $composableBuilder(
    column: $table.notificationDetectionEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showDetectionNotifications => $composableBuilder(
    column: $table.showDetectionNotifications,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get reminderEnabled => $composableBuilder(
    column: $table.reminderEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get dailyReminderEnabled => $composableBuilder(
    column: $table.dailyReminderEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get weeklyReminderEnabled => $composableBuilder(
    column: $table.weeklyReminderEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reminderHour => $composableBuilder(
    column: $table.reminderHour,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reminderMinute => $composableBuilder(
    column: $table.reminderMinute,
    builder: (column) => column,
  );

  GeneratedColumn<int> get weeklyReminderWeekday => $composableBuilder(
    column: $table.weeklyReminderWeekday,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get cardDueReminderEnabled => $composableBuilder(
    column: $table.cardDueReminderEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get pendingTransactionReminderEnabled =>
      $composableBuilder(
        column: $table.pendingTransactionReminderEnabled,
        builder: (column) => column,
      );

  GeneratedColumn<bool> get settlementReminderEnabled => $composableBuilder(
    column: $table.settlementReminderEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastReminderShownAt => $composableBuilder(
    column: $table.lastReminderShownAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get smsDetectionEnabled => $composableBuilder(
    column: $table.smsDetectionEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get smsPermissionAskedAt => $composableBuilder(
    column: $table.smsPermissionAskedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get smsBackfillEnabled => $composableBuilder(
    column: $table.smsBackfillEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get smsBackfillDays => $composableBuilder(
    column: $table.smsBackfillDays,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get smsLastScannedAt => $composableBuilder(
    column: $table.smsLastScannedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasCompletedOnboarding => $composableBuilder(
    column: $table.hasCompletedOnboarding,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quietHoursStartHour => $composableBuilder(
    column: $table.quietHoursStartHour,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quietHoursStartMinute => $composableBuilder(
    column: $table.quietHoursStartMinute,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quietHoursEndHour => $composableBuilder(
    column: $table.quietHoursEndHour,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quietHoursEndMinute => $composableBuilder(
    column: $table.quietHoursEndMinute,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get smartAlertsEnabled => $composableBuilder(
    column: $table.smartAlertsEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get lowBalanceAlertsEnabled => $composableBuilder(
    column: $table.lowBalanceAlertsEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<double> get lowBalanceThreshold => $composableBuilder(
    column: $table.lowBalanceThreshold,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get largeExpenseAlertsEnabled => $composableBuilder(
    column: $table.largeExpenseAlertsEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<double> get largeExpenseThreshold => $composableBuilder(
    column: $table.largeExpenseThreshold,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get unusualSpendingAlertsEnabled => $composableBuilder(
    column: $table.unusualSpendingAlertsEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<double> get unusualSpendingMultiplier => $composableBuilder(
    column: $table.unusualSpendingMultiplier,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get recurringMerchantAlertsEnabled =>
      $composableBuilder(
        column: $table.recurringMerchantAlertsEnabled,
        builder: (column) => column,
      );

  GeneratedColumn<bool> get weeklySummaryAlertsEnabled => $composableBuilder(
    column: $table.weeklySummaryAlertsEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get monthlySummaryAlertsEnabled => $composableBuilder(
    column: $table.monthlySummaryAlertsEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userName =>
      $composableBuilder(column: $table.userName, builder: (column) => column);

  GeneratedColumn<double> get monthlySalary => $composableBuilder(
    column: $table.monthlySalary,
    builder: (column) => column,
  );

  GeneratedColumn<int> get salaryCreditDay => $composableBuilder(
    column: $table.salaryCreditDay,
    builder: (column) => column,
  );

  GeneratedColumn<String> get companyName => $composableBuilder(
    column: $table.companyName,
    builder: (column) => column,
  );
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> isDarkMode = const Value.absent(),
                Value<bool> appLockEnabled = const Value.absent(),
                Value<bool> notificationDetectionEnabled = const Value.absent(),
                Value<bool> showDetectionNotifications = const Value.absent(),
                Value<bool> reminderEnabled = const Value.absent(),
                Value<bool> dailyReminderEnabled = const Value.absent(),
                Value<bool> weeklyReminderEnabled = const Value.absent(),
                Value<int> reminderHour = const Value.absent(),
                Value<int> reminderMinute = const Value.absent(),
                Value<int> weeklyReminderWeekday = const Value.absent(),
                Value<bool> cardDueReminderEnabled = const Value.absent(),
                Value<bool> pendingTransactionReminderEnabled =
                    const Value.absent(),
                Value<bool> settlementReminderEnabled = const Value.absent(),
                Value<DateTime?> lastReminderShownAt = const Value.absent(),
                Value<bool> smsDetectionEnabled = const Value.absent(),
                Value<DateTime?> smsPermissionAskedAt = const Value.absent(),
                Value<bool> smsBackfillEnabled = const Value.absent(),
                Value<int> smsBackfillDays = const Value.absent(),
                Value<DateTime?> smsLastScannedAt = const Value.absent(),
                Value<bool> hasCompletedOnboarding = const Value.absent(),
                Value<int> quietHoursStartHour = const Value.absent(),
                Value<int> quietHoursStartMinute = const Value.absent(),
                Value<int> quietHoursEndHour = const Value.absent(),
                Value<int> quietHoursEndMinute = const Value.absent(),
                Value<bool> smartAlertsEnabled = const Value.absent(),
                Value<bool> lowBalanceAlertsEnabled = const Value.absent(),
                Value<double> lowBalanceThreshold = const Value.absent(),
                Value<bool> largeExpenseAlertsEnabled = const Value.absent(),
                Value<double> largeExpenseThreshold = const Value.absent(),
                Value<bool> unusualSpendingAlertsEnabled = const Value.absent(),
                Value<double> unusualSpendingMultiplier = const Value.absent(),
                Value<bool> recurringMerchantAlertsEnabled =
                    const Value.absent(),
                Value<bool> weeklySummaryAlertsEnabled = const Value.absent(),
                Value<bool> monthlySummaryAlertsEnabled = const Value.absent(),
                Value<String?> userName = const Value.absent(),
                Value<double?> monthlySalary = const Value.absent(),
                Value<int?> salaryCreditDay = const Value.absent(),
                Value<String?> companyName = const Value.absent(),
              }) => AppSettingsCompanion(
                id: id,
                isDarkMode: isDarkMode,
                appLockEnabled: appLockEnabled,
                notificationDetectionEnabled: notificationDetectionEnabled,
                showDetectionNotifications: showDetectionNotifications,
                reminderEnabled: reminderEnabled,
                dailyReminderEnabled: dailyReminderEnabled,
                weeklyReminderEnabled: weeklyReminderEnabled,
                reminderHour: reminderHour,
                reminderMinute: reminderMinute,
                weeklyReminderWeekday: weeklyReminderWeekday,
                cardDueReminderEnabled: cardDueReminderEnabled,
                pendingTransactionReminderEnabled:
                    pendingTransactionReminderEnabled,
                settlementReminderEnabled: settlementReminderEnabled,
                lastReminderShownAt: lastReminderShownAt,
                smsDetectionEnabled: smsDetectionEnabled,
                smsPermissionAskedAt: smsPermissionAskedAt,
                smsBackfillEnabled: smsBackfillEnabled,
                smsBackfillDays: smsBackfillDays,
                smsLastScannedAt: smsLastScannedAt,
                hasCompletedOnboarding: hasCompletedOnboarding,
                quietHoursStartHour: quietHoursStartHour,
                quietHoursStartMinute: quietHoursStartMinute,
                quietHoursEndHour: quietHoursEndHour,
                quietHoursEndMinute: quietHoursEndMinute,
                smartAlertsEnabled: smartAlertsEnabled,
                lowBalanceAlertsEnabled: lowBalanceAlertsEnabled,
                lowBalanceThreshold: lowBalanceThreshold,
                largeExpenseAlertsEnabled: largeExpenseAlertsEnabled,
                largeExpenseThreshold: largeExpenseThreshold,
                unusualSpendingAlertsEnabled: unusualSpendingAlertsEnabled,
                unusualSpendingMultiplier: unusualSpendingMultiplier,
                recurringMerchantAlertsEnabled: recurringMerchantAlertsEnabled,
                weeklySummaryAlertsEnabled: weeklySummaryAlertsEnabled,
                monthlySummaryAlertsEnabled: monthlySummaryAlertsEnabled,
                userName: userName,
                monthlySalary: monthlySalary,
                salaryCreditDay: salaryCreditDay,
                companyName: companyName,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> isDarkMode = const Value.absent(),
                Value<bool> appLockEnabled = const Value.absent(),
                Value<bool> notificationDetectionEnabled = const Value.absent(),
                Value<bool> showDetectionNotifications = const Value.absent(),
                Value<bool> reminderEnabled = const Value.absent(),
                Value<bool> dailyReminderEnabled = const Value.absent(),
                Value<bool> weeklyReminderEnabled = const Value.absent(),
                Value<int> reminderHour = const Value.absent(),
                Value<int> reminderMinute = const Value.absent(),
                Value<int> weeklyReminderWeekday = const Value.absent(),
                Value<bool> cardDueReminderEnabled = const Value.absent(),
                Value<bool> pendingTransactionReminderEnabled =
                    const Value.absent(),
                Value<bool> settlementReminderEnabled = const Value.absent(),
                Value<DateTime?> lastReminderShownAt = const Value.absent(),
                Value<bool> smsDetectionEnabled = const Value.absent(),
                Value<DateTime?> smsPermissionAskedAt = const Value.absent(),
                Value<bool> smsBackfillEnabled = const Value.absent(),
                Value<int> smsBackfillDays = const Value.absent(),
                Value<DateTime?> smsLastScannedAt = const Value.absent(),
                Value<bool> hasCompletedOnboarding = const Value.absent(),
                Value<int> quietHoursStartHour = const Value.absent(),
                Value<int> quietHoursStartMinute = const Value.absent(),
                Value<int> quietHoursEndHour = const Value.absent(),
                Value<int> quietHoursEndMinute = const Value.absent(),
                Value<bool> smartAlertsEnabled = const Value.absent(),
                Value<bool> lowBalanceAlertsEnabled = const Value.absent(),
                Value<double> lowBalanceThreshold = const Value.absent(),
                Value<bool> largeExpenseAlertsEnabled = const Value.absent(),
                Value<double> largeExpenseThreshold = const Value.absent(),
                Value<bool> unusualSpendingAlertsEnabled = const Value.absent(),
                Value<double> unusualSpendingMultiplier = const Value.absent(),
                Value<bool> recurringMerchantAlertsEnabled =
                    const Value.absent(),
                Value<bool> weeklySummaryAlertsEnabled = const Value.absent(),
                Value<bool> monthlySummaryAlertsEnabled = const Value.absent(),
                Value<String?> userName = const Value.absent(),
                Value<double?> monthlySalary = const Value.absent(),
                Value<int?> salaryCreditDay = const Value.absent(),
                Value<String?> companyName = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                id: id,
                isDarkMode: isDarkMode,
                appLockEnabled: appLockEnabled,
                notificationDetectionEnabled: notificationDetectionEnabled,
                showDetectionNotifications: showDetectionNotifications,
                reminderEnabled: reminderEnabled,
                dailyReminderEnabled: dailyReminderEnabled,
                weeklyReminderEnabled: weeklyReminderEnabled,
                reminderHour: reminderHour,
                reminderMinute: reminderMinute,
                weeklyReminderWeekday: weeklyReminderWeekday,
                cardDueReminderEnabled: cardDueReminderEnabled,
                pendingTransactionReminderEnabled:
                    pendingTransactionReminderEnabled,
                settlementReminderEnabled: settlementReminderEnabled,
                lastReminderShownAt: lastReminderShownAt,
                smsDetectionEnabled: smsDetectionEnabled,
                smsPermissionAskedAt: smsPermissionAskedAt,
                smsBackfillEnabled: smsBackfillEnabled,
                smsBackfillDays: smsBackfillDays,
                smsLastScannedAt: smsLastScannedAt,
                hasCompletedOnboarding: hasCompletedOnboarding,
                quietHoursStartHour: quietHoursStartHour,
                quietHoursStartMinute: quietHoursStartMinute,
                quietHoursEndHour: quietHoursEndHour,
                quietHoursEndMinute: quietHoursEndMinute,
                smartAlertsEnabled: smartAlertsEnabled,
                lowBalanceAlertsEnabled: lowBalanceAlertsEnabled,
                lowBalanceThreshold: lowBalanceThreshold,
                largeExpenseAlertsEnabled: largeExpenseAlertsEnabled,
                largeExpenseThreshold: largeExpenseThreshold,
                unusualSpendingAlertsEnabled: unusualSpendingAlertsEnabled,
                unusualSpendingMultiplier: unusualSpendingMultiplier,
                recurringMerchantAlertsEnabled: recurringMerchantAlertsEnabled,
                weeklySummaryAlertsEnabled: weeklySummaryAlertsEnabled,
                monthlySummaryAlertsEnabled: monthlySummaryAlertsEnabled,
                userName: userName,
                monthlySalary: monthlySalary,
                salaryCreditDay: salaryCreditDay,
                companyName: companyName,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BankAccountsTableTableManager get bankAccounts =>
      $$BankAccountsTableTableManager(_db, _db.bankAccounts);
  $$CashWalletsTableTableManager get cashWallets =>
      $$CashWalletsTableTableManager(_db, _db.cashWallets);
  $$CreditCardsTableTableManager get creditCards =>
      $$CreditCardsTableTableManager(_db, _db.creditCards);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$PendingTransactionsTableTableManager get pendingTransactions =>
      $$PendingTransactionsTableTableManager(_db, _db.pendingTransactions);
  $$CardBillsTableTableManager get cardBills =>
      $$CardBillsTableTableManager(_db, _db.cardBills);
  $$SplitGroupsTableTableManager get splitGroups =>
      $$SplitGroupsTableTableManager(_db, _db.splitGroups);
  $$SplitMembersTableTableManager get splitMembers =>
      $$SplitMembersTableTableManager(_db, _db.splitMembers);
  $$SplitExpensesTableTableManager get splitExpenses =>
      $$SplitExpensesTableTableManager(_db, _db.splitExpenses);
  $$SplitExpenseSharesTableTableManager get splitExpenseShares =>
      $$SplitExpenseSharesTableTableManager(_db, _db.splitExpenseShares);
  $$SplitSettlementsTableTableManager get splitSettlements =>
      $$SplitSettlementsTableTableManager(_db, _db.splitSettlements);
  $$LoansTableTableManager get loans =>
      $$LoansTableTableManager(_db, _db.loans);
  $$LoanPaymentsTableTableManager get loanPayments =>
      $$LoanPaymentsTableTableManager(_db, _db.loanPayments);
  $$AlertsTableTableManager get alerts =>
      $$AlertsTableTableManager(_db, _db.alerts);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
