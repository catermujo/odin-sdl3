#+build darwin,linux,freebsd,openbsd,netbsd
package sdl3

// UNIX

X11EventHook :: #type proc "c" (
    userdata: rawptr,
    xevent: rawptr,
    /* ^xlib.XEvent */
) -> bool

when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32 {
    @(default_calling_convention = "c", link_prefix = "SDL_")
    foreign _ {
        SetX11EventHook :: proc(callback: X11EventHook, userdata: rawptr) ---
    }
} else {
    @(default_calling_convention = "c", link_prefix = "SDL_")
    foreign lib {
        SetX11EventHook :: proc(callback: X11EventHook, userdata: rawptr) ---
    }
}
