// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_storage.dart';

// **************************************************************************
// _IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

extension GetModelBoxCollection on Isar {
  IsarCollection<int, ModelBox> get modelBoxs => this.collection();
}

final ModelBoxSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'ModelBox',
    idName: 'id',
    embedded: false,
    properties: [
      IsarPropertySchema(
        name: 'modelId',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'historyIdx',
        type: IsarType.long,
      ),
      IsarPropertySchema(
        name: 'modelData',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'model',
        type: IsarType.object,
        target: 'ModelContainer',
      ),
      IsarPropertySchema(
        name: 'rootParentId',
        type: IsarType.string,
      ),
    ],
    indexes: [
      IsarIndexSchema(
        name: 'modelId_historyIdx',
        properties: [
          "modelId",
          "historyIdx",
        ],
        unique: true,
        hash: true,
      ),
    ],
  ),
  converter: IsarObjectConverter<int, ModelBox>(
    serialize: serializeModelBox,
    deserialize: deserializeModelBox,
    deserializeProperty: deserializeModelBoxProp,
  ),
  getEmbeddedSchemas: () => [ModelContainerSchema],
);

@isarProtected
int serializeModelBox(IsarWriter writer, ModelBox object) {
  {
    final value = object.modelId;
    if (value == null) {
      IsarCore.writeNull(writer, 1);
    } else {
      IsarCore.writeString(writer, 1, value);
    }
  }
  IsarCore.writeLong(writer, 2, object.historyIdx ?? -9223372036854775808);
  {
    final value = object.modelData;
    if (value == null) {
      IsarCore.writeNull(writer, 3);
    } else {
      IsarCore.writeString(writer, 3, value);
    }
  }
  {
    final value = object.model;
    if (value == null) {
      IsarCore.writeNull(writer, 4);
    } else {
      final objectWriter = IsarCore.beginObject(writer, 4);
      serializeModelContainer(objectWriter, value);
      IsarCore.endObject(writer, objectWriter);
    }
  }
  {
    final value = object.rootParentId;
    if (value == null) {
      IsarCore.writeNull(writer, 5);
    } else {
      IsarCore.writeString(writer, 5, value);
    }
  }
  return object.id;
}

@isarProtected
ModelBox deserializeModelBox(IsarReader reader) {
  final object = ModelBox();
  object.id = IsarCore.readId(reader);
  object.modelId = IsarCore.readString(reader, 1);
  {
    final value = IsarCore.readLong(reader, 2);
    if (value == -9223372036854775808) {
      object.historyIdx = null;
    } else {
      object.historyIdx = value;
    }
  }
  object.modelData = IsarCore.readString(reader, 3);
  {
    final objectReader = IsarCore.readObject(reader, 4);
    if (objectReader.isNull) {
      object.model = null;
    } else {
      final embedded = deserializeModelContainer(objectReader);
      IsarCore.freeReader(objectReader);
      object.model = embedded;
    }
  }
  object.rootParentId = IsarCore.readString(reader, 5);
  return object;
}

@isarProtected
dynamic deserializeModelBoxProp(IsarReader reader, int property) {
  switch (property) {
    case 0:
      return IsarCore.readId(reader);
    case 1:
      return IsarCore.readString(reader, 1);
    case 2:
      {
        final value = IsarCore.readLong(reader, 2);
        if (value == -9223372036854775808) {
          return null;
        } else {
          return value;
        }
      }
    case 3:
      return IsarCore.readString(reader, 3);
    case 4:
      {
        final objectReader = IsarCore.readObject(reader, 4);
        if (objectReader.isNull) {
          return null;
        } else {
          final embedded = deserializeModelContainer(objectReader);
          IsarCore.freeReader(objectReader);
          return embedded;
        }
      }
    case 5:
      return IsarCore.readString(reader, 5);
    default:
      throw ArgumentError('Unknown property: $property');
  }
}

sealed class _ModelBoxUpdate {
  bool call({
    required int id,
    String? modelId,
    int? historyIdx,
    String? modelData,
    String? rootParentId,
  });
}

class _ModelBoxUpdateImpl implements _ModelBoxUpdate {
  const _ModelBoxUpdateImpl(this.collection);

  final IsarCollection<int, ModelBox> collection;

  @override
  bool call({
    required int id,
    Object? modelId = ignore,
    Object? historyIdx = ignore,
    Object? modelData = ignore,
    Object? rootParentId = ignore,
  }) {
    return collection.updateProperties([
          id
        ], {
          if (modelId != ignore) 1: modelId as String?,
          if (historyIdx != ignore) 2: historyIdx as int?,
          if (modelData != ignore) 3: modelData as String?,
          if (rootParentId != ignore) 5: rootParentId as String?,
        }) >
        0;
  }
}

sealed class _ModelBoxUpdateAll {
  int call({
    required List<int> id,
    String? modelId,
    int? historyIdx,
    String? modelData,
    String? rootParentId,
  });
}

class _ModelBoxUpdateAllImpl implements _ModelBoxUpdateAll {
  const _ModelBoxUpdateAllImpl(this.collection);

  final IsarCollection<int, ModelBox> collection;

  @override
  int call({
    required List<int> id,
    Object? modelId = ignore,
    Object? historyIdx = ignore,
    Object? modelData = ignore,
    Object? rootParentId = ignore,
  }) {
    return collection.updateProperties(id, {
      if (modelId != ignore) 1: modelId as String?,
      if (historyIdx != ignore) 2: historyIdx as int?,
      if (modelData != ignore) 3: modelData as String?,
      if (rootParentId != ignore) 5: rootParentId as String?,
    });
  }
}

extension ModelBoxUpdate on IsarCollection<int, ModelBox> {
  _ModelBoxUpdate get update => _ModelBoxUpdateImpl(this);

  _ModelBoxUpdateAll get updateAll => _ModelBoxUpdateAllImpl(this);
}

sealed class _ModelBoxQueryUpdate {
  int call({
    String? modelId,
    int? historyIdx,
    String? modelData,
    String? rootParentId,
  });
}

class _ModelBoxQueryUpdateImpl implements _ModelBoxQueryUpdate {
  const _ModelBoxQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<ModelBox> query;
  final int? limit;

  @override
  int call({
    Object? modelId = ignore,
    Object? historyIdx = ignore,
    Object? modelData = ignore,
    Object? rootParentId = ignore,
  }) {
    return query.updateProperties(limit: limit, {
      if (modelId != ignore) 1: modelId as String?,
      if (historyIdx != ignore) 2: historyIdx as int?,
      if (modelData != ignore) 3: modelData as String?,
      if (rootParentId != ignore) 5: rootParentId as String?,
    });
  }
}

extension ModelBoxQueryUpdate on IsarQuery<ModelBox> {
  _ModelBoxQueryUpdate get updateFirst =>
      _ModelBoxQueryUpdateImpl(this, limit: 1);

  _ModelBoxQueryUpdate get updateAll => _ModelBoxQueryUpdateImpl(this);
}

class _ModelBoxQueryBuilderUpdateImpl implements _ModelBoxQueryUpdate {
  const _ModelBoxQueryBuilderUpdateImpl(this.query, {this.limit});

  final QueryBuilder<ModelBox, ModelBox, QOperations> query;
  final int? limit;

  @override
  int call({
    Object? modelId = ignore,
    Object? historyIdx = ignore,
    Object? modelData = ignore,
    Object? rootParentId = ignore,
  }) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (modelId != ignore) 1: modelId as String?,
        if (historyIdx != ignore) 2: historyIdx as int?,
        if (modelData != ignore) 3: modelData as String?,
        if (rootParentId != ignore) 5: rootParentId as String?,
      });
    } finally {
      q.close();
    }
  }
}

extension ModelBoxQueryBuilderUpdate
    on QueryBuilder<ModelBox, ModelBox, QOperations> {
  _ModelBoxQueryUpdate get updateFirst =>
      _ModelBoxQueryBuilderUpdateImpl(this, limit: 1);

  _ModelBoxQueryUpdate get updateAll => _ModelBoxQueryBuilderUpdateImpl(this);
}

extension ModelBoxQueryFilter
    on QueryBuilder<ModelBox, ModelBox, QFilterCondition> {
  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> idEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> idGreaterThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition>
      idGreaterThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> idLessThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> idLessThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> idBetween(
    int lower,
    int upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 0,
          lower: lower,
          upper: upper,
        ),
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> modelIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 1));
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> modelIdIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 1));
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> modelIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> modelIdGreaterThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition>
      modelIdGreaterThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> modelIdLessThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition>
      modelIdLessThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> modelIdBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 1,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> modelIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> modelIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> modelIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> modelIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 1,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> modelIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 1,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> modelIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 1,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> historyIdxIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 2));
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition>
      historyIdxIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 2));
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> historyIdxEqualTo(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 2,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> historyIdxGreaterThan(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 2,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition>
      historyIdxGreaterThanOrEqualTo(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 2,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> historyIdxLessThan(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 2,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition>
      historyIdxLessThanOrEqualTo(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 2,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> historyIdxBetween(
    int? lower,
    int? upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 2,
          lower: lower,
          upper: upper,
        ),
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> modelDataIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 3));
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> modelDataIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 3));
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> modelDataEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> modelDataGreaterThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition>
      modelDataGreaterThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> modelDataLessThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition>
      modelDataLessThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> modelDataBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 3,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> modelDataStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> modelDataEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> modelDataContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> modelDataMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 3,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> modelDataIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 3,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition>
      modelDataIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 3,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> modelIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 4));
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> modelIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 4));
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> rootParentIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 5));
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition>
      rootParentIdIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 5));
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> rootParentIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition>
      rootParentIdGreaterThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition>
      rootParentIdGreaterThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> rootParentIdLessThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition>
      rootParentIdLessThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> rootParentIdBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 5,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition>
      rootParentIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> rootParentIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> rootParentIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> rootParentIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 5,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition>
      rootParentIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 5,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition>
      rootParentIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 5,
          value: '',
        ),
      );
    });
  }
}

extension ModelBoxQueryObject
    on QueryBuilder<ModelBox, ModelBox, QFilterCondition> {
  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> model(
      FilterQuery<ModelContainer> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, 4);
    });
  }
}

extension ModelBoxQuerySortBy on QueryBuilder<ModelBox, ModelBox, QSortBy> {
  QueryBuilder<ModelBox, ModelBox, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterSortBy> sortByModelId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        1,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterSortBy> sortByModelIdDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        1,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterSortBy> sortByHistoryIdx() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2);
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterSortBy> sortByHistoryIdxDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc);
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterSortBy> sortByModelData(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        3,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterSortBy> sortByModelDataDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        3,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterSortBy> sortByRootParentId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        5,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterSortBy> sortByRootParentIdDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        5,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }
}

extension ModelBoxQuerySortThenBy
    on QueryBuilder<ModelBox, ModelBox, QSortThenBy> {
  QueryBuilder<ModelBox, ModelBox, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterSortBy> thenByModelId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterSortBy> thenByModelIdDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterSortBy> thenByHistoryIdx() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2);
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterSortBy> thenByHistoryIdxDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc);
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterSortBy> thenByModelData(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterSortBy> thenByModelDataDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterSortBy> thenByRootParentId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterSortBy> thenByRootParentIdDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }
}

extension ModelBoxQueryWhereDistinct
    on QueryBuilder<ModelBox, ModelBox, QDistinct> {
  QueryBuilder<ModelBox, ModelBox, QAfterDistinct> distinctByModelId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterDistinct> distinctByHistoryIdx() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(2);
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterDistinct> distinctByModelData(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterDistinct> distinctByRootParentId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(5, caseSensitive: caseSensitive);
    });
  }
}

extension ModelBoxQueryProperty1
    on QueryBuilder<ModelBox, ModelBox, QProperty> {
  QueryBuilder<ModelBox, int, QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<ModelBox, String?, QAfterProperty> modelIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<ModelBox, int?, QAfterProperty> historyIdxProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<ModelBox, String?, QAfterProperty> modelDataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<ModelBox, ModelContainer?, QAfterProperty> modelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<ModelBox, String?, QAfterProperty> rootParentIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }
}

extension ModelBoxQueryProperty2<R>
    on QueryBuilder<ModelBox, R, QAfterProperty> {
  QueryBuilder<ModelBox, (R, int), QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<ModelBox, (R, String?), QAfterProperty> modelIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<ModelBox, (R, int?), QAfterProperty> historyIdxProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<ModelBox, (R, String?), QAfterProperty> modelDataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<ModelBox, (R, ModelContainer?), QAfterProperty> modelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<ModelBox, (R, String?), QAfterProperty> rootParentIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }
}

extension ModelBoxQueryProperty3<R1, R2>
    on QueryBuilder<ModelBox, (R1, R2), QAfterProperty> {
  QueryBuilder<ModelBox, (R1, R2, int), QOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<ModelBox, (R1, R2, String?), QOperations> modelIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<ModelBox, (R1, R2, int?), QOperations> historyIdxProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<ModelBox, (R1, R2, String?), QOperations> modelDataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<ModelBox, (R1, R2, ModelContainer?), QOperations>
      modelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<ModelBox, (R1, R2, String?), QOperations>
      rootParentIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

extension GetOperationalBoxCollection on Isar {
  IsarCollection<int, OperationalBox> get operationalBoxs => this.collection();
}

final OperationalBoxSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'OperationalBox',
    idName: 'id',
    embedded: false,
    properties: [
      IsarPropertySchema(
        name: 'name',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'data',
        type: IsarType.string,
      ),
    ],
    indexes: [
      IsarIndexSchema(
        name: 'byName',
        properties: [
          "name",
        ],
        unique: true,
        hash: false,
      ),
    ],
  ),
  converter: IsarObjectConverter<int, OperationalBox>(
    serialize: serializeOperationalBox,
    deserialize: deserializeOperationalBox,
    deserializeProperty: deserializeOperationalBoxProp,
  ),
  getEmbeddedSchemas: () => [],
);

@isarProtected
int serializeOperationalBox(IsarWriter writer, OperationalBox object) {
  {
    final value = object.name;
    if (value == null) {
      IsarCore.writeNull(writer, 1);
    } else {
      IsarCore.writeString(writer, 1, value);
    }
  }
  {
    final value = object.data;
    if (value == null) {
      IsarCore.writeNull(writer, 2);
    } else {
      IsarCore.writeString(writer, 2, value);
    }
  }
  return object.id;
}

@isarProtected
OperationalBox deserializeOperationalBox(IsarReader reader) {
  final object = OperationalBox();
  object.id = IsarCore.readId(reader);
  object.name = IsarCore.readString(reader, 1);
  object.data = IsarCore.readString(reader, 2);
  return object;
}

@isarProtected
dynamic deserializeOperationalBoxProp(IsarReader reader, int property) {
  switch (property) {
    case 0:
      return IsarCore.readId(reader);
    case 1:
      return IsarCore.readString(reader, 1);
    case 2:
      return IsarCore.readString(reader, 2);
    default:
      throw ArgumentError('Unknown property: $property');
  }
}

sealed class _OperationalBoxUpdate {
  bool call({
    required int id,
    String? name,
    String? data,
  });
}

class _OperationalBoxUpdateImpl implements _OperationalBoxUpdate {
  const _OperationalBoxUpdateImpl(this.collection);

  final IsarCollection<int, OperationalBox> collection;

  @override
  bool call({
    required int id,
    Object? name = ignore,
    Object? data = ignore,
  }) {
    return collection.updateProperties([
          id
        ], {
          if (name != ignore) 1: name as String?,
          if (data != ignore) 2: data as String?,
        }) >
        0;
  }
}

sealed class _OperationalBoxUpdateAll {
  int call({
    required List<int> id,
    String? name,
    String? data,
  });
}

class _OperationalBoxUpdateAllImpl implements _OperationalBoxUpdateAll {
  const _OperationalBoxUpdateAllImpl(this.collection);

  final IsarCollection<int, OperationalBox> collection;

  @override
  int call({
    required List<int> id,
    Object? name = ignore,
    Object? data = ignore,
  }) {
    return collection.updateProperties(id, {
      if (name != ignore) 1: name as String?,
      if (data != ignore) 2: data as String?,
    });
  }
}

extension OperationalBoxUpdate on IsarCollection<int, OperationalBox> {
  _OperationalBoxUpdate get update => _OperationalBoxUpdateImpl(this);

  _OperationalBoxUpdateAll get updateAll => _OperationalBoxUpdateAllImpl(this);
}

sealed class _OperationalBoxQueryUpdate {
  int call({
    String? name,
    String? data,
  });
}

class _OperationalBoxQueryUpdateImpl implements _OperationalBoxQueryUpdate {
  const _OperationalBoxQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<OperationalBox> query;
  final int? limit;

  @override
  int call({
    Object? name = ignore,
    Object? data = ignore,
  }) {
    return query.updateProperties(limit: limit, {
      if (name != ignore) 1: name as String?,
      if (data != ignore) 2: data as String?,
    });
  }
}

extension OperationalBoxQueryUpdate on IsarQuery<OperationalBox> {
  _OperationalBoxQueryUpdate get updateFirst =>
      _OperationalBoxQueryUpdateImpl(this, limit: 1);

  _OperationalBoxQueryUpdate get updateAll =>
      _OperationalBoxQueryUpdateImpl(this);
}

class _OperationalBoxQueryBuilderUpdateImpl
    implements _OperationalBoxQueryUpdate {
  const _OperationalBoxQueryBuilderUpdateImpl(this.query, {this.limit});

  final QueryBuilder<OperationalBox, OperationalBox, QOperations> query;
  final int? limit;

  @override
  int call({
    Object? name = ignore,
    Object? data = ignore,
  }) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (name != ignore) 1: name as String?,
        if (data != ignore) 2: data as String?,
      });
    } finally {
      q.close();
    }
  }
}

extension OperationalBoxQueryBuilderUpdate
    on QueryBuilder<OperationalBox, OperationalBox, QOperations> {
  _OperationalBoxQueryUpdate get updateFirst =>
      _OperationalBoxQueryBuilderUpdateImpl(this, limit: 1);

  _OperationalBoxQueryUpdate get updateAll =>
      _OperationalBoxQueryBuilderUpdateImpl(this);
}

extension OperationalBoxQueryFilter
    on QueryBuilder<OperationalBox, OperationalBox, QFilterCondition> {
  QueryBuilder<OperationalBox, OperationalBox, QAfterFilterCondition> idEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OperationalBox, OperationalBox, QAfterFilterCondition>
      idGreaterThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OperationalBox, OperationalBox, QAfterFilterCondition>
      idGreaterThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OperationalBox, OperationalBox, QAfterFilterCondition>
      idLessThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OperationalBox, OperationalBox, QAfterFilterCondition>
      idLessThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OperationalBox, OperationalBox, QAfterFilterCondition> idBetween(
    int lower,
    int upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 0,
          lower: lower,
          upper: upper,
        ),
      );
    });
  }

  QueryBuilder<OperationalBox, OperationalBox, QAfterFilterCondition>
      nameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 1));
    });
  }

  QueryBuilder<OperationalBox, OperationalBox, QAfterFilterCondition>
      nameIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 1));
    });
  }

  QueryBuilder<OperationalBox, OperationalBox, QAfterFilterCondition>
      nameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OperationalBox, OperationalBox, QAfterFilterCondition>
      nameGreaterThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OperationalBox, OperationalBox, QAfterFilterCondition>
      nameGreaterThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OperationalBox, OperationalBox, QAfterFilterCondition>
      nameLessThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OperationalBox, OperationalBox, QAfterFilterCondition>
      nameLessThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OperationalBox, OperationalBox, QAfterFilterCondition>
      nameBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 1,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OperationalBox, OperationalBox, QAfterFilterCondition>
      nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OperationalBox, OperationalBox, QAfterFilterCondition>
      nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OperationalBox, OperationalBox, QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OperationalBox, OperationalBox, QAfterFilterCondition>
      nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 1,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OperationalBox, OperationalBox, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 1,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<OperationalBox, OperationalBox, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 1,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<OperationalBox, OperationalBox, QAfterFilterCondition>
      dataIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 2));
    });
  }

  QueryBuilder<OperationalBox, OperationalBox, QAfterFilterCondition>
      dataIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 2));
    });
  }

  QueryBuilder<OperationalBox, OperationalBox, QAfterFilterCondition>
      dataEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OperationalBox, OperationalBox, QAfterFilterCondition>
      dataGreaterThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OperationalBox, OperationalBox, QAfterFilterCondition>
      dataGreaterThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OperationalBox, OperationalBox, QAfterFilterCondition>
      dataLessThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OperationalBox, OperationalBox, QAfterFilterCondition>
      dataLessThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OperationalBox, OperationalBox, QAfterFilterCondition>
      dataBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 2,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OperationalBox, OperationalBox, QAfterFilterCondition>
      dataStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OperationalBox, OperationalBox, QAfterFilterCondition>
      dataEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OperationalBox, OperationalBox, QAfterFilterCondition>
      dataContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OperationalBox, OperationalBox, QAfterFilterCondition>
      dataMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 2,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OperationalBox, OperationalBox, QAfterFilterCondition>
      dataIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 2,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<OperationalBox, OperationalBox, QAfterFilterCondition>
      dataIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 2,
          value: '',
        ),
      );
    });
  }
}

extension OperationalBoxQueryObject
    on QueryBuilder<OperationalBox, OperationalBox, QFilterCondition> {}

extension OperationalBoxQuerySortBy
    on QueryBuilder<OperationalBox, OperationalBox, QSortBy> {
  QueryBuilder<OperationalBox, OperationalBox, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<OperationalBox, OperationalBox, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<OperationalBox, OperationalBox, QAfterSortBy> sortByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        1,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<OperationalBox, OperationalBox, QAfterSortBy> sortByNameDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        1,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<OperationalBox, OperationalBox, QAfterSortBy> sortByData(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        2,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<OperationalBox, OperationalBox, QAfterSortBy> sortByDataDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        2,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }
}

extension OperationalBoxQuerySortThenBy
    on QueryBuilder<OperationalBox, OperationalBox, QSortThenBy> {
  QueryBuilder<OperationalBox, OperationalBox, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<OperationalBox, OperationalBox, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<OperationalBox, OperationalBox, QAfterSortBy> thenByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OperationalBox, OperationalBox, QAfterSortBy> thenByNameDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OperationalBox, OperationalBox, QAfterSortBy> thenByData(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OperationalBox, OperationalBox, QAfterSortBy> thenByDataDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }
}

extension OperationalBoxQueryWhereDistinct
    on QueryBuilder<OperationalBox, OperationalBox, QDistinct> {
  QueryBuilder<OperationalBox, OperationalBox, QAfterDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OperationalBox, OperationalBox, QAfterDistinct> distinctByData(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(2, caseSensitive: caseSensitive);
    });
  }
}

extension OperationalBoxQueryProperty1
    on QueryBuilder<OperationalBox, OperationalBox, QProperty> {
  QueryBuilder<OperationalBox, int, QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<OperationalBox, String?, QAfterProperty> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<OperationalBox, String?, QAfterProperty> dataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }
}

extension OperationalBoxQueryProperty2<R>
    on QueryBuilder<OperationalBox, R, QAfterProperty> {
  QueryBuilder<OperationalBox, (R, int), QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<OperationalBox, (R, String?), QAfterProperty> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<OperationalBox, (R, String?), QAfterProperty> dataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }
}

extension OperationalBoxQueryProperty3<R1, R2>
    on QueryBuilder<OperationalBox, (R1, R2), QAfterProperty> {
  QueryBuilder<OperationalBox, (R1, R2, int), QOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<OperationalBox, (R1, R2, String?), QOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<OperationalBox, (R1, R2, String?), QOperations> dataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

extension GetRegistryBoxCollection on Isar {
  IsarCollection<int, RegistryBox> get registryBoxs => this.collection();
}

final RegistryBoxSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'RegistryBox',
    idName: 'id',
    embedded: false,
    properties: [
      IsarPropertySchema(
        name: 'registryId',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'parentId',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'transactionIndex',
        type: IsarType.long,
      ),
      IsarPropertySchema(
        name: 'ttransaction',
        type: IsarType.string,
      ),
    ],
    indexes: [
      IsarIndexSchema(
        name: 'registryId_transactionIndex',
        properties: [
          "registryId",
          "transactionIndex",
        ],
        unique: true,
        hash: true,
      ),
    ],
  ),
  converter: IsarObjectConverter<int, RegistryBox>(
    serialize: serializeRegistryBox,
    deserialize: deserializeRegistryBox,
    deserializeProperty: deserializeRegistryBoxProp,
  ),
  getEmbeddedSchemas: () => [],
);

@isarProtected
int serializeRegistryBox(IsarWriter writer, RegistryBox object) {
  {
    final value = object.registryId;
    if (value == null) {
      IsarCore.writeNull(writer, 1);
    } else {
      IsarCore.writeString(writer, 1, value);
    }
  }
  {
    final value = object.parentId;
    if (value == null) {
      IsarCore.writeNull(writer, 2);
    } else {
      IsarCore.writeString(writer, 2, value);
    }
  }
  IsarCore.writeLong(
      writer, 3, object.transactionIndex ?? -9223372036854775808);
  {
    final value = object.ttransaction;
    if (value == null) {
      IsarCore.writeNull(writer, 4);
    } else {
      IsarCore.writeString(writer, 4, value);
    }
  }
  return object.id;
}

@isarProtected
RegistryBox deserializeRegistryBox(IsarReader reader) {
  final object = RegistryBox();
  object.id = IsarCore.readId(reader);
  object.registryId = IsarCore.readString(reader, 1);
  object.parentId = IsarCore.readString(reader, 2);
  {
    final value = IsarCore.readLong(reader, 3);
    if (value == -9223372036854775808) {
      object.transactionIndex = null;
    } else {
      object.transactionIndex = value;
    }
  }
  object.ttransaction = IsarCore.readString(reader, 4);
  return object;
}

@isarProtected
dynamic deserializeRegistryBoxProp(IsarReader reader, int property) {
  switch (property) {
    case 0:
      return IsarCore.readId(reader);
    case 1:
      return IsarCore.readString(reader, 1);
    case 2:
      return IsarCore.readString(reader, 2);
    case 3:
      {
        final value = IsarCore.readLong(reader, 3);
        if (value == -9223372036854775808) {
          return null;
        } else {
          return value;
        }
      }
    case 4:
      return IsarCore.readString(reader, 4);
    default:
      throw ArgumentError('Unknown property: $property');
  }
}

sealed class _RegistryBoxUpdate {
  bool call({
    required int id,
    String? registryId,
    String? parentId,
    int? transactionIndex,
    String? ttransaction,
  });
}

class _RegistryBoxUpdateImpl implements _RegistryBoxUpdate {
  const _RegistryBoxUpdateImpl(this.collection);

  final IsarCollection<int, RegistryBox> collection;

  @override
  bool call({
    required int id,
    Object? registryId = ignore,
    Object? parentId = ignore,
    Object? transactionIndex = ignore,
    Object? ttransaction = ignore,
  }) {
    return collection.updateProperties([
          id
        ], {
          if (registryId != ignore) 1: registryId as String?,
          if (parentId != ignore) 2: parentId as String?,
          if (transactionIndex != ignore) 3: transactionIndex as int?,
          if (ttransaction != ignore) 4: ttransaction as String?,
        }) >
        0;
  }
}

sealed class _RegistryBoxUpdateAll {
  int call({
    required List<int> id,
    String? registryId,
    String? parentId,
    int? transactionIndex,
    String? ttransaction,
  });
}

class _RegistryBoxUpdateAllImpl implements _RegistryBoxUpdateAll {
  const _RegistryBoxUpdateAllImpl(this.collection);

  final IsarCollection<int, RegistryBox> collection;

  @override
  int call({
    required List<int> id,
    Object? registryId = ignore,
    Object? parentId = ignore,
    Object? transactionIndex = ignore,
    Object? ttransaction = ignore,
  }) {
    return collection.updateProperties(id, {
      if (registryId != ignore) 1: registryId as String?,
      if (parentId != ignore) 2: parentId as String?,
      if (transactionIndex != ignore) 3: transactionIndex as int?,
      if (ttransaction != ignore) 4: ttransaction as String?,
    });
  }
}

extension RegistryBoxUpdate on IsarCollection<int, RegistryBox> {
  _RegistryBoxUpdate get update => _RegistryBoxUpdateImpl(this);

  _RegistryBoxUpdateAll get updateAll => _RegistryBoxUpdateAllImpl(this);
}

sealed class _RegistryBoxQueryUpdate {
  int call({
    String? registryId,
    String? parentId,
    int? transactionIndex,
    String? ttransaction,
  });
}

class _RegistryBoxQueryUpdateImpl implements _RegistryBoxQueryUpdate {
  const _RegistryBoxQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<RegistryBox> query;
  final int? limit;

  @override
  int call({
    Object? registryId = ignore,
    Object? parentId = ignore,
    Object? transactionIndex = ignore,
    Object? ttransaction = ignore,
  }) {
    return query.updateProperties(limit: limit, {
      if (registryId != ignore) 1: registryId as String?,
      if (parentId != ignore) 2: parentId as String?,
      if (transactionIndex != ignore) 3: transactionIndex as int?,
      if (ttransaction != ignore) 4: ttransaction as String?,
    });
  }
}

extension RegistryBoxQueryUpdate on IsarQuery<RegistryBox> {
  _RegistryBoxQueryUpdate get updateFirst =>
      _RegistryBoxQueryUpdateImpl(this, limit: 1);

  _RegistryBoxQueryUpdate get updateAll => _RegistryBoxQueryUpdateImpl(this);
}

class _RegistryBoxQueryBuilderUpdateImpl implements _RegistryBoxQueryUpdate {
  const _RegistryBoxQueryBuilderUpdateImpl(this.query, {this.limit});

  final QueryBuilder<RegistryBox, RegistryBox, QOperations> query;
  final int? limit;

  @override
  int call({
    Object? registryId = ignore,
    Object? parentId = ignore,
    Object? transactionIndex = ignore,
    Object? ttransaction = ignore,
  }) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (registryId != ignore) 1: registryId as String?,
        if (parentId != ignore) 2: parentId as String?,
        if (transactionIndex != ignore) 3: transactionIndex as int?,
        if (ttransaction != ignore) 4: ttransaction as String?,
      });
    } finally {
      q.close();
    }
  }
}

extension RegistryBoxQueryBuilderUpdate
    on QueryBuilder<RegistryBox, RegistryBox, QOperations> {
  _RegistryBoxQueryUpdate get updateFirst =>
      _RegistryBoxQueryBuilderUpdateImpl(this, limit: 1);

  _RegistryBoxQueryUpdate get updateAll =>
      _RegistryBoxQueryBuilderUpdateImpl(this);
}

extension RegistryBoxQueryFilter
    on QueryBuilder<RegistryBox, RegistryBox, QFilterCondition> {
  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition> idEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition> idGreaterThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      idGreaterThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition> idLessThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      idLessThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition> idBetween(
    int lower,
    int upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 0,
          lower: lower,
          upper: upper,
        ),
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      registryIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 1));
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      registryIdIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 1));
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      registryIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      registryIdGreaterThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      registryIdGreaterThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      registryIdLessThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      registryIdLessThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      registryIdBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 1,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      registryIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      registryIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      registryIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      registryIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 1,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      registryIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 1,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      registryIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 1,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      parentIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 2));
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      parentIdIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 2));
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition> parentIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      parentIdGreaterThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      parentIdGreaterThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      parentIdLessThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      parentIdLessThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition> parentIdBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 2,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      parentIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      parentIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      parentIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition> parentIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 2,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      parentIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 2,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      parentIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 2,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      transactionIndexIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 3));
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      transactionIndexIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 3));
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      transactionIndexEqualTo(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 3,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      transactionIndexGreaterThan(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 3,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      transactionIndexGreaterThanOrEqualTo(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 3,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      transactionIndexLessThan(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 3,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      transactionIndexLessThanOrEqualTo(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 3,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      transactionIndexBetween(
    int? lower,
    int? upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 3,
          lower: lower,
          upper: upper,
        ),
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      ttransactionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 4));
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      ttransactionIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 4));
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      ttransactionEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      ttransactionGreaterThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      ttransactionGreaterThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      ttransactionLessThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      ttransactionLessThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      ttransactionBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 4,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      ttransactionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      ttransactionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      ttransactionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      ttransactionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 4,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      ttransactionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 4,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterFilterCondition>
      ttransactionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 4,
          value: '',
        ),
      );
    });
  }
}

extension RegistryBoxQueryObject
    on QueryBuilder<RegistryBox, RegistryBox, QFilterCondition> {}

extension RegistryBoxQuerySortBy
    on QueryBuilder<RegistryBox, RegistryBox, QSortBy> {
  QueryBuilder<RegistryBox, RegistryBox, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterSortBy> sortByRegistryId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        1,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterSortBy> sortByRegistryIdDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        1,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterSortBy> sortByParentId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        2,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterSortBy> sortByParentIdDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        2,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterSortBy>
      sortByTransactionIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3);
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterSortBy>
      sortByTransactionIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc);
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterSortBy> sortByTtransaction(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        4,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterSortBy> sortByTtransactionDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        4,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }
}

extension RegistryBoxQuerySortThenBy
    on QueryBuilder<RegistryBox, RegistryBox, QSortThenBy> {
  QueryBuilder<RegistryBox, RegistryBox, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterSortBy> thenByRegistryId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterSortBy> thenByRegistryIdDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterSortBy> thenByParentId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterSortBy> thenByParentIdDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterSortBy>
      thenByTransactionIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3);
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterSortBy>
      thenByTransactionIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc);
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterSortBy> thenByTtransaction(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterSortBy> thenByTtransactionDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }
}

extension RegistryBoxQueryWhereDistinct
    on QueryBuilder<RegistryBox, RegistryBox, QDistinct> {
  QueryBuilder<RegistryBox, RegistryBox, QAfterDistinct> distinctByRegistryId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterDistinct> distinctByParentId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterDistinct>
      distinctByTransactionIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(3);
    });
  }

  QueryBuilder<RegistryBox, RegistryBox, QAfterDistinct> distinctByTtransaction(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(4, caseSensitive: caseSensitive);
    });
  }
}

extension RegistryBoxQueryProperty1
    on QueryBuilder<RegistryBox, RegistryBox, QProperty> {
  QueryBuilder<RegistryBox, int, QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<RegistryBox, String?, QAfterProperty> registryIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<RegistryBox, String?, QAfterProperty> parentIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<RegistryBox, int?, QAfterProperty> transactionIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<RegistryBox, String?, QAfterProperty> ttransactionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }
}

extension RegistryBoxQueryProperty2<R>
    on QueryBuilder<RegistryBox, R, QAfterProperty> {
  QueryBuilder<RegistryBox, (R, int), QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<RegistryBox, (R, String?), QAfterProperty> registryIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<RegistryBox, (R, String?), QAfterProperty> parentIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<RegistryBox, (R, int?), QAfterProperty>
      transactionIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<RegistryBox, (R, String?), QAfterProperty>
      ttransactionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }
}

extension RegistryBoxQueryProperty3<R1, R2>
    on QueryBuilder<RegistryBox, (R1, R2), QAfterProperty> {
  QueryBuilder<RegistryBox, (R1, R2, int), QOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<RegistryBox, (R1, R2, String?), QOperations>
      registryIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<RegistryBox, (R1, R2, String?), QOperations> parentIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<RegistryBox, (R1, R2, int?), QOperations>
      transactionIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<RegistryBox, (R1, R2, String?), QOperations>
      ttransactionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

extension GetHistoryQueueHeadIdxCollection on Isar {
  IsarCollection<int, HistoryQueueHeadIdx> get historyQueueHeadIdxs =>
      this.collection();
}

final HistoryQueueHeadIdxSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'HistoryQueueHeadIdx',
    idName: 'id',
    embedded: false,
    properties: [
      IsarPropertySchema(
        name: 'value',
        type: IsarType.long,
      ),
    ],
    indexes: [],
  ),
  converter: IsarObjectConverter<int, HistoryQueueHeadIdx>(
    serialize: serializeHistoryQueueHeadIdx,
    deserialize: deserializeHistoryQueueHeadIdx,
    deserializeProperty: deserializeHistoryQueueHeadIdxProp,
  ),
  getEmbeddedSchemas: () => [],
);

@isarProtected
int serializeHistoryQueueHeadIdx(
    IsarWriter writer, HistoryQueueHeadIdx object) {
  IsarCore.writeLong(writer, 1, object.value);
  return object.id;
}

@isarProtected
HistoryQueueHeadIdx deserializeHistoryQueueHeadIdx(IsarReader reader) {
  final object = HistoryQueueHeadIdx();
  object.id = IsarCore.readId(reader);
  object.value = IsarCore.readLong(reader, 1);
  return object;
}

@isarProtected
dynamic deserializeHistoryQueueHeadIdxProp(IsarReader reader, int property) {
  switch (property) {
    case 0:
      return IsarCore.readId(reader);
    case 1:
      return IsarCore.readLong(reader, 1);
    default:
      throw ArgumentError('Unknown property: $property');
  }
}

sealed class _HistoryQueueHeadIdxUpdate {
  bool call({
    required int id,
    int? value,
  });
}

class _HistoryQueueHeadIdxUpdateImpl implements _HistoryQueueHeadIdxUpdate {
  const _HistoryQueueHeadIdxUpdateImpl(this.collection);

  final IsarCollection<int, HistoryQueueHeadIdx> collection;

  @override
  bool call({
    required int id,
    Object? value = ignore,
  }) {
    return collection.updateProperties([
          id
        ], {
          if (value != ignore) 1: value as int?,
        }) >
        0;
  }
}

sealed class _HistoryQueueHeadIdxUpdateAll {
  int call({
    required List<int> id,
    int? value,
  });
}

class _HistoryQueueHeadIdxUpdateAllImpl
    implements _HistoryQueueHeadIdxUpdateAll {
  const _HistoryQueueHeadIdxUpdateAllImpl(this.collection);

  final IsarCollection<int, HistoryQueueHeadIdx> collection;

  @override
  int call({
    required List<int> id,
    Object? value = ignore,
  }) {
    return collection.updateProperties(id, {
      if (value != ignore) 1: value as int?,
    });
  }
}

extension HistoryQueueHeadIdxUpdate
    on IsarCollection<int, HistoryQueueHeadIdx> {
  _HistoryQueueHeadIdxUpdate get update => _HistoryQueueHeadIdxUpdateImpl(this);

  _HistoryQueueHeadIdxUpdateAll get updateAll =>
      _HistoryQueueHeadIdxUpdateAllImpl(this);
}

sealed class _HistoryQueueHeadIdxQueryUpdate {
  int call({
    int? value,
  });
}

class _HistoryQueueHeadIdxQueryUpdateImpl
    implements _HistoryQueueHeadIdxQueryUpdate {
  const _HistoryQueueHeadIdxQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<HistoryQueueHeadIdx> query;
  final int? limit;

  @override
  int call({
    Object? value = ignore,
  }) {
    return query.updateProperties(limit: limit, {
      if (value != ignore) 1: value as int?,
    });
  }
}

extension HistoryQueueHeadIdxQueryUpdate on IsarQuery<HistoryQueueHeadIdx> {
  _HistoryQueueHeadIdxQueryUpdate get updateFirst =>
      _HistoryQueueHeadIdxQueryUpdateImpl(this, limit: 1);

  _HistoryQueueHeadIdxQueryUpdate get updateAll =>
      _HistoryQueueHeadIdxQueryUpdateImpl(this);
}

class _HistoryQueueHeadIdxQueryBuilderUpdateImpl
    implements _HistoryQueueHeadIdxQueryUpdate {
  const _HistoryQueueHeadIdxQueryBuilderUpdateImpl(this.query, {this.limit});

  final QueryBuilder<HistoryQueueHeadIdx, HistoryQueueHeadIdx, QOperations>
      query;
  final int? limit;

  @override
  int call({
    Object? value = ignore,
  }) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (value != ignore) 1: value as int?,
      });
    } finally {
      q.close();
    }
  }
}

extension HistoryQueueHeadIdxQueryBuilderUpdate
    on QueryBuilder<HistoryQueueHeadIdx, HistoryQueueHeadIdx, QOperations> {
  _HistoryQueueHeadIdxQueryUpdate get updateFirst =>
      _HistoryQueueHeadIdxQueryBuilderUpdateImpl(this, limit: 1);

  _HistoryQueueHeadIdxQueryUpdate get updateAll =>
      _HistoryQueueHeadIdxQueryBuilderUpdateImpl(this);
}

extension HistoryQueueHeadIdxQueryFilter on QueryBuilder<HistoryQueueHeadIdx,
    HistoryQueueHeadIdx, QFilterCondition> {
  QueryBuilder<HistoryQueueHeadIdx, HistoryQueueHeadIdx, QAfterFilterCondition>
      idEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<HistoryQueueHeadIdx, HistoryQueueHeadIdx, QAfterFilterCondition>
      idGreaterThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<HistoryQueueHeadIdx, HistoryQueueHeadIdx, QAfterFilterCondition>
      idGreaterThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<HistoryQueueHeadIdx, HistoryQueueHeadIdx, QAfterFilterCondition>
      idLessThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<HistoryQueueHeadIdx, HistoryQueueHeadIdx, QAfterFilterCondition>
      idLessThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<HistoryQueueHeadIdx, HistoryQueueHeadIdx, QAfterFilterCondition>
      idBetween(
    int lower,
    int upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 0,
          lower: lower,
          upper: upper,
        ),
      );
    });
  }

  QueryBuilder<HistoryQueueHeadIdx, HistoryQueueHeadIdx, QAfterFilterCondition>
      valueEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 1,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<HistoryQueueHeadIdx, HistoryQueueHeadIdx, QAfterFilterCondition>
      valueGreaterThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 1,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<HistoryQueueHeadIdx, HistoryQueueHeadIdx, QAfterFilterCondition>
      valueGreaterThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 1,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<HistoryQueueHeadIdx, HistoryQueueHeadIdx, QAfterFilterCondition>
      valueLessThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 1,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<HistoryQueueHeadIdx, HistoryQueueHeadIdx, QAfterFilterCondition>
      valueLessThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 1,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<HistoryQueueHeadIdx, HistoryQueueHeadIdx, QAfterFilterCondition>
      valueBetween(
    int lower,
    int upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 1,
          lower: lower,
          upper: upper,
        ),
      );
    });
  }
}

extension HistoryQueueHeadIdxQueryObject on QueryBuilder<HistoryQueueHeadIdx,
    HistoryQueueHeadIdx, QFilterCondition> {}

extension HistoryQueueHeadIdxQuerySortBy
    on QueryBuilder<HistoryQueueHeadIdx, HistoryQueueHeadIdx, QSortBy> {
  QueryBuilder<HistoryQueueHeadIdx, HistoryQueueHeadIdx, QAfterSortBy>
      sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<HistoryQueueHeadIdx, HistoryQueueHeadIdx, QAfterSortBy>
      sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<HistoryQueueHeadIdx, HistoryQueueHeadIdx, QAfterSortBy>
      sortByValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1);
    });
  }

  QueryBuilder<HistoryQueueHeadIdx, HistoryQueueHeadIdx, QAfterSortBy>
      sortByValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc);
    });
  }
}

extension HistoryQueueHeadIdxQuerySortThenBy
    on QueryBuilder<HistoryQueueHeadIdx, HistoryQueueHeadIdx, QSortThenBy> {
  QueryBuilder<HistoryQueueHeadIdx, HistoryQueueHeadIdx, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<HistoryQueueHeadIdx, HistoryQueueHeadIdx, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<HistoryQueueHeadIdx, HistoryQueueHeadIdx, QAfterSortBy>
      thenByValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1);
    });
  }

  QueryBuilder<HistoryQueueHeadIdx, HistoryQueueHeadIdx, QAfterSortBy>
      thenByValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc);
    });
  }
}

extension HistoryQueueHeadIdxQueryWhereDistinct
    on QueryBuilder<HistoryQueueHeadIdx, HistoryQueueHeadIdx, QDistinct> {
  QueryBuilder<HistoryQueueHeadIdx, HistoryQueueHeadIdx, QAfterDistinct>
      distinctByValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(1);
    });
  }
}

extension HistoryQueueHeadIdxQueryProperty1
    on QueryBuilder<HistoryQueueHeadIdx, HistoryQueueHeadIdx, QProperty> {
  QueryBuilder<HistoryQueueHeadIdx, int, QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<HistoryQueueHeadIdx, int, QAfterProperty> valueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }
}

extension HistoryQueueHeadIdxQueryProperty2<R>
    on QueryBuilder<HistoryQueueHeadIdx, R, QAfterProperty> {
  QueryBuilder<HistoryQueueHeadIdx, (R, int), QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<HistoryQueueHeadIdx, (R, int), QAfterProperty> valueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }
}

extension HistoryQueueHeadIdxQueryProperty3<R1, R2>
    on QueryBuilder<HistoryQueueHeadIdx, (R1, R2), QAfterProperty> {
  QueryBuilder<HistoryQueueHeadIdx, (R1, R2, int), QOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<HistoryQueueHeadIdx, (R1, R2, int), QOperations>
      valueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

extension GetHistoryQueueTailIdxCollection on Isar {
  IsarCollection<int, HistoryQueueTailIdx> get historyQueueTailIdxs =>
      this.collection();
}

final HistoryQueueTailIdxSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'HistoryQueueTailIdx',
    idName: 'id',
    embedded: false,
    properties: [
      IsarPropertySchema(
        name: 'value',
        type: IsarType.long,
      ),
    ],
    indexes: [],
  ),
  converter: IsarObjectConverter<int, HistoryQueueTailIdx>(
    serialize: serializeHistoryQueueTailIdx,
    deserialize: deserializeHistoryQueueTailIdx,
    deserializeProperty: deserializeHistoryQueueTailIdxProp,
  ),
  getEmbeddedSchemas: () => [],
);

@isarProtected
int serializeHistoryQueueTailIdx(
    IsarWriter writer, HistoryQueueTailIdx object) {
  IsarCore.writeLong(writer, 1, object.value);
  return object.id;
}

@isarProtected
HistoryQueueTailIdx deserializeHistoryQueueTailIdx(IsarReader reader) {
  final object = HistoryQueueTailIdx();
  object.id = IsarCore.readId(reader);
  object.value = IsarCore.readLong(reader, 1);
  return object;
}

@isarProtected
dynamic deserializeHistoryQueueTailIdxProp(IsarReader reader, int property) {
  switch (property) {
    case 0:
      return IsarCore.readId(reader);
    case 1:
      return IsarCore.readLong(reader, 1);
    default:
      throw ArgumentError('Unknown property: $property');
  }
}

sealed class _HistoryQueueTailIdxUpdate {
  bool call({
    required int id,
    int? value,
  });
}

class _HistoryQueueTailIdxUpdateImpl implements _HistoryQueueTailIdxUpdate {
  const _HistoryQueueTailIdxUpdateImpl(this.collection);

  final IsarCollection<int, HistoryQueueTailIdx> collection;

  @override
  bool call({
    required int id,
    Object? value = ignore,
  }) {
    return collection.updateProperties([
          id
        ], {
          if (value != ignore) 1: value as int?,
        }) >
        0;
  }
}

sealed class _HistoryQueueTailIdxUpdateAll {
  int call({
    required List<int> id,
    int? value,
  });
}

class _HistoryQueueTailIdxUpdateAllImpl
    implements _HistoryQueueTailIdxUpdateAll {
  const _HistoryQueueTailIdxUpdateAllImpl(this.collection);

  final IsarCollection<int, HistoryQueueTailIdx> collection;

  @override
  int call({
    required List<int> id,
    Object? value = ignore,
  }) {
    return collection.updateProperties(id, {
      if (value != ignore) 1: value as int?,
    });
  }
}

extension HistoryQueueTailIdxUpdate
    on IsarCollection<int, HistoryQueueTailIdx> {
  _HistoryQueueTailIdxUpdate get update => _HistoryQueueTailIdxUpdateImpl(this);

  _HistoryQueueTailIdxUpdateAll get updateAll =>
      _HistoryQueueTailIdxUpdateAllImpl(this);
}

sealed class _HistoryQueueTailIdxQueryUpdate {
  int call({
    int? value,
  });
}

class _HistoryQueueTailIdxQueryUpdateImpl
    implements _HistoryQueueTailIdxQueryUpdate {
  const _HistoryQueueTailIdxQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<HistoryQueueTailIdx> query;
  final int? limit;

  @override
  int call({
    Object? value = ignore,
  }) {
    return query.updateProperties(limit: limit, {
      if (value != ignore) 1: value as int?,
    });
  }
}

extension HistoryQueueTailIdxQueryUpdate on IsarQuery<HistoryQueueTailIdx> {
  _HistoryQueueTailIdxQueryUpdate get updateFirst =>
      _HistoryQueueTailIdxQueryUpdateImpl(this, limit: 1);

  _HistoryQueueTailIdxQueryUpdate get updateAll =>
      _HistoryQueueTailIdxQueryUpdateImpl(this);
}

class _HistoryQueueTailIdxQueryBuilderUpdateImpl
    implements _HistoryQueueTailIdxQueryUpdate {
  const _HistoryQueueTailIdxQueryBuilderUpdateImpl(this.query, {this.limit});

  final QueryBuilder<HistoryQueueTailIdx, HistoryQueueTailIdx, QOperations>
      query;
  final int? limit;

  @override
  int call({
    Object? value = ignore,
  }) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (value != ignore) 1: value as int?,
      });
    } finally {
      q.close();
    }
  }
}

extension HistoryQueueTailIdxQueryBuilderUpdate
    on QueryBuilder<HistoryQueueTailIdx, HistoryQueueTailIdx, QOperations> {
  _HistoryQueueTailIdxQueryUpdate get updateFirst =>
      _HistoryQueueTailIdxQueryBuilderUpdateImpl(this, limit: 1);

  _HistoryQueueTailIdxQueryUpdate get updateAll =>
      _HistoryQueueTailIdxQueryBuilderUpdateImpl(this);
}

extension HistoryQueueTailIdxQueryFilter on QueryBuilder<HistoryQueueTailIdx,
    HistoryQueueTailIdx, QFilterCondition> {
  QueryBuilder<HistoryQueueTailIdx, HistoryQueueTailIdx, QAfterFilterCondition>
      idEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<HistoryQueueTailIdx, HistoryQueueTailIdx, QAfterFilterCondition>
      idGreaterThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<HistoryQueueTailIdx, HistoryQueueTailIdx, QAfterFilterCondition>
      idGreaterThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<HistoryQueueTailIdx, HistoryQueueTailIdx, QAfterFilterCondition>
      idLessThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<HistoryQueueTailIdx, HistoryQueueTailIdx, QAfterFilterCondition>
      idLessThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<HistoryQueueTailIdx, HistoryQueueTailIdx, QAfterFilterCondition>
      idBetween(
    int lower,
    int upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 0,
          lower: lower,
          upper: upper,
        ),
      );
    });
  }

  QueryBuilder<HistoryQueueTailIdx, HistoryQueueTailIdx, QAfterFilterCondition>
      valueEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 1,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<HistoryQueueTailIdx, HistoryQueueTailIdx, QAfterFilterCondition>
      valueGreaterThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 1,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<HistoryQueueTailIdx, HistoryQueueTailIdx, QAfterFilterCondition>
      valueGreaterThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 1,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<HistoryQueueTailIdx, HistoryQueueTailIdx, QAfterFilterCondition>
      valueLessThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 1,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<HistoryQueueTailIdx, HistoryQueueTailIdx, QAfterFilterCondition>
      valueLessThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 1,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<HistoryQueueTailIdx, HistoryQueueTailIdx, QAfterFilterCondition>
      valueBetween(
    int lower,
    int upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 1,
          lower: lower,
          upper: upper,
        ),
      );
    });
  }
}

extension HistoryQueueTailIdxQueryObject on QueryBuilder<HistoryQueueTailIdx,
    HistoryQueueTailIdx, QFilterCondition> {}

extension HistoryQueueTailIdxQuerySortBy
    on QueryBuilder<HistoryQueueTailIdx, HistoryQueueTailIdx, QSortBy> {
  QueryBuilder<HistoryQueueTailIdx, HistoryQueueTailIdx, QAfterSortBy>
      sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<HistoryQueueTailIdx, HistoryQueueTailIdx, QAfterSortBy>
      sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<HistoryQueueTailIdx, HistoryQueueTailIdx, QAfterSortBy>
      sortByValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1);
    });
  }

  QueryBuilder<HistoryQueueTailIdx, HistoryQueueTailIdx, QAfterSortBy>
      sortByValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc);
    });
  }
}

extension HistoryQueueTailIdxQuerySortThenBy
    on QueryBuilder<HistoryQueueTailIdx, HistoryQueueTailIdx, QSortThenBy> {
  QueryBuilder<HistoryQueueTailIdx, HistoryQueueTailIdx, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<HistoryQueueTailIdx, HistoryQueueTailIdx, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<HistoryQueueTailIdx, HistoryQueueTailIdx, QAfterSortBy>
      thenByValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1);
    });
  }

  QueryBuilder<HistoryQueueTailIdx, HistoryQueueTailIdx, QAfterSortBy>
      thenByValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc);
    });
  }
}

extension HistoryQueueTailIdxQueryWhereDistinct
    on QueryBuilder<HistoryQueueTailIdx, HistoryQueueTailIdx, QDistinct> {
  QueryBuilder<HistoryQueueTailIdx, HistoryQueueTailIdx, QAfterDistinct>
      distinctByValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(1);
    });
  }
}

extension HistoryQueueTailIdxQueryProperty1
    on QueryBuilder<HistoryQueueTailIdx, HistoryQueueTailIdx, QProperty> {
  QueryBuilder<HistoryQueueTailIdx, int, QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<HistoryQueueTailIdx, int, QAfterProperty> valueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }
}

extension HistoryQueueTailIdxQueryProperty2<R>
    on QueryBuilder<HistoryQueueTailIdx, R, QAfterProperty> {
  QueryBuilder<HistoryQueueTailIdx, (R, int), QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<HistoryQueueTailIdx, (R, int), QAfterProperty> valueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }
}

extension HistoryQueueTailIdxQueryProperty3<R1, R2>
    on QueryBuilder<HistoryQueueTailIdx, (R1, R2), QAfterProperty> {
  QueryBuilder<HistoryQueueTailIdx, (R1, R2, int), QOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<HistoryQueueTailIdx, (R1, R2, int), QOperations>
      valueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }
}

// **************************************************************************
// _IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

final ModelContainerSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'ModelContainer',
    embedded: true,
    properties: [],
    indexes: [],
  ),
  converter: IsarObjectConverter<void, ModelContainer>(
    serialize: serializeModelContainer,
    deserialize: deserializeModelContainer,
  ),
);

@isarProtected
int serializeModelContainer(IsarWriter writer, ModelContainer object) {
  return 0;
}

@isarProtected
ModelContainer deserializeModelContainer(IsarReader reader) {
  final object = ModelContainer();
  return object;
}

extension ModelContainerQueryFilter
    on QueryBuilder<ModelContainer, ModelContainer, QFilterCondition> {}

extension ModelContainerQueryObject
    on QueryBuilder<ModelContainer, ModelContainer, QFilterCondition> {}
