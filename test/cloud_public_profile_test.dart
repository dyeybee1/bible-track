// SDK stand-ins are limited to tests and never subclass production behavior.
// ignore_for_file: subtype_of_sealed_class

import 'package:bible_track/data/books_data.dart';
import 'package:bible_track/data/cloud_repository.dart';
import 'package:bible_track/data/sync_merge.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

// Small Firestore stand-ins exercise the real repository's transaction and
// server-read behavior without Firebase credentials or a network connection.
class _Database implements FirebaseFirestore {
  final docs = <String, Map<String, dynamic>>{};
  final writes = <String>[];
  Source? readSource;
  Object? readError;

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) =>
      _Collection(this, collectionPath);
  @override
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction) handler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) => handler(_Transaction(this));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Collection implements CollectionReference<Map<String, dynamic>> {
  _Collection(this.db, this.collectionPath);
  final _Database db;
  final String collectionPath;
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _Document(db, '$collectionPath/$path');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Document implements DocumentReference<Map<String, dynamic>> {
  _Document(this.db, this.path);
  final _Database db;
  @override
  final String path;
  @override
  String get id => path.split('/').last;
  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async {
    db.readSource = options?.source;
    if (db.readError case final error?) throw error;
    return _Snapshot(id, db.docs[path]);
  }

  @override
  Future<void> delete() async {
    db.docs.remove(path);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Snapshot<T extends Object?> implements DocumentSnapshot<T> {
  _Snapshot(this.id, this.value);
  @override
  final String id;
  final T? value;
  @override
  T? data() => value;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Transaction implements Transaction {
  _Transaction(this.db);
  final _Database db;
  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(
    DocumentReference<T> ref,
  ) async => _Snapshot(ref.id, db.docs[ref.path] as T?);
  @override
  Transaction set<T>(DocumentReference<T> ref, T data, [SetOptions? options]) {
    db.writes.add(ref.path);
    db.docs[ref.path] = {
      if (options?.merge == true || options?.mergeFields != null)
        ...?db.docs[ref.path],
      ...data as Map<String, dynamic>,
    };
    return this;
  }

  @override
  Transaction delete(DocumentReference ref) {
    db.writes.add(ref.path);
    db.docs.remove(ref.path);
    return this;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'sync atomically publishes merged public reading fields only when opted in',
    () async {
      final db = _Database();
      final cloud = CloudRepository(db: db);
      db.docs['users/u'] = const SyncState(
        cycle: 1,
        books: {},
        username: 'Remote',
        usernameAt: 2,
        maxStarsEver: 5000,
      ).toMap();
      // Replacing the public doc must remove any unexpected existing fields.
      db.docs['publicProfiles/u'] = {'email': 'private@example.test'};
      final merged = await cloud.sync(
        'u',
        SyncState(
          cycle: 0,
          books: {
            'rut': BookRecord({1, 2, 3, 4}, 1),
          },
          completedEver: {'rut'},
          username: 'Local',
          usernameAt: 1,
        ),
        showOnLeaderboard: true,
      );
      expect(db.writes, ['users/u', 'publicProfiles/u']);
      final public = db.docs['publicProfiles/u']!;
      expect(public, {
        'username': 'Remote',
        'chaptersRead': totalChaptersInBible,
        'maxStars': 5000,
        'timesCompleted': 1,
        'chaptersCycle': 0,
        'completedBooks': 0,
        'completedBookIds': ['rut'],
        'updatedAt': isA<FieldValue>(),
      });
      expect(db.docs['users/u']!['maxStarsEver'], merged.maxStarsEver);
    },
  );

  test(
    'opt-out sync deletes public profile and retains private progress',
    () async {
      final db = _Database();
      db.docs['publicProfiles/u'] = {'username': 'Reader'};
      final cloud = CloudRepository(db: db);
      await cloud.sync(
        'u',
        const SyncState(cycle: 0, books: {}, username: 'Reader'),
        showOnLeaderboard: false,
      );
      expect(db.docs.containsKey('publicProfiles/u'), isFalse);
      expect(db.docs['users/u']!['username'], 'Reader');
    },
  );

  test(
    'public profile uses a server read and an authoritative document ID',
    () async {
      final db = _Database();
      final cloud = CloudRepository(db: db);
      expect(await cloud.fetchPublicProfile('u'), isNull);
      expect(db.readSource, Source.server);
      db.docs['publicProfiles/u'] = {
        'uid': 'spoofed',
        'username': 'Reader',
        'chaptersRead': 20,
        'maxStars': 30,
        'timesCompleted': 0,
        'chaptersCycle': 20,
        'completedBooks': 1,
        'updatedAt': Timestamp.now(),
      };
      final profile = await cloud.fetchPublicProfile('u');
      expect(profile!.uid, 'u');
      expect(profile.username, 'Reader');
      expect(profile.updatedAt, isNotNull);
      db.readError = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
      );
      await expectLater(
        cloud.fetchPublicProfile('u'),
        throwsA(isA<FirebaseException>()),
      );
    },
  );
}
