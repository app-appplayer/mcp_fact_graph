import 'package:test/test.dart';
import 'package:mcp_fact_graph/mcp_fact_graph.dart';

void main() {
  group('Candidate', () {
    test('creates candidate with required fields', () {
      final now = DateTime.now();
      final candidate = Candidate(
        workspaceId: 'test-workspace',
        candidateId: 'cand-1',
        objectType: 'expense',
        confidence: 0.9,
        createdAt: now,
        updatedAt: now,
      );

      expect(candidate.candidateId, equals('cand-1'));
      expect(candidate.objectType, equals('expense'));
      expect(candidate.confidence, equals(0.9));
      expect(candidate.status, equals(CandidateStatus.open));
      expect(candidate.fragmentIds, isEmpty);
      expect(candidate.fields, isEmpty);
    });

    test('creates candidate with all fields', () {
      final now = DateTime.now();
      final candidate = Candidate(
        workspaceId: 'test-workspace',
        candidateId: 'cand-2',
        objectType: 'schedule',
        status: CandidateStatus.ready,
        fragmentIds: ['frag-1', 'frag-2'],
        evidenceIds: ['ev-1'],
        fields: {
          'amount': CandidateField(value: 100.0, confidence: 0.95),
        },
        confidence: 0.85,
        unresolvedIssues: [
          UnresolvedIssue(
            code: 'LOW_CONF',
            type: IssueType.lowConfidence,
            field: 'merchant',
            description: 'Merchant confidence is low',
          ),
        ],
        createdAt: now,
        updatedAt: now,
        metadata: {'source': 'test'},
      );

      expect(candidate.status, equals(CandidateStatus.ready));
      expect(candidate.fragmentIds.length, equals(2));
      expect(candidate.fields['amount']!.value, equals(100.0));
      expect(candidate.unresolvedIssues.length, equals(1));
    });

    test('isReadyForConfirmation checks conditions', () {
      final now = DateTime.now();
      final readyCandidate = Candidate(
        workspaceId: 'test-workspace',
        candidateId: 'cand-3',
        objectType: 'task',
        confidence: 0.9,
        createdAt: now,
        updatedAt: now,
      );

      final notReadyCandidate = Candidate(
        workspaceId: 'test-workspace',
        candidateId: 'cand-4',
        objectType: 'task',
        confidence: 0.5,
        unresolvedIssues: [
          UnresolvedIssue(
            code: 'MISSING',
            type: IssueType.missingField,
            description: 'Required field missing',
          ),
        ],
        createdAt: now,
        updatedAt: now,
      );

      final confirmedCandidate = Candidate(
        workspaceId: 'test-workspace',
        candidateId: 'cand-5',
        objectType: 'task',
        status: CandidateStatus.confirmed,
        confidence: 0.9,
        createdAt: now,
        updatedAt: now,
      );

      expect(readyCandidate.isReadyForConfirmation, isTrue);
      expect(notReadyCandidate.isReadyForConfirmation, isFalse);
      expect(confirmedCandidate.isReadyForConfirmation, isFalse);
    });

    test('hasRequiredFields validates presence', () {
      final now = DateTime.now();
      final candidate = Candidate(
        workspaceId: 'test-workspace',
        candidateId: 'cand-6',
        objectType: 'expense',
        fields: {
          'amount': CandidateField(value: 50.0, confidence: 0.9),
          'date': CandidateField(value: '2024-01-01', confidence: 0.95),
        },
        confidence: 0.9,
        createdAt: now,
        updatedAt: now,
      );

      expect(candidate.hasRequiredFields(['amount', 'date']), isTrue);
      expect(candidate.hasRequiredFields(['amount', 'merchant']), isFalse);
    });

    test('serializes and deserializes correctly', () {
      final now = DateTime(2024, 1, 1, 12, 0, 0);
      final original = Candidate(
        workspaceId: 'test-workspace',
        candidateId: 'cand-7',
        objectType: 'expense',
        fields: {
          'amount': CandidateField(value: 25.0, confidence: 0.88),
        },
        confidence: 0.88,
        createdAt: now,
        updatedAt: now,
      );

      final json = original.toJson();
      final restored = Candidate.fromJson(json);

      expect(restored.candidateId, equals(original.candidateId));
      expect(restored.objectType, equals(original.objectType));
      expect(restored.confidence, equals(original.confidence));
    });

    test('fromJson handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final candidate = Candidate.fromJson(json);

      expect(candidate.candidateId, equals(''));
      expect(candidate.workspaceId, equals('default'));
      expect(candidate.objectType, equals(''));
      expect(candidate.status, equals(CandidateStatus.open));
      expect(candidate.resolutionState, equals(ResolutionState.unresolved));
      expect(candidate.fragmentIds, isEmpty);
      expect(candidate.evidenceIds, isEmpty);
      expect(candidate.fields, isEmpty);
      expect(candidate.links, isEmpty);
      expect(candidate.auditTrail, isEmpty);
      expect(candidate.confidence, equals(0.0));
      expect(candidate.unresolvedIssues, isEmpty);
      expect(candidate.confirmedAt, isNull);
      expect(candidate.resultingIds, isNull);
      expect(candidate.metadata, isEmpty);
    });

    test('fromJson parses all fields correctly', () {
      final json = {
        'candidateId': 'cand-full',
        'workspaceId': 'ws-1',
        'objectType': 'expense',
        'status': 'ready',
        'resolutionState': 'partial',
        'fragmentIds': ['frag-1'],
        'evidenceIds': ['ev-1'],
        'fields': {
          'amount': {'value': 100.0, 'confidence': 0.95, 'sourceFragmentId': 'frag-1', 'confirmed': true},
        },
        'links': [
          {'entityId': 'ent-1', 'role': 'vendor', 'status': 'confirmed'},
        ],
        'auditTrail': [
          {'timestamp': '2024-01-01T00:00:00.000', 'action': 'create', 'sourceId': 'src-1', 'changes': {'a': 'b'}, 'reason': 'initial'},
        ],
        'confidence': 0.85,
        'unresolvedIssues': [
          {'code': 'LOW', 'type': 'lowConfidence', 'field': 'merchant', 'description': 'Low conf', 'suggestion': 'Verify'},
        ],
        'createdAt': '2024-01-01T00:00:00.000',
        'updatedAt': '2024-01-02T00:00:00.000',
        'confirmedAt': '2024-01-03T00:00:00.000',
        'resultingIds': ['fact-1'],
        'metadata': {'src': 'test'},
      };

      final candidate = Candidate.fromJson(json);

      expect(candidate.candidateId, equals('cand-full'));
      expect(candidate.status, equals(CandidateStatus.ready));
      expect(candidate.resolutionState, equals(ResolutionState.partial));
      expect(candidate.fragmentIds, equals(['frag-1']));
      expect(candidate.evidenceIds, equals(['ev-1']));
      expect(candidate.fields['amount']!.value, equals(100.0));
      expect(candidate.fields['amount']!.confirmed, isTrue);
      expect(candidate.fields['amount']!.sourceFragmentId, equals('frag-1'));
      expect(candidate.links, hasLength(1));
      expect(candidate.links.first.entityId, equals('ent-1'));
      expect(candidate.links.first.role, equals('vendor'));
      expect(candidate.links.first.status, equals(LinkStatus.confirmed));
      expect(candidate.auditTrail, hasLength(1));
      expect(candidate.auditTrail.first.action, equals('create'));
      expect(candidate.auditTrail.first.sourceId, equals('src-1'));
      expect(candidate.auditTrail.first.changes, equals({'a': 'b'}));
      expect(candidate.auditTrail.first.reason, equals('initial'));
      expect(candidate.unresolvedIssues, hasLength(1));
      expect(candidate.unresolvedIssues.first.suggestion, equals('Verify'));
      expect(candidate.confirmedAt, equals(DateTime(2024, 1, 3)));
      expect(candidate.resultingIds, equals(['fact-1']));
      expect(candidate.metadata, equals({'src': 'test'}));
    });

    test('toJson excludes empty and null fields', () {
      final now = DateTime(2024, 1, 1);
      final candidate = Candidate(
        workspaceId: 'ws-1',
        candidateId: 'cand-min',
        objectType: 'task',
        confidence: 0.5,
        createdAt: now,
        updatedAt: now,
      );

      final json = candidate.toJson();

      expect(json.containsKey('fragmentIds'), isFalse);
      expect(json.containsKey('evidenceIds'), isFalse);
      expect(json.containsKey('fields'), isFalse);
      expect(json.containsKey('links'), isFalse);
      expect(json.containsKey('auditTrail'), isFalse);
      expect(json.containsKey('unresolvedIssues'), isFalse);
      expect(json.containsKey('confirmedAt'), isFalse);
      expect(json.containsKey('resultingIds'), isFalse);
      expect(json.containsKey('metadata'), isFalse);
    });

    test('toJson includes non-empty fields', () {
      final now = DateTime(2024, 1, 1);
      final candidate = Candidate(
        workspaceId: 'ws-1',
        candidateId: 'cand-full-json',
        objectType: 'expense',
        fragmentIds: ['frag-1'],
        evidenceIds: ['ev-1'],
        fields: {
          'amount': CandidateField(value: 50.0, confidence: 0.9),
        },
        links: [
          EntityLink(entityId: 'ent-1', role: 'vendor'),
        ],
        auditTrail: [
          AuditEntry(timestamp: now, action: 'create'),
        ],
        confidence: 0.9,
        unresolvedIssues: [
          UnresolvedIssue(code: 'X', type: IssueType.unknown, description: 'desc'),
        ],
        confirmedAt: now,
        resultingIds: ['fact-1'],
        metadata: {'k': 'v'},
        createdAt: now,
        updatedAt: now,
      );

      final json = candidate.toJson();

      expect(json['fragmentIds'], equals(['frag-1']));
      expect(json['evidenceIds'], equals(['ev-1']));
      expect(json['fields'], isA<Map>());
      expect(json['links'], isA<List>());
      expect(json['auditTrail'], isA<List>());
      expect(json['unresolvedIssues'], isA<List>());
      expect(json['confirmedAt'], equals(now.toIso8601String()));
      expect(json['resultingIds'], equals(['fact-1']));
      expect(json['metadata'], equals({'k': 'v'}));
    });

    test('fieldBag returns simple map of values', () {
      final now = DateTime.now();
      final candidate = Candidate(
        workspaceId: 'ws-1',
        candidateId: 'cand-fb',
        objectType: 'expense',
        fields: {
          'amount': CandidateField(value: 100.0, confidence: 0.9),
          'date': CandidateField(value: '2024-01-01', confidence: 0.8),
        },
        confidence: 0.85,
        createdAt: now,
        updatedAt: now,
      );

      final bag = candidate.fieldBag;
      expect(bag['amount'], equals(100.0));
      expect(bag['date'], equals('2024-01-01'));
    });

    test('copyWith creates modified copy', () {
      final now = DateTime.now();
      final original = Candidate(
        workspaceId: 'test-workspace',
        candidateId: 'cand-8',
        objectType: 'task',
        confidence: 0.7,
        createdAt: now,
        updatedAt: now,
      );

      final modified = original.copyWith(
        status: CandidateStatus.confirmed,
        confidence: 0.99,
        confirmedAt: now,
      );

      expect(original.status, equals(CandidateStatus.open));
      expect(modified.status, equals(CandidateStatus.confirmed));
      expect(modified.confidence, equals(0.99));
      expect(modified.confirmedAt, isNotNull);
    });

    test('copyWith all parameters', () {
      final now = DateTime(2024, 1, 1);
      final newDate = DateTime(2024, 6, 1);
      final original = Candidate(
        workspaceId: 'ws-1',
        candidateId: 'cand-orig',
        objectType: 'task',
        confidence: 0.5,
        createdAt: now,
        updatedAt: now,
      );

      final modified = original.copyWith(
        candidateId: 'cand-new',
        workspaceId: 'ws-2',
        objectType: 'expense',
        status: CandidateStatus.promoted,
        resolutionState: ResolutionState.resolved,
        fragmentIds: ['frag-new'],
        evidenceIds: ['ev-new'],
        fields: {'f': CandidateField(value: 1, confidence: 0.9)},
        links: [EntityLink(entityId: 'e-1', role: 'owner')],
        auditTrail: [AuditEntry(timestamp: newDate, action: 'update')],
        confidence: 0.99,
        unresolvedIssues: [],
        createdAt: newDate,
        updatedAt: newDate,
        confirmedAt: newDate,
        resultingIds: ['fact-new'],
        metadata: {'new': true},
      );

      expect(modified.candidateId, equals('cand-new'));
      expect(modified.workspaceId, equals('ws-2'));
      expect(modified.objectType, equals('expense'));
      expect(modified.status, equals(CandidateStatus.promoted));
      expect(modified.resolutionState, equals(ResolutionState.resolved));
      expect(modified.fragmentIds, equals(['frag-new']));
      expect(modified.evidenceIds, equals(['ev-new']));
      expect(modified.fields.containsKey('f'), isTrue);
      expect(modified.links, hasLength(1));
      expect(modified.auditTrail, hasLength(1));
      expect(modified.confidence, equals(0.99));
      expect(modified.unresolvedIssues, isEmpty);
      expect(modified.confirmedAt, equals(newDate));
      expect(modified.resultingIds, equals(['fact-new']));
      expect(modified.metadata, equals({'new': true}));
    });

    test('toString returns expected format', () {
      final now = DateTime.now();
      final candidate = Candidate(
        workspaceId: 'ws-1',
        candidateId: 'cand-str',
        objectType: 'expense',
        status: CandidateStatus.ready,
        confidence: 0.9,
        createdAt: now,
        updatedAt: now,
      );

      final str = candidate.toString();

      expect(str, contains('Candidate'));
      expect(str, contains('cand-str'));
      expect(str, contains('expense'));
      expect(str, contains('ready'));
    });

    test('equality based on candidateId', () {
      final now = DateTime.now();
      final cand1 = Candidate(
        workspaceId: 'test-workspace',
        candidateId: 'same-id',
        objectType: 'a',
        confidence: 0.5,
        createdAt: now,
        updatedAt: now,
      );
      final cand2 = Candidate(
        workspaceId: 'test-workspace',
        candidateId: 'same-id',
        objectType: 'b',
        confidence: 0.9,
        createdAt: now,
        updatedAt: now,
      );
      final cand3 = Candidate(
        workspaceId: 'test-workspace',
        candidateId: 'diff-id',
        objectType: 'a',
        confidence: 0.5,
        createdAt: now,
        updatedAt: now,
      );

      expect(cand1, equals(cand2));
      expect(cand1.hashCode, equals(cand2.hashCode));
      expect(cand1 == cand3, isFalse);
    });
  });

  group('CandidateStatus', () {
    test('fromString parses all values correctly', () {
      expect(CandidateStatus.fromString('open'), equals(CandidateStatus.open));
      expect(CandidateStatus.fromString('qualifying'), equals(CandidateStatus.qualifying));
      expect(CandidateStatus.fromString('ready'), equals(CandidateStatus.ready));
      expect(CandidateStatus.fromString('confirmed'), equals(CandidateStatus.confirmed));
      expect(CandidateStatus.fromString('rejected'), equals(CandidateStatus.rejected));
      expect(CandidateStatus.fromString('promoted'), equals(CandidateStatus.promoted));
      expect(CandidateStatus.fromString('orphaned'), equals(CandidateStatus.orphaned));
      expect(CandidateStatus.fromString('merged'), equals(CandidateStatus.merged));
    });

    test('fromString returns open for invalid', () {
      expect(CandidateStatus.fromString('invalid'), equals(CandidateStatus.open));
    });
  });

  group('ResolutionState', () {
    test('fromString parses all values correctly', () {
      expect(ResolutionState.fromString('unresolved'), equals(ResolutionState.unresolved));
      expect(ResolutionState.fromString('partial'), equals(ResolutionState.partial));
      expect(ResolutionState.fromString('resolved'), equals(ResolutionState.resolved));
    });

    test('fromString returns unresolved for invalid', () {
      expect(ResolutionState.fromString('invalid'), equals(ResolutionState.unresolved));
    });
  });

  group('CandidateField', () {
    test('creates field with required fields', () {
      final field = CandidateField(value: 'test', confidence: 0.9);

      expect(field.value, equals('test'));
      expect(field.confidence, equals(0.9));
      expect(field.sourceFragmentId, isNull);
      expect(field.confirmed, isFalse);
    });

    test('creates field with all fields', () {
      final field = CandidateField(
        value: 42,
        confidence: 0.95,
        sourceFragmentId: 'frag-1',
        confirmed: true,
      );

      expect(field.sourceFragmentId, equals('frag-1'));
      expect(field.confirmed, isTrue);
    });

    test('serializes and deserializes correctly', () {
      final original = CandidateField(
        value: {'nested': 'data'},
        confidence: 0.8,
        sourceFragmentId: 'frag-2',
      );

      final json = original.toJson();
      final restored = CandidateField.fromJson(json);

      expect(restored.confidence, equals(original.confidence));
      expect(restored.sourceFragmentId, equals(original.sourceFragmentId));
    });

    test('fromJson handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final field = CandidateField.fromJson(json);

      expect(field.value, isNull);
      expect(field.confidence, equals(0.0));
      expect(field.sourceFragmentId, isNull);
      expect(field.confirmed, isFalse);
    });

    test('toJson excludes null sourceFragmentId and unconfirmed', () {
      final field = CandidateField(value: 'test', confidence: 0.9);

      final json = field.toJson();

      expect(json.containsKey('sourceFragmentId'), isFalse);
      expect(json.containsKey('confirmed'), isFalse);
    });

    test('toJson includes sourceFragmentId and confirmed when set', () {
      final field = CandidateField(
        value: 'test',
        confidence: 0.9,
        sourceFragmentId: 'frag-1',
        confirmed: true,
      );

      final json = field.toJson();

      expect(json['sourceFragmentId'], equals('frag-1'));
      expect(json['confirmed'], isTrue);
    });
  });

  group('UnresolvedIssue', () {
    test('creates issue with required fields', () {
      final issue = UnresolvedIssue(
        code: 'MISSING_FIELD',
        type: IssueType.missingField,
        description: 'Amount field is required',
      );

      expect(issue.code, equals('MISSING_FIELD'));
      expect(issue.type, equals(IssueType.missingField));
      expect(issue.field, isNull);
      expect(issue.suggestion, isNull);
    });

    test('creates issue with all fields', () {
      final issue = UnresolvedIssue(
        code: 'LOW_CONFIDENCE',
        type: IssueType.lowConfidence,
        field: 'merchant',
        description: 'Confidence too low',
        suggestion: 'Manually verify merchant name',
      );

      expect(issue.field, equals('merchant'));
      expect(issue.suggestion, isNotNull);
    });

    test('serializes and deserializes correctly', () {
      final original = UnresolvedIssue(
        code: 'CONFLICT',
        type: IssueType.conflict,
        field: 'amount',
        description: 'Conflicting values',
      );

      final json = original.toJson();
      final restored = UnresolvedIssue.fromJson(json);

      expect(restored.code, equals(original.code));
      expect(restored.type, equals(original.type));
      expect(restored.field, equals(original.field));
    });

    test('fromJson handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final issue = UnresolvedIssue.fromJson(json);

      expect(issue.code, equals(''));
      expect(issue.type, equals(IssueType.unknown));
      expect(issue.field, isNull);
      expect(issue.description, equals(''));
      expect(issue.suggestion, isNull);
    });

    test('toJson excludes null field and suggestion', () {
      final issue = UnresolvedIssue(
        code: 'X',
        type: IssueType.unknown,
        description: 'desc',
      );

      final json = issue.toJson();

      expect(json.containsKey('field'), isFalse);
      expect(json.containsKey('suggestion'), isFalse);
    });

    test('toJson includes non-null field and suggestion', () {
      final issue = UnresolvedIssue(
        code: 'X',
        type: IssueType.lowConfidence,
        field: 'amount',
        description: 'desc',
        suggestion: 'fix it',
      );

      final json = issue.toJson();

      expect(json['field'], equals('amount'));
      expect(json['suggestion'], equals('fix it'));
    });
  });

  group('IssueType', () {
    test('fromString parses all values correctly', () {
      expect(IssueType.fromString('missingField'), equals(IssueType.missingField));
      expect(IssueType.fromString('lowConfidence'), equals(IssueType.lowConfidence));
      expect(IssueType.fromString('conflict'), equals(IssueType.conflict));
      expect(IssueType.fromString('entityUnresolved'), equals(IssueType.entityUnresolved));
      expect(IssueType.fromString('relationUnclear'), equals(IssueType.relationUnclear));
      expect(IssueType.fromString('policyViolation'), equals(IssueType.policyViolation));
      expect(IssueType.fromString('unknown'), equals(IssueType.unknown));
    });

    test('fromString returns unknown for invalid', () {
      expect(IssueType.fromString('invalid'), equals(IssueType.unknown));
    });
  });

  group('EntityLink', () {
    test('creates link with required fields', () {
      final link = EntityLink(entityId: 'ent-1', role: 'vendor');

      expect(link.entityId, equals('ent-1'));
      expect(link.role, equals('vendor'));
      expect(link.status, equals(LinkStatus.proposed));
    });

    test('creates link with all fields', () {
      final link = EntityLink(
        entityId: 'ent-1',
        role: 'owner',
        status: LinkStatus.confirmed,
      );

      expect(link.status, equals(LinkStatus.confirmed));
    });

    test('serializes and deserializes correctly', () {
      final original = EntityLink(
        entityId: 'ent-1',
        role: 'vendor',
        status: LinkStatus.confirmed,
      );

      final json = original.toJson();
      final restored = EntityLink.fromJson(json);

      expect(restored.entityId, equals(original.entityId));
      expect(restored.role, equals(original.role));
      expect(restored.status, equals(original.status));
    });

    test('fromJson handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final link = EntityLink.fromJson(json);

      expect(link.entityId, equals(''));
      expect(link.role, equals(''));
      expect(link.status, equals(LinkStatus.proposed));
    });
  });

  group('LinkStatus', () {
    test('fromString parses all values correctly', () {
      expect(LinkStatus.fromString('proposed'), equals(LinkStatus.proposed));
      expect(LinkStatus.fromString('confirmed'), equals(LinkStatus.confirmed));
    });

    test('fromString returns proposed for invalid', () {
      expect(LinkStatus.fromString('invalid'), equals(LinkStatus.proposed));
    });
  });

  group('AuditEntry', () {
    test('creates entry with required fields', () {
      final now = DateTime(2024, 1, 1);
      final entry = AuditEntry(timestamp: now, action: 'create');

      expect(entry.timestamp, equals(now));
      expect(entry.action, equals('create'));
      expect(entry.sourceId, isNull);
      expect(entry.changes, isNull);
      expect(entry.reason, isNull);
    });

    test('creates entry with all fields', () {
      final now = DateTime(2024, 1, 1);
      final entry = AuditEntry(
        timestamp: now,
        action: 'merge',
        sourceId: 'cand-other',
        changes: {'field': 'updated'},
        reason: 'Duplicate found',
      );

      expect(entry.sourceId, equals('cand-other'));
      expect(entry.changes, equals({'field': 'updated'}));
      expect(entry.reason, equals('Duplicate found'));
    });

    test('serializes and deserializes correctly', () {
      final now = DateTime(2024, 1, 1);
      final original = AuditEntry(
        timestamp: now,
        action: 'update',
        sourceId: 'src-1',
        changes: {'amount': 100},
        reason: 'Correction',
      );

      final json = original.toJson();
      final restored = AuditEntry.fromJson(json);

      expect(restored.action, equals(original.action));
      expect(restored.sourceId, equals(original.sourceId));
      expect(restored.changes, equals(original.changes));
      expect(restored.reason, equals(original.reason));
    });

    test('fromJson handles missing fields', () {
      final json = <String, dynamic>{};

      final entry = AuditEntry.fromJson(json);

      expect(entry.action, equals(''));
      expect(entry.sourceId, isNull);
      expect(entry.changes, isNull);
      expect(entry.reason, isNull);
    });

    test('toJson excludes null fields', () {
      final now = DateTime(2024, 1, 1);
      final entry = AuditEntry(timestamp: now, action: 'create');

      final json = entry.toJson();

      expect(json.containsKey('sourceId'), isFalse);
      expect(json.containsKey('changes'), isFalse);
      expect(json.containsKey('reason'), isFalse);
    });

    test('toJson includes non-null fields', () {
      final now = DateTime(2024, 1, 1);
      final entry = AuditEntry(
        timestamp: now,
        action: 'update',
        sourceId: 'src-1',
        changes: {'a': 1},
        reason: 'reason',
      );

      final json = entry.toJson();

      expect(json['sourceId'], equals('src-1'));
      expect(json['changes'], equals({'a': 1}));
      expect(json['reason'], equals('reason'));
    });
  });

  // =========================================================================
  // Additional coverage tests
  // =========================================================================
  group('Candidate additional coverage', () {
    test('constructor with all fields including confirmedAt and resultingIds', () {
      final now = DateTime(2024, 1, 1);
      final confirmed = DateTime(2024, 1, 5);
      final candidate = Candidate(
        candidateId: 'cand-all',
        workspaceId: 'ws-1',
        objectType: 'expense',
        status: CandidateStatus.confirmed,
        resolutionState: ResolutionState.resolved,
        fragmentIds: ['frag-1', 'frag-2'],
        evidenceIds: ['ev-1'],
        fields: {
          'amount': CandidateField(
            value: 100.0,
            confidence: 0.95,
            sourceFragmentId: 'frag-1',
            confirmed: true,
          ),
          'date': CandidateField(value: '2024-01-01', confidence: 0.9),
        },
        links: [
          EntityLink(entityId: 'ent-1', role: 'vendor', status: LinkStatus.confirmed),
          EntityLink(entityId: 'ent-2', role: 'owner'),
        ],
        auditTrail: [
          AuditEntry(
            timestamp: now,
            action: 'create',
            sourceId: 'src-1',
            changes: {'initial': true},
            reason: 'First creation',
          ),
        ],
        confidence: 0.92,
        unresolvedIssues: [
          UnresolvedIssue(
            code: 'REVIEW',
            type: IssueType.policyViolation,
            field: 'category',
            description: 'Category needs review',
            suggestion: 'Check policy',
          ),
        ],
        createdAt: now,
        updatedAt: now,
        confirmedAt: confirmed,
        resultingIds: ['fact-1', 'fact-2'],
        metadata: {'source': 'manual'},
      );

      expect(candidate.candidateId, equals('cand-all'));
      expect(candidate.status, equals(CandidateStatus.confirmed));
      expect(candidate.resolutionState, equals(ResolutionState.resolved));
      expect(candidate.fragmentIds, equals(['frag-1', 'frag-2']));
      expect(candidate.evidenceIds, equals(['ev-1']));
      expect(candidate.fields, hasLength(2));
      expect(candidate.fields['amount']!.sourceFragmentId, equals('frag-1'));
      expect(candidate.fields['amount']!.confirmed, isTrue);
      expect(candidate.links, hasLength(2));
      expect(candidate.auditTrail, hasLength(1));
      expect(candidate.unresolvedIssues, hasLength(1));
      expect(candidate.confirmedAt, equals(confirmed));
      expect(candidate.resultingIds, equals(['fact-1', 'fact-2']));
      expect(candidate.metadata, equals({'source': 'manual'}));
    });

    test('equality with identical reference', () {
      final now = DateTime.now();
      final candidate = Candidate(
        candidateId: 'cand-self',
        workspaceId: 'ws-1',
        objectType: 'task',
        confidence: 0.5,
        createdAt: now,
        updatedAt: now,
      );

      expect(candidate == candidate, isTrue);
    });

    test('equality with non-Candidate object', () {
      final now = DateTime.now();
      final candidate = Candidate(
        candidateId: 'cand-type',
        workspaceId: 'ws-1',
        objectType: 'task',
        confidence: 0.5,
        createdAt: now,
        updatedAt: now,
      );

      expect(candidate == Object(), isFalse);
    });

    test('hashCode is based on candidateId', () {
      final now = DateTime.now();
      final candidate = Candidate(
        candidateId: 'cand-hash',
        workspaceId: 'ws-1',
        objectType: 'task',
        confidence: 0.5,
        createdAt: now,
        updatedAt: now,
      );

      expect(candidate.hashCode, equals('cand-hash'.hashCode));
    });

    test('copyWith preserves all fields when no arguments', () {
      final now = DateTime(2024, 1, 1);
      final original = Candidate(
        candidateId: 'cand-no-change',
        workspaceId: 'ws-1',
        objectType: 'task',
        status: CandidateStatus.ready,
        resolutionState: ResolutionState.partial,
        fragmentIds: ['frag-1'],
        evidenceIds: ['ev-1'],
        fields: {'f': CandidateField(value: 1, confidence: 0.9)},
        links: [EntityLink(entityId: 'e-1', role: 'owner')],
        auditTrail: [AuditEntry(timestamp: now, action: 'create')],
        confidence: 0.8,
        unresolvedIssues: [
          UnresolvedIssue(code: 'X', type: IssueType.unknown, description: 'desc'),
        ],
        createdAt: now,
        updatedAt: now,
        confirmedAt: now,
        resultingIds: ['fact-1'],
        metadata: {'k': 'v'},
      );

      final copy = original.copyWith();

      expect(copy.candidateId, equals(original.candidateId));
      expect(copy.workspaceId, equals(original.workspaceId));
      expect(copy.objectType, equals(original.objectType));
      expect(copy.status, equals(original.status));
      expect(copy.resolutionState, equals(original.resolutionState));
      expect(copy.fragmentIds, equals(original.fragmentIds));
      expect(copy.evidenceIds, equals(original.evidenceIds));
      expect(copy.fields.length, equals(original.fields.length));
      expect(copy.links.length, equals(original.links.length));
      expect(copy.auditTrail.length, equals(original.auditTrail.length));
      expect(copy.confidence, equals(original.confidence));
      expect(copy.unresolvedIssues.length, equals(original.unresolvedIssues.length));
      expect(copy.createdAt, equals(original.createdAt));
      expect(copy.updatedAt, equals(original.updatedAt));
      expect(copy.confirmedAt, equals(original.confirmedAt));
      expect(copy.resultingIds, equals(original.resultingIds));
      expect(copy.metadata, equals(original.metadata));
    });

    test('toJson full roundtrip', () {
      final now = DateTime(2024, 1, 1);
      final candidate = Candidate(
        candidateId: 'cand-rt',
        workspaceId: 'ws-1',
        objectType: 'expense',
        status: CandidateStatus.qualifying,
        resolutionState: ResolutionState.partial,
        fragmentIds: ['frag-1'],
        evidenceIds: ['ev-1'],
        fields: {
          'amount': CandidateField(
            value: 50.0,
            confidence: 0.9,
            sourceFragmentId: 'frag-1',
            confirmed: true,
          ),
        },
        links: [
          EntityLink(entityId: 'ent-1', role: 'vendor', status: LinkStatus.confirmed),
        ],
        auditTrail: [
          AuditEntry(
            timestamp: now,
            action: 'merge',
            sourceId: 'cand-other',
            changes: {'merged': true},
            reason: 'Duplicate',
          ),
        ],
        confidence: 0.85,
        unresolvedIssues: [
          UnresolvedIssue(
            code: 'LOW',
            type: IssueType.lowConfidence,
            field: 'merchant',
            description: 'Low conf',
            suggestion: 'Verify',
          ),
        ],
        createdAt: now,
        updatedAt: now,
        confirmedAt: now,
        resultingIds: ['fact-1'],
        metadata: {'src': 'test'},
      );

      final json = candidate.toJson();
      final restored = Candidate.fromJson(json);

      expect(restored.candidateId, equals(candidate.candidateId));
      expect(restored.status, equals(candidate.status));
      expect(restored.resolutionState, equals(candidate.resolutionState));
      expect(restored.fragmentIds, equals(candidate.fragmentIds));
      expect(restored.evidenceIds, equals(candidate.evidenceIds));
      expect(restored.fields['amount']!.value, equals(50.0));
      expect(restored.fields['amount']!.sourceFragmentId, equals('frag-1'));
      expect(restored.fields['amount']!.confirmed, isTrue);
      expect(restored.links, hasLength(1));
      expect(restored.links.first.status, equals(LinkStatus.confirmed));
      expect(restored.auditTrail, hasLength(1));
      expect(restored.auditTrail.first.sourceId, equals('cand-other'));
      expect(restored.auditTrail.first.changes, equals({'merged': true}));
      expect(restored.auditTrail.first.reason, equals('Duplicate'));
      expect(restored.unresolvedIssues, hasLength(1));
      expect(restored.unresolvedIssues.first.suggestion, equals('Verify'));
      expect(restored.confirmedAt, isNotNull);
      expect(restored.resultingIds, equals(['fact-1']));
      expect(restored.metadata, equals({'src': 'test'}));
    });

    test('isReadyForConfirmation with rejected status', () {
      final now = DateTime.now();
      final rejected = Candidate(
        candidateId: 'cand-rej',
        workspaceId: 'ws-1',
        objectType: 'task',
        status: CandidateStatus.rejected,
        confidence: 0.9,
        createdAt: now,
        updatedAt: now,
      );

      expect(rejected.isReadyForConfirmation, isFalse);
    });
  });

  group('CandidateField additional', () {
    test('toJson with confirmed false does not include confirmed key', () {
      final field = CandidateField(
        value: 'test',
        confidence: 0.9,
        sourceFragmentId: 'frag-1',
        confirmed: false,
      );

      final json = field.toJson();

      expect(json['value'], equals('test'));
      expect(json['confidence'], equals(0.9));
      expect(json['sourceFragmentId'], equals('frag-1'));
      expect(json.containsKey('confirmed'), isFalse);
    });
  });

  group('UnresolvedIssue additional', () {
    test('fromJson with all fields', () {
      final json = {
        'code': 'ENTITY_UNRESOLVED',
        'type': 'entityUnresolved',
        'field': 'owner',
        'description': 'Owner entity not resolved',
        'suggestion': 'Create or link entity',
      };

      final issue = UnresolvedIssue.fromJson(json);

      expect(issue.code, equals('ENTITY_UNRESOLVED'));
      expect(issue.type, equals(IssueType.entityUnresolved));
      expect(issue.field, equals('owner'));
      expect(issue.description, equals('Owner entity not resolved'));
      expect(issue.suggestion, equals('Create or link entity'));
    });
  });

  group('EntityLink additional', () {
    test('toJson always includes status', () {
      final link = EntityLink(entityId: 'ent-1', role: 'vendor');
      final json = link.toJson();

      expect(json['entityId'], equals('ent-1'));
      expect(json['role'], equals('vendor'));
      expect(json['status'], equals('proposed'));
    });
  });

  group('AuditEntry additional', () {
    test('fromJson with all fields', () {
      final json = {
        'timestamp': '2024-06-15T10:00:00.000',
        'action': 'split',
        'sourceId': 'cand-src',
        'changes': {'split_into': ['cand-a', 'cand-b']},
        'reason': 'Multiple entities detected',
      };

      final entry = AuditEntry.fromJson(json);

      expect(entry.timestamp, equals(DateTime(2024, 6, 15, 10)));
      expect(entry.action, equals('split'));
      expect(entry.sourceId, equals('cand-src'));
      expect(entry.changes, isNotNull);
      expect(entry.reason, equals('Multiple entities detected'));
    });
  });

  group('IssueType additional', () {
    test('all values exist', () {
      expect(IssueType.values, contains(IssueType.missingField));
      expect(IssueType.values, contains(IssueType.lowConfidence));
      expect(IssueType.values, contains(IssueType.conflict));
      expect(IssueType.values, contains(IssueType.entityUnresolved));
      expect(IssueType.values, contains(IssueType.relationUnclear));
      expect(IssueType.values, contains(IssueType.policyViolation));
      expect(IssueType.values, contains(IssueType.unknown));
      expect(IssueType.values.length, equals(7));
    });

    test('fromString parses all remaining values', () {
      expect(IssueType.fromString('relationUnclear'), equals(IssueType.relationUnclear));
      expect(IssueType.fromString('policyViolation'), equals(IssueType.policyViolation));
    });
  });

  group('CandidateStatus additional', () {
    test('all values exist', () {
      expect(CandidateStatus.values.length, equals(8));
    });
  });

  group('ResolutionState additional', () {
    test('all values exist', () {
      expect(ResolutionState.values.length, equals(3));
    });
  });

  group('LinkStatus additional', () {
    test('all values exist', () {
      expect(LinkStatus.values.length, equals(2));
    });
  });
}
