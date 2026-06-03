#include <stdio.h>
#include "commons.h"

void CommonRails_printSystemComponent(const char *hash, int code, const char *message)
{
    (void)hash; (void)code;
    if (message) {
        printf("[CommonRails] %s\n", message);
    }
}
