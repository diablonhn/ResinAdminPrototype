library env;

import 'package:web_ui/web_ui.dart';

import 'dart:html';

import 'jamp/jamp.dart';
import 'views/View.dart';

import 'ResinAdminService.dart';
import 'ResinAuthService.dart';
import 'ResinStatService.dart';
import 'ResinLogService.dart';

var env;

class Env
{
  JampWebSocketConnection conn;

  ResinAdminService service;
  ResinAuthService authService;
  ResinStatService statService;
  ResinLogService logService;

  @observable
  bool isLoggedIn = false;

  View view;

  View defaultView;
  View errorView;
  View loginView;
  View loggedOutView;

  Map<String,View> viewMap;

  Env(String uri)
  {
    this.conn = new JampWebSocketConnection(uri);

    this.service = new ResinAdminService(this.conn);
    this.authService = new ResinAuthService(this.conn);
    this.statService = new ResinStatService(this.conn);
    this.logService = new ResinLogService(this.conn);

    this.viewMap = new Map();
  }

  static Env init(String uri)
  {
    env = new Env(uri);

    return env;
  }

  void loggedIn()
  {
    this.isLoggedIn = true;

    String queryViewName = getQueryParameter("view");

    if (queryViewName != null) {
      setViewByName(queryViewName);
    }
    else {
      setView(this.defaultView);
    }
  }

  void loggedOut()
  {
    this.isLoggedIn = false;

    setView(this.loggedOutView);
  }

  String getQueryParameter(String key)
  {
    return getQueryParameters()[key];
  }

  Map<String,String> getQueryParameters()
  {
    Map<String,String> map = new Map();

    String uri = window.location.href;

    int p = uri.indexOf("#");
    String fragment = uri.substring(p + 1);

    List<String> list = fragment.split("&");

    for (String token in list) {
      if (token.startsWith("&")) {
        token = token.substring(1);
      }

      int i = token.indexOf("=");

      if (i >= 0) {
        String key = token.substring(0, i);
        String value = token.substring(i + 1);

        map[key] = value;
      }
    }

    return map;
  }

  JampWebSocketConnection getConnection() => this.conn;

  ResinAdminService getResinAdminService() => this.service;

  ResinStatService getResinStatService() => this.statService;

  ResinLogService getResinLogService() => this.logService;

  ResinAuthService getResinAuthService() => this.authService;

  void addView(View view)
  {
    View oldView = this.viewMap[view.getName()];

    if (oldView != null) {
      throw new Exception("view already defined: ${view.getName()}");
    }

    if (view.isDefault()) {
      this.defaultView = view;
    }

    if (view.isError()) {
      this.errorView = view;
    }

    if (view.isLogin()) {
      this.loginView = view;
    }

    if (view.isLoggedOut()) {
      this.loggedOutView = view;
    }

    this.viewMap[view.getName()] = view;

    if (view.isTail()) {
      setView(this.loginView);

      /*

      String queryViewName = getQueryParameter("view");

      if (queryViewName != null) {
        if (queryViewName == view.getName()) {
          setView(view);
        }
        else {
          setView(this.errorView);
        }
      }
      else {
        setView(this.defaultView);
      }
      */

    }
  }

  void setView(View view)
  {
    View oldView = this.view;

    if (oldView != null) {
      oldView.hide();
    }

    this.view = view;

    view.show();
  }

  void setViewByName(String name)
  {
    if (! this.isLoggedIn) {
      setView(this.loginView);

      return;
    }

    View view = this.viewMap[name];

    if (view == null) {
      if (this.errorView != null) {
        setView(this.errorView);
      }
      else {
        throw new Exception("view not found: $name");
      }
    }
    else {
      setView(view);
    }
  }

  static Env getEnv()
  {
    return env;
  }
}

