import 'package:local_storage/hive/hive_storage.dart';
import '../models/task.dart';
import '../models/user.dart';

import 'package:remote_storage/remote_storage.dart';


class ClosePerson {}
class Domain {}


// Operates (soon) with 3 types of storages (databases):
//    - Local storage - stores data on this device (exlude web).
//    - Remote storage - stores data remotely in back-end database (now it is 3d party).
//    - Peer to peer storage - stores data locally on this device, but periodically updates it from closers devices.
//          Uses remote beacons to get link to closers devices.
//          All data transmitted directly between user devices in encrypted form.
//          Merge conflicts solves according user chousen merge politic.
class Repository {
  Repository();

  late final HiveStorage _localStorage;
  late final FirebaseStorage _remoteStorage;

  Future<void> init() async {
    _localStorage = HiveStorage();
    _remoteStorage = FirebaseStorage();
    await _localStorage.init();
    await _remoteStorage.init();
  }

  // # Settings

  // ## Operational settings - always local
  // Contains such data as credentials, active auth tokens...
  // создать нового пользователя, получить его токен или креды, сохранить токен, креды или авторизацию
  Future<void> setLocalUser(User user) async {await _localStorage.setUser(user);}
  Future<User?> getLocalUser() async {return await _localStorage.getUser();}
  Future<void> removeLocalUser() async {throw UnimplementedError('repository removeLocalUser');}
  Future<void> flushLocalStorage() async {throw UnimplementedError('repository flushLocalStorage');}
  Future<void> setRemoteAuth(auth) async {}
  Future<void> setRemoteUser(User user) async {_remoteStorage.setUser(user);}
  Future<User?> getRemoteUser() async {return await _remoteStorage.getUser();}
  Future<void> removeRemoteUser(User user) async {throw UnimplementedError('repository removeRemoteUser');}


  // ## User settings
  // Contains such data as theme, default type of repo to store user data (local or remote).
  // Can be stored as locally as remotely
  Future<void> saveUserSettings() async {}

  // ## User data - local/remote

  // Close people (known users)
  Future<Map<String, ClosePerson>> getClosers() async {throw UnimplementedError('repository getClosers');}
  Future<void> addClosePerson(ClosePerson closePerson) async {throw UnimplementedError('repository addClosePerson');}
  Future<void> removeClosePerson(ClosePerson closePerson) async {throw UnimplementedError('repository removeClosePerson');}

  // ### Tasks
  // добавить новую задачу, обновить имеющуюся задачу, удалить задачу
  // переместить задачу в другое хранилище 
  Future<Map<String, Task>> getTasks() async => await _localStorage.getTasks();
  Future<void> addTask(Task task) async {
    await _localStorage.save(item: task);
    await _remoteStorage.save(item: task);
  }
  Future<void> removeTask(Task task) async {throw UnimplementedError('repository removeTask');}

  // ### Domains
  // войти в домен, выйти из домена, создать домен, пригласить в домен, удалить из домена, удалить домен...
  // перенести домен в другое хранилище
  Future<Map<String, Domain>> getDomains() async {throw UnimplementedError('repository getDomains');}
  Future<void> addDomain(ClosePerson closePerson) async {throw UnimplementedError('repository addDomain');}
  Future<void> removeDomain(ClosePerson closePerson) async {throw UnimplementedError('repository removeDomain');}

  // ### Projects
  // ### Periods
  // ### Events
}