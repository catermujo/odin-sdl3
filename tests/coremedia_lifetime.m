#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#include "SDL.h"
#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <stdatomic.h>
#include "camera_layout.h"
static dispatch_semaphore_t iterate_entered, iterate_resume;
static _Atomic bool iterate_finished;
static void SDL_CameraPermissionOutcome(SDL_Camera *device, bool approved) {
    SDL_LockMutex(device->lock);
    device->permission = approved ? SDL_CAMERA_PERMISSION_STATE_APPROVED : SDL_CAMERA_PERMISSION_STATE_DENIED;
    SDL_UnlockMutex(device->lock);
}
static bool SDL_CameraThreadIterate(SDL_Camera *device) {
    SDL_LockMutex(device->lock);
    SDL_UnlockMutex(device->lock);
    if (iterate_entered) {
        dispatch_semaphore_signal(iterate_entered);
        assert(dispatch_semaphore_wait(iterate_resume, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC)) == 0);
        atomic_store(&iterate_finished, true);
    }
    return true;
}
#define SDLPrivateCameraData CoreMediaLifetimePrivateCameraData
#define SDLCaptureVideoDataOutputSampleBufferDelegate CoreMediaLifetimeSampleDelegate
#include "coremedia_backend.h"
static void late_callback(void) {
    SDL_Camera *device = calloc(1, sizeof(*device));
    device->lock = SDL_CreateMutex();
    device->permission = SDL_CAMERA_PERMISSION_STATE_APPROVED;
    SDLCaptureVideoDataOutputSampleBufferDelegate *delegate = [[SDLCaptureVideoDataOutputSampleBufferDelegate alloc] init:device];
    SDLPrivateCameraData *hidden = [SDLPrivateCameraData new];
    hidden.delegate = delegate;
    device->hidden = (void *)CFBridgingRetain(hidden);
    SDL_LockMutex(device->lock);
    COREMEDIA_CloseDevice(device);
    SDL_UnlockMutex(device->lock);
    SDL_DestroyMutex(device->lock);
    free(device);
    dispatch_queue_t queue = dispatch_queue_create("coremedia-late-callback", DISPATCH_QUEUE_SERIAL);
    dispatch_sync(queue, ^{ [delegate captureOutput:nil didOutputSampleBuffer:NULL fromConnection:nil]; });
    puts("late callback safely ignored");
}
static void contended_callback(void) {
    SDL_Camera *device = calloc(1, sizeof(*device));
    device->lock = SDL_CreateMutex();
    device->permission = SDL_CAMERA_PERMISSION_STATE_APPROVED;
    SDLCaptureVideoDataOutputSampleBufferDelegate *delegate = [[SDLCaptureVideoDataOutputSampleBufferDelegate alloc] init:device];
    SDLPrivateCameraData *hidden = [SDLPrivateCameraData new];
    hidden.delegate = delegate;
    device->hidden = (void *)CFBridgingRetain(hidden);
    SDL_LockMutex(device->lock);
    dispatch_queue_t queue = dispatch_queue_create("coremedia-contended-callback", DISPATCH_QUEUE_SERIAL);
    dispatch_semaphore_t done = dispatch_semaphore_create(0);
    dispatch_async(queue, ^{ [delegate captureOutput:nil didOutputSampleBuffer:NULL fromConnection:nil]; dispatch_semaphore_signal(done); });
    assert(dispatch_semaphore_wait(done, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC)) == 0);
    COREMEDIA_CloseDevice(device);
    SDL_UnlockMutex(device->lock);
    SDL_DestroyMutex(device->lock);
    free(device);
    puts("contended callback does not block teardown");
}
static void inflight_callback(void) {
    SDL_Camera *device = calloc(1, sizeof(*device));
    device->lock = SDL_CreateMutex();
    device->permission = SDL_CAMERA_PERMISSION_STATE_APPROVED;
    SDLCaptureVideoDataOutputSampleBufferDelegate *delegate = [[SDLCaptureVideoDataOutputSampleBufferDelegate alloc] init:device];
    SDLPrivateCameraData *hidden = [SDLPrivateCameraData new];
    hidden.delegate = delegate;
    device->hidden = (void *)CFBridgingRetain(hidden);
    iterate_entered = dispatch_semaphore_create(0);
    iterate_resume = dispatch_semaphore_create(0);
    atomic_store(&iterate_finished, false);
    dispatch_queue_t queue = dispatch_queue_create("coremedia-inflight-callback", DISPATCH_QUEUE_SERIAL);
    dispatch_semaphore_t done = dispatch_semaphore_create(0);
    dispatch_async(queue, ^{ [delegate captureOutput:nil didOutputSampleBuffer:NULL fromConnection:nil]; dispatch_semaphore_signal(done); });
    assert(dispatch_semaphore_wait(iterate_entered, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC)) == 0);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 20 * NSEC_PER_MSEC), dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        dispatch_semaphore_signal(iterate_resume);
    });
    SDL_LockMutex(device->lock);
    COREMEDIA_CloseDevice(device);
    assert(atomic_load(&iterate_finished));
    SDL_UnlockMutex(device->lock);
    SDL_DestroyMutex(device->lock);
    free(device);
    assert(dispatch_semaphore_wait(done, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC)) == 0);
    iterate_entered = nil;
    iterate_resume = nil;
    puts("inflight callback completes before state is freed");
}
int main(void) {
    @autoreleasepool {
        late_callback();
        contended_callback();
        inflight_callback();
    }
    return 0;
}
