package sdl3

when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32 {
    @(default_calling_convention = "c", link_prefix = "SDL_", require_results)
    foreign _ {
        OpenURL :: proc(url: cstring) -> bool ---
    }
} else {
    @(default_calling_convention = "c", link_prefix = "SDL_", require_results)
    foreign lib {
        OpenURL :: proc(url: cstring) -> bool ---
    }
}
