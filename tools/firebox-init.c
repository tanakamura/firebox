#include <sys/mount.h>
#include <sys/reboot.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <unistd.h>

#include "firebox-server.h"

static void
fail(const char *path, int line) {
    printf("%s:%d fail\n", path, line);
}

#define CHECK(r) { int r2 = (r); if (r2<0) { fail(__FILE__,__LINE__); } }


int main()
{

    setenv("PATH", "/sbin:/usr/sbin:/bin:/usr/bin:$PATH", 1);
    setenv("HOME", "/root", 1);

    CHECK(mount("none", "/proc", "proc", 0, NULL));
    CHECK(mount("none", "/sys", "sysfs", 0, NULL));
    CHECK(mount("none", "/dev", "devtmpfs", 0, NULL));

    CHECK(mkdir("/dev/pts", 0777));
    CHECK(mkdir("/dev/shm", 0777));

    CHECK(mount("none", "/dev/pts", "devpts", 0, NULL));
    CHECK(mount("none", "/dev/shm", "tmpfs", 0, NULL));

    CHECK(system("ip a add 127.0.0.1 dev lo"));
    CHECK(system("ip l set lo up"));

    {
        FILE *fp = fopen("/sys/class/tty/console/active", "rb");
        if (fp) {
            char buf[256] = "/dev/";
            ssize_t rdsz = fread(buf+5, 1, 256-4, fp);
            if (rdsz != -1) {
                buf[rdsz+4] = '\0';
            }

            int fd = open(buf, O_RDWR);
            if (fd >= 0) {
                dup2(fd, 0);
                dup2(fd, 1);
                dup2(fd, 2);
            }
            close(fd);
        }
    }

    CHECK(setsid());
    CHECK(ioctl(0, TIOCSCTTY, 1));
    puts("Welcome to FireBox system!");

    start_firebox_server();

    pid_t child;
    if ( (child=vfork()) == 0 ) {
        setsid();
        int null = open("/dev/null", O_WRONLY);
        dup2(null, 1);
        dup2(null, 2);
        close(null);
        execlp("xinit", "xinit", NULL);
        _exit(EXIT_FAILURE);
    }
    pid_t child_sh;
    if ( (child_sh=fork()) == 0) {
        execlp("/bin/sh", "/bin/sh", NULL);
        _exit(EXIT_FAILURE);
    }

    int st;
    wait(&st);
    wait(&st);
    puts("bye!");

    umount("/dev/shm");
    umount("/dev/pts");
    umount("/dev/dev");
    umount("/dev/sys");
    umount("/dev/proc");

    sync();

    int pid = vfork();
    if (pid == 0) {
        reboot(RB_POWER_OFF);
        _exit(EXIT_SUCCESS);
    }
    while (1) {
        sleep(1);
    }
}
