# Assembly and first boot

Most N100/N150 mini PCs need no real "assembly" — there's nothing to screw
together. This step is about unboxing, an optional internal check/upgrade,
cabling, and the BIOS settings you should change before installing anything.

## 1. Unbox and inspect

1. Unpack the mini PC, its power adapter, and any accessories (VESA mount,
   screws, HDMI cable).
2. Check the box contents against the listing — some budget brands omit the
   power adapter or ship the wrong region's plug.

## 2. Optional: open the case to check/upgrade RAM and storage

Skip this if your mini PC already has the RAM/storage you ordered and you
don't plan to add an internal NVMe later. If you do want to look inside:

1. Unplug the power adapter first.
2. Most mini PCs open via 4 small screws on the underside (Phillips/JIS
   #0 or #1 bit); a few use a twist-off bottom plate instead. Check the
   specific model's manual/product page — there's real variation here.
3. Inside you'll typically find:
   - One or two **SO-DIMM slots** (or soldered RAM on some models — 16 GB
     soldered is fine, you just can't expand it later).
   - One **M.2 2280 NVMe slot** for the primary boot SSD (should already
     have a drive if you bought it pre-configured), and often a **second,
     smaller M.2 2242 slot** — useful later as extra internal storage
     instead of one of the USB SSDs.
4. To add/swap a NVMe drive: insert at a ~30° angle into the M.2 slot,
   press down flat, and secure with the small screw provided.
5. Close the case, reinsert all screws (don't skip any — they usually also
   hold the case together structurally, not just cosmetically).

## 3. Connect the cables

1. Monitor: HDMI (needed only for the installer; the server runs headless
   afterwards).
2. USB keyboard (needed only for the installer).
3. **Ethernet cable to the router** — do this now; Wi-Fi is not
   recommended for a server that needs to stream reliably to multiple
   devices.
4. **Leave the two USB SSDs unplugged for now.** You'll plug them in after
   Debian is installed, so there's no risk of accidentally installing the
   OS onto one of them instead of the internal NVMe.
5. Power adapter last, then power on.

## 4. BIOS settings

1. As soon as you power on, press the BIOS key repeatedly — usually
   `Del` or `F2` (check your model; the one-time boot-menu key, if you need
   it later, is usually `F7`, `F11` or `F12`).
2. Find the power-loss recovery setting — labeled **"Restore on AC Power
   Loss"**, **"AC Back Function"** or **"State After G3"** depending on the
   BIOS vendor — and set it to **Power On / Always On**. This makes the
   server come back up by itself after a power cut, instead of staying off
   until someone physically presses the power button.
3. While you're in there, it's worth disabling any "fast boot" option that
   skips the boot-menu prompt, so you can reach the USB boot menu reliably
   during the OS install.
4. Save and exit (usually `F10`), then let it reboot into the boot menu
   once you have the installer USB ready (next doc).

Next: [03-create-installer-usb.md](03-create-installer-usb.md)
