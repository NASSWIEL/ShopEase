// Flutter web plugin registrant file.
//
// Generated file. Do not edit.
//

// @dart = 2.13
// ignore_for_file: type=lint

import 'package:flutter_keyboard_visibility_web/flutter_keyboard_visibility_web.dart';
import 'package:geolocator_web/geolocator_web.dart';
import 'package:pointer_interceptor_web/pointer_interceptor_web.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

void registerPlugins([final Registrar? pluginRegistrar]) {
  final Registrar registrar = pluginRegistrar ?? webPluginRegistrar;
  FlutterKeyboardVisibilityPlugin.registerWith(registrar);
  GeolocatorPlugin.registerWith(registrar);
  PointerInterceptorWeb.registerWith(registrar);
  registrar.registerMessageHandler();
}
