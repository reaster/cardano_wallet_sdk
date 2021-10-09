import 'package:dio/dio.dart';
import 'package:blockfrost/src/auth/auth.dart';

class BlockfrostApiKeyAuthInterceptor extends AuthInterceptor {
  final String projectId;
  BlockfrostApiKeyAuthInterceptor({required this.projectId});
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['project_id'] = projectId;
    super.onRequest(options, handler);
  }
}
