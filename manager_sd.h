#pragma once

// Initialize/mount once, only when a boot source or supervisor operation needs SD.
// A failed attempt is cached for this boot, as with the previous startup mount.
bool manager_sd_mount();
bool manager_sd_is_mounted();
