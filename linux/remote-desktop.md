# Remote desktops

Run either installer over SSH as your normal Linux user, or with sudo from that account. Both require Debian or Ubuntu, systemd, an authenticated Tailscale connection, and a tailscale0 interface.

Both installers include the standard administrative directories in their command search path. Missing-command errors name the package to install: Tailscale, iproute2 for ip and ss, or util-linux for runuser.

## Included apps

Both installers include everyday apps and add their launchers to the application menu:

| Purpose | KDE Plasma | XFCE |
| --- | --- | --- |
| Browser | Firefox | Firefox |
| File manager | Dolphin | Thunar |
| Terminal | Konsole | XFCE Terminal |
| Text editor | Kate | Mousepad |
| PDF viewer | Okular | Atril |
| Image viewer | Gwenview | Ristretto |
| Archives | Ark | File Roller |
| Screenshots | Spectacle | XFCE Screenshooter |
| Calculator | KCalc | Galculator |
| System monitor | Plasma System Monitor | XFCE Task Manager |
| Media player | VLC | VLC |

ZIP and XZ archive support, desktop link handlers, and standard user-folder setup are included. Existing user-folder paths and application defaults are preserved. LibreOffice is not included.

Debian uses Firefox ESR from its own repositories. Ubuntu uses native Firefox from [Mozilla's signed APT repository](https://support.mozilla.org/en-US/kb/install-firefox-linux). The installer checks Mozilla's signing key and restricts its APT preferences to Firefox packages. The repository remains configured so APT can update the browser.

Existing browser profiles and Firefox Snap installations are preserved. Native Firefox does not automatically import a Snap profile; use Firefox Sync or Mozilla's profile migration instructions if needed.

To add these apps to an existing setup, rerun the installer for your desktop. Keep the repository's linux/lib directory alongside linux/packages; the installers share their browser setup through that helper.

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

Run the syntax, ShellCheck, and browser setup checks before installing:

```bash
bash -n linux/lib/desktop-apps.sh linux/packages/20-kde-plasma.sh linux/packages/21-xrdp-xface.sh
shellcheck -x linux/lib/desktop-apps.sh linux/packages/20-kde-plasma.sh linux/packages/21-xrdp-xface.sh
python3 -B linux/tests/test_desktop_apps.py
```

Package checks alone do not verify desktop login. Test installation and an authenticated RDP connection on an isolated Linux system with systemd.

## Validation on 2026-10-19

The complete app bundles were tested from clean, disposable arm64 Linux machines:

| Environment | Desktop | Browser | Result |
| --- | --- | --- | --- |
| Debian 13 | KDE Plasma X11 | Debian Firefox ESR | Passed |
| Debian 13 | XFCE X11 | Debian Firefox ESR | Passed |
| Ubuntu 24.04 | KDE Plasma X11 | Mozilla native Firefox | Passed |
| Ubuntu 24.04 | XFCE X11 | Mozilla native Firefox | Passed |

Each run installed the desktop without the essential-packages script, reran the installer from another directory with a restricted user PATH, and authenticated through XRDP. Tests launched the browser, file manager, terminal, editor, PDF viewer, image viewer, archive manager, and VLC. Application menu entries were present. Browser pages and sample video frames were visually checked.

Firefox rendered a local test page with a seccomp-sandboxed content process. The tests did not disable its sandbox.

Reruns preserved the Linux password, original session backup, browser profile files, Snap profile fixtures, custom Documents path, and user file associations. On Ubuntu, repository, key, and preference files stayed unchanged. An epoch-version transitional Firefox DEB fixture was replaced with the native package through a full installer rerun.

Ten focused regression tests passed for source reuse, conflicting or insecure sources, signing-key rejection, native package selection, Firefox-only downgrades, and configuration preservation. Bash syntax checks and ShellCheck passed for both installers and the shared helper.

Earlier isolated checks also verified session symlink rejection, Xorg backend port preservation, native KRdp service migration, and KDE's custom port setting.

The live tests used a dummy tailscale0 interface and a Tailscale command fixture. They verified binding to that interface's address; they did not exercise authentication to a real Tailscale account or connections between tailnet devices.
