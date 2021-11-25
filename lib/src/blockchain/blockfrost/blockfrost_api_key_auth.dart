// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:dio/dio.dart';

class BlockfrostApiKeyAuthInterceptor extends Interceptor {
  final String projectId;
  BlockfrostApiKeyAuthInterceptor({required this.projectId});
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['project_id'] = projectId;
    super.onRequest(options, handler);
  }
}
