#include <sys/mount.h>

int main()
{
    mount("none", "/proc", "proc", 0, NULL);
    mount("none", "/sys", "sysfs", 0, NULL);
    mount("none", "/dev/pts", "devpts", 0, NULL);
    mount("none", "/dev/shm", "tmpfs", 0, NULL);
}
