#include <unistd.h>

#include "firebox-server.h"

int main()
{
    start_firebox_server();
    while (1) {
        sleep(1000);
    }
}
