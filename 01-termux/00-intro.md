# Termux

This section covers the Termux environment itself: installing it, managing
packages, repositories, storage setup, configuration, the official command
tools, and the add-on apps.

It is the practical counterpart to the conceptual material in
**[Foundations](../00-foundations/00-intro.md)**:

- **Installation** — [Installing Termux](01-installation.md): supported
  sources, requirements, and the mixing-source rule.
- **Package management** — [Package Management](02-package-management.md):
  `pkg`/`apt`, what you can and cannot install.
- **Repositories** — [Repositories and Mirrors](03-repositories.md): the
  official and community package sources and how mirrors work.
- **Storage setup** — [Storage Setup](04-storage-setup.md): running
  `termux-setup-storage` and verifying shared-storage access.
- **Configuration** — [Configuration](05-configuration.md):
  `termux.properties` and the settings it controls (sessions, keyboard,
  shortcuts, etc.).
- **Utilities** — [Termux Utilities](06-utilities.md): the commands that ship
  with the base environment.
- **Add-ons** — [Termux Add-ons](07-add-ons.md): Termux:API, Boot, Widget,
  Styling, Tasker, and more.
- **Maintenance** — [Backup, Restore, and Reset](08-backup-restore-reset.md):
  the tools for backing up and reinitialising `$PREFIX`.

Everything here assumes you understand the environment distinctions and the
filesystem rules from the Foundations section. In particular: package
management described here applies to **native Termux**; a Linux distribution
running inside proot-distro has its own package manager and repositories (see
[Android Sandboxing and Execution Environments](../00-foundations/02-android-sandboxing.md)).