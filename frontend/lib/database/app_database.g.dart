// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LahansTable extends Lahans with TableInfo<$LahansTable, Lahan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LahansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _namaLahanMeta =
      const VerificationMeta('namaLahan');
  @override
  late final GeneratedColumn<String> namaLahan = GeneratedColumn<String>(
      'nama_lahan', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _luasHaMeta = const VerificationMeta('luasHa');
  @override
  late final GeneratedColumn<double> luasHa = GeneratedColumn<double>(
      'luas_ha', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _usiaPohonMeta =
      const VerificationMeta('usiaPohon');
  @override
  late final GeneratedColumn<int> usiaPohon = GeneratedColumn<int>(
      'usia_pohon', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _tahunTanamMeta =
      const VerificationMeta('tahunTanam');
  @override
  late final GeneratedColumn<int> tahunTanam = GeneratedColumn<int>(
      'tahun_tanam', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _jumlahPohonMeta =
      const VerificationMeta('jumlahPohon');
  @override
  late final GeneratedColumn<int> jumlahPohon = GeneratedColumn<int>(
      'jumlah_pohon', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _lokasiMeta = const VerificationMeta('lokasi');
  @override
  late final GeneratedColumn<String> lokasi = GeneratedColumn<String>(
      'lokasi', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<int> cachedAt = GeneratedColumn<int>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        namaLahan,
        luasHa,
        usiaPohon,
        tahunTanam,
        jumlahPohon,
        lokasi,
        isActive,
        cachedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lahans';
  @override
  VerificationContext validateIntegrity(Insertable<Lahan> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('nama_lahan')) {
      context.handle(_namaLahanMeta,
          namaLahan.isAcceptableOrUnknown(data['nama_lahan']!, _namaLahanMeta));
    } else if (isInserting) {
      context.missing(_namaLahanMeta);
    }
    if (data.containsKey('luas_ha')) {
      context.handle(_luasHaMeta,
          luasHa.isAcceptableOrUnknown(data['luas_ha']!, _luasHaMeta));
    } else if (isInserting) {
      context.missing(_luasHaMeta);
    }
    if (data.containsKey('usia_pohon')) {
      context.handle(_usiaPohonMeta,
          usiaPohon.isAcceptableOrUnknown(data['usia_pohon']!, _usiaPohonMeta));
    } else if (isInserting) {
      context.missing(_usiaPohonMeta);
    }
    if (data.containsKey('tahun_tanam')) {
      context.handle(
          _tahunTanamMeta,
          tahunTanam.isAcceptableOrUnknown(
              data['tahun_tanam']!, _tahunTanamMeta));
    }
    if (data.containsKey('jumlah_pohon')) {
      context.handle(
          _jumlahPohonMeta,
          jumlahPohon.isAcceptableOrUnknown(
              data['jumlah_pohon']!, _jumlahPohonMeta));
    }
    if (data.containsKey('lokasi')) {
      context.handle(_lokasiMeta,
          lokasi.isAcceptableOrUnknown(data['lokasi']!, _lokasiMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Lahan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Lahan(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      namaLahan: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nama_lahan'])!,
      luasHa: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}luas_ha'])!,
      usiaPohon: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}usia_pohon'])!,
      tahunTanam: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tahun_tanam']),
      jumlahPohon: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}jumlah_pohon']),
      lokasi: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lokasi']),
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cached_at'])!,
    );
  }

  @override
  $LahansTable createAlias(String alias) {
    return $LahansTable(attachedDatabase, alias);
  }
}

class Lahan extends DataClass implements Insertable<Lahan> {
  final int id;
  final String namaLahan;
  final double luasHa;
  final int usiaPohon;
  final int? tahunTanam;
  final int? jumlahPohon;
  final String? lokasi;
  final bool isActive;
  final int cachedAt;
  const Lahan(
      {required this.id,
      required this.namaLahan,
      required this.luasHa,
      required this.usiaPohon,
      this.tahunTanam,
      this.jumlahPohon,
      this.lokasi,
      required this.isActive,
      required this.cachedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['nama_lahan'] = Variable<String>(namaLahan);
    map['luas_ha'] = Variable<double>(luasHa);
    map['usia_pohon'] = Variable<int>(usiaPohon);
    if (!nullToAbsent || tahunTanam != null) {
      map['tahun_tanam'] = Variable<int>(tahunTanam);
    }
    if (!nullToAbsent || jumlahPohon != null) {
      map['jumlah_pohon'] = Variable<int>(jumlahPohon);
    }
    if (!nullToAbsent || lokasi != null) {
      map['lokasi'] = Variable<String>(lokasi);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['cached_at'] = Variable<int>(cachedAt);
    return map;
  }

  LahansCompanion toCompanion(bool nullToAbsent) {
    return LahansCompanion(
      id: Value(id),
      namaLahan: Value(namaLahan),
      luasHa: Value(luasHa),
      usiaPohon: Value(usiaPohon),
      tahunTanam: tahunTanam == null && nullToAbsent
          ? const Value.absent()
          : Value(tahunTanam),
      jumlahPohon: jumlahPohon == null && nullToAbsent
          ? const Value.absent()
          : Value(jumlahPohon),
      lokasi:
          lokasi == null && nullToAbsent ? const Value.absent() : Value(lokasi),
      isActive: Value(isActive),
      cachedAt: Value(cachedAt),
    );
  }

  factory Lahan.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Lahan(
      id: serializer.fromJson<int>(json['id']),
      namaLahan: serializer.fromJson<String>(json['namaLahan']),
      luasHa: serializer.fromJson<double>(json['luasHa']),
      usiaPohon: serializer.fromJson<int>(json['usiaPohon']),
      tahunTanam: serializer.fromJson<int?>(json['tahunTanam']),
      jumlahPohon: serializer.fromJson<int?>(json['jumlahPohon']),
      lokasi: serializer.fromJson<String?>(json['lokasi']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      cachedAt: serializer.fromJson<int>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'namaLahan': serializer.toJson<String>(namaLahan),
      'luasHa': serializer.toJson<double>(luasHa),
      'usiaPohon': serializer.toJson<int>(usiaPohon),
      'tahunTanam': serializer.toJson<int?>(tahunTanam),
      'jumlahPohon': serializer.toJson<int?>(jumlahPohon),
      'lokasi': serializer.toJson<String?>(lokasi),
      'isActive': serializer.toJson<bool>(isActive),
      'cachedAt': serializer.toJson<int>(cachedAt),
    };
  }

  Lahan copyWith(
          {int? id,
          String? namaLahan,
          double? luasHa,
          int? usiaPohon,
          Value<int?> tahunTanam = const Value.absent(),
          Value<int?> jumlahPohon = const Value.absent(),
          Value<String?> lokasi = const Value.absent(),
          bool? isActive,
          int? cachedAt}) =>
      Lahan(
        id: id ?? this.id,
        namaLahan: namaLahan ?? this.namaLahan,
        luasHa: luasHa ?? this.luasHa,
        usiaPohon: usiaPohon ?? this.usiaPohon,
        tahunTanam: tahunTanam.present ? tahunTanam.value : this.tahunTanam,
        jumlahPohon: jumlahPohon.present ? jumlahPohon.value : this.jumlahPohon,
        lokasi: lokasi.present ? lokasi.value : this.lokasi,
        isActive: isActive ?? this.isActive,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  Lahan copyWithCompanion(LahansCompanion data) {
    return Lahan(
      id: data.id.present ? data.id.value : this.id,
      namaLahan: data.namaLahan.present ? data.namaLahan.value : this.namaLahan,
      luasHa: data.luasHa.present ? data.luasHa.value : this.luasHa,
      usiaPohon: data.usiaPohon.present ? data.usiaPohon.value : this.usiaPohon,
      tahunTanam:
          data.tahunTanam.present ? data.tahunTanam.value : this.tahunTanam,
      jumlahPohon:
          data.jumlahPohon.present ? data.jumlahPohon.value : this.jumlahPohon,
      lokasi: data.lokasi.present ? data.lokasi.value : this.lokasi,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Lahan(')
          ..write('id: $id, ')
          ..write('namaLahan: $namaLahan, ')
          ..write('luasHa: $luasHa, ')
          ..write('usiaPohon: $usiaPohon, ')
          ..write('tahunTanam: $tahunTanam, ')
          ..write('jumlahPohon: $jumlahPohon, ')
          ..write('lokasi: $lokasi, ')
          ..write('isActive: $isActive, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, namaLahan, luasHa, usiaPohon, tahunTanam,
      jumlahPohon, lokasi, isActive, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Lahan &&
          other.id == this.id &&
          other.namaLahan == this.namaLahan &&
          other.luasHa == this.luasHa &&
          other.usiaPohon == this.usiaPohon &&
          other.tahunTanam == this.tahunTanam &&
          other.jumlahPohon == this.jumlahPohon &&
          other.lokasi == this.lokasi &&
          other.isActive == this.isActive &&
          other.cachedAt == this.cachedAt);
}

class LahansCompanion extends UpdateCompanion<Lahan> {
  final Value<int> id;
  final Value<String> namaLahan;
  final Value<double> luasHa;
  final Value<int> usiaPohon;
  final Value<int?> tahunTanam;
  final Value<int?> jumlahPohon;
  final Value<String?> lokasi;
  final Value<bool> isActive;
  final Value<int> cachedAt;
  const LahansCompanion({
    this.id = const Value.absent(),
    this.namaLahan = const Value.absent(),
    this.luasHa = const Value.absent(),
    this.usiaPohon = const Value.absent(),
    this.tahunTanam = const Value.absent(),
    this.jumlahPohon = const Value.absent(),
    this.lokasi = const Value.absent(),
    this.isActive = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  LahansCompanion.insert({
    this.id = const Value.absent(),
    required String namaLahan,
    required double luasHa,
    required int usiaPohon,
    this.tahunTanam = const Value.absent(),
    this.jumlahPohon = const Value.absent(),
    this.lokasi = const Value.absent(),
    this.isActive = const Value.absent(),
    required int cachedAt,
  })  : namaLahan = Value(namaLahan),
        luasHa = Value(luasHa),
        usiaPohon = Value(usiaPohon),
        cachedAt = Value(cachedAt);
  static Insertable<Lahan> custom({
    Expression<int>? id,
    Expression<String>? namaLahan,
    Expression<double>? luasHa,
    Expression<int>? usiaPohon,
    Expression<int>? tahunTanam,
    Expression<int>? jumlahPohon,
    Expression<String>? lokasi,
    Expression<bool>? isActive,
    Expression<int>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (namaLahan != null) 'nama_lahan': namaLahan,
      if (luasHa != null) 'luas_ha': luasHa,
      if (usiaPohon != null) 'usia_pohon': usiaPohon,
      if (tahunTanam != null) 'tahun_tanam': tahunTanam,
      if (jumlahPohon != null) 'jumlah_pohon': jumlahPohon,
      if (lokasi != null) 'lokasi': lokasi,
      if (isActive != null) 'is_active': isActive,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  LahansCompanion copyWith(
      {Value<int>? id,
      Value<String>? namaLahan,
      Value<double>? luasHa,
      Value<int>? usiaPohon,
      Value<int?>? tahunTanam,
      Value<int?>? jumlahPohon,
      Value<String?>? lokasi,
      Value<bool>? isActive,
      Value<int>? cachedAt}) {
    return LahansCompanion(
      id: id ?? this.id,
      namaLahan: namaLahan ?? this.namaLahan,
      luasHa: luasHa ?? this.luasHa,
      usiaPohon: usiaPohon ?? this.usiaPohon,
      tahunTanam: tahunTanam ?? this.tahunTanam,
      jumlahPohon: jumlahPohon ?? this.jumlahPohon,
      lokasi: lokasi ?? this.lokasi,
      isActive: isActive ?? this.isActive,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (namaLahan.present) {
      map['nama_lahan'] = Variable<String>(namaLahan.value);
    }
    if (luasHa.present) {
      map['luas_ha'] = Variable<double>(luasHa.value);
    }
    if (usiaPohon.present) {
      map['usia_pohon'] = Variable<int>(usiaPohon.value);
    }
    if (tahunTanam.present) {
      map['tahun_tanam'] = Variable<int>(tahunTanam.value);
    }
    if (jumlahPohon.present) {
      map['jumlah_pohon'] = Variable<int>(jumlahPohon.value);
    }
    if (lokasi.present) {
      map['lokasi'] = Variable<String>(lokasi.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<int>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LahansCompanion(')
          ..write('id: $id, ')
          ..write('namaLahan: $namaLahan, ')
          ..write('luasHa: $luasHa, ')
          ..write('usiaPohon: $usiaPohon, ')
          ..write('tahunTanam: $tahunTanam, ')
          ..write('jumlahPohon: $jumlahPohon, ')
          ..write('lokasi: $lokasi, ')
          ..write('isActive: $isActive, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $PanensTable extends Panens with TableInfo<$PanensTable, Panen> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PanensTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _lahanIdMeta =
      const VerificationMeta('lahanId');
  @override
  late final GeneratedColumn<int> lahanId = GeneratedColumn<int>(
      'lahan_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _bulanMeta = const VerificationMeta('bulan');
  @override
  late final GeneratedColumn<String> bulan = GeneratedColumn<String>(
      'bulan', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tahunMeta = const VerificationMeta('tahun');
  @override
  late final GeneratedColumn<int> tahun = GeneratedColumn<int>(
      'tahun', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _bulanAngkaMeta =
      const VerificationMeta('bulanAngka');
  @override
  late final GeneratedColumn<int> bulanAngka = GeneratedColumn<int>(
      'bulan_angka', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _tanggalMeta =
      const VerificationMeta('tanggal');
  @override
  late final GeneratedColumn<int> tanggal = GeneratedColumn<int>(
      'tanggal', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _tonAktualMeta =
      const VerificationMeta('tonAktual');
  @override
  late final GeneratedColumn<double> tonAktual = GeneratedColumn<double>(
      'ton_aktual', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _targetMinMeta =
      const VerificationMeta('targetMin');
  @override
  late final GeneratedColumn<double> targetMin = GeneratedColumn<double>(
      'target_min', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _targetMaxMeta =
      const VerificationMeta('targetMax');
  @override
  late final GeneratedColumn<double> targetMax = GeneratedColumn<double>(
      'target_max', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _targetMidMeta =
      const VerificationMeta('targetMid');
  @override
  late final GeneratedColumn<double> targetMid = GeneratedColumn<double>(
      'target_mid', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _hargaPerTonMeta =
      const VerificationMeta('hargaPerTon');
  @override
  late final GeneratedColumn<double> hargaPerTon = GeneratedColumn<double>(
      'harga_per_ton', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(2400000.0));
  static const VerificationMeta _statusPanenMeta =
      const VerificationMeta('statusPanen');
  @override
  late final GeneratedColumn<String> statusPanen = GeneratedColumn<String>(
      'status_panen', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _persenKurangMeta =
      const VerificationMeta('persenKurang');
  @override
  late final GeneratedColumn<double> persenKurang = GeneratedColumn<double>(
      'persen_kurang', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _luasHaMeta = const VerificationMeta('luasHa');
  @override
  late final GeneratedColumn<double> luasHa = GeneratedColumn<double>(
      'luas_ha', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(14.0));
  static const VerificationMeta _usiaPohonMeta =
      const VerificationMeta('usiaPohon');
  @override
  late final GeneratedColumn<int> usiaPohon = GeneratedColumn<int>(
      'usia_pohon', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(8));
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<int> cachedAt = GeneratedColumn<int>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        lahanId,
        bulan,
        tahun,
        bulanAngka,
        tanggal,
        tonAktual,
        targetMin,
        targetMax,
        targetMid,
        hargaPerTon,
        statusPanen,
        persenKurang,
        luasHa,
        usiaPohon,
        cachedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'panens';
  @override
  VerificationContext validateIntegrity(Insertable<Panen> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('lahan_id')) {
      context.handle(_lahanIdMeta,
          lahanId.isAcceptableOrUnknown(data['lahan_id']!, _lahanIdMeta));
    } else if (isInserting) {
      context.missing(_lahanIdMeta);
    }
    if (data.containsKey('bulan')) {
      context.handle(
          _bulanMeta, bulan.isAcceptableOrUnknown(data['bulan']!, _bulanMeta));
    } else if (isInserting) {
      context.missing(_bulanMeta);
    }
    if (data.containsKey('tahun')) {
      context.handle(
          _tahunMeta, tahun.isAcceptableOrUnknown(data['tahun']!, _tahunMeta));
    } else if (isInserting) {
      context.missing(_tahunMeta);
    }
    if (data.containsKey('bulan_angka')) {
      context.handle(
          _bulanAngkaMeta,
          bulanAngka.isAcceptableOrUnknown(
              data['bulan_angka']!, _bulanAngkaMeta));
    } else if (isInserting) {
      context.missing(_bulanAngkaMeta);
    }
    if (data.containsKey('tanggal')) {
      context.handle(_tanggalMeta,
          tanggal.isAcceptableOrUnknown(data['tanggal']!, _tanggalMeta));
    }
    if (data.containsKey('ton_aktual')) {
      context.handle(_tonAktualMeta,
          tonAktual.isAcceptableOrUnknown(data['ton_aktual']!, _tonAktualMeta));
    } else if (isInserting) {
      context.missing(_tonAktualMeta);
    }
    if (data.containsKey('target_min')) {
      context.handle(_targetMinMeta,
          targetMin.isAcceptableOrUnknown(data['target_min']!, _targetMinMeta));
    }
    if (data.containsKey('target_max')) {
      context.handle(_targetMaxMeta,
          targetMax.isAcceptableOrUnknown(data['target_max']!, _targetMaxMeta));
    }
    if (data.containsKey('target_mid')) {
      context.handle(_targetMidMeta,
          targetMid.isAcceptableOrUnknown(data['target_mid']!, _targetMidMeta));
    }
    if (data.containsKey('harga_per_ton')) {
      context.handle(
          _hargaPerTonMeta,
          hargaPerTon.isAcceptableOrUnknown(
              data['harga_per_ton']!, _hargaPerTonMeta));
    }
    if (data.containsKey('status_panen')) {
      context.handle(
          _statusPanenMeta,
          statusPanen.isAcceptableOrUnknown(
              data['status_panen']!, _statusPanenMeta));
    }
    if (data.containsKey('persen_kurang')) {
      context.handle(
          _persenKurangMeta,
          persenKurang.isAcceptableOrUnknown(
              data['persen_kurang']!, _persenKurangMeta));
    }
    if (data.containsKey('luas_ha')) {
      context.handle(_luasHaMeta,
          luasHa.isAcceptableOrUnknown(data['luas_ha']!, _luasHaMeta));
    }
    if (data.containsKey('usia_pohon')) {
      context.handle(_usiaPohonMeta,
          usiaPohon.isAcceptableOrUnknown(data['usia_pohon']!, _usiaPohonMeta));
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Panen map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Panen(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      lahanId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}lahan_id'])!,
      bulan: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bulan'])!,
      tahun: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tahun'])!,
      bulanAngka: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}bulan_angka'])!,
      tanggal: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tanggal']),
      tonAktual: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}ton_aktual'])!,
      targetMin: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}target_min'])!,
      targetMax: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}target_max'])!,
      targetMid: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}target_mid'])!,
      hargaPerTon: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}harga_per_ton'])!,
      statusPanen: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status_panen']),
      persenKurang: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}persen_kurang'])!,
      luasHa: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}luas_ha'])!,
      usiaPohon: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}usia_pohon'])!,
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cached_at'])!,
    );
  }

  @override
  $PanensTable createAlias(String alias) {
    return $PanensTable(attachedDatabase, alias);
  }
}

class Panen extends DataClass implements Insertable<Panen> {
  final int id;
  final int lahanId;
  final String bulan;
  final int tahun;
  final int bulanAngka;
  final int? tanggal;
  final double tonAktual;
  final double targetMin;
  final double targetMax;
  final double targetMid;
  final double hargaPerTon;
  final String? statusPanen;
  final double persenKurang;
  final double luasHa;
  final int usiaPohon;
  final int cachedAt;
  const Panen(
      {required this.id,
      required this.lahanId,
      required this.bulan,
      required this.tahun,
      required this.bulanAngka,
      this.tanggal,
      required this.tonAktual,
      required this.targetMin,
      required this.targetMax,
      required this.targetMid,
      required this.hargaPerTon,
      this.statusPanen,
      required this.persenKurang,
      required this.luasHa,
      required this.usiaPohon,
      required this.cachedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['lahan_id'] = Variable<int>(lahanId);
    map['bulan'] = Variable<String>(bulan);
    map['tahun'] = Variable<int>(tahun);
    map['bulan_angka'] = Variable<int>(bulanAngka);
    if (!nullToAbsent || tanggal != null) {
      map['tanggal'] = Variable<int>(tanggal);
    }
    map['ton_aktual'] = Variable<double>(tonAktual);
    map['target_min'] = Variable<double>(targetMin);
    map['target_max'] = Variable<double>(targetMax);
    map['target_mid'] = Variable<double>(targetMid);
    map['harga_per_ton'] = Variable<double>(hargaPerTon);
    if (!nullToAbsent || statusPanen != null) {
      map['status_panen'] = Variable<String>(statusPanen);
    }
    map['persen_kurang'] = Variable<double>(persenKurang);
    map['luas_ha'] = Variable<double>(luasHa);
    map['usia_pohon'] = Variable<int>(usiaPohon);
    map['cached_at'] = Variable<int>(cachedAt);
    return map;
  }

  PanensCompanion toCompanion(bool nullToAbsent) {
    return PanensCompanion(
      id: Value(id),
      lahanId: Value(lahanId),
      bulan: Value(bulan),
      tahun: Value(tahun),
      bulanAngka: Value(bulanAngka),
      tanggal: tanggal == null && nullToAbsent
          ? const Value.absent()
          : Value(tanggal),
      tonAktual: Value(tonAktual),
      targetMin: Value(targetMin),
      targetMax: Value(targetMax),
      targetMid: Value(targetMid),
      hargaPerTon: Value(hargaPerTon),
      statusPanen: statusPanen == null && nullToAbsent
          ? const Value.absent()
          : Value(statusPanen),
      persenKurang: Value(persenKurang),
      luasHa: Value(luasHa),
      usiaPohon: Value(usiaPohon),
      cachedAt: Value(cachedAt),
    );
  }

  factory Panen.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Panen(
      id: serializer.fromJson<int>(json['id']),
      lahanId: serializer.fromJson<int>(json['lahanId']),
      bulan: serializer.fromJson<String>(json['bulan']),
      tahun: serializer.fromJson<int>(json['tahun']),
      bulanAngka: serializer.fromJson<int>(json['bulanAngka']),
      tanggal: serializer.fromJson<int?>(json['tanggal']),
      tonAktual: serializer.fromJson<double>(json['tonAktual']),
      targetMin: serializer.fromJson<double>(json['targetMin']),
      targetMax: serializer.fromJson<double>(json['targetMax']),
      targetMid: serializer.fromJson<double>(json['targetMid']),
      hargaPerTon: serializer.fromJson<double>(json['hargaPerTon']),
      statusPanen: serializer.fromJson<String?>(json['statusPanen']),
      persenKurang: serializer.fromJson<double>(json['persenKurang']),
      luasHa: serializer.fromJson<double>(json['luasHa']),
      usiaPohon: serializer.fromJson<int>(json['usiaPohon']),
      cachedAt: serializer.fromJson<int>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'lahanId': serializer.toJson<int>(lahanId),
      'bulan': serializer.toJson<String>(bulan),
      'tahun': serializer.toJson<int>(tahun),
      'bulanAngka': serializer.toJson<int>(bulanAngka),
      'tanggal': serializer.toJson<int?>(tanggal),
      'tonAktual': serializer.toJson<double>(tonAktual),
      'targetMin': serializer.toJson<double>(targetMin),
      'targetMax': serializer.toJson<double>(targetMax),
      'targetMid': serializer.toJson<double>(targetMid),
      'hargaPerTon': serializer.toJson<double>(hargaPerTon),
      'statusPanen': serializer.toJson<String?>(statusPanen),
      'persenKurang': serializer.toJson<double>(persenKurang),
      'luasHa': serializer.toJson<double>(luasHa),
      'usiaPohon': serializer.toJson<int>(usiaPohon),
      'cachedAt': serializer.toJson<int>(cachedAt),
    };
  }

  Panen copyWith(
          {int? id,
          int? lahanId,
          String? bulan,
          int? tahun,
          int? bulanAngka,
          Value<int?> tanggal = const Value.absent(),
          double? tonAktual,
          double? targetMin,
          double? targetMax,
          double? targetMid,
          double? hargaPerTon,
          Value<String?> statusPanen = const Value.absent(),
          double? persenKurang,
          double? luasHa,
          int? usiaPohon,
          int? cachedAt}) =>
      Panen(
        id: id ?? this.id,
        lahanId: lahanId ?? this.lahanId,
        bulan: bulan ?? this.bulan,
        tahun: tahun ?? this.tahun,
        bulanAngka: bulanAngka ?? this.bulanAngka,
        tanggal: tanggal.present ? tanggal.value : this.tanggal,
        tonAktual: tonAktual ?? this.tonAktual,
        targetMin: targetMin ?? this.targetMin,
        targetMax: targetMax ?? this.targetMax,
        targetMid: targetMid ?? this.targetMid,
        hargaPerTon: hargaPerTon ?? this.hargaPerTon,
        statusPanen: statusPanen.present ? statusPanen.value : this.statusPanen,
        persenKurang: persenKurang ?? this.persenKurang,
        luasHa: luasHa ?? this.luasHa,
        usiaPohon: usiaPohon ?? this.usiaPohon,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  Panen copyWithCompanion(PanensCompanion data) {
    return Panen(
      id: data.id.present ? data.id.value : this.id,
      lahanId: data.lahanId.present ? data.lahanId.value : this.lahanId,
      bulan: data.bulan.present ? data.bulan.value : this.bulan,
      tahun: data.tahun.present ? data.tahun.value : this.tahun,
      bulanAngka:
          data.bulanAngka.present ? data.bulanAngka.value : this.bulanAngka,
      tanggal: data.tanggal.present ? data.tanggal.value : this.tanggal,
      tonAktual: data.tonAktual.present ? data.tonAktual.value : this.tonAktual,
      targetMin: data.targetMin.present ? data.targetMin.value : this.targetMin,
      targetMax: data.targetMax.present ? data.targetMax.value : this.targetMax,
      targetMid: data.targetMid.present ? data.targetMid.value : this.targetMid,
      hargaPerTon:
          data.hargaPerTon.present ? data.hargaPerTon.value : this.hargaPerTon,
      statusPanen:
          data.statusPanen.present ? data.statusPanen.value : this.statusPanen,
      persenKurang: data.persenKurang.present
          ? data.persenKurang.value
          : this.persenKurang,
      luasHa: data.luasHa.present ? data.luasHa.value : this.luasHa,
      usiaPohon: data.usiaPohon.present ? data.usiaPohon.value : this.usiaPohon,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Panen(')
          ..write('id: $id, ')
          ..write('lahanId: $lahanId, ')
          ..write('bulan: $bulan, ')
          ..write('tahun: $tahun, ')
          ..write('bulanAngka: $bulanAngka, ')
          ..write('tanggal: $tanggal, ')
          ..write('tonAktual: $tonAktual, ')
          ..write('targetMin: $targetMin, ')
          ..write('targetMax: $targetMax, ')
          ..write('targetMid: $targetMid, ')
          ..write('hargaPerTon: $hargaPerTon, ')
          ..write('statusPanen: $statusPanen, ')
          ..write('persenKurang: $persenKurang, ')
          ..write('luasHa: $luasHa, ')
          ..write('usiaPohon: $usiaPohon, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      lahanId,
      bulan,
      tahun,
      bulanAngka,
      tanggal,
      tonAktual,
      targetMin,
      targetMax,
      targetMid,
      hargaPerTon,
      statusPanen,
      persenKurang,
      luasHa,
      usiaPohon,
      cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Panen &&
          other.id == this.id &&
          other.lahanId == this.lahanId &&
          other.bulan == this.bulan &&
          other.tahun == this.tahun &&
          other.bulanAngka == this.bulanAngka &&
          other.tanggal == this.tanggal &&
          other.tonAktual == this.tonAktual &&
          other.targetMin == this.targetMin &&
          other.targetMax == this.targetMax &&
          other.targetMid == this.targetMid &&
          other.hargaPerTon == this.hargaPerTon &&
          other.statusPanen == this.statusPanen &&
          other.persenKurang == this.persenKurang &&
          other.luasHa == this.luasHa &&
          other.usiaPohon == this.usiaPohon &&
          other.cachedAt == this.cachedAt);
}

class PanensCompanion extends UpdateCompanion<Panen> {
  final Value<int> id;
  final Value<int> lahanId;
  final Value<String> bulan;
  final Value<int> tahun;
  final Value<int> bulanAngka;
  final Value<int?> tanggal;
  final Value<double> tonAktual;
  final Value<double> targetMin;
  final Value<double> targetMax;
  final Value<double> targetMid;
  final Value<double> hargaPerTon;
  final Value<String?> statusPanen;
  final Value<double> persenKurang;
  final Value<double> luasHa;
  final Value<int> usiaPohon;
  final Value<int> cachedAt;
  const PanensCompanion({
    this.id = const Value.absent(),
    this.lahanId = const Value.absent(),
    this.bulan = const Value.absent(),
    this.tahun = const Value.absent(),
    this.bulanAngka = const Value.absent(),
    this.tanggal = const Value.absent(),
    this.tonAktual = const Value.absent(),
    this.targetMin = const Value.absent(),
    this.targetMax = const Value.absent(),
    this.targetMid = const Value.absent(),
    this.hargaPerTon = const Value.absent(),
    this.statusPanen = const Value.absent(),
    this.persenKurang = const Value.absent(),
    this.luasHa = const Value.absent(),
    this.usiaPohon = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  PanensCompanion.insert({
    this.id = const Value.absent(),
    required int lahanId,
    required String bulan,
    required int tahun,
    required int bulanAngka,
    this.tanggal = const Value.absent(),
    required double tonAktual,
    this.targetMin = const Value.absent(),
    this.targetMax = const Value.absent(),
    this.targetMid = const Value.absent(),
    this.hargaPerTon = const Value.absent(),
    this.statusPanen = const Value.absent(),
    this.persenKurang = const Value.absent(),
    this.luasHa = const Value.absent(),
    this.usiaPohon = const Value.absent(),
    required int cachedAt,
  })  : lahanId = Value(lahanId),
        bulan = Value(bulan),
        tahun = Value(tahun),
        bulanAngka = Value(bulanAngka),
        tonAktual = Value(tonAktual),
        cachedAt = Value(cachedAt);
  static Insertable<Panen> custom({
    Expression<int>? id,
    Expression<int>? lahanId,
    Expression<String>? bulan,
    Expression<int>? tahun,
    Expression<int>? bulanAngka,
    Expression<int>? tanggal,
    Expression<double>? tonAktual,
    Expression<double>? targetMin,
    Expression<double>? targetMax,
    Expression<double>? targetMid,
    Expression<double>? hargaPerTon,
    Expression<String>? statusPanen,
    Expression<double>? persenKurang,
    Expression<double>? luasHa,
    Expression<int>? usiaPohon,
    Expression<int>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lahanId != null) 'lahan_id': lahanId,
      if (bulan != null) 'bulan': bulan,
      if (tahun != null) 'tahun': tahun,
      if (bulanAngka != null) 'bulan_angka': bulanAngka,
      if (tanggal != null) 'tanggal': tanggal,
      if (tonAktual != null) 'ton_aktual': tonAktual,
      if (targetMin != null) 'target_min': targetMin,
      if (targetMax != null) 'target_max': targetMax,
      if (targetMid != null) 'target_mid': targetMid,
      if (hargaPerTon != null) 'harga_per_ton': hargaPerTon,
      if (statusPanen != null) 'status_panen': statusPanen,
      if (persenKurang != null) 'persen_kurang': persenKurang,
      if (luasHa != null) 'luas_ha': luasHa,
      if (usiaPohon != null) 'usia_pohon': usiaPohon,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  PanensCompanion copyWith(
      {Value<int>? id,
      Value<int>? lahanId,
      Value<String>? bulan,
      Value<int>? tahun,
      Value<int>? bulanAngka,
      Value<int?>? tanggal,
      Value<double>? tonAktual,
      Value<double>? targetMin,
      Value<double>? targetMax,
      Value<double>? targetMid,
      Value<double>? hargaPerTon,
      Value<String?>? statusPanen,
      Value<double>? persenKurang,
      Value<double>? luasHa,
      Value<int>? usiaPohon,
      Value<int>? cachedAt}) {
    return PanensCompanion(
      id: id ?? this.id,
      lahanId: lahanId ?? this.lahanId,
      bulan: bulan ?? this.bulan,
      tahun: tahun ?? this.tahun,
      bulanAngka: bulanAngka ?? this.bulanAngka,
      tanggal: tanggal ?? this.tanggal,
      tonAktual: tonAktual ?? this.tonAktual,
      targetMin: targetMin ?? this.targetMin,
      targetMax: targetMax ?? this.targetMax,
      targetMid: targetMid ?? this.targetMid,
      hargaPerTon: hargaPerTon ?? this.hargaPerTon,
      statusPanen: statusPanen ?? this.statusPanen,
      persenKurang: persenKurang ?? this.persenKurang,
      luasHa: luasHa ?? this.luasHa,
      usiaPohon: usiaPohon ?? this.usiaPohon,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (lahanId.present) {
      map['lahan_id'] = Variable<int>(lahanId.value);
    }
    if (bulan.present) {
      map['bulan'] = Variable<String>(bulan.value);
    }
    if (tahun.present) {
      map['tahun'] = Variable<int>(tahun.value);
    }
    if (bulanAngka.present) {
      map['bulan_angka'] = Variable<int>(bulanAngka.value);
    }
    if (tanggal.present) {
      map['tanggal'] = Variable<int>(tanggal.value);
    }
    if (tonAktual.present) {
      map['ton_aktual'] = Variable<double>(tonAktual.value);
    }
    if (targetMin.present) {
      map['target_min'] = Variable<double>(targetMin.value);
    }
    if (targetMax.present) {
      map['target_max'] = Variable<double>(targetMax.value);
    }
    if (targetMid.present) {
      map['target_mid'] = Variable<double>(targetMid.value);
    }
    if (hargaPerTon.present) {
      map['harga_per_ton'] = Variable<double>(hargaPerTon.value);
    }
    if (statusPanen.present) {
      map['status_panen'] = Variable<String>(statusPanen.value);
    }
    if (persenKurang.present) {
      map['persen_kurang'] = Variable<double>(persenKurang.value);
    }
    if (luasHa.present) {
      map['luas_ha'] = Variable<double>(luasHa.value);
    }
    if (usiaPohon.present) {
      map['usia_pohon'] = Variable<int>(usiaPohon.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<int>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PanensCompanion(')
          ..write('id: $id, ')
          ..write('lahanId: $lahanId, ')
          ..write('bulan: $bulan, ')
          ..write('tahun: $tahun, ')
          ..write('bulanAngka: $bulanAngka, ')
          ..write('tanggal: $tanggal, ')
          ..write('tonAktual: $tonAktual, ')
          ..write('targetMin: $targetMin, ')
          ..write('targetMax: $targetMax, ')
          ..write('targetMid: $targetMid, ')
          ..write('hargaPerTon: $hargaPerTon, ')
          ..write('statusPanen: $statusPanen, ')
          ..write('persenKurang: $persenKurang, ')
          ..write('luasHa: $luasHa, ')
          ..write('usiaPohon: $usiaPohon, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $BiayasTable extends Biayas with TableInfo<$BiayasTable, Biaya> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BiayasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _lahanIdMeta =
      const VerificationMeta('lahanId');
  @override
  late final GeneratedColumn<int> lahanId = GeneratedColumn<int>(
      'lahan_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _bulanMeta = const VerificationMeta('bulan');
  @override
  late final GeneratedColumn<String> bulan = GeneratedColumn<String>(
      'bulan', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tahunMeta = const VerificationMeta('tahun');
  @override
  late final GeneratedColumn<int> tahun = GeneratedColumn<int>(
      'tahun', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _bulanAngkaMeta =
      const VerificationMeta('bulanAngka');
  @override
  late final GeneratedColumn<int> bulanAngka = GeneratedColumn<int>(
      'bulan_angka', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _kategoriMeta =
      const VerificationMeta('kategori');
  @override
  late final GeneratedColumn<String> kategori = GeneratedColumn<String>(
      'kategori', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _jumlahMeta = const VerificationMeta('jumlah');
  @override
  late final GeneratedColumn<double> jumlah = GeneratedColumn<double>(
      'jumlah', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _keteranganMeta =
      const VerificationMeta('keterangan');
  @override
  late final GeneratedColumn<String> keterangan = GeneratedColumn<String>(
      'keterangan', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<int> cachedAt = GeneratedColumn<int>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        lahanId,
        bulan,
        tahun,
        bulanAngka,
        kategori,
        jumlah,
        keterangan,
        cachedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'biayas';
  @override
  VerificationContext validateIntegrity(Insertable<Biaya> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('lahan_id')) {
      context.handle(_lahanIdMeta,
          lahanId.isAcceptableOrUnknown(data['lahan_id']!, _lahanIdMeta));
    } else if (isInserting) {
      context.missing(_lahanIdMeta);
    }
    if (data.containsKey('bulan')) {
      context.handle(
          _bulanMeta, bulan.isAcceptableOrUnknown(data['bulan']!, _bulanMeta));
    } else if (isInserting) {
      context.missing(_bulanMeta);
    }
    if (data.containsKey('tahun')) {
      context.handle(
          _tahunMeta, tahun.isAcceptableOrUnknown(data['tahun']!, _tahunMeta));
    } else if (isInserting) {
      context.missing(_tahunMeta);
    }
    if (data.containsKey('bulan_angka')) {
      context.handle(
          _bulanAngkaMeta,
          bulanAngka.isAcceptableOrUnknown(
              data['bulan_angka']!, _bulanAngkaMeta));
    } else if (isInserting) {
      context.missing(_bulanAngkaMeta);
    }
    if (data.containsKey('kategori')) {
      context.handle(_kategoriMeta,
          kategori.isAcceptableOrUnknown(data['kategori']!, _kategoriMeta));
    } else if (isInserting) {
      context.missing(_kategoriMeta);
    }
    if (data.containsKey('jumlah')) {
      context.handle(_jumlahMeta,
          jumlah.isAcceptableOrUnknown(data['jumlah']!, _jumlahMeta));
    } else if (isInserting) {
      context.missing(_jumlahMeta);
    }
    if (data.containsKey('keterangan')) {
      context.handle(
          _keteranganMeta,
          keterangan.isAcceptableOrUnknown(
              data['keterangan']!, _keteranganMeta));
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Biaya map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Biaya(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      lahanId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}lahan_id'])!,
      bulan: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bulan'])!,
      tahun: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tahun'])!,
      bulanAngka: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}bulan_angka'])!,
      kategori: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kategori'])!,
      jumlah: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}jumlah'])!,
      keterangan: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}keterangan']),
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cached_at'])!,
    );
  }

  @override
  $BiayasTable createAlias(String alias) {
    return $BiayasTable(attachedDatabase, alias);
  }
}

class Biaya extends DataClass implements Insertable<Biaya> {
  final int id;
  final int lahanId;
  final String bulan;
  final int tahun;
  final int bulanAngka;
  final String kategori;
  final double jumlah;
  final String? keterangan;
  final int cachedAt;
  const Biaya(
      {required this.id,
      required this.lahanId,
      required this.bulan,
      required this.tahun,
      required this.bulanAngka,
      required this.kategori,
      required this.jumlah,
      this.keterangan,
      required this.cachedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['lahan_id'] = Variable<int>(lahanId);
    map['bulan'] = Variable<String>(bulan);
    map['tahun'] = Variable<int>(tahun);
    map['bulan_angka'] = Variable<int>(bulanAngka);
    map['kategori'] = Variable<String>(kategori);
    map['jumlah'] = Variable<double>(jumlah);
    if (!nullToAbsent || keterangan != null) {
      map['keterangan'] = Variable<String>(keterangan);
    }
    map['cached_at'] = Variable<int>(cachedAt);
    return map;
  }

  BiayasCompanion toCompanion(bool nullToAbsent) {
    return BiayasCompanion(
      id: Value(id),
      lahanId: Value(lahanId),
      bulan: Value(bulan),
      tahun: Value(tahun),
      bulanAngka: Value(bulanAngka),
      kategori: Value(kategori),
      jumlah: Value(jumlah),
      keterangan: keterangan == null && nullToAbsent
          ? const Value.absent()
          : Value(keterangan),
      cachedAt: Value(cachedAt),
    );
  }

  factory Biaya.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Biaya(
      id: serializer.fromJson<int>(json['id']),
      lahanId: serializer.fromJson<int>(json['lahanId']),
      bulan: serializer.fromJson<String>(json['bulan']),
      tahun: serializer.fromJson<int>(json['tahun']),
      bulanAngka: serializer.fromJson<int>(json['bulanAngka']),
      kategori: serializer.fromJson<String>(json['kategori']),
      jumlah: serializer.fromJson<double>(json['jumlah']),
      keterangan: serializer.fromJson<String?>(json['keterangan']),
      cachedAt: serializer.fromJson<int>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'lahanId': serializer.toJson<int>(lahanId),
      'bulan': serializer.toJson<String>(bulan),
      'tahun': serializer.toJson<int>(tahun),
      'bulanAngka': serializer.toJson<int>(bulanAngka),
      'kategori': serializer.toJson<String>(kategori),
      'jumlah': serializer.toJson<double>(jumlah),
      'keterangan': serializer.toJson<String?>(keterangan),
      'cachedAt': serializer.toJson<int>(cachedAt),
    };
  }

  Biaya copyWith(
          {int? id,
          int? lahanId,
          String? bulan,
          int? tahun,
          int? bulanAngka,
          String? kategori,
          double? jumlah,
          Value<String?> keterangan = const Value.absent(),
          int? cachedAt}) =>
      Biaya(
        id: id ?? this.id,
        lahanId: lahanId ?? this.lahanId,
        bulan: bulan ?? this.bulan,
        tahun: tahun ?? this.tahun,
        bulanAngka: bulanAngka ?? this.bulanAngka,
        kategori: kategori ?? this.kategori,
        jumlah: jumlah ?? this.jumlah,
        keterangan: keterangan.present ? keterangan.value : this.keterangan,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  Biaya copyWithCompanion(BiayasCompanion data) {
    return Biaya(
      id: data.id.present ? data.id.value : this.id,
      lahanId: data.lahanId.present ? data.lahanId.value : this.lahanId,
      bulan: data.bulan.present ? data.bulan.value : this.bulan,
      tahun: data.tahun.present ? data.tahun.value : this.tahun,
      bulanAngka:
          data.bulanAngka.present ? data.bulanAngka.value : this.bulanAngka,
      kategori: data.kategori.present ? data.kategori.value : this.kategori,
      jumlah: data.jumlah.present ? data.jumlah.value : this.jumlah,
      keterangan:
          data.keterangan.present ? data.keterangan.value : this.keterangan,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Biaya(')
          ..write('id: $id, ')
          ..write('lahanId: $lahanId, ')
          ..write('bulan: $bulan, ')
          ..write('tahun: $tahun, ')
          ..write('bulanAngka: $bulanAngka, ')
          ..write('kategori: $kategori, ')
          ..write('jumlah: $jumlah, ')
          ..write('keterangan: $keterangan, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, lahanId, bulan, tahun, bulanAngka,
      kategori, jumlah, keterangan, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Biaya &&
          other.id == this.id &&
          other.lahanId == this.lahanId &&
          other.bulan == this.bulan &&
          other.tahun == this.tahun &&
          other.bulanAngka == this.bulanAngka &&
          other.kategori == this.kategori &&
          other.jumlah == this.jumlah &&
          other.keterangan == this.keterangan &&
          other.cachedAt == this.cachedAt);
}

class BiayasCompanion extends UpdateCompanion<Biaya> {
  final Value<int> id;
  final Value<int> lahanId;
  final Value<String> bulan;
  final Value<int> tahun;
  final Value<int> bulanAngka;
  final Value<String> kategori;
  final Value<double> jumlah;
  final Value<String?> keterangan;
  final Value<int> cachedAt;
  const BiayasCompanion({
    this.id = const Value.absent(),
    this.lahanId = const Value.absent(),
    this.bulan = const Value.absent(),
    this.tahun = const Value.absent(),
    this.bulanAngka = const Value.absent(),
    this.kategori = const Value.absent(),
    this.jumlah = const Value.absent(),
    this.keterangan = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  BiayasCompanion.insert({
    this.id = const Value.absent(),
    required int lahanId,
    required String bulan,
    required int tahun,
    required int bulanAngka,
    required String kategori,
    required double jumlah,
    this.keterangan = const Value.absent(),
    required int cachedAt,
  })  : lahanId = Value(lahanId),
        bulan = Value(bulan),
        tahun = Value(tahun),
        bulanAngka = Value(bulanAngka),
        kategori = Value(kategori),
        jumlah = Value(jumlah),
        cachedAt = Value(cachedAt);
  static Insertable<Biaya> custom({
    Expression<int>? id,
    Expression<int>? lahanId,
    Expression<String>? bulan,
    Expression<int>? tahun,
    Expression<int>? bulanAngka,
    Expression<String>? kategori,
    Expression<double>? jumlah,
    Expression<String>? keterangan,
    Expression<int>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lahanId != null) 'lahan_id': lahanId,
      if (bulan != null) 'bulan': bulan,
      if (tahun != null) 'tahun': tahun,
      if (bulanAngka != null) 'bulan_angka': bulanAngka,
      if (kategori != null) 'kategori': kategori,
      if (jumlah != null) 'jumlah': jumlah,
      if (keterangan != null) 'keterangan': keterangan,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  BiayasCompanion copyWith(
      {Value<int>? id,
      Value<int>? lahanId,
      Value<String>? bulan,
      Value<int>? tahun,
      Value<int>? bulanAngka,
      Value<String>? kategori,
      Value<double>? jumlah,
      Value<String?>? keterangan,
      Value<int>? cachedAt}) {
    return BiayasCompanion(
      id: id ?? this.id,
      lahanId: lahanId ?? this.lahanId,
      bulan: bulan ?? this.bulan,
      tahun: tahun ?? this.tahun,
      bulanAngka: bulanAngka ?? this.bulanAngka,
      kategori: kategori ?? this.kategori,
      jumlah: jumlah ?? this.jumlah,
      keterangan: keterangan ?? this.keterangan,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (lahanId.present) {
      map['lahan_id'] = Variable<int>(lahanId.value);
    }
    if (bulan.present) {
      map['bulan'] = Variable<String>(bulan.value);
    }
    if (tahun.present) {
      map['tahun'] = Variable<int>(tahun.value);
    }
    if (bulanAngka.present) {
      map['bulan_angka'] = Variable<int>(bulanAngka.value);
    }
    if (kategori.present) {
      map['kategori'] = Variable<String>(kategori.value);
    }
    if (jumlah.present) {
      map['jumlah'] = Variable<double>(jumlah.value);
    }
    if (keterangan.present) {
      map['keterangan'] = Variable<String>(keterangan.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<int>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BiayasCompanion(')
          ..write('id: $id, ')
          ..write('lahanId: $lahanId, ')
          ..write('bulan: $bulan, ')
          ..write('tahun: $tahun, ')
          ..write('bulanAngka: $bulanAngka, ')
          ..write('kategori: $kategori, ')
          ..write('jumlah: $jumlah, ')
          ..write('keterangan: $keterangan, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
      'entity', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _operationMeta =
      const VerificationMeta('operation');
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
      'operation', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lahanIdMeta =
      const VerificationMeta('lahanId');
  @override
  late final GeneratedColumn<int> lahanId = GeneratedColumn<int>(
      'lahan_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _localIdMeta =
      const VerificationMeta('localId');
  @override
  late final GeneratedColumn<int> localId = GeneratedColumn<int>(
      'local_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _retryCountMeta =
      const VerificationMeta('retryCount');
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
      'retry_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [id, entity, operation, payload, lahanId, localId, createdAt, retryCount];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(Insertable<SyncQueueData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entity')) {
      context.handle(_entityMeta,
          entity.isAcceptableOrUnknown(data['entity']!, _entityMeta));
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(_operationMeta,
          operation.isAcceptableOrUnknown(data['operation']!, _operationMeta));
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('lahan_id')) {
      context.handle(_lahanIdMeta,
          lahanId.isAcceptableOrUnknown(data['lahan_id']!, _lahanIdMeta));
    } else if (isInserting) {
      context.missing(_lahanIdMeta);
    }
    if (data.containsKey('local_id')) {
      context.handle(_localIdMeta,
          localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta));
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
          _retryCountMeta,
          retryCount.isAcceptableOrUnknown(
              data['retry_count']!, _retryCountMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      entity: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity'])!,
      operation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operation'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      lahanId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}lahan_id'])!,
      localId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}local_id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      retryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retry_count'])!,
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueData extends DataClass implements Insertable<SyncQueueData> {
  final int id;
  final String entity;
  final String operation;
  final String payload;
  final int lahanId;
  final int localId;
  final int createdAt;
  final int retryCount;
  const SyncQueueData(
      {required this.id,
      required this.entity,
      required this.operation,
      required this.payload,
      required this.lahanId,
      required this.localId,
      required this.createdAt,
      required this.retryCount});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entity'] = Variable<String>(entity);
    map['operation'] = Variable<String>(operation);
    map['payload'] = Variable<String>(payload);
    map['lahan_id'] = Variable<int>(lahanId);
    map['local_id'] = Variable<int>(localId);
    map['created_at'] = Variable<int>(createdAt);
    map['retry_count'] = Variable<int>(retryCount);
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      entity: Value(entity),
      operation: Value(operation),
      payload: Value(payload),
      lahanId: Value(lahanId),
      localId: Value(localId),
      createdAt: Value(createdAt),
      retryCount: Value(retryCount),
    );
  }

  factory SyncQueueData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueData(
      id: serializer.fromJson<int>(json['id']),
      entity: serializer.fromJson<String>(json['entity']),
      operation: serializer.fromJson<String>(json['operation']),
      payload: serializer.fromJson<String>(json['payload']),
      lahanId: serializer.fromJson<int>(json['lahanId']),
      localId: serializer.fromJson<int>(json['localId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entity': serializer.toJson<String>(entity),
      'operation': serializer.toJson<String>(operation),
      'payload': serializer.toJson<String>(payload),
      'lahanId': serializer.toJson<int>(lahanId),
      'localId': serializer.toJson<int>(localId),
      'createdAt': serializer.toJson<int>(createdAt),
      'retryCount': serializer.toJson<int>(retryCount),
    };
  }

  SyncQueueData copyWith(
          {int? id,
          String? entity,
          String? operation,
          String? payload,
          int? lahanId,
          int? localId,
          int? createdAt,
          int? retryCount}) =>
      SyncQueueData(
        id: id ?? this.id,
        entity: entity ?? this.entity,
        operation: operation ?? this.operation,
        payload: payload ?? this.payload,
        lahanId: lahanId ?? this.lahanId,
        localId: localId ?? this.localId,
        createdAt: createdAt ?? this.createdAt,
        retryCount: retryCount ?? this.retryCount,
      );
  SyncQueueData copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueData(
      id: data.id.present ? data.id.value : this.id,
      entity: data.entity.present ? data.entity.value : this.entity,
      operation: data.operation.present ? data.operation.value : this.operation,
      payload: data.payload.present ? data.payload.value : this.payload,
      lahanId: data.lahanId.present ? data.lahanId.value : this.lahanId,
      localId: data.localId.present ? data.localId.value : this.localId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueData(')
          ..write('id: $id, ')
          ..write('entity: $entity, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('lahanId: $lahanId, ')
          ..write('localId: $localId, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, entity, operation, payload, lahanId, localId, createdAt, retryCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueData &&
          other.id == this.id &&
          other.entity == this.entity &&
          other.operation == this.operation &&
          other.payload == this.payload &&
          other.lahanId == this.lahanId &&
          other.localId == this.localId &&
          other.createdAt == this.createdAt &&
          other.retryCount == this.retryCount);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueData> {
  final Value<int> id;
  final Value<String> entity;
  final Value<String> operation;
  final Value<String> payload;
  final Value<int> lahanId;
  final Value<int> localId;
  final Value<int> createdAt;
  final Value<int> retryCount;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.entity = const Value.absent(),
    this.operation = const Value.absent(),
    this.payload = const Value.absent(),
    this.lahanId = const Value.absent(),
    this.localId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.retryCount = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    this.id = const Value.absent(),
    required String entity,
    required String operation,
    required String payload,
    required int lahanId,
    required int localId,
    required int createdAt,
    this.retryCount = const Value.absent(),
  })  : entity = Value(entity),
        operation = Value(operation),
        payload = Value(payload),
        lahanId = Value(lahanId),
        localId = Value(localId),
        createdAt = Value(createdAt);
  static Insertable<SyncQueueData> custom({
    Expression<int>? id,
    Expression<String>? entity,
    Expression<String>? operation,
    Expression<String>? payload,
    Expression<int>? lahanId,
    Expression<int>? localId,
    Expression<int>? createdAt,
    Expression<int>? retryCount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entity != null) 'entity': entity,
      if (operation != null) 'operation': operation,
      if (payload != null) 'payload': payload,
      if (lahanId != null) 'lahan_id': lahanId,
      if (localId != null) 'local_id': localId,
      if (createdAt != null) 'created_at': createdAt,
      if (retryCount != null) 'retry_count': retryCount,
    });
  }

  SyncQueueCompanion copyWith(
      {Value<int>? id,
      Value<String>? entity,
      Value<String>? operation,
      Value<String>? payload,
      Value<int>? lahanId,
      Value<int>? localId,
      Value<int>? createdAt,
      Value<int>? retryCount}) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      entity: entity ?? this.entity,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      lahanId: lahanId ?? this.lahanId,
      localId: localId ?? this.localId,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (lahanId.present) {
      map['lahan_id'] = Variable<int>(lahanId.value);
    }
    if (localId.present) {
      map['local_id'] = Variable<int>(localId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('entity: $entity, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('lahanId: $lahanId, ')
          ..write('localId: $localId, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount')
          ..write(')'))
        .toString();
  }
}

class $PekerjasTable extends Pekerjas with TableInfo<$PekerjasTable, Pekerja> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PekerjasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _lahanIdMeta =
      const VerificationMeta('lahanId');
  @override
  late final GeneratedColumn<int> lahanId = GeneratedColumn<int>(
      'lahan_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _namaMeta = const VerificationMeta('nama');
  @override
  late final GeneratedColumn<String> nama = GeneratedColumn<String>(
      'nama', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _peranMeta = const VerificationMeta('peran');
  @override
  late final GeneratedColumn<String> peran = GeneratedColumn<String>(
      'peran', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _kontakMeta = const VerificationMeta('kontak');
  @override
  late final GeneratedColumn<String> kontak = GeneratedColumn<String>(
      'kontak', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _gajiHarianMeta =
      const VerificationMeta('gajiHarian');
  @override
  late final GeneratedColumn<double> gajiHarian = GeneratedColumn<double>(
      'gaji_harian', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(150000));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, lahanId, nama, peran, kontak, gajiHarian, isActive, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pekerjas';
  @override
  VerificationContext validateIntegrity(Insertable<Pekerja> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('lahan_id')) {
      context.handle(_lahanIdMeta,
          lahanId.isAcceptableOrUnknown(data['lahan_id']!, _lahanIdMeta));
    } else if (isInserting) {
      context.missing(_lahanIdMeta);
    }
    if (data.containsKey('nama')) {
      context.handle(
          _namaMeta, nama.isAcceptableOrUnknown(data['nama']!, _namaMeta));
    } else if (isInserting) {
      context.missing(_namaMeta);
    }
    if (data.containsKey('peran')) {
      context.handle(
          _peranMeta, peran.isAcceptableOrUnknown(data['peran']!, _peranMeta));
    } else if (isInserting) {
      context.missing(_peranMeta);
    }
    if (data.containsKey('kontak')) {
      context.handle(_kontakMeta,
          kontak.isAcceptableOrUnknown(data['kontak']!, _kontakMeta));
    }
    if (data.containsKey('gaji_harian')) {
      context.handle(
          _gajiHarianMeta,
          gajiHarian.isAcceptableOrUnknown(
              data['gaji_harian']!, _gajiHarianMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Pekerja map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Pekerja(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      lahanId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}lahan_id'])!,
      nama: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nama'])!,
      peran: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}peran'])!,
      kontak: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kontak']),
      gajiHarian: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}gaji_harian'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $PekerjasTable createAlias(String alias) {
    return $PekerjasTable(attachedDatabase, alias);
  }
}

class Pekerja extends DataClass implements Insertable<Pekerja> {
  final int id;
  final int lahanId;
  final String nama;
  final String peran;
  final String? kontak;
  final double gajiHarian;
  final bool isActive;
  final int createdAt;
  const Pekerja(
      {required this.id,
      required this.lahanId,
      required this.nama,
      required this.peran,
      this.kontak,
      required this.gajiHarian,
      required this.isActive,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['lahan_id'] = Variable<int>(lahanId);
    map['nama'] = Variable<String>(nama);
    map['peran'] = Variable<String>(peran);
    if (!nullToAbsent || kontak != null) {
      map['kontak'] = Variable<String>(kontak);
    }
    map['gaji_harian'] = Variable<double>(gajiHarian);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  PekerjasCompanion toCompanion(bool nullToAbsent) {
    return PekerjasCompanion(
      id: Value(id),
      lahanId: Value(lahanId),
      nama: Value(nama),
      peran: Value(peran),
      kontak:
          kontak == null && nullToAbsent ? const Value.absent() : Value(kontak),
      gajiHarian: Value(gajiHarian),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
    );
  }

  factory Pekerja.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Pekerja(
      id: serializer.fromJson<int>(json['id']),
      lahanId: serializer.fromJson<int>(json['lahanId']),
      nama: serializer.fromJson<String>(json['nama']),
      peran: serializer.fromJson<String>(json['peran']),
      kontak: serializer.fromJson<String?>(json['kontak']),
      gajiHarian: serializer.fromJson<double>(json['gajiHarian']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'lahanId': serializer.toJson<int>(lahanId),
      'nama': serializer.toJson<String>(nama),
      'peran': serializer.toJson<String>(peran),
      'kontak': serializer.toJson<String?>(kontak),
      'gajiHarian': serializer.toJson<double>(gajiHarian),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  Pekerja copyWith(
          {int? id,
          int? lahanId,
          String? nama,
          String? peran,
          Value<String?> kontak = const Value.absent(),
          double? gajiHarian,
          bool? isActive,
          int? createdAt}) =>
      Pekerja(
        id: id ?? this.id,
        lahanId: lahanId ?? this.lahanId,
        nama: nama ?? this.nama,
        peran: peran ?? this.peran,
        kontak: kontak.present ? kontak.value : this.kontak,
        gajiHarian: gajiHarian ?? this.gajiHarian,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
      );
  Pekerja copyWithCompanion(PekerjasCompanion data) {
    return Pekerja(
      id: data.id.present ? data.id.value : this.id,
      lahanId: data.lahanId.present ? data.lahanId.value : this.lahanId,
      nama: data.nama.present ? data.nama.value : this.nama,
      peran: data.peran.present ? data.peran.value : this.peran,
      kontak: data.kontak.present ? data.kontak.value : this.kontak,
      gajiHarian:
          data.gajiHarian.present ? data.gajiHarian.value : this.gajiHarian,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Pekerja(')
          ..write('id: $id, ')
          ..write('lahanId: $lahanId, ')
          ..write('nama: $nama, ')
          ..write('peran: $peran, ')
          ..write('kontak: $kontak, ')
          ..write('gajiHarian: $gajiHarian, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, lahanId, nama, peran, kontak, gajiHarian, isActive, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Pekerja &&
          other.id == this.id &&
          other.lahanId == this.lahanId &&
          other.nama == this.nama &&
          other.peran == this.peran &&
          other.kontak == this.kontak &&
          other.gajiHarian == this.gajiHarian &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt);
}

class PekerjasCompanion extends UpdateCompanion<Pekerja> {
  final Value<int> id;
  final Value<int> lahanId;
  final Value<String> nama;
  final Value<String> peran;
  final Value<String?> kontak;
  final Value<double> gajiHarian;
  final Value<bool> isActive;
  final Value<int> createdAt;
  const PekerjasCompanion({
    this.id = const Value.absent(),
    this.lahanId = const Value.absent(),
    this.nama = const Value.absent(),
    this.peran = const Value.absent(),
    this.kontak = const Value.absent(),
    this.gajiHarian = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PekerjasCompanion.insert({
    this.id = const Value.absent(),
    required int lahanId,
    required String nama,
    required String peran,
    this.kontak = const Value.absent(),
    this.gajiHarian = const Value.absent(),
    this.isActive = const Value.absent(),
    required int createdAt,
  })  : lahanId = Value(lahanId),
        nama = Value(nama),
        peran = Value(peran),
        createdAt = Value(createdAt);
  static Insertable<Pekerja> custom({
    Expression<int>? id,
    Expression<int>? lahanId,
    Expression<String>? nama,
    Expression<String>? peran,
    Expression<String>? kontak,
    Expression<double>? gajiHarian,
    Expression<bool>? isActive,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lahanId != null) 'lahan_id': lahanId,
      if (nama != null) 'nama': nama,
      if (peran != null) 'peran': peran,
      if (kontak != null) 'kontak': kontak,
      if (gajiHarian != null) 'gaji_harian': gajiHarian,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PekerjasCompanion copyWith(
      {Value<int>? id,
      Value<int>? lahanId,
      Value<String>? nama,
      Value<String>? peran,
      Value<String?>? kontak,
      Value<double>? gajiHarian,
      Value<bool>? isActive,
      Value<int>? createdAt}) {
    return PekerjasCompanion(
      id: id ?? this.id,
      lahanId: lahanId ?? this.lahanId,
      nama: nama ?? this.nama,
      peran: peran ?? this.peran,
      kontak: kontak ?? this.kontak,
      gajiHarian: gajiHarian ?? this.gajiHarian,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (lahanId.present) {
      map['lahan_id'] = Variable<int>(lahanId.value);
    }
    if (nama.present) {
      map['nama'] = Variable<String>(nama.value);
    }
    if (peran.present) {
      map['peran'] = Variable<String>(peran.value);
    }
    if (kontak.present) {
      map['kontak'] = Variable<String>(kontak.value);
    }
    if (gajiHarian.present) {
      map['gaji_harian'] = Variable<double>(gajiHarian.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PekerjasCompanion(')
          ..write('id: $id, ')
          ..write('lahanId: $lahanId, ')
          ..write('nama: $nama, ')
          ..write('peran: $peran, ')
          ..write('kontak: $kontak, ')
          ..write('gajiHarian: $gajiHarian, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $HariKerjasTable extends HariKerjas
    with TableInfo<$HariKerjasTable, HariKerja> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HariKerjasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _pekerjaIdMeta =
      const VerificationMeta('pekerjaId');
  @override
  late final GeneratedColumn<int> pekerjaId = GeneratedColumn<int>(
      'pekerja_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES pekerjas (id)'));
  static const VerificationMeta _lahanIdMeta =
      const VerificationMeta('lahanId');
  @override
  late final GeneratedColumn<int> lahanId = GeneratedColumn<int>(
      'lahan_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _bulanMeta = const VerificationMeta('bulan');
  @override
  late final GeneratedColumn<String> bulan = GeneratedColumn<String>(
      'bulan', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tahunMeta = const VerificationMeta('tahun');
  @override
  late final GeneratedColumn<int> tahun = GeneratedColumn<int>(
      'tahun', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _bulanAngkaMeta =
      const VerificationMeta('bulanAngka');
  @override
  late final GeneratedColumn<int> bulanAngka = GeneratedColumn<int>(
      'bulan_angka', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _jumlahHariMeta =
      const VerificationMeta('jumlahHari');
  @override
  late final GeneratedColumn<int> jumlahHari = GeneratedColumn<int>(
      'jumlah_hari', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _totalGajiMeta =
      const VerificationMeta('totalGaji');
  @override
  late final GeneratedColumn<double> totalGaji = GeneratedColumn<double>(
      'total_gaji', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _catatanMeta =
      const VerificationMeta('catatan');
  @override
  late final GeneratedColumn<String> catatan = GeneratedColumn<String>(
      'catatan', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        pekerjaId,
        lahanId,
        bulan,
        tahun,
        bulanAngka,
        jumlahHari,
        totalGaji,
        catatan,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hari_kerjas';
  @override
  VerificationContext validateIntegrity(Insertable<HariKerja> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('pekerja_id')) {
      context.handle(_pekerjaIdMeta,
          pekerjaId.isAcceptableOrUnknown(data['pekerja_id']!, _pekerjaIdMeta));
    } else if (isInserting) {
      context.missing(_pekerjaIdMeta);
    }
    if (data.containsKey('lahan_id')) {
      context.handle(_lahanIdMeta,
          lahanId.isAcceptableOrUnknown(data['lahan_id']!, _lahanIdMeta));
    } else if (isInserting) {
      context.missing(_lahanIdMeta);
    }
    if (data.containsKey('bulan')) {
      context.handle(
          _bulanMeta, bulan.isAcceptableOrUnknown(data['bulan']!, _bulanMeta));
    } else if (isInserting) {
      context.missing(_bulanMeta);
    }
    if (data.containsKey('tahun')) {
      context.handle(
          _tahunMeta, tahun.isAcceptableOrUnknown(data['tahun']!, _tahunMeta));
    } else if (isInserting) {
      context.missing(_tahunMeta);
    }
    if (data.containsKey('bulan_angka')) {
      context.handle(
          _bulanAngkaMeta,
          bulanAngka.isAcceptableOrUnknown(
              data['bulan_angka']!, _bulanAngkaMeta));
    } else if (isInserting) {
      context.missing(_bulanAngkaMeta);
    }
    if (data.containsKey('jumlah_hari')) {
      context.handle(
          _jumlahHariMeta,
          jumlahHari.isAcceptableOrUnknown(
              data['jumlah_hari']!, _jumlahHariMeta));
    } else if (isInserting) {
      context.missing(_jumlahHariMeta);
    }
    if (data.containsKey('total_gaji')) {
      context.handle(_totalGajiMeta,
          totalGaji.isAcceptableOrUnknown(data['total_gaji']!, _totalGajiMeta));
    } else if (isInserting) {
      context.missing(_totalGajiMeta);
    }
    if (data.containsKey('catatan')) {
      context.handle(_catatanMeta,
          catatan.isAcceptableOrUnknown(data['catatan']!, _catatanMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HariKerja map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HariKerja(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      pekerjaId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}pekerja_id'])!,
      lahanId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}lahan_id'])!,
      bulan: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bulan'])!,
      tahun: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tahun'])!,
      bulanAngka: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}bulan_angka'])!,
      jumlahHari: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}jumlah_hari'])!,
      totalGaji: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_gaji'])!,
      catatan: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}catatan']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $HariKerjasTable createAlias(String alias) {
    return $HariKerjasTable(attachedDatabase, alias);
  }
}

class HariKerja extends DataClass implements Insertable<HariKerja> {
  final int id;
  final int pekerjaId;
  final int lahanId;
  final String bulan;
  final int tahun;
  final int bulanAngka;
  final int jumlahHari;
  final double totalGaji;
  final String? catatan;
  final int createdAt;
  const HariKerja(
      {required this.id,
      required this.pekerjaId,
      required this.lahanId,
      required this.bulan,
      required this.tahun,
      required this.bulanAngka,
      required this.jumlahHari,
      required this.totalGaji,
      this.catatan,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['pekerja_id'] = Variable<int>(pekerjaId);
    map['lahan_id'] = Variable<int>(lahanId);
    map['bulan'] = Variable<String>(bulan);
    map['tahun'] = Variable<int>(tahun);
    map['bulan_angka'] = Variable<int>(bulanAngka);
    map['jumlah_hari'] = Variable<int>(jumlahHari);
    map['total_gaji'] = Variable<double>(totalGaji);
    if (!nullToAbsent || catatan != null) {
      map['catatan'] = Variable<String>(catatan);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  HariKerjasCompanion toCompanion(bool nullToAbsent) {
    return HariKerjasCompanion(
      id: Value(id),
      pekerjaId: Value(pekerjaId),
      lahanId: Value(lahanId),
      bulan: Value(bulan),
      tahun: Value(tahun),
      bulanAngka: Value(bulanAngka),
      jumlahHari: Value(jumlahHari),
      totalGaji: Value(totalGaji),
      catatan: catatan == null && nullToAbsent
          ? const Value.absent()
          : Value(catatan),
      createdAt: Value(createdAt),
    );
  }

  factory HariKerja.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HariKerja(
      id: serializer.fromJson<int>(json['id']),
      pekerjaId: serializer.fromJson<int>(json['pekerjaId']),
      lahanId: serializer.fromJson<int>(json['lahanId']),
      bulan: serializer.fromJson<String>(json['bulan']),
      tahun: serializer.fromJson<int>(json['tahun']),
      bulanAngka: serializer.fromJson<int>(json['bulanAngka']),
      jumlahHari: serializer.fromJson<int>(json['jumlahHari']),
      totalGaji: serializer.fromJson<double>(json['totalGaji']),
      catatan: serializer.fromJson<String?>(json['catatan']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'pekerjaId': serializer.toJson<int>(pekerjaId),
      'lahanId': serializer.toJson<int>(lahanId),
      'bulan': serializer.toJson<String>(bulan),
      'tahun': serializer.toJson<int>(tahun),
      'bulanAngka': serializer.toJson<int>(bulanAngka),
      'jumlahHari': serializer.toJson<int>(jumlahHari),
      'totalGaji': serializer.toJson<double>(totalGaji),
      'catatan': serializer.toJson<String?>(catatan),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  HariKerja copyWith(
          {int? id,
          int? pekerjaId,
          int? lahanId,
          String? bulan,
          int? tahun,
          int? bulanAngka,
          int? jumlahHari,
          double? totalGaji,
          Value<String?> catatan = const Value.absent(),
          int? createdAt}) =>
      HariKerja(
        id: id ?? this.id,
        pekerjaId: pekerjaId ?? this.pekerjaId,
        lahanId: lahanId ?? this.lahanId,
        bulan: bulan ?? this.bulan,
        tahun: tahun ?? this.tahun,
        bulanAngka: bulanAngka ?? this.bulanAngka,
        jumlahHari: jumlahHari ?? this.jumlahHari,
        totalGaji: totalGaji ?? this.totalGaji,
        catatan: catatan.present ? catatan.value : this.catatan,
        createdAt: createdAt ?? this.createdAt,
      );
  HariKerja copyWithCompanion(HariKerjasCompanion data) {
    return HariKerja(
      id: data.id.present ? data.id.value : this.id,
      pekerjaId: data.pekerjaId.present ? data.pekerjaId.value : this.pekerjaId,
      lahanId: data.lahanId.present ? data.lahanId.value : this.lahanId,
      bulan: data.bulan.present ? data.bulan.value : this.bulan,
      tahun: data.tahun.present ? data.tahun.value : this.tahun,
      bulanAngka:
          data.bulanAngka.present ? data.bulanAngka.value : this.bulanAngka,
      jumlahHari:
          data.jumlahHari.present ? data.jumlahHari.value : this.jumlahHari,
      totalGaji: data.totalGaji.present ? data.totalGaji.value : this.totalGaji,
      catatan: data.catatan.present ? data.catatan.value : this.catatan,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HariKerja(')
          ..write('id: $id, ')
          ..write('pekerjaId: $pekerjaId, ')
          ..write('lahanId: $lahanId, ')
          ..write('bulan: $bulan, ')
          ..write('tahun: $tahun, ')
          ..write('bulanAngka: $bulanAngka, ')
          ..write('jumlahHari: $jumlahHari, ')
          ..write('totalGaji: $totalGaji, ')
          ..write('catatan: $catatan, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, pekerjaId, lahanId, bulan, tahun,
      bulanAngka, jumlahHari, totalGaji, catatan, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HariKerja &&
          other.id == this.id &&
          other.pekerjaId == this.pekerjaId &&
          other.lahanId == this.lahanId &&
          other.bulan == this.bulan &&
          other.tahun == this.tahun &&
          other.bulanAngka == this.bulanAngka &&
          other.jumlahHari == this.jumlahHari &&
          other.totalGaji == this.totalGaji &&
          other.catatan == this.catatan &&
          other.createdAt == this.createdAt);
}

class HariKerjasCompanion extends UpdateCompanion<HariKerja> {
  final Value<int> id;
  final Value<int> pekerjaId;
  final Value<int> lahanId;
  final Value<String> bulan;
  final Value<int> tahun;
  final Value<int> bulanAngka;
  final Value<int> jumlahHari;
  final Value<double> totalGaji;
  final Value<String?> catatan;
  final Value<int> createdAt;
  const HariKerjasCompanion({
    this.id = const Value.absent(),
    this.pekerjaId = const Value.absent(),
    this.lahanId = const Value.absent(),
    this.bulan = const Value.absent(),
    this.tahun = const Value.absent(),
    this.bulanAngka = const Value.absent(),
    this.jumlahHari = const Value.absent(),
    this.totalGaji = const Value.absent(),
    this.catatan = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  HariKerjasCompanion.insert({
    this.id = const Value.absent(),
    required int pekerjaId,
    required int lahanId,
    required String bulan,
    required int tahun,
    required int bulanAngka,
    required int jumlahHari,
    required double totalGaji,
    this.catatan = const Value.absent(),
    required int createdAt,
  })  : pekerjaId = Value(pekerjaId),
        lahanId = Value(lahanId),
        bulan = Value(bulan),
        tahun = Value(tahun),
        bulanAngka = Value(bulanAngka),
        jumlahHari = Value(jumlahHari),
        totalGaji = Value(totalGaji),
        createdAt = Value(createdAt);
  static Insertable<HariKerja> custom({
    Expression<int>? id,
    Expression<int>? pekerjaId,
    Expression<int>? lahanId,
    Expression<String>? bulan,
    Expression<int>? tahun,
    Expression<int>? bulanAngka,
    Expression<int>? jumlahHari,
    Expression<double>? totalGaji,
    Expression<String>? catatan,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pekerjaId != null) 'pekerja_id': pekerjaId,
      if (lahanId != null) 'lahan_id': lahanId,
      if (bulan != null) 'bulan': bulan,
      if (tahun != null) 'tahun': tahun,
      if (bulanAngka != null) 'bulan_angka': bulanAngka,
      if (jumlahHari != null) 'jumlah_hari': jumlahHari,
      if (totalGaji != null) 'total_gaji': totalGaji,
      if (catatan != null) 'catatan': catatan,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  HariKerjasCompanion copyWith(
      {Value<int>? id,
      Value<int>? pekerjaId,
      Value<int>? lahanId,
      Value<String>? bulan,
      Value<int>? tahun,
      Value<int>? bulanAngka,
      Value<int>? jumlahHari,
      Value<double>? totalGaji,
      Value<String?>? catatan,
      Value<int>? createdAt}) {
    return HariKerjasCompanion(
      id: id ?? this.id,
      pekerjaId: pekerjaId ?? this.pekerjaId,
      lahanId: lahanId ?? this.lahanId,
      bulan: bulan ?? this.bulan,
      tahun: tahun ?? this.tahun,
      bulanAngka: bulanAngka ?? this.bulanAngka,
      jumlahHari: jumlahHari ?? this.jumlahHari,
      totalGaji: totalGaji ?? this.totalGaji,
      catatan: catatan ?? this.catatan,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (pekerjaId.present) {
      map['pekerja_id'] = Variable<int>(pekerjaId.value);
    }
    if (lahanId.present) {
      map['lahan_id'] = Variable<int>(lahanId.value);
    }
    if (bulan.present) {
      map['bulan'] = Variable<String>(bulan.value);
    }
    if (tahun.present) {
      map['tahun'] = Variable<int>(tahun.value);
    }
    if (bulanAngka.present) {
      map['bulan_angka'] = Variable<int>(bulanAngka.value);
    }
    if (jumlahHari.present) {
      map['jumlah_hari'] = Variable<int>(jumlahHari.value);
    }
    if (totalGaji.present) {
      map['total_gaji'] = Variable<double>(totalGaji.value);
    }
    if (catatan.present) {
      map['catatan'] = Variable<String>(catatan.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HariKerjasCompanion(')
          ..write('id: $id, ')
          ..write('pekerjaId: $pekerjaId, ')
          ..write('lahanId: $lahanId, ')
          ..write('bulan: $bulan, ')
          ..write('tahun: $tahun, ')
          ..write('bulanAngka: $bulanAngka, ')
          ..write('jumlahHari: $jumlahHari, ')
          ..write('totalGaji: $totalGaji, ')
          ..write('catatan: $catatan, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $InventoryPupuksTable extends InventoryPupuks
    with TableInfo<$InventoryPupuksTable, InventoryPupuk> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventoryPupuksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _lahanIdMeta =
      const VerificationMeta('lahanId');
  @override
  late final GeneratedColumn<int> lahanId = GeneratedColumn<int>(
      'lahan_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _namaPupukMeta =
      const VerificationMeta('namaPupuk');
  @override
  late final GeneratedColumn<String> namaPupuk = GeneratedColumn<String>(
      'nama_pupuk', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _stokKgMeta = const VerificationMeta('stokKg');
  @override
  late final GeneratedColumn<double> stokKg = GeneratedColumn<double>(
      'stok_kg', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _thresholdAlertMeta =
      const VerificationMeta('thresholdAlert');
  @override
  late final GeneratedColumn<double> thresholdAlert = GeneratedColumn<double>(
      'threshold_alert', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(50));
  static const VerificationMeta _expiredAtMeta =
      const VerificationMeta('expiredAt');
  @override
  late final GeneratedColumn<int> expiredAt = GeneratedColumn<int>(
      'expired_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _catatanMeta =
      const VerificationMeta('catatan');
  @override
  late final GeneratedColumn<String> catatan = GeneratedColumn<String>(
      'catatan', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        lahanId,
        namaPupuk,
        stokKg,
        thresholdAlert,
        expiredAt,
        catatan,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventory_pupuks';
  @override
  VerificationContext validateIntegrity(Insertable<InventoryPupuk> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('lahan_id')) {
      context.handle(_lahanIdMeta,
          lahanId.isAcceptableOrUnknown(data['lahan_id']!, _lahanIdMeta));
    } else if (isInserting) {
      context.missing(_lahanIdMeta);
    }
    if (data.containsKey('nama_pupuk')) {
      context.handle(_namaPupukMeta,
          namaPupuk.isAcceptableOrUnknown(data['nama_pupuk']!, _namaPupukMeta));
    } else if (isInserting) {
      context.missing(_namaPupukMeta);
    }
    if (data.containsKey('stok_kg')) {
      context.handle(_stokKgMeta,
          stokKg.isAcceptableOrUnknown(data['stok_kg']!, _stokKgMeta));
    }
    if (data.containsKey('threshold_alert')) {
      context.handle(
          _thresholdAlertMeta,
          thresholdAlert.isAcceptableOrUnknown(
              data['threshold_alert']!, _thresholdAlertMeta));
    }
    if (data.containsKey('expired_at')) {
      context.handle(_expiredAtMeta,
          expiredAt.isAcceptableOrUnknown(data['expired_at']!, _expiredAtMeta));
    }
    if (data.containsKey('catatan')) {
      context.handle(_catatanMeta,
          catatan.isAcceptableOrUnknown(data['catatan']!, _catatanMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InventoryPupuk map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventoryPupuk(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      lahanId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}lahan_id'])!,
      namaPupuk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nama_pupuk'])!,
      stokKg: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}stok_kg'])!,
      thresholdAlert: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}threshold_alert'])!,
      expiredAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}expired_at']),
      catatan: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}catatan']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $InventoryPupuksTable createAlias(String alias) {
    return $InventoryPupuksTable(attachedDatabase, alias);
  }
}

class InventoryPupuk extends DataClass implements Insertable<InventoryPupuk> {
  final int id;
  final int lahanId;
  final String namaPupuk;
  final double stokKg;
  final double thresholdAlert;
  final int? expiredAt;
  final String? catatan;
  final int updatedAt;
  const InventoryPupuk(
      {required this.id,
      required this.lahanId,
      required this.namaPupuk,
      required this.stokKg,
      required this.thresholdAlert,
      this.expiredAt,
      this.catatan,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['lahan_id'] = Variable<int>(lahanId);
    map['nama_pupuk'] = Variable<String>(namaPupuk);
    map['stok_kg'] = Variable<double>(stokKg);
    map['threshold_alert'] = Variable<double>(thresholdAlert);
    if (!nullToAbsent || expiredAt != null) {
      map['expired_at'] = Variable<int>(expiredAt);
    }
    if (!nullToAbsent || catatan != null) {
      map['catatan'] = Variable<String>(catatan);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  InventoryPupuksCompanion toCompanion(bool nullToAbsent) {
    return InventoryPupuksCompanion(
      id: Value(id),
      lahanId: Value(lahanId),
      namaPupuk: Value(namaPupuk),
      stokKg: Value(stokKg),
      thresholdAlert: Value(thresholdAlert),
      expiredAt: expiredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiredAt),
      catatan: catatan == null && nullToAbsent
          ? const Value.absent()
          : Value(catatan),
      updatedAt: Value(updatedAt),
    );
  }

  factory InventoryPupuk.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventoryPupuk(
      id: serializer.fromJson<int>(json['id']),
      lahanId: serializer.fromJson<int>(json['lahanId']),
      namaPupuk: serializer.fromJson<String>(json['namaPupuk']),
      stokKg: serializer.fromJson<double>(json['stokKg']),
      thresholdAlert: serializer.fromJson<double>(json['thresholdAlert']),
      expiredAt: serializer.fromJson<int?>(json['expiredAt']),
      catatan: serializer.fromJson<String?>(json['catatan']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'lahanId': serializer.toJson<int>(lahanId),
      'namaPupuk': serializer.toJson<String>(namaPupuk),
      'stokKg': serializer.toJson<double>(stokKg),
      'thresholdAlert': serializer.toJson<double>(thresholdAlert),
      'expiredAt': serializer.toJson<int?>(expiredAt),
      'catatan': serializer.toJson<String?>(catatan),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  InventoryPupuk copyWith(
          {int? id,
          int? lahanId,
          String? namaPupuk,
          double? stokKg,
          double? thresholdAlert,
          Value<int?> expiredAt = const Value.absent(),
          Value<String?> catatan = const Value.absent(),
          int? updatedAt}) =>
      InventoryPupuk(
        id: id ?? this.id,
        lahanId: lahanId ?? this.lahanId,
        namaPupuk: namaPupuk ?? this.namaPupuk,
        stokKg: stokKg ?? this.stokKg,
        thresholdAlert: thresholdAlert ?? this.thresholdAlert,
        expiredAt: expiredAt.present ? expiredAt.value : this.expiredAt,
        catatan: catatan.present ? catatan.value : this.catatan,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  InventoryPupuk copyWithCompanion(InventoryPupuksCompanion data) {
    return InventoryPupuk(
      id: data.id.present ? data.id.value : this.id,
      lahanId: data.lahanId.present ? data.lahanId.value : this.lahanId,
      namaPupuk: data.namaPupuk.present ? data.namaPupuk.value : this.namaPupuk,
      stokKg: data.stokKg.present ? data.stokKg.value : this.stokKg,
      thresholdAlert: data.thresholdAlert.present
          ? data.thresholdAlert.value
          : this.thresholdAlert,
      expiredAt: data.expiredAt.present ? data.expiredAt.value : this.expiredAt,
      catatan: data.catatan.present ? data.catatan.value : this.catatan,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventoryPupuk(')
          ..write('id: $id, ')
          ..write('lahanId: $lahanId, ')
          ..write('namaPupuk: $namaPupuk, ')
          ..write('stokKg: $stokKg, ')
          ..write('thresholdAlert: $thresholdAlert, ')
          ..write('expiredAt: $expiredAt, ')
          ..write('catatan: $catatan, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, lahanId, namaPupuk, stokKg,
      thresholdAlert, expiredAt, catatan, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventoryPupuk &&
          other.id == this.id &&
          other.lahanId == this.lahanId &&
          other.namaPupuk == this.namaPupuk &&
          other.stokKg == this.stokKg &&
          other.thresholdAlert == this.thresholdAlert &&
          other.expiredAt == this.expiredAt &&
          other.catatan == this.catatan &&
          other.updatedAt == this.updatedAt);
}

class InventoryPupuksCompanion extends UpdateCompanion<InventoryPupuk> {
  final Value<int> id;
  final Value<int> lahanId;
  final Value<String> namaPupuk;
  final Value<double> stokKg;
  final Value<double> thresholdAlert;
  final Value<int?> expiredAt;
  final Value<String?> catatan;
  final Value<int> updatedAt;
  const InventoryPupuksCompanion({
    this.id = const Value.absent(),
    this.lahanId = const Value.absent(),
    this.namaPupuk = const Value.absent(),
    this.stokKg = const Value.absent(),
    this.thresholdAlert = const Value.absent(),
    this.expiredAt = const Value.absent(),
    this.catatan = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  InventoryPupuksCompanion.insert({
    this.id = const Value.absent(),
    required int lahanId,
    required String namaPupuk,
    this.stokKg = const Value.absent(),
    this.thresholdAlert = const Value.absent(),
    this.expiredAt = const Value.absent(),
    this.catatan = const Value.absent(),
    required int updatedAt,
  })  : lahanId = Value(lahanId),
        namaPupuk = Value(namaPupuk),
        updatedAt = Value(updatedAt);
  static Insertable<InventoryPupuk> custom({
    Expression<int>? id,
    Expression<int>? lahanId,
    Expression<String>? namaPupuk,
    Expression<double>? stokKg,
    Expression<double>? thresholdAlert,
    Expression<int>? expiredAt,
    Expression<String>? catatan,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lahanId != null) 'lahan_id': lahanId,
      if (namaPupuk != null) 'nama_pupuk': namaPupuk,
      if (stokKg != null) 'stok_kg': stokKg,
      if (thresholdAlert != null) 'threshold_alert': thresholdAlert,
      if (expiredAt != null) 'expired_at': expiredAt,
      if (catatan != null) 'catatan': catatan,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  InventoryPupuksCompanion copyWith(
      {Value<int>? id,
      Value<int>? lahanId,
      Value<String>? namaPupuk,
      Value<double>? stokKg,
      Value<double>? thresholdAlert,
      Value<int?>? expiredAt,
      Value<String?>? catatan,
      Value<int>? updatedAt}) {
    return InventoryPupuksCompanion(
      id: id ?? this.id,
      lahanId: lahanId ?? this.lahanId,
      namaPupuk: namaPupuk ?? this.namaPupuk,
      stokKg: stokKg ?? this.stokKg,
      thresholdAlert: thresholdAlert ?? this.thresholdAlert,
      expiredAt: expiredAt ?? this.expiredAt,
      catatan: catatan ?? this.catatan,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (lahanId.present) {
      map['lahan_id'] = Variable<int>(lahanId.value);
    }
    if (namaPupuk.present) {
      map['nama_pupuk'] = Variable<String>(namaPupuk.value);
    }
    if (stokKg.present) {
      map['stok_kg'] = Variable<double>(stokKg.value);
    }
    if (thresholdAlert.present) {
      map['threshold_alert'] = Variable<double>(thresholdAlert.value);
    }
    if (expiredAt.present) {
      map['expired_at'] = Variable<int>(expiredAt.value);
    }
    if (catatan.present) {
      map['catatan'] = Variable<String>(catatan.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventoryPupuksCompanion(')
          ..write('id: $id, ')
          ..write('lahanId: $lahanId, ')
          ..write('namaPupuk: $namaPupuk, ')
          ..write('stokKg: $stokKg, ')
          ..write('thresholdAlert: $thresholdAlert, ')
          ..write('expiredAt: $expiredAt, ')
          ..write('catatan: $catatan, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $JadwalPupuksTable extends JadwalPupuks
    with TableInfo<$JadwalPupuksTable, JadwalPupuk> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JadwalPupuksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _lahanIdMeta =
      const VerificationMeta('lahanId');
  @override
  late final GeneratedColumn<int> lahanId = GeneratedColumn<int>(
      'lahan_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _siklusHariMeta =
      const VerificationMeta('siklusHari');
  @override
  late final GeneratedColumn<int> siklusHari = GeneratedColumn<int>(
      'siklus_hari', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(90));
  static const VerificationMeta _lastPemupukanAtMeta =
      const VerificationMeta('lastPemupukanAt');
  @override
  late final GeneratedColumn<int> lastPemupukanAt = GeneratedColumn<int>(
      'last_pemupukan_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nextReminderAtMeta =
      const VerificationMeta('nextReminderAt');
  @override
  late final GeneratedColumn<int> nextReminderAt = GeneratedColumn<int>(
      'next_reminder_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _notificationIdMeta =
      const VerificationMeta('notificationId');
  @override
  late final GeneratedColumn<int> notificationId = GeneratedColumn<int>(
      'notification_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _jenisPupukMeta =
      const VerificationMeta('jenisPupuk');
  @override
  late final GeneratedColumn<String> jenisPupuk = GeneratedColumn<String>(
      'jenis_pupuk', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        lahanId,
        siklusHari,
        lastPemupukanAt,
        nextReminderAt,
        notificationId,
        isActive,
        jenisPupuk,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'jadwal_pupuks';
  @override
  VerificationContext validateIntegrity(Insertable<JadwalPupuk> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('lahan_id')) {
      context.handle(_lahanIdMeta,
          lahanId.isAcceptableOrUnknown(data['lahan_id']!, _lahanIdMeta));
    } else if (isInserting) {
      context.missing(_lahanIdMeta);
    }
    if (data.containsKey('siklus_hari')) {
      context.handle(
          _siklusHariMeta,
          siklusHari.isAcceptableOrUnknown(
              data['siklus_hari']!, _siklusHariMeta));
    }
    if (data.containsKey('last_pemupukan_at')) {
      context.handle(
          _lastPemupukanAtMeta,
          lastPemupukanAt.isAcceptableOrUnknown(
              data['last_pemupukan_at']!, _lastPemupukanAtMeta));
    }
    if (data.containsKey('next_reminder_at')) {
      context.handle(
          _nextReminderAtMeta,
          nextReminderAt.isAcceptableOrUnknown(
              data['next_reminder_at']!, _nextReminderAtMeta));
    }
    if (data.containsKey('notification_id')) {
      context.handle(
          _notificationIdMeta,
          notificationId.isAcceptableOrUnknown(
              data['notification_id']!, _notificationIdMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('jenis_pupuk')) {
      context.handle(
          _jenisPupukMeta,
          jenisPupuk.isAcceptableOrUnknown(
              data['jenis_pupuk']!, _jenisPupukMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  JadwalPupuk map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JadwalPupuk(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      lahanId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}lahan_id'])!,
      siklusHari: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}siklus_hari'])!,
      lastPemupukanAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_pemupukan_at']),
      nextReminderAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}next_reminder_at']),
      notificationId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}notification_id']),
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      jenisPupuk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}jenis_pupuk']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $JadwalPupuksTable createAlias(String alias) {
    return $JadwalPupuksTable(attachedDatabase, alias);
  }
}

class JadwalPupuk extends DataClass implements Insertable<JadwalPupuk> {
  final int id;
  final int lahanId;

  /// Siklus dalam hari (default 90)
  final int siklusHari;

  /// Tanggal pemupukan terakhir (unix ms timestamp)
  final int? lastPemupukanAt;

  /// Tanggal jadwal berikutnya (computed; unix ms timestamp)
  final int? nextReminderAt;

  /// Local notification ID (untuk cancel/reschedule)
  final int? notificationId;

  /// Active flag — user bisa pause reminder per lahan
  final bool isActive;

  /// Catatan/jenis pupuk
  final String? jenisPupuk;
  final int updatedAt;
  const JadwalPupuk(
      {required this.id,
      required this.lahanId,
      required this.siklusHari,
      this.lastPemupukanAt,
      this.nextReminderAt,
      this.notificationId,
      required this.isActive,
      this.jenisPupuk,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['lahan_id'] = Variable<int>(lahanId);
    map['siklus_hari'] = Variable<int>(siklusHari);
    if (!nullToAbsent || lastPemupukanAt != null) {
      map['last_pemupukan_at'] = Variable<int>(lastPemupukanAt);
    }
    if (!nullToAbsent || nextReminderAt != null) {
      map['next_reminder_at'] = Variable<int>(nextReminderAt);
    }
    if (!nullToAbsent || notificationId != null) {
      map['notification_id'] = Variable<int>(notificationId);
    }
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || jenisPupuk != null) {
      map['jenis_pupuk'] = Variable<String>(jenisPupuk);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  JadwalPupuksCompanion toCompanion(bool nullToAbsent) {
    return JadwalPupuksCompanion(
      id: Value(id),
      lahanId: Value(lahanId),
      siklusHari: Value(siklusHari),
      lastPemupukanAt: lastPemupukanAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPemupukanAt),
      nextReminderAt: nextReminderAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextReminderAt),
      notificationId: notificationId == null && nullToAbsent
          ? const Value.absent()
          : Value(notificationId),
      isActive: Value(isActive),
      jenisPupuk: jenisPupuk == null && nullToAbsent
          ? const Value.absent()
          : Value(jenisPupuk),
      updatedAt: Value(updatedAt),
    );
  }

  factory JadwalPupuk.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JadwalPupuk(
      id: serializer.fromJson<int>(json['id']),
      lahanId: serializer.fromJson<int>(json['lahanId']),
      siklusHari: serializer.fromJson<int>(json['siklusHari']),
      lastPemupukanAt: serializer.fromJson<int?>(json['lastPemupukanAt']),
      nextReminderAt: serializer.fromJson<int?>(json['nextReminderAt']),
      notificationId: serializer.fromJson<int?>(json['notificationId']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      jenisPupuk: serializer.fromJson<String?>(json['jenisPupuk']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'lahanId': serializer.toJson<int>(lahanId),
      'siklusHari': serializer.toJson<int>(siklusHari),
      'lastPemupukanAt': serializer.toJson<int?>(lastPemupukanAt),
      'nextReminderAt': serializer.toJson<int?>(nextReminderAt),
      'notificationId': serializer.toJson<int?>(notificationId),
      'isActive': serializer.toJson<bool>(isActive),
      'jenisPupuk': serializer.toJson<String?>(jenisPupuk),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  JadwalPupuk copyWith(
          {int? id,
          int? lahanId,
          int? siklusHari,
          Value<int?> lastPemupukanAt = const Value.absent(),
          Value<int?> nextReminderAt = const Value.absent(),
          Value<int?> notificationId = const Value.absent(),
          bool? isActive,
          Value<String?> jenisPupuk = const Value.absent(),
          int? updatedAt}) =>
      JadwalPupuk(
        id: id ?? this.id,
        lahanId: lahanId ?? this.lahanId,
        siklusHari: siklusHari ?? this.siklusHari,
        lastPemupukanAt: lastPemupukanAt.present
            ? lastPemupukanAt.value
            : this.lastPemupukanAt,
        nextReminderAt:
            nextReminderAt.present ? nextReminderAt.value : this.nextReminderAt,
        notificationId:
            notificationId.present ? notificationId.value : this.notificationId,
        isActive: isActive ?? this.isActive,
        jenisPupuk: jenisPupuk.present ? jenisPupuk.value : this.jenisPupuk,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  JadwalPupuk copyWithCompanion(JadwalPupuksCompanion data) {
    return JadwalPupuk(
      id: data.id.present ? data.id.value : this.id,
      lahanId: data.lahanId.present ? data.lahanId.value : this.lahanId,
      siklusHari:
          data.siklusHari.present ? data.siklusHari.value : this.siklusHari,
      lastPemupukanAt: data.lastPemupukanAt.present
          ? data.lastPemupukanAt.value
          : this.lastPemupukanAt,
      nextReminderAt: data.nextReminderAt.present
          ? data.nextReminderAt.value
          : this.nextReminderAt,
      notificationId: data.notificationId.present
          ? data.notificationId.value
          : this.notificationId,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      jenisPupuk:
          data.jenisPupuk.present ? data.jenisPupuk.value : this.jenisPupuk,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JadwalPupuk(')
          ..write('id: $id, ')
          ..write('lahanId: $lahanId, ')
          ..write('siklusHari: $siklusHari, ')
          ..write('lastPemupukanAt: $lastPemupukanAt, ')
          ..write('nextReminderAt: $nextReminderAt, ')
          ..write('notificationId: $notificationId, ')
          ..write('isActive: $isActive, ')
          ..write('jenisPupuk: $jenisPupuk, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, lahanId, siklusHari, lastPemupukanAt,
      nextReminderAt, notificationId, isActive, jenisPupuk, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JadwalPupuk &&
          other.id == this.id &&
          other.lahanId == this.lahanId &&
          other.siklusHari == this.siklusHari &&
          other.lastPemupukanAt == this.lastPemupukanAt &&
          other.nextReminderAt == this.nextReminderAt &&
          other.notificationId == this.notificationId &&
          other.isActive == this.isActive &&
          other.jenisPupuk == this.jenisPupuk &&
          other.updatedAt == this.updatedAt);
}

class JadwalPupuksCompanion extends UpdateCompanion<JadwalPupuk> {
  final Value<int> id;
  final Value<int> lahanId;
  final Value<int> siklusHari;
  final Value<int?> lastPemupukanAt;
  final Value<int?> nextReminderAt;
  final Value<int?> notificationId;
  final Value<bool> isActive;
  final Value<String?> jenisPupuk;
  final Value<int> updatedAt;
  const JadwalPupuksCompanion({
    this.id = const Value.absent(),
    this.lahanId = const Value.absent(),
    this.siklusHari = const Value.absent(),
    this.lastPemupukanAt = const Value.absent(),
    this.nextReminderAt = const Value.absent(),
    this.notificationId = const Value.absent(),
    this.isActive = const Value.absent(),
    this.jenisPupuk = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  JadwalPupuksCompanion.insert({
    this.id = const Value.absent(),
    required int lahanId,
    this.siklusHari = const Value.absent(),
    this.lastPemupukanAt = const Value.absent(),
    this.nextReminderAt = const Value.absent(),
    this.notificationId = const Value.absent(),
    this.isActive = const Value.absent(),
    this.jenisPupuk = const Value.absent(),
    required int updatedAt,
  })  : lahanId = Value(lahanId),
        updatedAt = Value(updatedAt);
  static Insertable<JadwalPupuk> custom({
    Expression<int>? id,
    Expression<int>? lahanId,
    Expression<int>? siklusHari,
    Expression<int>? lastPemupukanAt,
    Expression<int>? nextReminderAt,
    Expression<int>? notificationId,
    Expression<bool>? isActive,
    Expression<String>? jenisPupuk,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lahanId != null) 'lahan_id': lahanId,
      if (siklusHari != null) 'siklus_hari': siklusHari,
      if (lastPemupukanAt != null) 'last_pemupukan_at': lastPemupukanAt,
      if (nextReminderAt != null) 'next_reminder_at': nextReminderAt,
      if (notificationId != null) 'notification_id': notificationId,
      if (isActive != null) 'is_active': isActive,
      if (jenisPupuk != null) 'jenis_pupuk': jenisPupuk,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  JadwalPupuksCompanion copyWith(
      {Value<int>? id,
      Value<int>? lahanId,
      Value<int>? siklusHari,
      Value<int?>? lastPemupukanAt,
      Value<int?>? nextReminderAt,
      Value<int?>? notificationId,
      Value<bool>? isActive,
      Value<String?>? jenisPupuk,
      Value<int>? updatedAt}) {
    return JadwalPupuksCompanion(
      id: id ?? this.id,
      lahanId: lahanId ?? this.lahanId,
      siklusHari: siklusHari ?? this.siklusHari,
      lastPemupukanAt: lastPemupukanAt ?? this.lastPemupukanAt,
      nextReminderAt: nextReminderAt ?? this.nextReminderAt,
      notificationId: notificationId ?? this.notificationId,
      isActive: isActive ?? this.isActive,
      jenisPupuk: jenisPupuk ?? this.jenisPupuk,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (lahanId.present) {
      map['lahan_id'] = Variable<int>(lahanId.value);
    }
    if (siklusHari.present) {
      map['siklus_hari'] = Variable<int>(siklusHari.value);
    }
    if (lastPemupukanAt.present) {
      map['last_pemupukan_at'] = Variable<int>(lastPemupukanAt.value);
    }
    if (nextReminderAt.present) {
      map['next_reminder_at'] = Variable<int>(nextReminderAt.value);
    }
    if (notificationId.present) {
      map['notification_id'] = Variable<int>(notificationId.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (jenisPupuk.present) {
      map['jenis_pupuk'] = Variable<String>(jenisPupuk.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JadwalPupuksCompanion(')
          ..write('id: $id, ')
          ..write('lahanId: $lahanId, ')
          ..write('siklusHari: $siklusHari, ')
          ..write('lastPemupukanAt: $lastPemupukanAt, ')
          ..write('nextReminderAt: $nextReminderAt, ')
          ..write('notificationId: $notificationId, ')
          ..write('isActive: $isActive, ')
          ..write('jenisPupuk: $jenisPupuk, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LahansTable lahans = $LahansTable(this);
  late final $PanensTable panens = $PanensTable(this);
  late final $BiayasTable biayas = $BiayasTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final $PekerjasTable pekerjas = $PekerjasTable(this);
  late final $HariKerjasTable hariKerjas = $HariKerjasTable(this);
  late final $InventoryPupuksTable inventoryPupuks =
      $InventoryPupuksTable(this);
  late final $JadwalPupuksTable jadwalPupuks = $JadwalPupuksTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        lahans,
        panens,
        biayas,
        syncQueue,
        pekerjas,
        hariKerjas,
        inventoryPupuks,
        jadwalPupuks
      ];
}

typedef $$LahansTableCreateCompanionBuilder = LahansCompanion Function({
  Value<int> id,
  required String namaLahan,
  required double luasHa,
  required int usiaPohon,
  Value<int?> tahunTanam,
  Value<int?> jumlahPohon,
  Value<String?> lokasi,
  Value<bool> isActive,
  required int cachedAt,
});
typedef $$LahansTableUpdateCompanionBuilder = LahansCompanion Function({
  Value<int> id,
  Value<String> namaLahan,
  Value<double> luasHa,
  Value<int> usiaPohon,
  Value<int?> tahunTanam,
  Value<int?> jumlahPohon,
  Value<String?> lokasi,
  Value<bool> isActive,
  Value<int> cachedAt,
});

class $$LahansTableFilterComposer
    extends Composer<_$AppDatabase, $LahansTable> {
  $$LahansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get namaLahan => $composableBuilder(
      column: $table.namaLahan, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get luasHa => $composableBuilder(
      column: $table.luasHa, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get usiaPohon => $composableBuilder(
      column: $table.usiaPohon, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get tahunTanam => $composableBuilder(
      column: $table.tahunTanam, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get jumlahPohon => $composableBuilder(
      column: $table.jumlahPohon, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lokasi => $composableBuilder(
      column: $table.lokasi, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnFilters(column));
}

class $$LahansTableOrderingComposer
    extends Composer<_$AppDatabase, $LahansTable> {
  $$LahansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get namaLahan => $composableBuilder(
      column: $table.namaLahan, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get luasHa => $composableBuilder(
      column: $table.luasHa, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get usiaPohon => $composableBuilder(
      column: $table.usiaPohon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get tahunTanam => $composableBuilder(
      column: $table.tahunTanam, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get jumlahPohon => $composableBuilder(
      column: $table.jumlahPohon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lokasi => $composableBuilder(
      column: $table.lokasi, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnOrderings(column));
}

class $$LahansTableAnnotationComposer
    extends Composer<_$AppDatabase, $LahansTable> {
  $$LahansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get namaLahan =>
      $composableBuilder(column: $table.namaLahan, builder: (column) => column);

  GeneratedColumn<double> get luasHa =>
      $composableBuilder(column: $table.luasHa, builder: (column) => column);

  GeneratedColumn<int> get usiaPohon =>
      $composableBuilder(column: $table.usiaPohon, builder: (column) => column);

  GeneratedColumn<int> get tahunTanam => $composableBuilder(
      column: $table.tahunTanam, builder: (column) => column);

  GeneratedColumn<int> get jumlahPohon => $composableBuilder(
      column: $table.jumlahPohon, builder: (column) => column);

  GeneratedColumn<String> get lokasi =>
      $composableBuilder(column: $table.lokasi, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$LahansTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LahansTable,
    Lahan,
    $$LahansTableFilterComposer,
    $$LahansTableOrderingComposer,
    $$LahansTableAnnotationComposer,
    $$LahansTableCreateCompanionBuilder,
    $$LahansTableUpdateCompanionBuilder,
    (Lahan, BaseReferences<_$AppDatabase, $LahansTable, Lahan>),
    Lahan,
    PrefetchHooks Function()> {
  $$LahansTableTableManager(_$AppDatabase db, $LahansTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LahansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LahansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LahansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> namaLahan = const Value.absent(),
            Value<double> luasHa = const Value.absent(),
            Value<int> usiaPohon = const Value.absent(),
            Value<int?> tahunTanam = const Value.absent(),
            Value<int?> jumlahPohon = const Value.absent(),
            Value<String?> lokasi = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<int> cachedAt = const Value.absent(),
          }) =>
              LahansCompanion(
            id: id,
            namaLahan: namaLahan,
            luasHa: luasHa,
            usiaPohon: usiaPohon,
            tahunTanam: tahunTanam,
            jumlahPohon: jumlahPohon,
            lokasi: lokasi,
            isActive: isActive,
            cachedAt: cachedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String namaLahan,
            required double luasHa,
            required int usiaPohon,
            Value<int?> tahunTanam = const Value.absent(),
            Value<int?> jumlahPohon = const Value.absent(),
            Value<String?> lokasi = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            required int cachedAt,
          }) =>
              LahansCompanion.insert(
            id: id,
            namaLahan: namaLahan,
            luasHa: luasHa,
            usiaPohon: usiaPohon,
            tahunTanam: tahunTanam,
            jumlahPohon: jumlahPohon,
            lokasi: lokasi,
            isActive: isActive,
            cachedAt: cachedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LahansTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LahansTable,
    Lahan,
    $$LahansTableFilterComposer,
    $$LahansTableOrderingComposer,
    $$LahansTableAnnotationComposer,
    $$LahansTableCreateCompanionBuilder,
    $$LahansTableUpdateCompanionBuilder,
    (Lahan, BaseReferences<_$AppDatabase, $LahansTable, Lahan>),
    Lahan,
    PrefetchHooks Function()>;
typedef $$PanensTableCreateCompanionBuilder = PanensCompanion Function({
  Value<int> id,
  required int lahanId,
  required String bulan,
  required int tahun,
  required int bulanAngka,
  Value<int?> tanggal,
  required double tonAktual,
  Value<double> targetMin,
  Value<double> targetMax,
  Value<double> targetMid,
  Value<double> hargaPerTon,
  Value<String?> statusPanen,
  Value<double> persenKurang,
  Value<double> luasHa,
  Value<int> usiaPohon,
  required int cachedAt,
});
typedef $$PanensTableUpdateCompanionBuilder = PanensCompanion Function({
  Value<int> id,
  Value<int> lahanId,
  Value<String> bulan,
  Value<int> tahun,
  Value<int> bulanAngka,
  Value<int?> tanggal,
  Value<double> tonAktual,
  Value<double> targetMin,
  Value<double> targetMax,
  Value<double> targetMid,
  Value<double> hargaPerTon,
  Value<String?> statusPanen,
  Value<double> persenKurang,
  Value<double> luasHa,
  Value<int> usiaPohon,
  Value<int> cachedAt,
});

class $$PanensTableFilterComposer
    extends Composer<_$AppDatabase, $PanensTable> {
  $$PanensTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lahanId => $composableBuilder(
      column: $table.lahanId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bulan => $composableBuilder(
      column: $table.bulan, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get tahun => $composableBuilder(
      column: $table.tahun, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get bulanAngka => $composableBuilder(
      column: $table.bulanAngka, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get tanggal => $composableBuilder(
      column: $table.tanggal, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get tonAktual => $composableBuilder(
      column: $table.tonAktual, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get targetMin => $composableBuilder(
      column: $table.targetMin, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get targetMax => $composableBuilder(
      column: $table.targetMax, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get targetMid => $composableBuilder(
      column: $table.targetMid, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get hargaPerTon => $composableBuilder(
      column: $table.hargaPerTon, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get statusPanen => $composableBuilder(
      column: $table.statusPanen, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get persenKurang => $composableBuilder(
      column: $table.persenKurang, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get luasHa => $composableBuilder(
      column: $table.luasHa, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get usiaPohon => $composableBuilder(
      column: $table.usiaPohon, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnFilters(column));
}

class $$PanensTableOrderingComposer
    extends Composer<_$AppDatabase, $PanensTable> {
  $$PanensTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lahanId => $composableBuilder(
      column: $table.lahanId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bulan => $composableBuilder(
      column: $table.bulan, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get tahun => $composableBuilder(
      column: $table.tahun, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get bulanAngka => $composableBuilder(
      column: $table.bulanAngka, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get tanggal => $composableBuilder(
      column: $table.tanggal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get tonAktual => $composableBuilder(
      column: $table.tonAktual, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get targetMin => $composableBuilder(
      column: $table.targetMin, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get targetMax => $composableBuilder(
      column: $table.targetMax, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get targetMid => $composableBuilder(
      column: $table.targetMid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get hargaPerTon => $composableBuilder(
      column: $table.hargaPerTon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get statusPanen => $composableBuilder(
      column: $table.statusPanen, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get persenKurang => $composableBuilder(
      column: $table.persenKurang,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get luasHa => $composableBuilder(
      column: $table.luasHa, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get usiaPohon => $composableBuilder(
      column: $table.usiaPohon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnOrderings(column));
}

class $$PanensTableAnnotationComposer
    extends Composer<_$AppDatabase, $PanensTable> {
  $$PanensTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get lahanId =>
      $composableBuilder(column: $table.lahanId, builder: (column) => column);

  GeneratedColumn<String> get bulan =>
      $composableBuilder(column: $table.bulan, builder: (column) => column);

  GeneratedColumn<int> get tahun =>
      $composableBuilder(column: $table.tahun, builder: (column) => column);

  GeneratedColumn<int> get bulanAngka => $composableBuilder(
      column: $table.bulanAngka, builder: (column) => column);

  GeneratedColumn<int> get tanggal =>
      $composableBuilder(column: $table.tanggal, builder: (column) => column);

  GeneratedColumn<double> get tonAktual =>
      $composableBuilder(column: $table.tonAktual, builder: (column) => column);

  GeneratedColumn<double> get targetMin =>
      $composableBuilder(column: $table.targetMin, builder: (column) => column);

  GeneratedColumn<double> get targetMax =>
      $composableBuilder(column: $table.targetMax, builder: (column) => column);

  GeneratedColumn<double> get targetMid =>
      $composableBuilder(column: $table.targetMid, builder: (column) => column);

  GeneratedColumn<double> get hargaPerTon => $composableBuilder(
      column: $table.hargaPerTon, builder: (column) => column);

  GeneratedColumn<String> get statusPanen => $composableBuilder(
      column: $table.statusPanen, builder: (column) => column);

  GeneratedColumn<double> get persenKurang => $composableBuilder(
      column: $table.persenKurang, builder: (column) => column);

  GeneratedColumn<double> get luasHa =>
      $composableBuilder(column: $table.luasHa, builder: (column) => column);

  GeneratedColumn<int> get usiaPohon =>
      $composableBuilder(column: $table.usiaPohon, builder: (column) => column);

  GeneratedColumn<int> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$PanensTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PanensTable,
    Panen,
    $$PanensTableFilterComposer,
    $$PanensTableOrderingComposer,
    $$PanensTableAnnotationComposer,
    $$PanensTableCreateCompanionBuilder,
    $$PanensTableUpdateCompanionBuilder,
    (Panen, BaseReferences<_$AppDatabase, $PanensTable, Panen>),
    Panen,
    PrefetchHooks Function()> {
  $$PanensTableTableManager(_$AppDatabase db, $PanensTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PanensTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PanensTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PanensTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> lahanId = const Value.absent(),
            Value<String> bulan = const Value.absent(),
            Value<int> tahun = const Value.absent(),
            Value<int> bulanAngka = const Value.absent(),
            Value<int?> tanggal = const Value.absent(),
            Value<double> tonAktual = const Value.absent(),
            Value<double> targetMin = const Value.absent(),
            Value<double> targetMax = const Value.absent(),
            Value<double> targetMid = const Value.absent(),
            Value<double> hargaPerTon = const Value.absent(),
            Value<String?> statusPanen = const Value.absent(),
            Value<double> persenKurang = const Value.absent(),
            Value<double> luasHa = const Value.absent(),
            Value<int> usiaPohon = const Value.absent(),
            Value<int> cachedAt = const Value.absent(),
          }) =>
              PanensCompanion(
            id: id,
            lahanId: lahanId,
            bulan: bulan,
            tahun: tahun,
            bulanAngka: bulanAngka,
            tanggal: tanggal,
            tonAktual: tonAktual,
            targetMin: targetMin,
            targetMax: targetMax,
            targetMid: targetMid,
            hargaPerTon: hargaPerTon,
            statusPanen: statusPanen,
            persenKurang: persenKurang,
            luasHa: luasHa,
            usiaPohon: usiaPohon,
            cachedAt: cachedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int lahanId,
            required String bulan,
            required int tahun,
            required int bulanAngka,
            Value<int?> tanggal = const Value.absent(),
            required double tonAktual,
            Value<double> targetMin = const Value.absent(),
            Value<double> targetMax = const Value.absent(),
            Value<double> targetMid = const Value.absent(),
            Value<double> hargaPerTon = const Value.absent(),
            Value<String?> statusPanen = const Value.absent(),
            Value<double> persenKurang = const Value.absent(),
            Value<double> luasHa = const Value.absent(),
            Value<int> usiaPohon = const Value.absent(),
            required int cachedAt,
          }) =>
              PanensCompanion.insert(
            id: id,
            lahanId: lahanId,
            bulan: bulan,
            tahun: tahun,
            bulanAngka: bulanAngka,
            tanggal: tanggal,
            tonAktual: tonAktual,
            targetMin: targetMin,
            targetMax: targetMax,
            targetMid: targetMid,
            hargaPerTon: hargaPerTon,
            statusPanen: statusPanen,
            persenKurang: persenKurang,
            luasHa: luasHa,
            usiaPohon: usiaPohon,
            cachedAt: cachedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PanensTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PanensTable,
    Panen,
    $$PanensTableFilterComposer,
    $$PanensTableOrderingComposer,
    $$PanensTableAnnotationComposer,
    $$PanensTableCreateCompanionBuilder,
    $$PanensTableUpdateCompanionBuilder,
    (Panen, BaseReferences<_$AppDatabase, $PanensTable, Panen>),
    Panen,
    PrefetchHooks Function()>;
typedef $$BiayasTableCreateCompanionBuilder = BiayasCompanion Function({
  Value<int> id,
  required int lahanId,
  required String bulan,
  required int tahun,
  required int bulanAngka,
  required String kategori,
  required double jumlah,
  Value<String?> keterangan,
  required int cachedAt,
});
typedef $$BiayasTableUpdateCompanionBuilder = BiayasCompanion Function({
  Value<int> id,
  Value<int> lahanId,
  Value<String> bulan,
  Value<int> tahun,
  Value<int> bulanAngka,
  Value<String> kategori,
  Value<double> jumlah,
  Value<String?> keterangan,
  Value<int> cachedAt,
});

class $$BiayasTableFilterComposer
    extends Composer<_$AppDatabase, $BiayasTable> {
  $$BiayasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lahanId => $composableBuilder(
      column: $table.lahanId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bulan => $composableBuilder(
      column: $table.bulan, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get tahun => $composableBuilder(
      column: $table.tahun, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get bulanAngka => $composableBuilder(
      column: $table.bulanAngka, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kategori => $composableBuilder(
      column: $table.kategori, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get jumlah => $composableBuilder(
      column: $table.jumlah, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get keterangan => $composableBuilder(
      column: $table.keterangan, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnFilters(column));
}

class $$BiayasTableOrderingComposer
    extends Composer<_$AppDatabase, $BiayasTable> {
  $$BiayasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lahanId => $composableBuilder(
      column: $table.lahanId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bulan => $composableBuilder(
      column: $table.bulan, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get tahun => $composableBuilder(
      column: $table.tahun, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get bulanAngka => $composableBuilder(
      column: $table.bulanAngka, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kategori => $composableBuilder(
      column: $table.kategori, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get jumlah => $composableBuilder(
      column: $table.jumlah, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get keterangan => $composableBuilder(
      column: $table.keterangan, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnOrderings(column));
}

class $$BiayasTableAnnotationComposer
    extends Composer<_$AppDatabase, $BiayasTable> {
  $$BiayasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get lahanId =>
      $composableBuilder(column: $table.lahanId, builder: (column) => column);

  GeneratedColumn<String> get bulan =>
      $composableBuilder(column: $table.bulan, builder: (column) => column);

  GeneratedColumn<int> get tahun =>
      $composableBuilder(column: $table.tahun, builder: (column) => column);

  GeneratedColumn<int> get bulanAngka => $composableBuilder(
      column: $table.bulanAngka, builder: (column) => column);

  GeneratedColumn<String> get kategori =>
      $composableBuilder(column: $table.kategori, builder: (column) => column);

  GeneratedColumn<double> get jumlah =>
      $composableBuilder(column: $table.jumlah, builder: (column) => column);

  GeneratedColumn<String> get keterangan => $composableBuilder(
      column: $table.keterangan, builder: (column) => column);

  GeneratedColumn<int> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$BiayasTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BiayasTable,
    Biaya,
    $$BiayasTableFilterComposer,
    $$BiayasTableOrderingComposer,
    $$BiayasTableAnnotationComposer,
    $$BiayasTableCreateCompanionBuilder,
    $$BiayasTableUpdateCompanionBuilder,
    (Biaya, BaseReferences<_$AppDatabase, $BiayasTable, Biaya>),
    Biaya,
    PrefetchHooks Function()> {
  $$BiayasTableTableManager(_$AppDatabase db, $BiayasTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BiayasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BiayasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BiayasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> lahanId = const Value.absent(),
            Value<String> bulan = const Value.absent(),
            Value<int> tahun = const Value.absent(),
            Value<int> bulanAngka = const Value.absent(),
            Value<String> kategori = const Value.absent(),
            Value<double> jumlah = const Value.absent(),
            Value<String?> keterangan = const Value.absent(),
            Value<int> cachedAt = const Value.absent(),
          }) =>
              BiayasCompanion(
            id: id,
            lahanId: lahanId,
            bulan: bulan,
            tahun: tahun,
            bulanAngka: bulanAngka,
            kategori: kategori,
            jumlah: jumlah,
            keterangan: keterangan,
            cachedAt: cachedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int lahanId,
            required String bulan,
            required int tahun,
            required int bulanAngka,
            required String kategori,
            required double jumlah,
            Value<String?> keterangan = const Value.absent(),
            required int cachedAt,
          }) =>
              BiayasCompanion.insert(
            id: id,
            lahanId: lahanId,
            bulan: bulan,
            tahun: tahun,
            bulanAngka: bulanAngka,
            kategori: kategori,
            jumlah: jumlah,
            keterangan: keterangan,
            cachedAt: cachedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$BiayasTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BiayasTable,
    Biaya,
    $$BiayasTableFilterComposer,
    $$BiayasTableOrderingComposer,
    $$BiayasTableAnnotationComposer,
    $$BiayasTableCreateCompanionBuilder,
    $$BiayasTableUpdateCompanionBuilder,
    (Biaya, BaseReferences<_$AppDatabase, $BiayasTable, Biaya>),
    Biaya,
    PrefetchHooks Function()>;
typedef $$SyncQueueTableCreateCompanionBuilder = SyncQueueCompanion Function({
  Value<int> id,
  required String entity,
  required String operation,
  required String payload,
  required int lahanId,
  required int localId,
  required int createdAt,
  Value<int> retryCount,
});
typedef $$SyncQueueTableUpdateCompanionBuilder = SyncQueueCompanion Function({
  Value<int> id,
  Value<String> entity,
  Value<String> operation,
  Value<String> payload,
  Value<int> lahanId,
  Value<int> localId,
  Value<int> createdAt,
  Value<int> retryCount,
});

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entity => $composableBuilder(
      column: $table.entity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lahanId => $composableBuilder(
      column: $table.lahanId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnFilters(column));
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entity => $composableBuilder(
      column: $table.entity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lahanId => $composableBuilder(
      column: $table.lahanId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnOrderings(column));
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get lahanId =>
      $composableBuilder(column: $table.lahanId, builder: (column) => column);

  GeneratedColumn<int> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => column);
}

class $$SyncQueueTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncQueueTable,
    SyncQueueData,
    $$SyncQueueTableFilterComposer,
    $$SyncQueueTableOrderingComposer,
    $$SyncQueueTableAnnotationComposer,
    $$SyncQueueTableCreateCompanionBuilder,
    $$SyncQueueTableUpdateCompanionBuilder,
    (
      SyncQueueData,
      BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>
    ),
    SyncQueueData,
    PrefetchHooks Function()> {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> entity = const Value.absent(),
            Value<String> operation = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<int> lahanId = const Value.absent(),
            Value<int> localId = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
          }) =>
              SyncQueueCompanion(
            id: id,
            entity: entity,
            operation: operation,
            payload: payload,
            lahanId: lahanId,
            localId: localId,
            createdAt: createdAt,
            retryCount: retryCount,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String entity,
            required String operation,
            required String payload,
            required int lahanId,
            required int localId,
            required int createdAt,
            Value<int> retryCount = const Value.absent(),
          }) =>
              SyncQueueCompanion.insert(
            id: id,
            entity: entity,
            operation: operation,
            payload: payload,
            lahanId: lahanId,
            localId: localId,
            createdAt: createdAt,
            retryCount: retryCount,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncQueueTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncQueueTable,
    SyncQueueData,
    $$SyncQueueTableFilterComposer,
    $$SyncQueueTableOrderingComposer,
    $$SyncQueueTableAnnotationComposer,
    $$SyncQueueTableCreateCompanionBuilder,
    $$SyncQueueTableUpdateCompanionBuilder,
    (
      SyncQueueData,
      BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>
    ),
    SyncQueueData,
    PrefetchHooks Function()>;
typedef $$PekerjasTableCreateCompanionBuilder = PekerjasCompanion Function({
  Value<int> id,
  required int lahanId,
  required String nama,
  required String peran,
  Value<String?> kontak,
  Value<double> gajiHarian,
  Value<bool> isActive,
  required int createdAt,
});
typedef $$PekerjasTableUpdateCompanionBuilder = PekerjasCompanion Function({
  Value<int> id,
  Value<int> lahanId,
  Value<String> nama,
  Value<String> peran,
  Value<String?> kontak,
  Value<double> gajiHarian,
  Value<bool> isActive,
  Value<int> createdAt,
});

final class $$PekerjasTableReferences
    extends BaseReferences<_$AppDatabase, $PekerjasTable, Pekerja> {
  $$PekerjasTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$HariKerjasTable, List<HariKerja>>
      _hariKerjasRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.hariKerjas,
          aliasName:
              $_aliasNameGenerator(db.pekerjas.id, db.hariKerjas.pekerjaId));

  $$HariKerjasTableProcessedTableManager get hariKerjasRefs {
    final manager = $$HariKerjasTableTableManager($_db, $_db.hariKerjas)
        .filter((f) => f.pekerjaId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_hariKerjasRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$PekerjasTableFilterComposer
    extends Composer<_$AppDatabase, $PekerjasTable> {
  $$PekerjasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lahanId => $composableBuilder(
      column: $table.lahanId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nama => $composableBuilder(
      column: $table.nama, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get peran => $composableBuilder(
      column: $table.peran, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kontak => $composableBuilder(
      column: $table.kontak, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get gajiHarian => $composableBuilder(
      column: $table.gajiHarian, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> hariKerjasRefs(
      Expression<bool> Function($$HariKerjasTableFilterComposer f) f) {
    final $$HariKerjasTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.hariKerjas,
        getReferencedColumn: (t) => t.pekerjaId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HariKerjasTableFilterComposer(
              $db: $db,
              $table: $db.hariKerjas,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PekerjasTableOrderingComposer
    extends Composer<_$AppDatabase, $PekerjasTable> {
  $$PekerjasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lahanId => $composableBuilder(
      column: $table.lahanId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nama => $composableBuilder(
      column: $table.nama, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get peran => $composableBuilder(
      column: $table.peran, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kontak => $composableBuilder(
      column: $table.kontak, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get gajiHarian => $composableBuilder(
      column: $table.gajiHarian, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$PekerjasTableAnnotationComposer
    extends Composer<_$AppDatabase, $PekerjasTable> {
  $$PekerjasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get lahanId =>
      $composableBuilder(column: $table.lahanId, builder: (column) => column);

  GeneratedColumn<String> get nama =>
      $composableBuilder(column: $table.nama, builder: (column) => column);

  GeneratedColumn<String> get peran =>
      $composableBuilder(column: $table.peran, builder: (column) => column);

  GeneratedColumn<String> get kontak =>
      $composableBuilder(column: $table.kontak, builder: (column) => column);

  GeneratedColumn<double> get gajiHarian => $composableBuilder(
      column: $table.gajiHarian, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> hariKerjasRefs<T extends Object>(
      Expression<T> Function($$HariKerjasTableAnnotationComposer a) f) {
    final $$HariKerjasTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.hariKerjas,
        getReferencedColumn: (t) => t.pekerjaId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HariKerjasTableAnnotationComposer(
              $db: $db,
              $table: $db.hariKerjas,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PekerjasTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PekerjasTable,
    Pekerja,
    $$PekerjasTableFilterComposer,
    $$PekerjasTableOrderingComposer,
    $$PekerjasTableAnnotationComposer,
    $$PekerjasTableCreateCompanionBuilder,
    $$PekerjasTableUpdateCompanionBuilder,
    (Pekerja, $$PekerjasTableReferences),
    Pekerja,
    PrefetchHooks Function({bool hariKerjasRefs})> {
  $$PekerjasTableTableManager(_$AppDatabase db, $PekerjasTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PekerjasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PekerjasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PekerjasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> lahanId = const Value.absent(),
            Value<String> nama = const Value.absent(),
            Value<String> peran = const Value.absent(),
            Value<String?> kontak = const Value.absent(),
            Value<double> gajiHarian = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
          }) =>
              PekerjasCompanion(
            id: id,
            lahanId: lahanId,
            nama: nama,
            peran: peran,
            kontak: kontak,
            gajiHarian: gajiHarian,
            isActive: isActive,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int lahanId,
            required String nama,
            required String peran,
            Value<String?> kontak = const Value.absent(),
            Value<double> gajiHarian = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            required int createdAt,
          }) =>
              PekerjasCompanion.insert(
            id: id,
            lahanId: lahanId,
            nama: nama,
            peran: peran,
            kontak: kontak,
            gajiHarian: gajiHarian,
            isActive: isActive,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$PekerjasTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({hariKerjasRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (hariKerjasRefs) db.hariKerjas],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (hariKerjasRefs)
                    await $_getPrefetchedData<Pekerja, $PekerjasTable,
                            HariKerja>(
                        currentTable: table,
                        referencedTable:
                            $$PekerjasTableReferences._hariKerjasRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PekerjasTableReferences(db, table, p0)
                                .hariKerjasRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.pekerjaId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$PekerjasTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PekerjasTable,
    Pekerja,
    $$PekerjasTableFilterComposer,
    $$PekerjasTableOrderingComposer,
    $$PekerjasTableAnnotationComposer,
    $$PekerjasTableCreateCompanionBuilder,
    $$PekerjasTableUpdateCompanionBuilder,
    (Pekerja, $$PekerjasTableReferences),
    Pekerja,
    PrefetchHooks Function({bool hariKerjasRefs})>;
typedef $$HariKerjasTableCreateCompanionBuilder = HariKerjasCompanion Function({
  Value<int> id,
  required int pekerjaId,
  required int lahanId,
  required String bulan,
  required int tahun,
  required int bulanAngka,
  required int jumlahHari,
  required double totalGaji,
  Value<String?> catatan,
  required int createdAt,
});
typedef $$HariKerjasTableUpdateCompanionBuilder = HariKerjasCompanion Function({
  Value<int> id,
  Value<int> pekerjaId,
  Value<int> lahanId,
  Value<String> bulan,
  Value<int> tahun,
  Value<int> bulanAngka,
  Value<int> jumlahHari,
  Value<double> totalGaji,
  Value<String?> catatan,
  Value<int> createdAt,
});

final class $$HariKerjasTableReferences
    extends BaseReferences<_$AppDatabase, $HariKerjasTable, HariKerja> {
  $$HariKerjasTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PekerjasTable _pekerjaIdTable(_$AppDatabase db) =>
      db.pekerjas.createAlias(
          $_aliasNameGenerator(db.hariKerjas.pekerjaId, db.pekerjas.id));

  $$PekerjasTableProcessedTableManager get pekerjaId {
    final $_column = $_itemColumn<int>('pekerja_id')!;

    final manager = $$PekerjasTableTableManager($_db, $_db.pekerjas)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_pekerjaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$HariKerjasTableFilterComposer
    extends Composer<_$AppDatabase, $HariKerjasTable> {
  $$HariKerjasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lahanId => $composableBuilder(
      column: $table.lahanId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bulan => $composableBuilder(
      column: $table.bulan, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get tahun => $composableBuilder(
      column: $table.tahun, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get bulanAngka => $composableBuilder(
      column: $table.bulanAngka, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get jumlahHari => $composableBuilder(
      column: $table.jumlahHari, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalGaji => $composableBuilder(
      column: $table.totalGaji, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get catatan => $composableBuilder(
      column: $table.catatan, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$PekerjasTableFilterComposer get pekerjaId {
    final $$PekerjasTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.pekerjaId,
        referencedTable: $db.pekerjas,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PekerjasTableFilterComposer(
              $db: $db,
              $table: $db.pekerjas,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$HariKerjasTableOrderingComposer
    extends Composer<_$AppDatabase, $HariKerjasTable> {
  $$HariKerjasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lahanId => $composableBuilder(
      column: $table.lahanId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bulan => $composableBuilder(
      column: $table.bulan, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get tahun => $composableBuilder(
      column: $table.tahun, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get bulanAngka => $composableBuilder(
      column: $table.bulanAngka, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get jumlahHari => $composableBuilder(
      column: $table.jumlahHari, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalGaji => $composableBuilder(
      column: $table.totalGaji, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get catatan => $composableBuilder(
      column: $table.catatan, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$PekerjasTableOrderingComposer get pekerjaId {
    final $$PekerjasTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.pekerjaId,
        referencedTable: $db.pekerjas,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PekerjasTableOrderingComposer(
              $db: $db,
              $table: $db.pekerjas,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$HariKerjasTableAnnotationComposer
    extends Composer<_$AppDatabase, $HariKerjasTable> {
  $$HariKerjasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get lahanId =>
      $composableBuilder(column: $table.lahanId, builder: (column) => column);

  GeneratedColumn<String> get bulan =>
      $composableBuilder(column: $table.bulan, builder: (column) => column);

  GeneratedColumn<int> get tahun =>
      $composableBuilder(column: $table.tahun, builder: (column) => column);

  GeneratedColumn<int> get bulanAngka => $composableBuilder(
      column: $table.bulanAngka, builder: (column) => column);

  GeneratedColumn<int> get jumlahHari => $composableBuilder(
      column: $table.jumlahHari, builder: (column) => column);

  GeneratedColumn<double> get totalGaji =>
      $composableBuilder(column: $table.totalGaji, builder: (column) => column);

  GeneratedColumn<String> get catatan =>
      $composableBuilder(column: $table.catatan, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$PekerjasTableAnnotationComposer get pekerjaId {
    final $$PekerjasTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.pekerjaId,
        referencedTable: $db.pekerjas,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PekerjasTableAnnotationComposer(
              $db: $db,
              $table: $db.pekerjas,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$HariKerjasTableTableManager extends RootTableManager<
    _$AppDatabase,
    $HariKerjasTable,
    HariKerja,
    $$HariKerjasTableFilterComposer,
    $$HariKerjasTableOrderingComposer,
    $$HariKerjasTableAnnotationComposer,
    $$HariKerjasTableCreateCompanionBuilder,
    $$HariKerjasTableUpdateCompanionBuilder,
    (HariKerja, $$HariKerjasTableReferences),
    HariKerja,
    PrefetchHooks Function({bool pekerjaId})> {
  $$HariKerjasTableTableManager(_$AppDatabase db, $HariKerjasTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HariKerjasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HariKerjasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HariKerjasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> pekerjaId = const Value.absent(),
            Value<int> lahanId = const Value.absent(),
            Value<String> bulan = const Value.absent(),
            Value<int> tahun = const Value.absent(),
            Value<int> bulanAngka = const Value.absent(),
            Value<int> jumlahHari = const Value.absent(),
            Value<double> totalGaji = const Value.absent(),
            Value<String?> catatan = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
          }) =>
              HariKerjasCompanion(
            id: id,
            pekerjaId: pekerjaId,
            lahanId: lahanId,
            bulan: bulan,
            tahun: tahun,
            bulanAngka: bulanAngka,
            jumlahHari: jumlahHari,
            totalGaji: totalGaji,
            catatan: catatan,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int pekerjaId,
            required int lahanId,
            required String bulan,
            required int tahun,
            required int bulanAngka,
            required int jumlahHari,
            required double totalGaji,
            Value<String?> catatan = const Value.absent(),
            required int createdAt,
          }) =>
              HariKerjasCompanion.insert(
            id: id,
            pekerjaId: pekerjaId,
            lahanId: lahanId,
            bulan: bulan,
            tahun: tahun,
            bulanAngka: bulanAngka,
            jumlahHari: jumlahHari,
            totalGaji: totalGaji,
            catatan: catatan,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$HariKerjasTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({pekerjaId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (pekerjaId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.pekerjaId,
                    referencedTable:
                        $$HariKerjasTableReferences._pekerjaIdTable(db),
                    referencedColumn:
                        $$HariKerjasTableReferences._pekerjaIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$HariKerjasTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $HariKerjasTable,
    HariKerja,
    $$HariKerjasTableFilterComposer,
    $$HariKerjasTableOrderingComposer,
    $$HariKerjasTableAnnotationComposer,
    $$HariKerjasTableCreateCompanionBuilder,
    $$HariKerjasTableUpdateCompanionBuilder,
    (HariKerja, $$HariKerjasTableReferences),
    HariKerja,
    PrefetchHooks Function({bool pekerjaId})>;
typedef $$InventoryPupuksTableCreateCompanionBuilder = InventoryPupuksCompanion
    Function({
  Value<int> id,
  required int lahanId,
  required String namaPupuk,
  Value<double> stokKg,
  Value<double> thresholdAlert,
  Value<int?> expiredAt,
  Value<String?> catatan,
  required int updatedAt,
});
typedef $$InventoryPupuksTableUpdateCompanionBuilder = InventoryPupuksCompanion
    Function({
  Value<int> id,
  Value<int> lahanId,
  Value<String> namaPupuk,
  Value<double> stokKg,
  Value<double> thresholdAlert,
  Value<int?> expiredAt,
  Value<String?> catatan,
  Value<int> updatedAt,
});

class $$InventoryPupuksTableFilterComposer
    extends Composer<_$AppDatabase, $InventoryPupuksTable> {
  $$InventoryPupuksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lahanId => $composableBuilder(
      column: $table.lahanId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get namaPupuk => $composableBuilder(
      column: $table.namaPupuk, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get stokKg => $composableBuilder(
      column: $table.stokKg, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get thresholdAlert => $composableBuilder(
      column: $table.thresholdAlert,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get expiredAt => $composableBuilder(
      column: $table.expiredAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get catatan => $composableBuilder(
      column: $table.catatan, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$InventoryPupuksTableOrderingComposer
    extends Composer<_$AppDatabase, $InventoryPupuksTable> {
  $$InventoryPupuksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lahanId => $composableBuilder(
      column: $table.lahanId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get namaPupuk => $composableBuilder(
      column: $table.namaPupuk, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get stokKg => $composableBuilder(
      column: $table.stokKg, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get thresholdAlert => $composableBuilder(
      column: $table.thresholdAlert,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get expiredAt => $composableBuilder(
      column: $table.expiredAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get catatan => $composableBuilder(
      column: $table.catatan, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$InventoryPupuksTableAnnotationComposer
    extends Composer<_$AppDatabase, $InventoryPupuksTable> {
  $$InventoryPupuksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get lahanId =>
      $composableBuilder(column: $table.lahanId, builder: (column) => column);

  GeneratedColumn<String> get namaPupuk =>
      $composableBuilder(column: $table.namaPupuk, builder: (column) => column);

  GeneratedColumn<double> get stokKg =>
      $composableBuilder(column: $table.stokKg, builder: (column) => column);

  GeneratedColumn<double> get thresholdAlert => $composableBuilder(
      column: $table.thresholdAlert, builder: (column) => column);

  GeneratedColumn<int> get expiredAt =>
      $composableBuilder(column: $table.expiredAt, builder: (column) => column);

  GeneratedColumn<String> get catatan =>
      $composableBuilder(column: $table.catatan, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$InventoryPupuksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $InventoryPupuksTable,
    InventoryPupuk,
    $$InventoryPupuksTableFilterComposer,
    $$InventoryPupuksTableOrderingComposer,
    $$InventoryPupuksTableAnnotationComposer,
    $$InventoryPupuksTableCreateCompanionBuilder,
    $$InventoryPupuksTableUpdateCompanionBuilder,
    (
      InventoryPupuk,
      BaseReferences<_$AppDatabase, $InventoryPupuksTable, InventoryPupuk>
    ),
    InventoryPupuk,
    PrefetchHooks Function()> {
  $$InventoryPupuksTableTableManager(
      _$AppDatabase db, $InventoryPupuksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InventoryPupuksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InventoryPupuksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InventoryPupuksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> lahanId = const Value.absent(),
            Value<String> namaPupuk = const Value.absent(),
            Value<double> stokKg = const Value.absent(),
            Value<double> thresholdAlert = const Value.absent(),
            Value<int?> expiredAt = const Value.absent(),
            Value<String?> catatan = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
          }) =>
              InventoryPupuksCompanion(
            id: id,
            lahanId: lahanId,
            namaPupuk: namaPupuk,
            stokKg: stokKg,
            thresholdAlert: thresholdAlert,
            expiredAt: expiredAt,
            catatan: catatan,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int lahanId,
            required String namaPupuk,
            Value<double> stokKg = const Value.absent(),
            Value<double> thresholdAlert = const Value.absent(),
            Value<int?> expiredAt = const Value.absent(),
            Value<String?> catatan = const Value.absent(),
            required int updatedAt,
          }) =>
              InventoryPupuksCompanion.insert(
            id: id,
            lahanId: lahanId,
            namaPupuk: namaPupuk,
            stokKg: stokKg,
            thresholdAlert: thresholdAlert,
            expiredAt: expiredAt,
            catatan: catatan,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$InventoryPupuksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $InventoryPupuksTable,
    InventoryPupuk,
    $$InventoryPupuksTableFilterComposer,
    $$InventoryPupuksTableOrderingComposer,
    $$InventoryPupuksTableAnnotationComposer,
    $$InventoryPupuksTableCreateCompanionBuilder,
    $$InventoryPupuksTableUpdateCompanionBuilder,
    (
      InventoryPupuk,
      BaseReferences<_$AppDatabase, $InventoryPupuksTable, InventoryPupuk>
    ),
    InventoryPupuk,
    PrefetchHooks Function()>;
typedef $$JadwalPupuksTableCreateCompanionBuilder = JadwalPupuksCompanion
    Function({
  Value<int> id,
  required int lahanId,
  Value<int> siklusHari,
  Value<int?> lastPemupukanAt,
  Value<int?> nextReminderAt,
  Value<int?> notificationId,
  Value<bool> isActive,
  Value<String?> jenisPupuk,
  required int updatedAt,
});
typedef $$JadwalPupuksTableUpdateCompanionBuilder = JadwalPupuksCompanion
    Function({
  Value<int> id,
  Value<int> lahanId,
  Value<int> siklusHari,
  Value<int?> lastPemupukanAt,
  Value<int?> nextReminderAt,
  Value<int?> notificationId,
  Value<bool> isActive,
  Value<String?> jenisPupuk,
  Value<int> updatedAt,
});

class $$JadwalPupuksTableFilterComposer
    extends Composer<_$AppDatabase, $JadwalPupuksTable> {
  $$JadwalPupuksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lahanId => $composableBuilder(
      column: $table.lahanId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get siklusHari => $composableBuilder(
      column: $table.siklusHari, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastPemupukanAt => $composableBuilder(
      column: $table.lastPemupukanAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get nextReminderAt => $composableBuilder(
      column: $table.nextReminderAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get notificationId => $composableBuilder(
      column: $table.notificationId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get jenisPupuk => $composableBuilder(
      column: $table.jenisPupuk, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$JadwalPupuksTableOrderingComposer
    extends Composer<_$AppDatabase, $JadwalPupuksTable> {
  $$JadwalPupuksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lahanId => $composableBuilder(
      column: $table.lahanId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get siklusHari => $composableBuilder(
      column: $table.siklusHari, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastPemupukanAt => $composableBuilder(
      column: $table.lastPemupukanAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get nextReminderAt => $composableBuilder(
      column: $table.nextReminderAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get notificationId => $composableBuilder(
      column: $table.notificationId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get jenisPupuk => $composableBuilder(
      column: $table.jenisPupuk, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$JadwalPupuksTableAnnotationComposer
    extends Composer<_$AppDatabase, $JadwalPupuksTable> {
  $$JadwalPupuksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get lahanId =>
      $composableBuilder(column: $table.lahanId, builder: (column) => column);

  GeneratedColumn<int> get siklusHari => $composableBuilder(
      column: $table.siklusHari, builder: (column) => column);

  GeneratedColumn<int> get lastPemupukanAt => $composableBuilder(
      column: $table.lastPemupukanAt, builder: (column) => column);

  GeneratedColumn<int> get nextReminderAt => $composableBuilder(
      column: $table.nextReminderAt, builder: (column) => column);

  GeneratedColumn<int> get notificationId => $composableBuilder(
      column: $table.notificationId, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get jenisPupuk => $composableBuilder(
      column: $table.jenisPupuk, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$JadwalPupuksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $JadwalPupuksTable,
    JadwalPupuk,
    $$JadwalPupuksTableFilterComposer,
    $$JadwalPupuksTableOrderingComposer,
    $$JadwalPupuksTableAnnotationComposer,
    $$JadwalPupuksTableCreateCompanionBuilder,
    $$JadwalPupuksTableUpdateCompanionBuilder,
    (
      JadwalPupuk,
      BaseReferences<_$AppDatabase, $JadwalPupuksTable, JadwalPupuk>
    ),
    JadwalPupuk,
    PrefetchHooks Function()> {
  $$JadwalPupuksTableTableManager(_$AppDatabase db, $JadwalPupuksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JadwalPupuksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JadwalPupuksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JadwalPupuksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> lahanId = const Value.absent(),
            Value<int> siklusHari = const Value.absent(),
            Value<int?> lastPemupukanAt = const Value.absent(),
            Value<int?> nextReminderAt = const Value.absent(),
            Value<int?> notificationId = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<String?> jenisPupuk = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
          }) =>
              JadwalPupuksCompanion(
            id: id,
            lahanId: lahanId,
            siklusHari: siklusHari,
            lastPemupukanAt: lastPemupukanAt,
            nextReminderAt: nextReminderAt,
            notificationId: notificationId,
            isActive: isActive,
            jenisPupuk: jenisPupuk,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int lahanId,
            Value<int> siklusHari = const Value.absent(),
            Value<int?> lastPemupukanAt = const Value.absent(),
            Value<int?> nextReminderAt = const Value.absent(),
            Value<int?> notificationId = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<String?> jenisPupuk = const Value.absent(),
            required int updatedAt,
          }) =>
              JadwalPupuksCompanion.insert(
            id: id,
            lahanId: lahanId,
            siklusHari: siklusHari,
            lastPemupukanAt: lastPemupukanAt,
            nextReminderAt: nextReminderAt,
            notificationId: notificationId,
            isActive: isActive,
            jenisPupuk: jenisPupuk,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$JadwalPupuksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $JadwalPupuksTable,
    JadwalPupuk,
    $$JadwalPupuksTableFilterComposer,
    $$JadwalPupuksTableOrderingComposer,
    $$JadwalPupuksTableAnnotationComposer,
    $$JadwalPupuksTableCreateCompanionBuilder,
    $$JadwalPupuksTableUpdateCompanionBuilder,
    (
      JadwalPupuk,
      BaseReferences<_$AppDatabase, $JadwalPupuksTable, JadwalPupuk>
    ),
    JadwalPupuk,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LahansTableTableManager get lahans =>
      $$LahansTableTableManager(_db, _db.lahans);
  $$PanensTableTableManager get panens =>
      $$PanensTableTableManager(_db, _db.panens);
  $$BiayasTableTableManager get biayas =>
      $$BiayasTableTableManager(_db, _db.biayas);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
  $$PekerjasTableTableManager get pekerjas =>
      $$PekerjasTableTableManager(_db, _db.pekerjas);
  $$HariKerjasTableTableManager get hariKerjas =>
      $$HariKerjasTableTableManager(_db, _db.hariKerjas);
  $$InventoryPupuksTableTableManager get inventoryPupuks =>
      $$InventoryPupuksTableTableManager(_db, _db.inventoryPupuks);
  $$JadwalPupuksTableTableManager get jadwalPupuks =>
      $$JadwalPupuksTableTableManager(_db, _db.jadwalPupuks);
}
