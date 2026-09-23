# First server configuration

From here on, everything happens over SSH from your PC. Clone (or copy) this
repo to your PC first if you haven't already, so the scripts referenced
below are at hand.

## 1. Connect

```bash
ssh stefano@192.168.1.10
```

(replace with your own user/IP.)

## 2. Set up the shared config file

On the server:

```bash
git clone <this-repo-url> ~/media-server-setup   # or copy the repo over some other way
cd ~/media-server-setup/scripts
cp 00-config.env.example config.env
nano config.env        # set SERVER_USER, TZ, and disk labels to match your setup
source config.env
```

Every script below expects `config.env` to be sourced first in the same
shell session. If you open a new terminal, `source` it again.

## 3. Base OS setup

This installs the Intel GPU driver, enables the `non-free-firmware` APT
component it needs, updates the system, and turns on automatic security
updates:

```bash
chmod +x *.sh
./01-base-setup.sh
sudo reboot
```

After the reboot, confirm the iGPU is visible:

```bash
ls -l /dev/dri     # expect: card0 (or card1), renderD128
vainfo              # expect a list of H.264/HEVC decode/encode profiles
```

If `/dev/dri` is empty, the kernel driver didn't load — check `dmesg | grep
-i i915` and make sure the reboot actually happened on the new kernel
(`uname -r`).

## 4. Switch to SSH keys (recommended)

Passwords over SSH work, but a key is both more convenient and more secure.
Run this **on your PC**, not the server:

```bash
./scripts/02-setup-ssh-keys.sh stefano 192.168.1.10
```

It generates a key if you don't have one, copies it to the server, tests
key-based login, and prints the two commands to disable password auth on
the server once you've confirmed the key works. Follow that printed
instruction — don't skip the "test in a second terminal" step, or you could
lock yourself out if something's misconfigured.

## What's next

At this point the server has: a working Intel GPU driver, up-to-date
packages, automatic security updates, and (optionally) key-only SSH. Next,
prepare the two USB SSDs: [06-storage-setup.md](06-storage-setup.md).
