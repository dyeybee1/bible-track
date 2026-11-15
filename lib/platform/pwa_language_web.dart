import 'dart:js_interop';

@JS('document.documentElement.lang')
external set _documentLanguage(JSString value);

void setPwaLanguage(String language) {
  _documentLanguage = language.toJS;
}
