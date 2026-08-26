#pragma once

#include <stdbool.h>
#include <stdint.h>

struct SupervisorReconfigureRequest {
    uint8_t context;
};

void supervisor_service_init(bool sd_mounted);
bool supervisor_service_once(SupervisorReconfigureRequest* request);
