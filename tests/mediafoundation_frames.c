#define COBJMACROS
#define SDL_MAIN_HANDLED
#include <windows.h>
#include <mfapi.h>
#include <mfidl.h>
#include <assert.h>
#include <stdio.h>
#include <SDL3/SDL.h>

typedef enum { SDL_CAMERA_FRAME_ERROR = -1, SDL_CAMERA_FRAME_READY = 1 } SDL_CameraFrameResult;
typedef struct { IMFSample *current_sample; int pitch; } CameraHidden;
struct SDL_Camera { CameraHidden *hidden; };
static bool hide_2d2;
static HRESULT query_buffer(IMFMediaBuffer *buffer, const IID *iid, void **object)
{
    if (hide_2d2 && iid->Data1 == 0x33ae5ea6) {
        *object = NULL;
        return E_NOINTERFACE;
    }
    return buffer->lpVtbl->QueryInterface(buffer, iid, object);
}
#undef IMFMediaBuffer_QueryInterface
#define IMFMediaBuffer_QueryInterface(buffer, iid, object) query_buffer(buffer, iid, object)
#include "mediafoundation_backend.h"

static void require_hr(HRESULT result)
{
    if (FAILED(result)) {
        fprintf(stderr, "Media Foundation failed: 0x%08lx\n", result);
        exit(1);
    }
}

static BYTE color(int x, int y) { return (BYTE)(x * 7 + y * 31); }

static void fill(BYTE *top, LONG pitch, int width, int height)
{
    for (int y = 0; y < height; ++y) {
        BYTE *row = top + y * pitch;
        for (int x = 0; x < width * 3; ++x) row[x] = color(x, y);
    }
}

static void verify(SDL_Surface *frame)
{
    assert(frame->pitch >= frame->w * 3);
    for (int y = 0; y < frame->h; ++y) {
        const BYTE *row = (const BYTE *)frame->pixels + y * frame->pitch;
        for (int x = 0; x < frame->w * 3; ++x) assert(row[x] == color(x, y));
    }
}

static void guard_frame(int width, int height, int pitch)
{
    const int length = pitch * (height - 1) + width * 3;
    SYSTEM_INFO info;
    GetSystemInfo(&info);
    SIZE_T committed = (length + info.dwPageSize - 1) / info.dwPageSize * info.dwPageSize;
    BYTE *region = VirtualAlloc(NULL, committed + info.dwPageSize, MEM_RESERVE, PAGE_NOACCESS);
    assert(region);
    assert(VirtualAlloc(region, committed, MEM_COMMIT, PAGE_READWRITE));
    BYTE *base = region + committed - length;
    BYTE *top = base + (height - 1) * pitch;
    fill(top, -pitch, width, height);
    SDL_Surface *frame = SDL_CreateSurfaceFrom(width, height, SDL_PIXELFORMAT_RGB24, NULL, 0);
    assert(frame);
    assert(MEDIAFOUNDATION_CopyFrame(frame, top, -pitch, length) == SDL_CAMERA_FRAME_READY);
    verify(frame);
    MEDIAFOUNDATION_ReleaseFrame(NULL, frame);
    frame->pixels = NULL;
    SDL_DestroySurface(frame);
    VirtualFree(region, 0, MEM_RELEASE);
    printf("guarded %dx%d bottom-up frame: passed\n", width, height);
}

static void media_frame(int width, int height, bool bottom_up, bool two_dimensional)
{
    printf("testing Media Foundation %s %dx%d %s\n", two_dimensional ? "2D" : "memory", width, height,
           bottom_up ? "bottom-up" : "top-down");
    IMFMediaBuffer *buffer = NULL;
    LONG pitch = (width * 3 + 3) & ~3;
    if (two_dimensional) {
        require_hr(MFCreate2DMediaBuffer(width, height, 20, bottom_up, &buffer));
        IMF2DBuffer *buffer2d = NULL;
        require_hr(IMFMediaBuffer_QueryInterface(buffer, &SDL_IID_IMF2DBuffer, (void **)&buffer2d));
        BYTE *top = NULL;
        require_hr(IMF2DBuffer_Lock2D(buffer2d, &top, &pitch));
        assert((pitch < 0) == bottom_up);
        fill(top, pitch, width, height);
        require_hr(IMF2DBuffer_Unlock2D(buffer2d));
        IMF2DBuffer_Release(buffer2d);
    } else {
        require_hr(MFCreateMemoryBuffer(pitch * height, &buffer));
        BYTE *base = NULL;
        DWORD maximum = 0, length = 0;
        require_hr(IMFMediaBuffer_Lock(buffer, &base, &maximum, &length));
        BYTE *top = bottom_up ? base + pitch * (height - 1) : base;
        if (bottom_up) pitch = -pitch;
        fill(top, pitch, width, height);
        require_hr(IMFMediaBuffer_Unlock(buffer));
        require_hr(IMFMediaBuffer_SetCurrentLength(buffer, abs(pitch) * height));
    }
    IMFSample *sample = NULL;
    require_hr(MFCreateSample(&sample));
    require_hr(IMFSample_SetSampleTime(sample, 12345));
    require_hr(IMFSample_AddBuffer(sample, buffer));
    IMFMediaBuffer_Release(buffer);
    CameraHidden hidden = {sample, pitch};
    SDL_Camera camera = {&hidden};
    SDL_Surface *frame = SDL_CreateSurfaceFrom(width, height, SDL_PIXELFORMAT_RGB24, NULL, 0);
    assert(frame);
    Uint64 timestamp = 0;
    float rotation = 0;
    assert(MEDIAFOUNDATION_AcquireFrame(&camera, frame, &timestamp, &rotation) == SDL_CAMERA_FRAME_READY);
    assert(timestamp == 1234500);
    assert(hidden.current_sample == NULL);
    verify(frame);
    MEDIAFOUNDATION_ReleaseFrame(&camera, frame);
    frame->pixels = NULL;
    SDL_DestroySurface(frame);
    printf("Media Foundation %s %dx%d %s: passed\n", two_dimensional ? "2D" : "memory", width, height,
           bottom_up ? "bottom-up" : "top-down");
}

static void passthrough(SDL_PixelFormat format, int pitch, int length)
{
    BYTE input[128];
    assert((size_t)length <= sizeof(input));
    for (int i = 0; i < length; ++i) input[i] = (BYTE)i;
    SDL_Surface frame = {0};
    frame.w = 8;
    frame.h = 4;
    frame.format = format;
    assert(MEDIAFOUNDATION_CopyFrame(&frame, input, pitch, length) == SDL_CAMERA_FRAME_READY);
    assert(frame.pitch == pitch);
    assert(memcmp(frame.pixels, input, length) == 0);
    MEDIAFOUNDATION_ReleaseFrame(NULL, &frame);
    puts("positive-pitch full payload: passed");
}

int main(int argc, char **argv)
{
    setvbuf(stdout, NULL, _IONBF, 0);
    SetErrorMode(SEM_FAILCRITICALERRORS | SEM_NOGPFAULTERRORBOX);
    if (argc == 2 && strcmp(argv[1], "guard") == 0) {
        guard_frame(640, 480, 1920);
        return 0;
    }
    require_hr(CoInitializeEx(NULL, COINIT_MULTITHREADED));
    require_hr(MFStartup(MF_VERSION, MFSTARTUP_LITE));
    for (int two_dimensional = 0; two_dimensional < 2; ++two_dimensional) {
        for (int bottom_up = 0; bottom_up < 2; ++bottom_up) {
            media_frame(640, 480, bottom_up, two_dimensional);
            media_frame(3, 3, bottom_up, two_dimensional);
        }
    }
    hide_2d2 = true;
    media_frame(640, 480, false, true);
    media_frame(640, 480, true, true);
    media_frame(3, 3, true, true);
    guard_frame(640, 480, 1920);
    guard_frame(3, 3, 12);
    passthrough(SDL_PIXELFORMAT_NV12, 8, 48);
    passthrough(SDL_PIXELFORMAT_MJPG, 100, 100);
    MFShutdown();
    CoUninitialize();
    return 0;
}
