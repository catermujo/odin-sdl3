package sdl3

import "core:c"

when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32 {
    @(default_calling_convention = "c", link_prefix = "SDL_")
    foreign _ {
        SetError :: proc(fmt: cstring, #c_vararg args: ..any) -> bool ---
        SetErrorV :: proc(fmt: cstring, ap: c.va_list) -> bool ---
        @(require_results)
        OutOfMemory :: proc() -> bool ---
        @(require_results)
        GetError :: proc() -> cstring ---
        ClearError :: proc() -> bool ---
    }
} else {
    @(default_calling_convention = "c", link_prefix = "SDL_")
    foreign lib {
        SetError :: proc(fmt: cstring, #c_vararg args: ..any) -> bool ---
        SetErrorV :: proc(fmt: cstring, ap: c.va_list) -> bool ---
        @(require_results)
        OutOfMemory :: proc() -> bool ---
        @(require_results)
        GetError :: proc() -> cstring ---
        ClearError :: proc() -> bool ---
    }
}

Unsupported :: proc "c" () -> bool { return SetError("That operation is not supported") }
InvalidParamError :: proc "c" (param: cstring) -> bool { return SetError("Parameter '%s' is invalid", param) }
