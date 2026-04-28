// Tests for FactGraphService - L1 Layer operations.

import 'package:test/test.dart';
import 'package:mcp_fact_graph/mcp_fact_graph.dart';
// Internal ports — accessed via src path since they are not barrel-exported.
import 'package:mcp_fact_graph/src/ports/storage_port.dart';
import 'package:mcp_fact_graph/src/ports/llm_port.dart';

// Mock CandidateStoragePort
class MockCandidateStoragePort implements CandidateStoragePort {
  final Map<String, Candidate> _candidates = {};

  @override
  Future<void> saveCandidate(Candidate candidate) async {
    _candidates[candidate.candidateId] = candidate;
  }

  @override
  Future<Candidate?> getCandidate(String candidateId) async {
    return _candidates[candidateId];
  }

  @override
  Future<List<Candidate>> queryCandidates(CandidateQuery query) async {
    var results = _candidates.values.toList();
    if (query.workspaceId != null) {
      results =
          results.where((c) => c.workspaceId == query.workspaceId).toList();
    }
    if (query.status != null) {
      results = results.where((c) => c.status == query.status).toList();
    }
    if (query.limit != null) {
      results = results.take(query.limit!).toList();
    }
    return results;
  }

  @override
  Future<void> updateCandidateStatus(
      String candidateId, CandidateStatus status) async {
    final candidate = _candidates[candidateId];
    if (candidate != null) {
      _candidates[candidateId] = candidate.copyWith(status: status);
    }
  }

  @override
  Future<void> deleteCandidate(String candidateId) async {
    _candidates.remove(candidateId);
  }
}

// Mock EntityStoragePort
class MockEntityStoragePort implements EntityStoragePort {
  final Map<String, Entity> _entities = {};

  @override
  Future<void> saveEntity(Entity entity) async {
    _entities[entity.entityId] = entity;
  }

  @override
  Future<Entity?> getEntity(String entityId) async {
    return _entities[entityId];
  }

  @override
  Future<List<Entity>> queryEntities(EntityQuery query) async {
    return _entities.values.toList();
  }

  @override
  Future<List<Entity>> findByName(String query) async {
    return _entities.values
        .where((e) => e.matchesName(query))
        .toList();
  }

  @override
  Future<List<Entity>> getRelated(String entityId) async {
    // Return all entities except the one requested
    return _entities.values
        .where((e) => e.entityId != entityId)
        .toList();
  }

  @override
  Future<void> deleteEntity(String entityId) async {
    _entities.remove(entityId);
  }
}

// Mock FactStoragePort
class MockFactStoragePort implements FactStoragePort {
  final Map<String, Fact> _facts = {};

  @override
  Future<void> saveFact(Fact fact) async {
    _facts[fact.factId] = fact;
  }

  @override
  Future<Fact?> getFact(String factId) async {
    return _facts[factId];
  }

  @override
  Future<List<Fact>> queryFacts(FactQuery query) async {
    var results = _facts.values.toList();
    if (query.status != null) {
      results = results.where((f) => f.status == query.status).toList();
    }
    if (query.limit != null) {
      results = results.take(query.limit!).toList();
    }
    return results;
  }

  @override
  Future<List<Fact>> getFactsForEntity(String entityId) async {
    return _facts.values
        .where((f) => f.entityRefs.contains(entityId))
        .toList();
  }

  @override
  Future<void> deleteFact(String factId) async {
    _facts.remove(factId);
  }
}

// Mock ViewStoragePort
class MockViewStoragePort implements ViewStoragePort {
  final Map<String, View> _views = {};

  @override
  Future<void> saveView(View view) async {
    _views[view.viewId] = view;
  }

  @override
  Future<View?> getView(String viewId) async {
    return _views[viewId];
  }

  @override
  Future<List<View>> queryViews(ViewQuery query) async {
    var results = _views.values.toList();
    if (query.workspaceId != null) {
      results =
          results.where((v) => v.workspaceId == query.workspaceId).toList();
    }
    if (query.limit != null) {
      results = results.take(query.limit!).toList();
    }
    return results;
  }

  @override
  Future<void> deleteView(String viewId) async {
    _views.remove(viewId);
  }
}

// Mock EntityResolutionPort
class MockEntityResolutionPort implements EntityResolutionPort {
  EntityResolutionResult? resolveResult;

  @override
  Future<EntityResolutionResult> resolve(EntityResolutionInput input) async {
    return resolveResult ??
        const EntityResolutionResult(
          shouldCreate: true,
          confidence: 0.8,
        );
  }

  @override
  Future<List<EntityMatch>> findMatches(
      String query, String entityType) async {
    return [];
  }
}

void main() {
  group('FactGraphService', () {
    late MockCandidateStoragePort candidateStorage;
    late MockEntityStoragePort entityStorage;
    late MockFactStoragePort factStorage;
    late MockViewStoragePort viewStorage;
    late MockEntityResolutionPort entityResolver;
    late FactGraphService serviceWithResolver;
    late FactGraphService serviceWithoutResolver;

    final now = DateTime.now();

    setUp(() {
      candidateStorage = MockCandidateStoragePort();
      entityStorage = MockEntityStoragePort();
      factStorage = MockFactStoragePort();
      viewStorage = MockViewStoragePort();
      entityResolver = MockEntityResolutionPort();

      serviceWithResolver = FactGraphService(
        candidateStorage: candidateStorage,
        entityStorage: entityStorage,
        factStorage: factStorage,
        viewStorage: viewStorage,
        entityResolver: entityResolver,
      );
      serviceWithoutResolver = FactGraphService(
        candidateStorage: candidateStorage,
        entityStorage: entityStorage,
        factStorage: factStorage,
        viewStorage: viewStorage,
      );
    });

    group('createCandidate', () {
      test('creates candidate from fragments', () async {
        final fragments = [
          Fragment(
            fragmentId: 'frag-1',
            workspaceId: 'ws-1',
            evidenceId: 'ev-1',
            fields: const {'name': 'Test', 'amount': 100},
            confidence: 0.9,
            createdAt: now,
          ),
        ];

        final candidate = await serviceWithResolver.createCandidate(
          workspaceId: 'ws-1',
          objectType: 'expense',
          fragments: fragments,
        );

        expect(candidate.candidateId, startsWith('cand_'));
        expect(candidate.workspaceId, equals('ws-1'));
        expect(candidate.objectType, equals('expense'));
        expect(candidate.status, equals(CandidateStatus.open));
        expect(candidate.fragmentIds, contains('frag-1'));
        expect(candidate.fields.containsKey('name'), isTrue);
        expect(candidate.fields['name']!.value, equals('Test'));
      });

      test('calculates confidence from fields', () async {
        final fragments = [
          Fragment(
            fragmentId: 'frag-1',
            workspaceId: 'ws-1',
            evidenceId: 'ev-1',
            fields: const {'name': 'Test'},
            confidence: 0.8,
            createdAt: now,
          ),
          Fragment(
            fragmentId: 'frag-2',
            workspaceId: 'ws-1',
            evidenceId: 'ev-1',
            fields: const {'amount': 50},
            confidence: 0.6,
            createdAt: now,
          ),
        ];

        final candidate = await serviceWithResolver.createCandidate(
          workspaceId: 'ws-1',
          objectType: 'expense',
          fragments: fragments,
        );

        // Average of 0.8 and 0.6 = 0.7
        expect(candidate.confidence, closeTo(0.7, 0.01));
      });

      test('handles empty fragments', () async {
        final candidate = await serviceWithResolver.createCandidate(
          workspaceId: 'ws-1',
          objectType: 'expense',
          fragments: [],
        );

        expect(candidate.fields, isEmpty);
        expect(candidate.confidence, equals(0.0));
      });

      test('includes additional data as metadata', () async {
        final candidate = await serviceWithResolver.createCandidate(
          workspaceId: 'ws-1',
          objectType: 'expense',
          fragments: [],
          additionalData: {'source': 'manual'},
        );

        expect(candidate.metadata, equals({'source': 'manual'}));
      });
    });

    group('getCandidate', () {
      test('returns candidate when found', () async {
        final candidate = await serviceWithResolver.createCandidate(
          workspaceId: 'ws-1',
          objectType: 'expense',
          fragments: [],
        );

        final result =
            await serviceWithResolver.getCandidate(candidate.candidateId);

        expect(result, isNotNull);
        expect(result!.candidateId, equals(candidate.candidateId));
      });

      test('returns null when not found', () async {
        final result =
            await serviceWithResolver.getCandidate('nonexistent');

        expect(result, isNull);
      });
    });

    group('queryCandidates', () {
      test('returns matching candidates', () async {
        await serviceWithResolver.createCandidate(
          workspaceId: 'ws-1',
          objectType: 'expense',
          fragments: [],
        );
        // Delay to ensure unique timestamp-based ID generation
        await Future.delayed(const Duration(milliseconds: 2));
        await serviceWithResolver.createCandidate(
          workspaceId: 'ws-2',
          objectType: 'task',
          fragments: [],
        );

        final results = await serviceWithResolver
            .queryCandidates(const CandidateQuery(workspaceId: 'ws-1'));

        expect(results, hasLength(1));
        expect(results.first.workspaceId, equals('ws-1'));
      });
    });

    group('confirmCandidate', () {
      test('confirms candidate and creates fact without resolver', () async {
        final candidate = await serviceWithoutResolver.createCandidate(
          workspaceId: 'ws-1',
          objectType: 'expense',
          fragments: [
            Fragment(
              fragmentId: 'frag-1',
              workspaceId: 'ws-1',
              evidenceId: 'ev-1',
              fields: const {'name': 'Lunch', 'amount': 15},
              confidence: 0.9,
              createdAt: now,
            ),
          ],
        );

        final result = await serviceWithoutResolver
            .confirmCandidate(candidate.candidateId);

        expect(result.candidateId, equals(candidate.candidateId));
        expect(result.factId, isNotNull);
        expect(result.entityId, isNull);
      });

      test('confirms candidate with entity resolution', () async {
        entityResolver.resolveResult = const EntityResolutionResult(
          shouldCreate: true,
          confidence: 0.9,
        );

        final candidate = await serviceWithResolver.createCandidate(
          workspaceId: 'ws-1',
          objectType: 'expense',
          fragments: [
            Fragment(
              fragmentId: 'frag-1',
              workspaceId: 'ws-1',
              evidenceId: 'ev-1',
              fields: const {'name': 'Lunch'},
              confidence: 0.9,
              createdAt: now,
            ),
          ],
        );

        final result = await serviceWithResolver
            .confirmCandidate(candidate.candidateId);

        expect(result.factId, isNotNull);
        expect(result.entityId, isNotNull);
      });

      test('resolves existing entity when entityId returned', () async {
        entityResolver.resolveResult = const EntityResolutionResult(
          entityId: 'existing-entity',
          shouldCreate: false,
          confidence: 0.95,
        );

        final candidate = await serviceWithResolver.createCandidate(
          workspaceId: 'ws-1',
          objectType: 'expense',
          fragments: [
            Fragment(
              fragmentId: 'frag-1',
              workspaceId: 'ws-1',
              evidenceId: 'ev-1',
              fields: const {'name': 'Lunch'},
              confidence: 0.9,
              createdAt: now,
            ),
          ],
        );

        final result = await serviceWithResolver
            .confirmCandidate(candidate.candidateId);

        expect(result.entityId, equals('existing-entity'));
      });

      test('returns null entity when resolver returns no match and no create',
          () async {
        entityResolver.resolveResult = const EntityResolutionResult(
          shouldCreate: false,
          confidence: 0.3,
        );

        final candidate = await serviceWithResolver.createCandidate(
          workspaceId: 'ws-1',
          objectType: 'expense',
          fragments: [
            Fragment(
              fragmentId: 'frag-1',
              workspaceId: 'ws-1',
              evidenceId: 'ev-1',
              fields: const {'name': 'Lunch'},
              confidence: 0.9,
              createdAt: now,
            ),
          ],
        );

        final result = await serviceWithResolver
            .confirmCandidate(candidate.candidateId);

        expect(result.entityId, isNull);
      });

      test('skips entity resolution when no name/entity field', () async {
        final candidate = await serviceWithResolver.createCandidate(
          workspaceId: 'ws-1',
          objectType: 'expense',
          fragments: [
            Fragment(
              fragmentId: 'frag-1',
              workspaceId: 'ws-1',
              evidenceId: 'ev-1',
              fields: const {'amount': 100},
              confidence: 0.9,
              createdAt: now,
            ),
          ],
        );

        final result = await serviceWithResolver
            .confirmCandidate(candidate.candidateId);

        expect(result.entityId, isNull);
      });

      test('updates candidate status to confirmed', () async {
        final candidate = await serviceWithoutResolver.createCandidate(
          workspaceId: 'ws-1',
          objectType: 'expense',
          fragments: [],
        );

        await serviceWithoutResolver
            .confirmCandidate(candidate.candidateId);

        final updated =
            await candidateStorage.getCandidate(candidate.candidateId);
        expect(updated!.status, equals(CandidateStatus.confirmed));
        expect(updated.confirmedAt, isNotNull);
      });

      test('throws ArgumentError when candidate not found', () async {
        expect(
          () => serviceWithResolver.confirmCandidate('nonexistent'),
          throwsArgumentError,
        );
      });

      test('passes policyVersion to fact', () async {
        final candidate = await serviceWithoutResolver.createCandidate(
          workspaceId: 'ws-1',
          objectType: 'expense',
          fragments: [],
        );

        await serviceWithoutResolver
            .confirmCandidate(candidate.candidateId, policyVersion: 'v2.0');

        // Verify fact was created (by checking resultingIds on updated candidate)
        final updated =
            await candidateStorage.getCandidate(candidate.candidateId);
        expect(updated!.resultingIds, isNotNull);
        expect(updated.resultingIds, isNotEmpty);
      });
    });

    group('rejectCandidate', () {
      test('rejects a candidate', () async {
        final candidate = await serviceWithResolver.createCandidate(
          workspaceId: 'ws-1',
          objectType: 'expense',
          fragments: [],
        );

        final rejected = await serviceWithResolver
            .rejectCandidate(candidate.candidateId);

        expect(rejected.status, equals(CandidateStatus.rejected));
      });

      test('throws ArgumentError when candidate not found', () async {
        expect(
          () => serviceWithResolver.rejectCandidate('nonexistent'),
          throwsArgumentError,
        );
      });
    });

    group('Entity operations', () {
      test('getEntity returns entity by ID', () async {
        final entity = Entity(
          entityId: 'ent-1',
          workspaceId: 'ws-1',
          type: 'person',
          canonicalName: 'Alice',
          createdAt: now,
          updatedAt: now,
        );
        await entityStorage.saveEntity(entity);

        final result = await serviceWithResolver.getEntity('ent-1');

        expect(result, isNotNull);
        expect(result!.canonicalName, equals('Alice'));
      });

      test('findEntitiesByName returns matching entities', () async {
        final entity = Entity(
          entityId: 'ent-1',
          workspaceId: 'ws-1',
          type: 'person',
          canonicalName: 'Alice',
          createdAt: now,
          updatedAt: now,
        );
        await entityStorage.saveEntity(entity);

        final results =
            await serviceWithResolver.findEntitiesByName('Alice');

        expect(results, hasLength(1));
        expect(results.first.canonicalName, equals('Alice'));
      });

      test('getRelatedEntities returns related entities', () async {
        final entity1 = Entity(
          entityId: 'ent-1',
          workspaceId: 'ws-1',
          type: 'person',
          canonicalName: 'Alice',
          createdAt: now,
          updatedAt: now,
        );
        final entity2 = Entity(
          entityId: 'ent-2',
          workspaceId: 'ws-1',
          type: 'person',
          canonicalName: 'Bob',
          createdAt: now,
          updatedAt: now,
        );
        await entityStorage.saveEntity(entity1);
        await entityStorage.saveEntity(entity2);

        final results =
            await serviceWithResolver.getRelatedEntities('ent-1');

        expect(results, hasLength(1));
        expect(results.first.entityId, equals('ent-2'));
      });
    });

    group('Fact operations', () {
      test('getFact returns fact by ID', () async {
        final fact = Fact(
          factId: 'fact-1',
          workspaceId: 'ws-1',
          factType: 'expense',
          summary: 'Lunch at 15 dollars',
          occurredAt: now,
          candidateId: 'cand-1',
          createdAt: now,
        );
        await factStorage.saveFact(fact);

        final result = await serviceWithResolver.getFact('fact-1');

        expect(result, isNotNull);
        expect(result!.summary, equals('Lunch at 15 dollars'));
      });

      test('queryFacts returns matching facts', () async {
        final fact = Fact(
          factId: 'fact-1',
          workspaceId: 'ws-1',
          factType: 'expense',
          summary: 'Lunch',
          occurredAt: now,
          candidateId: 'cand-1',
          createdAt: now,
        );
        await factStorage.saveFact(fact);

        final results = await serviceWithResolver
            .queryFacts(const FactQuery(status: FactStatus.confirmed));

        expect(results, hasLength(1));
      });

      test('getFactsForEntity returns facts for entity', () async {
        final fact = Fact(
          factId: 'fact-1',
          workspaceId: 'ws-1',
          factType: 'expense',
          summary: 'Lunch',
          occurredAt: now,
          candidateId: 'cand-1',
          entityRefs: const ['ent-1'],
          createdAt: now,
        );
        await factStorage.saveFact(fact);

        final results =
            await serviceWithResolver.getFactsForEntity('ent-1');

        expect(results, hasLength(1));
      });
    });

    group('View operations', () {
      test('computeView creates and saves a view', () async {
        final period = ViewPeriod(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );

        final view = await serviceWithResolver.computeView(
          workspaceId: 'ws-1',
          viewType: 'weekly-summary',
          title: 'Weekly Summary',
          period: period,
          scope: 'all',
          policyVersion: '1.0.0',
        );

        expect(view.viewId, startsWith('view_'));
        expect(view.workspaceId, equals('ws-1'));
        expect(view.viewType, equals('weekly-summary'));
        expect(view.title, equals('Weekly Summary'));
        expect(view.status, equals(ViewStatus.current));
        expect(view.metrics.containsKey('factCount'), isTrue);
      });

      test('getView returns view by ID', () async {
        final period = ViewPeriod(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );

        final view = await serviceWithResolver.computeView(
          workspaceId: 'ws-1',
          viewType: 'weekly-summary',
          title: 'Weekly Summary',
          period: period,
          scope: 'all',
          policyVersion: '1.0.0',
        );

        final result = await serviceWithResolver.getView(view.viewId);

        expect(result, isNotNull);
        expect(result!.viewId, equals(view.viewId));
      });

      test('queryViews returns matching views', () async {
        final period = ViewPeriod(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );

        await serviceWithResolver.computeView(
          workspaceId: 'ws-1',
          viewType: 'weekly-summary',
          title: 'Weekly Summary',
          period: period,
          scope: 'all',
          policyVersion: '1.0.0',
        );

        final results = await serviceWithResolver
            .queryViews(const ViewQuery(workspaceId: 'ws-1'));

        expect(results, hasLength(1));
      });
    });

    group('ConfirmationResult', () {
      test('has correct properties', () {
        const result = ConfirmationResult(
          candidateId: 'cand-1',
          factId: 'fact-1',
          entityId: 'ent-1',
        );

        expect(result.candidateId, equals('cand-1'));
        expect(result.factId, equals('fact-1'));
        expect(result.entityId, equals('ent-1'));
      });

      test('allows null factId and entityId', () {
        const result = ConfirmationResult(
          candidateId: 'cand-1',
        );

        expect(result.factId, isNull);
        expect(result.entityId, isNull);
      });
    });

    // Additional coverage tests

    group('createCandidate - additional coverage', () {
      test('builds fields from multiple fragments with overlapping keys',
          () async {
        final fragments = [
          Fragment(
            fragmentId: 'frag-1',
            workspaceId: 'ws-1',
            evidenceId: 'ev-1',
            fields: const {'name': 'Lunch', 'amount': 15},
            confidence: 0.9,
            createdAt: now,
          ),
          Fragment(
            fragmentId: 'frag-2',
            workspaceId: 'ws-1',
            evidenceId: 'ev-1',
            fields: const {'name': 'Dinner', 'location': 'Downtown'},
            confidence: 0.7,
            createdAt: now,
          ),
        ];

        final candidate = await serviceWithResolver.createCandidate(
          workspaceId: 'ws-1',
          objectType: 'expense',
          fragments: fragments,
        );

        // Later fragment overwrites 'name' key
        expect(candidate.fields['name']!.value, equals('Dinner'));
        expect(candidate.fields['amount']!.value, equals(15));
        expect(candidate.fields['location']!.value, equals('Downtown'));
        expect(candidate.fragmentIds, contains('frag-1'));
        expect(candidate.fragmentIds, contains('frag-2'));
      });

      test('uses empty metadata when additionalData not provided', () async {
        final candidate = await serviceWithResolver.createCandidate(
          workspaceId: 'ws-1',
          objectType: 'expense',
          fragments: [],
        );

        expect(candidate.metadata, isEmpty);
      });

      test('fields have correct sourceFragmentId and confidence', () async {
        final fragments = [
          Fragment(
            fragmentId: 'frag-src',
            workspaceId: 'ws-1',
            evidenceId: 'ev-1',
            fields: const {'name': 'Test'},
            confidence: 0.85,
            createdAt: now,
          ),
        ];

        final candidate = await serviceWithResolver.createCandidate(
          workspaceId: 'ws-1',
          objectType: 'expense',
          fragments: fragments,
        );

        expect(candidate.fields['name']!.sourceFragmentId, equals('frag-src'));
        expect(candidate.fields['name']!.confidence, equals(0.85));
      });
    });

    group('confirmCandidate - additional coverage', () {
      test('creates fact with name and amount in summary', () async {
        final candidate = await serviceWithoutResolver.createCandidate(
          workspaceId: 'ws-1',
          objectType: 'expense',
          fragments: [
            Fragment(
              fragmentId: 'frag-1',
              workspaceId: 'ws-1',
              evidenceId: 'ev-1',
              fields: const {'name': 'Lunch', 'amount': 15},
              confidence: 0.9,
              createdAt: now,
            ),
          ],
        );

        final result = await serviceWithoutResolver
            .confirmCandidate(candidate.candidateId);

        // Verify fact was created with proper summary
        final fact = await factStorage.getFact(result.factId!);
        expect(fact, isNotNull);
        expect(fact!.summary, contains('expense'));
        expect(fact.summary, contains('Lunch'));
        expect(fact.summary, contains('15'));
        expect(fact.factType, equals('expense'));
        expect(fact.status, equals(FactStatus.confirmed));
        expect(fact.candidateId, equals(candidate.candidateId));
      });

      test('creates fact with fields converted to payload', () async {
        final candidate = await serviceWithoutResolver.createCandidate(
          workspaceId: 'ws-1',
          objectType: 'expense',
          fragments: [
            Fragment(
              fragmentId: 'frag-1',
              workspaceId: 'ws-1',
              evidenceId: 'ev-1',
              fields: const {'name': 'Lunch', 'amount': 15, 'currency': 'USD'},
              confidence: 0.9,
              createdAt: now,
            ),
          ],
        );

        final result = await serviceWithoutResolver
            .confirmCandidate(candidate.candidateId);

        final fact = await factStorage.getFact(result.factId!);
        expect(fact, isNotNull);
        expect(fact!.payload['name'], equals('Lunch'));
        expect(fact.payload['amount'], equals(15));
        expect(fact.payload['currency'], equals('USD'));
      });

      test('creates entity when resolver returns shouldCreate=true', () async {
        entityResolver.resolveResult = const EntityResolutionResult(
          shouldCreate: true,
          confidence: 0.9,
        );

        final candidate = await serviceWithResolver.createCandidate(
          workspaceId: 'ws-1',
          objectType: 'person',
          fragments: [
            Fragment(
              fragmentId: 'frag-1',
              workspaceId: 'ws-1',
              evidenceId: 'ev-1',
              fields: const {'name': 'Alice'},
              confidence: 0.9,
              createdAt: now,
            ),
          ],
        );

        final result = await serviceWithResolver
            .confirmCandidate(candidate.candidateId);

        expect(result.entityId, isNotNull);
        expect(result.entityId, startsWith('ent_'));

        // Verify entity was created in storage
        final entity = await entityStorage.getEntity(result.entityId!);
        expect(entity, isNotNull);
        expect(entity!.canonicalName, equals('Alice'));
        expect(entity.type, equals('person'));
        expect(entity.sourceCandidateIds, contains(candidate.candidateId));
      });

      test('resolves entity using entity field instead of name', () async {
        entityResolver.resolveResult = const EntityResolutionResult(
          shouldCreate: true,
          confidence: 0.9,
        );

        final candidate = await serviceWithResolver.createCandidate(
          workspaceId: 'ws-1',
          objectType: 'transaction',
          fragments: [
            Fragment(
              fragmentId: 'frag-1',
              workspaceId: 'ws-1',
              evidenceId: 'ev-1',
              fields: const {'entity': 'Bob', 'amount': 50},
              confidence: 0.9,
              createdAt: now,
            ),
          ],
        );

        final result = await serviceWithResolver
            .confirmCandidate(candidate.candidateId);

        expect(result.entityId, isNotNull);

        // Verify entity has correct name from 'entity' field
        final entity = await entityStorage.getEntity(result.entityId!);
        expect(entity, isNotNull);
        expect(entity!.canonicalName, equals('Bob'));
      });

      test('updates candidate with resultingIds containing fact and entity',
          () async {
        entityResolver.resolveResult = const EntityResolutionResult(
          shouldCreate: true,
          confidence: 0.9,
        );

        final candidate = await serviceWithResolver.createCandidate(
          workspaceId: 'ws-1',
          objectType: 'expense',
          fragments: [
            Fragment(
              fragmentId: 'frag-1',
              workspaceId: 'ws-1',
              evidenceId: 'ev-1',
              fields: const {'name': 'Lunch'},
              confidence: 0.9,
              createdAt: now,
            ),
          ],
        );

        final result = await serviceWithResolver
            .confirmCandidate(candidate.candidateId);

        final updated =
            await candidateStorage.getCandidate(candidate.candidateId);
        expect(updated!.resultingIds, contains(result.factId));
        expect(updated.resultingIds, contains(result.entityId));
        expect(updated.status, equals(CandidateStatus.confirmed));
        expect(updated.confirmedAt, isNotNull);
      });

      test('fact summary contains only objectType when no name/amount fields',
          () async {
        final candidate = await serviceWithoutResolver.createCandidate(
          workspaceId: 'ws-1',
          objectType: 'note',
          fragments: [
            Fragment(
              fragmentId: 'frag-1',
              workspaceId: 'ws-1',
              evidenceId: 'ev-1',
              fields: const {'content': 'Some text'},
              confidence: 0.9,
              createdAt: now,
            ),
          ],
        );

        final result = await serviceWithoutResolver
            .confirmCandidate(candidate.candidateId);

        final fact = await factStorage.getFact(result.factId!);
        expect(fact, isNotNull);
        // Summary should just be the objectType since no name/amount
        expect(fact!.summary, equals('note'));
      });
    });

    group('rejectCandidate - additional coverage', () {
      test('sets updatedAt on rejected candidate', () async {
        final candidate = await serviceWithResolver.createCandidate(
          workspaceId: 'ws-1',
          objectType: 'expense',
          fragments: [],
        );

        final rejected = await serviceWithResolver
            .rejectCandidate(candidate.candidateId, reason: 'invalid');

        expect(rejected.status, equals(CandidateStatus.rejected));
        expect(rejected.updatedAt, isNotNull);
      });
    });

    group('Entity operations - additional coverage', () {
      test('getEntity returns null for non-existent entity', () async {
        final result = await serviceWithResolver.getEntity('no-such-entity');
        expect(result, isNull);
      });

      test('findEntitiesByName returns empty when no match', () async {
        final results =
            await serviceWithResolver.findEntitiesByName('Unknown Person');
        expect(results, isEmpty);
      });

      test('getRelatedEntities returns empty when no related', () async {
        final entity = Entity(
          entityId: 'solo-ent',
          workspaceId: 'ws-1',
          type: 'person',
          canonicalName: 'Solo',
          createdAt: now,
          updatedAt: now,
        );
        await entityStorage.saveEntity(entity);

        final results =
            await serviceWithResolver.getRelatedEntities('solo-ent');
        expect(results, isEmpty);
      });
    });

    group('Fact operations - additional coverage', () {
      test('getFact returns null for non-existent fact', () async {
        final result = await serviceWithResolver.getFact('no-such-fact');
        expect(result, isNull);
      });

      test('queryFacts returns empty when no facts match', () async {
        final results = await serviceWithResolver
            .queryFacts(const FactQuery(status: FactStatus.confirmed));
        expect(results, isEmpty);
      });

      test('getFactsForEntity returns empty when no matching entity refs',
          () async {
        final results =
            await serviceWithResolver.getFactsForEntity('no-entity');
        expect(results, isEmpty);
      });
    });

    group('View operations - additional coverage', () {
      test('computeView with facts in period returns correct metrics',
          () async {
        final fact = Fact(
          factId: 'fact-view-1',
          workspaceId: 'ws-1',
          factType: 'expense',
          summary: 'Lunch',
          occurredAt: now,
          candidateId: 'cand-1',
          createdAt: now,
        );
        await factStorage.saveFact(fact);

        await Future.delayed(const Duration(milliseconds: 2));

        final fact2 = Fact(
          factId: 'fact-view-2',
          workspaceId: 'ws-1',
          factType: 'task',
          summary: 'Meeting',
          occurredAt: now,
          candidateId: 'cand-2',
          createdAt: now,
        );
        await factStorage.saveFact(fact2);

        final period = ViewPeriod(
          start: now.subtract(const Duration(days: 7)),
          end: now.add(const Duration(days: 1)),
        );

        final view = await serviceWithResolver.computeView(
          workspaceId: 'ws-1',
          viewType: 'weekly-summary',
          title: 'Weekly Summary',
          period: period,
          scope: 'all',
          policyVersion: '1.0.0',
        );

        expect(view.metrics['factCount'], equals(2));
        expect((view.metrics['factTypes'] as List), contains('expense'));
        expect((view.metrics['factTypes'] as List), contains('task'));
        expect(view.sourceRefs, contains('fact-view-1'));
        expect(view.sourceRefs, contains('fact-view-2'));
        expect(view.computationMeta!.eventsProcessed, equals(2));
        expect(view.computationMeta!.algorithm, equals('basic'));
        expect(view.status, equals(ViewStatus.current));
      });

      test('getView returns null for non-existent view', () async {
        final result = await serviceWithResolver.getView('no-such-view');
        expect(result, isNull);
      });

      test('queryViews returns empty when no matching views', () async {
        final results = await serviceWithResolver
            .queryViews(const ViewQuery(workspaceId: 'non-existent'));
        expect(results, isEmpty);
      });

      test('computeView saves view to storage', () async {
        final period = ViewPeriod(
          start: now.subtract(const Duration(days: 1)),
          end: now,
        );

        final view = await serviceWithResolver.computeView(
          workspaceId: 'ws-1',
          viewType: 'daily',
          title: 'Daily Report',
          period: period,
          scope: 'expenses',
          policyVersion: '2.0.0',
        );

        final stored = await viewStorage.getView(view.viewId);
        expect(stored, isNotNull);
        expect(stored!.viewType, equals('daily'));
        expect(stored.title, equals('Daily Report'));
        expect(stored.scope, equals('expenses'));
        expect(stored.policyVersion, equals('2.0.0'));
      });
    });
  });
}
