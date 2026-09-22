# USB Debugging

USB debugging is the classic ADB path: a cable to the computer, with the
device performing a **RSA-key authorization** when a new host connects.

## Enabling it

1. **Reveal Developer options.** Since Android 4.2 (API 17) the menu is
   hidden; open **Settings → About phone** and tap **Build number** 7 times
   until it says you are a developer. (OEMs can relocate the build-number
   entry; the official guide covers the stock flow.) **[version-sensitive]**
2. **Enable USB debugging**: **Settings → Developer options → USB debugging**.
3. Connect the phone by USB. Depending on your device you may need to pick
   "File transfer / USB debugging" in the USB-mode notification
   **[DEVICE]**.
4. A dialog **"Allow USB debugging?"** appears the first time a computer's
   key connects. It is **required** to proceed — commands cannot run until you
   confirm while the device is unlocked. Checking **"Always allow this
   computer"** stores authorization.
5. Verify:

```
adb devices
```

The device should list with state `device`. If it shows `offline`, check the
cable/port, the USB mode, and that the authorization dialog was accepted.

## The authorization model

- The RSA-key dialog is standard **since Android 4.2.2**. Authorized host keys
  are stored on the device (historically under `/data/misc/adb/`), and the
  pairing flow for Wi‑Fi stores keys in the same way
  (see [Wireless Debugging](03-wireless-debugging.md)).
- To clear all authorization, use **Settings → Developer options → Revoke USB
  debugging authorizations** (exact label varies by Android version
  **[DEVICE]**). After revoking, the next connection shows the dialog again.

## The `adb root` boundary

Within USB (or wireless) debugging, adb normally runs device-side commands as
the **shell** user (uid 2000), not root — see [ADB Shell](04-adb-shell.md).

`adb root` and `adb unroot` restart `adbd` as root, but **only on debuggable
builds** (a developer/engineering image): production builds answer with
"adbd cannot run as root in production builds" (verified from AOSP
`restart_service.cpp`). So:

- On a normal retail phone, `adb shell` is never root, no matter how the
  device is connected.
- Root (or Shizuku/rish-style privileged access) is a separate,
  independently-audited topic covered in later sections of this Bible.

## Security notes

> **Debugging is a capability, not a feature to leave on.** With an
> authorized host, someone can read logs, dump app data the shell can read,
> take screenshots, inject input, and install apps. Practical rules
> (AGENTS.md §11):
>
> - Revoke USB debugging authorizations on a device you lend, sell, or return.
> - Do not plug an unknown cable/computer into a device with debugging
>   enabled without expecting data exposure.
> - Disable USB debugging when you do not need it.

## Troubleshooting

- `adb devices` state `unauthorized` (on the older UI wording) → accept the
  prompt on the phone **while it is unlocked**.
- `offline` → replace the cable (charge-only cables are a common cause), try
  another port, toggling USB debugging, or `adb kill-server` then reconnect.
- Some OEM slow-charging/battery settings block the data line; those are
  device-specific **[DEVICE]** and are not documented as general behavior.

## References

- Official adb reference: developer.android.com/tools/adb.
- AOSP `packages/modules/adb/daemon/restart_service.cpp` (root gating, main).
- Phase 4 research notes: `research/adb/00-adb-research.md` (§4, §11, §12).