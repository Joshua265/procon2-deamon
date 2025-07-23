# ProCon2‑Daemon

Run the Nintendo **Pro Controller 2 (PID 0x2069)** on Linux without patching the kernel.

- 🔌 USB handshake → unlocks HID mode
- 🎮 Translates to a single **uinput** game‑pad (ABS axes + buttons)
- 🧊 Ships a Nix flake (`nix run .#procon2-daemon`)

---

## Build & run (any distro)

```bash
git clone https://github.com/Joshua265/procon2-daemon
cargo r --release          # sudo or setcap cap_sys_rawio
```

Open `evtest` – pick **ProCon2 (virt)**. Sticks = ±32 767, buttons light up.

### NixOS (one‑liner)

```bash
nix run github:Joshua265/procon2-daemon       # builds + runs
```

Add to `configuration.nix` for auto‑start:

```nix
services.procon2.enable = true;
```

---

## Stop Steam from reading the raw pad

Steam ≥2024 has no UI toggle for wired Nintendo pads, but you can blacklist it.

1. Exit Steam.
2. Edit `~/.steam/steam/config/config.vdf` and add:

   ```
   "controller_blacklist"      "057E/2069"
   ```

3. Save & restart Steam – only **ProCon2 (virt)** appears.

_(The daemon can also grab evdev for you; see \***\*`--grab`\*\*** flag.)_

---

## Roadmap

- Bluetooth pairing helper (USB → BlueZ)

PRs welcome! 🎉
