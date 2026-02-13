package sdl3

SharedObject :: struct {}

when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32 {
    @(default_calling_convention = "c", link_prefix = "SDL_", require_results)
    foreign _ {
        LoadObject :: proc(sofile: cstring) -> ^SharedObject ---
        LoadFunction :: proc(handle: ^SharedObject, name: cstring) -> FunctionPointer ---
        UnloadObject :: proc(handle: ^SharedObject) ---
    }
} else {
    @(default_calling_convention = "c", link_prefix = "SDL_", require_results)
    foreign lib {
        LoadObject :: proc(sofile: cstring) -> ^SharedObject ---
        LoadFunction :: proc(handle: ^SharedObject, name: cstring) -> FunctionPointer ---
        UnloadObject :: proc(handle: ^SharedObject) ---
    }
}
