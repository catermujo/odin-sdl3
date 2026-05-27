package sdl3

MIXER :: #config(SDL3_MIXER, false)
when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32 {
    foreign import lib "SDL3.wasm.a"
    SYSTEM_SUPPORT :: false
} else {
    SYSTEM_SUPPORT :: ODIN_OS != .Windows && (ODIN_OS != .Darwin || !MIXER)
    LINK :: #config(SDL3_LINK, "system" when SYSTEM_SUPPORT else "shared")

    when ODIN_OS == .Darwin && MIXER && LINK == "system" {
        #panic("not available on brew yet, you gotta copile")
    }

    when ODIN_OS == .Windows {
        when LINK == "shared" {
            @(export)
            foreign import lib "SDL3.lib"
        } else when LINK == "static" {
            @(require) foreign import "system:Kernel32.lib"
            @(require) foreign import "system:User32.lib"
            @(require) foreign import "system:Gdi32.lib"
            @(require) foreign import "system:Winmm.lib"
            @(require) foreign import "system:Imm32.lib"
            @(require) foreign import "system:Ole32.lib"
            @(require) foreign import "system:Oleaut32.lib"
            @(require) foreign import "system:Version.lib"
            @(require) foreign import "system:Uuid.lib"
            @(require) foreign import "system:Advapi32.lib"
            @(require) foreign import "system:Setupapi.lib"
            @(require) foreign import "system:Shell32.lib"
            @(require) foreign import "system:Cfgmgr32.lib"
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
            // DUMBAI: Pin Darwin shared import to ABI-major install-name so vendor tree does not need duplicate unversioned alias files.
            @(export)
            foreign import lib "libSDL3.0.dylib"
        } else {
            @(export)
            foreign import lib "system:SDL3"
        }
    } else when ODIN_OS == .Linux {
        when LINK == "static" {
            when ODIN_ARCH == .amd64 {
                @(export)
                foreign import lib "linux_x64/SDL3.linux.a"
            } else when ODIN_ARCH == .arm64 {
                @(export)
                foreign import lib "linux_arm64/SDL3.linux.a"
            } else {
                #panic("vendor/sdl static link supports only linux amd64/arm64")
            }
        } else when LINK == "shared" {
            when ODIN_ARCH == .amd64 {
                @(export)
                foreign import lib "linux_x64/libSDL3.so"
            } else when ODIN_ARCH == .arm64 {
                @(export)
                foreign import lib "linux_arm64/libSDL3.so"
            } else {
                #panic("vendor/sdl shared link supports only linux amd64/arm64")
            }
        } else {
            @(export)
            foreign import lib "system:SDL3"
        }
    }
}
