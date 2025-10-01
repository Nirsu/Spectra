import 'package:flutter/services.dart';

class HotkeyService {
  static const MethodChannel _channel = MethodChannel('spectra/hotkey');
  static Function()? _onHotkeyPressed;

  // Initialiser l'écoute des événements hotkey
  static void initialize() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onHotkeyPressed' && _onHotkeyPressed != null) {
        _onHotkeyPressed!();
      }
    });
  }

  // Définir le callback à appeler quand le hotkey est pressé
  static void setOnHotkeyPressed(Function() callback) {
    _onHotkeyPressed = callback;
  }

  // Virtual key codes pour Windows
  static const Map<String, int> _keyCodes = {
    'A': 0x41, 'B': 0x42, 'C': 0x43, 'D': 0x44, 'E': 0x45, 'F': 0x46,
    'G': 0x47, 'H': 0x48, 'I': 0x49, 'J': 0x4A, 'K': 0x4B, 'L': 0x4C,
    'M': 0x4D, 'N': 0x4E, 'O': 0x4F, 'P': 0x50, 'Q': 0x51, 'R': 0x52,
    'S': 0x53, 'T': 0x54, 'U': 0x55, 'V': 0x56, 'W': 0x57, 'X': 0x58,
    'Y': 0x59, 'Z': 0x5A,
    '0': 0x30, '1': 0x31, '2': 0x32, '3': 0x33, '4': 0x34,
    '5': 0x35, '6': 0x36, '7': 0x37, '8': 0x38, '9': 0x39,
    'F1': 0x70, 'F2': 0x71, 'F3': 0x72, 'F4': 0x73, 'F5': 0x74,
    'F6': 0x75, 'F7': 0x76, 'F8': 0x77, 'F9': 0x78, 'F10': 0x79,
    'F11': 0x7A, 'F12': 0x7B,
    'SPACE': 0x20, 'ENTER': 0x0D, 'TAB': 0x09, 'ESC': 0x1B,
    '/': 0xBF, // VK_OEM_2
    ',': 0xBC, '.': 0xBE, ';': 0xBA, "'": 0xDE,
    '[': 0xDB, ']': 0xDD, '\\': 0xDC, '`': 0xC0,
    '-': 0xBD, '=': 0xBB,
  };

  // Modifier flags
  static const Map<String, int> _modifiers = {
    'ALT': 0x0001, // MOD_ALT
    'CTRL': 0x0002, // MOD_CONTROL
    'SHIFT': 0x0004, // MOD_SHIFT
    'WIN': 0x0008, // MOD_WIN
  };

  /// Enregistre un nouveau hotkey
  /// [modifiers] : Liste des modificateurs (ex: ['WIN', 'CTRL'])
  /// [key] : Touche principale (ex: '/', 'A', 'F1')
  static Future<bool> registerHotkey(List<String> modifiers, String key) async {
    try {
      int modifierFlags = 0;
      for (String mod in modifiers) {
        if (_modifiers.containsKey(mod.toUpperCase())) {
          modifierFlags |= _modifiers[mod.toUpperCase()]!;
        }
      }

      int? keyCode = _keyCodes[key.toUpperCase()];
      if (keyCode == null) {
        throw Exception('Touche non supportée: $key');
      }

      final bool result = await _channel.invokeMethod('registerHotkey', {
        'modifiers': modifierFlags,
        'keyCode': keyCode,
      });

      return result;
    } catch (e) {
      print('Erreur lors de l\'enregistrement du hotkey: $e');
      return false;
    }
  }

  /// Désenregistre le hotkey actuel
  static Future<bool> unregisterHotkey() async {
    try {
      final bool result = await _channel.invokeMethod('unregisterHotkey');
      return result;
    } catch (e) {
      print('Erreur lors du désenregistrement du hotkey: $e');
      return false;
    }
  }

  /// Obtient le hotkey actuellement configuré
  static Future<Map<String, dynamic>?> getCurrentHotkey() async {
    try {
      final result = await _channel.invokeMethod('getCurrentHotkey');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      print('Erreur lors de la récupération du hotkey: $e');
      return null;
    }
  }

  /// Convertit les flags de modificateurs en liste de strings
  static List<String> modifierFlagsToStrings(int flags) {
    List<String> result = [];
    if (flags & _modifiers['ALT']! != 0) result.add('ALT');
    if (flags & _modifiers['CTRL']! != 0) result.add('CTRL');
    if (flags & _modifiers['SHIFT']! != 0) result.add('SHIFT');
    if (flags & _modifiers['WIN']! != 0) result.add('WIN');
    return result;
  }

  /// Convertit un code de touche en string
  static String? keyCodeToString(int keyCode) {
    for (var entry in _keyCodes.entries) {
      if (entry.value == keyCode) {
        return entry.key;
      }
    }
    return null;
  }
}
