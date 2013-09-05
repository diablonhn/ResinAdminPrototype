library util;

import "dart:html";

typedef void Listener<T extends Event>(T e);

Map<String,String> getQueryParameters()
{
  Map<String,String> map = new Map();

  String query = window.location.search;

  if (query.length == 0) {
    return map;
  }

  query = query.substring(1);

  List<String> tokens = query.split("&");

  for (String token in tokens) {
    List<String> entry = token.split("=");

    String key = entry[0];
    String value = null;

    if(entry.length > 1 && entry[1].length > 0) {
      value = entry[1];
    }

    map[key] = value;
  }

  return map;
}

String getQueryParameter(String key)
{
  Map<String,String> paramMap = getQueryParameters();

  return paramMap[key];
}

String getSelectedValue(SelectElement select)
{
  return select.selectedOptions[0].value;
}

List<String> getSelectedValues(SelectElement select)
{
  List<String> list = new List();

  for (OptionElement option in select.selectedOptions) {
    list.add(option.value);
  }

  return list;
}

