package sdl3_image

import "core:c"

import sdl "../"
SDL3_LINK :: sdl.SDL3_LINK

when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32 {


    @(default_calling_convention = "c", link_prefix = "IMG_")
    foreign _ {
        Version :: proc() -> c.int ---

        /* Load an image from an sdl data source.
        The 'type' may be one of: "BMP", "GIF", "PNG", etc.
        If the image format supports a transparent pixel, sdl will set the
        colorkey for the surface.  You can enable RLE acceleration on the
        surface afterwards by calling:
            sdl_SetColorKey(image, sdl_RLEACCEL, image->format->colorkey);
        */
        LoadTyped_IO :: proc(src: ^sdl.IOStream, closeio: bool, type: cstring) -> ^sdl.Surface ---

        /* Convenience functions */
        Load :: proc(file: cstring) -> ^sdl.Surface ---
        Load_IO :: proc(src: ^sdl.IOStream, closeio: bool) -> ^sdl.Surface ---

        /* Load an image directly into a render texture. */
        LoadTexture :: proc(renderer: ^sdl.Renderer, file: cstring) -> ^sdl.Texture ---
        LoadTexture_IO :: proc(renderer: ^sdl.Renderer, src: ^sdl.IOStream, closeio: bool) -> ^sdl.Texture ---
        LoadTextureTyped_IO :: proc(renderer: ^sdl.Renderer, src: ^sdl.IOStream, closeio: bool, type: cstring) -> ^sdl.Texture ---

        /* Functions to detect a file type, given a seekable source */
        isAVIF :: proc(src: ^sdl.IOStream) -> bool ---
        isICO :: proc(src: ^sdl.IOStream) -> bool ---
        isCUR :: proc(src: ^sdl.IOStream) -> bool ---
        isBMP :: proc(src: ^sdl.IOStream) -> bool ---
        isGIF :: proc(src: ^sdl.IOStream) -> bool ---
        isJPG :: proc(src: ^sdl.IOStream) -> bool ---
        isJXL :: proc(src: ^sdl.IOStream) -> bool ---
        isLBM :: proc(src: ^sdl.IOStream) -> bool ---
        isPCX :: proc(src: ^sdl.IOStream) -> bool ---
        isPNG :: proc(src: ^sdl.IOStream) -> bool ---
        isPNM :: proc(src: ^sdl.IOStream) -> bool ---
        isSVG :: proc(src: ^sdl.IOStream) -> bool ---
        isQOI :: proc(src: ^sdl.IOStream) -> bool ---
        isTIF :: proc(src: ^sdl.IOStream) -> bool ---
        isXCF :: proc(src: ^sdl.IOStream) -> bool ---
        isXPM :: proc(src: ^sdl.IOStream) -> bool ---
        isXV :: proc(src: ^sdl.IOStream) -> bool ---
        isWEBP :: proc(src: ^sdl.IOStream) -> bool ---

        /* Individual loading functions */
        LoadAVIF_IO :: proc(src: ^sdl.IOStream) -> ^sdl.Surface ---
        LoadICO_IO :: proc(src: ^sdl.IOStream) -> ^sdl.Surface ---
        LoadCUR_IO :: proc(src: ^sdl.IOStream) -> ^sdl.Surface ---
        LoadBMP_IO :: proc(src: ^sdl.IOStream) -> ^sdl.Surface ---
        LoadGIF_IO :: proc(src: ^sdl.IOStream) -> ^sdl.Surface ---
        LoadJPG_IO :: proc(src: ^sdl.IOStream) -> ^sdl.Surface ---
        LoadJXL_IO :: proc(src: ^sdl.IOStream) -> ^sdl.Surface ---
        LoadLBM_IO :: proc(src: ^sdl.IOStream) -> ^sdl.Surface ---
        LoadPCX_IO :: proc(src: ^sdl.IOStream) -> ^sdl.Surface ---
        LoadPNG_IO :: proc(src: ^sdl.IOStream) -> ^sdl.Surface ---
        LoadPNM_IO :: proc(src: ^sdl.IOStream) -> ^sdl.Surface ---
        LoadSVG_IO :: proc(src: ^sdl.IOStream) -> ^sdl.Surface ---
        LoadQOI_IO :: proc(src: ^sdl.IOStream) -> ^sdl.Surface ---
        LoadTGA_IO :: proc(src: ^sdl.IOStream) -> ^sdl.Surface ---
        LoadTIF_IO :: proc(src: ^sdl.IOStream) -> ^sdl.Surface ---
        LoadXCF_IO :: proc(src: ^sdl.IOStream) -> ^sdl.Surface ---
        LoadXPM_IO :: proc(src: ^sdl.IOStream) -> ^sdl.Surface ---
        LoadXV_IO :: proc(src: ^sdl.IOStream) -> ^sdl.Surface ---
        LoadWEBP_IO :: proc(src: ^sdl.IOStream) -> ^sdl.Surface ---

        LoadSizedSVG_IO :: proc(src: ^sdl.IOStream, width, height: c.int) -> ^sdl.Surface ---

        ReadXPMFromArray :: proc(xpm: [^]cstring) -> ^sdl.Surface ---
        ReadXPMFromArrayToRGB888 :: proc(xpm: [^]cstring) -> ^sdl.Surface ---

        /* Individual saving functions */
        SaveAVIF :: proc(surface: ^sdl.Surface, file: cstring, quality: c.int) -> c.bool ---
        SaveAVIF_IO :: proc(surface: ^sdl.Surface, dst: ^sdl.IOStream, closeio: bool, quality: c.int) -> c.bool ---
        SavePNG :: proc(surface: ^sdl.Surface, file: cstring) -> c.bool ---
        SavePNG_IO :: proc(surface: ^sdl.Surface, dst: ^sdl.IOStream, closeio: bool) -> c.bool ---
        SaveJPG :: proc(surface: ^sdl.Surface, file: cstring, quality: c.int) -> c.bool ---
        SaveJPG_IO :: proc(surface: ^sdl.Surface, dst: ^sdl.IOStream, closeio: bool, quality: c.int) -> c.bool ---

        LoadAnimation :: proc(file: cstring) -> ^Animation ---
        LoadAnimation_IO :: proc(src: ^sdl.IOStream, closeio: bool) -> ^Animation ---
        LoadAnimationTyped_IO :: proc(src: ^sdl.IOStream, closeio: bool, type: cstring) -> ^Animation ---
        FreeAnimation :: proc(anim: ^Animation) ---

        /* Individual loading functions */
        LoadGIFAnimation_IO :: proc(src: ^sdl.IOStream) -> ^Animation ---
        LoadWEBPAnimation_IO :: proc(src: ^sdl.IOStream) -> ^Animation ---
    }
} else {
    when ODIN_OS == .Windows {
        when SDL3_LINK == "shared" {
            foreign import lib "SDL3_image.lib"
        } else when SDL3_LINK == "static" {
            foreign import lib "SDL3_image_static.lib"
        }
    } else when ODIN_OS == .Darwin {
        when SDL3_LINK == "static" {
            foreign import lib "SDL3_image.darwin.a"
        } else when SDL3_LINK == "shared" {
            @(export)
            foreign import lib "libSDL3_image.dylib"
        } else {
            @(export)
            foreign import lib "system:SDL3_image"
        }
    } else when ODIN_OS == .Linux {
        when SDL3_LINK == "static" {
            @(export)
            foreign import lib "SDL3_image.linux.a"
        } else when SDL3_LINK == "shared" {
            @(export)
            foreign import lib "libSDL3_image.so"
        } else {
            @(export)
            foreign import lib "system:SDL3_image"
        }
    }

    @(default_calling_convention = "c", link_prefix = "IMG_")
    foreign lib {
        Version :: proc() -> c.int ---

        /* Load an image from an sdl data source.
        The 'type' may be one of: "BMP", "GIF", "PNG", etc.
        If the image format supports a transparent pixel, sdl will set the
        colorkey for the surface.  You can enable RLE acceleration on the
        surface afterwards by calling:
            sdl_SetColorKey(image, sdl_RLEACCEL, image->format->colorkey);
        */
        LoadTyped_IO :: proc(src: ^sdl.IOStream, closeio: bool, type: cstring) -> ^sdl.Surface ---

        /* Convenience functions */
        Load :: proc(file: cstring) -> ^sdl.Surface ---
        Load_IO :: proc(src: ^sdl.IOStream, closeio: bool) -> ^sdl.Surface ---

        /* Load an image directly into a render texture. */
        LoadTexture :: proc(renderer: ^sdl.Renderer, file: cstring) -> ^sdl.Texture ---
        LoadTexture_IO :: proc(renderer: ^sdl.Renderer, src: ^sdl.IOStream, closeio: bool) -> ^sdl.Texture ---
        LoadTextureTyped_IO :: proc(renderer: ^sdl.Renderer, src: ^sdl.IOStream, closeio: bool, type: cstring) -> ^sdl.Texture ---

        /* Functions to detect a file type, given a seekable source */
        isAVIF :: proc(src: ^sdl.IOStream) -> bool ---
        isICO :: proc(src: ^sdl.IOStream) -> bool ---
        isCUR :: proc(src: ^sdl.IOStream) -> bool ---
        isBMP :: proc(src: ^sdl.IOStream) -> bool ---
        isGIF :: proc(src: ^sdl.IOStream) -> bool ---
        isJPG :: proc(src: ^sdl.IOStream) -> bool ---
        isJXL :: proc(src: ^sdl.IOStream) -> bool ---
        isLBM :: proc(src: ^sdl.IOStream) -> bool ---
        isPCX :: proc(src: ^sdl.IOStream) -> bool ---
        isPNG :: proc(src: ^sdl.IOStream) -> bool ---
        isPNM :: proc(src: ^sdl.IOStream) -> bool ---
        isSVG :: proc(src: ^sdl.IOStream) -> bool ---
        isQOI :: proc(src: ^sdl.IOStream) -> bool ---
        isTIF :: proc(src: ^sdl.IOStream) -> bool ---
        isXCF :: proc(src: ^sdl.IOStream) -> bool ---
        isXPM :: proc(src: ^sdl.IOStream) -> bool ---
        isXV :: proc(src: ^sdl.IOStream) -> bool ---
        isWEBP :: proc(src: ^sdl.IOStream) -> bool ---

        /* Individual loading functions */
        LoadAVIF_IO :: proc(src: ^sdl.IOStream) -> ^sdl.Surface ---
        LoadICO_IO :: proc(src: ^sdl.IOStream) -> ^sdl.Surface ---
        LoadCUR_IO :: proc(src: ^sdl.IOStream) -> ^sdl.Surface ---
        LoadBMP_IO :: proc(src: ^sdl.IOStream) -> ^sdl.Surface ---
        LoadGIF_IO :: proc(src: ^sdl.IOStream) -> ^sdl.Surface ---
        LoadJPG_IO :: proc(src: ^sdl.IOStream) -> ^sdl.Surface ---
        LoadJXL_IO :: proc(src: ^sdl.IOStream) -> ^sdl.Surface ---
        LoadLBM_IO :: proc(src: ^sdl.IOStream) -> ^sdl.Surface ---
        LoadPCX_IO :: proc(src: ^sdl.IOStream) -> ^sdl.Surface ---
        LoadPNG_IO :: proc(src: ^sdl.IOStream) -> ^sdl.Surface ---
        LoadPNM_IO :: proc(src: ^sdl.IOStream) -> ^sdl.Surface ---
        LoadSVG_IO :: proc(src: ^sdl.IOStream) -> ^sdl.Surface ---
        LoadQOI_IO :: proc(src: ^sdl.IOStream) -> ^sdl.Surface ---
        LoadTGA_IO :: proc(src: ^sdl.IOStream) -> ^sdl.Surface ---
        LoadTIF_IO :: proc(src: ^sdl.IOStream) -> ^sdl.Surface ---
        LoadXCF_IO :: proc(src: ^sdl.IOStream) -> ^sdl.Surface ---
        LoadXPM_IO :: proc(src: ^sdl.IOStream) -> ^sdl.Surface ---
        LoadXV_IO :: proc(src: ^sdl.IOStream) -> ^sdl.Surface ---
        LoadWEBP_IO :: proc(src: ^sdl.IOStream) -> ^sdl.Surface ---

        LoadSizedSVG_IO :: proc(src: ^sdl.IOStream, width, height: c.int) -> ^sdl.Surface ---

        ReadXPMFromArray :: proc(xpm: [^]cstring) -> ^sdl.Surface ---
        ReadXPMFromArrayToRGB888 :: proc(xpm: [^]cstring) -> ^sdl.Surface ---

        /* Individual saving functions */
        SaveAVIF :: proc(surface: ^sdl.Surface, file: cstring, quality: c.int) -> c.bool ---
        SaveAVIF_IO :: proc(surface: ^sdl.Surface, dst: ^sdl.IOStream, closeio: bool, quality: c.int) -> c.bool ---
        SavePNG :: proc(surface: ^sdl.Surface, file: cstring) -> c.bool ---
        SavePNG_IO :: proc(surface: ^sdl.Surface, dst: ^sdl.IOStream, closeio: bool) -> c.bool ---
        SaveJPG :: proc(surface: ^sdl.Surface, file: cstring, quality: c.int) -> c.bool ---
        SaveJPG_IO :: proc(surface: ^sdl.Surface, dst: ^sdl.IOStream, closeio: bool, quality: c.int) -> c.bool ---

        LoadAnimation :: proc(file: cstring) -> ^Animation ---
        LoadAnimation_IO :: proc(src: ^sdl.IOStream, closeio: bool) -> ^Animation ---
        LoadAnimationTyped_IO :: proc(src: ^sdl.IOStream, closeio: bool, type: cstring) -> ^Animation ---
        FreeAnimation :: proc(anim: ^Animation) ---

        /* Individual loading functions */
        LoadGIFAnimation_IO :: proc(src: ^sdl.IOStream) -> ^Animation ---
        LoadWEBPAnimation_IO :: proc(src: ^sdl.IOStream) -> ^Animation ---
    }
}

MAJOR_VERSION :: 3
MINOR_VERSION :: 2
PATCHLEVEL :: 4

Animation :: struct {
    w, h:   c.int,
    count:  c.int,
    frames: [^]^sdl.Surface,
    delays: [^]c.int,
}

