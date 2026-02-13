#+build linux
package sdl3

import "core:c"

// Linux

@(default_calling_convention = "c", link_prefix = "SDL_")
foreign lib {
    SetLinuxThreadPriority :: proc(threadID: Sint64, priority: c.int) -> bool ---
    SetLinuxThreadPriorityAndPolicy :: proc(threadID: Sint64, sdlPriority: c.int, schedPolicy: c.int) -> bool ---
}

// Android

when ODIN_PLATFORM_SUBTARGET == .Android {
    RequestAndroidPermissionCallback :: #type proc "c" (userdata: rawptr, permission: cstring, granted: bool)

    @(default_calling_convention = "c", link_prefix = "SDL_", require_results)
    foreign lib {
        GetAndroidJNIEnv :: proc() -> rawptr ---
        GetAndroidActivity :: proc() -> rawptr ---
        GetAndroidSDKVersion :: proc() -> c.int ---
        IsChromebook :: proc() -> bool ---
        IsDeXMode :: proc() -> bool ---
        SendAndroidBackButton :: proc() ---
        GetAndroidInternalStoragePath :: proc() -> cstring ---
        GetAndroidExternalStorageState :: proc() -> Uint32 ---
        GetAndroidExternalStoragePath :: proc() -> cstring ---
        GetAndroidCachePath :: proc() -> cstring ---
        RequestAndroidPermission :: proc(permission: cstring, cb: RequestAndroidPermissionCallback, userdata: rawptr) -> bool ---
        ShowAndroidToast :: proc(message: cstring, duration: c.int, gravity: c.int, xoffset, yoffset: c.int) -> bool ---
        SendAndroidMessage :: proc(command: Uint32, param: c.int) -> bool ---
    }
}

