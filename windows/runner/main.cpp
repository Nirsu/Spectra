#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

// =============================
// Hotkey constants
// =============================
#define HOTKEY_ID 1
#define HOTKEY_SHOW_HIDE 0x001

// =============================
// Global variables
// =============================
static FlutterWindow* g_window = nullptr;
static bool g_window_visible = true;

// =============================
// Struct to set blur
// =============================
enum ACCENT_STATE {
  ACCENT_DISABLED = 0,
  ACCENT_ENABLE_BLURBEHIND = 3,
  ACCENT_ENABLE_ACRYLICBLURBEHIND = 4, // Windows 10 1803+
};

struct ACCENT_POLICY {
  int nAccentState;
  int nFlags;
  int nColor;
  int nAnimationId;
};

struct WINDOWCOMPOSITIONATTRIBDATA {
  int Attrib;
  PVOID pvData;
  SIZE_T cbData;
};

enum WINDOWCOMPOSITIONATTRIB {
  WCA_ACCENT_POLICY = 19
};

typedef BOOL (WINAPI* pSetWindowCompositionAttribute)(HWND, WINDOWCOMPOSITIONATTRIBDATA*);

// =============================
// Function to toggle window visibility
// =============================
void ToggleWindowVisibility() {
  if (!g_window) return;
  
  HWND hwnd = g_window->GetHandle();
  if (!hwnd) return;
  
  if (g_window_visible) {
    // Hide window
    ShowWindow(hwnd, SW_HIDE);
    g_window_visible = false;
  } else {
    // Show window
    ShowWindow(hwnd, SW_SHOW);
    SetForegroundWindow(hwnd);
    g_window_visible = true;
  }
}

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  g_window = &window; // Store global reference
  
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"spectra", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  // ==============================
  // REGISTER GLOBAL HOTKEY (Windows + /)
  // ==============================
  HWND hwnd = window.GetHandle();
  if (hwnd) {
    // Register Windows + / hotkey (VK_OEM_2 is the '/' key)
    if (!RegisterHotKey(hwnd, HOTKEY_ID, MOD_WIN, VK_OEM_2)) {
      DWORD err = GetLastError();
      std::wstring msg = L"RegisterHotKey failed, error=" + std::to_wstring(err) + L"\n";
      OutputDebugString(msg.c_str());
    }
    
    // ==============================
    // SET WINDOW TO BE INVISIBLE TO SCREEN CAPTURE
    // ==============================
    if (!SetWindowDisplayAffinity(hwnd, WDA_EXCLUDEFROMCAPTURE)) {
      DWORD err = GetLastError();
      std::wstring msg = L"SetWindowDisplayAffinity failed, error=" + std::to_wstring(err) + L"\n";
      OutputDebugString(msg.c_str());
    }
  }

  // Remove the window from the ALT-TAB list
  LONG exStyle = GetWindowLong(hwnd, GWL_EXSTYLE);
  exStyle &= ~WS_EX_APPWINDOW;
  exStyle |= WS_EX_TOOLWINDOW;
  SetWindowLong(hwnd, GWL_EXSTYLE, exStyle);

  // Set always on top
   SetWindowPos(
      hwnd,
      HWND_TOPMOST, // place the window above all non-topmost windows
      0, 0, 0, 0,
      SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE
  );

  // ==============================

  // ==============================
  // SET WINDOW WITH TRANSPARENT WITH BLUR EFFECT
  // ==============================

  LONG style = GetWindowLong(hwnd, GWL_EXSTYLE);
  style |= WS_EX_LAYERED;
  SetWindowLong(hwnd, GWL_EXSTYLE, style);
  SetLayeredWindowAttributes(hwnd, 0, 230, LWA_ALPHA);

  auto SetWindowCompositionAttribute =
        (pSetWindowCompositionAttribute)GetProcAddress(
            GetModuleHandle(L"user32.dll"), "SetWindowCompositionAttribute");

  if (SetWindowCompositionAttribute) {
    ACCENT_POLICY accent = {};
    accent.nAccentState = ACCENT_ENABLE_ACRYLICBLURBEHIND;
    accent.nFlags = 2;
    accent.nColor = 0x33000000;

    WINDOWCOMPOSITIONATTRIBDATA data;
    data.Attrib = WCA_ACCENT_POLICY;
    data.pvData = &accent;
    data.cbData = sizeof(accent);

    SetWindowCompositionAttribute(hwnd, &data);
  }

  // =============================

  // =============================
  // MESSAGE LOOP WITH HOTKEY HANDLING
  // =============================
  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    // Handle hotkey messages
    if (msg.message == WM_HOTKEY) {
      if (msg.wParam == HOTKEY_ID) {
        ToggleWindowVisibility();
      }
      // Hotkey notifications are now handled directly in FlutterWindow::MessageHandler
    }
    
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  // Unregister hotkey before exit
  if (hwnd) {
    UnregisterHotKey(hwnd, HOTKEY_ID);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
