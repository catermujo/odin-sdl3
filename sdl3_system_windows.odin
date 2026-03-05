#+build windows
package sdl3

import win32 "core:sys/windows"

WindowsMessageHook :: #type proc(userdata: rawptr, msg: ^win32.MSG) -> bool

@(default_calling_convention = "c", link_prefix = "SDL_")
foreign lib {
    SetWindowsMessageHook :: proc(callback: WindowsMessageHook, userdata: rawptr) ---
    GetDirect3D9AdapterIndex :: proc(displayID: DisplayID) -> i32 ---
    GetDXGIOutputInfo :: proc(displayID: DisplayID, adapterIndex: ^i32, outputIndex: ^i32) -> bool ---
}

