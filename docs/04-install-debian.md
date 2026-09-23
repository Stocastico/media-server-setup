# Install Debian

With the installer USB plugged into the mini PC (monitor, keyboard and
Ethernet connected, the two media SSDs still **unplugged**):

1. Power on, press the one-time boot-menu key (`F7`/`F11`/`F12`, model-
   dependent) and pick the USB stick.

## The installer, screen by screen

1. **Install** (the graphical installer works too, but the text installer is
   lighter and perfectly fine for a headless server). Language: English (or
   your preference). Location and keyboard layout: your own.
2. **Hostname**: `mediaserver` (or your choice — used throughout this
   guide). Leave the **domain** field empty.
3. **Root password**: leave it empty/blank. Debian then installs `sudo` and
   grants admin rights to the user you create next, which is the normal
   setup for a personal server (no separate root login needed).
4. **Create your user** (e.g. `stefano`) with a strong password. This
   account is what everything in this repo assumes — replace `stefano`
   with your own username consistently across every doc and script.
5. **Partitioning**: *Guided – use entire disk* → select the **internal
   NVMe** (double-check the size shown matches the NVMe, not a USB stick —
   this is exactly why the media SSDs stay unplugged during install) → *All
   files in one partition* → *Finish partitioning and write changes* →
   *Yes*.
6. **Package mirror**: pick your country, then the default mirror
   (`deb.debian.org` works everywhere).
7. **Software selection**: **untick** "Debian desktop environment" and
   "GNOME" (this is a headless server, a desktop just wastes RAM/disk and
   widens the attack surface) — **tick** "SSH server" and "standard system
   utilities".
8. **Install GRUB** to the internal NVMe when asked.
9. Remove the USB stick when prompted, then reboot.

## First login

1. Log in on the console with the user you created.
2. Note the server's IP address:
   ```bash
   ip -4 addr show | grep inet
   ```
3. In your router's admin page, create a **DHCP reservation** (sometimes
   called a "static lease") for that IP, keyed to the mini PC's MAC address,
   so the address never changes. Every doc after this one assumes a fixed
   IP — without a reservation, the server can silently move to a different
   address after a reboot or router restart.

You're done with the console/keyboard/monitor for the server itself from
here on — everything else happens over SSH from your PC.

Next: [05-first-server-configuration.md](05-first-server-configuration.md)
