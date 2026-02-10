package sdl3

MIXER :: #config(SDL3_MIXER, false)
when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32 {
    SYSTEM_SUPPORT :: false
} else {
    SYSTEM_SUPPORT :: ODIN_OS != .Windows && (ODIN_OS != .Darwin || !MIXER)
    LINK :: #config(LINK, "system" when SYSTEM_SUPPORT else "shared")

    when ODIN_OS == .Darwin && MIXER && LINK == "system" {
        #panic("not available on brew yet, you gotta copile")
    }

    when ODIN_OS == .Windows {
        when LINK == "shared" {
            @(export)
            foreign import lib "SDL3.lib"
        } else when LINK == "static" {
            @(export)
            foreign import lib "SDL3_static.lib"
        }
    } else when ODIN_OS == .Darwin {
        when LINK == "static" {
            @(require) foreign import "system:System"
            @(require) foreign import "system:ObjC"
            @(require) foreign import "system:iconv"
            @(require) foreign import "system:AVFoundation.framework"
            @(require) foreign import "system:Foundation.framework"
            @(require) foreign import "system:CoreFoundation.framework"
            @(require) foreign import "system:CoreAudio.framework"
            @(require) foreign import "system:CoreMedia.framework"
            @(require) foreign import "system:UniformTypeIdentifiers.framework"
            @(require) foreign import "system:CoreGraphics.framework"
            @(require) foreign import "system:CoreVideo.framework"
            @(require) foreign import "system:CoreServices.framework"
            @(require) foreign import "system:CoreHaptics.framework"
            @(require) foreign import "system:AudioToolbox.framework"
            @(require) foreign import "system:IOKit.framework"
            @(require) foreign import "system:QuartzCore.framework"
            @(require) foreign import "system:GameController.framework"
            @(require) foreign import "system:ForceFeedback.framework"
            @(require) foreign import "system:Metal.framework"
            @(require) foreign import "system:MetalKit.framework"
            @(require) foreign import "system:Cocoa.framework"
            @(require) foreign import "system:AppKit.framework"
            @(require) foreign import "system:Carbon.framework"
            @(export)
            foreign import lib "SDL3.darwin.a"
        } else when LINK == "shared" {
            @(export)
            foreign import lib "libSDL3.dylib"
        } else {
            @(export)
            foreign import lib "system:SDL3"
        }
    } else when ODIN_OS == .Linux {
        when LINK == "static" {
            @(export)
            foreign import lib "SDL3.linux.a"
        } else when LINK == "shared" {
            @(export)
            foreign import lib "libSDL3.so"
        } else {
            @(export)
            foreign import lib "system:SDL3"
        }
    }
}
