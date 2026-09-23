# Create the Debian installer USB

Do this on your everyday PC (Windows, macOS or Linux) — not on the mini PC.

## 1. Download the Debian image

1. Go to [debian.org/download](https://www.debian.org/download) and get the
   **amd64 netinst** ISO for the current stable release (Debian 13,
   "trixie", as of this guide — the site always points at the current
   stable point release, e.g. `debian-13.7.0-amd64-netinst.iso`).
2. Optional but recommended: verify the download against the `SHA256SUMS`
   file published next to it on the same page, so a corrupted download
   doesn't waste an install attempt:
   ```bash
   sha256sum debian-13.*-amd64-netinst.iso
   # compare against the matching line in SHA256SUMS
   ```
   "netinst" means most packages are fetched over the network during
   install — that's expected and handled automatically as long as the
   server has Ethernet connected (see the previous doc).

## 2. Write it to a USB stick

Use a stick of at least 1 GB — it will be **completely erased**.

### Windows

1. Download [Rufus](https://rufus.ie).
2. Plug in the USB stick.
3. Open Rufus → Device: select your stick → Boot selection: click
   **SELECT** and choose the ISO → Start.
4. If prompted to choose an image-writing mode, pick **DD Image mode** (not
   ISO mode) — this makes the stick boot exactly like the official Debian
   installer expects.

### macOS or Linux

1. Identify the stick's device name — **be certain**, this step is
   destructive to whatever you pick:
   - Linux: `lsblk` (look for the matching size, e.g. `sdb`, not the size of
     your internal disk).
   - macOS: `diskutil list` (look for `/dev/diskN` matching the stick's
     size).
2. Either run the provided script, which adds confirmation prompts:
   ```bash
   ./scripts/local/make-installer-usb.sh debian-13.7.0-amd64-netinst.iso /dev/sdX
   ```
   (macOS: pass `/dev/diskN`, e.g. `/dev/disk4` — the script handles
   unmounting and uses the raw `/dev/rdiskN` device for faster writes.)
3. …or run the `dd` command by hand:
   ```bash
   sudo dd if=debian-13.*-amd64-netinst.iso of=/dev/sdX bs=4M status=progress conv=fsync
   ```
   Double- and triple-check `of=` before pressing Enter — `dd` will overwrite
   whatever device you point it at without asking again.

## 3. Next

Unplug the stick once the write finishes and `sync` has completed (the
script/command above waits for that automatically). Plug it into the mini
PC and move on to [04-install-debian.md](04-install-debian.md).
