#ifndef SystemControlsShim_h
#define SystemControlsShim_h

#include <stdbool.h>
#include <CoreFoundation/CoreFoundation.h>

bool MTBColorFilterIsAvailable(void);
bool MTBColorFilterIsEnabled(void);
bool MTBSetColorFilterEnabled(bool enabled);

bool MTBNightShiftIsAvailable(void);
bool MTBNightShiftIsEnabled(void);
bool MTBSetNightShiftEnabled(bool enabled);
bool MTBStartNightShiftStatusNotifications(void);

bool MTBSetTimeAnnouncementPreferences(CFDictionaryRef preferences);

#endif
