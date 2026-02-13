package sdl3

import "core:c"

Locale :: struct {
    language: cstring, /**< A language name, like "en" for English. */
    country:  cstring, /**< A country, like "US" for America. Can be NULL. */
}

when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32 {
    @(default_calling_convention = "c", link_prefix = "SDL_", require_results)
    foreign _ {
        GetPreferredLocales :: proc(count: ^c.int) -> [^]^Locale ---
    }
} else {
    @(default_calling_convention = "c", link_prefix = "SDL_", require_results)
    foreign lib {
        GetPreferredLocales :: proc(count: ^c.int) -> [^]^Locale ---
    }
}
