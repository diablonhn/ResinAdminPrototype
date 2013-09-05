library ResinAuthService;

import "package:meta/meta.dart" show override;

import 'dart:async';

import 'jamp/jamp.dart' as Jamp;

class ResinAuthService
{
  static const String SERVICE_NAME = "channel:///auth";

  Jamp.JampWebSocketConnection conn;

  ResinAuthService(this.conn);

  Future<bool> login(String user, String pass)
  {
    print("ResinAuthService.login0: $user $pass");

    String methodName = "login";

    List args = [user, pass];

    Future<Jamp.ReplyMessage> future
      = this.conn.submitQuery(SERVICE_NAME, methodName, parameters : args);

    Completer<bool> completer = new Completer();

    future.then((Jamp.ReplyMessage msg) {
      bool result = msg.result as bool;

      print("ResinAuthService.login1: $result");

      completer.complete(result);
    });

    return completer.future;
  }
}
