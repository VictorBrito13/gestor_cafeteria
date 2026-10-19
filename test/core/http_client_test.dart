import 'dart:convert';

import 'package:gestor_cafeteria/core/failure.dart';
import 'package:gestor_cafeteria/core/http_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';

ApiClient clienteQueResponde(int status, [Object? body]) {
  return ApiClient(
    baseUrl: 'http://test',
    client: MockClient(
      (request) async => http.Response(
        body == null ? '' : jsonEncode(body),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      ),
    ),
  );
}

void main() {
  group('Probar los Codigos de error', () {
    test('404 -> NotFoundFailure()', () async {
      final api = clienteQueResponde(404, {'detail': 'Order 999 not found'});

      await expectLater(
        api.get('/orders/999'),
        throwsA(isA<NotFoundFailure>()),
      );
    });

    test('200 -> devuelve el cuerpo decodificado', () async {
      final api = clienteQueResponde(200, {'id': 1, 'nombre': 'cafe'});

      final resultado = await api.get('/productos/1');

      expect(resultado, {'id': 1, 'nombre': 'cafe'});
    });

    test('409 -> ConflictFailure()', () async {
      final api = clienteQueResponde(409, {'detail': 'Order 999 ya existe'});

      await expectLater(
        api.get('/orders/999'),
        throwsA(isA<ConflictFailure>()),
      );
    });

    test('422 -> ValidationFailure() con fields', () async {
      final api = clienteQueResponde(422, {
        'detail': 'error de validacion',
        'fields': {'email': 'requerido'},
      });

      await expectLater(
        api.get('/usuarios'),
        throwsA(
          isA<ValidationFailure>().having(
            (failure) => failure.fields,
            'fields',
            {'email': 'requerido'},
          ),
        ),
      );
    });

    test('500 -> ServerFailure() con statusCode', () async {
      final api = clienteQueResponde(500, {'detail': 'boom'});

      await expectLater(
        api.get('/orders'),
        throwsA(
          isA<ServerFailure>().having(
            (failure) => failure.statusCode,
            'statusCode',
            500,
          ),
        ),
      );
    });

    test('timeout -> NetworkFailure()', () async {
      final api = ApiClient(
        baseUrl: 'http://test',
        timeouts: const Duration(milliseconds: 10),
        client: MockClient((request) async {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          return http.Response('{}', 200);
        }),
      );

      await expectLater(
        api.get('/slow'),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('201 -> devuelve el cuerpo decodificado', () async {
      final api = clienteQueResponde(201, {'id': 7, 'creado': true});

      final resultado = await api.post('/productos', body: {'nombre': 'cafe'});

      expect(resultado, {'id': 7, 'creado': true});
    });

    test('204 sin cuerpo -> null', () async {
      final api = clienteQueResponde(204);

      final resultado = await api.get('/orders/1');

      expect(resultado, isNull);
    });

    test('200 con cuerpo no JSON -> devuelve el texto', () async {
      final api = ApiClient(
        baseUrl: 'http://test',
        client: MockClient((request) async => http.Response('no-json', 200)),
      );

      final resultado = await api.get('/texto');

      expect(resultado, 'no-json');
    });

    test('400 -> UnexpectedFailure() con statusCode', () async {
      final api = clienteQueResponde(400, {'detail': 'solicitud invalida'});

      await expectLater(
        api.get('/orders'),
        throwsA(
          isA<UnexpectedFailure>().having(
            (failure) => failure.statusCode,
            'statusCode',
            400,
          ),
        ),
      );
    });

    test('403 -> UnexpectedFailure()', () async {
      final api = clienteQueResponde(403, {'detail': 'prohibido'});

      await expectLater(
        api.get('/orders'),
        throwsA(isA<UnexpectedFailure>()),
      );
    });

    test('503 -> ServerFailure() con statusCode', () async {
      final api = clienteQueResponde(503, {'detail': 'no disponible'});

      await expectLater(
        api.get('/orders'),
        throwsA(
          isA<ServerFailure>().having(
            (failure) => failure.statusCode,
            'statusCode',
            503,
          ),
        ),
      );
    });

    test('422 sin fields -> fields vacio', () async {
      final api = clienteQueResponde(422, {'detail': 'error de validacion'});

      await expectLater(
        api.get('/usuarios'),
        throwsA(
          isA<ValidationFailure>().having(
            (failure) => failure.fields,
            'fields',
            isEmpty,
          ),
        ),
      );
    });

    test('404 sin detail -> NotFoundFailure()', () async {
      final api = clienteQueResponde(404, {});

      await expectLater(
        api.get('/orders/999'),
        throwsA(isA<NotFoundFailure>()),
      );
    });

    test('ClientException -> NetworkFailure()', () async {
      final api = ApiClient(
        baseUrl: 'http://test',
        client: MockClient((request) async {
          throw http.ClientException('sin conexion');
        }),
      );

      await expectLater(
        api.get('/orders'),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('POST envia el cuerpo y devuelve la respuesta', () async {
      late http.Request capturada;
      final api = ApiClient(
        baseUrl: 'http://test',
        client: MockClient((request) async {
          capturada = request;
          return http.Response(
            jsonEncode({'id': 10, 'nombre': 'cafe'}),
            201,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

      final resultado = await api.post('/productos', body: {'nombre': 'cafe'});

      expect(capturada.method, 'POST');
      expect(capturada.headers['content-type'], contains('application/json'));
      expect(jsonDecode(capturada.body), {'nombre': 'cafe'});
      expect(resultado, {'id': 10, 'nombre': 'cafe'});
    });
  });
}
