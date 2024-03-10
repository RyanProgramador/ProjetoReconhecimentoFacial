import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'dart:convert';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  Future initializePersistedState() async {
    prefs = await SharedPreferences.getInstance();
    _safeInit(() {
      _RostosAutorizadosSalvos =
          prefs.getStringList('ff_RostosAutorizadosSalvos')?.map((x) {
                try {
                  return jsonDecode(x);
                } catch (e) {
                  print("Can't decode persisted json. Error: $e.");
                  return {};
                }
              }).toList() ??
              _RostosAutorizadosSalvos;
    });
  }

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  late SharedPreferences prefs;

  List<dynamic> _RostosAutorizadosSalvos = [];
  List<dynamic> get RostosAutorizadosSalvos => _RostosAutorizadosSalvos;
  set RostosAutorizadosSalvos(List<dynamic> value) {
    _RostosAutorizadosSalvos = value;
    prefs.setStringList('ff_RostosAutorizadosSalvos',
        value.map((x) => jsonEncode(x)).toList());
  }

  void addToRostosAutorizadosSalvos(dynamic value) {
    _RostosAutorizadosSalvos.add(value);
    prefs.setStringList('ff_RostosAutorizadosSalvos',
        _RostosAutorizadosSalvos.map((x) => jsonEncode(x)).toList());
  }

  void removeFromRostosAutorizadosSalvos(dynamic value) {
    _RostosAutorizadosSalvos.remove(value);
    prefs.setStringList('ff_RostosAutorizadosSalvos',
        _RostosAutorizadosSalvos.map((x) => jsonEncode(x)).toList());
  }

  void removeAtIndexFromRostosAutorizadosSalvos(int index) {
    _RostosAutorizadosSalvos.removeAt(index);
    prefs.setStringList('ff_RostosAutorizadosSalvos',
        _RostosAutorizadosSalvos.map((x) => jsonEncode(x)).toList());
  }

  void updateRostosAutorizadosSalvosAtIndex(
    int index,
    dynamic Function(dynamic) updateFn,
  ) {
    _RostosAutorizadosSalvos[index] =
        updateFn(_RostosAutorizadosSalvos[index]);
    prefs.setStringList('ff_RostosAutorizadosSalvos',
        _RostosAutorizadosSalvos.map((x) => jsonEncode(x)).toList());
  }

  void insertAtIndexInRostosAutorizadosSalvos(int index, dynamic value) {
    _RostosAutorizadosSalvos.insert(index, value);
    prefs.setStringList('ff_RostosAutorizadosSalvos',
        _RostosAutorizadosSalvos.map((x) => jsonEncode(x)).toList());
  }
}

void _safeInit(Function() initializeField) {
  try {
    initializeField();
  } catch (_) {}
}

Future _safeInitAsync(Function() initializeField) async {
  try {
    await initializeField();
  } catch (_) {}
}
