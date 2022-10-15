use libc::{
    _exit, c_char, close, dup2, execlp, execvp, fork, getpid, ioctl, mkdir, mount, open,
    perror, pid_t, reboot, setenv, setsid, sigfillset, siginfo_t, sigprocmask, sigset_t,
    sigwaitinfo, sync, system, umount, waitpid, ECHILD, EXIT_FAILURE, EXIT_SUCCESS, O_RDONLY,
    O_RDWR, RB_POWER_OFF, SIGCHLD, SIGUSR1, SIG_SETMASK, TIOCSCTTY, WNOHANG,
};
use serde::Deserialize;
use std::ffi::CString;
use std::fs::File;
use std::io::{BufRead, BufReader};
use std::mem;

mod server;

macro_rules! cs {
    ($lit:expr) => {
        std::ffi::CStr::from_ptr(concat!($lit, "\0").as_ptr() as *const std::os::raw::c_char)
            .as_ptr()
    };
}

#[derive(Deserialize,Default)]
struct Config {
    mode: String,
    show_list: Option<i32>
}

unsafe fn run_spawner(orig_sig: *const sigset_t, true_init: bool) -> std::io::Result<pid_t> {
    let mut cmds = Vec::new();

    cmds.push(vec![
        cs!("seatd-launch"),
        cs!("--"),
        cs!("dbus-launch"),
        cs!("Hyprland"),
        cs!("--i-am-really-stupid"),
        std::ptr::null(),
    ]);

    cmds.push(vec![cs!("/usr/libexec/iwd"), std::ptr::null()]);

    let mut ttydev = None;
    if true_init {
        cmds.push(vec![cs!("dhcpcd"), cs!("eth0"), std::ptr::null()]);
        let fp = File::open("/sys/class/tty/console/active");
        if let Ok(fp) = fp {
            let mut reader = BufReader::new(fp);
            let mut line = String::new();
            let len = reader.read_line(&mut line);

            if let Ok(len) = len {
                if len > 0 {
                    line.truncate(len - 1);
                    ttydev = Some(CString::new("/dev/".to_owned() + &line).unwrap());
                }
            }
        }
    }

    let pid = fork();
    if pid > 0 {
        return Ok(pid);
    }
    assert_ne!(pid, -1);

    // memo : should not alloate in child process

    if let Some(ttydev) = ttydev {
        let fd = open(ttydev.as_ptr(), O_RDWR);

        if fd >= 0 {
            dup2(fd, 0);
            dup2(fd, 1);
            dup2(fd, 2);

            close(fd);
        }
    }

    if true_init {
        assert_ne!(setsid(), -1);
        assert_eq!(ioctl(0, TIOCSCTTY, 1), 0);

        assert_eq!(system(cs!("/sbin/udevd -d")), 0);
        assert_eq!(system(cs!("/sbin/udevadm trigger --type=subsystems --action=add")), 0);
        assert_eq!(system(cs!("/sbin/udevadm trigger --type=devices --action=add")), 0);
        assert_eq!(system(cs!("/sbin/udevadm trigger")), 0);
        assert_eq!(system(cs!("dbus-daemon --system")), 0);
    }

    unsafe fn spawn_commands(coms: Vec<Vec<*const i8>>, orig_sig: *const sigset_t) {
        for c in &coms {
            let pid = fork();
            if pid > 0 {
                continue;
            }
            assert_eq!(pid, 0);

            //let null_fd = open(cs!("/dev/null"), O_RDONLY);
            //dup2(null_fd, 1);
            //dup2(null_fd, 2);
            //close(null_fd);

            sigprocmask(SIG_SETMASK, orig_sig, std::ptr::null_mut());
            execvp(c[0], c.as_ptr());
        }
    }

    spawn_commands(cmds, orig_sig);

    let sh_pid = fork();
    if sh_pid == 0 {
        sigprocmask(SIG_SETMASK, orig_sig, std::ptr::null_mut());

        execlp(
            cs!("/bin/sh"),
            cs!("/bin/sh"),
            std::ptr::null() as *const c_char,
        );
        _exit(EXIT_FAILURE);
    }
    assert_ne!(sh_pid, -1);

    let mut sh_st = 0;
    waitpid(sh_pid, &mut sh_st, 0);

    _exit(EXIT_SUCCESS);
}

fn main() -> std::io::Result<()> {
    let config_file = File::open("/etc/firebox.json");
    let mut config :Config = Default::default();

    if let Ok(config_file) = config_file {
        let reader = BufReader::new(config_file);

        if let Ok(c) = serde_json::from_reader(reader) {
            config = c;
        }
    }

    unsafe {
        if config.mode == "installer" {
            system(cs!(
                "find / -mount -type f -print0 | xargs -0 touch -a -d 1980/01/01"
            ));
        }

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
            setenv(cs!("LANG"), cs!("C.utf8"), 1);

            assert_eq!(
                mount(cs!("none"), cs!("/proc"), cs!("proc"), 0, std::ptr::null()),
                0
            );
            assert_eq!(
                mount(cs!("none"), cs!("/sys"), cs!("sysfs"), 0, std::ptr::null()),
                0
            );
            mount(
                cs!("none"),
                cs!("/dev"),
                cs!("devtmpfs"),
                0,
                std::ptr::null(),
            );

            mkdir(cs!("/dev/pts"), 0o0777);
            mkdir(cs!("/dev/shm"), 0o0777);
            mkdir(cs!("/run"), 0o0777);

            mount(cs!("none"), cs!("/run"), cs!("tmpfs"), 0, std::ptr::null());
            mkdir(cs!("/run/dbus"), 0o0777);
            mkdir(cs!("/run/user"), 0o0777);
            mkdir(cs!("/run/user/1"), 0o0700);

            assert_eq!(
                mount(
                    cs!("none"),
                    cs!("/dev/pts"),
                    cs!("devpts"),
                    0,
                    std::ptr::null()
                ),
                0
            );
            assert_eq!(
                mount(
                    cs!("none"),
                    cs!("/dev/shm"),
                    cs!("tmpfs"),
                    0,
                    std::ptr::null()
                ),
                0
            );

            assert_eq!(system(cs!("ip l set lo up")), 0);
            assert_eq!(system(cs!("ip a add 127.0.0.1 dev lo")), 0);
        }

        server::start_server()?;
        let spawner_pid = run_spawner(orig.as_ptr(), true_init)?;

        'wait_children: loop {
            let mut cur = mem::MaybeUninit::<siginfo_t>::uninit();

            let r = sigwaitinfo(allsig.as_ptr(), cur.as_mut_ptr());

            if r < 0 {
                break;
            }

            let cur = cur.as_ptr();

            match (*cur).si_signo {
                SIGCHLD => 'no_wait: loop {
                    let mut st = 0;
                    let pid = waitpid(-1, &mut st, WNOHANG);
                    match pid {
                        -1 => {
                            let e = std::io::Error::last_os_error();
                            if e.raw_os_error() == Some(ECHILD) {
                                break 'no_wait;
                            } else {
                                perror(cs!("unknown wait error"));
                            }
                        }

                        0 => {
                            break 'no_wait;
                        }

                        pid => {
                            if pid == spawner_pid {
                                break 'wait_children;
                            }
                        }
                    }
                },

                SIGUSR1 => {
                    break 'wait_children;
                }

                _ => {
                    println!("unknown sig");
                }
            }
        }
        let mut spawner_st = 0;
        waitpid(spawner_pid, &mut spawner_st, 0);

        println!("bye!");

        if config.mode == "installer" {
            system(cs!(
                r#"find -L ./ -mount -not -name ".cache" -not -name ".mozilla" -not -amin +1000 -type f -print0 > /touch_files.txt"#
            ));

            if let Some(_) = config.show_list {
                system(cs!(
                    r#"less /touch_files.txt"#
                ));
            }
            system(cs!(
                r#"equery -C f eudev kmod | cut -d' ' -f1 > /additional_files.txt"#
            ));
        }

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
