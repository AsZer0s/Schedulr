// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SemestersTable extends Semesters
    with TableInfo<$SemestersTable, Semester> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SemestersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _academicYearMeta = const VerificationMeta(
    'academicYear',
  );
  @override
  late final GeneratedColumn<String> academicYear = GeneratedColumn<String>(
    'academic_year',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _termMeta = const VerificationMeta('term');
  @override
  late final GeneratedColumn<String> term = GeneratedColumn<String>(
    'term',
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
  static const VerificationMeta _timetableNameMeta = const VerificationMeta(
    'timetableName',
  );
  @override
  late final GeneratedColumn<String> timetableName = GeneratedColumn<String>(
    'timetable_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('我的课表'),
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
  static const VerificationMeta _teachingWeeksMeta = const VerificationMeta(
    'teachingWeeks',
  );
  @override
  late final GeneratedColumn<int> teachingWeeks = GeneratedColumn<int>(
    'teaching_weeks',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timeZoneMeta = const VerificationMeta(
    'timeZone',
  );
  @override
  late final GeneratedColumn<String> timeZone = GeneratedColumn<String>(
    'time_zone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local'),
  );
  static const VerificationMeta _isCurrentMeta = const VerificationMeta(
    'isCurrent',
  );
  @override
  late final GeneratedColumn<bool> isCurrent = GeneratedColumn<bool>(
    'is_current',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_current" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    academicYear,
    term,
    name,
    timetableName,
    startDate,
    teachingWeeks,
    timeZone,
    isCurrent,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'semesters';
  @override
  VerificationContext validateIntegrity(
    Insertable<Semester> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('academic_year')) {
      context.handle(
        _academicYearMeta,
        academicYear.isAcceptableOrUnknown(
          data['academic_year']!,
          _academicYearMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_academicYearMeta);
    }
    if (data.containsKey('term')) {
      context.handle(
        _termMeta,
        term.isAcceptableOrUnknown(data['term']!, _termMeta),
      );
    } else if (isInserting) {
      context.missing(_termMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('timetable_name')) {
      context.handle(
        _timetableNameMeta,
        timetableName.isAcceptableOrUnknown(
          data['timetable_name']!,
          _timetableNameMeta,
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
    if (data.containsKey('teaching_weeks')) {
      context.handle(
        _teachingWeeksMeta,
        teachingWeeks.isAcceptableOrUnknown(
          data['teaching_weeks']!,
          _teachingWeeksMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_teachingWeeksMeta);
    }
    if (data.containsKey('time_zone')) {
      context.handle(
        _timeZoneMeta,
        timeZone.isAcceptableOrUnknown(data['time_zone']!, _timeZoneMeta),
      );
    }
    if (data.containsKey('is_current')) {
      context.handle(
        _isCurrentMeta,
        isCurrent.isAcceptableOrUnknown(data['is_current']!, _isCurrentMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Semester map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Semester(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      academicYear: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}academic_year'],
      )!,
      term: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}term'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      timetableName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timetable_name'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      )!,
      teachingWeeks: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}teaching_weeks'],
      )!,
      timeZone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_zone'],
      )!,
      isCurrent: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_current'],
      )!,
    );
  }

  @override
  $SemestersTable createAlias(String alias) {
    return $SemestersTable(attachedDatabase, alias);
  }
}

class Semester extends DataClass implements Insertable<Semester> {
  final String id;
  final String academicYear;
  final String term;
  final String name;
  final String timetableName;
  final DateTime startDate;
  final int teachingWeeks;
  final String timeZone;
  final bool isCurrent;
  const Semester({
    required this.id,
    required this.academicYear,
    required this.term,
    required this.name,
    required this.timetableName,
    required this.startDate,
    required this.teachingWeeks,
    required this.timeZone,
    required this.isCurrent,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['academic_year'] = Variable<String>(academicYear);
    map['term'] = Variable<String>(term);
    map['name'] = Variable<String>(name);
    map['timetable_name'] = Variable<String>(timetableName);
    map['start_date'] = Variable<DateTime>(startDate);
    map['teaching_weeks'] = Variable<int>(teachingWeeks);
    map['time_zone'] = Variable<String>(timeZone);
    map['is_current'] = Variable<bool>(isCurrent);
    return map;
  }

  SemestersCompanion toCompanion(bool nullToAbsent) {
    return SemestersCompanion(
      id: Value(id),
      academicYear: Value(academicYear),
      term: Value(term),
      name: Value(name),
      timetableName: Value(timetableName),
      startDate: Value(startDate),
      teachingWeeks: Value(teachingWeeks),
      timeZone: Value(timeZone),
      isCurrent: Value(isCurrent),
    );
  }

  factory Semester.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Semester(
      id: serializer.fromJson<String>(json['id']),
      academicYear: serializer.fromJson<String>(json['academicYear']),
      term: serializer.fromJson<String>(json['term']),
      name: serializer.fromJson<String>(json['name']),
      timetableName: serializer.fromJson<String>(json['timetableName']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      teachingWeeks: serializer.fromJson<int>(json['teachingWeeks']),
      timeZone: serializer.fromJson<String>(json['timeZone']),
      isCurrent: serializer.fromJson<bool>(json['isCurrent']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'academicYear': serializer.toJson<String>(academicYear),
      'term': serializer.toJson<String>(term),
      'name': serializer.toJson<String>(name),
      'timetableName': serializer.toJson<String>(timetableName),
      'startDate': serializer.toJson<DateTime>(startDate),
      'teachingWeeks': serializer.toJson<int>(teachingWeeks),
      'timeZone': serializer.toJson<String>(timeZone),
      'isCurrent': serializer.toJson<bool>(isCurrent),
    };
  }

  Semester copyWith({
    String? id,
    String? academicYear,
    String? term,
    String? name,
    String? timetableName,
    DateTime? startDate,
    int? teachingWeeks,
    String? timeZone,
    bool? isCurrent,
  }) => Semester(
    id: id ?? this.id,
    academicYear: academicYear ?? this.academicYear,
    term: term ?? this.term,
    name: name ?? this.name,
    timetableName: timetableName ?? this.timetableName,
    startDate: startDate ?? this.startDate,
    teachingWeeks: teachingWeeks ?? this.teachingWeeks,
    timeZone: timeZone ?? this.timeZone,
    isCurrent: isCurrent ?? this.isCurrent,
  );
  Semester copyWithCompanion(SemestersCompanion data) {
    return Semester(
      id: data.id.present ? data.id.value : this.id,
      academicYear: data.academicYear.present
          ? data.academicYear.value
          : this.academicYear,
      term: data.term.present ? data.term.value : this.term,
      name: data.name.present ? data.name.value : this.name,
      timetableName: data.timetableName.present
          ? data.timetableName.value
          : this.timetableName,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      teachingWeeks: data.teachingWeeks.present
          ? data.teachingWeeks.value
          : this.teachingWeeks,
      timeZone: data.timeZone.present ? data.timeZone.value : this.timeZone,
      isCurrent: data.isCurrent.present ? data.isCurrent.value : this.isCurrent,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Semester(')
          ..write('id: $id, ')
          ..write('academicYear: $academicYear, ')
          ..write('term: $term, ')
          ..write('name: $name, ')
          ..write('timetableName: $timetableName, ')
          ..write('startDate: $startDate, ')
          ..write('teachingWeeks: $teachingWeeks, ')
          ..write('timeZone: $timeZone, ')
          ..write('isCurrent: $isCurrent')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    academicYear,
    term,
    name,
    timetableName,
    startDate,
    teachingWeeks,
    timeZone,
    isCurrent,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Semester &&
          other.id == this.id &&
          other.academicYear == this.academicYear &&
          other.term == this.term &&
          other.name == this.name &&
          other.timetableName == this.timetableName &&
          other.startDate == this.startDate &&
          other.teachingWeeks == this.teachingWeeks &&
          other.timeZone == this.timeZone &&
          other.isCurrent == this.isCurrent);
}

class SemestersCompanion extends UpdateCompanion<Semester> {
  final Value<String> id;
  final Value<String> academicYear;
  final Value<String> term;
  final Value<String> name;
  final Value<String> timetableName;
  final Value<DateTime> startDate;
  final Value<int> teachingWeeks;
  final Value<String> timeZone;
  final Value<bool> isCurrent;
  final Value<int> rowid;
  const SemestersCompanion({
    this.id = const Value.absent(),
    this.academicYear = const Value.absent(),
    this.term = const Value.absent(),
    this.name = const Value.absent(),
    this.timetableName = const Value.absent(),
    this.startDate = const Value.absent(),
    this.teachingWeeks = const Value.absent(),
    this.timeZone = const Value.absent(),
    this.isCurrent = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SemestersCompanion.insert({
    required String id,
    required String academicYear,
    required String term,
    required String name,
    this.timetableName = const Value.absent(),
    required DateTime startDate,
    required int teachingWeeks,
    this.timeZone = const Value.absent(),
    this.isCurrent = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       academicYear = Value(academicYear),
       term = Value(term),
       name = Value(name),
       startDate = Value(startDate),
       teachingWeeks = Value(teachingWeeks);
  static Insertable<Semester> custom({
    Expression<String>? id,
    Expression<String>? academicYear,
    Expression<String>? term,
    Expression<String>? name,
    Expression<String>? timetableName,
    Expression<DateTime>? startDate,
    Expression<int>? teachingWeeks,
    Expression<String>? timeZone,
    Expression<bool>? isCurrent,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (academicYear != null) 'academic_year': academicYear,
      if (term != null) 'term': term,
      if (name != null) 'name': name,
      if (timetableName != null) 'timetable_name': timetableName,
      if (startDate != null) 'start_date': startDate,
      if (teachingWeeks != null) 'teaching_weeks': teachingWeeks,
      if (timeZone != null) 'time_zone': timeZone,
      if (isCurrent != null) 'is_current': isCurrent,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SemestersCompanion copyWith({
    Value<String>? id,
    Value<String>? academicYear,
    Value<String>? term,
    Value<String>? name,
    Value<String>? timetableName,
    Value<DateTime>? startDate,
    Value<int>? teachingWeeks,
    Value<String>? timeZone,
    Value<bool>? isCurrent,
    Value<int>? rowid,
  }) {
    return SemestersCompanion(
      id: id ?? this.id,
      academicYear: academicYear ?? this.academicYear,
      term: term ?? this.term,
      name: name ?? this.name,
      timetableName: timetableName ?? this.timetableName,
      startDate: startDate ?? this.startDate,
      teachingWeeks: teachingWeeks ?? this.teachingWeeks,
      timeZone: timeZone ?? this.timeZone,
      isCurrent: isCurrent ?? this.isCurrent,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (academicYear.present) {
      map['academic_year'] = Variable<String>(academicYear.value);
    }
    if (term.present) {
      map['term'] = Variable<String>(term.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (timetableName.present) {
      map['timetable_name'] = Variable<String>(timetableName.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (teachingWeeks.present) {
      map['teaching_weeks'] = Variable<int>(teachingWeeks.value);
    }
    if (timeZone.present) {
      map['time_zone'] = Variable<String>(timeZone.value);
    }
    if (isCurrent.present) {
      map['is_current'] = Variable<bool>(isCurrent.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SemestersCompanion(')
          ..write('id: $id, ')
          ..write('academicYear: $academicYear, ')
          ..write('term: $term, ')
          ..write('name: $name, ')
          ..write('timetableName: $timetableName, ')
          ..write('startDate: $startDate, ')
          ..write('teachingWeeks: $teachingWeeks, ')
          ..write('timeZone: $timeZone, ')
          ..write('isCurrent: $isCurrent, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CoursesTable extends Courses with TableInfo<$CoursesTable, Course> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CoursesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _semesterIdMeta = const VerificationMeta(
    'semesterId',
  );
  @override
  late final GeneratedColumn<String> semesterId = GeneratedColumn<String>(
    'semester_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES semesters (id)',
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
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _teacherMeta = const VerificationMeta(
    'teacher',
  );
  @override
  late final GeneratedColumn<String> teacher = GeneratedColumn<String>(
    'teacher',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _teachingClassMeta = const VerificationMeta(
    'teachingClass',
  );
  @override
  late final GeneratedColumn<String> teachingClass = GeneratedColumn<String>(
    'teaching_class',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorValueMeta = const VerificationMeta(
    'colorValue',
  );
  @override
  late final GeneratedColumn<int> colorValue = GeneratedColumn<int>(
    'color_value',
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
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isLocallyModifiedMeta = const VerificationMeta(
    'isLocallyModified',
  );
  @override
  late final GeneratedColumn<bool> isLocallyModified = GeneratedColumn<bool>(
    'is_locally_modified',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_locally_modified" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    semesterId,
    name,
    code,
    teacher,
    teachingClass,
    colorValue,
    notes,
    source,
    sourceId,
    isLocallyModified,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'courses';
  @override
  VerificationContext validateIntegrity(
    Insertable<Course> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('semester_id')) {
      context.handle(
        _semesterIdMeta,
        semesterId.isAcceptableOrUnknown(data['semester_id']!, _semesterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_semesterIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    }
    if (data.containsKey('teacher')) {
      context.handle(
        _teacherMeta,
        teacher.isAcceptableOrUnknown(data['teacher']!, _teacherMeta),
      );
    }
    if (data.containsKey('teaching_class')) {
      context.handle(
        _teachingClassMeta,
        teachingClass.isAcceptableOrUnknown(
          data['teaching_class']!,
          _teachingClassMeta,
        ),
      );
    }
    if (data.containsKey('color_value')) {
      context.handle(
        _colorValueMeta,
        colorValue.isAcceptableOrUnknown(data['color_value']!, _colorValueMeta),
      );
    } else if (isInserting) {
      context.missing(_colorValueMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    }
    if (data.containsKey('is_locally_modified')) {
      context.handle(
        _isLocallyModifiedMeta,
        isLocallyModified.isAcceptableOrUnknown(
          data['is_locally_modified']!,
          _isLocallyModifiedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Course map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Course(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      semesterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}semester_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      ),
      teacher: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}teacher'],
      ),
      teachingClass: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}teaching_class'],
      ),
      colorValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_value'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      ),
      isLocallyModified: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_locally_modified'],
      )!,
    );
  }

  @override
  $CoursesTable createAlias(String alias) {
    return $CoursesTable(attachedDatabase, alias);
  }
}

class Course extends DataClass implements Insertable<Course> {
  final String id;
  final String semesterId;
  final String name;
  final String? code;
  final String? teacher;
  final String? teachingClass;
  final int colorValue;
  final String? notes;
  final String source;
  final String? sourceId;
  final bool isLocallyModified;
  const Course({
    required this.id,
    required this.semesterId,
    required this.name,
    this.code,
    this.teacher,
    this.teachingClass,
    required this.colorValue,
    this.notes,
    required this.source,
    this.sourceId,
    required this.isLocallyModified,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['semester_id'] = Variable<String>(semesterId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || code != null) {
      map['code'] = Variable<String>(code);
    }
    if (!nullToAbsent || teacher != null) {
      map['teacher'] = Variable<String>(teacher);
    }
    if (!nullToAbsent || teachingClass != null) {
      map['teaching_class'] = Variable<String>(teachingClass);
    }
    map['color_value'] = Variable<int>(colorValue);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<String>(sourceId);
    }
    map['is_locally_modified'] = Variable<bool>(isLocallyModified);
    return map;
  }

  CoursesCompanion toCompanion(bool nullToAbsent) {
    return CoursesCompanion(
      id: Value(id),
      semesterId: Value(semesterId),
      name: Value(name),
      code: code == null && nullToAbsent ? const Value.absent() : Value(code),
      teacher: teacher == null && nullToAbsent
          ? const Value.absent()
          : Value(teacher),
      teachingClass: teachingClass == null && nullToAbsent
          ? const Value.absent()
          : Value(teachingClass),
      colorValue: Value(colorValue),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      source: Value(source),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
      isLocallyModified: Value(isLocallyModified),
    );
  }

  factory Course.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Course(
      id: serializer.fromJson<String>(json['id']),
      semesterId: serializer.fromJson<String>(json['semesterId']),
      name: serializer.fromJson<String>(json['name']),
      code: serializer.fromJson<String?>(json['code']),
      teacher: serializer.fromJson<String?>(json['teacher']),
      teachingClass: serializer.fromJson<String?>(json['teachingClass']),
      colorValue: serializer.fromJson<int>(json['colorValue']),
      notes: serializer.fromJson<String?>(json['notes']),
      source: serializer.fromJson<String>(json['source']),
      sourceId: serializer.fromJson<String?>(json['sourceId']),
      isLocallyModified: serializer.fromJson<bool>(json['isLocallyModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'semesterId': serializer.toJson<String>(semesterId),
      'name': serializer.toJson<String>(name),
      'code': serializer.toJson<String?>(code),
      'teacher': serializer.toJson<String?>(teacher),
      'teachingClass': serializer.toJson<String?>(teachingClass),
      'colorValue': serializer.toJson<int>(colorValue),
      'notes': serializer.toJson<String?>(notes),
      'source': serializer.toJson<String>(source),
      'sourceId': serializer.toJson<String?>(sourceId),
      'isLocallyModified': serializer.toJson<bool>(isLocallyModified),
    };
  }

  Course copyWith({
    String? id,
    String? semesterId,
    String? name,
    Value<String?> code = const Value.absent(),
    Value<String?> teacher = const Value.absent(),
    Value<String?> teachingClass = const Value.absent(),
    int? colorValue,
    Value<String?> notes = const Value.absent(),
    String? source,
    Value<String?> sourceId = const Value.absent(),
    bool? isLocallyModified,
  }) => Course(
    id: id ?? this.id,
    semesterId: semesterId ?? this.semesterId,
    name: name ?? this.name,
    code: code.present ? code.value : this.code,
    teacher: teacher.present ? teacher.value : this.teacher,
    teachingClass: teachingClass.present
        ? teachingClass.value
        : this.teachingClass,
    colorValue: colorValue ?? this.colorValue,
    notes: notes.present ? notes.value : this.notes,
    source: source ?? this.source,
    sourceId: sourceId.present ? sourceId.value : this.sourceId,
    isLocallyModified: isLocallyModified ?? this.isLocallyModified,
  );
  Course copyWithCompanion(CoursesCompanion data) {
    return Course(
      id: data.id.present ? data.id.value : this.id,
      semesterId: data.semesterId.present
          ? data.semesterId.value
          : this.semesterId,
      name: data.name.present ? data.name.value : this.name,
      code: data.code.present ? data.code.value : this.code,
      teacher: data.teacher.present ? data.teacher.value : this.teacher,
      teachingClass: data.teachingClass.present
          ? data.teachingClass.value
          : this.teachingClass,
      colorValue: data.colorValue.present
          ? data.colorValue.value
          : this.colorValue,
      notes: data.notes.present ? data.notes.value : this.notes,
      source: data.source.present ? data.source.value : this.source,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      isLocallyModified: data.isLocallyModified.present
          ? data.isLocallyModified.value
          : this.isLocallyModified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Course(')
          ..write('id: $id, ')
          ..write('semesterId: $semesterId, ')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('teacher: $teacher, ')
          ..write('teachingClass: $teachingClass, ')
          ..write('colorValue: $colorValue, ')
          ..write('notes: $notes, ')
          ..write('source: $source, ')
          ..write('sourceId: $sourceId, ')
          ..write('isLocallyModified: $isLocallyModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    semesterId,
    name,
    code,
    teacher,
    teachingClass,
    colorValue,
    notes,
    source,
    sourceId,
    isLocallyModified,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Course &&
          other.id == this.id &&
          other.semesterId == this.semesterId &&
          other.name == this.name &&
          other.code == this.code &&
          other.teacher == this.teacher &&
          other.teachingClass == this.teachingClass &&
          other.colorValue == this.colorValue &&
          other.notes == this.notes &&
          other.source == this.source &&
          other.sourceId == this.sourceId &&
          other.isLocallyModified == this.isLocallyModified);
}

class CoursesCompanion extends UpdateCompanion<Course> {
  final Value<String> id;
  final Value<String> semesterId;
  final Value<String> name;
  final Value<String?> code;
  final Value<String?> teacher;
  final Value<String?> teachingClass;
  final Value<int> colorValue;
  final Value<String?> notes;
  final Value<String> source;
  final Value<String?> sourceId;
  final Value<bool> isLocallyModified;
  final Value<int> rowid;
  const CoursesCompanion({
    this.id = const Value.absent(),
    this.semesterId = const Value.absent(),
    this.name = const Value.absent(),
    this.code = const Value.absent(),
    this.teacher = const Value.absent(),
    this.teachingClass = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.notes = const Value.absent(),
    this.source = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.isLocallyModified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CoursesCompanion.insert({
    required String id,
    required String semesterId,
    required String name,
    this.code = const Value.absent(),
    this.teacher = const Value.absent(),
    this.teachingClass = const Value.absent(),
    required int colorValue,
    this.notes = const Value.absent(),
    required String source,
    this.sourceId = const Value.absent(),
    this.isLocallyModified = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       semesterId = Value(semesterId),
       name = Value(name),
       colorValue = Value(colorValue),
       source = Value(source);
  static Insertable<Course> custom({
    Expression<String>? id,
    Expression<String>? semesterId,
    Expression<String>? name,
    Expression<String>? code,
    Expression<String>? teacher,
    Expression<String>? teachingClass,
    Expression<int>? colorValue,
    Expression<String>? notes,
    Expression<String>? source,
    Expression<String>? sourceId,
    Expression<bool>? isLocallyModified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (semesterId != null) 'semester_id': semesterId,
      if (name != null) 'name': name,
      if (code != null) 'code': code,
      if (teacher != null) 'teacher': teacher,
      if (teachingClass != null) 'teaching_class': teachingClass,
      if (colorValue != null) 'color_value': colorValue,
      if (notes != null) 'notes': notes,
      if (source != null) 'source': source,
      if (sourceId != null) 'source_id': sourceId,
      if (isLocallyModified != null) 'is_locally_modified': isLocallyModified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CoursesCompanion copyWith({
    Value<String>? id,
    Value<String>? semesterId,
    Value<String>? name,
    Value<String?>? code,
    Value<String?>? teacher,
    Value<String?>? teachingClass,
    Value<int>? colorValue,
    Value<String?>? notes,
    Value<String>? source,
    Value<String?>? sourceId,
    Value<bool>? isLocallyModified,
    Value<int>? rowid,
  }) {
    return CoursesCompanion(
      id: id ?? this.id,
      semesterId: semesterId ?? this.semesterId,
      name: name ?? this.name,
      code: code ?? this.code,
      teacher: teacher ?? this.teacher,
      teachingClass: teachingClass ?? this.teachingClass,
      colorValue: colorValue ?? this.colorValue,
      notes: notes ?? this.notes,
      source: source ?? this.source,
      sourceId: sourceId ?? this.sourceId,
      isLocallyModified: isLocallyModified ?? this.isLocallyModified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (semesterId.present) {
      map['semester_id'] = Variable<String>(semesterId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (teacher.present) {
      map['teacher'] = Variable<String>(teacher.value);
    }
    if (teachingClass.present) {
      map['teaching_class'] = Variable<String>(teachingClass.value);
    }
    if (colorValue.present) {
      map['color_value'] = Variable<int>(colorValue.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (isLocallyModified.present) {
      map['is_locally_modified'] = Variable<bool>(isLocallyModified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CoursesCompanion(')
          ..write('id: $id, ')
          ..write('semesterId: $semesterId, ')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('teacher: $teacher, ')
          ..write('teachingClass: $teachingClass, ')
          ..write('colorValue: $colorValue, ')
          ..write('notes: $notes, ')
          ..write('source: $source, ')
          ..write('sourceId: $sourceId, ')
          ..write('isLocallyModified: $isLocallyModified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CourseSessionsTable extends CourseSessions
    with TableInfo<$CourseSessionsTable, CourseSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CourseSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _courseIdMeta = const VerificationMeta(
    'courseId',
  );
  @override
  late final GeneratedColumn<String> courseId = GeneratedColumn<String>(
    'course_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES courses (id)',
    ),
  );
  static const VerificationMeta _weekdayMeta = const VerificationMeta(
    'weekday',
  );
  @override
  late final GeneratedColumn<int> weekday = GeneratedColumn<int>(
    'weekday',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startPeriodMeta = const VerificationMeta(
    'startPeriod',
  );
  @override
  late final GeneratedColumn<int> startPeriod = GeneratedColumn<int>(
    'start_period',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endPeriodMeta = const VerificationMeta(
    'endPeriod',
  );
  @override
  late final GeneratedColumn<int> endPeriod = GeneratedColumn<int>(
    'end_period',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weeksMeta = const VerificationMeta('weeks');
  @override
  late final GeneratedColumn<String> weeks = GeneratedColumn<String>(
    'weeks',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    courseId,
    weekday,
    startPeriod,
    endPeriod,
    location,
    weeks,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'course_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<CourseSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('course_id')) {
      context.handle(
        _courseIdMeta,
        courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_courseIdMeta);
    }
    if (data.containsKey('weekday')) {
      context.handle(
        _weekdayMeta,
        weekday.isAcceptableOrUnknown(data['weekday']!, _weekdayMeta),
      );
    } else if (isInserting) {
      context.missing(_weekdayMeta);
    }
    if (data.containsKey('start_period')) {
      context.handle(
        _startPeriodMeta,
        startPeriod.isAcceptableOrUnknown(
          data['start_period']!,
          _startPeriodMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startPeriodMeta);
    }
    if (data.containsKey('end_period')) {
      context.handle(
        _endPeriodMeta,
        endPeriod.isAcceptableOrUnknown(data['end_period']!, _endPeriodMeta),
      );
    } else if (isInserting) {
      context.missing(_endPeriodMeta);
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('weeks')) {
      context.handle(
        _weeksMeta,
        weeks.isAcceptableOrUnknown(data['weeks']!, _weeksMeta),
      );
    } else if (isInserting) {
      context.missing(_weeksMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CourseSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CourseSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      courseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course_id'],
      )!,
      weekday: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weekday'],
      )!,
      startPeriod: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_period'],
      )!,
      endPeriod: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_period'],
      )!,
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      weeks: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weeks'],
      )!,
    );
  }

  @override
  $CourseSessionsTable createAlias(String alias) {
    return $CourseSessionsTable(attachedDatabase, alias);
  }
}

class CourseSession extends DataClass implements Insertable<CourseSession> {
  final String id;
  final String courseId;
  final int weekday;
  final int startPeriod;
  final int endPeriod;
  final String? location;
  final String weeks;
  const CourseSession({
    required this.id,
    required this.courseId,
    required this.weekday,
    required this.startPeriod,
    required this.endPeriod,
    this.location,
    required this.weeks,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['course_id'] = Variable<String>(courseId);
    map['weekday'] = Variable<int>(weekday);
    map['start_period'] = Variable<int>(startPeriod);
    map['end_period'] = Variable<int>(endPeriod);
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    map['weeks'] = Variable<String>(weeks);
    return map;
  }

  CourseSessionsCompanion toCompanion(bool nullToAbsent) {
    return CourseSessionsCompanion(
      id: Value(id),
      courseId: Value(courseId),
      weekday: Value(weekday),
      startPeriod: Value(startPeriod),
      endPeriod: Value(endPeriod),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      weeks: Value(weeks),
    );
  }

  factory CourseSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CourseSession(
      id: serializer.fromJson<String>(json['id']),
      courseId: serializer.fromJson<String>(json['courseId']),
      weekday: serializer.fromJson<int>(json['weekday']),
      startPeriod: serializer.fromJson<int>(json['startPeriod']),
      endPeriod: serializer.fromJson<int>(json['endPeriod']),
      location: serializer.fromJson<String?>(json['location']),
      weeks: serializer.fromJson<String>(json['weeks']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'courseId': serializer.toJson<String>(courseId),
      'weekday': serializer.toJson<int>(weekday),
      'startPeriod': serializer.toJson<int>(startPeriod),
      'endPeriod': serializer.toJson<int>(endPeriod),
      'location': serializer.toJson<String?>(location),
      'weeks': serializer.toJson<String>(weeks),
    };
  }

  CourseSession copyWith({
    String? id,
    String? courseId,
    int? weekday,
    int? startPeriod,
    int? endPeriod,
    Value<String?> location = const Value.absent(),
    String? weeks,
  }) => CourseSession(
    id: id ?? this.id,
    courseId: courseId ?? this.courseId,
    weekday: weekday ?? this.weekday,
    startPeriod: startPeriod ?? this.startPeriod,
    endPeriod: endPeriod ?? this.endPeriod,
    location: location.present ? location.value : this.location,
    weeks: weeks ?? this.weeks,
  );
  CourseSession copyWithCompanion(CourseSessionsCompanion data) {
    return CourseSession(
      id: data.id.present ? data.id.value : this.id,
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      weekday: data.weekday.present ? data.weekday.value : this.weekday,
      startPeriod: data.startPeriod.present
          ? data.startPeriod.value
          : this.startPeriod,
      endPeriod: data.endPeriod.present ? data.endPeriod.value : this.endPeriod,
      location: data.location.present ? data.location.value : this.location,
      weeks: data.weeks.present ? data.weeks.value : this.weeks,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CourseSession(')
          ..write('id: $id, ')
          ..write('courseId: $courseId, ')
          ..write('weekday: $weekday, ')
          ..write('startPeriod: $startPeriod, ')
          ..write('endPeriod: $endPeriod, ')
          ..write('location: $location, ')
          ..write('weeks: $weeks')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    courseId,
    weekday,
    startPeriod,
    endPeriod,
    location,
    weeks,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CourseSession &&
          other.id == this.id &&
          other.courseId == this.courseId &&
          other.weekday == this.weekday &&
          other.startPeriod == this.startPeriod &&
          other.endPeriod == this.endPeriod &&
          other.location == this.location &&
          other.weeks == this.weeks);
}

class CourseSessionsCompanion extends UpdateCompanion<CourseSession> {
  final Value<String> id;
  final Value<String> courseId;
  final Value<int> weekday;
  final Value<int> startPeriod;
  final Value<int> endPeriod;
  final Value<String?> location;
  final Value<String> weeks;
  final Value<int> rowid;
  const CourseSessionsCompanion({
    this.id = const Value.absent(),
    this.courseId = const Value.absent(),
    this.weekday = const Value.absent(),
    this.startPeriod = const Value.absent(),
    this.endPeriod = const Value.absent(),
    this.location = const Value.absent(),
    this.weeks = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CourseSessionsCompanion.insert({
    required String id,
    required String courseId,
    required int weekday,
    required int startPeriod,
    required int endPeriod,
    this.location = const Value.absent(),
    required String weeks,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       courseId = Value(courseId),
       weekday = Value(weekday),
       startPeriod = Value(startPeriod),
       endPeriod = Value(endPeriod),
       weeks = Value(weeks);
  static Insertable<CourseSession> custom({
    Expression<String>? id,
    Expression<String>? courseId,
    Expression<int>? weekday,
    Expression<int>? startPeriod,
    Expression<int>? endPeriod,
    Expression<String>? location,
    Expression<String>? weeks,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (courseId != null) 'course_id': courseId,
      if (weekday != null) 'weekday': weekday,
      if (startPeriod != null) 'start_period': startPeriod,
      if (endPeriod != null) 'end_period': endPeriod,
      if (location != null) 'location': location,
      if (weeks != null) 'weeks': weeks,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CourseSessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? courseId,
    Value<int>? weekday,
    Value<int>? startPeriod,
    Value<int>? endPeriod,
    Value<String?>? location,
    Value<String>? weeks,
    Value<int>? rowid,
  }) {
    return CourseSessionsCompanion(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      weekday: weekday ?? this.weekday,
      startPeriod: startPeriod ?? this.startPeriod,
      endPeriod: endPeriod ?? this.endPeriod,
      location: location ?? this.location,
      weeks: weeks ?? this.weeks,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (courseId.present) {
      map['course_id'] = Variable<String>(courseId.value);
    }
    if (weekday.present) {
      map['weekday'] = Variable<int>(weekday.value);
    }
    if (startPeriod.present) {
      map['start_period'] = Variable<int>(startPeriod.value);
    }
    if (endPeriod.present) {
      map['end_period'] = Variable<int>(endPeriod.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (weeks.present) {
      map['weeks'] = Variable<String>(weeks.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CourseSessionsCompanion(')
          ..write('id: $id, ')
          ..write('courseId: $courseId, ')
          ..write('weekday: $weekday, ')
          ..write('startPeriod: $startPeriod, ')
          ..write('endPeriod: $endPeriod, ')
          ..write('location: $location, ')
          ..write('weeks: $weeks, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PeriodDefinitionsTable extends PeriodDefinitions
    with TableInfo<$PeriodDefinitionsTable, PeriodDefinition> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeriodDefinitionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _semesterIdMeta = const VerificationMeta(
    'semesterId',
  );
  @override
  late final GeneratedColumn<String> semesterId = GeneratedColumn<String>(
    'semester_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES semesters (id)',
    ),
  );
  static const VerificationMeta _periodMeta = const VerificationMeta('period');
  @override
  late final GeneratedColumn<int> period = GeneratedColumn<int>(
    'period',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<String> startTime = GeneratedColumn<String>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<String> endTime = GeneratedColumn<String>(
    'end_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _periodGroupMeta = const VerificationMeta(
    'periodGroup',
  );
  @override
  late final GeneratedColumn<String> periodGroup = GeneratedColumn<String>(
    'period_group',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    semesterId,
    period,
    startTime,
    endTime,
    periodGroup,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'period_definitions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PeriodDefinition> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('semester_id')) {
      context.handle(
        _semesterIdMeta,
        semesterId.isAcceptableOrUnknown(data['semester_id']!, _semesterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_semesterIdMeta);
    }
    if (data.containsKey('period')) {
      context.handle(
        _periodMeta,
        period.isAcceptableOrUnknown(data['period']!, _periodMeta),
      );
    } else if (isInserting) {
      context.missing(_periodMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_endTimeMeta);
    }
    if (data.containsKey('period_group')) {
      context.handle(
        _periodGroupMeta,
        periodGroup.isAcceptableOrUnknown(
          data['period_group']!,
          _periodGroupMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_periodGroupMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PeriodDefinition map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PeriodDefinition(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      semesterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}semester_id'],
      )!,
      period: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}period'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_time'],
      )!,
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_time'],
      )!,
      periodGroup: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}period_group'],
      )!,
    );
  }

  @override
  $PeriodDefinitionsTable createAlias(String alias) {
    return $PeriodDefinitionsTable(attachedDatabase, alias);
  }
}

class PeriodDefinition extends DataClass
    implements Insertable<PeriodDefinition> {
  final String id;
  final String semesterId;
  final int period;
  final String startTime;
  final String endTime;
  final String periodGroup;
  const PeriodDefinition({
    required this.id,
    required this.semesterId,
    required this.period,
    required this.startTime,
    required this.endTime,
    required this.periodGroup,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['semester_id'] = Variable<String>(semesterId);
    map['period'] = Variable<int>(period);
    map['start_time'] = Variable<String>(startTime);
    map['end_time'] = Variable<String>(endTime);
    map['period_group'] = Variable<String>(periodGroup);
    return map;
  }

  PeriodDefinitionsCompanion toCompanion(bool nullToAbsent) {
    return PeriodDefinitionsCompanion(
      id: Value(id),
      semesterId: Value(semesterId),
      period: Value(period),
      startTime: Value(startTime),
      endTime: Value(endTime),
      periodGroup: Value(periodGroup),
    );
  }

  factory PeriodDefinition.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PeriodDefinition(
      id: serializer.fromJson<String>(json['id']),
      semesterId: serializer.fromJson<String>(json['semesterId']),
      period: serializer.fromJson<int>(json['period']),
      startTime: serializer.fromJson<String>(json['startTime']),
      endTime: serializer.fromJson<String>(json['endTime']),
      periodGroup: serializer.fromJson<String>(json['periodGroup']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'semesterId': serializer.toJson<String>(semesterId),
      'period': serializer.toJson<int>(period),
      'startTime': serializer.toJson<String>(startTime),
      'endTime': serializer.toJson<String>(endTime),
      'periodGroup': serializer.toJson<String>(periodGroup),
    };
  }

  PeriodDefinition copyWith({
    String? id,
    String? semesterId,
    int? period,
    String? startTime,
    String? endTime,
    String? periodGroup,
  }) => PeriodDefinition(
    id: id ?? this.id,
    semesterId: semesterId ?? this.semesterId,
    period: period ?? this.period,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    periodGroup: periodGroup ?? this.periodGroup,
  );
  PeriodDefinition copyWithCompanion(PeriodDefinitionsCompanion data) {
    return PeriodDefinition(
      id: data.id.present ? data.id.value : this.id,
      semesterId: data.semesterId.present
          ? data.semesterId.value
          : this.semesterId,
      period: data.period.present ? data.period.value : this.period,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      periodGroup: data.periodGroup.present
          ? data.periodGroup.value
          : this.periodGroup,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PeriodDefinition(')
          ..write('id: $id, ')
          ..write('semesterId: $semesterId, ')
          ..write('period: $period, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('periodGroup: $periodGroup')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, semesterId, period, startTime, endTime, periodGroup);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PeriodDefinition &&
          other.id == this.id &&
          other.semesterId == this.semesterId &&
          other.period == this.period &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.periodGroup == this.periodGroup);
}

class PeriodDefinitionsCompanion extends UpdateCompanion<PeriodDefinition> {
  final Value<String> id;
  final Value<String> semesterId;
  final Value<int> period;
  final Value<String> startTime;
  final Value<String> endTime;
  final Value<String> periodGroup;
  final Value<int> rowid;
  const PeriodDefinitionsCompanion({
    this.id = const Value.absent(),
    this.semesterId = const Value.absent(),
    this.period = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.periodGroup = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PeriodDefinitionsCompanion.insert({
    required String id,
    required String semesterId,
    required int period,
    required String startTime,
    required String endTime,
    required String periodGroup,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       semesterId = Value(semesterId),
       period = Value(period),
       startTime = Value(startTime),
       endTime = Value(endTime),
       periodGroup = Value(periodGroup);
  static Insertable<PeriodDefinition> custom({
    Expression<String>? id,
    Expression<String>? semesterId,
    Expression<int>? period,
    Expression<String>? startTime,
    Expression<String>? endTime,
    Expression<String>? periodGroup,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (semesterId != null) 'semester_id': semesterId,
      if (period != null) 'period': period,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (periodGroup != null) 'period_group': periodGroup,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PeriodDefinitionsCompanion copyWith({
    Value<String>? id,
    Value<String>? semesterId,
    Value<int>? period,
    Value<String>? startTime,
    Value<String>? endTime,
    Value<String>? periodGroup,
    Value<int>? rowid,
  }) {
    return PeriodDefinitionsCompanion(
      id: id ?? this.id,
      semesterId: semesterId ?? this.semesterId,
      period: period ?? this.period,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      periodGroup: periodGroup ?? this.periodGroup,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (semesterId.present) {
      map['semester_id'] = Variable<String>(semesterId.value);
    }
    if (period.present) {
      map['period'] = Variable<int>(period.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<String>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<String>(endTime.value);
    }
    if (periodGroup.present) {
      map['period_group'] = Variable<String>(periodGroup.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeriodDefinitionsCompanion(')
          ..write('id: $id, ')
          ..write('semesterId: $semesterId, ')
          ..write('period: $period, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('periodGroup: $periodGroup, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SemestersTable semesters = $SemestersTable(this);
  late final $CoursesTable courses = $CoursesTable(this);
  late final $CourseSessionsTable courseSessions = $CourseSessionsTable(this);
  late final $PeriodDefinitionsTable periodDefinitions =
      $PeriodDefinitionsTable(this);
  late final Index courseSessionsCourseId = Index(
    'course_sessions_course_id',
    'CREATE INDEX course_sessions_course_id ON course_sessions (course_id)',
  );
  late final Index periodDefinitionsSemesterPeriod = Index(
    'period_definitions_semester_period',
    'CREATE UNIQUE INDEX period_definitions_semester_period ON period_definitions (semester_id, period)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    semesters,
    courses,
    courseSessions,
    periodDefinitions,
    courseSessionsCourseId,
    periodDefinitionsSemesterPeriod,
  ];
}

typedef $$SemestersTableCreateCompanionBuilder = SemestersCompanion Function({
  required String id,
  required String academicYear,
  required String term,
  required String name,
  Value<String> timetableName,
  required DateTime startDate,
  required int teachingWeeks,
  Value<String> timeZone,
  Value<bool> isCurrent,
  Value<int> rowid,
});
typedef $$SemestersTableUpdateCompanionBuilder = SemestersCompanion Function({
  Value<String> id,
  Value<String> academicYear,
  Value<String> term,
  Value<String> name,
  Value<String> timetableName,
  Value<DateTime> startDate,
  Value<int> teachingWeeks,
  Value<String> timeZone,
  Value<bool> isCurrent,
  Value<int> rowid,
});

final class $$SemestersTableReferences
    extends BaseReferences<_$AppDatabase, $SemestersTable, Semester> {
  $$SemestersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CoursesTable, List<Course>> _coursesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.courses,
    aliasName: 'semesters__id__courses__semester_id',
  );

  $$CoursesTableProcessedTableManager get coursesRefs {
    final manager = $$CoursesTableTableManager(
      $_db,
      $_db.courses,
    ).filter((f) => f.semesterId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_coursesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PeriodDefinitionsTable, List<PeriodDefinition>>
  _periodDefinitionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.periodDefinitions,
        aliasName: 'semesters__id__period_definitions__semester_id',
      );

  $$PeriodDefinitionsTableProcessedTableManager get periodDefinitionsRefs {
    final manager = $$PeriodDefinitionsTableTableManager(
      $_db,
      $_db.periodDefinitions,
    ).filter((f) => f.semesterId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _periodDefinitionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SemestersTableFilterComposer
    extends Composer<_$AppDatabase, $SemestersTable> {
  $$SemestersTableFilterComposer({
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

  ColumnFilters<String> get academicYear => $composableBuilder(
    column: $table.academicYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get term => $composableBuilder(
    column: $table.term,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timetableName => $composableBuilder(
    column: $table.timetableName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get teachingWeeks => $composableBuilder(
    column: $table.teachingWeeks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timeZone => $composableBuilder(
    column: $table.timeZone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCurrent => $composableBuilder(
    column: $table.isCurrent,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> coursesRefs(
    Expression<bool> Function($$CoursesTableFilterComposer f) f,
  ) {
    final $$CoursesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.semesterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableFilterComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> periodDefinitionsRefs(
    Expression<bool> Function($$PeriodDefinitionsTableFilterComposer f) f,
  ) {
    final $$PeriodDefinitionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.periodDefinitions,
      getReferencedColumn: (t) => t.semesterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeriodDefinitionsTableFilterComposer(
            $db: $db,
            $table: $db.periodDefinitions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SemestersTableOrderingComposer
    extends Composer<_$AppDatabase, $SemestersTable> {
  $$SemestersTableOrderingComposer({
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

  ColumnOrderings<String> get academicYear => $composableBuilder(
    column: $table.academicYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get term => $composableBuilder(
    column: $table.term,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timetableName => $composableBuilder(
    column: $table.timetableName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get teachingWeeks => $composableBuilder(
    column: $table.teachingWeeks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeZone => $composableBuilder(
    column: $table.timeZone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCurrent => $composableBuilder(
    column: $table.isCurrent,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SemestersTableAnnotationComposer
    extends Composer<_$AppDatabase, $SemestersTable> {
  $$SemestersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get academicYear => $composableBuilder(
    column: $table.academicYear,
    builder: (column) => column,
  );

  GeneratedColumn<String> get term =>
      $composableBuilder(column: $table.term, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get timetableName => $composableBuilder(
    column: $table.timetableName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<int> get teachingWeeks => $composableBuilder(
    column: $table.teachingWeeks,
    builder: (column) => column,
  );

  GeneratedColumn<String> get timeZone =>
      $composableBuilder(column: $table.timeZone, builder: (column) => column);

  GeneratedColumn<bool> get isCurrent =>
      $composableBuilder(column: $table.isCurrent, builder: (column) => column);

  Expression<T> coursesRefs<T extends Object>(
    Expression<T> Function($$CoursesTableAnnotationComposer a) f,
  ) {
    final $$CoursesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.semesterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableAnnotationComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> periodDefinitionsRefs<T extends Object>(
    Expression<T> Function($$PeriodDefinitionsTableAnnotationComposer a) f,
  ) {
    final $$PeriodDefinitionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.periodDefinitions,
          getReferencedColumn: (t) => t.semesterId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PeriodDefinitionsTableAnnotationComposer(
                $db: $db,
                $table: $db.periodDefinitions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$SemestersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SemestersTable,
          Semester,
          $$SemestersTableFilterComposer,
          $$SemestersTableOrderingComposer,
          $$SemestersTableAnnotationComposer,
          $$SemestersTableCreateCompanionBuilder,
          $$SemestersTableUpdateCompanionBuilder,
          (Semester, $$SemestersTableReferences),
          Semester,
          PrefetchHooks Function({bool coursesRefs, bool periodDefinitionsRefs})
        > {
  $$SemestersTableTableManager(_$AppDatabase db, $SemestersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SemestersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SemestersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SemestersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> academicYear = const Value.absent(),
                Value<String> term = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> timetableName = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<int> teachingWeeks = const Value.absent(),
                Value<String> timeZone = const Value.absent(),
                Value<bool> isCurrent = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SemestersCompanion(
                id: id,
                academicYear: academicYear,
                term: term,
                name: name,
                timetableName: timetableName,
                startDate: startDate,
                teachingWeeks: teachingWeeks,
                timeZone: timeZone,
                isCurrent: isCurrent,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String academicYear,
                required String term,
                required String name,
                Value<String> timetableName = const Value.absent(),
                required DateTime startDate,
                required int teachingWeeks,
                Value<String> timeZone = const Value.absent(),
                Value<bool> isCurrent = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SemestersCompanion.insert(
                id: id,
                academicYear: academicYear,
                term: term,
                name: name,
                timetableName: timetableName,
                startDate: startDate,
                teachingWeeks: teachingWeeks,
                timeZone: timeZone,
                isCurrent: isCurrent,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SemestersTable, Semester>(table),
                  $$SemestersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({coursesRefs = false, periodDefinitionsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (coursesRefs) db.courses,
                    if (periodDefinitionsRefs) db.periodDefinitions,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (coursesRefs)
                        await $_getPrefetchedData<
                          Semester,
                          $SemestersTable,
                          Course
                        >(
                          currentTable: table,
                          referencedTable: $$SemestersTableReferences
                              ._coursesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SemestersTableReferences(
                                db,
                                table,
                                p0,
                              ).coursesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.semesterId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (periodDefinitionsRefs)
                        await $_getPrefetchedData<
                          Semester,
                          $SemestersTable,
                          PeriodDefinition
                        >(
                          currentTable: table,
                          referencedTable: $$SemestersTableReferences
                              ._periodDefinitionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SemestersTableReferences(
                                db,
                                table,
                                p0,
                              ).periodDefinitionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.semesterId == item.id,
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

typedef $$SemestersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SemestersTable,
      Semester,
      $$SemestersTableFilterComposer,
      $$SemestersTableOrderingComposer,
      $$SemestersTableAnnotationComposer,
      $$SemestersTableCreateCompanionBuilder,
      $$SemestersTableUpdateCompanionBuilder,
      (Semester, $$SemestersTableReferences),
      Semester,
      PrefetchHooks Function({bool coursesRefs, bool periodDefinitionsRefs})
    >;
typedef $$CoursesTableCreateCompanionBuilder = CoursesCompanion Function({
  required String id,
  required String semesterId,
  required String name,
  Value<String?> code,
  Value<String?> teacher,
  Value<String?> teachingClass,
  required int colorValue,
  Value<String?> notes,
  required String source,
  Value<String?> sourceId,
  Value<bool> isLocallyModified,
  Value<int> rowid,
});
typedef $$CoursesTableUpdateCompanionBuilder = CoursesCompanion Function({
  Value<String> id,
  Value<String> semesterId,
  Value<String> name,
  Value<String?> code,
  Value<String?> teacher,
  Value<String?> teachingClass,
  Value<int> colorValue,
  Value<String?> notes,
  Value<String> source,
  Value<String?> sourceId,
  Value<bool> isLocallyModified,
  Value<int> rowid,
});

final class $$CoursesTableReferences
    extends BaseReferences<_$AppDatabase, $CoursesTable, Course> {
  $$CoursesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SemestersTable _semesterIdTable(_$AppDatabase db) =>
      db.semesters.createAlias('courses__semester_id__semesters__id');

  $$SemestersTableProcessedTableManager get semesterId {
    final $_column = $_itemColumn<String>('semester_id')!;

    final manager = $$SemestersTableTableManager(
      $_db,
      $_db.semesters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_semesterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$CourseSessionsTable, List<CourseSession>>
  _courseSessionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.courseSessions,
    aliasName: 'courses__id__course_sessions__course_id',
  );

  $$CourseSessionsTableProcessedTableManager get courseSessionsRefs {
    final manager = $$CourseSessionsTableTableManager(
      $_db,
      $_db.courseSessions,
    ).filter((f) => f.courseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_courseSessionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CoursesTableFilterComposer
    extends Composer<_$AppDatabase, $CoursesTable> {
  $$CoursesTableFilterComposer({
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

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get teacher => $composableBuilder(
    column: $table.teacher,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get teachingClass => $composableBuilder(
    column: $table.teachingClass,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isLocallyModified => $composableBuilder(
    column: $table.isLocallyModified,
    builder: (column) => ColumnFilters(column),
  );

  $$SemestersTableFilterComposer get semesterId {
    final $$SemestersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.semesterId,
      referencedTable: $db.semesters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemestersTableFilterComposer(
            $db: $db,
            $table: $db.semesters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> courseSessionsRefs(
    Expression<bool> Function($$CourseSessionsTableFilterComposer f) f,
  ) {
    final $$CourseSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.courseSessions,
      getReferencedColumn: (t) => t.courseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseSessionsTableFilterComposer(
            $db: $db,
            $table: $db.courseSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CoursesTableOrderingComposer
    extends Composer<_$AppDatabase, $CoursesTable> {
  $$CoursesTableOrderingComposer({
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

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get teacher => $composableBuilder(
    column: $table.teacher,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get teachingClass => $composableBuilder(
    column: $table.teachingClass,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isLocallyModified => $composableBuilder(
    column: $table.isLocallyModified,
    builder: (column) => ColumnOrderings(column),
  );

  $$SemestersTableOrderingComposer get semesterId {
    final $$SemestersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.semesterId,
      referencedTable: $db.semesters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemestersTableOrderingComposer(
            $db: $db,
            $table: $db.semesters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CoursesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CoursesTable> {
  $$CoursesTableAnnotationComposer({
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

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get teacher =>
      $composableBuilder(column: $table.teacher, builder: (column) => column);

  GeneratedColumn<String> get teachingClass => $composableBuilder(
    column: $table.teachingClass,
    builder: (column) => column,
  );

  GeneratedColumn<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<bool> get isLocallyModified => $composableBuilder(
    column: $table.isLocallyModified,
    builder: (column) => column,
  );

  $$SemestersTableAnnotationComposer get semesterId {
    final $$SemestersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.semesterId,
      referencedTable: $db.semesters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemestersTableAnnotationComposer(
            $db: $db,
            $table: $db.semesters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> courseSessionsRefs<T extends Object>(
    Expression<T> Function($$CourseSessionsTableAnnotationComposer a) f,
  ) {
    final $$CourseSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.courseSessions,
      getReferencedColumn: (t) => t.courseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.courseSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CoursesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CoursesTable,
          Course,
          $$CoursesTableFilterComposer,
          $$CoursesTableOrderingComposer,
          $$CoursesTableAnnotationComposer,
          $$CoursesTableCreateCompanionBuilder,
          $$CoursesTableUpdateCompanionBuilder,
          (Course, $$CoursesTableReferences),
          Course,
          PrefetchHooks Function({bool semesterId, bool courseSessionsRefs})
        > {
  $$CoursesTableTableManager(_$AppDatabase db, $CoursesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CoursesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CoursesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CoursesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> semesterId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> code = const Value.absent(),
                Value<String?> teacher = const Value.absent(),
                Value<String?> teachingClass = const Value.absent(),
                Value<int> colorValue = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<bool> isLocallyModified = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CoursesCompanion(
                id: id,
                semesterId: semesterId,
                name: name,
                code: code,
                teacher: teacher,
                teachingClass: teachingClass,
                colorValue: colorValue,
                notes: notes,
                source: source,
                sourceId: sourceId,
                isLocallyModified: isLocallyModified,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String semesterId,
                required String name,
                Value<String?> code = const Value.absent(),
                Value<String?> teacher = const Value.absent(),
                Value<String?> teachingClass = const Value.absent(),
                required int colorValue,
                Value<String?> notes = const Value.absent(),
                required String source,
                Value<String?> sourceId = const Value.absent(),
                Value<bool> isLocallyModified = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CoursesCompanion.insert(
                id: id,
                semesterId: semesterId,
                name: name,
                code: code,
                teacher: teacher,
                teachingClass: teachingClass,
                colorValue: colorValue,
                notes: notes,
                source: source,
                sourceId: sourceId,
                isLocallyModified: isLocallyModified,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CoursesTable, Course>(table),
                  $$CoursesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({semesterId = false, courseSessionsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (courseSessionsRefs) db.courseSessions,
                  ],
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
                        if (semesterId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.semesterId,
                            referencedTable: $$CoursesTableReferences
                                ._semesterIdTable(db),
                            referencedColumn: $$CoursesTableReferences
                                ._semesterIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (courseSessionsRefs)
                        await $_getPrefetchedData<
                          Course,
                          $CoursesTable,
                          CourseSession
                        >(
                          currentTable: table,
                          referencedTable: $$CoursesTableReferences
                              ._courseSessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CoursesTableReferences(
                                db,
                                table,
                                p0,
                              ).courseSessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.courseId == item.id,
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

typedef $$CoursesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CoursesTable,
      Course,
      $$CoursesTableFilterComposer,
      $$CoursesTableOrderingComposer,
      $$CoursesTableAnnotationComposer,
      $$CoursesTableCreateCompanionBuilder,
      $$CoursesTableUpdateCompanionBuilder,
      (Course, $$CoursesTableReferences),
      Course,
      PrefetchHooks Function({bool semesterId, bool courseSessionsRefs})
    >;
typedef $$CourseSessionsTableCreateCompanionBuilder =
    CourseSessionsCompanion Function({
      required String id,
      required String courseId,
      required int weekday,
      required int startPeriod,
      required int endPeriod,
      Value<String?> location,
      required String weeks,
      Value<int> rowid,
    });
typedef $$CourseSessionsTableUpdateCompanionBuilder =
    CourseSessionsCompanion Function({
      Value<String> id,
      Value<String> courseId,
      Value<int> weekday,
      Value<int> startPeriod,
      Value<int> endPeriod,
      Value<String?> location,
      Value<String> weeks,
      Value<int> rowid,
    });

final class $$CourseSessionsTableReferences
    extends BaseReferences<_$AppDatabase, $CourseSessionsTable, CourseSession> {
  $$CourseSessionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CoursesTable _courseIdTable(_$AppDatabase db) =>
      db.courses.createAlias('course_sessions__course_id__courses__id');

  $$CoursesTableProcessedTableManager get courseId {
    final $_column = $_itemColumn<String>('course_id')!;

    final manager = $$CoursesTableTableManager(
      $_db,
      $_db.courses,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_courseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CourseSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $CourseSessionsTable> {
  $$CourseSessionsTableFilterComposer({
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

  ColumnFilters<int> get weekday => $composableBuilder(
    column: $table.weekday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startPeriod => $composableBuilder(
    column: $table.startPeriod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endPeriod => $composableBuilder(
    column: $table.endPeriod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weeks => $composableBuilder(
    column: $table.weeks,
    builder: (column) => ColumnFilters(column),
  );

  $$CoursesTableFilterComposer get courseId {
    final $$CoursesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableFilterComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CourseSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $CourseSessionsTable> {
  $$CourseSessionsTableOrderingComposer({
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

  ColumnOrderings<int> get weekday => $composableBuilder(
    column: $table.weekday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startPeriod => $composableBuilder(
    column: $table.startPeriod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endPeriod => $composableBuilder(
    column: $table.endPeriod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weeks => $composableBuilder(
    column: $table.weeks,
    builder: (column) => ColumnOrderings(column),
  );

  $$CoursesTableOrderingComposer get courseId {
    final $$CoursesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableOrderingComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CourseSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CourseSessionsTable> {
  $$CourseSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get weekday =>
      $composableBuilder(column: $table.weekday, builder: (column) => column);

  GeneratedColumn<int> get startPeriod => $composableBuilder(
    column: $table.startPeriod,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endPeriod =>
      $composableBuilder(column: $table.endPeriod, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get weeks =>
      $composableBuilder(column: $table.weeks, builder: (column) => column);

  $$CoursesTableAnnotationComposer get courseId {
    final $$CoursesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableAnnotationComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CourseSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CourseSessionsTable,
          CourseSession,
          $$CourseSessionsTableFilterComposer,
          $$CourseSessionsTableOrderingComposer,
          $$CourseSessionsTableAnnotationComposer,
          $$CourseSessionsTableCreateCompanionBuilder,
          $$CourseSessionsTableUpdateCompanionBuilder,
          (CourseSession, $$CourseSessionsTableReferences),
          CourseSession,
          PrefetchHooks Function({bool courseId})
        > {
  $$CourseSessionsTableTableManager(
    _$AppDatabase db,
    $CourseSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CourseSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CourseSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CourseSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> courseId = const Value.absent(),
                Value<int> weekday = const Value.absent(),
                Value<int> startPeriod = const Value.absent(),
                Value<int> endPeriod = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String> weeks = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CourseSessionsCompanion(
                id: id,
                courseId: courseId,
                weekday: weekday,
                startPeriod: startPeriod,
                endPeriod: endPeriod,
                location: location,
                weeks: weeks,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String courseId,
                required int weekday,
                required int startPeriod,
                required int endPeriod,
                Value<String?> location = const Value.absent(),
                required String weeks,
                Value<int> rowid = const Value.absent(),
              }) => CourseSessionsCompanion.insert(
                id: id,
                courseId: courseId,
                weekday: weekday,
                startPeriod: startPeriod,
                endPeriod: endPeriod,
                location: location,
                weeks: weeks,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CourseSessionsTable, CourseSession>(table),
                  $$CourseSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({courseId = false}) {
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
                    if (courseId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.courseId,
                        referencedTable: $$CourseSessionsTableReferences
                            ._courseIdTable(db),
                        referencedColumn: $$CourseSessionsTableReferences
                            ._courseIdTable(db)
                            .id,
                      ) as T;
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

typedef $$CourseSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CourseSessionsTable,
      CourseSession,
      $$CourseSessionsTableFilterComposer,
      $$CourseSessionsTableOrderingComposer,
      $$CourseSessionsTableAnnotationComposer,
      $$CourseSessionsTableCreateCompanionBuilder,
      $$CourseSessionsTableUpdateCompanionBuilder,
      (CourseSession, $$CourseSessionsTableReferences),
      CourseSession,
      PrefetchHooks Function({bool courseId})
    >;
typedef $$PeriodDefinitionsTableCreateCompanionBuilder =
    PeriodDefinitionsCompanion Function({
      required String id,
      required String semesterId,
      required int period,
      required String startTime,
      required String endTime,
      required String periodGroup,
      Value<int> rowid,
    });
typedef $$PeriodDefinitionsTableUpdateCompanionBuilder =
    PeriodDefinitionsCompanion Function({
      Value<String> id,
      Value<String> semesterId,
      Value<int> period,
      Value<String> startTime,
      Value<String> endTime,
      Value<String> periodGroup,
      Value<int> rowid,
    });

final class $$PeriodDefinitionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $PeriodDefinitionsTable,
          PeriodDefinition
        > {
  $$PeriodDefinitionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SemestersTable _semesterIdTable(_$AppDatabase db) => db.semesters
      .createAlias('period_definitions__semester_id__semesters__id');

  $$SemestersTableProcessedTableManager get semesterId {
    final $_column = $_itemColumn<String>('semester_id')!;

    final manager = $$SemestersTableTableManager(
      $_db,
      $_db.semesters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_semesterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PeriodDefinitionsTableFilterComposer
    extends Composer<_$AppDatabase, $PeriodDefinitionsTable> {
  $$PeriodDefinitionsTableFilterComposer({
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

  ColumnFilters<int> get period => $composableBuilder(
    column: $table.period,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get periodGroup => $composableBuilder(
    column: $table.periodGroup,
    builder: (column) => ColumnFilters(column),
  );

  $$SemestersTableFilterComposer get semesterId {
    final $$SemestersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.semesterId,
      referencedTable: $db.semesters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemestersTableFilterComposer(
            $db: $db,
            $table: $db.semesters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PeriodDefinitionsTableOrderingComposer
    extends Composer<_$AppDatabase, $PeriodDefinitionsTable> {
  $$PeriodDefinitionsTableOrderingComposer({
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

  ColumnOrderings<int> get period => $composableBuilder(
    column: $table.period,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get periodGroup => $composableBuilder(
    column: $table.periodGroup,
    builder: (column) => ColumnOrderings(column),
  );

  $$SemestersTableOrderingComposer get semesterId {
    final $$SemestersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.semesterId,
      referencedTable: $db.semesters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemestersTableOrderingComposer(
            $db: $db,
            $table: $db.semesters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PeriodDefinitionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PeriodDefinitionsTable> {
  $$PeriodDefinitionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get period =>
      $composableBuilder(column: $table.period, builder: (column) => column);

  GeneratedColumn<String> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<String> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<String> get periodGroup => $composableBuilder(
    column: $table.periodGroup,
    builder: (column) => column,
  );

  $$SemestersTableAnnotationComposer get semesterId {
    final $$SemestersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.semesterId,
      referencedTable: $db.semesters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemestersTableAnnotationComposer(
            $db: $db,
            $table: $db.semesters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PeriodDefinitionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PeriodDefinitionsTable,
          PeriodDefinition,
          $$PeriodDefinitionsTableFilterComposer,
          $$PeriodDefinitionsTableOrderingComposer,
          $$PeriodDefinitionsTableAnnotationComposer,
          $$PeriodDefinitionsTableCreateCompanionBuilder,
          $$PeriodDefinitionsTableUpdateCompanionBuilder,
          (PeriodDefinition, $$PeriodDefinitionsTableReferences),
          PeriodDefinition,
          PrefetchHooks Function({bool semesterId})
        > {
  $$PeriodDefinitionsTableTableManager(
    _$AppDatabase db,
    $PeriodDefinitionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PeriodDefinitionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PeriodDefinitionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PeriodDefinitionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> semesterId = const Value.absent(),
                Value<int> period = const Value.absent(),
                Value<String> startTime = const Value.absent(),
                Value<String> endTime = const Value.absent(),
                Value<String> periodGroup = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PeriodDefinitionsCompanion(
                id: id,
                semesterId: semesterId,
                period: period,
                startTime: startTime,
                endTime: endTime,
                periodGroup: periodGroup,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String semesterId,
                required int period,
                required String startTime,
                required String endTime,
                required String periodGroup,
                Value<int> rowid = const Value.absent(),
              }) => PeriodDefinitionsCompanion.insert(
                id: id,
                semesterId: semesterId,
                period: period,
                startTime: startTime,
                endTime: endTime,
                periodGroup: periodGroup,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PeriodDefinitionsTable, PeriodDefinition>(table),
                  $$PeriodDefinitionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({semesterId = false}) {
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
                    if (semesterId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.semesterId,
                        referencedTable: $$PeriodDefinitionsTableReferences
                            ._semesterIdTable(db),
                        referencedColumn: $$PeriodDefinitionsTableReferences
                            ._semesterIdTable(db)
                            .id,
                      ) as T;
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

typedef $$PeriodDefinitionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PeriodDefinitionsTable,
      PeriodDefinition,
      $$PeriodDefinitionsTableFilterComposer,
      $$PeriodDefinitionsTableOrderingComposer,
      $$PeriodDefinitionsTableAnnotationComposer,
      $$PeriodDefinitionsTableCreateCompanionBuilder,
      $$PeriodDefinitionsTableUpdateCompanionBuilder,
      (PeriodDefinition, $$PeriodDefinitionsTableReferences),
      PeriodDefinition,
      PrefetchHooks Function({bool semesterId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SemestersTableTableManager get semesters =>
      $$SemestersTableTableManager(_db, _db.semesters);
  $$CoursesTableTableManager get courses =>
      $$CoursesTableTableManager(_db, _db.courses);
  $$CourseSessionsTableTableManager get courseSessions =>
      $$CourseSessionsTableTableManager(_db, _db.courseSessions);
  $$PeriodDefinitionsTableTableManager get periodDefinitions =>
      $$PeriodDefinitionsTableTableManager(_db, _db.periodDefinitions);
}
