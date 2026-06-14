import 'dart:io';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';

class ApiService {
  // Dynamically choose host so Android emulator can reach localhost.
  static String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000/api';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000/api';
    } catch (_) {}
    return 'http://127.0.0.1:8000/api';
  }

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

  Future<Response> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    return await dio.get(
      '/profile',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

    Future<Response> changePassword({
      required String currentPassword,
      required String newPassword,
      required String newPasswordConfirmation,
    }) async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      return await dio.post(
        '/profile/password',
        data: {
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': newPasswordConfirmation,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
    }

  Future<Response> getMyPins() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    // debug: print token used for authenticated requests
    print('TOKEN = $token');

    return await dio.get(
      '/pins/mine',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  Future<Response> updateProfile({
    String? name,
    String? username,
    String? email,
    String? profilePicture,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    return await dio.put(
      '/profile',
      data: {
        if (name != null) 'name': name,
        if (username != null) 'username': username,
        if (email != null) 'email': email,
        if (profilePicture != null) 'profile_picture': profilePicture,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  Future<Response> updatePin({
    required int pinId,
    required int categoryId,
    required String title,
    String? description,
    int? priceCoin,
    bool? isPremium,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    return await dio.put(
      '/pins/$pinId',
      data: {
        'category_id': categoryId,
        'title': title,
        'description': description,
        'price_coin': priceCoin,
        'is_premium': isPremium,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  Future<Response> deletePin({required int pinId}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    return await dio.delete(
      '/pins/$pinId',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );
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
Future<Response> getPin(int pinId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    return await dio.get(
      '/pins/$pinId',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );
}

Future<Response> likePin({required int pinId}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  return await dio.post(
    '/pins/$pinId/like',
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );
}

Future<Response> unlikePin({required int pinId}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  return await dio.delete(
    '/pins/$pinId/like',
    options: Options(headers: {'Authorization': 'Bearer $token'}),
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

Future<Response> getNotifications() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  return await dio.get(
    '/notifications',
    options: Options(
      headers: {
        'Authorization': 'Bearer $token',
      },
    ),
  );
}
}