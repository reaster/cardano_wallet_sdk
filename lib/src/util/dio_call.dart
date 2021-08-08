import 'dart:io';

import 'package:dio/dio.dart';
import 'package:quiver/strings.dart';
import 'package:oxidized/oxidized.dart';

typedef Future<Response<dynamic>> NetworkRquest();
typedef void OneArgFunction(dynamic);
typedef void ResponseFunction({Response? response, DioError? dioError, Exception? exception});

///
/// DIO network request wrapper that handles checking response and packaging result or error message. Returns an oxidizer Result.
///
Future<Result<T, String>> dioCall<T>(
    {required NetworkRquest request, OneArgFunction? onSuccess, ResponseFunction? onError, String? errorSubject}) async {
  try {
    final response = await request();
    if (response.statusCode != 200 || response.data == null) {
      if (onError != null) {
        onError(response: response);
      }
      return Err("${response.statusCode}: ${response.statusMessage}");
    }
    if (onSuccess != null) {
      onSuccess(response.data!);
    }
    return Ok(response.data!);
  } on DioError catch (dioError) {
    //print("DioError: ${dioError.message}");
    if (dioError.error is SocketException) {
      if (onError != null) {
        onError(exception: dioError.error);
      }
      return Err('internet not available');
    }
    if (onError != null) {
      onError(dioError: dioError);
    }
    return Err(translateErrorMessage(dioError: dioError, subject: errorSubject));
    // } on SocketException catch (e) {
    //   print("SocketException: ${e.message}");
    //   if (onError != null) {
    //     onError(exception: e);
    //   }
  } on Exception catch (e) {
    //print("Exception: ${e.toString()}");
    if (onError != null) {
      onError(exception: e);
    }
  }
  return Err("error loading $errorSubject");
}

///
/// blockfrost error codes to user readable messages
///
String translateErrorMessage({required DioError dioError, String? subject}) {
  if (dioError.response == null) {
    return dioError.message;
  }
  final prefix = isBlank(subject) ? '' : "$subject ";
  switch (dioError.response!.statusCode) {
    case 400: //HTTP 400 return code is used when the request is not valid.
      return "${prefix}request is not valid";
    case 402: //HTTP 402 return code is used when the projects exceed their daily request limit.
      return "exceded blockfrost daily request limit";
    case 403: //HTTP 403 return code is used when the request is not authenticated.
      return "not authenticated";
    case 404: // HTTP 404 return code is used when the resource doesn't exist.
      return "${prefix}doesn't exist"; // HTTP 418 return code is used when the user has been auto-banned for flooding too much after previously receiving error code 402 or 429.
    case 418:
      return "auto-banned from blockfrost";
    case 429: // HTTP 429 return code is used when the user has sent too many requests in a given amount of time and therefore has been rate-limited.
      return "rate-limited: sent too many requests";
    case 500: //  HTTP 500 return code is used when our endpoints are having a problem.
      return "blockfrost server having problems";
    default:
      return "unknown blockfrost error: ${dioError.response!.statusCode}";
  }
}
