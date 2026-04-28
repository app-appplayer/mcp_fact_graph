import 'package:test/test.dart';
import 'package:mcp_fact_graph/src/domain/entities/fact.dart';

void main() {
  group('FactStatus', () {
    test('has all expected values', () {
      expect(FactStatus.values, contains(FactStatus.confirmed));
      expect(FactStatus.values, contains(FactStatus.reclassified));
      expect(FactStatus.values, contains(FactStatus.archived));
    });

    test('fromString returns correct value', () {
      expect(FactStatus.fromString('confirmed'), equals(FactStatus.confirmed));
      expect(FactStatus.fromString('reclassified'), equals(FactStatus.reclassified));
      expect(FactStatus.fromString('archived'), equals(FactStatus.archived));
    });

    test('fromString returns confirmed for unknown values', () {
      expect(FactStatus.fromString('unknown'), equals(FactStatus.confirmed));
      expect(FactStatus.fromString(''), equals(FactStatus.confirmed));
    });
  });

  group('Fact', () {
    test('constructor creates instance with required fields', () {
      final now = DateTime.now();
      final fact = Fact(
        factId: 'fact-1',
        workspaceId: 'workspace-1',
        factType: 'expense',
        summary: 'Coffee purchase',
        occurredAt: now,
        candidateId: 'candidate-1',
        createdAt: now,
      );

      expect(fact.factId, equals('fact-1'));
      expect(fact.workspaceId, equals('workspace-1'));
      expect(fact.factType, equals('expense'));
      expect(fact.summary, equals('Coffee purchase'));
      expect(fact.payload, isEmpty);
      expect(fact.occurredAt, equals(now));
      expect(fact.status, equals(FactStatus.confirmed));
      expect(fact.candidateId, equals('candidate-1'));
      expect(fact.evidenceRefs, isEmpty);
      expect(fact.entityRefs, isEmpty);
      expect(fact.policyVersion, isNull);
      expect(fact.metadata, isEmpty);
    });

    test('constructor creates instance with all fields', () {
      final now = DateTime.now();
      final fact = Fact(
        factId: 'fact-1',
        workspaceId: 'workspace-1',
        factType: 'expense',
        summary: 'Coffee purchase',
        payload: {'amount': 5.50},
        occurredAt: now,
        status: FactStatus.archived,
        candidateId: 'candidate-1',
        evidenceRefs: ['evidence-1'],
        entityRefs: ['entity-1'],
        createdAt: now,
        policyVersion: 'v1.0',
        supersedes: 'old-fact-1',
        factClusterId: 'cluster-1',
        metadata: {'source': 'receipt'},
      );

      expect(fact.payload, equals({'amount': 5.50}));
      expect(fact.status, equals(FactStatus.archived));
      expect(fact.evidenceRefs, equals(['evidence-1']));
      expect(fact.entityRefs, equals(['entity-1']));
      expect(fact.policyVersion, equals('v1.0'));
      expect(fact.supersedes, equals('old-fact-1'));
      expect(fact.factClusterId, equals('cluster-1'));
      expect(fact.metadata, equals({'source': 'receipt'}));
    });

    test('fromJson creates instance from JSON', () {
      final json = {
        'factId': 'fact-1',
        'workspaceId': 'workspace-1',
        'factType': 'transaction',
        'summary': 'Bank transfer',
        'payload': {'amount': 100.0},
        'occurredAt': '2024-01-15T10:00:00.000',
        'status': 'reclassified',
        'candidateId': 'candidate-1',
        'evidenceRefs': ['ev-1', 'ev-2'],
        'entityRefs': ['ent-1'],
        'createdAt': '2024-01-14T10:00:00.000',
        'policyVersion': 'v2.0',
        'metadata': {'verified': true},
      };

      final fact = Fact.fromJson(json);

      expect(fact.factId, equals('fact-1'));
      expect(fact.factType, equals('transaction'));
      expect(fact.payload, equals({'amount': 100.0}));
      expect(fact.status, equals(FactStatus.reclassified));
      expect(fact.evidenceRefs, equals(['ev-1', 'ev-2']));
      expect(fact.policyVersion, equals('v2.0'));
    });

    test('fromJson handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final fact = Fact.fromJson(json);

      expect(fact.factId, equals(''));
      expect(fact.workspaceId, equals('default'));
      expect(fact.factType, equals(''));
      expect(fact.status, equals(FactStatus.confirmed));
      expect(fact.evidenceRefs, isEmpty);
    });

    test('toJson converts instance to JSON', () {
      final occurredAt = DateTime(2024, 1, 15);
      final createdAt = DateTime(2024, 1, 14);

      final fact = Fact(
        factId: 'fact-1',
        workspaceId: 'workspace-1',
        factType: 'meeting',
        summary: 'Team standup',
        payload: {'duration': 30},
        occurredAt: occurredAt,
        status: FactStatus.confirmed,
        candidateId: 'candidate-1',
        evidenceRefs: ['ev-1'],
        entityRefs: ['ent-1'],
        createdAt: createdAt,
        policyVersion: 'v1.0',
        metadata: {'recurring': true},
      );

      final json = fact.toJson();

      expect(json['factId'], equals('fact-1'));
      expect(json['workspaceId'], equals('workspace-1'));
      expect(json['factType'], equals('meeting'));
      expect(json['summary'], equals('Team standup'));
      expect(json['payload'], equals({'duration': 30}));
      expect(json['occurredAt'], equals(occurredAt.toIso8601String()));
      expect(json['status'], equals('confirmed'));
      expect(json['candidateId'], equals('candidate-1'));
      expect(json['evidenceRefs'], equals(['ev-1']));
      expect(json['policyVersion'], equals('v1.0'));
    });

    test('toJson excludes empty and null fields', () {
      final now = DateTime.now();
      final fact = Fact(
        factId: 'fact-1',
        workspaceId: 'workspace-1',
        factType: 'simple',
        summary: 'Simple fact',
        occurredAt: now,
        candidateId: 'candidate-1',
        createdAt: now,
      );

      final json = fact.toJson();

      expect(json.containsKey('payload'), isFalse);
      expect(json.containsKey('evidenceRefs'), isFalse);
      expect(json.containsKey('entityRefs'), isFalse);
      expect(json.containsKey('policyVersion'), isFalse);
      expect(json.containsKey('metadata'), isFalse);
    });

    test('fromJson parses supersedes and factClusterId', () {
      final json = {
        'factId': 'fact-super',
        'workspaceId': 'ws-1',
        'factType': 'expense',
        'summary': 'Correction',
        'occurredAt': '2024-01-15T10:00:00.000',
        'candidateId': 'cand-1',
        'createdAt': '2024-01-15T10:00:00.000',
        'supersedes': 'old-fact-1',
        'factClusterId': 'cluster-1',
      };

      final fact = Fact.fromJson(json);

      expect(fact.supersedes, equals('old-fact-1'));
      expect(fact.factClusterId, equals('cluster-1'));
    });

    test('toJson includes supersedes and factClusterId when present', () {
      final now = DateTime(2024, 1, 15);
      final fact = Fact(
        factId: 'fact-1',
        workspaceId: 'ws-1',
        factType: 'expense',
        summary: 'Test',
        occurredAt: now,
        candidateId: 'cand-1',
        createdAt: now,
        supersedes: 'old-fact',
        factClusterId: 'cluster-1',
      );

      final json = fact.toJson();

      expect(json['supersedes'], equals('old-fact'));
      expect(json['factClusterId'], equals('cluster-1'));
    });

    test('toJson excludes null supersedes and factClusterId', () {
      final now = DateTime(2024, 1, 15);
      final fact = Fact(
        factId: 'fact-1',
        workspaceId: 'ws-1',
        factType: 'expense',
        summary: 'Test',
        occurredAt: now,
        candidateId: 'cand-1',
        createdAt: now,
      );

      final json = fact.toJson();

      expect(json.containsKey('supersedes'), isFalse);
      expect(json.containsKey('factClusterId'), isFalse);
    });

    test('copyWith creates copy with updated fields', () {
      final now = DateTime.now();
      final original = Fact(
        factId: 'fact-1',
        workspaceId: 'workspace-1',
        factType: 'expense',
        summary: 'Original summary',
        occurredAt: now,
        candidateId: 'candidate-1',
        createdAt: now,
      );

      final copy = original.copyWith(
        summary: 'Updated summary',
        status: FactStatus.archived,
      );

      expect(copy.factId, equals('fact-1'));
      expect(copy.summary, equals('Updated summary'));
      expect(copy.status, equals(FactStatus.archived));
      expect(copy.factType, equals('expense'));
    });

    test('copyWith all parameters', () {
      final now = DateTime(2024, 1, 1);
      final newDate = DateTime(2024, 6, 1);
      final original = Fact(
        factId: 'fact-orig',
        workspaceId: 'ws-1',
        factType: 'expense',
        summary: 'Original',
        occurredAt: now,
        candidateId: 'cand-1',
        createdAt: now,
      );

      final copy = original.copyWith(
        factId: 'fact-new',
        workspaceId: 'ws-2',
        factType: 'meeting',
        summary: 'New summary',
        payload: {'amount': 100},
        occurredAt: newDate,
        status: FactStatus.reclassified,
        candidateId: 'cand-2',
        evidenceRefs: ['ev-1'],
        entityRefs: ['ent-1'],
        createdAt: newDate,
        policyVersion: 'v2.0',
        supersedes: 'old-fact',
        factClusterId: 'cluster-1',
        metadata: {'updated': true},
      );

      expect(copy.factId, equals('fact-new'));
      expect(copy.workspaceId, equals('ws-2'));
      expect(copy.factType, equals('meeting'));
      expect(copy.summary, equals('New summary'));
      expect(copy.payload, equals({'amount': 100}));
      expect(copy.occurredAt, equals(newDate));
      expect(copy.status, equals(FactStatus.reclassified));
      expect(copy.candidateId, equals('cand-2'));
      expect(copy.evidenceRefs, equals(['ev-1']));
      expect(copy.entityRefs, equals(['ent-1']));
      expect(copy.createdAt, equals(newDate));
      expect(copy.policyVersion, equals('v2.0'));
      expect(copy.supersedes, equals('old-fact'));
      expect(copy.factClusterId, equals('cluster-1'));
      expect(copy.metadata, equals({'updated': true}));
    });

    test('copyWith preserves summary and status when not specified', () {
      final now = DateTime.now();
      final original = Fact(
        factId: 'fact-preserve',
        workspaceId: 'workspace-1',
        factType: 'expense',
        summary: 'Preserved summary',
        occurredAt: now,
        status: FactStatus.reclassified,
        candidateId: 'candidate-1',
        createdAt: now,
      );

      // Only change factType, leaving summary and status untouched
      final copy = original.copyWith(factType: 'meeting');

      expect(copy.summary, equals('Preserved summary'));
      expect(copy.status, equals(FactStatus.reclassified));
      expect(copy.factType, equals('meeting'));
    });

    test('toString returns expected string representation', () {
      final fact = Fact(
        factId: 'fact-1',
        workspaceId: 'workspace-1',
        factType: 'expense',
        summary: 'Coffee',
        occurredAt: DateTime.now(),
        candidateId: 'candidate-1',
        createdAt: DateTime.now(),
      );

      final str = fact.toString();

      expect(str, contains('Fact'));
      expect(str, contains('fact-1'));
      expect(str, contains('expense'));
      expect(str, contains('Coffee'));
    });

    test('equality compares by factId', () {
      final now = DateTime.now();
      final fact1 = Fact(
        factId: 'fact-1',
        workspaceId: 'workspace-1',
        factType: 'expense',
        summary: 'Summary 1',
        occurredAt: now,
        candidateId: 'candidate-1',
        createdAt: now,
      );

      final fact2 = Fact(
        factId: 'fact-1',
        workspaceId: 'workspace-2',
        factType: 'meeting',
        summary: 'Summary 2',
        occurredAt: now,
        candidateId: 'candidate-2',
        createdAt: now,
      );

      final fact3 = Fact(
        factId: 'fact-2',
        workspaceId: 'workspace-1',
        factType: 'expense',
        summary: 'Summary 1',
        occurredAt: now,
        candidateId: 'candidate-1',
        createdAt: now,
      );

      expect(fact1 == fact2, isTrue);
      expect(fact1 == fact3, isFalse);
      expect(fact1.hashCode, equals(fact2.hashCode));
    });
  });
}
