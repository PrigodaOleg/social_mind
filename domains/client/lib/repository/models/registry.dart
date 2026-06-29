part of 'models.dart';


// Что вообще такое реестр?
// Это список изменений, которые были сделаны над моделями.
// Он нужен для разрешения конфликтов при синхронизации, историю по нему восстановить нельзя.
// Реестр глобален, то есть хранится одновременно во всех хранилищах.
// Истинной считается локальная копия реестра, пока не будет доказано обратное.
// Как можно доказать обратное?
// Для одного удаленного хранилища это отказ в записи в базу данных.
// Если удаленных хранилищ несколько, то нужна процедура разрешения конфликтов.
// Для распределенного хранилища результат процедуры арбитража.
// Если доказано, что локальный реестр содержит неактуальную запись, то нужна процедура мержа/ребейса изменений на актуальную голову.
// Реестр состоит из транзакций.
// В базе данных реестры отделены от моделей.
// На каждое изменение в модели есть запись в транзакции.
// Транзакция - это изменение как минимум одной модели. Одна транзакция может описывать изменение нескольких моделей.
// Транзакция имеет идентификатор и хэш предыдущей транзакции.
// Хэширование происходит по содержимому транзакции.
// Транзакция может быть отклонена, если она не соответствует правилам.
// Транзакция может быть принята, если она соответствует правилам.
// В базу данных записывается консистентный набор изменений + транзакция. Изменений должно быть ровно столько, сколько записей в транзакции.
// Если есть лишние, то транзакция будет отклонена, если каких-то изменений не достает, то транзакция будет отклонена.
// Предоставить годную транзакцию - дело клиента пользователя.


@HiveType(typeId: 7)
class Transaction {
  Transaction(
    String? id,
    this.prevHash,
    this.prevId,
    this.timeStamp,
    this.originatorId,
    this.changeDetails,
    this.changeType,
    this.changes,
    this.path
  ) :
  id = id ?? const Uuid().v4();

  @HiveField(0)
  String id; // Идентификатор этого изменения
  @HiveField(1)
  String prevId; // Идентификатор предыдущего изменения
  @HiveField(2)
  int prevHash; // Хэш предыдущего изменения, возможно будем использовать его в арбитраже транзакций в распределенном хранилище
  @HiveField(3)
  DateTime timeStamp;
  @HiveField(4)
  String originatorId;
  @HiveField(5)
  String changeDetails; // Адрес изменения на уровне экосистемы (человек-сессия-программа-устройство), пока не понятно зачем
  @HiveField(6)
  String changeType; // Тип изменения - создание, изменение, удаление
  @HiveField(7)
  List<String> changes; // Инеднификаторы изменившихся моделей, может тут нужна MAP с сериализованными изменениями в значениях полей
  @HiveField(8)
  String path; // адрес в дереве моделей (домен-...), или цепочка вложенности/наследования

  Map<String, Object> toJson() => {
    'id': id,
    'prevHash': prevHash,
    'prevId': prevId,
    'timeStamp': timeStamp.toIso8601String(),
    'originatorId': originatorId,
    'changeDetails': changeDetails,
    'changeType': changeType,
    'changes': changes,
    'path': path,
  };

  Transaction.fromJson(Map<String, dynamic> json):
    id = json['id'] as String,
    prevHash = json['prevHash'] as int,
    prevId = json['prevId'] as String,
    timeStamp = DateTime.parse(json['timeStamp'] as String),
    originatorId = json['originatorId'] as String,
    changeDetails = json['changeDetails'] as String,
    changeType = json['changeType'] as String,
    changes = json['changes'] as List<String>,
    path = json['path'] as String;
}

@HiveType(typeId: 8)
class RegistryMetadata {
  RegistryMetadata({
    required this.id,
    required this.parentId
  });

  /// The unique identifier of the model.
  ///
  /// Cannot be empty.
  @HiveField(0)
  final String id;

  /// The identifier of container model (domain or user).
  ///
  /// Cannot be empty.
  @HiveField(1)
  final String parentId;

  Map<String, Object> toJson() => {
    'id': id,
    'parentId': parentId,
  };

  RegistryMetadata.fromJson(Map<String, dynamic> json):
    id = json['id'] as String,
    parentId = json['parentId'] as String;
}

@HiveType(typeId: 6)
// ignore: must_be_immutable
class Registry extends Equatable {
  Registry({
    String? id,
    String? parentId,
    Map<int, Transaction>? transactions
  }) : 
  assert(id == null || id.isNotEmpty, 'id must be null or not empty'),
  metadata = RegistryMetadata(
    id: id ?? const Uuid().v4(),
    parentId: parentId ?? ''
  ),
  transactions = transactions ?? {};

  Registry.fromMaps({
    required Map<String, dynamic> metadata,
    required Map<int, Map<String, dynamic>> transactions
  }) :
  metadata = RegistryMetadata.fromJson(metadata),
  transactions = transactions.map((key, value) => MapEntry(key, Transaction.fromJson(value)));

  /// Registry metadata.
  /// Cannot be null.
  /// Храним тут любые аттрибуты, связанные с реестром, например, его тип, имя, описание и т.п.
  @HiveField(0)
  RegistryMetadata metadata;

  /// Transactions list.
  /// Can be empty.
  /// К сожалению, в firebase нельзя хранить списки, а можно только словари. Это означает, что последовательность
  /// записанных элементов не созраняеися при последующем чтении. Это значит, что мы должны будем сортировать
  /// словарь по ключам, чтобы получить исходный порядок элементов. Ключи при этом должны инкрементироваться 
  /// при каждой новой транзакции. За этим мы будем следить с помощью правил доступа в firebase.
  /// При чтении можно запросить несколько последних элементов а не весь список.
  /// В качестве ключей будем использовать целые числа. Максимальное возможное целое число - 2^53.
  /// Это, вроде как, много, поэтому проблему переполнения можем проигнорировать, по крайней мере, на время.
  /// В hive нельзя читать ни списки ни словари частично из коробки. Но можно дописать свои методы
  /// для чтения/записи нескольких элементов с конца. Таким образом можно содержать/накапливать в базе полный 
  /// словарь никогда полностью не читаю его в память. Этот подход дает также возможность выгружать часть словаря в архив.
  @HiveField(1)
  Map<int, Transaction> transactions;

  Map<String, Object> toJson() => {
    'metadata': metadata.toJson(),
    'transactions': transactions.map((key, value) => MapEntry(key.toString(), value.toJson())),
  };

  Registry.fromJson(Map<String, dynamic> json):
    metadata = RegistryMetadata.fromJson(json['metadata']),
    transactions = (json['transactions'] as Map).map((key, value) => MapEntry(int.parse(key), Transaction.fromJson(value)));

  @override
  List<Object> get props => [metadata, transactions];
}