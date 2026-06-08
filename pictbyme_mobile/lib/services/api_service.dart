import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';

class ApiService {
 static const String baseUrl =
    'http://localhost:8001/api';

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'Accept': 'application/json',
      },
    ),
  );

  Future<Response> login({
    required String email,
    required String password,
  }) async {
    return await dio.post(
      '/login',
      data: {
        'email': email,
        'password': password,
      },
    );
  }

  Future<Response> register({
    required String name,
    required String username,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    return await dio.post(
      '/register',
      data: {
        'name': name,
        'username': username,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
  }

  Future<Response> getPins() async {
    return await dio.get('/pins');
  }

  Future<Response> getPinsFiltered({bool paid = false}) async {
    final qp = <String, dynamic>{};
    if (paid) qp['paid'] = 1;
    return await dio.get('/pins', queryParameters: qp);
  }

  Future<Response> createPin({
  required int categoryId,
  required String title,
  required String description,
  required String fileUrl,
  int priceCoin = 0,
  bool isPremium = false,
}) async {
    final prefs =
        await SharedPreferences.getInstance();

    final token =
        prefs.getString('token');

    return await dio.post(
      '/pins',
      data: {
        'category_id': categoryId,
        'title': title,
        'description': description,
        'file_url': fileUrl,
        'type': 'image',
        'price_coin': priceCoin,
        'is_premium': isPremium,
      },
      options: Options(
        headers: {
          'Authorization':
              'Bearer $token',
        },
      ),
    );
  }
Future<Response> savePinToBoard({
  required int boardId,
  required int pinId,
}) async {

  final prefs =
      await SharedPreferences.getInstance();

  final token =
      prefs.getString('token');

  return await dio.post(
    '/boards/$boardId/pins',
    data: {
      'pin_id': pinId,
    },
    options: Options(
      headers: {
        'Authorization':
            'Bearer $token',
      },
    ),
  );

}
Future<Response> getBoards() async {

  final prefs =
      await SharedPreferences.getInstance();

  final token =
      prefs.getString('token');

  return await dio.get(
    '/boards',
    options: Options(
      headers: {
        'Authorization':
            'Bearer $token',
      },
    ),
  );
}
Future<Response> getBoardDetail(
  int boardId,
) async {

  final prefs =
      await SharedPreferences.getInstance();

  final token =
      prefs.getString('token');

  return await dio.get(
    '/boards/$boardId',
    options: Options(
      headers: {
        'Authorization':
            'Bearer $token',
      },
    ),
  );
}
Future<Response> topup({
  required int amount,
}) async {

  final prefs =
      await SharedPreferences.getInstance();

  final token =
      prefs.getString('token');

  return await dio.post(
    '/topup',
    data: {
      'amount': amount,
    },
    options: Options(
      headers: {
        'Authorization':
            'Bearer $token',
      },
    ),
  );
}

  Future<Response> purchasePin({
    required int pinId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    return await dio.post(
      '/pins/$pinId/purchase',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

Future<Response> createBoard({
  required String title,
  required String description,
}) async {

  final prefs =
      await SharedPreferences.getInstance();

  final token =
      prefs.getString('token');

  return await dio.post(
    '/boards',
    data: {
      'title': title,
      'description': description,
    },
    options: Options(
      headers: {
        'Authorization':
            'Bearer $token',
      },
    ),
  );
}
  
  Future<Response> uploadImage({
    required String filePath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final fileName = filePath.split('/').last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    return await dio.post(
      '/pins/upload',
      data: formData,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  Future<Response> uploadImageBytes({
    required Uint8List bytes,
    required String filename,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });

    return await dio.post(
      '/pins/upload',
      data: formData,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }
Future<Response> getCategories() async {
  return await dio.get(
    '/categories',
  );
}
}