use libc::{getpid, mount, mkdir, system, open, setsid, ioctl, TIOCSCTTY, setenv,
           O_RDWR, dup2, close, fork, execlp, execvp, _exit, EXIT_FAILURE, c_char, umount, sync, RB_POWER_OFF, reboot, EXIT_SUCCESS, waitpid,
           sigfillset, sigset_t, sigprocmask, SIG_SETMASK, pid_t, siginfo_t, sigwaitinfo,
           CLD_EXITED, CLD_KILLED, CLD_DUMPED, c_int, SIGCHLD, SIGUSR1, sleep, puts};
use std::fs::File;
use std::io::{BufReader, BufRead};
use std::ffi::CString;
use std::mem;

mod server;

macro_rules! cs {
    ($lit:expr) => {
        std::ffi::CStr::from_ptr(concat!($lit, "\0").as_ptr() as *const std::os::raw::c_char).as_ptr()
    }
}

unsafe fn run_spawner(orig_sig : *const sigset_t, true_init: bool) -> std::io::Result<pid_t> {
    let pid = fork();
    if pid > 0 {
        return Ok(pid);
    }
    assert_ne!(pid, -1);

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
        assert_eq!(system(cs!("dbus-daemon --system")), 0);
    }

    unsafe fn spawn_commands(coms: Vec< Vec<&str>>, orig_sig:*const sigset_t ) {
        for c in &coms {
            let mut vec = Vec::new();
            let mut ptrvec = Vec::new();
            for s in c {
                let c = CString::new(*s);
                ptrvec.push( c.as_ref().unwrap().as_ptr() );
                vec.push(c);
            }

            ptrvec.push( std::ptr::null() );

            let pid = fork();
            if pid > 0 {
                sleep(4);
                continue;
            }
            assert_eq!(pid, 0);

            sigprocmask(SIG_SETMASK, orig_sig, std::ptr::null_mut());
            execvp(ptrvec[0], ptrvec.as_ptr());
        }
    }

    let coms = vec![vec!["seatd-launch", "--", "dbus-launch", "Hyprland", "--i-am-really-stupid"],
                    vec!["/usr/libexec/iwd"],
                    vec!["dhcpcd", "eth0"],
    ];

    spawn_commands(
        coms, orig_sig
    );

//    let winsys_pid = fork();
//    if winsys_pid == 0 {
//        sigprocmask(SIG_SETMASK, orig_sig, std::ptr::null_mut());
//        execlp(cs!("seatd-launch"), cs!("seatd-launch"), cs!("--"),
//               cs!("dbus-launch"),
//               cs!("Hyprland"), cs!("--i-am-really-stupid"),
//               //cs!("weston"),
//               std::ptr::null::<*const i8>());
//        _exit(EXIT_FAILURE);
//    }
//    assert_ne!(winsys_pid, -1);
//
//    let iwd_pid = fork();
//    if iwd_pid == 0 {
//        sigprocmask(SIG_SETMASK, orig_sig, std::ptr::null_mut());
//        execlp(cs!("/usr/libexec/iwd"), cs!("/usr/libexec/iwd"),
//               std::ptr::null::<*const i8>());
//        _exit(EXIT_FAILURE);
//    }
//    assert_ne!(iwd_pid, -1);

    if true_init {
        assert_eq!(system(cs!("dhcpcd eth0")), 0);
    }

    let sh_pid = fork();
    if sh_pid == 0 {
        sigprocmask(SIG_SETMASK, orig_sig, std::ptr::null_mut());

        execlp(cs!("/bin/sh"), cs!("/bin/sh"), std::ptr::null() as *const c_char);
        _exit(EXIT_FAILURE);
    }
    assert_ne!(sh_pid, -1);

    let mut sh_st = 0;
    waitpid(sh_pid, &mut sh_st, 0);

    println!("sh exit");

    _exit(EXIT_SUCCESS);
}


fn main() -> std::io::Result<()> {
    unsafe {
        let true_init = getpid() == 1;
        println!("Welcome to FireBox system!");

        let mut allsig = mem::MaybeUninit::<sigset_t>::uninit();
        let mut orig = mem::MaybeUninit::<sigset_t>::uninit();

        sigfillset(allsig.as_mut_ptr());
        sigprocmask(SIG_SETMASK, allsig.as_ptr(), orig.as_mut_ptr());

        if true_init {
            setenv(cs!("PATH"), cs!("/sbin:/usr/sbin:/bin:/usr/bin"), 1);
            setenv(cs!("HOME"), cs!("/root"), 1);
            setenv(cs!("XDG_RUNTIME_DIR"), cs!("/run/user/1"), 1);

            assert_eq!(mount(cs!("none"), cs!("/proc"), cs!("proc"), 0, std::ptr::null()), 0);
            assert_eq!(mount(cs!("none"), cs!("/sys"), cs!("sysfs"), 0, std::ptr::null()), 0);
            mount(cs!("none"), cs!("/dev"), cs!("devtmpfs"), 0, std::ptr::null());

            mkdir(cs!("/dev/pts"), 0o0777);
            mkdir(cs!("/dev/shm"), 0o0777);
            mkdir(cs!("/run"), 0o0777);
            mkdir(cs!("/run/dbus"), 0o0777);
            mkdir(cs!("/run/user"), 0o0777);
            mkdir(cs!("/run/user/1"), 0o0700);

            assert_eq!(mount(cs!("none"), cs!("/dev/pts"), cs!("devpts"), 0, std::ptr::null()), 0);
            assert_eq!(mount(cs!("none"), cs!("/dev/shm"), cs!("tmpfs"), 0, std::ptr::null()), 0);

            assert_eq!(system(cs!("ip l set lo up")), 0);
            assert_eq!(system(cs!("ip a add 127.0.0.1 dev lo")), 0);
        }

        let spawner_pid = run_spawner(orig.as_ptr(), true_init)?;

        'wait_children: loop {
            let mut cur = mem::MaybeUninit::<siginfo_t>::uninit();

            let r = sigwaitinfo(allsig.as_ptr(), cur.as_mut_ptr());

            if r < 0 {
                break;
            }

            let cur = cur.as_ptr();
            match (*cur).si_signo {
                SIGCHLD => {
                    let mut st = mem::MaybeUninit::<c_int>::uninit();
                    if (*cur).si_code == CLD_EXITED || (*cur).si_code == CLD_KILLED || (*cur).si_code == CLD_DUMPED {
                        waitpid((*cur).si_pid(), st.as_mut_ptr(), 0);
                        if (*cur).si_pid() == spawner_pid {
                            break 'wait_children;
                        }
                    }
                },

                SIGUSR1 => {
                    break 'wait_children;
                },

                _ => {
                    println!("unknown sig");
                },
            }
        }
        let mut spawner_st = 0;
        waitpid(spawner_pid, &mut spawner_st, 0);

        println!("bye!");
        sleep(4);

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

