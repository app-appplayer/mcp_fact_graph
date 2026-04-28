import 'package:test/test.dart';
import 'package:mcp_fact_graph/mcp_fact_graph.dart';

void main() {
  // =========================================================================
  // FactClusterStatus enum tests
  // =========================================================================
  group('FactClusterStatus', () {
    test('has all expected values', () {
      expect(FactClusterStatus.values, contains(FactClusterStatus.active));
      expect(FactClusterStatus.values, contains(FactClusterStatus.merged));
      expect(FactClusterStatus.values, contains(FactClusterStatus.archived));
      expect(FactClusterStatus.values.length, equals(3));
    });

    test('fromString valid values', () {
      expect(FactClusterStatus.fromString('active'),
          equals(FactClusterStatus.active));
      expect(FactClusterStatus.fromString('merged'),
          equals(FactClusterStatus.merged));
      expect(FactClusterStatus.fromString('archived'),
          equals(FactClusterStatus.archived));
    });

    test('fromString is case-insensitive', () {
      expect(FactClusterStatus.fromString('ACTIVE'),
          equals(FactClusterStatus.active));
      expect(FactClusterStatus.fromString('Merged'),
          equals(FactClusterStatus.merged));
      expect(FactClusterStatus.fromString('ARCHIVED'),
          equals(FactClusterStatus.archived));
    });

    test('fromString invalid returns default (active)', () {
      expect(FactClusterStatus.fromString('unknown'),
          equals(FactClusterStatus.active));
      expect(
          FactClusterStatus.fromString(''), equals(FactClusterStatus.active));
      expect(FactClusterStatus.fromString('invalid'),
          equals(FactClusterStatus.active));
    });
  });

  // =========================================================================
  // FactClusterAuditEntry tests
  // =========================================================================
  group('FactClusterAuditEntry', () {
    final timestamp = DateTime(2024, 6, 15, 10);

    test('constructor with required fields only', () {
      final entry = FactClusterAuditEntry(
        timestamp: timestamp,
        action: 'create',
      );

      expect(entry.timestamp, equals(timestamp));
      expect(entry.action, equals('create'));
      expect(entry.factId, isNull);
      expect(entry.reason, isNull);
      expect(entry.actor, isNull);
    });

    test('constructor with all fields', () {
      final entry = FactClusterAuditEntry(
        timestamp: timestamp,
        action: 'add_member',
        factId: 'fact-1',
        reason: 'Similar content',
        actor: 'system',
      );

      expect(entry.timestamp, equals(timestamp));
      expect(entry.action, equals('add_member'));
      expect(entry.factId, equals('fact-1'));
      expect(entry.reason, equals('Similar content'));
      expect(entry.actor, equals('system'));
    });

    test('fromJson complete', () {
      final json = {
        'timestamp': '2024-06-15T10:00:00.000',
        'action': 'remove_member',
        'factId': 'fact-2',
        'reason': 'Incorrect match',
        'actor': 'user',
      };

      final entry = FactClusterAuditEntry.fromJson(json);

      expect(entry.timestamp, equals(DateTime(2024, 6, 15, 10)));
      expect(entry.action, equals('remove_member'));
      expect(entry.factId, equals('fact-2'));
      expect(entry.reason, equals('Incorrect match'));
      expect(entry.actor, equals('user'));
    });

    test('fromJson with minimal fields', () {
      final json = {
        'timestamp': '2024-06-15T10:00:00.000',
      };

      final entry = FactClusterAuditEntry.fromJson(json);

      expect(entry.timestamp, equals(DateTime(2024, 6, 15, 10)));
      expect(entry.action, equals(''));
      expect(entry.factId, isNull);
      expect(entry.reason, isNull);
      expect(entry.actor, isNull);
    });

    test('toJson populated', () {
      final entry = FactClusterAuditEntry(
        timestamp: timestamp,
        action: 'set_primary',
        factId: 'fact-3',
        reason: 'Higher quality',
        actor: 'llm',
      );

      final json = entry.toJson();

      expect(json['timestamp'], equals(timestamp.toIso8601String()));
      expect(json['action'], equals('set_primary'));
      expect(json['factId'], equals('fact-3'));
      expect(json['reason'], equals('Higher quality'));
      expect(json['actor'], equals('llm'));
    });

    test('toJson excludes null fields', () {
      final entry = FactClusterAuditEntry(
        timestamp: timestamp,
        action: 'create',
      );

      final json = entry.toJson();

      expect(json.containsKey('timestamp'), isTrue);
      expect(json.containsKey('action'), isTrue);
      expect(json.containsKey('factId'), isFalse);
      expect(json.containsKey('reason'), isFalse);
      expect(json.containsKey('actor'), isFalse);
    });

    test('copyWith modifies selected fields', () {
      final original = FactClusterAuditEntry(
        timestamp: timestamp,
        action: 'create',
        factId: 'fact-1',
      );

      final copy = original.copyWith(
        action: 'add_member',
        reason: 'New reason',
      );

      expect(copy.timestamp, equals(timestamp));
      expect(copy.action, equals('add_member'));
      expect(copy.factId, equals('fact-1'));
      expect(copy.reason, equals('New reason'));
      expect(copy.actor, isNull);
    });

    test('copyWith with no arguments returns equivalent object', () {
      final original = FactClusterAuditEntry(
        timestamp: timestamp,
        action: 'create',
      );

      final copy = original.copyWith();

      expect(copy.timestamp, equals(original.timestamp));
      expect(copy.action, equals(original.action));
      expect(copy.factId, equals(original.factId));
      expect(copy.reason, equals(original.reason));
      expect(copy.actor, equals(original.actor));
    });

    test('copyWith replaces all fields', () {
      final original = FactClusterAuditEntry(
        timestamp: timestamp,
        action: 'create',
      );

      final newTimestamp = DateTime(2025, 1, 1);
      final copy = original.copyWith(
        timestamp: newTimestamp,
        action: 'merge',
        factId: 'fact-new',
        reason: 'Merged',
        actor: 'admin',
      );

      expect(copy.timestamp, equals(newTimestamp));
      expect(copy.action, equals('merge'));
      expect(copy.factId, equals('fact-new'));
      expect(copy.reason, equals('Merged'));
      expect(copy.actor, equals('admin'));
    });
  });

  // =========================================================================
  // FactCluster tests
  // =========================================================================
  group('FactCluster', () {
    final now = DateTime(2024, 6, 15, 10);

    test('constructor with required fields only', () {
      final cluster = FactCluster(
        factClusterId: 'fc-1',
        factType: 'expense',
        primaryFactId: 'fact-1',
        memberFactIds: ['fact-1'],
        createdAt: now,
        updatedAt: now,
      );

      expect(cluster.factClusterId, equals('fc-1'));
      expect(cluster.factType, equals('expense'));
      expect(cluster.primaryFactId, equals('fact-1'));
      expect(cluster.memberFactIds, equals(['fact-1']));
      expect(cluster.mergedPayload, isEmpty);
      expect(cluster.status, equals(FactClusterStatus.active));
      expect(cluster.confidence, equals(1.0));
      expect(cluster.mergedInto, isNull);
      expect(cluster.auditTrail, isEmpty);
      expect(cluster.createdAt, equals(now));
      expect(cluster.updatedAt, equals(now));
    });

    test('constructor with all fields', () {
      final auditEntry = FactClusterAuditEntry(
        timestamp: now,
        action: 'create',
        actor: 'system',
      );
      final cluster = FactCluster(
        factClusterId: 'fc-2',
        factType: 'transaction',
        primaryFactId: 'fact-2',
        memberFactIds: ['fact-2', 'fact-3'],
        mergedPayload: {'amount': 100},
        status: FactClusterStatus.merged,
        confidence: 0.85,
        mergedInto: 'fc-1',
        auditTrail: [auditEntry],
        createdAt: now,
        updatedAt: now,
      );

      expect(cluster.factClusterId, equals('fc-2'));
      expect(cluster.factType, equals('transaction'));
      expect(cluster.primaryFactId, equals('fact-2'));
      expect(cluster.memberFactIds, equals(['fact-2', 'fact-3']));
      expect(cluster.mergedPayload, equals({'amount': 100}));
      expect(cluster.status, equals(FactClusterStatus.merged));
      expect(cluster.confidence, equals(0.85));
      expect(cluster.mergedInto, equals('fc-1'));
      expect(cluster.auditTrail, hasLength(1));
      expect(cluster.auditTrail.first.action, equals('create'));
    });

    test('fromJson complete', () {
      final json = {
        'factClusterId': 'fc-1',
        'factType': 'expense',
        'primaryFactId': 'fact-1',
        'memberFactIds': ['fact-1', 'fact-2'],
        'mergedPayload': {'total': 250},
        'status': 'merged',
        'confidence': 0.9,
        'mergedInto': 'fc-0',
        'auditTrail': [
          {
            'timestamp': '2024-06-15T10:00:00.000',
            'action': 'create',
            'actor': 'system',
          },
        ],
        'createdAt': '2024-06-15T10:00:00.000',
        'updatedAt': '2024-06-16T10:00:00.000',
      };

      final cluster = FactCluster.fromJson(json);

      expect(cluster.factClusterId, equals('fc-1'));
      expect(cluster.factType, equals('expense'));
      expect(cluster.primaryFactId, equals('fact-1'));
      expect(cluster.memberFactIds, equals(['fact-1', 'fact-2']));
      expect(cluster.mergedPayload, equals({'total': 250}));
      expect(cluster.status, equals(FactClusterStatus.merged));
      expect(cluster.confidence, equals(0.9));
      expect(cluster.mergedInto, equals('fc-0'));
      expect(cluster.auditTrail, hasLength(1));
      expect(cluster.auditTrail.first.action, equals('create'));
      expect(cluster.createdAt, equals(DateTime(2024, 6, 15, 10)));
      expect(cluster.updatedAt, equals(DateTime(2024, 6, 16, 10)));
    });

    test('fromJson empty/missing fields', () {
      final cluster = FactCluster.fromJson(<String, dynamic>{});

      expect(cluster.factClusterId, equals(''));
      expect(cluster.factType, equals(''));
      expect(cluster.primaryFactId, equals(''));
      expect(cluster.memberFactIds, isEmpty);
      expect(cluster.mergedPayload, isEmpty);
      expect(cluster.status, equals(FactClusterStatus.active));
      expect(cluster.confidence, equals(1.0));
      expect(cluster.mergedInto, isNull);
      expect(cluster.auditTrail, isEmpty);
      expect(cluster.createdAt, isA<DateTime>());
      expect(cluster.updatedAt, isA<DateTime>());
    });

    test('fromJson with null datetime fields', () {
      final cluster = FactCluster.fromJson({
        'createdAt': null,
        'updatedAt': null,
      });
      expect(cluster.createdAt, isA<DateTime>());
      expect(cluster.updatedAt, isA<DateTime>());
    });

    test('toJson populated', () {
      final auditEntry = FactClusterAuditEntry(
        timestamp: now,
        action: 'create',
        actor: 'system',
      );
      final cluster = FactCluster(
        factClusterId: 'fc-1',
        factType: 'expense',
        primaryFactId: 'fact-1',
        memberFactIds: ['fact-1'],
        mergedPayload: {'amount': 100},
        status: FactClusterStatus.active,
        confidence: 0.95,
        mergedInto: 'fc-old',
        auditTrail: [auditEntry],
        createdAt: now,
        updatedAt: now,
      );

      final json = cluster.toJson();

      expect(json['factClusterId'], equals('fc-1'));
      expect(json['factType'], equals('expense'));
      expect(json['primaryFactId'], equals('fact-1'));
      expect(json['memberFactIds'], equals(['fact-1']));
      expect(json['mergedPayload'], equals({'amount': 100}));
      expect(json['status'], equals('active'));
      expect(json['confidence'], equals(0.95));
      expect(json['mergedInto'], equals('fc-old'));
      expect(json['auditTrail'], isA<List>());
      expect((json['auditTrail'] as List).length, equals(1));
      expect(json['createdAt'], equals(now.toIso8601String()));
      expect(json['updatedAt'], equals(now.toIso8601String()));
    });

    test('toJson excludes empty and null fields', () {
      final cluster = FactCluster(
        factClusterId: 'fc-1',
        factType: 'expense',
        primaryFactId: 'fact-1',
        memberFactIds: ['fact-1'],
        createdAt: now,
        updatedAt: now,
      );

      final json = cluster.toJson();

      expect(json.containsKey('mergedPayload'), isFalse);
      expect(json.containsKey('mergedInto'), isFalse);
      expect(json.containsKey('auditTrail'), isFalse);
      // Always-present fields
      expect(json.containsKey('factClusterId'), isTrue);
      expect(json.containsKey('factType'), isTrue);
      expect(json.containsKey('primaryFactId'), isTrue);
      expect(json.containsKey('memberFactIds'), isTrue);
      expect(json.containsKey('status'), isTrue);
      expect(json.containsKey('confidence'), isTrue);
      expect(json.containsKey('createdAt'), isTrue);
      expect(json.containsKey('updatedAt'), isTrue);
    });

    test('copyWith modifies selected fields', () {
      final original = FactCluster(
        factClusterId: 'fc-1',
        factType: 'expense',
        primaryFactId: 'fact-1',
        memberFactIds: ['fact-1'],
        createdAt: now,
        updatedAt: now,
      );

      final copy = original.copyWith(
        status: FactClusterStatus.archived,
        confidence: 0.5,
      );

      expect(copy.factClusterId, equals('fc-1'));
      expect(copy.factType, equals('expense'));
      expect(copy.status, equals(FactClusterStatus.archived));
      expect(copy.confidence, equals(0.5));
      expect(copy.primaryFactId, equals('fact-1'));
    });

    test('copyWith with no arguments returns equivalent object', () {
      final original = FactCluster(
        factClusterId: 'fc-1',
        factType: 'expense',
        primaryFactId: 'fact-1',
        memberFactIds: ['fact-1'],
        createdAt: now,
        updatedAt: now,
      );

      final copy = original.copyWith();

      expect(copy.factClusterId, equals(original.factClusterId));
      expect(copy.factType, equals(original.factType));
      expect(copy.primaryFactId, equals(original.primaryFactId));
      expect(copy.memberFactIds, equals(original.memberFactIds));
      expect(copy.mergedPayload, equals(original.mergedPayload));
      expect(copy.status, equals(original.status));
      expect(copy.confidence, equals(original.confidence));
      expect(copy.mergedInto, equals(original.mergedInto));
      expect(copy.auditTrail, equals(original.auditTrail));
      expect(copy.createdAt, equals(original.createdAt));
      expect(copy.updatedAt, equals(original.updatedAt));
    });

    test('copyWith replaces all fields', () {
      final original = FactCluster(
        factClusterId: 'fc-1',
        factType: 'expense',
        primaryFactId: 'fact-1',
        memberFactIds: ['fact-1'],
        createdAt: now,
        updatedAt: now,
      );

      final newDate = DateTime(2025, 1, 1);
      final newAudit = FactClusterAuditEntry(
        timestamp: newDate,
        action: 'merge',
      );
      final copy = original.copyWith(
        factClusterId: 'fc-new',
        factType: 'meeting',
        primaryFactId: 'fact-new',
        memberFactIds: ['fact-new', 'fact-new2'],
        mergedPayload: {'new': true},
        status: FactClusterStatus.merged,
        confidence: 0.1,
        mergedInto: 'fc-target',
        auditTrail: [newAudit],
        createdAt: newDate,
        updatedAt: newDate,
      );

      expect(copy.factClusterId, equals('fc-new'));
      expect(copy.factType, equals('meeting'));
      expect(copy.primaryFactId, equals('fact-new'));
      expect(copy.memberFactIds, equals(['fact-new', 'fact-new2']));
      expect(copy.mergedPayload, equals({'new': true}));
      expect(copy.status, equals(FactClusterStatus.merged));
      expect(copy.confidence, equals(0.1));
      expect(copy.mergedInto, equals('fc-target'));
      expect(copy.auditTrail, hasLength(1));
      expect(copy.createdAt, equals(newDate));
      expect(copy.updatedAt, equals(newDate));
    });

    // -----------------------------------------------------------------------
    // Boolean getters
    // -----------------------------------------------------------------------
    test('isActive returns true when status is active', () {
      final cluster = FactCluster(
        factClusterId: 'fc-1',
        factType: 'expense',
        primaryFactId: 'fact-1',
        memberFactIds: ['fact-1'],
        status: FactClusterStatus.active,
        createdAt: now,
        updatedAt: now,
      );
      expect(cluster.isActive, isTrue);
    });

    test('isActive returns false when status is not active', () {
      final cluster = FactCluster(
        factClusterId: 'fc-1',
        factType: 'expense',
        primaryFactId: 'fact-1',
        memberFactIds: ['fact-1'],
        status: FactClusterStatus.merged,
        createdAt: now,
        updatedAt: now,
      );
      expect(cluster.isActive, isFalse);
    });

    test('hasMultipleMembers returns true with more than 1 member', () {
      final cluster = FactCluster(
        factClusterId: 'fc-1',
        factType: 'expense',
        primaryFactId: 'fact-1',
        memberFactIds: ['fact-1', 'fact-2'],
        createdAt: now,
        updatedAt: now,
      );
      expect(cluster.hasMultipleMembers, isTrue);
    });

    test('hasMultipleMembers returns false with 1 member', () {
      final cluster = FactCluster(
        factClusterId: 'fc-1',
        factType: 'expense',
        primaryFactId: 'fact-1',
        memberFactIds: ['fact-1'],
        createdAt: now,
        updatedAt: now,
      );
      expect(cluster.hasMultipleMembers, isFalse);
    });

    test('hasMultipleMembers returns false with empty members', () {
      final cluster = FactCluster(
        factClusterId: 'fc-1',
        factType: 'expense',
        primaryFactId: 'fact-1',
        memberFactIds: [],
        createdAt: now,
        updatedAt: now,
      );
      expect(cluster.hasMultipleMembers, isFalse);
    });

    // -----------------------------------------------------------------------
    // Methods
    // -----------------------------------------------------------------------
    group('addMember', () {
      test('adds a new member and audit entry', () {
        final cluster = FactCluster(
          factClusterId: 'fc-1',
          factType: 'expense',
          primaryFactId: 'fact-1',
          memberFactIds: ['fact-1'],
          createdAt: now,
          updatedAt: now,
        );

        final updated =
            cluster.addMember('fact-2', reason: 'Similar', actor: 'system');

        expect(updated.memberFactIds, contains('fact-2'));
        expect(updated.memberFactIds, hasLength(2));
        expect(updated.auditTrail, hasLength(1));
        expect(updated.auditTrail.last.action, equals('add_member'));
        expect(updated.auditTrail.last.factId, equals('fact-2'));
        expect(updated.auditTrail.last.reason, equals('Similar'));
        expect(updated.auditTrail.last.actor, equals('system'));
      });

      test('returns same cluster if member already exists', () {
        final cluster = FactCluster(
          factClusterId: 'fc-1',
          factType: 'expense',
          primaryFactId: 'fact-1',
          memberFactIds: ['fact-1', 'fact-2'],
          createdAt: now,
          updatedAt: now,
        );

        final result = cluster.addMember('fact-2');

        // Should return the same instance (no change)
        expect(identical(result, cluster), isTrue);
        expect(result.memberFactIds, hasLength(2));
        expect(result.auditTrail, isEmpty);
      });

      test('adds member without optional parameters', () {
        final cluster = FactCluster(
          factClusterId: 'fc-1',
          factType: 'expense',
          primaryFactId: 'fact-1',
          memberFactIds: ['fact-1'],
          createdAt: now,
          updatedAt: now,
        );

        final updated = cluster.addMember('fact-3');

        expect(updated.memberFactIds, contains('fact-3'));
        expect(updated.auditTrail.last.reason, isNull);
        expect(updated.auditTrail.last.actor, isNull);
      });
    });

    group('removeMember', () {
      test('removes a member and adds audit entry', () {
        final cluster = FactCluster(
          factClusterId: 'fc-1',
          factType: 'expense',
          primaryFactId: 'fact-1',
          memberFactIds: ['fact-1', 'fact-2', 'fact-3'],
          createdAt: now,
          updatedAt: now,
        );

        final updated =
            cluster.removeMember('fact-2', reason: 'Error', actor: 'user');

        expect(updated.memberFactIds, isNot(contains('fact-2')));
        expect(updated.memberFactIds, hasLength(2));
        expect(updated.auditTrail, hasLength(1));
        expect(updated.auditTrail.last.action, equals('remove_member'));
        expect(updated.auditTrail.last.factId, equals('fact-2'));
        expect(updated.auditTrail.last.reason, equals('Error'));
        expect(updated.auditTrail.last.actor, equals('user'));
        // Primary should remain unchanged since it was not removed
        expect(updated.primaryFactId, equals('fact-1'));
      });

      test('returns same cluster if member does not exist', () {
        final cluster = FactCluster(
          factClusterId: 'fc-1',
          factType: 'expense',
          primaryFactId: 'fact-1',
          memberFactIds: ['fact-1'],
          createdAt: now,
          updatedAt: now,
        );

        final result = cluster.removeMember('non-existent');

        expect(identical(result, cluster), isTrue);
        expect(result.memberFactIds, hasLength(1));
      });

      test('updates primary when primary is removed and others remain', () {
        final cluster = FactCluster(
          factClusterId: 'fc-1',
          factType: 'expense',
          primaryFactId: 'fact-1',
          memberFactIds: ['fact-1', 'fact-2'],
          createdAt: now,
          updatedAt: now,
        );

        final updated = cluster.removeMember('fact-1');

        expect(updated.memberFactIds, equals(['fact-2']));
        expect(updated.primaryFactId, equals('fact-2'));
      });

      test('keeps primary when removed fact is the only member', () {
        final cluster = FactCluster(
          factClusterId: 'fc-1',
          factType: 'expense',
          primaryFactId: 'fact-1',
          memberFactIds: ['fact-1'],
          createdAt: now,
          updatedAt: now,
        );

        final updated = cluster.removeMember('fact-1');

        expect(updated.memberFactIds, isEmpty);
        // When no members remain, primaryFactId stays the same
        expect(updated.primaryFactId, equals('fact-1'));
      });

      test('removes member without optional parameters', () {
        final cluster = FactCluster(
          factClusterId: 'fc-1',
          factType: 'expense',
          primaryFactId: 'fact-1',
          memberFactIds: ['fact-1', 'fact-2'],
          createdAt: now,
          updatedAt: now,
        );

        final updated = cluster.removeMember('fact-2');

        expect(updated.auditTrail.last.reason, isNull);
        expect(updated.auditTrail.last.actor, isNull);
      });
    });

    group('setPrimary', () {
      test('sets a new primary fact and adds audit entry', () {
        final cluster = FactCluster(
          factClusterId: 'fc-1',
          factType: 'expense',
          primaryFactId: 'fact-1',
          memberFactIds: ['fact-1', 'fact-2'],
          createdAt: now,
          updatedAt: now,
        );

        final updated =
            cluster.setPrimary('fact-2', reason: 'Better', actor: 'user');

        expect(updated.primaryFactId, equals('fact-2'));
        expect(updated.auditTrail, hasLength(1));
        expect(updated.auditTrail.last.action, equals('set_primary'));
        expect(updated.auditTrail.last.factId, equals('fact-2'));
        expect(updated.auditTrail.last.reason, equals('Better'));
        expect(updated.auditTrail.last.actor, equals('user'));
      });

      test('throws ArgumentError when fact is not a member', () {
        final cluster = FactCluster(
          factClusterId: 'fc-1',
          factType: 'expense',
          primaryFactId: 'fact-1',
          memberFactIds: ['fact-1'],
          createdAt: now,
          updatedAt: now,
        );

        expect(
          () => cluster.setPrimary('non-existent'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('sets primary without optional parameters', () {
        final cluster = FactCluster(
          factClusterId: 'fc-1',
          factType: 'expense',
          primaryFactId: 'fact-1',
          memberFactIds: ['fact-1', 'fact-2'],
          createdAt: now,
          updatedAt: now,
        );

        final updated = cluster.setPrimary('fact-2');

        expect(updated.primaryFactId, equals('fact-2'));
        expect(updated.auditTrail.last.reason, isNull);
        expect(updated.auditTrail.last.actor, isNull);
      });
    });
  });
}
