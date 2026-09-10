#pragma once

// The early runtime hook arms the watchdog automatically for a valid TRIAL
// journal. These helpers are safe to call unconditionally from normal startup.
bool firmware_trial_active();
void firmware_trial_watchdog_feed();
bool firmware_trial_confirm();
