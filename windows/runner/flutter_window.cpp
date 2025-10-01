#include "flutter_window.h"

#include <optional>

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project), current_hotkey_id_(0), current_modifiers_(0), current_keycode_(0) {}

FlutterWindow::~FlutterWindow() {
  // Unregister hotkey if registered
  if (current_hotkey_id_ > 0) {
    UnregisterHotKey(GetHandle(), current_hotkey_id_);
  }
}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  // Setup hotkey method channel
  hotkey_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(), "spectra/hotkey",
      &flutter::StandardMethodCodec::GetInstance());

  hotkey_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue> &call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        HandleMethodCall(call, std::move(result));
      });

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Handle hotkey messages first
  if (message == WM_HOTKEY && wparam == current_hotkey_id_) {
    // Notify Flutter that hotkey was pressed
    if (hotkey_channel_) {
      hotkey_channel_->InvokeMethod("onHotkeyPressed", nullptr);
    }
    return 0;
  }

  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

void FlutterWindow::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  if (method_call.method_name().compare("registerHotkey") == 0) {
    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (arguments) {
      auto modifiers_it = arguments->find(flutter::EncodableValue("modifiers"));
      auto keycode_it = arguments->find(flutter::EncodableValue("keyCode"));
      
      if (modifiers_it != arguments->end() && keycode_it != arguments->end()) {
        int modifiers = std::get<int>(modifiers_it->second);
        int keycode = std::get<int>(keycode_it->second);
        
        // Unregister previous hotkey
        if (current_hotkey_id_ > 0) {
          UnregisterHotKey(GetHandle(), current_hotkey_id_);
        }
        
        // Register new hotkey
        current_hotkey_id_++;
        if (RegisterHotKey(GetHandle(), current_hotkey_id_, modifiers, keycode)) {
          current_modifiers_ = modifiers;
          current_keycode_ = keycode;
          result->Success(flutter::EncodableValue(true));
        } else {
          result->Success(flutter::EncodableValue(false));
        }
      } else {
        result->Error("INVALID_ARGUMENTS", "Missing modifiers or keyCode");
      }
    } else {
      result->Error("INVALID_ARGUMENTS", "Arguments must be a map");
    }
  }
  else if (method_call.method_name().compare("unregisterHotkey") == 0) {
    bool success = false;
    if (current_hotkey_id_ > 0) {
      success = UnregisterHotKey(GetHandle(), current_hotkey_id_);
      if (success) {
        current_modifiers_ = 0;
        current_keycode_ = 0;
        current_hotkey_id_ = 0;
      }
    }
    result->Success(flutter::EncodableValue(success));
  }
  else if (method_call.method_name().compare("getCurrentHotkey") == 0) {
    if (current_modifiers_ != 0 && current_keycode_ != 0) {
      flutter::EncodableMap response;
      response[flutter::EncodableValue("modifiers")] = flutter::EncodableValue(current_modifiers_);
      response[flutter::EncodableValue("keyCode")] = flutter::EncodableValue(current_keycode_);
      result->Success(flutter::EncodableValue(response));
    } else {
      result->Success();
    }
  }
  else {
    result->NotImplemented();
  }
}
