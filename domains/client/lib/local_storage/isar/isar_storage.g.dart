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
        name: 'byModelId',
        properties: [
          "modelId",
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
  {
    final value = object.modelData;
    if (value == null) {
      IsarCore.writeNull(writer, 2);
    } else {
      IsarCore.writeString(writer, 2, value);
    }
  }
  {
    final value = object.model;
    if (value == null) {
      IsarCore.writeNull(writer, 3);
    } else {
      final objectWriter = IsarCore.beginObject(writer, 3);
      serializeModelContainer(objectWriter, value);
      IsarCore.endObject(writer, objectWriter);
    }
  }
  {
    final value = object.rootParentId;
    if (value == null) {
      IsarCore.writeNull(writer, 4);
    } else {
      IsarCore.writeString(writer, 4, value);
    }
  }
  return object.id;
}

@isarProtected
ModelBox deserializeModelBox(IsarReader reader) {
  final object = ModelBox();
  object.id = IsarCore.readId(reader);
  object.modelId = IsarCore.readString(reader, 1);
  object.modelData = IsarCore.readString(reader, 2);
  {
    final objectReader = IsarCore.readObject(reader, 3);
    if (objectReader.isNull) {
      object.model = null;
    } else {
      final embedded = deserializeModelContainer(objectReader);
      IsarCore.freeReader(objectReader);
      object.model = embedded;
    }
  }
  object.rootParentId = IsarCore.readString(reader, 4);
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
      return IsarCore.readString(reader, 2);
    case 3:
      {
        final objectReader = IsarCore.readObject(reader, 3);
        if (objectReader.isNull) {
          return null;
        } else {
          final embedded = deserializeModelContainer(objectReader);
          IsarCore.freeReader(objectReader);
          return embedded;
        }
      }
    case 4:
      return IsarCore.readString(reader, 4);
    default:
      throw ArgumentError('Unknown property: $property');
  }
}

sealed class _ModelBoxUpdate {
  bool call({
    required int id,
    String? modelId,
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
    Object? modelData = ignore,
    Object? rootParentId = ignore,
  }) {
    return collection.updateProperties([
          id
        ], {
          if (modelId != ignore) 1: modelId as String?,
          if (modelData != ignore) 2: modelData as String?,
          if (rootParentId != ignore) 4: rootParentId as String?,
        }) >
        0;
  }
}

sealed class _ModelBoxUpdateAll {
  int call({
    required List<int> id,
    String? modelId,
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
    Object? modelData = ignore,
    Object? rootParentId = ignore,
  }) {
    return collection.updateProperties(id, {
      if (modelId != ignore) 1: modelId as String?,
      if (modelData != ignore) 2: modelData as String?,
      if (rootParentId != ignore) 4: rootParentId as String?,
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
    Object? modelData = ignore,
    Object? rootParentId = ignore,
  }) {
    return query.updateProperties(limit: limit, {
      if (modelId != ignore) 1: modelId as String?,
      if (modelData != ignore) 2: modelData as String?,
      if (rootParentId != ignore) 4: rootParentId as String?,
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
    Object? modelData = ignore,
    Object? rootParentId = ignore,
  }) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (modelId != ignore) 1: modelId as String?,
        if (modelData != ignore) 2: modelData as String?,
        if (rootParentId != ignore) 4: rootParentId as String?,
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

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> modelDataIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 2));
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> modelDataIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 2));
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> modelDataEqualTo(
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

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> modelDataGreaterThan(
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

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition>
      modelDataGreaterThanOrEqualTo(
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

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> modelDataLessThan(
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

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition>
      modelDataLessThanOrEqualTo(
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

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> modelDataBetween(
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

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> modelDataStartsWith(
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

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> modelDataEndsWith(
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

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> modelDataContains(
      String value,
      {bool caseSensitive = true}) {
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

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> modelDataMatches(
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

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> modelDataIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 2,
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
          property: 2,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> modelIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 3));
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> modelIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 3));
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> rootParentIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 4));
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition>
      rootParentIdIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 4));
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> rootParentIdEqualTo(
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

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition>
      rootParentIdGreaterThan(
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

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition>
      rootParentIdGreaterThanOrEqualTo(
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

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> rootParentIdLessThan(
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

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition>
      rootParentIdLessThanOrEqualTo(
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

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> rootParentIdBetween(
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

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition>
      rootParentIdStartsWith(
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

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> rootParentIdEndsWith(
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

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> rootParentIdContains(
      String value,
      {bool caseSensitive = true}) {
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

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition> rootParentIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
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

  QueryBuilder<ModelBox, ModelBox, QAfterFilterCondition>
      rootParentIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 4,
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
          property: 4,
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
      return query.object(q, 3);
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

  QueryBuilder<ModelBox, ModelBox, QAfterSortBy> sortByModelData(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        2,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterSortBy> sortByModelDataDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        2,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterSortBy> sortByRootParentId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        4,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterSortBy> sortByRootParentIdDesc(
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

  QueryBuilder<ModelBox, ModelBox, QAfterSortBy> thenByModelData(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterSortBy> thenByModelDataDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterSortBy> thenByRootParentId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterSortBy> thenByRootParentIdDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, sort: Sort.desc, caseSensitive: caseSensitive);
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

  QueryBuilder<ModelBox, ModelBox, QAfterDistinct> distinctByModelData(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ModelBox, ModelBox, QAfterDistinct> distinctByRootParentId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(4, caseSensitive: caseSensitive);
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

  QueryBuilder<ModelBox, String?, QAfterProperty> modelDataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<ModelBox, ModelContainer?, QAfterProperty> modelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<ModelBox, String?, QAfterProperty> rootParentIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
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

  QueryBuilder<ModelBox, (R, String?), QAfterProperty> modelDataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<ModelBox, (R, ModelContainer?), QAfterProperty> modelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<ModelBox, (R, String?), QAfterProperty> rootParentIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
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

  QueryBuilder<ModelBox, (R1, R2, String?), QOperations> modelDataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<ModelBox, (R1, R2, ModelContainer?), QOperations>
      modelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<ModelBox, (R1, R2, String?), QOperations>
      rootParentIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
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
