# Remote desktops

Run either installer as your normal Linux user. Both require systemd, an authenticated Tailscale connection, and a tailscale0 interface.

Both installers include the standard administrative directories in their command search path. If a prerequisite is missing, the error names its package: Tailscale for tailscale, iproute2 for ip and ss, or util-linux for runuser.

## KDE Plasma

Run `bash linux/packages/20-kde-plasma.sh`.

This installs Plasma and its native KRdp server. It requires a distribution that provides the krdp package, such as Debian 13 or Ubuntu 26.04. Debian 12 and Ubuntu 24.04 do not provide this setup in their default repositories.

Log in to Plasma (Wayland), open System Settings > Remote Desktop, add an RDP user and password, and enable the server. Approve screen sharing when prompted. KRdp stores these credentials in KWallet; the installer does not change your Linux account password.

Screen capture requires OpenGL compositing. The installer reports when no DRM graphics device is present.

Sharing uses the logged-in desktop. The installer does not enable automatic local login or provide access to the login screen. Existing RDP users, certificate settings, and the saved port are preserved.

The service binds to the Tailscale IPv4 address. A system-wide service override applies that restriction before installation because Debian can enable KRdp for all users during package setup. The login user's service also receives an override and autostart setting.

To choose a different port, use `KDE_RDP_PORT=3390 bash linux/packages/20-kde-plasma.sh`.

## XFCE

Run `bash linux/packages/21-xrdp-xface.sh`.

This installs XFCE with XRDP and its Xorg backend. Select Xorg on the RDP login screen. Log out of other graphical sessions for the same user before connecting.

XRDP uses the Linux account password. The installer offers to keep an existing password, or lets you set or generate one. It preserves the original .xsession file and stops and masks XRDP if installation or listener verification fails.

## Checks

Run `python3 -B linux/tests/test_remote_desktop_installers.py`.

The tests run the installers against temporary files and command fixtures. They cover package failures, listener restrictions, session backups, symlinks, password preservation, native RDP settings, and private-key permissions. They do not install packages or change real services.

Live checks need an isolated Linux system with systemd and a graphical session. KDE video validation also needs working OpenGL graphics; a QPainter desktop cannot provide screencasting. Docker can validate package installation, but ordinary containers do not provide that complete desktop environment.

## Validation on 2026-10-19

Tests ran on arm64 in disposable containers and isolated Linux machines:

| Environment | Check | Result |
| --- | --- | --- |
| Debian 12, Docker | XFCE packages and the regression suite | Passed |
| Debian 13, systemd | XFCE installation, rerun, and authenticated Xorg desktop login | Passed |
| Ubuntu 24.04, systemd | XFCE installation, rerun, password preservation, file ownership, and authenticated Xorg desktop login | Passed |
| Debian 13, systemd | Native KDE installation, autostart, certificate permissions, and RDP authentication | Passed |
| Ubuntu 26.04, Docker | Native KDE package resolution | Passed |

Bash syntax checks, ShellCheck, and all ten regression tests passed.

Live tests used a dummy tailnet interface rather than a real Tailscale account. Native KDE video validation did not pass: the test machines had no DRM graphics device, KWin used QPainter, and the RDP client received blank frames. KDE video still needs verification on a Plasma Wayland desktop with OpenGL compositing. KWin's capture requirement is documented in its [source code](https://github.com/KDE/kwin/blob/Plasma/6.3/src/plugins/screencast/screencaststream.cpp#L338).
