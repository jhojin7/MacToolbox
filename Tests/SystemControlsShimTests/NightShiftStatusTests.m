#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <string.h>

#import "SystemControlsShim.h"

static BOOL fixtureActive;
static BOOL fixtureEnabled;
static BOOL fixtureReadSucceeds = YES;

// Replace only the getter in this test process. Never call setEnabled: or
// change the system's Night Shift configuration.
static BOOL fixtureStatus(id self, SEL command, void *status) {
    memset(status, 0, 128);
    ((unsigned char *)status)[0] = fixtureActive;
    ((unsigned char *)status)[1] = fixtureEnabled;
    return fixtureReadSucceeds;
}

int main(void) {
    @autoreleasepool {
        NSBundle *bundle = [NSBundle bundleWithPath:
            @"/System/Library/PrivateFrameworks/CoreBrightness.framework"];
        if (![bundle load]) {
            fprintf(stderr, "CoreBrightness is unavailable\n");
            return 2;
        }

        Class clientClass = NSClassFromString(@"CBBlueLightClient");
        Method getter = class_getInstanceMethod(
            clientClass, NSSelectorFromString(@"getBlueLightStatus:")
        );
        if (!getter) {
            fprintf(stderr, "The Night Shift status getter is unavailable\n");
            return 2;
        }

        IMP originalGetter = method_setImplementation(getter, (IMP)fixtureStatus);
        int failures = 0;
        for (int active = 0; active < 2; active++) {
            for (int enabled = 0; enabled < 2; enabled++) {
                fixtureActive = active;
                fixtureEnabled = enabled;
                bool observed = MTBNightShiftIsEnabled();
                bool passed = observed == enabled;
                printf("active=%d enabled=%d observed=%d: %s\n",
                    active, enabled, observed, passed ? "PASS" : "FAIL");
                failures += !passed;
            }
        }

        fixtureReadSucceeds = NO;
        bool failedReadPassed = !MTBNightShiftIsEnabled();
        printf("Failed status read: %s\n", failedReadPassed ? "PASS" : "FAIL");
        failures += !failedReadPassed;
        method_setImplementation(getter, originalGetter);
        return failures ? 1 : 0;
    }
}
