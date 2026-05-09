// Bindings for [[ SDL3 ; https://wiki.libsdl.org/SDL3/FrontPage ]].
package sdl3

import "core:c"

main_func :: #type proc(argc: c.int, argv: [^]cstring)

when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32 {
    @(default_calling_convention = "c", link_prefix = "SDL_")
    foreign _ {
        AppInit :: proc(appstate: ^rawptr, argc: c.int, argv: [^]cstring) -> AppResult ---
        AppIterate :: proc(appstate: rawptr) -> AppResult ---
        AppEvent :: proc(appstate: rawptr, event: ^Event) -> AppResult ---
        AppQuit :: proc(appstate: rawptr, result: AppResult) ---
        SetMainReady :: proc() ---
        RunApp :: proc(argc: c.int, argv: [^]cstring, mainFunction: main_func, reserved: rawptr) -> c.int ---
        EnterAppMainCallbacks :: proc(argc: c.int, argv: [^]cstring, appinit: AppInit_func, appiter: AppIterate_func, appevent: AppEvent_func, appquit: AppQuit_func) -> c.int ---
        RegisterApp :: proc(name: cstring, style: Uint32, hInst: rawptr) -> bool ---
        UnregisterApp :: proc() ---
        GDKSuspendComplete :: proc() ---
    }
} else {
    @(default_calling_convention = "c", link_prefix = "SDL_")
    foreign lib {
        AppInit :: proc(appstate: ^rawptr, argc: c.int, argv: [^]cstring) -> AppResult ---
        AppIterate :: proc(appstate: rawptr) -> AppResult ---
        AppEvent :: proc(appstate: rawptr, event: ^Event) -> AppResult ---
        AppQuit :: proc(appstate: rawptr, result: AppResult) ---
        SetMainReady :: proc() ---
        RunApp :: proc(argc: c.int, argv: [^]cstring, mainFunction: main_func, reserved: rawptr) -> c.int ---
        EnterAppMainCallbacks :: proc(argc: c.int, argv: [^]cstring, appinit: AppInit_func, appiter: AppIterate_func, appevent: AppEvent_func, appquit: AppQuit_func) -> c.int ---
        RegisterApp :: proc(name: cstring, style: Uint32, hInst: rawptr) -> bool ---
        UnregisterApp :: proc() ---
        GDKSuspendComplete :: proc() ---
    }
}

when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32 {
    @(default_calling_convention = "c")
    foreign _ {
        SDL_main :: proc(argc: c.int, argv: [^]cstring) -> c.int ---
    }} else {
    @(default_calling_convention = "c")
    foreign lib {
        SDL_main :: proc(argc: c.int, argv: [^]cstring) -> c.int ---
    }}
