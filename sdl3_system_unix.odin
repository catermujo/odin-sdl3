#+build darwin,linux,freebsd,openbsd,netbsd
package sdl3

// UNIX

X11EventHook :: #type proc "c" (
    userdata: rawptr,
    xevent: rawptr,
    /* ^xlib.XEvent */
) -> bool

@(default_calling_convention = "c", link_prefix = "SDL_")
    foreign lib {
        SetX11EventHook :: proc(callback: X11EventHook, userdata: rawptr) ---
    }
