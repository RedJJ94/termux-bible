# Databases

MariaDB, PostgreSQL, and Redis are all packaged for Termux and run as
on-device servers under the normal app UID. That means: high ports, custom data
directories under `$PREFIX` or `$HOME`, runit service scripts via
`termux-services`, and all the Android background-lifecycle caveats from
[Development Environment and Constraints](01-development-environment-and-constraints.md#background-execution-and-process-limits).

Versions below are from the 2026-09-22 `termux-main` aarch64 index
**[version-sensitive]**.

## termux-services (runit) — how services run

`termux-services` provides runit on Termux: service directories live under
`$PREFIX/var/service/`, controlled with `sv-enable`, `sv-disable`, `sv`, and
`sv status`; logging goes through `svlogger`.

```sh
pkg install termux-services
sv-enable mysqld          # example: enable the MariaDB service
sv status mysqld
```

Service scripts shipped by packages here include `sshd`, `ssh-agent`
(see [SSH and Remote Access](02-ssh-and-remote-access.md)), `mysqld`, and
`postgres`. Even with a service enabled, Android battery optimization and the
phantom-process killer (Android 12+) can stop daemons **[DEVICE]**; disable
battery optimization for Termux if you rely on a database server.

## MariaDB

Package `mariadb` (2:13.0.2).

- Data directory: `$PREFIX/var/lib/mysql`; socket:
  `$PREFIX/var/run/mysqld.sock`; config under `$PREFIX/etc` (with
  `my.cnf.d`); temp space `$PREFIX/tmp`.
- The postinst initializes the data directory on first install
  (`mariadb-install-db --user=root --auth-root-authentication-method=normal`)
  if it is missing.
- As a service:

```sh
pkg install mariadb termux-services
sv-enable mysqld           # runit runs: exec mysqld --basedir=$PREFIX --datadir=$PREFIX/var/lib/mysql
mysql -u root              # connect via the socket
```

- DEPENDS: `libandroid-support, libbz2, libc++, libcrypt, libedit, liblz4,
  libxml2, liblzma, ncurses, openssl, pcre2, zlib, zstd`.

## PostgreSQL

Package `postgresql` (18.2-1).

- Data directory: the runit service (`postgres`) prefers `~/.postgres` when a
  `postgresql.conf` exists there, otherwise `$PREFIX/var/lib/postgresql`, and
  executes `postgres -D $DATADIR`.
- **Initialize before first start**:

```sh
pkg install postgresql termux-services
initdb -D "$PREFIX/var/lib/postgresql"
sv-enable postgres
psql -l
```

  The exact service-init sequence on a fresh device is `[needs verification]`
  **[DEVICE]** — the pattern above is standard but confirm the data-dir choice
  on your own install.
- Keep its Android shim libraries installed — `initdb` failures have been
  traced to missing symbols; `libandroid-shmem` and `libandroid-execinfo` are
  hard dependencies.
- DEPENDS include `libicu, libpq, libuuid, libxml2, openssl, readline, zlib`
  plus the shim libs.

## Redis

Package `redis` (1:8.10.2).

- Installs `redis.conf` to `$PREFIX/etc/redis.conf` (mode 600). DEPENDS
  `libandroid-execinfo, libandroid-glob`.
- **No default runit service script ships** with the package
  `[needs verification]` whether a later release added one — `termux-services`
  users create their own service file. A minimal manual start:

```sh
pkg install redis
redis-server --port 6379 --daemonize no   # foreground, or configure a runit service
redis-cli ping                            # -> PONG
```

  Redis running as a Termux process is unprivileged; the default port is its
  normal 6379 (above 1024, so binding is allowed).

## Security notes

- Termux database servers listen (or socket-bind) **inside the app sandbox**.
  The default `mysql`/`psql`/`redis` configuration is not a hardened network
  service: do not expose them to the LAN/WAN without authentication, TLS, and
  a deliberate config review. Unprivileged binding means **no ports below
  1024**.
- The data directories contain your data; back them up with the rest of
  `$PREFIX`/`$HOME` ([Backup, Restore, and Reset](../01-termux/08-backup-restore-reset.md)).

## Native Termux vs. proot

Inside proot-distro, `postgresql`/`mariadb-server`/`redis-server` come from the
guest's repositories with desktop-style paths (`/var/lib/...`, `/etc/...`) and
their own initialization steps. Do not point Termux-native clients at a
guest's data directory or vice versa.

## Cross-references

- Running long-lived processes: [Processes and Sessions](../00-foundations/06-processes-and-sessions.md)
- Background limits that stop servers:
  [Development Environment and Constraints](01-development-environment-and-constraints.md#background-execution-and-process-limits)
- Testing a server from the shell: `curl`, `nc`, `socat` in
  [Networking (Shell Bible)](../02-shell/07-networking.md) and
  [Networking and Developer Utilities](11-networking-and-developer-utilities.md)
- SSH/sshd as another runit service: [SSH and Remote Access](02-ssh-and-remote-access.md)

## References

- Phase 7 research notes §8–§9:
  `research/development/03-build-dev-tools-editors-databases-research.md`.
- Versions/deps verified against the `termux-main` (aarch64) index and the
  `termux/termux-packages` master build.sh files for mariadb, postgresql,
  redis, and termux-services, fetched 2026-09-22.