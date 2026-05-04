// Bindings for [[ SDL3 Mixer ; https://wiki.libsdl.org/SDL3_mixer/FrontPage ]].
package mixer

import "core:c"

import sdl "../"

when sdl.MIXER {
    // Keep mixer optional while reusing the root SDL package's link-mode selection on native targets.
    when ODIN_OS == .Windows {
        when sdl.LINK == "shared" {
            foreign import lib "SDL3_mixer.lib"
        } else when sdl.LINK == "static" {
            foreign import lib "SDL3_mixer_static.lib"
        }
    } else when ODIN_OS == .Darwin {
        when sdl.LINK == "static" {
            @(export)
            foreign import lib "SDL3_mixer.darwin.a"
        } else when sdl.LINK == "shared" {
            // DUMBAI: Pin Darwin shared import to ABI-major install-name so vendor tree can drop duplicate unversioned alias files.
            @(export)
            foreign import lib "libSDL3_mixer.0.dylib"
        } else {
            @(export)
            foreign import lib "system:SDL3_mixer"
        }
    } else when ODIN_OS == .Linux {
        when sdl.LINK == "static" {
            @(export)
            foreign import lib "SDL3_mixer.linux.a"
        } else when sdl.LINK == "shared" {
            @(export)
            foreign import lib "libSDL3_mixer.so"
        } else {
            @(export)
            foreign import lib "system:SDL3_mixer"
        }
    } else when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32 {
    }

    Mixer :: struct {}
    Audio :: struct {}
    Track :: struct {}
    Group :: struct {}

    StereoGains :: struct {
        left, right: c.float,
    }

    Point3D :: struct {
        x, y, z: c.float,
    }

    TrackStoppedCallback :: #type proc "c" (userdata: rawptr, track: ^Track)
    TrackMixCallback :: #type proc "c" (userdata: rawptr, track: ^Track, spec: ^sdl.AudioSpec, pcm: ^c.float, samples: c.int)
    GroupMixCallback :: #type proc "c" (userdata: rawptr, group: ^Group, spec: ^sdl.AudioSpec, pcm: ^c.float, samples: c.int)
    PostMixCallback :: #type proc "c" (userdata: rawptr, mixer: ^Mixer, spec: ^sdl.AudioSpec, pcm: ^c.float, samples: c.int)

    AudioDecoder :: struct {}

    MAJOR_VERSION :: 3
    MINOR_VERSION :: 2
    MICRO_VERSION :: 0

    // Preserve the older local version spellings so call sites can migrate incrementally.
    sdl_MIXER_MAJOR_VERSION :: MAJOR_VERSION
    sdl_MIXER_MINOR_VERSION :: MINOR_VERSION
    sdl_MIXER_MICRO_VERSION :: MICRO_VERSION
    sdl_MIXER_VERSION :: MAJOR_VERSION * 1000000 + MINOR_VERSION * 1000 + MICRO_VERSION

    PROP_MIXER_DEVICE_NUMBER :: "SDL_mixer.mixer.device"

    PROP_AUDIO_LOAD_IOSTREAM_POINTER :: "SDL_mixer.audio.load.iostream"
    PROP_AUDIO_LOAD_CLOSEIO_BOOLEAN :: "SDL_mixer.audio.load.closeio"
    PROP_AUDIO_LOAD_PREDECODE_BOOLEAN :: "SDL_mixer.audio.load.predecode"
    PROP_AUDIO_LOAD_PREFERRED_MIXER_POINTER :: "SDL_mixer.audio.load.preferred_mixer"
    PROP_AUDIO_LOAD_SKIP_METADATA_TAGS_BOOLEAN :: "SDL_mixer.audio.load.skip_metadata_tags"
    PROP_AUDIO_DECODER_STRING :: "SDL_mixer.audio.decoder"

    PROP_METADATA_TITLE_STRING :: "SDL_mixer.metadata.title"
    PROP_METADATA_ARTIST_STRING :: "SDL_mixer.metadata.artist"
    PROP_METADATA_ALBUM_STRING :: "SDL_mixer.metadata.album"
    PROP_METADATA_COPYRIGHT_STRING :: "SDL_mixer.metadata.copyright"
    PROP_METADATA_TRACK_NUMBER :: "SDL_mixer.metadata.track"
    PROP_METADATA_TOTAL_TRACKS_NUMBER :: "SDL_mixer.metadata.total_tracks"
    PROP_METADATA_YEAR_NUMBER :: "SDL_mixer.metadata.year"
    PROP_METADATA_DURATION_FRAMES_NUMBER :: "SDL_mixer.metadata.duration_frames"
    PROP_METADATA_DURATION_INFINITE_BOOLEAN :: "SDL_mixer.metadata.duration_infinite"

    PROP_PLAY_LOOPS_NUMBER :: "SDL_mixer.play.loops"
    PROP_PLAY_MAX_FRAME_NUMBER :: "SDL_mixer.play.max_frame"
    PROP_PLAY_MAX_MILLISECONDS_NUMBER :: "SDL_mixer.play.max_milliseconds"
    PROP_PLAY_START_FRAME_NUMBER :: "SDL_mixer.play.start_frame"
    PROP_PLAY_START_MILLISECOND_NUMBER :: "SDL_mixer.play.start_millisecond"
    PROP_PLAY_LOOP_START_FRAME_NUMBER :: "SDL_mixer.play.loop_start_frame"
    PROP_PLAY_LOOP_START_MILLISECOND_NUMBER :: "SDL_mixer.play.loop_start_millisecond"
    PROP_PLAY_FADE_IN_FRAMES_NUMBER :: "SDL_mixer.play.fade_in_frames"
    PROP_PLAY_FADE_IN_MILLISECONDS_NUMBER :: "SDL_mixer.play.fade_in_milliseconds"
    PROP_PLAY_FADE_IN_START_GAIN_FLOAT :: "SDL_mixer.play.fade_in_start_gain"
    PROP_PLAY_APPEND_SILENCE_FRAMES_NUMBER :: "SDL_mixer.play.append_silence_frames"
    PROP_PLAY_APPEND_SILENCE_MILLISECONDS_NUMBER :: "SDL_mixer.play.append_silence_milliseconds"
    PROP_PLAY_HALT_WHEN_EXHAUSTED_BOOLEAN :: "SDL_mixer.play.halt_when_exhausted"

    DURATION_UNKNOWN :: -1
    DURATION_INFINITE :: -2

    when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32 {
        @(default_calling_convention = "c", link_prefix = "MIX_", require_results)
        foreign _ {
            Version :: proc() -> c.int ---
            Init :: proc() -> c.bool ---
            Quit :: proc() ---
            GetNumAudioDecoders :: proc() -> c.int ---
            GetAudioDecoder :: proc(index: c.int) -> cstring ---
            CreateMixerDevice :: proc(devid: sdl.AudioDeviceID, spec: ^sdl.AudioSpec) -> ^Mixer ---
            CreateMixer :: proc(spec: ^sdl.AudioSpec) -> ^Mixer ---
            DestroyMixer :: proc(mixer: ^Mixer) ---
            GetMixerProperties :: proc(mixer: ^Mixer) -> sdl.PropertiesID ---
            GetMixerFormat :: proc(mixer: ^Mixer, spec: ^sdl.AudioSpec) -> c.bool ---
            LockMixer :: proc(mixer: ^Mixer) ---
            UnlockMixer :: proc(mixer: ^Mixer) ---
            LoadAudio_IO :: proc(mixer: ^Mixer, io: ^sdl.IOStream, predecode, closeio: c.bool) -> ^Audio ---
            LoadAudio :: proc(mixer: ^Mixer, path: cstring, predecode: c.bool) -> ^Audio ---
            LoadAudioNoCopy :: proc(mixer: ^Mixer, data: rawptr, datalen: c.size_t, free_when_done: c.bool) -> ^Audio ---
            LoadAudioWithProperties :: proc(props: sdl.PropertiesID) -> ^Audio ---
            LoadRawAudio_IO :: proc(mixer: ^Mixer, io: ^sdl.IOStream, spec: ^sdl.AudioSpec, closeio: c.bool) -> ^Audio ---
            LoadRawAudio :: proc(mixer: ^Mixer, data: rawptr, datalen: c.size_t, spec: ^sdl.AudioSpec) -> ^Audio ---
            LoadRawAudioNoCopy :: proc(mixer: ^Mixer, data: rawptr, datalen: c.size_t, spec: ^sdl.AudioSpec, free_when_done: c.bool) -> ^Audio ---
            CreateSineWaveAudio :: proc(mixer: ^Mixer, hz: c.int, amplitude: c.float, ms: sdl.Sint64) -> ^Audio ---
            GetAudioProperties :: proc(audio: ^Audio) -> sdl.PropertiesID ---
            GetAudioDuration :: proc(audio: ^Audio) -> sdl.Sint64 ---
            GetAudioFormat :: proc(audio: ^Audio, spec: ^sdl.AudioSpec) -> c.bool ---
            DestroyAudio :: proc(audio: ^Audio) ---
            CreateTrack :: proc(mixer: ^Mixer) -> ^Track ---
            DestroyTrack :: proc(track: ^Track) ---
            GetTrackProperties :: proc(track: ^Track) -> sdl.PropertiesID ---
            GetTrackMixer :: proc(track: ^Track) -> ^Mixer ---
            SetTrackAudio :: proc(track: ^Track, audio: ^Audio) -> c.bool ---
            SetTrackAudioStream :: proc(track: ^Track, stream: ^sdl.AudioStream) -> c.bool ---
            SetTrackIOStream :: proc(track: ^Track, io: ^sdl.IOStream, closeio: c.bool) -> c.bool ---
            SetTrackRawIOStream :: proc(track: ^Track, io: ^sdl.IOStream, spec: ^sdl.AudioSpec, closeio: c.bool) -> c.bool ---
            TagTrack :: proc(track: ^Track, tag: cstring) -> c.bool ---
            UntagTrack :: proc(track: ^Track, tag: cstring) ---
            GetTrackTags :: proc(track: ^Track, count: ^c.int) -> [^]cstring ---
            GetTaggedTracks :: proc(mixer: ^Mixer, tag: cstring, count: ^c.int) -> [^]^Track ---
            SetTrackPlaybackPosition :: proc(track: ^Track, frames: sdl.Sint64) -> c.bool ---
            GetTrackPlaybackPosition :: proc(track: ^Track) -> sdl.Sint64 ---
            GetTrackFadeFrames :: proc(track: ^Track) -> sdl.Sint64 ---
            GetTrackLoops :: proc(track: ^Track) -> c.int ---
            SetTrackLoops :: proc(track: ^Track, num_loops: c.int) -> c.bool ---
            GetTrackAudio :: proc(track: ^Track) -> ^Audio ---
            GetTrackAudioStream :: proc(track: ^Track) -> ^sdl.AudioStream ---
            GetTrackRemaining :: proc(track: ^Track) -> sdl.Sint64 ---
            TrackMSToFrames :: proc(track: ^Track, ms: sdl.Sint64) -> sdl.Sint64 ---
            TrackFramesToMS :: proc(track: ^Track, frames: sdl.Sint64) -> sdl.Sint64 ---
            AudioMSToFrames :: proc(audio: ^Audio, ms: sdl.Sint64) -> sdl.Sint64 ---
            AudioFramesToMS :: proc(audio: ^Audio, frames: sdl.Sint64) -> sdl.Sint64 ---
            MSToFrames :: proc(sample_rate: c.int, ms: sdl.Sint64) -> sdl.Sint64 ---
            FramesToMS :: proc(sample_rate: c.int, frames: sdl.Sint64) -> sdl.Sint64 ---
            PlayTrack :: proc(track: ^Track, options: sdl.PropertiesID) -> c.bool ---
            PlayTag :: proc(mixer: ^Mixer, tag: cstring, options: sdl.PropertiesID) -> c.bool ---
            PlayAudio :: proc(mixer: ^Mixer, audio: ^Audio) -> c.bool ---
            StopTrack :: proc(track: ^Track, fade_out_frames: sdl.Sint64) -> c.bool ---
            StopAllTracks :: proc(mixer: ^Mixer, fade_out_ms: sdl.Sint64) -> c.bool ---
            StopTag :: proc(mixer: ^Mixer, tag: cstring, fade_out_ms: sdl.Sint64) -> c.bool ---
            PauseTrack :: proc(track: ^Track) -> c.bool ---
            PauseAllTracks :: proc(mixer: ^Mixer) -> c.bool ---
            PauseTag :: proc(mixer: ^Mixer, tag: cstring) -> c.bool ---
            ResumeTrack :: proc(track: ^Track) -> c.bool ---
            ResumeAllTracks :: proc(mixer: ^Mixer) -> c.bool ---
            ResumeTag :: proc(mixer: ^Mixer, tag: cstring) -> c.bool ---
            TrackPlaying :: proc(track: ^Track) -> c.bool ---
            TrackPaused :: proc(track: ^Track) -> c.bool ---
            SetMixerGain :: proc(mixer: ^Mixer, gain: c.float) -> c.bool ---
            GetMixerGain :: proc(mixer: ^Mixer) -> c.float ---
            SetTrackGain :: proc(track: ^Track, gain: c.float) -> c.bool ---
            GetTrackGain :: proc(track: ^Track) -> c.float ---
            SetTagGain :: proc(mixer: ^Mixer, tag: cstring, gain: c.float) -> c.bool ---
            SetMixerFrequencyRatio :: proc(mixer: ^Mixer, ratio: c.float) -> c.bool ---
            GetMixerFrequencyRatio :: proc(mixer: ^Mixer) -> c.float ---
            SetTrackFrequencyRatio :: proc(track: ^Track, ratio: c.float) -> c.bool ---
            GetTrackFrequencyRatio :: proc(track: ^Track) -> c.float ---
            SetTrackOutputChannelMap :: proc(track: ^Track, chmap: [^]c.int, count: c.int) -> c.bool ---
            SetTrackStereo :: proc(track: ^Track, #by_ptr gains: StereoGains) -> c.bool ---
            SetTrack3DPosition :: proc(track: ^Track, #by_ptr position: Point3D) -> c.bool ---
            GetTrack3DPosition :: proc(track: ^Track, position: ^Point3D) -> c.bool ---
            CreateGroup :: proc(mixer: ^Mixer) -> ^Group ---
            DestroyGroup :: proc(group: ^Group) ---
            GetGroupProperties :: proc(group: ^Group) -> sdl.PropertiesID ---
            GetGroupMixer :: proc(group: ^Group) -> ^Mixer ---
            SetTrackGroup :: proc(track: ^Track, group: ^Group) -> c.bool ---
            SetTrackStoppedCallback :: proc(track: ^Track, cb: TrackStoppedCallback, userdata: rawptr) -> c.bool ---
            SetTrackRawCallback :: proc(track: ^Track, cb: TrackMixCallback, userdata: rawptr) -> c.bool ---
            SetTrackCookedCallback :: proc(track: ^Track, cb: TrackMixCallback, userdata: rawptr) -> c.bool ---
            SetGroupPostMixCallback :: proc(group: ^Group, cb: GroupMixCallback, userdata: rawptr) -> c.bool ---
            SetPostMixCallback :: proc(mixer: ^Mixer, cb: PostMixCallback, userdata: rawptr) -> c.bool ---
            Generate :: proc(mixer: ^Mixer, buffer: rawptr, buflen: c.int) -> c.int ---
            CreateAudioDecoder :: proc(path: cstring, props: sdl.PropertiesID) -> ^AudioDecoder ---
            CreateAudioDecoder_IO :: proc(io: ^sdl.IOStream, closeio: c.bool, props: sdl.PropertiesID) -> ^AudioDecoder ---
            DestroyAudioDecoder :: proc(audiodecoder: ^AudioDecoder) ---
            GetAudioDecoderProperties :: proc(audiodecoder: ^AudioDecoder) -> sdl.PropertiesID ---
            GetAudioDecoderFormat :: proc(audiodecoder: ^AudioDecoder, spec: ^sdl.AudioSpec) -> c.bool ---
            DecodeAudio :: proc(audiodecoder: ^AudioDecoder, buffer: rawptr, buflen: c.int, spec: ^sdl.AudioSpec) -> c.int ---
        }
    } else {
        @(default_calling_convention = "c", link_prefix = "MIX_", require_results)
        foreign lib {
            Version :: proc() -> c.int ---
            Init :: proc() -> c.bool ---
            Quit :: proc() ---
            GetNumAudioDecoders :: proc() -> c.int ---
            GetAudioDecoder :: proc(index: c.int) -> cstring ---
            CreateMixerDevice :: proc(devid: sdl.AudioDeviceID, spec: ^sdl.AudioSpec) -> ^Mixer ---
            CreateMixer :: proc(spec: ^sdl.AudioSpec) -> ^Mixer ---
            DestroyMixer :: proc(mixer: ^Mixer) ---
            GetMixerProperties :: proc(mixer: ^Mixer) -> sdl.PropertiesID ---
            GetMixerFormat :: proc(mixer: ^Mixer, spec: ^sdl.AudioSpec) -> c.bool ---
            LockMixer :: proc(mixer: ^Mixer) ---
            UnlockMixer :: proc(mixer: ^Mixer) ---
            LoadAudio_IO :: proc(mixer: ^Mixer, io: ^sdl.IOStream, predecode, closeio: c.bool) -> ^Audio ---
            LoadAudio :: proc(mixer: ^Mixer, path: cstring, predecode: c.bool) -> ^Audio ---
            LoadAudioNoCopy :: proc(mixer: ^Mixer, data: rawptr, datalen: c.size_t, free_when_done: c.bool) -> ^Audio ---
            LoadAudioWithProperties :: proc(props: sdl.PropertiesID) -> ^Audio ---
            LoadRawAudio_IO :: proc(mixer: ^Mixer, io: ^sdl.IOStream, spec: ^sdl.AudioSpec, closeio: c.bool) -> ^Audio ---
            LoadRawAudio :: proc(mixer: ^Mixer, data: rawptr, datalen: c.size_t, spec: ^sdl.AudioSpec) -> ^Audio ---
            LoadRawAudioNoCopy :: proc(mixer: ^Mixer, data: rawptr, datalen: c.size_t, spec: ^sdl.AudioSpec, free_when_done: c.bool) -> ^Audio ---
            CreateSineWaveAudio :: proc(mixer: ^Mixer, hz: c.int, amplitude: c.float, ms: sdl.Sint64) -> ^Audio ---
            GetAudioProperties :: proc(audio: ^Audio) -> sdl.PropertiesID ---
            GetAudioDuration :: proc(audio: ^Audio) -> sdl.Sint64 ---
            GetAudioFormat :: proc(audio: ^Audio, spec: ^sdl.AudioSpec) -> c.bool ---
            DestroyAudio :: proc(audio: ^Audio) ---
            CreateTrack :: proc(mixer: ^Mixer) -> ^Track ---
            DestroyTrack :: proc(track: ^Track) ---
            GetTrackProperties :: proc(track: ^Track) -> sdl.PropertiesID ---
            GetTrackMixer :: proc(track: ^Track) -> ^Mixer ---
            SetTrackAudio :: proc(track: ^Track, audio: ^Audio) -> c.bool ---
            SetTrackAudioStream :: proc(track: ^Track, stream: ^sdl.AudioStream) -> c.bool ---
            SetTrackIOStream :: proc(track: ^Track, io: ^sdl.IOStream, closeio: c.bool) -> c.bool ---
            SetTrackRawIOStream :: proc(track: ^Track, io: ^sdl.IOStream, spec: ^sdl.AudioSpec, closeio: c.bool) -> c.bool ---
            TagTrack :: proc(track: ^Track, tag: cstring) -> c.bool ---
            UntagTrack :: proc(track: ^Track, tag: cstring) ---
            GetTrackTags :: proc(track: ^Track, count: ^c.int) -> [^]cstring ---
            GetTaggedTracks :: proc(mixer: ^Mixer, tag: cstring, count: ^c.int) -> [^]^Track ---
            SetTrackPlaybackPosition :: proc(track: ^Track, frames: sdl.Sint64) -> c.bool ---
            GetTrackPlaybackPosition :: proc(track: ^Track) -> sdl.Sint64 ---
            GetTrackFadeFrames :: proc(track: ^Track) -> sdl.Sint64 ---
            GetTrackLoops :: proc(track: ^Track) -> c.int ---
            SetTrackLoops :: proc(track: ^Track, num_loops: c.int) -> c.bool ---
            GetTrackAudio :: proc(track: ^Track) -> ^Audio ---
            GetTrackAudioStream :: proc(track: ^Track) -> ^sdl.AudioStream ---
            GetTrackRemaining :: proc(track: ^Track) -> sdl.Sint64 ---
            TrackMSToFrames :: proc(track: ^Track, ms: sdl.Sint64) -> sdl.Sint64 ---
            TrackFramesToMS :: proc(track: ^Track, frames: sdl.Sint64) -> sdl.Sint64 ---
            AudioMSToFrames :: proc(audio: ^Audio, ms: sdl.Sint64) -> sdl.Sint64 ---
            AudioFramesToMS :: proc(audio: ^Audio, frames: sdl.Sint64) -> sdl.Sint64 ---
            MSToFrames :: proc(sample_rate: c.int, ms: sdl.Sint64) -> sdl.Sint64 ---
            FramesToMS :: proc(sample_rate: c.int, frames: sdl.Sint64) -> sdl.Sint64 ---
            PlayTrack :: proc(track: ^Track, options: sdl.PropertiesID) -> c.bool ---
            PlayTag :: proc(mixer: ^Mixer, tag: cstring, options: sdl.PropertiesID) -> c.bool ---
            PlayAudio :: proc(mixer: ^Mixer, audio: ^Audio) -> c.bool ---
            StopTrack :: proc(track: ^Track, fade_out_frames: sdl.Sint64) -> c.bool ---
            StopAllTracks :: proc(mixer: ^Mixer, fade_out_ms: sdl.Sint64) -> c.bool ---
            StopTag :: proc(mixer: ^Mixer, tag: cstring, fade_out_ms: sdl.Sint64) -> c.bool ---
            PauseTrack :: proc(track: ^Track) -> c.bool ---
            PauseAllTracks :: proc(mixer: ^Mixer) -> c.bool ---
            PauseTag :: proc(mixer: ^Mixer, tag: cstring) -> c.bool ---
            ResumeTrack :: proc(track: ^Track) -> c.bool ---
            ResumeAllTracks :: proc(mixer: ^Mixer) -> c.bool ---
            ResumeTag :: proc(mixer: ^Mixer, tag: cstring) -> c.bool ---
            TrackPlaying :: proc(track: ^Track) -> c.bool ---
            TrackPaused :: proc(track: ^Track) -> c.bool ---
            SetMixerGain :: proc(mixer: ^Mixer, gain: c.float) -> c.bool ---
            GetMixerGain :: proc(mixer: ^Mixer) -> c.float ---
            SetTrackGain :: proc(track: ^Track, gain: c.float) -> c.bool ---
            GetTrackGain :: proc(track: ^Track) -> c.float ---
            SetTagGain :: proc(mixer: ^Mixer, tag: cstring, gain: c.float) -> c.bool ---
            SetMixerFrequencyRatio :: proc(mixer: ^Mixer, ratio: c.float) -> c.bool ---
            GetMixerFrequencyRatio :: proc(mixer: ^Mixer) -> c.float ---
            SetTrackFrequencyRatio :: proc(track: ^Track, ratio: c.float) -> c.bool ---
            GetTrackFrequencyRatio :: proc(track: ^Track) -> c.float ---
            SetTrackOutputChannelMap :: proc(track: ^Track, chmap: [^]c.int, count: c.int) -> c.bool ---
            SetTrackStereo :: proc(track: ^Track, #by_ptr gains: StereoGains) -> c.bool ---
            SetTrack3DPosition :: proc(track: ^Track, #by_ptr position: Point3D) -> c.bool ---
            GetTrack3DPosition :: proc(track: ^Track, position: ^Point3D) -> c.bool ---
            CreateGroup :: proc(mixer: ^Mixer) -> ^Group ---
            DestroyGroup :: proc(group: ^Group) ---
            GetGroupProperties :: proc(group: ^Group) -> sdl.PropertiesID ---
            GetGroupMixer :: proc(group: ^Group) -> ^Mixer ---
            SetTrackGroup :: proc(track: ^Track, group: ^Group) -> c.bool ---
            SetTrackStoppedCallback :: proc(track: ^Track, cb: TrackStoppedCallback, userdata: rawptr) -> c.bool ---
            SetTrackRawCallback :: proc(track: ^Track, cb: TrackMixCallback, userdata: rawptr) -> c.bool ---
            SetTrackCookedCallback :: proc(track: ^Track, cb: TrackMixCallback, userdata: rawptr) -> c.bool ---
            SetGroupPostMixCallback :: proc(group: ^Group, cb: GroupMixCallback, userdata: rawptr) -> c.bool ---
            SetPostMixCallback :: proc(mixer: ^Mixer, cb: PostMixCallback, userdata: rawptr) -> c.bool ---
            Generate :: proc(mixer: ^Mixer, buffer: rawptr, buflen: c.int) -> c.int ---
            CreateAudioDecoder :: proc(path: cstring, props: sdl.PropertiesID) -> ^AudioDecoder ---
            CreateAudioDecoder_IO :: proc(io: ^sdl.IOStream, closeio: c.bool, props: sdl.PropertiesID) -> ^AudioDecoder ---
            DestroyAudioDecoder :: proc(audiodecoder: ^AudioDecoder) ---
            GetAudioDecoderProperties :: proc(audiodecoder: ^AudioDecoder) -> sdl.PropertiesID ---
            GetAudioDecoderFormat :: proc(audiodecoder: ^AudioDecoder, spec: ^sdl.AudioSpec) -> c.bool ---
            DecodeAudio :: proc(audiodecoder: ^AudioDecoder, buffer: rawptr, buflen: c.int, spec: ^sdl.AudioSpec) -> c.int ---
        }
    }

    // Keep the older local helper names available while the repo converges on upstream SDL_mixer naming.
    SetMasterGain :: SetMixerGain
    GetMasterGain :: GetMixerGain
    TrackLooping :: proc(track: ^Track) -> bool {
        return GetTrackLoops(track) != 0
    }
}
