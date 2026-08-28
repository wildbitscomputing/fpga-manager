#pragma once

#include <stdbool.h>
#include <stdint.h>

struct SupervisorReconfigureRequest {
    bool restart;
    uint8_t context;
    bool transient;
    uint8_t source;
    char path[192];
};

void supervisor_service_init(bool sd_mounted, uint8_t active_context);
bool supervisor_service_once(SupervisorReconfigureRequest* request);
