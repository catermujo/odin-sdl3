package sdl3

MetalView :: distinct rawptr

when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32 {
    @(default_calling_convention = "c", link_prefix = "SDL_", require_results)
    foreign _ {
        Metal_CreateView :: proc(window: ^Window) -> MetalView ---
        Metal_DestroyView :: proc(view: MetalView) ---
        Metal_GetLayer :: proc(view: MetalView) -> rawptr ---
    }
} else {
    @(default_calling_convention = "c", link_prefix = "SDL_", require_results)
    foreign lib {
        Metal_CreateView :: proc(window: ^Window) -> MetalView ---
        Metal_DestroyView :: proc(view: MetalView) ---
        Metal_GetLayer :: proc(view: MetalView) -> rawptr ---
    }
}
