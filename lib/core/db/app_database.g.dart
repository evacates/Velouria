part of 'app_database.dart';

class $MedicationsTable extends Medications
    with TableInfo<$MedicationsTable, Medication> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MedicationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  static const VerificationMeta _strengthMeta = const VerificationMeta(
    'strength',
  );
  @override
  late final GeneratedColumn<String> strength = GeneratedColumn<String>(
    'strength',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _formMeta = const VerificationMeta('form');
  @override
  late final GeneratedColumn<String> form = GeneratedColumn<String>(
    'form',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalPillsMeta = const VerificationMeta(
    'totalPills',
  );
  @override
  late final GeneratedColumn<int> totalPills = GeneratedColumn<int>(
    'total_pills',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pillPerDoseMeta = const VerificationMeta(
    'pillPerDose',
  );
  @override
  late final GeneratedColumn<int> pillPerDose = GeneratedColumn<int>(
    'pill_per_dose',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _refillThresholdMeta = const VerificationMeta(
    'refillThreshold',
  );
  @override
  late final GeneratedColumn<int> refillThreshold = GeneratedColumn<int>(
    'refill_threshold',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
    name,
    strength,
    form,
    totalPills,
    pillPerDose,
    refillThreshold,
    notes,
    isActive,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'medications';
  @override
  VerificationContext validateIntegrity(
    Insertable<Medication> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('strength')) {
      context.handle(
        _strengthMeta,
        strength.isAcceptableOrUnknown(data['strength']!, _strengthMeta),
      );
    }
    if (data.containsKey('form')) {
      context.handle(
        _formMeta,
        form.isAcceptableOrUnknown(data['form']!, _formMeta),
      );
    }
    if (data.containsKey('total_pills')) {
      context.handle(
        _totalPillsMeta,
        totalPills.isAcceptableOrUnknown(data['total_pills']!, _totalPillsMeta),
      );
    } else if (isInserting) {
      context.missing(_totalPillsMeta);
    }
    if (data.containsKey('pill_per_dose')) {
      context.handle(
        _pillPerDoseMeta,
        pillPerDose.isAcceptableOrUnknown(
          data['pill_per_dose']!,
          _pillPerDoseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pillPerDoseMeta);
    }
    if (data.containsKey('refill_threshold')) {
      context.handle(
        _refillThresholdMeta,
        refillThreshold.isAcceptableOrUnknown(
          data['refill_threshold']!,
          _refillThresholdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_refillThresholdMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
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
  Medication map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Medication(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      strength: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}strength'],
      ),
      form: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}form'],
      ),
      totalPills: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_pills'],
      )!,
      pillPerDose: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pill_per_dose'],
      )!,
      refillThreshold: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}refill_threshold'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MedicationsTable createAlias(String alias) {
    return $MedicationsTable(attachedDatabase, alias);
  }
}

class Medication extends DataClass implements Insertable<Medication> {
  final String id;
  final String name;

  /// Example: "500mg", optional for MVP.
  final String? strength;

  /// Example: "tablet", "capsule", optional for MVP.
  final String? form;

  /// Total pills currently on hand (used for refill prediction).
  final int totalPills;

  /// Pills to consume per confirmed dose.
  final int pillPerDose;

  /// If projected remaining pills crosses this threshold soon, warn.
  final int refillThreshold;
  final String? notes;

  /// Soft-delete/archive support.
  final bool isActive;
  final DateTime createdAt;
  const Medication({
    required this.id,
    required this.name,
    this.strength,
    this.form,
    required this.totalPills,
    required this.pillPerDose,
    required this.refillThreshold,
    this.notes,
    required this.isActive,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || strength != null) {
      map['strength'] = Variable<String>(strength);
    }
    if (!nullToAbsent || form != null) {
      map['form'] = Variable<String>(form);
    }
    map['total_pills'] = Variable<int>(totalPills);
    map['pill_per_dose'] = Variable<int>(pillPerDose);
    map['refill_threshold'] = Variable<int>(refillThreshold);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MedicationsCompanion toCompanion(bool nullToAbsent) {
    return MedicationsCompanion(
      id: Value(id),
      name: Value(name),
      strength: strength == null && nullToAbsent
          ? const Value.absent()
          : Value(strength),
      form: form == null && nullToAbsent ? const Value.absent() : Value(form),
      totalPills: Value(totalPills),
      pillPerDose: Value(pillPerDose),
      refillThreshold: Value(refillThreshold),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
    );
  }

  factory Medication.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Medication(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      strength: serializer.fromJson<String?>(json['strength']),
      form: serializer.fromJson<String?>(json['form']),
      totalPills: serializer.fromJson<int>(json['totalPills']),
      pillPerDose: serializer.fromJson<int>(json['pillPerDose']),
      refillThreshold: serializer.fromJson<int>(json['refillThreshold']),
      notes: serializer.fromJson<String?>(json['notes']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'strength': serializer.toJson<String?>(strength),
      'form': serializer.toJson<String?>(form),
      'totalPills': serializer.toJson<int>(totalPills),
      'pillPerDose': serializer.toJson<int>(pillPerDose),
      'refillThreshold': serializer.toJson<int>(refillThreshold),
      'notes': serializer.toJson<String?>(notes),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Medication copyWith({
    String? id,
    String? name,
    Value<String?> strength = const Value.absent(),
    Value<String?> form = const Value.absent(),
    int? totalPills,
    int? pillPerDose,
    int? refillThreshold,
    Value<String?> notes = const Value.absent(),
    bool? isActive,
    DateTime? createdAt,
  }) => Medication(
    id: id ?? this.id,
    name: name ?? this.name,
    strength: strength.present ? strength.value : this.strength,
    form: form.present ? form.value : this.form,
    totalPills: totalPills ?? this.totalPills,
    pillPerDose: pillPerDose ?? this.pillPerDose,
    refillThreshold: refillThreshold ?? this.refillThreshold,
    notes: notes.present ? notes.value : this.notes,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
  );
  Medication copyWithCompanion(MedicationsCompanion data) {
    return Medication(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      strength: data.strength.present ? data.strength.value : this.strength,
      form: data.form.present ? data.form.value : this.form,
      totalPills: data.totalPills.present
          ? data.totalPills.value
          : this.totalPills,
      pillPerDose: data.pillPerDose.present
          ? data.pillPerDose.value
          : this.pillPerDose,
      refillThreshold: data.refillThreshold.present
          ? data.refillThreshold.value
          : this.refillThreshold,
      notes: data.notes.present ? data.notes.value : this.notes,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Medication(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('strength: $strength, ')
          ..write('form: $form, ')
          ..write('totalPills: $totalPills, ')
          ..write('pillPerDose: $pillPerDose, ')
          ..write('refillThreshold: $refillThreshold, ')
          ..write('notes: $notes, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    strength,
    form,
    totalPills,
    pillPerDose,
    refillThreshold,
    notes,
    isActive,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Medication &&
          other.id == this.id &&
          other.name == this.name &&
          other.strength == this.strength &&
          other.form == this.form &&
          other.totalPills == this.totalPills &&
          other.pillPerDose == this.pillPerDose &&
          other.refillThreshold == this.refillThreshold &&
          other.notes == this.notes &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt);
}

class MedicationsCompanion extends UpdateCompanion<Medication> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> strength;
  final Value<String?> form;
  final Value<int> totalPills;
  final Value<int> pillPerDose;
  final Value<int> refillThreshold;
  final Value<String?> notes;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const MedicationsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.strength = const Value.absent(),
    this.form = const Value.absent(),
    this.totalPills = const Value.absent(),
    this.pillPerDose = const Value.absent(),
    this.refillThreshold = const Value.absent(),
    this.notes = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MedicationsCompanion.insert({
    required String id,
    required String name,
    this.strength = const Value.absent(),
    this.form = const Value.absent(),
    required int totalPills,
    required int pillPerDose,
    required int refillThreshold,
    this.notes = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       totalPills = Value(totalPills),
       pillPerDose = Value(pillPerDose),
       refillThreshold = Value(refillThreshold);
  static Insertable<Medication> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? strength,
    Expression<String>? form,
    Expression<int>? totalPills,
    Expression<int>? pillPerDose,
    Expression<int>? refillThreshold,
    Expression<String>? notes,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (strength != null) 'strength': strength,
      if (form != null) 'form': form,
      if (totalPills != null) 'total_pills': totalPills,
      if (pillPerDose != null) 'pill_per_dose': pillPerDose,
      if (refillThreshold != null) 'refill_threshold': refillThreshold,
      if (notes != null) 'notes': notes,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MedicationsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? strength,
    Value<String?>? form,
    Value<int>? totalPills,
    Value<int>? pillPerDose,
    Value<int>? refillThreshold,
    Value<String?>? notes,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return MedicationsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      strength: strength ?? this.strength,
      form: form ?? this.form,
      totalPills: totalPills ?? this.totalPills,
      pillPerDose: pillPerDose ?? this.pillPerDose,
      refillThreshold: refillThreshold ?? this.refillThreshold,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (strength.present) {
      map['strength'] = Variable<String>(strength.value);
    }
    if (form.present) {
      map['form'] = Variable<String>(form.value);
    }
    if (totalPills.present) {
      map['total_pills'] = Variable<int>(totalPills.value);
    }
    if (pillPerDose.present) {
      map['pill_per_dose'] = Variable<int>(pillPerDose.value);
    }
    if (refillThreshold.present) {
      map['refill_threshold'] = Variable<int>(refillThreshold.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MedicationsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('strength: $strength, ')
          ..write('form: $form, ')
          ..write('totalPills: $totalPills, ')
          ..write('pillPerDose: $pillPerDose, ')
          ..write('refillThreshold: $refillThreshold, ')
          ..write('notes: $notes, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DoseScheduleTimesTable extends DoseScheduleTimes
    with TableInfo<$DoseScheduleTimesTable, DoseScheduleTime> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DoseScheduleTimesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _medicationIdMeta = const VerificationMeta(
    'medicationId',
  );
  @override
  late final GeneratedColumn<String> medicationId = GeneratedColumn<String>(
    'medication_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES medications (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _timeHourMeta = const VerificationMeta(
    'timeHour',
  );
  @override
  late final GeneratedColumn<int> timeHour = GeneratedColumn<int>(
    'time_hour',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timeMinuteMeta = const VerificationMeta(
    'timeMinute',
  );
  @override
  late final GeneratedColumn<int> timeMinute = GeneratedColumn<int>(
    'time_minute',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _daysOfWeekBitmaskMeta = const VerificationMeta(
    'daysOfWeekBitmask',
  );
  @override
  late final GeneratedColumn<int> daysOfWeekBitmask = GeneratedColumn<int>(
    'days_of_week_bitmask',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(127),
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
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
  static const VerificationMeta _timezoneMeta = const VerificationMeta(
    'timezone',
  );
  @override
  late final GeneratedColumn<String> timezone = GeneratedColumn<String>(
    'timezone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isEnabledMeta = const VerificationMeta(
    'isEnabled',
  );
  @override
  late final GeneratedColumn<bool> isEnabled = GeneratedColumn<bool>(
    'is_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    medicationId,
    timeHour,
    timeMinute,
    daysOfWeekBitmask,
    startDate,
    endDate,
    timezone,
    isEnabled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dose_schedule_times';
  @override
  VerificationContext validateIntegrity(
    Insertable<DoseScheduleTime> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('medication_id')) {
      context.handle(
        _medicationIdMeta,
        medicationId.isAcceptableOrUnknown(
          data['medication_id']!,
          _medicationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_medicationIdMeta);
    }
    if (data.containsKey('time_hour')) {
      context.handle(
        _timeHourMeta,
        timeHour.isAcceptableOrUnknown(data['time_hour']!, _timeHourMeta),
      );
    } else if (isInserting) {
      context.missing(_timeHourMeta);
    }
    if (data.containsKey('time_minute')) {
      context.handle(
        _timeMinuteMeta,
        timeMinute.isAcceptableOrUnknown(data['time_minute']!, _timeMinuteMeta),
      );
    } else if (isInserting) {
      context.missing(_timeMinuteMeta);
    }
    if (data.containsKey('days_of_week_bitmask')) {
      context.handle(
        _daysOfWeekBitmaskMeta,
        daysOfWeekBitmask.isAcceptableOrUnknown(
          data['days_of_week_bitmask']!,
          _daysOfWeekBitmaskMeta,
        ),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    }
    if (data.containsKey('timezone')) {
      context.handle(
        _timezoneMeta,
        timezone.isAcceptableOrUnknown(data['timezone']!, _timezoneMeta),
      );
    }
    if (data.containsKey('is_enabled')) {
      context.handle(
        _isEnabledMeta,
        isEnabled.isAcceptableOrUnknown(data['is_enabled']!, _isEnabledMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DoseScheduleTime map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DoseScheduleTime(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      medicationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medication_id'],
      )!,
      timeHour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_hour'],
      )!,
      timeMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_minute'],
      )!,
      daysOfWeekBitmask: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}days_of_week_bitmask'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_date'],
      ),
      timezone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timezone'],
      ),
      isEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_enabled'],
      )!,
    );
  }

  @override
  $DoseScheduleTimesTable createAlias(String alias) {
    return $DoseScheduleTimesTable(attachedDatabase, alias);
  }
}

class DoseScheduleTime extends DataClass
    implements Insertable<DoseScheduleTime> {
  final int id;
  final String medicationId;

  /// Stored as local time fields (hour/minute).
  final int timeHour;
  final int timeMinute;

  /// 0..127 bitmask for Mon..Sun. (Bit 0 = Monday.)
  final int daysOfWeekBitmask;

  /// Range of validity for this time slot.
  final DateTime startDate;
  final DateTime? endDate;

  /// Optional override; if null, app uses user settings timezone.
  final String? timezone;
  final bool isEnabled;
  const DoseScheduleTime({
    required this.id,
    required this.medicationId,
    required this.timeHour,
    required this.timeMinute,
    required this.daysOfWeekBitmask,
    required this.startDate,
    this.endDate,
    this.timezone,
    required this.isEnabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['medication_id'] = Variable<String>(medicationId);
    map['time_hour'] = Variable<int>(timeHour);
    map['time_minute'] = Variable<int>(timeMinute);
    map['days_of_week_bitmask'] = Variable<int>(daysOfWeekBitmask);
    map['start_date'] = Variable<DateTime>(startDate);
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    if (!nullToAbsent || timezone != null) {
      map['timezone'] = Variable<String>(timezone);
    }
    map['is_enabled'] = Variable<bool>(isEnabled);
    return map;
  }

  DoseScheduleTimesCompanion toCompanion(bool nullToAbsent) {
    return DoseScheduleTimesCompanion(
      id: Value(id),
      medicationId: Value(medicationId),
      timeHour: Value(timeHour),
      timeMinute: Value(timeMinute),
      daysOfWeekBitmask: Value(daysOfWeekBitmask),
      startDate: Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      timezone: timezone == null && nullToAbsent
          ? const Value.absent()
          : Value(timezone),
      isEnabled: Value(isEnabled),
    );
  }

  factory DoseScheduleTime.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DoseScheduleTime(
      id: serializer.fromJson<int>(json['id']),
      medicationId: serializer.fromJson<String>(json['medicationId']),
      timeHour: serializer.fromJson<int>(json['timeHour']),
      timeMinute: serializer.fromJson<int>(json['timeMinute']),
      daysOfWeekBitmask: serializer.fromJson<int>(json['daysOfWeekBitmask']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
      timezone: serializer.fromJson<String?>(json['timezone']),
      isEnabled: serializer.fromJson<bool>(json['isEnabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'medicationId': serializer.toJson<String>(medicationId),
      'timeHour': serializer.toJson<int>(timeHour),
      'timeMinute': serializer.toJson<int>(timeMinute),
      'daysOfWeekBitmask': serializer.toJson<int>(daysOfWeekBitmask),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime?>(endDate),
      'timezone': serializer.toJson<String?>(timezone),
      'isEnabled': serializer.toJson<bool>(isEnabled),
    };
  }

  DoseScheduleTime copyWith({
    int? id,
    String? medicationId,
    int? timeHour,
    int? timeMinute,
    int? daysOfWeekBitmask,
    DateTime? startDate,
    Value<DateTime?> endDate = const Value.absent(),
    Value<String?> timezone = const Value.absent(),
    bool? isEnabled,
  }) => DoseScheduleTime(
    id: id ?? this.id,
    medicationId: medicationId ?? this.medicationId,
    timeHour: timeHour ?? this.timeHour,
    timeMinute: timeMinute ?? this.timeMinute,
    daysOfWeekBitmask: daysOfWeekBitmask ?? this.daysOfWeekBitmask,
    startDate: startDate ?? this.startDate,
    endDate: endDate.present ? endDate.value : this.endDate,
    timezone: timezone.present ? timezone.value : this.timezone,
    isEnabled: isEnabled ?? this.isEnabled,
  );
  DoseScheduleTime copyWithCompanion(DoseScheduleTimesCompanion data) {
    return DoseScheduleTime(
      id: data.id.present ? data.id.value : this.id,
      medicationId: data.medicationId.present
          ? data.medicationId.value
          : this.medicationId,
      timeHour: data.timeHour.present ? data.timeHour.value : this.timeHour,
      timeMinute: data.timeMinute.present
          ? data.timeMinute.value
          : this.timeMinute,
      daysOfWeekBitmask: data.daysOfWeekBitmask.present
          ? data.daysOfWeekBitmask.value
          : this.daysOfWeekBitmask,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      timezone: data.timezone.present ? data.timezone.value : this.timezone,
      isEnabled: data.isEnabled.present ? data.isEnabled.value : this.isEnabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DoseScheduleTime(')
          ..write('id: $id, ')
          ..write('medicationId: $medicationId, ')
          ..write('timeHour: $timeHour, ')
          ..write('timeMinute: $timeMinute, ')
          ..write('daysOfWeekBitmask: $daysOfWeekBitmask, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('timezone: $timezone, ')
          ..write('isEnabled: $isEnabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    medicationId,
    timeHour,
    timeMinute,
    daysOfWeekBitmask,
    startDate,
    endDate,
    timezone,
    isEnabled,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DoseScheduleTime &&
          other.id == this.id &&
          other.medicationId == this.medicationId &&
          other.timeHour == this.timeHour &&
          other.timeMinute == this.timeMinute &&
          other.daysOfWeekBitmask == this.daysOfWeekBitmask &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.timezone == this.timezone &&
          other.isEnabled == this.isEnabled);
}

class DoseScheduleTimesCompanion extends UpdateCompanion<DoseScheduleTime> {
  final Value<int> id;
  final Value<String> medicationId;
  final Value<int> timeHour;
  final Value<int> timeMinute;
  final Value<int> daysOfWeekBitmask;
  final Value<DateTime> startDate;
  final Value<DateTime?> endDate;
  final Value<String?> timezone;
  final Value<bool> isEnabled;
  const DoseScheduleTimesCompanion({
    this.id = const Value.absent(),
    this.medicationId = const Value.absent(),
    this.timeHour = const Value.absent(),
    this.timeMinute = const Value.absent(),
    this.daysOfWeekBitmask = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.timezone = const Value.absent(),
    this.isEnabled = const Value.absent(),
  });
  DoseScheduleTimesCompanion.insert({
    this.id = const Value.absent(),
    required String medicationId,
    required int timeHour,
    required int timeMinute,
    this.daysOfWeekBitmask = const Value.absent(),
    required DateTime startDate,
    this.endDate = const Value.absent(),
    this.timezone = const Value.absent(),
    this.isEnabled = const Value.absent(),
  }) : medicationId = Value(medicationId),
       timeHour = Value(timeHour),
       timeMinute = Value(timeMinute),
       startDate = Value(startDate);
  static Insertable<DoseScheduleTime> custom({
    Expression<int>? id,
    Expression<String>? medicationId,
    Expression<int>? timeHour,
    Expression<int>? timeMinute,
    Expression<int>? daysOfWeekBitmask,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<String>? timezone,
    Expression<bool>? isEnabled,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (medicationId != null) 'medication_id': medicationId,
      if (timeHour != null) 'time_hour': timeHour,
      if (timeMinute != null) 'time_minute': timeMinute,
      if (daysOfWeekBitmask != null) 'days_of_week_bitmask': daysOfWeekBitmask,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (timezone != null) 'timezone': timezone,
      if (isEnabled != null) 'is_enabled': isEnabled,
    });
  }

  DoseScheduleTimesCompanion copyWith({
    Value<int>? id,
    Value<String>? medicationId,
    Value<int>? timeHour,
    Value<int>? timeMinute,
    Value<int>? daysOfWeekBitmask,
    Value<DateTime>? startDate,
    Value<DateTime?>? endDate,
    Value<String?>? timezone,
    Value<bool>? isEnabled,
  }) {
    return DoseScheduleTimesCompanion(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      timeHour: timeHour ?? this.timeHour,
      timeMinute: timeMinute ?? this.timeMinute,
      daysOfWeekBitmask: daysOfWeekBitmask ?? this.daysOfWeekBitmask,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      timezone: timezone ?? this.timezone,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (medicationId.present) {
      map['medication_id'] = Variable<String>(medicationId.value);
    }
    if (timeHour.present) {
      map['time_hour'] = Variable<int>(timeHour.value);
    }
    if (timeMinute.present) {
      map['time_minute'] = Variable<int>(timeMinute.value);
    }
    if (daysOfWeekBitmask.present) {
      map['days_of_week_bitmask'] = Variable<int>(daysOfWeekBitmask.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (timezone.present) {
      map['timezone'] = Variable<String>(timezone.value);
    }
    if (isEnabled.present) {
      map['is_enabled'] = Variable<bool>(isEnabled.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DoseScheduleTimesCompanion(')
          ..write('id: $id, ')
          ..write('medicationId: $medicationId, ')
          ..write('timeHour: $timeHour, ')
          ..write('timeMinute: $timeMinute, ')
          ..write('daysOfWeekBitmask: $daysOfWeekBitmask, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('timezone: $timezone, ')
          ..write('isEnabled: $isEnabled')
          ..write(')'))
        .toString();
  }
}

class $DoseEventsTable extends DoseEvents
    with TableInfo<$DoseEventsTable, DoseEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DoseEventsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _medicationIdMeta = const VerificationMeta(
    'medicationId',
  );
  @override
  late final GeneratedColumn<String> medicationId = GeneratedColumn<String>(
    'medication_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES medications (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _doseScheduleTimeIdMeta =
      const VerificationMeta('doseScheduleTimeId');
  @override
  late final GeneratedColumn<int> doseScheduleTimeId = GeneratedColumn<int>(
    'dose_schedule_time_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES dose_schedule_times (id)',
    ),
  );
  static const VerificationMeta _scheduledAtMeta = const VerificationMeta(
    'scheduledAt',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledAt = GeneratedColumn<DateTime>(
    'scheduled_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _takenAtMeta = const VerificationMeta(
    'takenAt',
  );
  @override
  late final GeneratedColumn<DateTime> takenAt = GeneratedColumn<DateTime>(
    'taken_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<int> source = GeneratedColumn<int>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    medicationId,
    doseScheduleTimeId,
    scheduledAt,
    takenAt,
    status,
    source,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dose_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<DoseEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('medication_id')) {
      context.handle(
        _medicationIdMeta,
        medicationId.isAcceptableOrUnknown(
          data['medication_id']!,
          _medicationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_medicationIdMeta);
    }
    if (data.containsKey('dose_schedule_time_id')) {
      context.handle(
        _doseScheduleTimeIdMeta,
        doseScheduleTimeId.isAcceptableOrUnknown(
          data['dose_schedule_time_id']!,
          _doseScheduleTimeIdMeta,
        ),
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
    } else if (isInserting) {
      context.missing(_scheduledAtMeta);
    }
    if (data.containsKey('taken_at')) {
      context.handle(
        _takenAtMeta,
        takenAt.isAcceptableOrUnknown(data['taken_at']!, _takenAtMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DoseEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DoseEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      medicationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medication_id'],
      )!,
      doseScheduleTimeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dose_schedule_time_id'],
      ),
      scheduledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_at'],
      )!,
      takenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}taken_at'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source'],
      )!,
    );
  }

  @override
  $DoseEventsTable createAlias(String alias) {
    return $DoseEventsTable(attachedDatabase, alias);
  }
}

class DoseEvent extends DataClass implements Insertable<DoseEvent> {
  final int id;
  final String medicationId;

  /// Links a taken/missed/skipped event to the specific schedule time.
  /// Nullable so we can backfill if needed.
  final int? doseScheduleTimeId;

  /// Concrete occurrence datetime for this scheduled dose (UTC epoch storage).
  final DateTime scheduledAt;

  /// When marked taken. Null for missed/skipped/scheduled states.
  final DateTime? takenAt;

  /// 0=scheduled, 1=taken, 2=missed, 3=skipped
  final int status;

  /// 0=notification, 1=manual
  final int source;
  const DoseEvent({
    required this.id,
    required this.medicationId,
    this.doseScheduleTimeId,
    required this.scheduledAt,
    this.takenAt,
    required this.status,
    required this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['medication_id'] = Variable<String>(medicationId);
    if (!nullToAbsent || doseScheduleTimeId != null) {
      map['dose_schedule_time_id'] = Variable<int>(doseScheduleTimeId);
    }
    map['scheduled_at'] = Variable<DateTime>(scheduledAt);
    if (!nullToAbsent || takenAt != null) {
      map['taken_at'] = Variable<DateTime>(takenAt);
    }
    map['status'] = Variable<int>(status);
    map['source'] = Variable<int>(source);
    return map;
  }

  DoseEventsCompanion toCompanion(bool nullToAbsent) {
    return DoseEventsCompanion(
      id: Value(id),
      medicationId: Value(medicationId),
      doseScheduleTimeId: doseScheduleTimeId == null && nullToAbsent
          ? const Value.absent()
          : Value(doseScheduleTimeId),
      scheduledAt: Value(scheduledAt),
      takenAt: takenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(takenAt),
      status: Value(status),
      source: Value(source),
    );
  }

  factory DoseEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DoseEvent(
      id: serializer.fromJson<int>(json['id']),
      medicationId: serializer.fromJson<String>(json['medicationId']),
      doseScheduleTimeId: serializer.fromJson<int?>(json['doseScheduleTimeId']),
      scheduledAt: serializer.fromJson<DateTime>(json['scheduledAt']),
      takenAt: serializer.fromJson<DateTime?>(json['takenAt']),
      status: serializer.fromJson<int>(json['status']),
      source: serializer.fromJson<int>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'medicationId': serializer.toJson<String>(medicationId),
      'doseScheduleTimeId': serializer.toJson<int?>(doseScheduleTimeId),
      'scheduledAt': serializer.toJson<DateTime>(scheduledAt),
      'takenAt': serializer.toJson<DateTime?>(takenAt),
      'status': serializer.toJson<int>(status),
      'source': serializer.toJson<int>(source),
    };
  }

  DoseEvent copyWith({
    int? id,
    String? medicationId,
    Value<int?> doseScheduleTimeId = const Value.absent(),
    DateTime? scheduledAt,
    Value<DateTime?> takenAt = const Value.absent(),
    int? status,
    int? source,
  }) => DoseEvent(
    id: id ?? this.id,
    medicationId: medicationId ?? this.medicationId,
    doseScheduleTimeId: doseScheduleTimeId.present
        ? doseScheduleTimeId.value
        : this.doseScheduleTimeId,
    scheduledAt: scheduledAt ?? this.scheduledAt,
    takenAt: takenAt.present ? takenAt.value : this.takenAt,
    status: status ?? this.status,
    source: source ?? this.source,
  );
  DoseEvent copyWithCompanion(DoseEventsCompanion data) {
    return DoseEvent(
      id: data.id.present ? data.id.value : this.id,
      medicationId: data.medicationId.present
          ? data.medicationId.value
          : this.medicationId,
      doseScheduleTimeId: data.doseScheduleTimeId.present
          ? data.doseScheduleTimeId.value
          : this.doseScheduleTimeId,
      scheduledAt: data.scheduledAt.present
          ? data.scheduledAt.value
          : this.scheduledAt,
      takenAt: data.takenAt.present ? data.takenAt.value : this.takenAt,
      status: data.status.present ? data.status.value : this.status,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DoseEvent(')
          ..write('id: $id, ')
          ..write('medicationId: $medicationId, ')
          ..write('doseScheduleTimeId: $doseScheduleTimeId, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('takenAt: $takenAt, ')
          ..write('status: $status, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    medicationId,
    doseScheduleTimeId,
    scheduledAt,
    takenAt,
    status,
    source,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DoseEvent &&
          other.id == this.id &&
          other.medicationId == this.medicationId &&
          other.doseScheduleTimeId == this.doseScheduleTimeId &&
          other.scheduledAt == this.scheduledAt &&
          other.takenAt == this.takenAt &&
          other.status == this.status &&
          other.source == this.source);
}

class DoseEventsCompanion extends UpdateCompanion<DoseEvent> {
  final Value<int> id;
  final Value<String> medicationId;
  final Value<int?> doseScheduleTimeId;
  final Value<DateTime> scheduledAt;
  final Value<DateTime?> takenAt;
  final Value<int> status;
  final Value<int> source;
  const DoseEventsCompanion({
    this.id = const Value.absent(),
    this.medicationId = const Value.absent(),
    this.doseScheduleTimeId = const Value.absent(),
    this.scheduledAt = const Value.absent(),
    this.takenAt = const Value.absent(),
    this.status = const Value.absent(),
    this.source = const Value.absent(),
  });
  DoseEventsCompanion.insert({
    this.id = const Value.absent(),
    required String medicationId,
    this.doseScheduleTimeId = const Value.absent(),
    required DateTime scheduledAt,
    this.takenAt = const Value.absent(),
    this.status = const Value.absent(),
    this.source = const Value.absent(),
  }) : medicationId = Value(medicationId),
       scheduledAt = Value(scheduledAt);
  static Insertable<DoseEvent> custom({
    Expression<int>? id,
    Expression<String>? medicationId,
    Expression<int>? doseScheduleTimeId,
    Expression<DateTime>? scheduledAt,
    Expression<DateTime>? takenAt,
    Expression<int>? status,
    Expression<int>? source,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (medicationId != null) 'medication_id': medicationId,
      if (doseScheduleTimeId != null)
        'dose_schedule_time_id': doseScheduleTimeId,
      if (scheduledAt != null) 'scheduled_at': scheduledAt,
      if (takenAt != null) 'taken_at': takenAt,
      if (status != null) 'status': status,
      if (source != null) 'source': source,
    });
  }

  DoseEventsCompanion copyWith({
    Value<int>? id,
    Value<String>? medicationId,
    Value<int?>? doseScheduleTimeId,
    Value<DateTime>? scheduledAt,
    Value<DateTime?>? takenAt,
    Value<int>? status,
    Value<int>? source,
  }) {
    return DoseEventsCompanion(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      doseScheduleTimeId: doseScheduleTimeId ?? this.doseScheduleTimeId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      takenAt: takenAt ?? this.takenAt,
      status: status ?? this.status,
      source: source ?? this.source,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (medicationId.present) {
      map['medication_id'] = Variable<String>(medicationId.value);
    }
    if (doseScheduleTimeId.present) {
      map['dose_schedule_time_id'] = Variable<int>(doseScheduleTimeId.value);
    }
    if (scheduledAt.present) {
      map['scheduled_at'] = Variable<DateTime>(scheduledAt.value);
    }
    if (takenAt.present) {
      map['taken_at'] = Variable<DateTime>(takenAt.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (source.present) {
      map['source'] = Variable<int>(source.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DoseEventsCompanion(')
          ..write('id: $id, ')
          ..write('medicationId: $medicationId, ')
          ..write('doseScheduleTimeId: $doseScheduleTimeId, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('takenAt: $takenAt, ')
          ..write('status: $status, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }
}

class $UserSettingsTable extends UserSettings
    with TableInfo<$UserSettingsTable, UserSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _doseGraceMinutesMeta = const VerificationMeta(
    'doseGraceMinutes',
  );
  @override
  late final GeneratedColumn<int> doseGraceMinutes = GeneratedColumn<int>(
    'dose_grace_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(120),
  );
  static const VerificationMeta _lowPillWarningDaysMeta =
      const VerificationMeta('lowPillWarningDays');
  @override
  late final GeneratedColumn<int> lowPillWarningDays = GeneratedColumn<int>(
    'low_pill_warning_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(3),
  );
  static const VerificationMeta _lastTimezoneMeta = const VerificationMeta(
    'lastTimezone',
  );
  @override
  late final GeneratedColumn<String> lastTimezone = GeneratedColumn<String>(
    'last_timezone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    doseGraceMinutes,
    lowPillWarningDays,
    lastTimezone,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('dose_grace_minutes')) {
      context.handle(
        _doseGraceMinutesMeta,
        doseGraceMinutes.isAcceptableOrUnknown(
          data['dose_grace_minutes']!,
          _doseGraceMinutesMeta,
        ),
      );
    }
    if (data.containsKey('low_pill_warning_days')) {
      context.handle(
        _lowPillWarningDaysMeta,
        lowPillWarningDays.isAcceptableOrUnknown(
          data['low_pill_warning_days']!,
          _lowPillWarningDaysMeta,
        ),
      );
    }
    if (data.containsKey('last_timezone')) {
      context.handle(
        _lastTimezoneMeta,
        lastTimezone.isAcceptableOrUnknown(
          data['last_timezone']!,
          _lastTimezoneMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      doseGraceMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dose_grace_minutes'],
      )!,
      lowPillWarningDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}low_pill_warning_days'],
      )!,
      lastTimezone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_timezone'],
      ),
    );
  }

  @override
  $UserSettingsTable createAlias(String alias) {
    return $UserSettingsTable(attachedDatabase, alias);
  }
}

class UserSetting extends DataClass implements Insertable<UserSetting> {
  /// Singleton row: we store `id=1`.
  final int id;

  /// Minutes after scheduledAt after which we consider a dose "missed".
  final int doseGraceMinutes;

  /// Low-pill warning lead time in days.
  final int lowPillWarningDays;

  /// Used to detect timezone changes after restarts.
  final String? lastTimezone;
  const UserSetting({
    required this.id,
    required this.doseGraceMinutes,
    required this.lowPillWarningDays,
    this.lastTimezone,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['dose_grace_minutes'] = Variable<int>(doseGraceMinutes);
    map['low_pill_warning_days'] = Variable<int>(lowPillWarningDays);
    if (!nullToAbsent || lastTimezone != null) {
      map['last_timezone'] = Variable<String>(lastTimezone);
    }
    return map;
  }

  UserSettingsCompanion toCompanion(bool nullToAbsent) {
    return UserSettingsCompanion(
      id: Value(id),
      doseGraceMinutes: Value(doseGraceMinutes),
      lowPillWarningDays: Value(lowPillWarningDays),
      lastTimezone: lastTimezone == null && nullToAbsent
          ? const Value.absent()
          : Value(lastTimezone),
    );
  }

  factory UserSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserSetting(
      id: serializer.fromJson<int>(json['id']),
      doseGraceMinutes: serializer.fromJson<int>(json['doseGraceMinutes']),
      lowPillWarningDays: serializer.fromJson<int>(json['lowPillWarningDays']),
      lastTimezone: serializer.fromJson<String?>(json['lastTimezone']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'doseGraceMinutes': serializer.toJson<int>(doseGraceMinutes),
      'lowPillWarningDays': serializer.toJson<int>(lowPillWarningDays),
      'lastTimezone': serializer.toJson<String?>(lastTimezone),
    };
  }

  UserSetting copyWith({
    int? id,
    int? doseGraceMinutes,
    int? lowPillWarningDays,
    Value<String?> lastTimezone = const Value.absent(),
  }) => UserSetting(
    id: id ?? this.id,
    doseGraceMinutes: doseGraceMinutes ?? this.doseGraceMinutes,
    lowPillWarningDays: lowPillWarningDays ?? this.lowPillWarningDays,
    lastTimezone: lastTimezone.present ? lastTimezone.value : this.lastTimezone,
  );
  UserSetting copyWithCompanion(UserSettingsCompanion data) {
    return UserSetting(
      id: data.id.present ? data.id.value : this.id,
      doseGraceMinutes: data.doseGraceMinutes.present
          ? data.doseGraceMinutes.value
          : this.doseGraceMinutes,
      lowPillWarningDays: data.lowPillWarningDays.present
          ? data.lowPillWarningDays.value
          : this.lowPillWarningDays,
      lastTimezone: data.lastTimezone.present
          ? data.lastTimezone.value
          : this.lastTimezone,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserSetting(')
          ..write('id: $id, ')
          ..write('doseGraceMinutes: $doseGraceMinutes, ')
          ..write('lowPillWarningDays: $lowPillWarningDays, ')
          ..write('lastTimezone: $lastTimezone')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, doseGraceMinutes, lowPillWarningDays, lastTimezone);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserSetting &&
          other.id == this.id &&
          other.doseGraceMinutes == this.doseGraceMinutes &&
          other.lowPillWarningDays == this.lowPillWarningDays &&
          other.lastTimezone == this.lastTimezone);
}

class UserSettingsCompanion extends UpdateCompanion<UserSetting> {
  final Value<int> id;
  final Value<int> doseGraceMinutes;
  final Value<int> lowPillWarningDays;
  final Value<String?> lastTimezone;
  const UserSettingsCompanion({
    this.id = const Value.absent(),
    this.doseGraceMinutes = const Value.absent(),
    this.lowPillWarningDays = const Value.absent(),
    this.lastTimezone = const Value.absent(),
  });
  UserSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.doseGraceMinutes = const Value.absent(),
    this.lowPillWarningDays = const Value.absent(),
    this.lastTimezone = const Value.absent(),
  });
  static Insertable<UserSetting> custom({
    Expression<int>? id,
    Expression<int>? doseGraceMinutes,
    Expression<int>? lowPillWarningDays,
    Expression<String>? lastTimezone,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (doseGraceMinutes != null) 'dose_grace_minutes': doseGraceMinutes,
      if (lowPillWarningDays != null)
        'low_pill_warning_days': lowPillWarningDays,
      if (lastTimezone != null) 'last_timezone': lastTimezone,
    });
  }

  UserSettingsCompanion copyWith({
    Value<int>? id,
    Value<int>? doseGraceMinutes,
    Value<int>? lowPillWarningDays,
    Value<String?>? lastTimezone,
  }) {
    return UserSettingsCompanion(
      id: id ?? this.id,
      doseGraceMinutes: doseGraceMinutes ?? this.doseGraceMinutes,
      lowPillWarningDays: lowPillWarningDays ?? this.lowPillWarningDays,
      lastTimezone: lastTimezone ?? this.lastTimezone,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (doseGraceMinutes.present) {
      map['dose_grace_minutes'] = Variable<int>(doseGraceMinutes.value);
    }
    if (lowPillWarningDays.present) {
      map['low_pill_warning_days'] = Variable<int>(lowPillWarningDays.value);
    }
    if (lastTimezone.present) {
      map['last_timezone'] = Variable<String>(lastTimezone.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserSettingsCompanion(')
          ..write('id: $id, ')
          ..write('doseGraceMinutes: $doseGraceMinutes, ')
          ..write('lowPillWarningDays: $lowPillWarningDays, ')
          ..write('lastTimezone: $lastTimezone')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MedicationsTable medications = $MedicationsTable(this);
  late final $DoseScheduleTimesTable doseScheduleTimes =
      $DoseScheduleTimesTable(this);
  late final $DoseEventsTable doseEvents = $DoseEventsTable(this);
  late final $UserSettingsTable userSettings = $UserSettingsTable(this);
  late final Index uniqueDoseEventPerMedAndTime = Index(
    'unique_dose_event_per_med_and_time',
    'CREATE UNIQUE INDEX unique_dose_event_per_med_and_time ON dose_events (medication_id, scheduled_at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    medications,
    doseScheduleTimes,
    doseEvents,
    userSettings,
    uniqueDoseEventPerMedAndTime,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'medications',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('dose_schedule_times', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'medications',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('dose_events', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$MedicationsTableCreateCompanionBuilder =
    MedicationsCompanion Function({
      required String id,
      required String name,
      Value<String?> strength,
      Value<String?> form,
      required int totalPills,
      required int pillPerDose,
      required int refillThreshold,
      Value<String?> notes,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$MedicationsTableUpdateCompanionBuilder =
    MedicationsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> strength,
      Value<String?> form,
      Value<int> totalPills,
      Value<int> pillPerDose,
      Value<int> refillThreshold,
      Value<String?> notes,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$MedicationsTableReferences
    extends BaseReferences<_$AppDatabase, $MedicationsTable, Medication> {
  $$MedicationsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$DoseScheduleTimesTable, List<DoseScheduleTime>>
  _doseScheduleTimesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.doseScheduleTimes,
        aliasName: $_aliasNameGenerator(
          db.medications.id,
          db.doseScheduleTimes.medicationId,
        ),
      );

  $$DoseScheduleTimesTableProcessedTableManager get doseScheduleTimesRefs {
    final manager = $$DoseScheduleTimesTableTableManager(
      $_db,
      $_db.doseScheduleTimes,
    ).filter((f) => f.medicationId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _doseScheduleTimesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DoseEventsTable, List<DoseEvent>>
  _doseEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.doseEvents,
    aliasName: $_aliasNameGenerator(
      db.medications.id,
      db.doseEvents.medicationId,
    ),
  );

  $$DoseEventsTableProcessedTableManager get doseEventsRefs {
    final manager = $$DoseEventsTableTableManager(
      $_db,
      $_db.doseEvents,
    ).filter((f) => f.medicationId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_doseEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MedicationsTableFilterComposer
    extends Composer<_$AppDatabase, $MedicationsTable> {
  $$MedicationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get strength => $composableBuilder(
    column: $table.strength,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get form => $composableBuilder(
    column: $table.form,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalPills => $composableBuilder(
    column: $table.totalPills,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pillPerDose => $composableBuilder(
    column: $table.pillPerDose,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get refillThreshold => $composableBuilder(
    column: $table.refillThreshold,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> doseScheduleTimesRefs(
    Expression<bool> Function($$DoseScheduleTimesTableFilterComposer f) f,
  ) {
    final $$DoseScheduleTimesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.doseScheduleTimes,
      getReferencedColumn: (t) => t.medicationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DoseScheduleTimesTableFilterComposer(
            $db: $db,
            $table: $db.doseScheduleTimes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> doseEventsRefs(
    Expression<bool> Function($$DoseEventsTableFilterComposer f) f,
  ) {
    final $$DoseEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.doseEvents,
      getReferencedColumn: (t) => t.medicationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DoseEventsTableFilterComposer(
            $db: $db,
            $table: $db.doseEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MedicationsTableOrderingComposer
    extends Composer<_$AppDatabase, $MedicationsTable> {
  $$MedicationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get strength => $composableBuilder(
    column: $table.strength,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get form => $composableBuilder(
    column: $table.form,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalPills => $composableBuilder(
    column: $table.totalPills,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pillPerDose => $composableBuilder(
    column: $table.pillPerDose,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get refillThreshold => $composableBuilder(
    column: $table.refillThreshold,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MedicationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MedicationsTable> {
  $$MedicationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get strength =>
      $composableBuilder(column: $table.strength, builder: (column) => column);

  GeneratedColumn<String> get form =>
      $composableBuilder(column: $table.form, builder: (column) => column);

  GeneratedColumn<int> get totalPills => $composableBuilder(
    column: $table.totalPills,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pillPerDose => $composableBuilder(
    column: $table.pillPerDose,
    builder: (column) => column,
  );

  GeneratedColumn<int> get refillThreshold => $composableBuilder(
    column: $table.refillThreshold,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> doseScheduleTimesRefs<T extends Object>(
    Expression<T> Function($$DoseScheduleTimesTableAnnotationComposer a) f,
  ) {
    final $$DoseScheduleTimesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.doseScheduleTimes,
          getReferencedColumn: (t) => t.medicationId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DoseScheduleTimesTableAnnotationComposer(
                $db: $db,
                $table: $db.doseScheduleTimes,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> doseEventsRefs<T extends Object>(
    Expression<T> Function($$DoseEventsTableAnnotationComposer a) f,
  ) {
    final $$DoseEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.doseEvents,
      getReferencedColumn: (t) => t.medicationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DoseEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.doseEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MedicationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MedicationsTable,
          Medication,
          $$MedicationsTableFilterComposer,
          $$MedicationsTableOrderingComposer,
          $$MedicationsTableAnnotationComposer,
          $$MedicationsTableCreateCompanionBuilder,
          $$MedicationsTableUpdateCompanionBuilder,
          (Medication, $$MedicationsTableReferences),
          Medication,
          PrefetchHooks Function({
            bool doseScheduleTimesRefs,
            bool doseEventsRefs,
          })
        > {
  $$MedicationsTableTableManager(_$AppDatabase db, $MedicationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MedicationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MedicationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MedicationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> strength = const Value.absent(),
                Value<String?> form = const Value.absent(),
                Value<int> totalPills = const Value.absent(),
                Value<int> pillPerDose = const Value.absent(),
                Value<int> refillThreshold = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MedicationsCompanion(
                id: id,
                name: name,
                strength: strength,
                form: form,
                totalPills: totalPills,
                pillPerDose: pillPerDose,
                refillThreshold: refillThreshold,
                notes: notes,
                isActive: isActive,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> strength = const Value.absent(),
                Value<String?> form = const Value.absent(),
                required int totalPills,
                required int pillPerDose,
                required int refillThreshold,
                Value<String?> notes = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MedicationsCompanion.insert(
                id: id,
                name: name,
                strength: strength,
                form: form,
                totalPills: totalPills,
                pillPerDose: pillPerDose,
                refillThreshold: refillThreshold,
                notes: notes,
                isActive: isActive,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MedicationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({doseScheduleTimesRefs = false, doseEventsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (doseScheduleTimesRefs) db.doseScheduleTimes,
                    if (doseEventsRefs) db.doseEvents,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (doseScheduleTimesRefs)
                        await $_getPrefetchedData<
                          Medication,
                          $MedicationsTable,
                          DoseScheduleTime
                        >(
                          currentTable: table,
                          referencedTable: $$MedicationsTableReferences
                              ._doseScheduleTimesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MedicationsTableReferences(
                                db,
                                table,
                                p0,
                              ).doseScheduleTimesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.medicationId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (doseEventsRefs)
                        await $_getPrefetchedData<
                          Medication,
                          $MedicationsTable,
                          DoseEvent
                        >(
                          currentTable: table,
                          referencedTable: $$MedicationsTableReferences
                              ._doseEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MedicationsTableReferences(
                                db,
                                table,
                                p0,
                              ).doseEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.medicationId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$MedicationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MedicationsTable,
      Medication,
      $$MedicationsTableFilterComposer,
      $$MedicationsTableOrderingComposer,
      $$MedicationsTableAnnotationComposer,
      $$MedicationsTableCreateCompanionBuilder,
      $$MedicationsTableUpdateCompanionBuilder,
      (Medication, $$MedicationsTableReferences),
      Medication,
      PrefetchHooks Function({bool doseScheduleTimesRefs, bool doseEventsRefs})
    >;
typedef $$DoseScheduleTimesTableCreateCompanionBuilder =
    DoseScheduleTimesCompanion Function({
      Value<int> id,
      required String medicationId,
      required int timeHour,
      required int timeMinute,
      Value<int> daysOfWeekBitmask,
      required DateTime startDate,
      Value<DateTime?> endDate,
      Value<String?> timezone,
      Value<bool> isEnabled,
    });
typedef $$DoseScheduleTimesTableUpdateCompanionBuilder =
    DoseScheduleTimesCompanion Function({
      Value<int> id,
      Value<String> medicationId,
      Value<int> timeHour,
      Value<int> timeMinute,
      Value<int> daysOfWeekBitmask,
      Value<DateTime> startDate,
      Value<DateTime?> endDate,
      Value<String?> timezone,
      Value<bool> isEnabled,
    });

final class $$DoseScheduleTimesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $DoseScheduleTimesTable,
          DoseScheduleTime
        > {
  $$DoseScheduleTimesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $MedicationsTable _medicationIdTable(_$AppDatabase db) =>
      db.medications.createAlias(
        $_aliasNameGenerator(
          db.doseScheduleTimes.medicationId,
          db.medications.id,
        ),
      );

  $$MedicationsTableProcessedTableManager get medicationId {
    final $_column = $_itemColumn<String>('medication_id')!;

    final manager = $$MedicationsTableTableManager(
      $_db,
      $_db.medications,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_medicationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$DoseEventsTable, List<DoseEvent>>
  _doseEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.doseEvents,
    aliasName: $_aliasNameGenerator(
      db.doseScheduleTimes.id,
      db.doseEvents.doseScheduleTimeId,
    ),
  );

  $$DoseEventsTableProcessedTableManager get doseEventsRefs {
    final manager = $$DoseEventsTableTableManager($_db, $_db.doseEvents).filter(
      (f) => f.doseScheduleTimeId.id.sqlEquals($_itemColumn<int>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_doseEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DoseScheduleTimesTableFilterComposer
    extends Composer<_$AppDatabase, $DoseScheduleTimesTable> {
  $$DoseScheduleTimesTableFilterComposer({
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

  ColumnFilters<int> get timeHour => $composableBuilder(
    column: $table.timeHour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeMinute => $composableBuilder(
    column: $table.timeMinute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get daysOfWeekBitmask => $composableBuilder(
    column: $table.daysOfWeekBitmask,
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

  ColumnFilters<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnFilters(column),
  );

  $$MedicationsTableFilterComposer get medicationId {
    final $$MedicationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.medicationId,
      referencedTable: $db.medications,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationsTableFilterComposer(
            $db: $db,
            $table: $db.medications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> doseEventsRefs(
    Expression<bool> Function($$DoseEventsTableFilterComposer f) f,
  ) {
    final $$DoseEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.doseEvents,
      getReferencedColumn: (t) => t.doseScheduleTimeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DoseEventsTableFilterComposer(
            $db: $db,
            $table: $db.doseEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DoseScheduleTimesTableOrderingComposer
    extends Composer<_$AppDatabase, $DoseScheduleTimesTable> {
  $$DoseScheduleTimesTableOrderingComposer({
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

  ColumnOrderings<int> get timeHour => $composableBuilder(
    column: $table.timeHour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeMinute => $composableBuilder(
    column: $table.timeMinute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get daysOfWeekBitmask => $composableBuilder(
    column: $table.daysOfWeekBitmask,
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

  ColumnOrderings<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  $$MedicationsTableOrderingComposer get medicationId {
    final $$MedicationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.medicationId,
      referencedTable: $db.medications,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationsTableOrderingComposer(
            $db: $db,
            $table: $db.medications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DoseScheduleTimesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DoseScheduleTimesTable> {
  $$DoseScheduleTimesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get timeHour =>
      $composableBuilder(column: $table.timeHour, builder: (column) => column);

  GeneratedColumn<int> get timeMinute => $composableBuilder(
    column: $table.timeMinute,
    builder: (column) => column,
  );

  GeneratedColumn<int> get daysOfWeekBitmask => $composableBuilder(
    column: $table.daysOfWeekBitmask,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get timezone =>
      $composableBuilder(column: $table.timezone, builder: (column) => column);

  GeneratedColumn<bool> get isEnabled =>
      $composableBuilder(column: $table.isEnabled, builder: (column) => column);

  $$MedicationsTableAnnotationComposer get medicationId {
    final $$MedicationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.medicationId,
      referencedTable: $db.medications,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationsTableAnnotationComposer(
            $db: $db,
            $table: $db.medications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> doseEventsRefs<T extends Object>(
    Expression<T> Function($$DoseEventsTableAnnotationComposer a) f,
  ) {
    final $$DoseEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.doseEvents,
      getReferencedColumn: (t) => t.doseScheduleTimeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DoseEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.doseEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DoseScheduleTimesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DoseScheduleTimesTable,
          DoseScheduleTime,
          $$DoseScheduleTimesTableFilterComposer,
          $$DoseScheduleTimesTableOrderingComposer,
          $$DoseScheduleTimesTableAnnotationComposer,
          $$DoseScheduleTimesTableCreateCompanionBuilder,
          $$DoseScheduleTimesTableUpdateCompanionBuilder,
          (DoseScheduleTime, $$DoseScheduleTimesTableReferences),
          DoseScheduleTime,
          PrefetchHooks Function({bool medicationId, bool doseEventsRefs})
        > {
  $$DoseScheduleTimesTableTableManager(
    _$AppDatabase db,
    $DoseScheduleTimesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DoseScheduleTimesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DoseScheduleTimesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DoseScheduleTimesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> medicationId = const Value.absent(),
                Value<int> timeHour = const Value.absent(),
                Value<int> timeMinute = const Value.absent(),
                Value<int> daysOfWeekBitmask = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<DateTime?> endDate = const Value.absent(),
                Value<String?> timezone = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
              }) => DoseScheduleTimesCompanion(
                id: id,
                medicationId: medicationId,
                timeHour: timeHour,
                timeMinute: timeMinute,
                daysOfWeekBitmask: daysOfWeekBitmask,
                startDate: startDate,
                endDate: endDate,
                timezone: timezone,
                isEnabled: isEnabled,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String medicationId,
                required int timeHour,
                required int timeMinute,
                Value<int> daysOfWeekBitmask = const Value.absent(),
                required DateTime startDate,
                Value<DateTime?> endDate = const Value.absent(),
                Value<String?> timezone = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
              }) => DoseScheduleTimesCompanion.insert(
                id: id,
                medicationId: medicationId,
                timeHour: timeHour,
                timeMinute: timeMinute,
                daysOfWeekBitmask: daysOfWeekBitmask,
                startDate: startDate,
                endDate: endDate,
                timezone: timezone,
                isEnabled: isEnabled,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DoseScheduleTimesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({medicationId = false, doseEventsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (doseEventsRefs) db.doseEvents],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (medicationId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.medicationId,
                                    referencedTable:
                                        $$DoseScheduleTimesTableReferences
                                            ._medicationIdTable(db),
                                    referencedColumn:
                                        $$DoseScheduleTimesTableReferences
                                            ._medicationIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (doseEventsRefs)
                        await $_getPrefetchedData<
                          DoseScheduleTime,
                          $DoseScheduleTimesTable,
                          DoseEvent
                        >(
                          currentTable: table,
                          referencedTable: $$DoseScheduleTimesTableReferences
                              ._doseEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DoseScheduleTimesTableReferences(
                                db,
                                table,
                                p0,
                              ).doseEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.doseScheduleTimeId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$DoseScheduleTimesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DoseScheduleTimesTable,
      DoseScheduleTime,
      $$DoseScheduleTimesTableFilterComposer,
      $$DoseScheduleTimesTableOrderingComposer,
      $$DoseScheduleTimesTableAnnotationComposer,
      $$DoseScheduleTimesTableCreateCompanionBuilder,
      $$DoseScheduleTimesTableUpdateCompanionBuilder,
      (DoseScheduleTime, $$DoseScheduleTimesTableReferences),
      DoseScheduleTime,
      PrefetchHooks Function({bool medicationId, bool doseEventsRefs})
    >;
typedef $$DoseEventsTableCreateCompanionBuilder =
    DoseEventsCompanion Function({
      Value<int> id,
      required String medicationId,
      Value<int?> doseScheduleTimeId,
      required DateTime scheduledAt,
      Value<DateTime?> takenAt,
      Value<int> status,
      Value<int> source,
    });
typedef $$DoseEventsTableUpdateCompanionBuilder =
    DoseEventsCompanion Function({
      Value<int> id,
      Value<String> medicationId,
      Value<int?> doseScheduleTimeId,
      Value<DateTime> scheduledAt,
      Value<DateTime?> takenAt,
      Value<int> status,
      Value<int> source,
    });

final class $$DoseEventsTableReferences
    extends BaseReferences<_$AppDatabase, $DoseEventsTable, DoseEvent> {
  $$DoseEventsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MedicationsTable _medicationIdTable(_$AppDatabase db) =>
      db.medications.createAlias(
        $_aliasNameGenerator(db.doseEvents.medicationId, db.medications.id),
      );

  $$MedicationsTableProcessedTableManager get medicationId {
    final $_column = $_itemColumn<String>('medication_id')!;

    final manager = $$MedicationsTableTableManager(
      $_db,
      $_db.medications,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_medicationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $DoseScheduleTimesTable _doseScheduleTimeIdTable(_$AppDatabase db) =>
      db.doseScheduleTimes.createAlias(
        $_aliasNameGenerator(
          db.doseEvents.doseScheduleTimeId,
          db.doseScheduleTimes.id,
        ),
      );

  $$DoseScheduleTimesTableProcessedTableManager? get doseScheduleTimeId {
    final $_column = $_itemColumn<int>('dose_schedule_time_id');
    if ($_column == null) return null;
    final manager = $$DoseScheduleTimesTableTableManager(
      $_db,
      $_db.doseScheduleTimes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_doseScheduleTimeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DoseEventsTableFilterComposer
    extends Composer<_$AppDatabase, $DoseEventsTable> {
  $$DoseEventsTableFilterComposer({
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

  ColumnFilters<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get takenAt => $composableBuilder(
    column: $table.takenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  $$MedicationsTableFilterComposer get medicationId {
    final $$MedicationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.medicationId,
      referencedTable: $db.medications,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationsTableFilterComposer(
            $db: $db,
            $table: $db.medications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DoseScheduleTimesTableFilterComposer get doseScheduleTimeId {
    final $$DoseScheduleTimesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.doseScheduleTimeId,
      referencedTable: $db.doseScheduleTimes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DoseScheduleTimesTableFilterComposer(
            $db: $db,
            $table: $db.doseScheduleTimes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DoseEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $DoseEventsTable> {
  $$DoseEventsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get takenAt => $composableBuilder(
    column: $table.takenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  $$MedicationsTableOrderingComposer get medicationId {
    final $$MedicationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.medicationId,
      referencedTable: $db.medications,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationsTableOrderingComposer(
            $db: $db,
            $table: $db.medications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DoseScheduleTimesTableOrderingComposer get doseScheduleTimeId {
    final $$DoseScheduleTimesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.doseScheduleTimeId,
      referencedTable: $db.doseScheduleTimes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DoseScheduleTimesTableOrderingComposer(
            $db: $db,
            $table: $db.doseScheduleTimes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DoseEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DoseEventsTable> {
  $$DoseEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get takenAt =>
      $composableBuilder(column: $table.takenAt, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  $$MedicationsTableAnnotationComposer get medicationId {
    final $$MedicationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.medicationId,
      referencedTable: $db.medications,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationsTableAnnotationComposer(
            $db: $db,
            $table: $db.medications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DoseScheduleTimesTableAnnotationComposer get doseScheduleTimeId {
    final $$DoseScheduleTimesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.doseScheduleTimeId,
          referencedTable: $db.doseScheduleTimes,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DoseScheduleTimesTableAnnotationComposer(
                $db: $db,
                $table: $db.doseScheduleTimes,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$DoseEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DoseEventsTable,
          DoseEvent,
          $$DoseEventsTableFilterComposer,
          $$DoseEventsTableOrderingComposer,
          $$DoseEventsTableAnnotationComposer,
          $$DoseEventsTableCreateCompanionBuilder,
          $$DoseEventsTableUpdateCompanionBuilder,
          (DoseEvent, $$DoseEventsTableReferences),
          DoseEvent,
          PrefetchHooks Function({bool medicationId, bool doseScheduleTimeId})
        > {
  $$DoseEventsTableTableManager(_$AppDatabase db, $DoseEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DoseEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DoseEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DoseEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> medicationId = const Value.absent(),
                Value<int?> doseScheduleTimeId = const Value.absent(),
                Value<DateTime> scheduledAt = const Value.absent(),
                Value<DateTime?> takenAt = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<int> source = const Value.absent(),
              }) => DoseEventsCompanion(
                id: id,
                medicationId: medicationId,
                doseScheduleTimeId: doseScheduleTimeId,
                scheduledAt: scheduledAt,
                takenAt: takenAt,
                status: status,
                source: source,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String medicationId,
                Value<int?> doseScheduleTimeId = const Value.absent(),
                required DateTime scheduledAt,
                Value<DateTime?> takenAt = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<int> source = const Value.absent(),
              }) => DoseEventsCompanion.insert(
                id: id,
                medicationId: medicationId,
                doseScheduleTimeId: doseScheduleTimeId,
                scheduledAt: scheduledAt,
                takenAt: takenAt,
                status: status,
                source: source,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DoseEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({medicationId = false, doseScheduleTimeId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (medicationId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.medicationId,
                                    referencedTable: $$DoseEventsTableReferences
                                        ._medicationIdTable(db),
                                    referencedColumn:
                                        $$DoseEventsTableReferences
                                            ._medicationIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (doseScheduleTimeId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.doseScheduleTimeId,
                                    referencedTable: $$DoseEventsTableReferences
                                        ._doseScheduleTimeIdTable(db),
                                    referencedColumn:
                                        $$DoseEventsTableReferences
                                            ._doseScheduleTimeIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$DoseEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DoseEventsTable,
      DoseEvent,
      $$DoseEventsTableFilterComposer,
      $$DoseEventsTableOrderingComposer,
      $$DoseEventsTableAnnotationComposer,
      $$DoseEventsTableCreateCompanionBuilder,
      $$DoseEventsTableUpdateCompanionBuilder,
      (DoseEvent, $$DoseEventsTableReferences),
      DoseEvent,
      PrefetchHooks Function({bool medicationId, bool doseScheduleTimeId})
    >;
typedef $$UserSettingsTableCreateCompanionBuilder =
    UserSettingsCompanion Function({
      Value<int> id,
      Value<int> doseGraceMinutes,
      Value<int> lowPillWarningDays,
      Value<String?> lastTimezone,
    });
typedef $$UserSettingsTableUpdateCompanionBuilder =
    UserSettingsCompanion Function({
      Value<int> id,
      Value<int> doseGraceMinutes,
      Value<int> lowPillWarningDays,
      Value<String?> lastTimezone,
    });

class $$UserSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $UserSettingsTable> {
  $$UserSettingsTableFilterComposer({
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

  ColumnFilters<int> get doseGraceMinutes => $composableBuilder(
    column: $table.doseGraceMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lowPillWarningDays => $composableBuilder(
    column: $table.lowPillWarningDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastTimezone => $composableBuilder(
    column: $table.lastTimezone,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $UserSettingsTable> {
  $$UserSettingsTableOrderingComposer({
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

  ColumnOrderings<int> get doseGraceMinutes => $composableBuilder(
    column: $table.doseGraceMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lowPillWarningDays => $composableBuilder(
    column: $table.lowPillWarningDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastTimezone => $composableBuilder(
    column: $table.lastTimezone,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserSettingsTable> {
  $$UserSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get doseGraceMinutes => $composableBuilder(
    column: $table.doseGraceMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lowPillWarningDays => $composableBuilder(
    column: $table.lowPillWarningDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastTimezone => $composableBuilder(
    column: $table.lastTimezone,
    builder: (column) => column,
  );
}

class $$UserSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserSettingsTable,
          UserSetting,
          $$UserSettingsTableFilterComposer,
          $$UserSettingsTableOrderingComposer,
          $$UserSettingsTableAnnotationComposer,
          $$UserSettingsTableCreateCompanionBuilder,
          $$UserSettingsTableUpdateCompanionBuilder,
          (
            UserSetting,
            BaseReferences<_$AppDatabase, $UserSettingsTable, UserSetting>,
          ),
          UserSetting,
          PrefetchHooks Function()
        > {
  $$UserSettingsTableTableManager(_$AppDatabase db, $UserSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> doseGraceMinutes = const Value.absent(),
                Value<int> lowPillWarningDays = const Value.absent(),
                Value<String?> lastTimezone = const Value.absent(),
              }) => UserSettingsCompanion(
                id: id,
                doseGraceMinutes: doseGraceMinutes,
                lowPillWarningDays: lowPillWarningDays,
                lastTimezone: lastTimezone,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> doseGraceMinutes = const Value.absent(),
                Value<int> lowPillWarningDays = const Value.absent(),
                Value<String?> lastTimezone = const Value.absent(),
              }) => UserSettingsCompanion.insert(
                id: id,
                doseGraceMinutes: doseGraceMinutes,
                lowPillWarningDays: lowPillWarningDays,
                lastTimezone: lastTimezone,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserSettingsTable,
      UserSetting,
      $$UserSettingsTableFilterComposer,
      $$UserSettingsTableOrderingComposer,
      $$UserSettingsTableAnnotationComposer,
      $$UserSettingsTableCreateCompanionBuilder,
      $$UserSettingsTableUpdateCompanionBuilder,
      (
        UserSetting,
        BaseReferences<_$AppDatabase, $UserSettingsTable, UserSetting>,
      ),
      UserSetting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MedicationsTableTableManager get medications =>
      $$MedicationsTableTableManager(_db, _db.medications);
  $$DoseScheduleTimesTableTableManager get doseScheduleTimes =>
      $$DoseScheduleTimesTableTableManager(_db, _db.doseScheduleTimes);
  $$DoseEventsTableTableManager get doseEvents =>
      $$DoseEventsTableTableManager(_db, _db.doseEvents);
  $$UserSettingsTableTableManager get userSettings =>
      $$UserSettingsTableTableManager(_db, _db.userSettings);
}

mixin _$MedicationDaoMixin on DatabaseAccessor<AppDatabase> {
  $MedicationsTable get medications => attachedDatabase.medications;
  MedicationDaoManager get managers => MedicationDaoManager(this);
}

class MedicationDaoManager {
  final _$MedicationDaoMixin _db;
  MedicationDaoManager(this._db);
  $$MedicationsTableTableManager get medications =>
      $$MedicationsTableTableManager(_db.attachedDatabase, _db.medications);
}

mixin _$DoseScheduleDaoMixin on DatabaseAccessor<AppDatabase> {
  $MedicationsTable get medications => attachedDatabase.medications;
  $DoseScheduleTimesTable get doseScheduleTimes =>
      attachedDatabase.doseScheduleTimes;
  DoseScheduleDaoManager get managers => DoseScheduleDaoManager(this);
}

class DoseScheduleDaoManager {
  final _$DoseScheduleDaoMixin _db;
  DoseScheduleDaoManager(this._db);
  $$MedicationsTableTableManager get medications =>
      $$MedicationsTableTableManager(_db.attachedDatabase, _db.medications);
  $$DoseScheduleTimesTableTableManager get doseScheduleTimes =>
      $$DoseScheduleTimesTableTableManager(
        _db.attachedDatabase,
        _db.doseScheduleTimes,
      );
}

mixin _$DoseEventDaoMixin on DatabaseAccessor<AppDatabase> {
  $MedicationsTable get medications => attachedDatabase.medications;
  $DoseScheduleTimesTable get doseScheduleTimes =>
      attachedDatabase.doseScheduleTimes;
  $DoseEventsTable get doseEvents => attachedDatabase.doseEvents;
  DoseEventDaoManager get managers => DoseEventDaoManager(this);
}

class DoseEventDaoManager {
  final _$DoseEventDaoMixin _db;
  DoseEventDaoManager(this._db);
  $$MedicationsTableTableManager get medications =>
      $$MedicationsTableTableManager(_db.attachedDatabase, _db.medications);
  $$DoseScheduleTimesTableTableManager get doseScheduleTimes =>
      $$DoseScheduleTimesTableTableManager(
        _db.attachedDatabase,
        _db.doseScheduleTimes,
      );
  $$DoseEventsTableTableManager get doseEvents =>
      $$DoseEventsTableTableManager(_db.attachedDatabase, _db.doseEvents);
}

mixin _$UserSettingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $UserSettingsTable get userSettings => attachedDatabase.userSettings;
  UserSettingsDaoManager get managers => UserSettingsDaoManager(this);
}

class UserSettingsDaoManager {
  final _$UserSettingsDaoMixin _db;
  UserSettingsDaoManager(this._db);
  $$UserSettingsTableTableManager get userSettings =>
      $$UserSettingsTableTableManager(_db.attachedDatabase, _db.userSettings);
}
