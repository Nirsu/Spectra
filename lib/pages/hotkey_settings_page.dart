import 'package:flutter/material.dart';
import '../services/hotkey_service.dart';

class HotkeySettingsPage extends StatefulWidget {
  const HotkeySettingsPage({super.key});

  @override
  State<HotkeySettingsPage> createState() => _HotkeySettingsPageState();
}

class _HotkeySettingsPageState extends State<HotkeySettingsPage> {
  List<String> selectedModifiers = ['WIN'];
  String selectedKey = '/';
  String? currentHotkeyDisplay;
  bool isLoading = true;

  final List<String> availableModifiers = ['WIN', 'CTRL', 'ALT', 'SHIFT'];
  final List<String> availableKeys = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    'F1',
    'F2',
    'F3',
    'F4',
    'F5',
    'F6',
    'F7',
    'F8',
    'F9',
    'F10',
    'F11',
    'F12',
    '/',
    ',',
    '.',
    ';',
    "'",
    '[',
    ']',
    '\\',
    '`',
    '-',
    '=',
    'SPACE',
    'ENTER',
    'TAB',
    'ESC',
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentHotkey();
  }

  void _loadCurrentHotkey() async {
    final current = await HotkeyService.getCurrentHotkey();
    if (current != null) {
      setState(() {
        selectedModifiers = HotkeyService.modifierFlagsToStrings(
          current['modifiers'],
        );
        selectedKey = HotkeyService.keyCodeToString(current['keyCode']) ?? '/';
        currentHotkeyDisplay = _buildHotkeyDisplay(
          selectedModifiers,
          selectedKey,
        );
        isLoading = false;
      });
    } else {
      setState(() {
        currentHotkeyDisplay = _buildHotkeyDisplay(
          selectedModifiers,
          selectedKey,
        );
        isLoading = false;
      });
    }
  }

  String _buildHotkeyDisplay(List<String> modifiers, String key) {
    return '${modifiers.join(' + ')} + $key';
  }

  void _applyHotkey() async {
    setState(() => isLoading = true);

    // Désenregistrer l'ancien hotkey
    await HotkeyService.unregisterHotkey();

    // Enregistrer le nouveau
    final success = await HotkeyService.registerHotkey(
      selectedModifiers,
      selectedKey,
    );

    setState(() => isLoading = false);

    if (success) {
      setState(() {
        currentHotkeyDisplay = _buildHotkeyDisplay(
          selectedModifiers,
          selectedKey,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hotkey updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error updating hotkey'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hotkey Configuration',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    color: Colors.black54,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Hotkey:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white),
                            ),
                            child: Text(
                              currentHotkeyDisplay ?? 'None',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Modifiers:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: availableModifiers.map((modifier) {
                      final isSelected = selectedModifiers.contains(modifier);
                      return FilterChip(
                        label: Text(modifier),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              selectedModifiers.add(modifier);
                            } else {
                              selectedModifiers.remove(modifier);
                            }
                          });
                        },
                        backgroundColor: Colors.black54,
                        selectedColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : Colors.grey,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Key:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedKey,
                        dropdownColor: Colors.black87,
                        style: const TextStyle(color: Colors.white),
                        items: availableKeys.map((key) {
                          return DropdownMenuItem(value: key, child: Text(key));
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedKey = value;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'New hotkey preview:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _buildHotkeyDisplay(selectedModifiers, selectedKey),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: selectedModifiers.isNotEmpty
                          ? _applyHotkey
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Apply Hotkey',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
