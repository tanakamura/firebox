use libc::{getpid, mount, mkdir, system, open, setsid, ioctl, TIOCSCTTY, setenv,
 O_RDWR, dup2, close, fork, execlp, _exit, EXIT_FAILURE, c_char, umount, sync, RB_POWER_OFF, reboot, EXIT_SUCCESS, waitpid, O_WRONLY};
use std::fs::File;
use std::io::{BufReader, BufRead};
use std::ffi::CString;

mod server;

macro_rules! cs {
    ($lit:expr) => {
        std::ffi::CStr::from_ptr(concat!($lit, "\0").as_ptr() as *const std::os::raw::c_char).as_ptr()
    }
}

fn main() -> std::io::Result<()> {
    unsafe {
        let true_init = getpid() == 1;
        println!("Welcome to FireBox system!");

        if true_init {
            setenv(cs!("PATH"), cs!("/sbin:/usr/sbin:/bin:/usr/bin"), 1);
            setenv(cs!("HOME"), cs!("/root"), 1);
            setenv(cs!("XDG_RUNTIME_DIR"), cs!("/run/user/0"), 1);

            assert_eq!(mount(cs!("none"), cs!("/proc"), cs!("proc"), 0, std::ptr::null()), 0);
            assert_eq!(mount(cs!("none"), cs!("/sys"), cs!("sysfs"), 0, std::ptr::null()), 0);
            mount(cs!("none"), cs!("/dev"), cs!("devtmpfs"), 0, std::ptr::null());

            mkdir(cs!("/dev/pts"), 0o0777);
            mkdir(cs!("/dev/shm"), 0o0777);
            mkdir(cs!("/run"), 0o0777);
            mkdir(cs!("/run/user"), 0o0777);
            mkdir(cs!("/run/user/0"), 0o0700);

            assert_eq!(mount(cs!("none"), cs!("/dev/pts"), cs!("devpts"), 0, std::ptr::null()), 0);
            assert_eq!(mount(cs!("none"), cs!("/dev/shm"), cs!("tmpfs"), 0, std::ptr::null()), 0);

            assert_eq!(system(cs!("ip l set lo up")), 0);
            assert_eq!(system(cs!("ip a add 127.0.0.1 dev lo")), 0);
            assert_eq!(system(cs!("ip l set eth0 up")), 0);
            assert_eq!(system(cs!("ip a add 192.168.1.51/24 dev eth0")), 0);
            assert_eq!(system(cs!("ip route add default via 192.168.1.1")), 0);
        }


        server::start_server()?;

        if true_init {
            let fp = File::open("/sys/class/tty/console/active");
            if let Ok(fp) = fp {
                let mut reader = BufReader::new(fp);
                let mut line = String::new();
                let len = reader.read_line(&mut line);

                if let Ok(len) = len {
                    if len > 0 {
                        line.truncate(len-1);
                        let ttydev = CString::new("/dev/".to_owned() + &line).unwrap();
                        let fd = open(ttydev.as_ptr(), O_RDWR);

                        if fd >= 0 {
                            dup2(fd, 0);
                            dup2(fd, 1);
                            dup2(fd, 2);

                            close(fd);
                        }
                    }
                }
            }
            assert_ne!(setsid(), -1);
            assert_eq!(ioctl(0, TIOCSCTTY, 1), 0);

            assert_eq!(system(cs!("/sbin/udevd -d")), 0);
            assert_eq!(system(cs!("/sbin/udevadm trigger")), 0);
        }

        let winsys_pid = fork();
        if winsys_pid == 0 {
            if true_init {
                setsid();
                let nullfd = open(cs!("/dev/null"), O_WRONLY);
                //dup2(nullfd, 1);
                //dup2(nullfd, 2);
                close(nullfd);
            }
            execlp(cs!("dbus-launch"), cs!("dbus-launch"),
                   cs!("seatd-launch"), cs!("--"),
                   cs!("Hyprland"), cs!("--i-am-really-stupid"),
                   std::ptr::null::<*const i8>());
            _exit(EXIT_FAILURE);
        }
        assert_ne!(winsys_pid, -1);

        let sh_pid = fork();
        if sh_pid == 0 {
            execlp(cs!("/bin/sh"), cs!("/bin/sh"), std::ptr::null() as *const c_char);
            _exit(EXIT_FAILURE);
        }
        assert_ne!(sh_pid, -1);


        let mut winsys_st = 0;
        waitpid(winsys_pid, &mut winsys_st, 0);

        let mut sh_st = 0;
        waitpid(sh_pid, &mut sh_st, 0);

        println!("bye!");

        if true_init {
            umount(cs!("/dev/shm"));
            umount(cs!("/dev/pts"));
            umount(cs!("/dev"));
            umount(cs!("/proc"));
            umount(cs!("/sys"));

            sync();

            let pid = fork();
            if pid == 0 {
                reboot(RB_POWER_OFF);
                _exit(EXIT_SUCCESS);
            }

            loop {
                libc::sleep(1);
            }
        }

    }
    Ok(())
}

