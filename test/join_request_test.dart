import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/core/constants/company_self_serve_strings.dart';
import 'package:job_platform_mobile/features/company/data/repositories/api_company_join_request_repository.dart';
import 'package:job_platform_mobile/features/company/domain/models/join_request.dart';
import 'package:job_platform_mobile/features/company/domain/repositories/company_join_request_repository.dart';
import 'package:job_platform_mobile/features/company/presentation/join_request_status_screen.dart';
import 'package:job_platform_mobile/features/company/presentation/join_requests_screen.dart';

class _Reply {
  const _Reply(this.statusCode, [this.body = const {}]);
  final int statusCode;
  final Map<String, dynamic> body;
}

class _ScriptedDio {
  _ScriptedDio(this._replies) {
    dio = Dio(BaseOptions(baseUrl: 'http://gateway.test'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          final reply = _replies.length > 1
              ? _replies.removeAt(0)
              : _replies.first;
          final response = Response<dynamic>(
            requestOptions: options,
            statusCode: reply.statusCode,
            data: reply.body,
          );
          if (reply.statusCode >= 400) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: response,
              ),
            );
          } else {
            handler.resolve(response);
          }
        },
      ),
    );
  }

  final List<_Reply> _replies;
  late final Dio dio;
  final List<RequestOptions> requests = [];
}

/// In-memory repository used by the widget tests. It records every call so the
/// screen's contract with the data layer is observable.
class _FakeJoinRequestRepository implements ICompanyJoinRequestRepository {
  _FakeJoinRequestRepository({
    List<CompanyJoinRequest>? requests,
    this.mine,
    this.listError,
    this.mineError,
    this.escalateError,
  }) : requests = requests ?? [];

  List<CompanyJoinRequest> requests;
  MyJoinRequest? mine;
  String? listError;
  String? mineError;
  String? escalateError;

  final List<String> approved = [];
  final List<String> rejected = [];
  final List<String?> rejectReasons = [];
  int listCalls = 0;
  bool escalated = false;

  @override
  Future<List<CompanyJoinRequest>> listForCompany(String companyId) async {
    listCalls++;
    if (listError != null) throw JoinRequestException(listError!);
    return List.of(requests);
  }

  @override
  Future<void> approve({
    required String companyId,
    required String requestId,
  }) async {
    approved.add(requestId);
    requests = requests
        .where((request) => request.id != requestId)
        .toList(growable: false);
  }

  @override
  Future<void> reject({
    required String companyId,
    required String requestId,
    String? reason,
  }) async {
    rejected.add(requestId);
    rejectReasons.add(reason);
    requests = requests
        .where((request) => request.id != requestId)
        .toList(growable: false);
  }

  @override
  Future<MyJoinRequest?> getMine() async {
    if (mineError != null) throw JoinRequestException(mineError!);
    return mine;
  }

  @override
  Future<void> escalate() async {
    escalated = true;
    if (escalateError != null) throw JoinRequestException(escalateError!);
    final current = mine;
    if (current != null) {
      mine = MyJoinRequest(
        id: current.id,
        companyId: current.companyId,
        status: JoinRequestStatus.escalated,
        expiresAt: current.expiresAt,
        createdAt: current.createdAt,
      );
    }
  }
}

CompanyJoinRequest _request({
  required String id,
  JoinRequestStatus status = JoinRequestStatus.pending,
  String? reason,
}) => CompanyJoinRequest(
  id: id,
  companyId: 'company-1',
  userId: '11111111-2222-3333-4444-555555555555',
  status: status,
  expiresAt: DateTime(2030, 1, 7),
  createdAt: DateTime(2029, 12, 31),
  decisionReason: reason,
);

MyJoinRequest _mine({
  JoinRequestStatus status = JoinRequestStatus.pending,
  bool canEscalate = false,
}) => MyJoinRequest(
  id: 'request-1',
  companyId: 'company-1',
  status: status,
  expiresAt: DateTime(2030, 1, 7),
  createdAt: DateTime(2029, 12, 31),
  canEscalate: canEscalate,
);

void main() {
  group('ApiCompanyJoinRequestRepository', () {
    test(
      'lists the company requests through the gateway and parses them',
      () async {
        final server = _ScriptedDio([
          const _Reply(200, {
            'items': [
              {
                'id': 'request-1',
                'companyId': 'company-1',
                'userId': 'user-1',
                'status': 'Pending',
                'expiresAt': '2030-01-07T00:00:00Z',
                'createdAt': '2029-12-31T00:00:00Z',
                'decidedAt': null,
                'decisionReason': null,
              },
              {
                'id': 'request-2',
                'companyId': 'company-1',
                'userId': 'user-2',
                'status': 'Expired',
                'expiresAt': '2029-01-07T00:00:00Z',
                'createdAt': '2028-12-31T00:00:00Z',
                'decidedAt': null,
                'decisionReason': null,
              },
            ],
            'total': 2,
            'page': 1,
            'size': 20,
          }),
        ]);
        final repo = ApiCompanyJoinRequestRepository(dio: server.dio);

        final requests = await repo.listForCompany('company-1');

        expect(
          server.requests.single.path,
          '/api/companies/company-1/join-requests',
        );
        expect(server.requests.single.method, 'GET');
        expect(requests, hasLength(2));
        expect(requests.first.id, 'request-1');
        expect(requests.first.status, JoinRequestStatus.pending);
        expect(requests.first.expiresAt, isNotNull);
        expect(requests.last.status, JoinRequestStatus.expired);
        expect(requests.last.createdAt, isNotNull);
      },
    );

    test('an unknown status is not guessed into a known one', () async {
      final server = _ScriptedDio([
        const _Reply(200, {
          'items': [
            {'id': 'r', 'status': 'SomethingNew'},
          ],
        }),
      ]);
      final repo = ApiCompanyJoinRequestRepository(dio: server.dio);

      final requests = await repo.listForCompany('company-1');

      expect(requests.single.status, JoinRequestStatus.unknown);
      expect(requests.single.status.label, JoinRequestStrings.statusUnknown);
    });

    test('approve and reject post to the decision paths', () async {
      final server = _ScriptedDio([
        const _Reply(200, {'id': 'request-1', 'status': 'Approved'}),
        const _Reply(200, {'id': 'request-2', 'status': 'Rejected'}),
      ]);
      final repo = ApiCompanyJoinRequestRepository(dio: server.dio);

      await repo.approve(companyId: 'company-1', requestId: 'request-1');
      await repo.reject(
        companyId: 'company-1',
        requestId: 'request-2',
        reason: '  không thuộc công ty ',
      );

      expect(
        server.requests.first.path,
        '/api/companies/company-1/join-requests/request-1/approve',
      );
      expect(server.requests.first.method, 'POST');
      expect(
        server.requests.last.path,
        '/api/companies/company-1/join-requests/request-2/reject',
      );
      expect(server.requests.last.data, {'reason': 'không thuộc công ty'});
    });

    test('reject omits an empty reason', () async {
      final server = _ScriptedDio([
        const _Reply(200, {'status': 'Rejected'}),
      ]);
      final repo = ApiCompanyJoinRequestRepository(dio: server.dio);

      await repo.reject(
        companyId: 'company-1',
        requestId: 'request-2',
        reason: '   ',
      );

      expect(server.requests.single.data, isEmpty);
    });

    test('403 means the caller is not the company admin', () async {
      final server = _ScriptedDio([
        const _Reply(403, {'errorCode': 'JOIN_REQUEST_NOT_ADMIN'}),
      ]);
      final repo = ApiCompanyJoinRequestRepository(dio: server.dio);

      await expectLater(
        repo.listForCompany('company-1'),
        throwsA(
          isA<JoinRequestException>().having(
            (e) => e.message,
            'message',
            contains('người tạo công ty'),
          ),
        ),
      );
    });

    test(
      '409 on a decided request explains the state, not the raw detail',
      () async {
        final server = _ScriptedDio([
          const _Reply(409, {
            'errorCode': 'JOIN_REQUEST_STATE_INVALID',
            'detail': 'Only a pending, unexpired join request can be approved.',
          }),
        ]);
        final repo = ApiCompanyJoinRequestRepository(dio: server.dio);

        await expectLater(
          repo.approve(companyId: 'company-1', requestId: 'request-1'),
          throwsA(
            isA<JoinRequestException>()
                .having((e) => e.message, 'message', contains('trạng thái'))
                .having(
                  (e) => e.message,
                  'raw detail leaked',
                  isNot(contains('Only a pending')),
                ),
          ),
        );
      },
    );

    test('409 ACCOUNT_ALREADY_HAS_COMPANY has its own message', () async {
      final server = _ScriptedDio([
        const _Reply(409, {'errorCode': 'ACCOUNT_ALREADY_HAS_COMPANY'}),
      ]);
      final repo = ApiCompanyJoinRequestRepository(dio: server.dio);

      await expectLater(
        repo.approve(companyId: 'company-1', requestId: 'request-1'),
        throwsA(
          isA<JoinRequestException>().having(
            (e) => e.message,
            'message',
            contains('công ty khác'),
          ),
        ),
      );
    });

    test('a missing join request is null, not an error', () async {
      final server = _ScriptedDio([
        const _Reply(404, {'errorCode': 'JOIN_REQUEST_NOT_FOUND'}),
      ]);
      final repo = ApiCompanyJoinRequestRepository(dio: server.dio);

      expect(await repo.getMine(), isNull);
    });

    test('getMine parses the status and the server-side canEscalate', () async {
      final server = _ScriptedDio([
        const _Reply(200, {
          'id': 'request-1',
          'companyId': 'company-1',
          'status': 'Expired',
          'expiresAt': '2029-01-07T00:00:00Z',
          'createdAt': '2028-12-31T00:00:00Z',
          'canEscalate': true,
        }),
      ]);
      final repo = ApiCompanyJoinRequestRepository(dio: server.dio);

      final mine = await repo.getMine();

      expect(server.requests.single.path, '/api/companies/me/join-request');
      expect(mine, isNotNull);
      expect(mine!.status, JoinRequestStatus.expired);
      expect(mine.canEscalate, isTrue);
    });

    test('escalate posts to the requester path', () async {
      final server = _ScriptedDio([
        const _Reply(200, {'id': 'request-1', 'status': 'Escalated'}),
      ]);
      final repo = ApiCompanyJoinRequestRepository(dio: server.dio);

      await repo.escalate();

      expect(
        server.requests.single.path,
        '/api/companies/me/join-request/escalate',
      );
      expect(server.requests.single.method, 'POST');
    });
  });

  group('JoinRequestsScreen (company admin)', () {
    testWidgets('lists pending requests with approve and reject actions', (
      tester,
    ) async {
      final repo = _FakeJoinRequestRepository(
        requests: [
          _request(id: 'pending-1'),
          _request(id: 'done-1', status: JoinRequestStatus.approved),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: JoinRequestsScreen(repository: repo, companyId: 'company-1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('join_request_approve_pending-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('join_request_reject_pending-1')),
        findsOneWidget,
      );
      // A decided request offers no new decision.
      expect(
        find.byKey(const Key('join_request_approve_done-1')),
        findsNothing,
      );
      expect(repo.listCalls, 1);
    });

    testWidgets('approve calls the repository and reloads the list', (
      tester,
    ) async {
      final repo = _FakeJoinRequestRepository(
        requests: [_request(id: 'pending-1')],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: JoinRequestsScreen(repository: repo, companyId: 'company-1'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('join_request_approve_pending-1')));
      await tester.pumpAndSettle();

      expect(repo.approved, ['pending-1']);
      expect(repo.listCalls, 2);
      expect(find.text(JoinRequestStrings.approved), findsOneWidget);
      expect(find.text(JoinRequestStrings.adminEmpty), findsOneWidget);
    });

    testWidgets('reject asks for an optional reason and sends it', (
      tester,
    ) async {
      final repo = _FakeJoinRequestRepository(
        requests: [_request(id: 'pending-1')],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: JoinRequestsScreen(repository: repo, companyId: 'company-1'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('join_request_reject_pending-1')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('join_request_reject_reason')),
        'không thuộc công ty',
      );
      await tester.tap(find.byKey(const Key('join_request_reject_confirm')));
      await tester.pumpAndSettle();

      expect(repo.rejected, ['pending-1']);
      expect(repo.rejectReasons, ['không thuộc công ty']);
      expect(find.text(JoinRequestStrings.adminEmpty), findsOneWidget);
    });

    testWidgets('a 403 shows the admin-only message and a retry', (
      tester,
    ) async {
      final repo = _FakeJoinRequestRepository(
        listError: 'Chỉ người tạo công ty mới được quản lý yêu cầu tham gia.',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: JoinRequestsScreen(repository: repo, companyId: 'company-1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Chỉ người tạo công ty mới được quản lý yêu cầu tham gia.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('join_requests_retry')), findsOneWidget);

      await tester.tap(find.byKey(const Key('join_requests_retry')));
      await tester.pumpAndSettle();

      expect(repo.listCalls, 2);
    });
  });

  group('JoinRequestStatusScreen (requester)', () {
    testWidgets('an account without a request sees the empty state', (
      tester,
    ) async {
      final repo = _FakeJoinRequestRepository();
      await tester.pumpWidget(
        MaterialApp(home: JoinRequestStatusScreen(repository: repo)),
      );
      await tester.pumpAndSettle();

      expect(find.text(JoinRequestStrings.myEmpty), findsOneWidget);
      expect(find.byKey(const Key('join_request_escalate')), findsNothing);
    });

    testWidgets('a pending request shows its status without escalate', (
      tester,
    ) async {
      final repo = _FakeJoinRequestRepository(mine: _mine());
      await tester.pumpWidget(
        MaterialApp(home: JoinRequestStatusScreen(repository: repo)),
      );
      await tester.pumpAndSettle();

      expect(find.text(JoinRequestStrings.statusPending), findsOneWidget);
      expect(find.byKey(const Key('join_request_escalate')), findsNothing);
    });

    testWidgets('escalate appears only when the server allows it and reloads', (
      tester,
    ) async {
      final repo = _FakeJoinRequestRepository(
        mine: _mine(status: JoinRequestStatus.expired, canEscalate: true),
      );
      await tester.pumpWidget(
        MaterialApp(home: JoinRequestStatusScreen(repository: repo)),
      );
      await tester.pumpAndSettle();

      expect(find.text(JoinRequestStrings.statusExpired), findsOneWidget);
      final escalate = find.byKey(const Key('join_request_escalate'));
      expect(escalate, findsOneWidget);

      await tester.tap(escalate);
      await tester.pumpAndSettle();

      expect(repo.escalated, isTrue);
      expect(find.text(JoinRequestStrings.statusEscalated), findsOneWidget);
      expect(find.byKey(const Key('join_request_escalate')), findsNothing);
    });

    testWidgets('a request error shows the message and a retry', (
      tester,
    ) async {
      final repo = _FakeJoinRequestRepository(
        mineError:
            'Không tải được trạng thái yêu cầu tham gia. Vui lòng thử lại.',
      );
      await tester.pumpWidget(
        MaterialApp(home: JoinRequestStatusScreen(repository: repo)),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Không tải được trạng thái yêu cầu tham gia. Vui lòng thử lại.',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('join_request_status_retry')),
        findsOneWidget,
      );
    });

    testWidgets('a 409 from escalate is explained and the status reloads', (
      tester,
    ) async {
      final repo = _FakeJoinRequestRepository(
        mine: _mine(status: JoinRequestStatus.expired, canEscalate: true),
        escalateError: 'Yêu cầu không còn ở trạng thái có thể xử lý.',
      );
      await tester.pumpWidget(
        MaterialApp(home: JoinRequestStatusScreen(repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('join_request_escalate')));
      await tester.pumpAndSettle();

      expect(
        find.text('Yêu cầu không còn ở trạng thái có thể xử lý.'),
        findsOneWidget,
      );
    });
  });
}
