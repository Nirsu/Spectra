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
          content: Text('Raccourci clavier mis à jour avec succès!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la mise à jour du raccourci'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration du raccourci clavier'),
        backgroundColor: Colors.transparent,
      ),
      backgroundColor: Colors.transparent,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: Colors.black54,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Raccourci actuel:',
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
                              border: Border.all(color: Colors.deepPurple),
                            ),
                            child: Text(
                              currentHotkeyDisplay ?? 'Aucun',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Modificateurs:',
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
                        selectedColor: Colors.deepPurple,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Touche:',
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
                      border: Border.all(color: Colors.deepPurple),
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
                        color: Colors.deepPurple.withOpacity(0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Aperçu du nouveau raccourci:',
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
                            color: Colors.deepPurple,
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
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Appliquer le raccourci',
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
