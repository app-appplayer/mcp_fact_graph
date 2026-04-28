import 'package:test/test.dart';
import 'package:mcp_fact_graph/mcp_fact_graph.dart';

void main() {
  // =========================================================================
  // ValidationResult enum
  // =========================================================================
  group('ValidationResult', () {
    test('has all expected values', () {
      expect(ValidationResult.values, contains(ValidationResult.passed));
      expect(ValidationResult.values, contains(ValidationResult.failed));
      expect(ValidationResult.values, contains(ValidationResult.needsReview));
      expect(ValidationResult.values.length, equals(3));
    });

    test('fromString returns correct value for all variants', () {
      expect(ValidationResult.fromString('passed'),
          equals(ValidationResult.passed));
      expect(ValidationResult.fromString('failed'),
          equals(ValidationResult.failed));
      expect(ValidationResult.fromString('needsReview'),
          equals(ValidationResult.needsReview));
    });

    test('fromString returns needsReview for invalid values', () {
      expect(ValidationResult.fromString('unknown'),
          equals(ValidationResult.needsReview));
      expect(
          ValidationResult.fromString(''), equals(ValidationResult.needsReview));
      expect(ValidationResult.fromString('PASSED'),
          equals(ValidationResult.needsReview));
    });
  });

  // =========================================================================
  // ValidationIssueType enum
  // =========================================================================
  group('ValidationIssueType', () {
    test('has all expected values', () {
      expect(ValidationIssueType.values,
          contains(ValidationIssueType.missingEvidence));
      expect(ValidationIssueType.values,
          contains(ValidationIssueType.contradiction));
      expect(ValidationIssueType.values,
          contains(ValidationIssueType.hallucination));
      expect(
          ValidationIssueType.values, contains(ValidationIssueType.outdated));
      expect(ValidationIssueType.values,
          contains(ValidationIssueType.policyViolation));
      expect(ValidationIssueType.values.length, equals(5));
    });

    test('fromString returns correct value for all variants', () {
      expect(ValidationIssueType.fromString('missingEvidence'),
          equals(ValidationIssueType.missingEvidence));
      expect(ValidationIssueType.fromString('contradiction'),
          equals(ValidationIssueType.contradiction));
      expect(ValidationIssueType.fromString('hallucination'),
          equals(ValidationIssueType.hallucination));
      expect(ValidationIssueType.fromString('outdated'),
          equals(ValidationIssueType.outdated));
      expect(ValidationIssueType.fromString('policyViolation'),
          equals(ValidationIssueType.policyViolation));
    });

    test('fromString returns missingEvidence for invalid values', () {
      expect(ValidationIssueType.fromString('unknown'),
          equals(ValidationIssueType.missingEvidence));
      expect(ValidationIssueType.fromString(''),
          equals(ValidationIssueType.missingEvidence));
    });
  });

  // =========================================================================
  // IssueSeverity enum
  // =========================================================================
  group('IssueSeverity', () {
    test('has all expected values', () {
      expect(IssueSeverity.values, contains(IssueSeverity.error));
      expect(IssueSeverity.values, contains(IssueSeverity.warning));
      expect(IssueSeverity.values, contains(IssueSeverity.info));
      expect(IssueSeverity.values.length, equals(3));
    });

    test('fromString returns correct value for all variants', () {
      expect(IssueSeverity.fromString('error'), equals(IssueSeverity.error));
      expect(
          IssueSeverity.fromString('warning'), equals(IssueSeverity.warning));
      expect(IssueSeverity.fromString('info'), equals(IssueSeverity.info));
    });

    test('fromString returns warning for invalid values', () {
      expect(
          IssueSeverity.fromString('unknown'), equals(IssueSeverity.warning));
      expect(IssueSeverity.fromString(''), equals(IssueSeverity.warning));
    });
  });

  // =========================================================================
  // ValidationIssue class
  // =========================================================================
  group('ValidationIssue', () {
    test('constructor with required fields only', () {
      const issue = ValidationIssue(
        issueId: 'iss-1',
        issueType: ValidationIssueType.contradiction,
        description: 'Conflicting dates found',
      );

      expect(issue.issueId, equals('iss-1'));
      expect(issue.issueType, equals(ValidationIssueType.contradiction));
      expect(issue.severity, equals(IssueSeverity.warning));
      expect(issue.description, equals('Conflicting dates found'));
      expect(issue.relatedClaimIds, isEmpty);
      expect(issue.suggestedAction, isNull);
    });

    test('constructor with all fields', () {
      const issue = ValidationIssue(
        issueId: 'iss-2',
        issueType: ValidationIssueType.hallucination,
        severity: IssueSeverity.error,
        description: 'No supporting evidence',
        relatedClaimIds: ['claim-1', 'claim-2'],
        suggestedAction: 'Remove claim from response',
      );

      expect(issue.issueId, equals('iss-2'));
      expect(issue.issueType, equals(ValidationIssueType.hallucination));
      expect(issue.severity, equals(IssueSeverity.error));
      expect(issue.description, equals('No supporting evidence'));
      expect(issue.relatedClaimIds, equals(['claim-1', 'claim-2']));
      expect(issue.suggestedAction, equals('Remove claim from response'));
    });

    test('fromJson complete', () {
      final json = {
        'issueId': 'iss-3',
        'issueType': 'outdated',
        'severity': 'info',
        'description': 'Data is stale',
        'relatedClaimIds': ['c-1'],
        'suggestedAction': 'Refresh data',
      };

      final issue = ValidationIssue.fromJson(json);

      expect(issue.issueId, equals('iss-3'));
      expect(issue.issueType, equals(ValidationIssueType.outdated));
      expect(issue.severity, equals(IssueSeverity.info));
      expect(issue.description, equals('Data is stale'));
      expect(issue.relatedClaimIds, equals(['c-1']));
      expect(issue.suggestedAction, equals('Refresh data'));
    });

    test('fromJson empty/missing fields uses defaults', () {
      final json = <String, dynamic>{};

      final issue = ValidationIssue.fromJson(json);

      expect(issue.issueId, equals(''));
      expect(issue.issueType, equals(ValidationIssueType.missingEvidence));
      expect(issue.severity, equals(IssueSeverity.warning));
      expect(issue.description, equals(''));
      expect(issue.relatedClaimIds, isEmpty);
      expect(issue.suggestedAction, isNull);
    });

    test('toJson populated', () {
      const issue = ValidationIssue(
        issueId: 'iss-4',
        issueType: ValidationIssueType.policyViolation,
        severity: IssueSeverity.error,
        description: 'Policy breach detected',
        relatedClaimIds: ['c-10', 'c-20'],
        suggestedAction: 'Apply policy filter',
      );

      final json = issue.toJson();

      expect(json['issueId'], equals('iss-4'));
      expect(json['issueType'], equals('policyViolation'));
      expect(json['severity'], equals('error'));
      expect(json['description'], equals('Policy breach detected'));
      expect(json['relatedClaimIds'], equals(['c-10', 'c-20']));
      expect(json['suggestedAction'], equals('Apply policy filter'));
    });

    test('toJson excludes empty/null fields', () {
      const issue = ValidationIssue(
        issueId: 'iss-5',
        issueType: ValidationIssueType.missingEvidence,
        description: 'Minimal issue',
      );

      final json = issue.toJson();

      expect(json.containsKey('relatedClaimIds'), isFalse);
      expect(json.containsKey('suggestedAction'), isFalse);
      expect(json.containsKey('issueId'), isTrue);
      expect(json.containsKey('issueType'), isTrue);
      expect(json.containsKey('severity'), isTrue);
      expect(json.containsKey('description'), isTrue);
    });

    test('copyWith modifies specified fields', () {
      const original = ValidationIssue(
        issueId: 'iss-6',
        issueType: ValidationIssueType.contradiction,
        description: 'Original description',
      );

      final copy = original.copyWith(
        issueType: ValidationIssueType.hallucination,
        severity: IssueSeverity.error,
        description: 'Updated description',
        relatedClaimIds: ['new-claim'],
        suggestedAction: 'Review manually',
      );

      // Unchanged
      expect(copy.issueId, equals('iss-6'));

      // Changed
      expect(copy.issueType, equals(ValidationIssueType.hallucination));
      expect(copy.severity, equals(IssueSeverity.error));
      expect(copy.description, equals('Updated description'));
      expect(copy.relatedClaimIds, equals(['new-claim']));
      expect(copy.suggestedAction, equals('Review manually'));
    });

    test('copyWith with no arguments returns equivalent issue', () {
      const original = ValidationIssue(
        issueId: 'iss-7',
        issueType: ValidationIssueType.outdated,
        severity: IssueSeverity.info,
        description: 'No change test',
      );

      final copy = original.copyWith();

      expect(copy.issueId, equals(original.issueId));
      expect(copy.issueType, equals(original.issueType));
      expect(copy.severity, equals(original.severity));
      expect(copy.description, equals(original.description));
    });

    test('toString returns expected format', () {
      const issue = ValidationIssue(
        issueId: 'iss-str',
        issueType: ValidationIssueType.contradiction,
        severity: IssueSeverity.error,
        description: 'Test',
      );

      expect(issue.toString(),
          equals('ValidationIssue(iss-str, ValidationIssueType.contradiction, IssueSeverity.error)'));
    });

    test('equality compares by issueId', () {
      const issue1 = ValidationIssue(
        issueId: 'iss-eq',
        issueType: ValidationIssueType.contradiction,
        description: 'Issue A',
      );

      const issue2 = ValidationIssue(
        issueId: 'iss-eq',
        issueType: ValidationIssueType.hallucination,
        description: 'Issue B',
      );

      const issue3 = ValidationIssue(
        issueId: 'iss-different',
        issueType: ValidationIssueType.contradiction,
        description: 'Issue A',
      );

      expect(issue1 == issue2, isTrue);
      expect(issue1 == issue3, isFalse);
      expect(issue1.hashCode, equals(issue2.hashCode));
    });

    test('equality with identical reference', () {
      const issue = ValidationIssue(
        issueId: 'iss-id',
        issueType: ValidationIssueType.outdated,
        description: 'Self',
      );

      expect(issue == issue, isTrue);
    });

    test('equality with non-ValidationIssue object', () {
      const issue = ValidationIssue(
        issueId: 'iss-id',
        issueType: ValidationIssueType.outdated,
        description: 'Type check',
      );

      expect(issue == Object(), isFalse);
    });
  });

  // =========================================================================
  // ResponseValidation entity
  // =========================================================================
  group('ResponseValidation', () {
    final now = DateTime(2024, 6, 15, 10, 0, 0);
    final later = DateTime(2024, 7, 15, 10, 0, 0);

    test('constructor with required fields only', () {
      final rv = ResponseValidation(
        validationId: 'rv-1',
        workspaceId: 'ws-1',
        originalResponse: 'The company was founded in 2020.',
        policyVersion: '1.0.0',
        asOf: now,
        createdAt: now,
      );

      expect(rv.validationId, equals('rv-1'));
      expect(rv.workspaceId, equals('ws-1'));
      expect(rv.originalResponse, equals('The company was founded in 2020.'));
      expect(rv.extractedClaims, isEmpty);
      expect(rv.issues, isEmpty);
      expect(rv.result, equals(ValidationResult.needsReview));
      expect(rv.sanitizedResponse, isNull);
      expect(rv.policyVersion, equals('1.0.0'));
      expect(rv.asOf, equals(now));
      expect(rv.createdAt, equals(now));
      expect(rv.durationMs, equals(0));
      expect(rv.metadata, isEmpty);
    });

    test('constructor with all fields', () {
      final claim = VerifiableClaim(
        claimId: 'vc-1',
        workspaceId: 'ws-1',
        statement: 'Founded in 2020',
        verificationStatus: ClaimStatus.supported,
        createdAt: now,
      );

      const issue = ValidationIssue(
        issueId: 'iss-1',
        issueType: ValidationIssueType.outdated,
        severity: IssueSeverity.warning,
        description: 'Data might be stale',
      );

      final rv = ResponseValidation(
        validationId: 'rv-2',
        workspaceId: 'ws-2',
        originalResponse: 'Full response text',
        extractedClaims: [claim],
        issues: [issue],
        result: ValidationResult.passed,
        sanitizedResponse: 'Sanitized response text',
        policyVersion: '2.0.0',
        asOf: now,
        createdAt: now,
        durationMs: 150,
        metadata: {'model': 'gpt-4'},
      );

      expect(rv.extractedClaims.length, equals(1));
      expect(rv.issues.length, equals(1));
      expect(rv.result, equals(ValidationResult.passed));
      expect(rv.sanitizedResponse, equals('Sanitized response text'));
      expect(rv.durationMs, equals(150));
      expect(rv.metadata, equals({'model': 'gpt-4'}));
    });

    test('fromJson complete', () {
      final json = {
        'validationId': 'rv-3',
        'workspaceId': 'ws-3',
        'originalResponse': 'JSON response',
        'extractedClaims': [
          {
            'claimId': 'vc-1',
            'workspaceId': 'ws-1',
            'statement': 'Claim text',
            'claimType': 'fact',
            'verificationStatus': 'supported',
            'createdAt': '2024-06-15T10:00:00.000',
          }
        ],
        'issues': [
          {
            'issueId': 'iss-1',
            'issueType': 'hallucination',
            'severity': 'error',
            'description': 'Hallucinated content',
          }
        ],
        'result': 'failed',
        'sanitizedResponse': 'Clean response',
        'policyVersion': '3.0.0',
        'asOf': '2024-06-15T10:00:00.000',
        'createdAt': '2024-06-15T10:00:00.000',
        'durationMs': 250,
        'metadata': {'key': 'val'},
      };

      final rv = ResponseValidation.fromJson(json);

      expect(rv.validationId, equals('rv-3'));
      expect(rv.workspaceId, equals('ws-3'));
      expect(rv.originalResponse, equals('JSON response'));
      expect(rv.extractedClaims.length, equals(1));
      expect(rv.extractedClaims.first.claimId, equals('vc-1'));
      expect(rv.extractedClaims.first.verificationStatus,
          equals(ClaimStatus.supported));
      expect(rv.issues.length, equals(1));
      expect(rv.issues.first.issueType,
          equals(ValidationIssueType.hallucination));
      expect(rv.result, equals(ValidationResult.failed));
      expect(rv.sanitizedResponse, equals('Clean response'));
      expect(rv.policyVersion, equals('3.0.0'));
      expect(rv.durationMs, equals(250));
      expect(rv.metadata, equals({'key': 'val'}));
    });

    test('fromJson empty/missing fields uses defaults', () {
      final json = <String, dynamic>{};

      final rv = ResponseValidation.fromJson(json);

      expect(rv.validationId, equals(''));
      expect(rv.workspaceId, equals('default'));
      expect(rv.originalResponse, equals(''));
      expect(rv.extractedClaims, isEmpty);
      expect(rv.issues, isEmpty);
      expect(rv.result, equals(ValidationResult.needsReview));
      expect(rv.sanitizedResponse, isNull);
      expect(rv.policyVersion, equals(''));
      expect(rv.durationMs, equals(0));
      expect(rv.metadata, isEmpty);
    });

    test('toJson populated', () {
      final claim = VerifiableClaim(
        claimId: 'vc-1',
        workspaceId: 'ws-1',
        statement: 'Test claim',
        createdAt: now,
      );

      const issue = ValidationIssue(
        issueId: 'iss-1',
        issueType: ValidationIssueType.missingEvidence,
        description: 'No evidence',
      );

      final rv = ResponseValidation(
        validationId: 'rv-tj',
        workspaceId: 'ws-tj',
        originalResponse: 'Test response',
        extractedClaims: [claim],
        issues: [issue],
        result: ValidationResult.failed,
        sanitizedResponse: 'Sanitized test',
        policyVersion: '1.0.0',
        asOf: now,
        createdAt: now,
        durationMs: 100,
        metadata: {'source': 'test'},
      );

      final json = rv.toJson();

      expect(json['validationId'], equals('rv-tj'));
      expect(json['workspaceId'], equals('ws-tj'));
      expect(json['originalResponse'], equals('Test response'));
      expect(json['extractedClaims'], isA<List>());
      expect((json['extractedClaims'] as List).length, equals(1));
      expect(json['issues'], isA<List>());
      expect((json['issues'] as List).length, equals(1));
      expect(json['result'], equals('failed'));
      expect(json['sanitizedResponse'], equals('Sanitized test'));
      expect(json['policyVersion'], equals('1.0.0'));
      expect(json['asOf'], equals(now.toIso8601String()));
      expect(json['createdAt'], equals(now.toIso8601String()));
      expect(json['durationMs'], equals(100));
      expect(json['metadata'], equals({'source': 'test'}));
    });

    test('toJson excludes empty/null fields', () {
      final rv = ResponseValidation(
        validationId: 'rv-min',
        workspaceId: 'ws-min',
        originalResponse: 'Minimal response',
        policyVersion: '1.0.0',
        asOf: now,
        createdAt: now,
      );

      final json = rv.toJson();

      expect(json.containsKey('extractedClaims'), isFalse);
      expect(json.containsKey('issues'), isFalse);
      expect(json.containsKey('sanitizedResponse'), isFalse);
      expect(json.containsKey('metadata'), isFalse);
      // Always present
      expect(json.containsKey('validationId'), isTrue);
      expect(json.containsKey('workspaceId'), isTrue);
      expect(json.containsKey('originalResponse'), isTrue);
      expect(json.containsKey('result'), isTrue);
      expect(json.containsKey('policyVersion'), isTrue);
      expect(json.containsKey('asOf'), isTrue);
      expect(json.containsKey('createdAt'), isTrue);
      expect(json.containsKey('durationMs'), isTrue);
    });

    test('copyWith modifies specified fields', () {
      final original = ResponseValidation(
        validationId: 'rv-cw',
        workspaceId: 'ws-cw',
        originalResponse: 'Original response',
        policyVersion: '1.0.0',
        asOf: now,
        createdAt: now,
      );

      final copy = original.copyWith(
        result: ValidationResult.passed,
        sanitizedResponse: 'Updated sanitized',
        durationMs: 500,
        metadata: {'changed': true},
      );

      // Unchanged
      expect(copy.validationId, equals('rv-cw'));
      expect(copy.workspaceId, equals('ws-cw'));
      expect(copy.originalResponse, equals('Original response'));
      expect(copy.policyVersion, equals('1.0.0'));

      // Changed
      expect(copy.result, equals(ValidationResult.passed));
      expect(copy.sanitizedResponse, equals('Updated sanitized'));
      expect(copy.durationMs, equals(500));
      expect(copy.metadata, equals({'changed': true}));
    });

    test('copyWith preserves result, sanitizedResponse, durationMs, metadata when not specified', () {
      final rv = ResponseValidation(
        validationId: 'rv-preserve',
        workspaceId: 'ws-1',
        originalResponse: 'Original',
        result: ValidationResult.failed,
        sanitizedResponse: 'Sanitized text',
        policyVersion: '1.0.0',
        asOf: now,
        createdAt: now,
        durationMs: 250,
        metadata: {'key': 'value'},
      );

      // Change only workspaceId, preserving result, sanitizedResponse, durationMs, metadata
      final copy = rv.copyWith(workspaceId: 'ws-2');

      expect(copy.workspaceId, equals('ws-2'));
      expect(copy.result, equals(ValidationResult.failed));
      expect(copy.sanitizedResponse, equals('Sanitized text'));
      expect(copy.durationMs, equals(250));
      expect(copy.metadata, equals({'key': 'value'}));
    });

    test('copyWith all parameters', () {
      final claim = VerifiableClaim(
        claimId: 'vc-cw',
        workspaceId: 'ws-1',
        statement: 'CW claim',
        createdAt: now,
      );
      const issue = ValidationIssue(
        issueId: 'iss-cw',
        issueType: ValidationIssueType.hallucination,
        description: 'CW issue',
      );

      final original = ResponseValidation(
        validationId: 'rv-orig',
        workspaceId: 'ws-1',
        originalResponse: 'Orig response',
        policyVersion: '1.0.0',
        asOf: now,
        createdAt: now,
      );

      final copy = original.copyWith(
        validationId: 'rv-new',
        workspaceId: 'ws-new',
        originalResponse: 'New response',
        extractedClaims: [claim],
        issues: [issue],
        result: ValidationResult.passed,
        sanitizedResponse: 'New sanitized',
        policyVersion: '2.0.0',
        asOf: later,
        createdAt: later,
        durationMs: 999,
        metadata: {'all': true},
      );

      expect(copy.validationId, equals('rv-new'));
      expect(copy.workspaceId, equals('ws-new'));
      expect(copy.originalResponse, equals('New response'));
      expect(copy.extractedClaims.length, equals(1));
      expect(copy.issues.length, equals(1));
      expect(copy.result, equals(ValidationResult.passed));
      expect(copy.sanitizedResponse, equals('New sanitized'));
      expect(copy.policyVersion, equals('2.0.0'));
      expect(copy.asOf, equals(later));
      expect(copy.createdAt, equals(later));
      expect(copy.durationMs, equals(999));
      expect(copy.metadata, equals({'all': true}));
    });

    test('isPassed getter', () {
      final passed = ResponseValidation(
        validationId: 'rv-p',
        workspaceId: 'ws-1',
        originalResponse: 'Test',
        result: ValidationResult.passed,
        policyVersion: '1.0.0',
        asOf: now,
        createdAt: now,
      );

      final failed = ResponseValidation(
        validationId: 'rv-f',
        workspaceId: 'ws-1',
        originalResponse: 'Test',
        result: ValidationResult.failed,
        policyVersion: '1.0.0',
        asOf: now,
        createdAt: now,
      );

      expect(passed.isPassed, isTrue);
      expect(failed.isPassed, isFalse);
    });

    test('isFailed getter', () {
      final failed = ResponseValidation(
        validationId: 'rv-f',
        workspaceId: 'ws-1',
        originalResponse: 'Test',
        result: ValidationResult.failed,
        policyVersion: '1.0.0',
        asOf: now,
        createdAt: now,
      );

      final passed = ResponseValidation(
        validationId: 'rv-p',
        workspaceId: 'ws-1',
        originalResponse: 'Test',
        result: ValidationResult.passed,
        policyVersion: '1.0.0',
        asOf: now,
        createdAt: now,
      );

      expect(failed.isFailed, isTrue);
      expect(passed.isFailed, isFalse);
    });

    test('needsReview getter', () {
      final review = ResponseValidation(
        validationId: 'rv-r',
        workspaceId: 'ws-1',
        originalResponse: 'Test',
        result: ValidationResult.needsReview,
        policyVersion: '1.0.0',
        asOf: now,
        createdAt: now,
      );

      final passed = ResponseValidation(
        validationId: 'rv-p',
        workspaceId: 'ws-1',
        originalResponse: 'Test',
        result: ValidationResult.passed,
        policyVersion: '1.0.0',
        asOf: now,
        createdAt: now,
      );

      expect(review.needsReview, isTrue);
      expect(passed.needsReview, isFalse);
    });

    test('errors getter filters error-severity issues', () {
      const errorIssue = ValidationIssue(
        issueId: 'iss-err',
        issueType: ValidationIssueType.hallucination,
        severity: IssueSeverity.error,
        description: 'Error issue',
      );

      const warningIssue = ValidationIssue(
        issueId: 'iss-warn',
        issueType: ValidationIssueType.outdated,
        severity: IssueSeverity.warning,
        description: 'Warning issue',
      );

      const infoIssue = ValidationIssue(
        issueId: 'iss-info',
        issueType: ValidationIssueType.missingEvidence,
        severity: IssueSeverity.info,
        description: 'Info issue',
      );

      final rv = ResponseValidation(
        validationId: 'rv-errs',
        workspaceId: 'ws-1',
        originalResponse: 'Test',
        issues: [errorIssue, warningIssue, infoIssue],
        policyVersion: '1.0.0',
        asOf: now,
        createdAt: now,
      );

      expect(rv.errors.length, equals(1));
      expect(rv.errors.first.issueId, equals('iss-err'));
    });

    test('warnings getter filters warning-severity issues', () {
      const errorIssue = ValidationIssue(
        issueId: 'iss-err',
        issueType: ValidationIssueType.hallucination,
        severity: IssueSeverity.error,
        description: 'Error issue',
      );

      const warningIssue1 = ValidationIssue(
        issueId: 'iss-warn1',
        issueType: ValidationIssueType.outdated,
        severity: IssueSeverity.warning,
        description: 'Warning 1',
      );

      const warningIssue2 = ValidationIssue(
        issueId: 'iss-warn2',
        issueType: ValidationIssueType.contradiction,
        severity: IssueSeverity.warning,
        description: 'Warning 2',
      );

      final rv = ResponseValidation(
        validationId: 'rv-warns',
        workspaceId: 'ws-1',
        originalResponse: 'Test',
        issues: [errorIssue, warningIssue1, warningIssue2],
        policyVersion: '1.0.0',
        asOf: now,
        createdAt: now,
      );

      expect(rv.warnings.length, equals(2));
    });

    test('hasErrors getter', () {
      final withErrors = ResponseValidation(
        validationId: 'rv-he',
        workspaceId: 'ws-1',
        originalResponse: 'Test',
        issues: const [
          ValidationIssue(
            issueId: 'iss-1',
            issueType: ValidationIssueType.hallucination,
            severity: IssueSeverity.error,
            description: 'Error',
          ),
        ],
        policyVersion: '1.0.0',
        asOf: now,
        createdAt: now,
      );

      final withoutErrors = ResponseValidation(
        validationId: 'rv-no-err',
        workspaceId: 'ws-1',
        originalResponse: 'Test',
        issues: const [
          ValidationIssue(
            issueId: 'iss-1',
            issueType: ValidationIssueType.outdated,
            severity: IssueSeverity.warning,
            description: 'Just a warning',
          ),
        ],
        policyVersion: '1.0.0',
        asOf: now,
        createdAt: now,
      );

      final noIssues = ResponseValidation(
        validationId: 'rv-no-iss',
        workspaceId: 'ws-1',
        originalResponse: 'Test',
        policyVersion: '1.0.0',
        asOf: now,
        createdAt: now,
      );

      expect(withErrors.hasErrors, isTrue);
      expect(withoutErrors.hasErrors, isFalse);
      expect(noIssues.hasErrors, isFalse);
    });

    test('supportedClaimCount getter', () {
      final claims = [
        VerifiableClaim(
          claimId: 'vc-1',
          workspaceId: 'ws-1',
          statement: 'Supported claim',
          verificationStatus: ClaimStatus.supported,
          createdAt: now,
        ),
        VerifiableClaim(
          claimId: 'vc-2',
          workspaceId: 'ws-1',
          statement: 'Unsupported claim',
          verificationStatus: ClaimStatus.unsupported,
          createdAt: now,
        ),
        VerifiableClaim(
          claimId: 'vc-3',
          workspaceId: 'ws-1',
          statement: 'Another supported claim',
          verificationStatus: ClaimStatus.supported,
          createdAt: now,
        ),
      ];

      final rv = ResponseValidation(
        validationId: 'rv-sc',
        workspaceId: 'ws-1',
        originalResponse: 'Test',
        extractedClaims: claims,
        policyVersion: '1.0.0',
        asOf: now,
        createdAt: now,
      );

      expect(rv.supportedClaimCount, equals(2));
    });

    test('conflictingClaimCount getter', () {
      final claims = [
        VerifiableClaim(
          claimId: 'vc-1',
          workspaceId: 'ws-1',
          statement: 'Conflicting claim',
          verificationStatus: ClaimStatus.conflicting,
          createdAt: now,
        ),
        VerifiableClaim(
          claimId: 'vc-2',
          workspaceId: 'ws-1',
          statement: 'Supported claim',
          verificationStatus: ClaimStatus.supported,
          createdAt: now,
        ),
        VerifiableClaim(
          claimId: 'vc-3',
          workspaceId: 'ws-1',
          statement: 'Another conflicting claim',
          verificationStatus: ClaimStatus.conflicting,
          createdAt: now,
        ),
      ];

      final rv = ResponseValidation(
        validationId: 'rv-cc',
        workspaceId: 'ws-1',
        originalResponse: 'Test',
        extractedClaims: claims,
        policyVersion: '1.0.0',
        asOf: now,
        createdAt: now,
      );

      expect(rv.conflictingClaimCount, equals(2));
    });

    test('toString returns expected format', () {
      final claim = VerifiableClaim(
        claimId: 'vc-1',
        workspaceId: 'ws-1',
        statement: 'Claim',
        createdAt: now,
      );

      const issue = ValidationIssue(
        issueId: 'iss-1',
        issueType: ValidationIssueType.missingEvidence,
        description: 'Issue',
      );

      final rv = ResponseValidation(
        validationId: 'rv-str',
        workspaceId: 'ws-1',
        originalResponse: 'Test',
        extractedClaims: [claim],
        issues: [issue],
        result: ValidationResult.failed,
        policyVersion: '1.0.0',
        asOf: now,
        createdAt: now,
      );

      expect(rv.toString(),
          equals('ResponseValidation(rv-str, result: ValidationResult.failed, claims: 1, issues: 1)'));
    });

    test('equality compares by validationId', () {
      final rv1 = ResponseValidation(
        validationId: 'rv-eq',
        workspaceId: 'ws-1',
        originalResponse: 'Response A',
        policyVersion: '1.0.0',
        asOf: now,
        createdAt: now,
      );

      final rv2 = ResponseValidation(
        validationId: 'rv-eq',
        workspaceId: 'ws-2',
        originalResponse: 'Response B',
        policyVersion: '2.0.0',
        asOf: later,
        createdAt: later,
      );

      final rv3 = ResponseValidation(
        validationId: 'rv-different',
        workspaceId: 'ws-1',
        originalResponse: 'Response A',
        policyVersion: '1.0.0',
        asOf: now,
        createdAt: now,
      );

      expect(rv1 == rv2, isTrue);
      expect(rv1 == rv3, isFalse);
      expect(rv1.hashCode, equals(rv2.hashCode));
    });

    test('equality with identical reference', () {
      final rv = ResponseValidation(
        validationId: 'rv-id',
        workspaceId: 'ws-1',
        originalResponse: 'Self',
        policyVersion: '1.0.0',
        asOf: now,
        createdAt: now,
      );

      expect(rv == rv, isTrue);
    });

    test('equality with non-ResponseValidation object', () {
      final rv = ResponseValidation(
        validationId: 'rv-id',
        workspaceId: 'ws-1',
        originalResponse: 'Type check',
        policyVersion: '1.0.0',
        asOf: now,
        createdAt: now,
      );

      expect(rv == Object(), isFalse);
    });
  });
}
