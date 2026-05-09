package sdl3

import "core:c"

GUID :: struct {
    data: [16]Uint8,
}

when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32 {
    @(default_calling_convention = "c", link_prefix = "SDL_")
    foreign _ {
        GUIDToString :: proc(guid: GUID, pszGUID: [^]c.char, cbGUID: c.int) ---
        StringToGUID :: proc(pchGUID: cstring) -> GUID ---
    }} else {
    @(default_calling_convention = "c", link_prefix = "SDL_")
    foreign lib {
        GUIDToString :: proc(guid: GUID, pszGUID: [^]c.char, cbGUID: c.int) ---
        StringToGUID :: proc(pchGUID: cstring) -> GUID ---
    }}
