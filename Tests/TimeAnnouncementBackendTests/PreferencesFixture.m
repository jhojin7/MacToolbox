#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <string.h>

// Interpose only in the standalone test process. No real preferences or speech
// services are changed. The real Swift system backend and shim remain in use.
#define INTERPOSE(replacement, original) \
    __attribute__((used)) static struct { const void *new; const void *old; } \
    interpose_##original __attribute__((section("__DATA,__interpose"))) = \
    { (const void *)&replacement, (const void *)&original };

static NSDictionary *preferences;
static int applyCount;
static bool applySucceeds = true;

static bool isSpeechDomain(CFStringRef domain) {
    return CFEqual(domain, CFSTR("com.apple.speech.synthesis.general.prefs"));
}

void MTBFixtureReset(void) {
    preferences = @{
        @"TimeAnnouncementsEnabled": @1,
        @"TimeAnnouncementsIntervalIdentifier": @"EveryQuarterHourInterval",
        @"TimeAnnouncementsVoiceSettings": @{@"CustomVolume": @0.36}
    };
    applyCount = 0;
    applySucceeds = true;
}
int MTBFixtureApplyCount(void) { return applyCount; }
void MTBFixtureFailApply(void) { applySucceeds = false; }

static CFPropertyListRef fixtureCopy(CFStringRef key, CFStringRef domain) {
    if (isSpeechDomain(domain) && CFEqual(key, CFSTR("TimeAnnouncementPrefs"))) {
        return CFBridgingRetain(preferences);
    }
    return CFPreferencesCopyAppValue(key, domain);
}
static void fixtureWrite(CFStringRef key, CFPropertyListRef value, CFStringRef domain) {
    if (isSpeechDomain(domain) && CFEqual(key, CFSTR("TimeAnnouncementPrefs"))) {
        preferences = [(__bridge NSDictionary *)value copy];
        return;
    }
    CFPreferencesSetAppValue(key, value, domain);
}
static Boolean fixtureSynchronize(CFStringRef domain) {
    return isSpeechDomain(domain) ? true : CFPreferencesAppSynchronize(domain);
}
static Boolean fixtureApply(CFDictionaryRef value) {
    applyCount++;
    if (!applySucceeds) { return false; }
    preferences = [(__bridge NSDictionary *)value copy];
    return true;
}
static void *fixtureLookup(void *handle, const char *name) {
    if (strcmp(name, "SetTimeAnnouncementsPreferences") == 0) {
        return (void *)&fixtureApply;
    }
    return dlsym(handle, name);
}

INTERPOSE(fixtureCopy, CFPreferencesCopyAppValue)
INTERPOSE(fixtureWrite, CFPreferencesSetAppValue)
INTERPOSE(fixtureSynchronize, CFPreferencesAppSynchronize)
INTERPOSE(fixtureLookup, dlsym)
