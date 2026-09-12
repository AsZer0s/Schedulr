import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

class AppHttpClient {
  AppHttpClient({Dio? dio, CookieJar? cookieJar})
    : cookieJar = cookieJar ?? CookieJar(),
      dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 25),
              sendTimeout: const Duration(seconds: 15),
              responseType: ResponseType.bytes,
              followRedirects: true,
              maxRedirects: 8,
              validateStatus: (status) => status != null && status < 500,
            ),
          ) {
    this.dio.interceptors.add(CookieManager(this.cookieJar));
  }

  final Dio dio;
  final CookieJar cookieJar;

  Future<void> clearSession() => cookieJar.deleteAll();
}
