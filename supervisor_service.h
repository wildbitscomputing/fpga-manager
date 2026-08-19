#pragma once

#include <stdbool.h>
#include <stdint.h>

void supervisor_service_init(bool sd_mounted);
bool supervisor_service_once(uint8_t* reconfigure_slot);
