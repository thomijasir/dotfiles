# Remote desktops

Run either installer over SSH as your normal Linux user, or with sudo from that account. Both require Debian or Ubuntu, systemd, an authenticated Tailscale connection, and a tailscale0 interface.

Both installers include the standard administrative directories in their command search path. Missing-command errors name the package to install: Tailscale, iproute2 for ip and ss, or util-linux for runuser.

## KDE Plasma X11

Run `bash linux/packages/20-kde-plasma.sh`.

This installs XRDP, its Xorg backend, and KDE Plasma with the X11 window manager. Select Xorg at the XRDP login screen and use your Linux username and password. XRDP starts the desktop when you connect, so setup needs no local graphical login or display manager.

The installer offers to keep an existing Linux account password, or lets you set or generate one. It saves the original .xsession as .xsession.before-xrdp-kde and writes a session that starts Plasma X11 with its own D-Bus session. Log out of other graphical sessions for the same user before connecting. Running both desktop installers for the same user changes that user's next XRDP session to the last desktop installed.

If native KRdp is installed, the installer stops and masks its service for the selected user. Its settings and certificates remain available. To use native KRdp again later, stop XRDP, unmask app-org.kde.krdpserver.service in the user's systemd manager, and configure a Plasma Wayland session.

XRDP listens only on the current Tailscale IPv4 address, on TCP port 3389. To choose another port, run `KDE_RDP_PORT=3390 bash linux/packages/20-kde-plasma.sh`. If installation or listener verification fails after XRDP is masked, the services stay masked until setup completes successfully.

The distribution must provide plasma-workspace with startplasma-x11, kwin-x11, and xorgxrdp. A Wayland-only Plasma build cannot run this setup. This installer does not add third-party repositories to obtain X11 packages.

## XFCE

Run `bash linux/packages/21-xrdp-xface.sh`.

This installs XFCE with XRDP and its Xorg backend. Select Xorg on the RDP login screen and use your Linux account password. The installer offers to keep an existing password, or lets you set or generate one.

It preserves the original .xsession as .xsession.before-xrdp-xfce and stops and masks XRDP if installation or listener verification fails. Log out of other graphical sessions for the same user before connecting.

## Checks

Run Bash syntax checks and ShellCheck before installing:

```bash
bash -n linux/packages/20-kde-plasma.sh linux/packages/21-xrdp-xface.sh
shellcheck linux/packages/20-kde-plasma.sh linux/packages/21-xrdp-xface.sh
```

Package checks alone do not verify desktop login. Test installation and an authenticated RDP connection on an isolated Linux system with systemd.

## Validation on 2026-10-19

Earlier XFCE checks passed on Debian 13 and Ubuntu 24.04 in isolated arm64 Linux machines: installation, rerun, and authenticated Xorg desktop login. Debian 12 package installation also passed in Docker.

The KDE XRDP installer passed these checks in disposable arm64 Linux machines:

| Environment | Checks | Result |
| --- | --- | --- |
| Debian 13, Plasma 6 | Installation, rerun, password and backup preservation, Tailscale address binding, and authenticated Plasma X11 desktop login | Passed |
| Ubuntu 24.04, Plasma 5 | Installation as a normal user with a restricted PATH, custom port 3390, rerun, password and backup preservation, address binding, and authenticated Plasma X11 desktop login | Passed |

Both machines had no GPU device or prior graphical login. Captured desktop frames showed the Plasma panel and wallpaper.

Focused Docker checks passed for session file ownership, backup preservation on reruns, symlink rejection, and XRDP configuration that preserves the Xorg backend ports. Native KRdp migration passed with both an active user service and no running user bus. The active service was stopped and masked while its configuration was preserved.

Bash syntax checks and ShellCheck passed for both installers.

The live tests used a dummy tailscale0 interface and a Tailscale command fixture. They verified binding to that interface's address; they did not exercise authentication to a real Tailscale account or connections between tailnet devices.
