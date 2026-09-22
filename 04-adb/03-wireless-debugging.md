# Wireless Debugging

Wireless debugging lets a host reach `adbd` over the network instead of a USB
cable. There are two distinct mechanisms, and it matters which one you are
using:

1. **Wireless debugging (Android 11+)** — the modern **TLS**-based
   **pairing** flow. TL;DR: enable the toggle, pair once, reconnect
   automatically on the same network.
2. **`adb tcpip` (legacy, ≤ Android 10)** — a plain TCP service on 5555 that
   is **RSA-authenticated but unencrypted**. Use only on trusted networks.

## Wireless debugging (Android 11+)

Prerequisites and behavior (verified against the official reference):

- **Android 11 (API 30)+** for phones; **Android 13 (API 33)+** for **TV and
  Wear OS**. **[version-sensitive]**
- The device and the host must be on the **same wireless network**.
- Enable **Settings → Developer options → Wireless debugging**. A quick toggle
  is also available in the Quick-settings developer tiles.

### Pairing (one-time)

The device shows an **IP:port** plus a **6-digit pairing code**. On the host:

```
adb pair 192.168.1.50:37001
# → prompts for the pairing code; enter the 6 digits
```

- After pairing, the host **auto-connects** to the device. Verify:

```
adb devices
```

The wireless device shows up looking like an `ipaddr:port`, e.g.

```
192.168.1.50:38907  device
```

- Pairing is a **one-time** step: the device stays paired to that workstation
  until you forget it or revoke authorizations, and it reconnects
  automatically when both are on the same network.
- **Trusted network:** when the device asks "Always allow debugging on this
  network?", accepting makes that network a *trusted wireless debugging
  network* and future connections skip the prompt.
- **QR pairing** is a phone-scan flow (used by Android Studio): the QR encodes
  the pairing secret as a `WIFI:T:ADB;...` string plus a requested pairing
  service name. On the command line, `adb pair` prompts for the numeric code;
  there is no "scan QR from the shell".

### Unpairing / revoking

- Device side: **Developer options → Wireless debugging → Paired devices →
  Forget**, which removes that workstation.
- "**Revoke USB debugging authorizations**" (or the equivalent) removes all
  workstations, wired and wireless **[DEVICE: exact label varies]**.

### How pairing works (internals)

Clarifying with AOSP `adb_wifi.md` (a development doc; markup translated):

- Trust starts from a **shared secret**: the **6-digit pairing code**, or the
  **10-digit payload** inside the QR code.
- The pairing exchange is an **RSA-2048** x509 key exchange; the host's
  authorized public keys are stored on-device in **`/data/misc/adb/adb_keys`**
  (also `/adb_keys` in root/recovery contexts).
- Two handshake classes exist:
  - **TLS (`A_STLS`)** — used by modern wireless debugging;
  - **legacy `A_AUTH`** — the non-TLS RSA handshake, used by the legacy
    `adb tcpip` service.
- These correspond to separate mDNS advertising types, and the TLS pairing and
  connect servers bind to a **random port** (not fixed 5555).

## mDNS, server status, and "ADB Wi-Fi 2.0"

- The network glue is **mDNS**. On the host, `adb server-status` should show
  `version: "37.0.0"` (or higher) and `mdns_enabled: true`. If mDNS was
  disabled, set `ADB_MDNS=1`, then `adb kill-server` and run any adb command
  to restart the server. **[version-sensitive]**
- Watch the announcements with:

```
adb mdns track-services --proto-text
```

  A paired device advertises a `_adb-tls-connect._tcp` service with the device
  IP and port; a newer device also reports `mdns_service_version`.
- **ADB Wi-Fi 2.0 (Android 17 + adb 37.0.0)**: the device automatically
  connects to the workstation when it joins a *trusted wireless debugging
  network*. Confirmed for your setup when `adb mdns track-services` shows
  `mdns_service_version: "2.0"` or higher. **[version-sensitive]**
- **Termux `adb` (android-tools) has mDNS disabled** in its current build
  (verified 2026-09-22) — so `adb mdns`, `adb server-status` mDNS fields, and
  Wi-Fi 2.0 auto-connect are **not available** from that build's client. The
  manual `adb pair` / `adb devices` flow above works regardless because
  pairing uses a direct address. Check the package again if the recipe changes
  when you read this. **[version-sensitive]**

## Legacy `adb tcpip` (≤ Android 10 path)

The official ≤Android 10 flow (still documented; it works on Android 11+ if
you start with a USB step):

```
# 1. Make sure device and computer are on the same Wi-Fi network.
# 2. Connect via USB and switch adbd to TCP:
adb tcpip 5555
# 3. Disconnect USB; note the device's IP (e.g. Settings → About → Status).
# 4. Connect over the network:
adb connect 192.168.1.50:5555
# 5. Check:
adb devices         # shows 192.168.1.50:5555  device
```

- If the connection drops, re-run `adb connect ...`; if that fails,
  `adb kill-server` and start over from step 4. The device must be on a
  firewall-friendly access point (client isolation or mDNS blocking break
  this). **[DEVICE]**
- **Security — important (kept accurate per audit):** legacy `adb tcpip` is
  **NOT "unauthenticated"**. It still performs the legacy **RSA `A_AUTH`**
  handshake, and a new host must still be RSA-authorized on the device.
  The real caveat is **traffic is unencrypted plaintext** over the network:
  an on-path observer/MITM can read (and potentially alter) the session. Use
  it **only on trusted networks** (AGENTS.md §11), and prefer the TLS pairing
  flow on Android 11+ whenever possible.

> **Warning — do not combine casually:** leaving `adb tcpip 5555` active with
> a wireless-debugging device on a public network exposes an unencrypted adb
> service. Disable wireless debugging when not in use, and revoke
> authorizations when the device changes hands.

## Common issues

- **Pairing service doesn't show up / code rejected** → same-network check
  (host Wi-Fi vs device cellular/VPN), client-isolation, or VPN interference.
  **[DEVICE]**
- **Termux client drops Wi-Fi 2.0 features** → expected mDNS-off limitation;
  use manual `adb pair`.
- **Authorization timeout kills active sessions** → Android 11+ exposes a
  developer option "Disable adb authorization timeout" (documented in the
  Shizuku setup guide and recommended there to keep sessions alive). That
  option is preserved/covered by the later privileged-access section of this
  Bible; mention it here because it affects plain wireless-debugging sessions.

## References

- Official adb reference: developer.android.com/tools/adb (wireless
  debugging, "Resolve wireless connection issues").
- AOSP `packages/modules/adb/docs/dev/adb_wifi.md`.
- Phase 4 research notes: `research/adb/00-adb-research.md` (§5–§7, §11).