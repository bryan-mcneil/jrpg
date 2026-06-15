// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $KanjiEntriesTable extends KanjiEntries
    with TableInfo<$KanjiEntriesTable, KanjiEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KanjiEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _literalMeta = const VerificationMeta(
    'literal',
  );
  @override
  late final GeneratedColumn<String> literal = GeneratedColumn<String>(
    'literal',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _strokeCountMeta = const VerificationMeta(
    'strokeCount',
  );
  @override
  late final GeneratedColumn<int> strokeCount = GeneratedColumn<int>(
    'stroke_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gradeMeta = const VerificationMeta('grade');
  @override
  late final GeneratedColumn<int> grade = GeneratedColumn<int>(
    'grade',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _freqMeta = const VerificationMeta('freq');
  @override
  late final GeneratedColumn<int> freq = GeneratedColumn<int>(
    'freq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _meaningsMeta = const VerificationMeta(
    'meanings',
  );
  @override
  late final GeneratedColumn<String> meanings = GeneratedColumn<String>(
    'meanings',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _onReadingsMeta = const VerificationMeta(
    'onReadings',
  );
  @override
  late final GeneratedColumn<String> onReadings = GeneratedColumn<String>(
    'on_readings',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kunReadingsMeta = const VerificationMeta(
    'kunReadings',
  );
  @override
  late final GeneratedColumn<String> kunReadings = GeneratedColumn<String>(
    'kun_readings',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _componentsMeta = const VerificationMeta(
    'components',
  );
  @override
  late final GeneratedColumn<String> components = GeneratedColumn<String>(
    'components',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tagMeta = const VerificationMeta('tag');
  @override
  late final GeneratedColumn<String> tag = GeneratedColumn<String>(
    'tag',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _strokesMeta = const VerificationMeta(
    'strokes',
  );
  @override
  late final GeneratedColumn<String> strokes = GeneratedColumn<String>(
    'strokes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    literal,
    strokeCount,
    grade,
    freq,
    level,
    meanings,
    onReadings,
    kunReadings,
    components,
    tag,
    strokes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'kanji_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<KanjiEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('literal')) {
      context.handle(
        _literalMeta,
        literal.isAcceptableOrUnknown(data['literal']!, _literalMeta),
      );
    } else if (isInserting) {
      context.missing(_literalMeta);
    }
    if (data.containsKey('stroke_count')) {
      context.handle(
        _strokeCountMeta,
        strokeCount.isAcceptableOrUnknown(
          data['stroke_count']!,
          _strokeCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_strokeCountMeta);
    }
    if (data.containsKey('grade')) {
      context.handle(
        _gradeMeta,
        grade.isAcceptableOrUnknown(data['grade']!, _gradeMeta),
      );
    }
    if (data.containsKey('freq')) {
      context.handle(
        _freqMeta,
        freq.isAcceptableOrUnknown(data['freq']!, _freqMeta),
      );
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('meanings')) {
      context.handle(
        _meaningsMeta,
        meanings.isAcceptableOrUnknown(data['meanings']!, _meaningsMeta),
      );
    } else if (isInserting) {
      context.missing(_meaningsMeta);
    }
    if (data.containsKey('on_readings')) {
      context.handle(
        _onReadingsMeta,
        onReadings.isAcceptableOrUnknown(data['on_readings']!, _onReadingsMeta),
      );
    } else if (isInserting) {
      context.missing(_onReadingsMeta);
    }
    if (data.containsKey('kun_readings')) {
      context.handle(
        _kunReadingsMeta,
        kunReadings.isAcceptableOrUnknown(
          data['kun_readings']!,
          _kunReadingsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_kunReadingsMeta);
    }
    if (data.containsKey('components')) {
      context.handle(
        _componentsMeta,
        components.isAcceptableOrUnknown(data['components']!, _componentsMeta),
      );
    } else if (isInserting) {
      context.missing(_componentsMeta);
    }
    if (data.containsKey('tag')) {
      context.handle(
        _tagMeta,
        tag.isAcceptableOrUnknown(data['tag']!, _tagMeta),
      );
    } else if (isInserting) {
      context.missing(_tagMeta);
    }
    if (data.containsKey('strokes')) {
      context.handle(
        _strokesMeta,
        strokes.isAcceptableOrUnknown(data['strokes']!, _strokesMeta),
      );
    } else if (isInserting) {
      context.missing(_strokesMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {literal};
  @override
  KanjiEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KanjiEntry(
      literal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}literal'],
      )!,
      strokeCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stroke_count'],
      )!,
      grade: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}grade'],
      ),
      freq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}freq'],
      ),
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      )!,
      meanings: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meanings'],
      )!,
      onReadings: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}on_readings'],
      )!,
      kunReadings: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kun_readings'],
      )!,
      components: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}components'],
      )!,
      tag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag'],
      )!,
      strokes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}strokes'],
      )!,
    );
  }

  @override
  $KanjiEntriesTable createAlias(String alias) {
    return $KanjiEntriesTable(attachedDatabase, alias);
  }
}

class KanjiEntry extends DataClass implements Insertable<KanjiEntry> {
  final String literal;
  final int strokeCount;
  final int? grade;
  final int? freq;

  /// JLPT level: 5 = N5 … 1 = N1.
  final int level;
  final String meanings;
  final String onReadings;
  final String kunReadings;
  final String components;

  /// Element (fire/water/wood/earth/metal/light/dark) or modifier class
  /// (storm/blade/ward/amp/orb/mend) — the magic-grammar tag.
  final String tag;

  /// JSON list of KanjiVG SVG path strings in stroke order (109×109 space).
  final String strokes;
  const KanjiEntry({
    required this.literal,
    required this.strokeCount,
    this.grade,
    this.freq,
    required this.level,
    required this.meanings,
    required this.onReadings,
    required this.kunReadings,
    required this.components,
    required this.tag,
    required this.strokes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['literal'] = Variable<String>(literal);
    map['stroke_count'] = Variable<int>(strokeCount);
    if (!nullToAbsent || grade != null) {
      map['grade'] = Variable<int>(grade);
    }
    if (!nullToAbsent || freq != null) {
      map['freq'] = Variable<int>(freq);
    }
    map['level'] = Variable<int>(level);
    map['meanings'] = Variable<String>(meanings);
    map['on_readings'] = Variable<String>(onReadings);
    map['kun_readings'] = Variable<String>(kunReadings);
    map['components'] = Variable<String>(components);
    map['tag'] = Variable<String>(tag);
    map['strokes'] = Variable<String>(strokes);
    return map;
  }

  KanjiEntriesCompanion toCompanion(bool nullToAbsent) {
    return KanjiEntriesCompanion(
      literal: Value(literal),
      strokeCount: Value(strokeCount),
      grade: grade == null && nullToAbsent
          ? const Value.absent()
          : Value(grade),
      freq: freq == null && nullToAbsent ? const Value.absent() : Value(freq),
      level: Value(level),
      meanings: Value(meanings),
      onReadings: Value(onReadings),
      kunReadings: Value(kunReadings),
      components: Value(components),
      tag: Value(tag),
      strokes: Value(strokes),
    );
  }

  factory KanjiEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KanjiEntry(
      literal: serializer.fromJson<String>(json['literal']),
      strokeCount: serializer.fromJson<int>(json['strokeCount']),
      grade: serializer.fromJson<int?>(json['grade']),
      freq: serializer.fromJson<int?>(json['freq']),
      level: serializer.fromJson<int>(json['level']),
      meanings: serializer.fromJson<String>(json['meanings']),
      onReadings: serializer.fromJson<String>(json['onReadings']),
      kunReadings: serializer.fromJson<String>(json['kunReadings']),
      components: serializer.fromJson<String>(json['components']),
      tag: serializer.fromJson<String>(json['tag']),
      strokes: serializer.fromJson<String>(json['strokes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'literal': serializer.toJson<String>(literal),
      'strokeCount': serializer.toJson<int>(strokeCount),
      'grade': serializer.toJson<int?>(grade),
      'freq': serializer.toJson<int?>(freq),
      'level': serializer.toJson<int>(level),
      'meanings': serializer.toJson<String>(meanings),
      'onReadings': serializer.toJson<String>(onReadings),
      'kunReadings': serializer.toJson<String>(kunReadings),
      'components': serializer.toJson<String>(components),
      'tag': serializer.toJson<String>(tag),
      'strokes': serializer.toJson<String>(strokes),
    };
  }

  KanjiEntry copyWith({
    String? literal,
    int? strokeCount,
    Value<int?> grade = const Value.absent(),
    Value<int?> freq = const Value.absent(),
    int? level,
    String? meanings,
    String? onReadings,
    String? kunReadings,
    String? components,
    String? tag,
    String? strokes,
  }) => KanjiEntry(
    literal: literal ?? this.literal,
    strokeCount: strokeCount ?? this.strokeCount,
    grade: grade.present ? grade.value : this.grade,
    freq: freq.present ? freq.value : this.freq,
    level: level ?? this.level,
    meanings: meanings ?? this.meanings,
    onReadings: onReadings ?? this.onReadings,
    kunReadings: kunReadings ?? this.kunReadings,
    components: components ?? this.components,
    tag: tag ?? this.tag,
    strokes: strokes ?? this.strokes,
  );
  KanjiEntry copyWithCompanion(KanjiEntriesCompanion data) {
    return KanjiEntry(
      literal: data.literal.present ? data.literal.value : this.literal,
      strokeCount: data.strokeCount.present
          ? data.strokeCount.value
          : this.strokeCount,
      grade: data.grade.present ? data.grade.value : this.grade,
      freq: data.freq.present ? data.freq.value : this.freq,
      level: data.level.present ? data.level.value : this.level,
      meanings: data.meanings.present ? data.meanings.value : this.meanings,
      onReadings: data.onReadings.present
          ? data.onReadings.value
          : this.onReadings,
      kunReadings: data.kunReadings.present
          ? data.kunReadings.value
          : this.kunReadings,
      components: data.components.present
          ? data.components.value
          : this.components,
      tag: data.tag.present ? data.tag.value : this.tag,
      strokes: data.strokes.present ? data.strokes.value : this.strokes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KanjiEntry(')
          ..write('literal: $literal, ')
          ..write('strokeCount: $strokeCount, ')
          ..write('grade: $grade, ')
          ..write('freq: $freq, ')
          ..write('level: $level, ')
          ..write('meanings: $meanings, ')
          ..write('onReadings: $onReadings, ')
          ..write('kunReadings: $kunReadings, ')
          ..write('components: $components, ')
          ..write('tag: $tag, ')
          ..write('strokes: $strokes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    literal,
    strokeCount,
    grade,
    freq,
    level,
    meanings,
    onReadings,
    kunReadings,
    components,
    tag,
    strokes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KanjiEntry &&
          other.literal == this.literal &&
          other.strokeCount == this.strokeCount &&
          other.grade == this.grade &&
          other.freq == this.freq &&
          other.level == this.level &&
          other.meanings == this.meanings &&
          other.onReadings == this.onReadings &&
          other.kunReadings == this.kunReadings &&
          other.components == this.components &&
          other.tag == this.tag &&
          other.strokes == this.strokes);
}

class KanjiEntriesCompanion extends UpdateCompanion<KanjiEntry> {
  final Value<String> literal;
  final Value<int> strokeCount;
  final Value<int?> grade;
  final Value<int?> freq;
  final Value<int> level;
  final Value<String> meanings;
  final Value<String> onReadings;
  final Value<String> kunReadings;
  final Value<String> components;
  final Value<String> tag;
  final Value<String> strokes;
  final Value<int> rowid;
  const KanjiEntriesCompanion({
    this.literal = const Value.absent(),
    this.strokeCount = const Value.absent(),
    this.grade = const Value.absent(),
    this.freq = const Value.absent(),
    this.level = const Value.absent(),
    this.meanings = const Value.absent(),
    this.onReadings = const Value.absent(),
    this.kunReadings = const Value.absent(),
    this.components = const Value.absent(),
    this.tag = const Value.absent(),
    this.strokes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KanjiEntriesCompanion.insert({
    required String literal,
    required int strokeCount,
    this.grade = const Value.absent(),
    this.freq = const Value.absent(),
    required int level,
    required String meanings,
    required String onReadings,
    required String kunReadings,
    required String components,
    required String tag,
    required String strokes,
    this.rowid = const Value.absent(),
  }) : literal = Value(literal),
       strokeCount = Value(strokeCount),
       level = Value(level),
       meanings = Value(meanings),
       onReadings = Value(onReadings),
       kunReadings = Value(kunReadings),
       components = Value(components),
       tag = Value(tag),
       strokes = Value(strokes);
  static Insertable<KanjiEntry> custom({
    Expression<String>? literal,
    Expression<int>? strokeCount,
    Expression<int>? grade,
    Expression<int>? freq,
    Expression<int>? level,
    Expression<String>? meanings,
    Expression<String>? onReadings,
    Expression<String>? kunReadings,
    Expression<String>? components,
    Expression<String>? tag,
    Expression<String>? strokes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (literal != null) 'literal': literal,
      if (strokeCount != null) 'stroke_count': strokeCount,
      if (grade != null) 'grade': grade,
      if (freq != null) 'freq': freq,
      if (level != null) 'level': level,
      if (meanings != null) 'meanings': meanings,
      if (onReadings != null) 'on_readings': onReadings,
      if (kunReadings != null) 'kun_readings': kunReadings,
      if (components != null) 'components': components,
      if (tag != null) 'tag': tag,
      if (strokes != null) 'strokes': strokes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KanjiEntriesCompanion copyWith({
    Value<String>? literal,
    Value<int>? strokeCount,
    Value<int?>? grade,
    Value<int?>? freq,
    Value<int>? level,
    Value<String>? meanings,
    Value<String>? onReadings,
    Value<String>? kunReadings,
    Value<String>? components,
    Value<String>? tag,
    Value<String>? strokes,
    Value<int>? rowid,
  }) {
    return KanjiEntriesCompanion(
      literal: literal ?? this.literal,
      strokeCount: strokeCount ?? this.strokeCount,
      grade: grade ?? this.grade,
      freq: freq ?? this.freq,
      level: level ?? this.level,
      meanings: meanings ?? this.meanings,
      onReadings: onReadings ?? this.onReadings,
      kunReadings: kunReadings ?? this.kunReadings,
      components: components ?? this.components,
      tag: tag ?? this.tag,
      strokes: strokes ?? this.strokes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (literal.present) {
      map['literal'] = Variable<String>(literal.value);
    }
    if (strokeCount.present) {
      map['stroke_count'] = Variable<int>(strokeCount.value);
    }
    if (grade.present) {
      map['grade'] = Variable<int>(grade.value);
    }
    if (freq.present) {
      map['freq'] = Variable<int>(freq.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (meanings.present) {
      map['meanings'] = Variable<String>(meanings.value);
    }
    if (onReadings.present) {
      map['on_readings'] = Variable<String>(onReadings.value);
    }
    if (kunReadings.present) {
      map['kun_readings'] = Variable<String>(kunReadings.value);
    }
    if (components.present) {
      map['components'] = Variable<String>(components.value);
    }
    if (tag.present) {
      map['tag'] = Variable<String>(tag.value);
    }
    if (strokes.present) {
      map['strokes'] = Variable<String>(strokes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KanjiEntriesCompanion(')
          ..write('literal: $literal, ')
          ..write('strokeCount: $strokeCount, ')
          ..write('grade: $grade, ')
          ..write('freq: $freq, ')
          ..write('level: $level, ')
          ..write('meanings: $meanings, ')
          ..write('onReadings: $onReadings, ')
          ..write('kunReadings: $kunReadings, ')
          ..write('components: $components, ')
          ..write('tag: $tag, ')
          ..write('strokes: $strokes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VocabEntriesTable extends VocabEntries
    with TableInfo<$VocabEntriesTable, VocabEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VocabEntriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _wordMeta = const VerificationMeta('word');
  @override
  late final GeneratedColumn<String> word = GeneratedColumn<String>(
    'word',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _readingMeta = const VerificationMeta(
    'reading',
  );
  @override
  late final GeneratedColumn<String> reading = GeneratedColumn<String>(
    'reading',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _glossesMeta = const VerificationMeta(
    'glosses',
  );
  @override
  late final GeneratedColumn<String> glosses = GeneratedColumn<String>(
    'glosses',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _posMeta = const VerificationMeta('pos');
  @override
  late final GeneratedColumn<String> pos = GeneratedColumn<String>(
    'pos',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rankMeta = const VerificationMeta('rank');
  @override
  late final GeneratedColumn<int> rank = GeneratedColumn<int>(
    'rank',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    word,
    reading,
    glosses,
    pos,
    level,
    rank,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vocab_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<VocabEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('word')) {
      context.handle(
        _wordMeta,
        word.isAcceptableOrUnknown(data['word']!, _wordMeta),
      );
    } else if (isInserting) {
      context.missing(_wordMeta);
    }
    if (data.containsKey('reading')) {
      context.handle(
        _readingMeta,
        reading.isAcceptableOrUnknown(data['reading']!, _readingMeta),
      );
    } else if (isInserting) {
      context.missing(_readingMeta);
    }
    if (data.containsKey('glosses')) {
      context.handle(
        _glossesMeta,
        glosses.isAcceptableOrUnknown(data['glosses']!, _glossesMeta),
      );
    } else if (isInserting) {
      context.missing(_glossesMeta);
    }
    if (data.containsKey('pos')) {
      context.handle(
        _posMeta,
        pos.isAcceptableOrUnknown(data['pos']!, _posMeta),
      );
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('rank')) {
      context.handle(
        _rankMeta,
        rank.isAcceptableOrUnknown(data['rank']!, _rankMeta),
      );
    } else if (isInserting) {
      context.missing(_rankMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VocabEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VocabEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      word: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word'],
      )!,
      reading: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reading'],
      )!,
      glosses: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}glosses'],
      )!,
      pos: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pos'],
      ),
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      )!,
      rank: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rank'],
      )!,
    );
  }

  @override
  $VocabEntriesTable createAlias(String alias) {
    return $VocabEntriesTable(attachedDatabase, alias);
  }
}

class VocabEntry extends DataClass implements Insertable<VocabEntry> {
  final int id;
  final String word;
  final String reading;

  /// JSON-encoded string list.
  final String glosses;
  final String? pos;
  final int level;

  /// JMdict priority rank; lower = more common.
  final int rank;
  const VocabEntry({
    required this.id,
    required this.word,
    required this.reading,
    required this.glosses,
    this.pos,
    required this.level,
    required this.rank,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['word'] = Variable<String>(word);
    map['reading'] = Variable<String>(reading);
    map['glosses'] = Variable<String>(glosses);
    if (!nullToAbsent || pos != null) {
      map['pos'] = Variable<String>(pos);
    }
    map['level'] = Variable<int>(level);
    map['rank'] = Variable<int>(rank);
    return map;
  }

  VocabEntriesCompanion toCompanion(bool nullToAbsent) {
    return VocabEntriesCompanion(
      id: Value(id),
      word: Value(word),
      reading: Value(reading),
      glosses: Value(glosses),
      pos: pos == null && nullToAbsent ? const Value.absent() : Value(pos),
      level: Value(level),
      rank: Value(rank),
    );
  }

  factory VocabEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VocabEntry(
      id: serializer.fromJson<int>(json['id']),
      word: serializer.fromJson<String>(json['word']),
      reading: serializer.fromJson<String>(json['reading']),
      glosses: serializer.fromJson<String>(json['glosses']),
      pos: serializer.fromJson<String?>(json['pos']),
      level: serializer.fromJson<int>(json['level']),
      rank: serializer.fromJson<int>(json['rank']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'word': serializer.toJson<String>(word),
      'reading': serializer.toJson<String>(reading),
      'glosses': serializer.toJson<String>(glosses),
      'pos': serializer.toJson<String?>(pos),
      'level': serializer.toJson<int>(level),
      'rank': serializer.toJson<int>(rank),
    };
  }

  VocabEntry copyWith({
    int? id,
    String? word,
    String? reading,
    String? glosses,
    Value<String?> pos = const Value.absent(),
    int? level,
    int? rank,
  }) => VocabEntry(
    id: id ?? this.id,
    word: word ?? this.word,
    reading: reading ?? this.reading,
    glosses: glosses ?? this.glosses,
    pos: pos.present ? pos.value : this.pos,
    level: level ?? this.level,
    rank: rank ?? this.rank,
  );
  VocabEntry copyWithCompanion(VocabEntriesCompanion data) {
    return VocabEntry(
      id: data.id.present ? data.id.value : this.id,
      word: data.word.present ? data.word.value : this.word,
      reading: data.reading.present ? data.reading.value : this.reading,
      glosses: data.glosses.present ? data.glosses.value : this.glosses,
      pos: data.pos.present ? data.pos.value : this.pos,
      level: data.level.present ? data.level.value : this.level,
      rank: data.rank.present ? data.rank.value : this.rank,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VocabEntry(')
          ..write('id: $id, ')
          ..write('word: $word, ')
          ..write('reading: $reading, ')
          ..write('glosses: $glosses, ')
          ..write('pos: $pos, ')
          ..write('level: $level, ')
          ..write('rank: $rank')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, word, reading, glosses, pos, level, rank);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VocabEntry &&
          other.id == this.id &&
          other.word == this.word &&
          other.reading == this.reading &&
          other.glosses == this.glosses &&
          other.pos == this.pos &&
          other.level == this.level &&
          other.rank == this.rank);
}

class VocabEntriesCompanion extends UpdateCompanion<VocabEntry> {
  final Value<int> id;
  final Value<String> word;
  final Value<String> reading;
  final Value<String> glosses;
  final Value<String?> pos;
  final Value<int> level;
  final Value<int> rank;
  const VocabEntriesCompanion({
    this.id = const Value.absent(),
    this.word = const Value.absent(),
    this.reading = const Value.absent(),
    this.glosses = const Value.absent(),
    this.pos = const Value.absent(),
    this.level = const Value.absent(),
    this.rank = const Value.absent(),
  });
  VocabEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String word,
    required String reading,
    required String glosses,
    this.pos = const Value.absent(),
    required int level,
    required int rank,
  }) : word = Value(word),
       reading = Value(reading),
       glosses = Value(glosses),
       level = Value(level),
       rank = Value(rank);
  static Insertable<VocabEntry> custom({
    Expression<int>? id,
    Expression<String>? word,
    Expression<String>? reading,
    Expression<String>? glosses,
    Expression<String>? pos,
    Expression<int>? level,
    Expression<int>? rank,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (word != null) 'word': word,
      if (reading != null) 'reading': reading,
      if (glosses != null) 'glosses': glosses,
      if (pos != null) 'pos': pos,
      if (level != null) 'level': level,
      if (rank != null) 'rank': rank,
    });
  }

  VocabEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? word,
    Value<String>? reading,
    Value<String>? glosses,
    Value<String?>? pos,
    Value<int>? level,
    Value<int>? rank,
  }) {
    return VocabEntriesCompanion(
      id: id ?? this.id,
      word: word ?? this.word,
      reading: reading ?? this.reading,
      glosses: glosses ?? this.glosses,
      pos: pos ?? this.pos,
      level: level ?? this.level,
      rank: rank ?? this.rank,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (word.present) {
      map['word'] = Variable<String>(word.value);
    }
    if (reading.present) {
      map['reading'] = Variable<String>(reading.value);
    }
    if (glosses.present) {
      map['glosses'] = Variable<String>(glosses.value);
    }
    if (pos.present) {
      map['pos'] = Variable<String>(pos.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (rank.present) {
      map['rank'] = Variable<int>(rank.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VocabEntriesCompanion(')
          ..write('id: $id, ')
          ..write('word: $word, ')
          ..write('reading: $reading, ')
          ..write('glosses: $glosses, ')
          ..write('pos: $pos, ')
          ..write('level: $level, ')
          ..write('rank: $rank')
          ..write(')'))
        .toString();
  }
}

class $SrsCardsTable extends SrsCards with TableInfo<$SrsCardsTable, SrsCard> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SrsCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _literalMeta = const VerificationMeta(
    'literal',
  );
  @override
  late final GeneratedColumn<String> literal = GeneratedColumn<String>(
    'literal',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES kanji_entries (literal)',
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
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<int> state = GeneratedColumn<int>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stepMeta = const VerificationMeta('step');
  @override
  late final GeneratedColumn<int> step = GeneratedColumn<int>(
    'step',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stabilityMeta = const VerificationMeta(
    'stability',
  );
  @override
  late final GeneratedColumn<double> stability = GeneratedColumn<double>(
    'stability',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<double> difficulty = GeneratedColumn<double>(
    'difficulty',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueMeta = const VerificationMeta('due');
  @override
  late final GeneratedColumn<DateTime> due = GeneratedColumn<DateTime>(
    'due',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastReviewMeta = const VerificationMeta(
    'lastReview',
  );
  @override
  late final GeneratedColumn<DateTime> lastReview = GeneratedColumn<DateTime>(
    'last_review',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    literal,
    cardId,
    state,
    step,
    stability,
    difficulty,
    due,
    lastReview,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'srs_cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<SrsCard> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('literal')) {
      context.handle(
        _literalMeta,
        literal.isAcceptableOrUnknown(data['literal']!, _literalMeta),
      );
    } else if (isInserting) {
      context.missing(_literalMeta);
    }
    if (data.containsKey('card_id')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('step')) {
      context.handle(
        _stepMeta,
        step.isAcceptableOrUnknown(data['step']!, _stepMeta),
      );
    }
    if (data.containsKey('stability')) {
      context.handle(
        _stabilityMeta,
        stability.isAcceptableOrUnknown(data['stability']!, _stabilityMeta),
      );
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    }
    if (data.containsKey('due')) {
      context.handle(
        _dueMeta,
        due.isAcceptableOrUnknown(data['due']!, _dueMeta),
      );
    } else if (isInserting) {
      context.missing(_dueMeta);
    }
    if (data.containsKey('last_review')) {
      context.handle(
        _lastReviewMeta,
        lastReview.isAcceptableOrUnknown(data['last_review']!, _lastReviewMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {literal};
  @override
  SrsCard map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SrsCard(
      literal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}literal'],
      )!,
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}card_id'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}state'],
      )!,
      step: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}step'],
      ),
      stability: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}stability'],
      ),
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}difficulty'],
      ),
      due: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due'],
      )!,
      lastReview: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_review'],
      ),
    );
  }

  @override
  $SrsCardsTable createAlias(String alias) {
    return $SrsCardsTable(attachedDatabase, alias);
  }
}

class SrsCard extends DataClass implements Insertable<SrsCard> {
  final String literal;
  final int cardId;
  final int state;
  final int? step;
  final double? stability;
  final double? difficulty;
  final DateTime due;
  final DateTime? lastReview;
  const SrsCard({
    required this.literal,
    required this.cardId,
    required this.state,
    this.step,
    this.stability,
    this.difficulty,
    required this.due,
    this.lastReview,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['literal'] = Variable<String>(literal);
    map['card_id'] = Variable<int>(cardId);
    map['state'] = Variable<int>(state);
    if (!nullToAbsent || step != null) {
      map['step'] = Variable<int>(step);
    }
    if (!nullToAbsent || stability != null) {
      map['stability'] = Variable<double>(stability);
    }
    if (!nullToAbsent || difficulty != null) {
      map['difficulty'] = Variable<double>(difficulty);
    }
    map['due'] = Variable<DateTime>(due);
    if (!nullToAbsent || lastReview != null) {
      map['last_review'] = Variable<DateTime>(lastReview);
    }
    return map;
  }

  SrsCardsCompanion toCompanion(bool nullToAbsent) {
    return SrsCardsCompanion(
      literal: Value(literal),
      cardId: Value(cardId),
      state: Value(state),
      step: step == null && nullToAbsent ? const Value.absent() : Value(step),
      stability: stability == null && nullToAbsent
          ? const Value.absent()
          : Value(stability),
      difficulty: difficulty == null && nullToAbsent
          ? const Value.absent()
          : Value(difficulty),
      due: Value(due),
      lastReview: lastReview == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReview),
    );
  }

  factory SrsCard.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SrsCard(
      literal: serializer.fromJson<String>(json['literal']),
      cardId: serializer.fromJson<int>(json['cardId']),
      state: serializer.fromJson<int>(json['state']),
      step: serializer.fromJson<int?>(json['step']),
      stability: serializer.fromJson<double?>(json['stability']),
      difficulty: serializer.fromJson<double?>(json['difficulty']),
      due: serializer.fromJson<DateTime>(json['due']),
      lastReview: serializer.fromJson<DateTime?>(json['lastReview']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'literal': serializer.toJson<String>(literal),
      'cardId': serializer.toJson<int>(cardId),
      'state': serializer.toJson<int>(state),
      'step': serializer.toJson<int?>(step),
      'stability': serializer.toJson<double?>(stability),
      'difficulty': serializer.toJson<double?>(difficulty),
      'due': serializer.toJson<DateTime>(due),
      'lastReview': serializer.toJson<DateTime?>(lastReview),
    };
  }

  SrsCard copyWith({
    String? literal,
    int? cardId,
    int? state,
    Value<int?> step = const Value.absent(),
    Value<double?> stability = const Value.absent(),
    Value<double?> difficulty = const Value.absent(),
    DateTime? due,
    Value<DateTime?> lastReview = const Value.absent(),
  }) => SrsCard(
    literal: literal ?? this.literal,
    cardId: cardId ?? this.cardId,
    state: state ?? this.state,
    step: step.present ? step.value : this.step,
    stability: stability.present ? stability.value : this.stability,
    difficulty: difficulty.present ? difficulty.value : this.difficulty,
    due: due ?? this.due,
    lastReview: lastReview.present ? lastReview.value : this.lastReview,
  );
  SrsCard copyWithCompanion(SrsCardsCompanion data) {
    return SrsCard(
      literal: data.literal.present ? data.literal.value : this.literal,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      state: data.state.present ? data.state.value : this.state,
      step: data.step.present ? data.step.value : this.step,
      stability: data.stability.present ? data.stability.value : this.stability,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      due: data.due.present ? data.due.value : this.due,
      lastReview: data.lastReview.present
          ? data.lastReview.value
          : this.lastReview,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SrsCard(')
          ..write('literal: $literal, ')
          ..write('cardId: $cardId, ')
          ..write('state: $state, ')
          ..write('step: $step, ')
          ..write('stability: $stability, ')
          ..write('difficulty: $difficulty, ')
          ..write('due: $due, ')
          ..write('lastReview: $lastReview')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    literal,
    cardId,
    state,
    step,
    stability,
    difficulty,
    due,
    lastReview,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SrsCard &&
          other.literal == this.literal &&
          other.cardId == this.cardId &&
          other.state == this.state &&
          other.step == this.step &&
          other.stability == this.stability &&
          other.difficulty == this.difficulty &&
          other.due == this.due &&
          other.lastReview == this.lastReview);
}

class SrsCardsCompanion extends UpdateCompanion<SrsCard> {
  final Value<String> literal;
  final Value<int> cardId;
  final Value<int> state;
  final Value<int?> step;
  final Value<double?> stability;
  final Value<double?> difficulty;
  final Value<DateTime> due;
  final Value<DateTime?> lastReview;
  final Value<int> rowid;
  const SrsCardsCompanion({
    this.literal = const Value.absent(),
    this.cardId = const Value.absent(),
    this.state = const Value.absent(),
    this.step = const Value.absent(),
    this.stability = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.due = const Value.absent(),
    this.lastReview = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SrsCardsCompanion.insert({
    required String literal,
    required int cardId,
    required int state,
    this.step = const Value.absent(),
    this.stability = const Value.absent(),
    this.difficulty = const Value.absent(),
    required DateTime due,
    this.lastReview = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : literal = Value(literal),
       cardId = Value(cardId),
       state = Value(state),
       due = Value(due);
  static Insertable<SrsCard> custom({
    Expression<String>? literal,
    Expression<int>? cardId,
    Expression<int>? state,
    Expression<int>? step,
    Expression<double>? stability,
    Expression<double>? difficulty,
    Expression<DateTime>? due,
    Expression<DateTime>? lastReview,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (literal != null) 'literal': literal,
      if (cardId != null) 'card_id': cardId,
      if (state != null) 'state': state,
      if (step != null) 'step': step,
      if (stability != null) 'stability': stability,
      if (difficulty != null) 'difficulty': difficulty,
      if (due != null) 'due': due,
      if (lastReview != null) 'last_review': lastReview,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SrsCardsCompanion copyWith({
    Value<String>? literal,
    Value<int>? cardId,
    Value<int>? state,
    Value<int?>? step,
    Value<double?>? stability,
    Value<double?>? difficulty,
    Value<DateTime>? due,
    Value<DateTime?>? lastReview,
    Value<int>? rowid,
  }) {
    return SrsCardsCompanion(
      literal: literal ?? this.literal,
      cardId: cardId ?? this.cardId,
      state: state ?? this.state,
      step: step ?? this.step,
      stability: stability ?? this.stability,
      difficulty: difficulty ?? this.difficulty,
      due: due ?? this.due,
      lastReview: lastReview ?? this.lastReview,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (literal.present) {
      map['literal'] = Variable<String>(literal.value);
    }
    if (cardId.present) {
      map['card_id'] = Variable<int>(cardId.value);
    }
    if (state.present) {
      map['state'] = Variable<int>(state.value);
    }
    if (step.present) {
      map['step'] = Variable<int>(step.value);
    }
    if (stability.present) {
      map['stability'] = Variable<double>(stability.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<double>(difficulty.value);
    }
    if (due.present) {
      map['due'] = Variable<DateTime>(due.value);
    }
    if (lastReview.present) {
      map['last_review'] = Variable<DateTime>(lastReview.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SrsCardsCompanion(')
          ..write('literal: $literal, ')
          ..write('cardId: $cardId, ')
          ..write('state: $state, ')
          ..write('step: $step, ')
          ..write('stability: $stability, ')
          ..write('difficulty: $difficulty, ')
          ..write('due: $due, ')
          ..write('lastReview: $lastReview, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReviewLogsTable extends ReviewLogs
    with TableInfo<$ReviewLogsTable, ReviewLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewLogsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _literalMeta = const VerificationMeta(
    'literal',
  );
  @override
  late final GeneratedColumn<String> literal = GeneratedColumn<String>(
    'literal',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reviewedAtMeta = const VerificationMeta(
    'reviewedAt',
  );
  @override
  late final GeneratedColumn<DateTime> reviewedAt = GeneratedColumn<DateTime>(
    'reviewed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    literal,
    rating,
    reviewedAt,
    durationMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'review_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReviewLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('literal')) {
      context.handle(
        _literalMeta,
        literal.isAcceptableOrUnknown(data['literal']!, _literalMeta),
      );
    } else if (isInserting) {
      context.missing(_literalMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    if (data.containsKey('reviewed_at')) {
      context.handle(
        _reviewedAtMeta,
        reviewedAt.isAcceptableOrUnknown(data['reviewed_at']!, _reviewedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_reviewedAtMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReviewLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      literal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}literal'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rating'],
      )!,
      reviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}reviewed_at'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      ),
    );
  }

  @override
  $ReviewLogsTable createAlias(String alias) {
    return $ReviewLogsTable(attachedDatabase, alias);
  }
}

class ReviewLog extends DataClass implements Insertable<ReviewLog> {
  final int id;
  final String literal;
  final int rating;
  final DateTime reviewedAt;
  final int? durationMs;
  const ReviewLog({
    required this.id,
    required this.literal,
    required this.rating,
    required this.reviewedAt,
    this.durationMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['literal'] = Variable<String>(literal);
    map['rating'] = Variable<int>(rating);
    map['reviewed_at'] = Variable<DateTime>(reviewedAt);
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    return map;
  }

  ReviewLogsCompanion toCompanion(bool nullToAbsent) {
    return ReviewLogsCompanion(
      id: Value(id),
      literal: Value(literal),
      rating: Value(rating),
      reviewedAt: Value(reviewedAt),
      durationMs: durationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMs),
    );
  }

  factory ReviewLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewLog(
      id: serializer.fromJson<int>(json['id']),
      literal: serializer.fromJson<String>(json['literal']),
      rating: serializer.fromJson<int>(json['rating']),
      reviewedAt: serializer.fromJson<DateTime>(json['reviewedAt']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'literal': serializer.toJson<String>(literal),
      'rating': serializer.toJson<int>(rating),
      'reviewedAt': serializer.toJson<DateTime>(reviewedAt),
      'durationMs': serializer.toJson<int?>(durationMs),
    };
  }

  ReviewLog copyWith({
    int? id,
    String? literal,
    int? rating,
    DateTime? reviewedAt,
    Value<int?> durationMs = const Value.absent(),
  }) => ReviewLog(
    id: id ?? this.id,
    literal: literal ?? this.literal,
    rating: rating ?? this.rating,
    reviewedAt: reviewedAt ?? this.reviewedAt,
    durationMs: durationMs.present ? durationMs.value : this.durationMs,
  );
  ReviewLog copyWithCompanion(ReviewLogsCompanion data) {
    return ReviewLog(
      id: data.id.present ? data.id.value : this.id,
      literal: data.literal.present ? data.literal.value : this.literal,
      rating: data.rating.present ? data.rating.value : this.rating,
      reviewedAt: data.reviewedAt.present
          ? data.reviewedAt.value
          : this.reviewedAt,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewLog(')
          ..write('id: $id, ')
          ..write('literal: $literal, ')
          ..write('rating: $rating, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('durationMs: $durationMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, literal, rating, reviewedAt, durationMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewLog &&
          other.id == this.id &&
          other.literal == this.literal &&
          other.rating == this.rating &&
          other.reviewedAt == this.reviewedAt &&
          other.durationMs == this.durationMs);
}

class ReviewLogsCompanion extends UpdateCompanion<ReviewLog> {
  final Value<int> id;
  final Value<String> literal;
  final Value<int> rating;
  final Value<DateTime> reviewedAt;
  final Value<int?> durationMs;
  const ReviewLogsCompanion({
    this.id = const Value.absent(),
    this.literal = const Value.absent(),
    this.rating = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.durationMs = const Value.absent(),
  });
  ReviewLogsCompanion.insert({
    this.id = const Value.absent(),
    required String literal,
    required int rating,
    required DateTime reviewedAt,
    this.durationMs = const Value.absent(),
  }) : literal = Value(literal),
       rating = Value(rating),
       reviewedAt = Value(reviewedAt);
  static Insertable<ReviewLog> custom({
    Expression<int>? id,
    Expression<String>? literal,
    Expression<int>? rating,
    Expression<DateTime>? reviewedAt,
    Expression<int>? durationMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (literal != null) 'literal': literal,
      if (rating != null) 'rating': rating,
      if (reviewedAt != null) 'reviewed_at': reviewedAt,
      if (durationMs != null) 'duration_ms': durationMs,
    });
  }

  ReviewLogsCompanion copyWith({
    Value<int>? id,
    Value<String>? literal,
    Value<int>? rating,
    Value<DateTime>? reviewedAt,
    Value<int?>? durationMs,
  }) {
    return ReviewLogsCompanion(
      id: id ?? this.id,
      literal: literal ?? this.literal,
      rating: rating ?? this.rating,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      durationMs: durationMs ?? this.durationMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (literal.present) {
      map['literal'] = Variable<String>(literal.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (reviewedAt.present) {
      map['reviewed_at'] = Variable<DateTime>(reviewedAt.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewLogsCompanion(')
          ..write('id: $id, ')
          ..write('literal: $literal, ')
          ..write('rating: $rating, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('durationMs: $durationMs')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $KanjiEntriesTable kanjiEntries = $KanjiEntriesTable(this);
  late final $VocabEntriesTable vocabEntries = $VocabEntriesTable(this);
  late final $SrsCardsTable srsCards = $SrsCardsTable(this);
  late final $ReviewLogsTable reviewLogs = $ReviewLogsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    kanjiEntries,
    vocabEntries,
    srsCards,
    reviewLogs,
  ];
}

typedef $$KanjiEntriesTableCreateCompanionBuilder =
    KanjiEntriesCompanion Function({
      required String literal,
      required int strokeCount,
      Value<int?> grade,
      Value<int?> freq,
      required int level,
      required String meanings,
      required String onReadings,
      required String kunReadings,
      required String components,
      required String tag,
      required String strokes,
      Value<int> rowid,
    });
typedef $$KanjiEntriesTableUpdateCompanionBuilder =
    KanjiEntriesCompanion Function({
      Value<String> literal,
      Value<int> strokeCount,
      Value<int?> grade,
      Value<int?> freq,
      Value<int> level,
      Value<String> meanings,
      Value<String> onReadings,
      Value<String> kunReadings,
      Value<String> components,
      Value<String> tag,
      Value<String> strokes,
      Value<int> rowid,
    });

final class $$KanjiEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $KanjiEntriesTable, KanjiEntry> {
  $$KanjiEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SrsCardsTable, List<SrsCard>> _srsCardsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.srsCards,
    aliasName: 'kanji_entries__literal__srs_cards__literal',
  );

  $$SrsCardsTableProcessedTableManager get srsCardsRefs {
    final manager = $$SrsCardsTableTableManager($_db, $_db.srsCards).filter(
      (f) => f.literal.literal.sqlEquals($_itemColumn<String>('literal')!),
    );

    final cache = $_typedResult.readTableOrNull(_srsCardsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$KanjiEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $KanjiEntriesTable> {
  $$KanjiEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get literal => $composableBuilder(
    column: $table.literal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get strokeCount => $composableBuilder(
    column: $table.strokeCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get grade => $composableBuilder(
    column: $table.grade,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get freq => $composableBuilder(
    column: $table.freq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meanings => $composableBuilder(
    column: $table.meanings,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get onReadings => $composableBuilder(
    column: $table.onReadings,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kunReadings => $composableBuilder(
    column: $table.kunReadings,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get components => $composableBuilder(
    column: $table.components,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get strokes => $composableBuilder(
    column: $table.strokes,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> srsCardsRefs(
    Expression<bool> Function($$SrsCardsTableFilterComposer f) f,
  ) {
    final $$SrsCardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.literal,
      referencedTable: $db.srsCards,
      getReferencedColumn: (t) => t.literal,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SrsCardsTableFilterComposer(
            $db: $db,
            $table: $db.srsCards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$KanjiEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $KanjiEntriesTable> {
  $$KanjiEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get literal => $composableBuilder(
    column: $table.literal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get strokeCount => $composableBuilder(
    column: $table.strokeCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get grade => $composableBuilder(
    column: $table.grade,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get freq => $composableBuilder(
    column: $table.freq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meanings => $composableBuilder(
    column: $table.meanings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get onReadings => $composableBuilder(
    column: $table.onReadings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kunReadings => $composableBuilder(
    column: $table.kunReadings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get components => $composableBuilder(
    column: $table.components,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get strokes => $composableBuilder(
    column: $table.strokes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KanjiEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $KanjiEntriesTable> {
  $$KanjiEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get literal =>
      $composableBuilder(column: $table.literal, builder: (column) => column);

  GeneratedColumn<int> get strokeCount => $composableBuilder(
    column: $table.strokeCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get grade =>
      $composableBuilder(column: $table.grade, builder: (column) => column);

  GeneratedColumn<int> get freq =>
      $composableBuilder(column: $table.freq, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<String> get meanings =>
      $composableBuilder(column: $table.meanings, builder: (column) => column);

  GeneratedColumn<String> get onReadings => $composableBuilder(
    column: $table.onReadings,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kunReadings => $composableBuilder(
    column: $table.kunReadings,
    builder: (column) => column,
  );

  GeneratedColumn<String> get components => $composableBuilder(
    column: $table.components,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tag =>
      $composableBuilder(column: $table.tag, builder: (column) => column);

  GeneratedColumn<String> get strokes =>
      $composableBuilder(column: $table.strokes, builder: (column) => column);

  Expression<T> srsCardsRefs<T extends Object>(
    Expression<T> Function($$SrsCardsTableAnnotationComposer a) f,
  ) {
    final $$SrsCardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.literal,
      referencedTable: $db.srsCards,
      getReferencedColumn: (t) => t.literal,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SrsCardsTableAnnotationComposer(
            $db: $db,
            $table: $db.srsCards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$KanjiEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KanjiEntriesTable,
          KanjiEntry,
          $$KanjiEntriesTableFilterComposer,
          $$KanjiEntriesTableOrderingComposer,
          $$KanjiEntriesTableAnnotationComposer,
          $$KanjiEntriesTableCreateCompanionBuilder,
          $$KanjiEntriesTableUpdateCompanionBuilder,
          (KanjiEntry, $$KanjiEntriesTableReferences),
          KanjiEntry,
          PrefetchHooks Function({bool srsCardsRefs})
        > {
  $$KanjiEntriesTableTableManager(_$AppDatabase db, $KanjiEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KanjiEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KanjiEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KanjiEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> literal = const Value.absent(),
                Value<int> strokeCount = const Value.absent(),
                Value<int?> grade = const Value.absent(),
                Value<int?> freq = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<String> meanings = const Value.absent(),
                Value<String> onReadings = const Value.absent(),
                Value<String> kunReadings = const Value.absent(),
                Value<String> components = const Value.absent(),
                Value<String> tag = const Value.absent(),
                Value<String> strokes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KanjiEntriesCompanion(
                literal: literal,
                strokeCount: strokeCount,
                grade: grade,
                freq: freq,
                level: level,
                meanings: meanings,
                onReadings: onReadings,
                kunReadings: kunReadings,
                components: components,
                tag: tag,
                strokes: strokes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String literal,
                required int strokeCount,
                Value<int?> grade = const Value.absent(),
                Value<int?> freq = const Value.absent(),
                required int level,
                required String meanings,
                required String onReadings,
                required String kunReadings,
                required String components,
                required String tag,
                required String strokes,
                Value<int> rowid = const Value.absent(),
              }) => KanjiEntriesCompanion.insert(
                literal: literal,
                strokeCount: strokeCount,
                grade: grade,
                freq: freq,
                level: level,
                meanings: meanings,
                onReadings: onReadings,
                kunReadings: kunReadings,
                components: components,
                tag: tag,
                strokes: strokes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$KanjiEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({srsCardsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (srsCardsRefs) db.srsCards],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (srsCardsRefs)
                    await $_getPrefetchedData<
                      KanjiEntry,
                      $KanjiEntriesTable,
                      SrsCard
                    >(
                      currentTable: table,
                      referencedTable: $$KanjiEntriesTableReferences
                          ._srsCardsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$KanjiEntriesTableReferences(
                            db,
                            table,
                            p0,
                          ).srsCardsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.literal == item.literal,
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

typedef $$KanjiEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KanjiEntriesTable,
      KanjiEntry,
      $$KanjiEntriesTableFilterComposer,
      $$KanjiEntriesTableOrderingComposer,
      $$KanjiEntriesTableAnnotationComposer,
      $$KanjiEntriesTableCreateCompanionBuilder,
      $$KanjiEntriesTableUpdateCompanionBuilder,
      (KanjiEntry, $$KanjiEntriesTableReferences),
      KanjiEntry,
      PrefetchHooks Function({bool srsCardsRefs})
    >;
typedef $$VocabEntriesTableCreateCompanionBuilder =
    VocabEntriesCompanion Function({
      Value<int> id,
      required String word,
      required String reading,
      required String glosses,
      Value<String?> pos,
      required int level,
      required int rank,
    });
typedef $$VocabEntriesTableUpdateCompanionBuilder =
    VocabEntriesCompanion Function({
      Value<int> id,
      Value<String> word,
      Value<String> reading,
      Value<String> glosses,
      Value<String?> pos,
      Value<int> level,
      Value<int> rank,
    });

class $$VocabEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $VocabEntriesTable> {
  $$VocabEntriesTableFilterComposer({
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

  ColumnFilters<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reading => $composableBuilder(
    column: $table.reading,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get glosses => $composableBuilder(
    column: $table.glosses,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pos => $composableBuilder(
    column: $table.pos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rank => $composableBuilder(
    column: $table.rank,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VocabEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $VocabEntriesTable> {
  $$VocabEntriesTableOrderingComposer({
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

  ColumnOrderings<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reading => $composableBuilder(
    column: $table.reading,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get glosses => $composableBuilder(
    column: $table.glosses,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pos => $composableBuilder(
    column: $table.pos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rank => $composableBuilder(
    column: $table.rank,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VocabEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VocabEntriesTable> {
  $$VocabEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get word =>
      $composableBuilder(column: $table.word, builder: (column) => column);

  GeneratedColumn<String> get reading =>
      $composableBuilder(column: $table.reading, builder: (column) => column);

  GeneratedColumn<String> get glosses =>
      $composableBuilder(column: $table.glosses, builder: (column) => column);

  GeneratedColumn<String> get pos =>
      $composableBuilder(column: $table.pos, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<int> get rank =>
      $composableBuilder(column: $table.rank, builder: (column) => column);
}

class $$VocabEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VocabEntriesTable,
          VocabEntry,
          $$VocabEntriesTableFilterComposer,
          $$VocabEntriesTableOrderingComposer,
          $$VocabEntriesTableAnnotationComposer,
          $$VocabEntriesTableCreateCompanionBuilder,
          $$VocabEntriesTableUpdateCompanionBuilder,
          (
            VocabEntry,
            BaseReferences<_$AppDatabase, $VocabEntriesTable, VocabEntry>,
          ),
          VocabEntry,
          PrefetchHooks Function()
        > {
  $$VocabEntriesTableTableManager(_$AppDatabase db, $VocabEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VocabEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VocabEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VocabEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> word = const Value.absent(),
                Value<String> reading = const Value.absent(),
                Value<String> glosses = const Value.absent(),
                Value<String?> pos = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<int> rank = const Value.absent(),
              }) => VocabEntriesCompanion(
                id: id,
                word: word,
                reading: reading,
                glosses: glosses,
                pos: pos,
                level: level,
                rank: rank,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String word,
                required String reading,
                required String glosses,
                Value<String?> pos = const Value.absent(),
                required int level,
                required int rank,
              }) => VocabEntriesCompanion.insert(
                id: id,
                word: word,
                reading: reading,
                glosses: glosses,
                pos: pos,
                level: level,
                rank: rank,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VocabEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VocabEntriesTable,
      VocabEntry,
      $$VocabEntriesTableFilterComposer,
      $$VocabEntriesTableOrderingComposer,
      $$VocabEntriesTableAnnotationComposer,
      $$VocabEntriesTableCreateCompanionBuilder,
      $$VocabEntriesTableUpdateCompanionBuilder,
      (
        VocabEntry,
        BaseReferences<_$AppDatabase, $VocabEntriesTable, VocabEntry>,
      ),
      VocabEntry,
      PrefetchHooks Function()
    >;
typedef $$SrsCardsTableCreateCompanionBuilder =
    SrsCardsCompanion Function({
      required String literal,
      required int cardId,
      required int state,
      Value<int?> step,
      Value<double?> stability,
      Value<double?> difficulty,
      required DateTime due,
      Value<DateTime?> lastReview,
      Value<int> rowid,
    });
typedef $$SrsCardsTableUpdateCompanionBuilder =
    SrsCardsCompanion Function({
      Value<String> literal,
      Value<int> cardId,
      Value<int> state,
      Value<int?> step,
      Value<double?> stability,
      Value<double?> difficulty,
      Value<DateTime> due,
      Value<DateTime?> lastReview,
      Value<int> rowid,
    });

final class $$SrsCardsTableReferences
    extends BaseReferences<_$AppDatabase, $SrsCardsTable, SrsCard> {
  $$SrsCardsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $KanjiEntriesTable _literalTable(_$AppDatabase db) =>
      db.kanjiEntries.createAlias('srs_cards__literal__kanji_entries__literal');

  $$KanjiEntriesTableProcessedTableManager get literal {
    final $_column = $_itemColumn<String>('literal')!;

    final manager = $$KanjiEntriesTableTableManager(
      $_db,
      $_db.kanjiEntries,
    ).filter((f) => f.literal.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_literalTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SrsCardsTableFilterComposer
    extends Composer<_$AppDatabase, $SrsCardsTable> {
  $$SrsCardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get step => $composableBuilder(
    column: $table.step,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get stability => $composableBuilder(
    column: $table.stability,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get due => $composableBuilder(
    column: $table.due,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastReview => $composableBuilder(
    column: $table.lastReview,
    builder: (column) => ColumnFilters(column),
  );

  $$KanjiEntriesTableFilterComposer get literal {
    final $$KanjiEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.literal,
      referencedTable: $db.kanjiEntries,
      getReferencedColumn: (t) => t.literal,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KanjiEntriesTableFilterComposer(
            $db: $db,
            $table: $db.kanjiEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SrsCardsTableOrderingComposer
    extends Composer<_$AppDatabase, $SrsCardsTable> {
  $$SrsCardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get step => $composableBuilder(
    column: $table.step,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get stability => $composableBuilder(
    column: $table.stability,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get due => $composableBuilder(
    column: $table.due,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastReview => $composableBuilder(
    column: $table.lastReview,
    builder: (column) => ColumnOrderings(column),
  );

  $$KanjiEntriesTableOrderingComposer get literal {
    final $$KanjiEntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.literal,
      referencedTable: $db.kanjiEntries,
      getReferencedColumn: (t) => t.literal,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KanjiEntriesTableOrderingComposer(
            $db: $db,
            $table: $db.kanjiEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SrsCardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SrsCardsTable> {
  $$SrsCardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get cardId =>
      $composableBuilder(column: $table.cardId, builder: (column) => column);

  GeneratedColumn<int> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get step =>
      $composableBuilder(column: $table.step, builder: (column) => column);

  GeneratedColumn<double> get stability =>
      $composableBuilder(column: $table.stability, builder: (column) => column);

  GeneratedColumn<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get due =>
      $composableBuilder(column: $table.due, builder: (column) => column);

  GeneratedColumn<DateTime> get lastReview => $composableBuilder(
    column: $table.lastReview,
    builder: (column) => column,
  );

  $$KanjiEntriesTableAnnotationComposer get literal {
    final $$KanjiEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.literal,
      referencedTable: $db.kanjiEntries,
      getReferencedColumn: (t) => t.literal,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KanjiEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.kanjiEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SrsCardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SrsCardsTable,
          SrsCard,
          $$SrsCardsTableFilterComposer,
          $$SrsCardsTableOrderingComposer,
          $$SrsCardsTableAnnotationComposer,
          $$SrsCardsTableCreateCompanionBuilder,
          $$SrsCardsTableUpdateCompanionBuilder,
          (SrsCard, $$SrsCardsTableReferences),
          SrsCard,
          PrefetchHooks Function({bool literal})
        > {
  $$SrsCardsTableTableManager(_$AppDatabase db, $SrsCardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SrsCardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SrsCardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SrsCardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> literal = const Value.absent(),
                Value<int> cardId = const Value.absent(),
                Value<int> state = const Value.absent(),
                Value<int?> step = const Value.absent(),
                Value<double?> stability = const Value.absent(),
                Value<double?> difficulty = const Value.absent(),
                Value<DateTime> due = const Value.absent(),
                Value<DateTime?> lastReview = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SrsCardsCompanion(
                literal: literal,
                cardId: cardId,
                state: state,
                step: step,
                stability: stability,
                difficulty: difficulty,
                due: due,
                lastReview: lastReview,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String literal,
                required int cardId,
                required int state,
                Value<int?> step = const Value.absent(),
                Value<double?> stability = const Value.absent(),
                Value<double?> difficulty = const Value.absent(),
                required DateTime due,
                Value<DateTime?> lastReview = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SrsCardsCompanion.insert(
                literal: literal,
                cardId: cardId,
                state: state,
                step: step,
                stability: stability,
                difficulty: difficulty,
                due: due,
                lastReview: lastReview,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SrsCardsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({literal = false}) {
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
                    if (literal) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.literal,
                                referencedTable: $$SrsCardsTableReferences
                                    ._literalTable(db),
                                referencedColumn: $$SrsCardsTableReferences
                                    ._literalTable(db)
                                    .literal,
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

typedef $$SrsCardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SrsCardsTable,
      SrsCard,
      $$SrsCardsTableFilterComposer,
      $$SrsCardsTableOrderingComposer,
      $$SrsCardsTableAnnotationComposer,
      $$SrsCardsTableCreateCompanionBuilder,
      $$SrsCardsTableUpdateCompanionBuilder,
      (SrsCard, $$SrsCardsTableReferences),
      SrsCard,
      PrefetchHooks Function({bool literal})
    >;
typedef $$ReviewLogsTableCreateCompanionBuilder =
    ReviewLogsCompanion Function({
      Value<int> id,
      required String literal,
      required int rating,
      required DateTime reviewedAt,
      Value<int?> durationMs,
    });
typedef $$ReviewLogsTableUpdateCompanionBuilder =
    ReviewLogsCompanion Function({
      Value<int> id,
      Value<String> literal,
      Value<int> rating,
      Value<DateTime> reviewedAt,
      Value<int?> durationMs,
    });

class $$ReviewLogsTableFilterComposer
    extends Composer<_$AppDatabase, $ReviewLogsTable> {
  $$ReviewLogsTableFilterComposer({
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

  ColumnFilters<String> get literal => $composableBuilder(
    column: $table.literal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReviewLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReviewLogsTable> {
  $$ReviewLogsTableOrderingComposer({
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

  ColumnOrderings<String> get literal => $composableBuilder(
    column: $table.literal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReviewLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReviewLogsTable> {
  $$ReviewLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get literal =>
      $composableBuilder(column: $table.literal, builder: (column) => column);

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );
}

class $$ReviewLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReviewLogsTable,
          ReviewLog,
          $$ReviewLogsTableFilterComposer,
          $$ReviewLogsTableOrderingComposer,
          $$ReviewLogsTableAnnotationComposer,
          $$ReviewLogsTableCreateCompanionBuilder,
          $$ReviewLogsTableUpdateCompanionBuilder,
          (
            ReviewLog,
            BaseReferences<_$AppDatabase, $ReviewLogsTable, ReviewLog>,
          ),
          ReviewLog,
          PrefetchHooks Function()
        > {
  $$ReviewLogsTableTableManager(_$AppDatabase db, $ReviewLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> literal = const Value.absent(),
                Value<int> rating = const Value.absent(),
                Value<DateTime> reviewedAt = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
              }) => ReviewLogsCompanion(
                id: id,
                literal: literal,
                rating: rating,
                reviewedAt: reviewedAt,
                durationMs: durationMs,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String literal,
                required int rating,
                required DateTime reviewedAt,
                Value<int?> durationMs = const Value.absent(),
              }) => ReviewLogsCompanion.insert(
                id: id,
                literal: literal,
                rating: rating,
                reviewedAt: reviewedAt,
                durationMs: durationMs,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReviewLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReviewLogsTable,
      ReviewLog,
      $$ReviewLogsTableFilterComposer,
      $$ReviewLogsTableOrderingComposer,
      $$ReviewLogsTableAnnotationComposer,
      $$ReviewLogsTableCreateCompanionBuilder,
      $$ReviewLogsTableUpdateCompanionBuilder,
      (ReviewLog, BaseReferences<_$AppDatabase, $ReviewLogsTable, ReviewLog>),
      ReviewLog,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$KanjiEntriesTableTableManager get kanjiEntries =>
      $$KanjiEntriesTableTableManager(_db, _db.kanjiEntries);
  $$VocabEntriesTableTableManager get vocabEntries =>
      $$VocabEntriesTableTableManager(_db, _db.vocabEntries);
  $$SrsCardsTableTableManager get srsCards =>
      $$SrsCardsTableTableManager(_db, _db.srsCards);
  $$ReviewLogsTableTableManager get reviewLogs =>
      $$ReviewLogsTableTableManager(_db, _db.reviewLogs);
}
