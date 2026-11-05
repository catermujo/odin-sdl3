#define SDL_MAIN_HANDLED
#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>
#include <assert.h>
#include <stdio.h>

/* DUMBAI: Drive real SDL migration with dummy hardware, without changing the host's default output. */
typedef struct SDL_AudioDevice SDL_AudioDevice;
extern SDL_AudioDevice *SDL_AddAudioDevice(bool recording, const char *name, const SDL_AudioSpec *spec, void *handle);
extern void SDL_DefaultAudioDeviceChanged(SDL_AudioDevice *device);

static void migrate_and_close(const int order[3], bool occupied, int switches)
{
    assert(SDL_SetHint(SDL_HINT_AUDIO_DRIVER, "dummy"));
    assert(SDL_Init(SDL_INIT_AUDIO));
    assert(SDL_strcmp(SDL_GetCurrentAudioDriver(), "dummy") == 0);
    const SDL_AudioSpec spec = { SDL_AUDIO_F32, 2, 48000 };
    SDL_AudioDeviceID devices[3] = {0};
    SDL_AudioStream *streams[3] = {0};
    for (int i = 0; i < 2; ++i) {
        devices[i] = SDL_OpenAudioDevice(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, &spec);
        assert(devices[i]);
    }

    int handle;
    SDL_AudioDevice *target = SDL_AddAudioDevice(false, "migration target", &spec, &handle);
    assert(target);
    if (occupied) {
        int count;
        SDL_AudioDeviceID *physical = SDL_GetAudioPlaybackDevices(&count);
        for (int i = 0; i < count; ++i) {
            if (SDL_strcmp(SDL_GetAudioDeviceName(physical[i]), "migration target") == 0) {
                devices[2] = SDL_OpenAudioDevice(physical[i], &spec);
            }
        }
        SDL_free(physical);
        assert(devices[2]);
    }
    for (int i = 0; i < 3; ++i) {
        if (!devices[i]) continue;
        streams[i] = SDL_CreateAudioStream(&spec, &spec);
        assert(streams[i] && SDL_BindAudioStream(devices[i], streams[i]));
    }
    for (int i = 0; i < switches; ++i) {
        SDL_DefaultAudioDeviceChanged(target);
        if (i + 1 < switches) {
            /* DUMBAI: Give each migration a fresh physical destination to exercise repeated list relinking. */
            target = SDL_AddAudioDevice(false, "next migration target", &spec, streams[i]);
            assert(target);
        }
    }
    for (int i = 0; i < 3; ++i) {
        int index = order[i];
        if (!devices[index]) continue;
        SDL_CloseAudioDevice(devices[index]);
        SDL_DestroyAudioStream(streams[index]);
    }
    SDL_Quit();
}

int main(void)
{
    /* DUMBAI: This standalone test supplies main instead of SDL's platform entry wrapper. */
    SDL_SetMainReady();
    const int orders[][3] = {{0, 1, 2}, {0, 2, 1}, {1, 0, 2}, {1, 2, 0}, {2, 0, 1}, {2, 1, 0}};
    for (int occupied = 0; occupied < 2; ++occupied) {
        for (int switches = 1; switches <= 3; ++switches) {
            for (int i = 0; i < SDL_arraysize(orders); ++i) {
                migrate_and_close(orders[i], occupied, switches);
            }
        }
    }
    puts("36 default-output migration and shutdown cases passed");
    return 0;
}
