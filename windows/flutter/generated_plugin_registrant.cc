//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <permission_handler_windows/permission_handler_windows_plugin.h>
<<<<<<< HEAD
=======
#include <speech_to_text_windows/speech_to_text_windows.h>
>>>>>>> f5d1d2c945f24168b89203f4fe49db20a8fb1fe9

void RegisterPlugins(flutter::PluginRegistry* registry) {
  PermissionHandlerWindowsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("PermissionHandlerWindowsPlugin"));
<<<<<<< HEAD
=======
  SpeechToTextWindowsRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("SpeechToTextWindows"));
>>>>>>> f5d1d2c945f24168b89203f4fe49db20a8fb1fe9
}
