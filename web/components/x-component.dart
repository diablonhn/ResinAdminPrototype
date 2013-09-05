library Component;

import 'package:web_ui/web_ui.dart';

import 'dart:html';

abstract class Component extends WebComponent
{
  Component()
  {
  }

  void appendTo(Element e)
  {
    this.host = e;

    ComponentItem item = new ComponentItem(this);

    item.create();
    item.insert();
  }

  @observable
  bool isReady()
  {
    return true;
  }
}
