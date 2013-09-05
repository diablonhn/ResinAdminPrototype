library view;

import 'package:web_ui/web_ui.dart';

import '../env.dart';

abstract class View extends WebComponent
{
  @observable
  bool isShow = false;

  View()
  {
  }

  bool isDefault() => dataset["default"] == "true";

  bool isTail() => dataset["tail"] == "true";

  bool isLogin() => false;

  bool isLoggedOut() => false;

  bool isError() => false;

  String getName();

  void inserted()
  {
    Env.getEnv().addView(this);
  }

  void hide()
  {
    this.hidden = true;

    this.isShow = false;
  }

  void show()
  {
    this.hidden = false;

    this.isShow = true;
  }
}
