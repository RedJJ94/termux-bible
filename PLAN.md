PLAN.md — Comprehensive Termux Bible Master Plan

1. Project Vision

The Termux Bible is intended to become a comprehensive, practical, research-driven reference for using Termux and Android as a powerful command-line environment.

The project should cover beginner fundamentals through advanced workflows, while remaining useful as a long-term reference for experienced users.

The canonical source will be Markdown.

The documentation should eventually be publishable as an EPUB using Pandoc.

---

2. Core Project Goals

The project should:

- explain Termux from beginner to advanced levels;
- document important shell commands;
- explain Android-specific command-line workflows;
- document ADB and Android debugging;
- document Shizuku;
- document rish;
- document Porter;
- cover development tools;
- cover Git and GitHub;
- cover scripting and automation;
- cover documents, media, and data workflows;
- provide troubleshooting information;
- provide security guidance;
- provide a command encyclopedia;
- provide quick-reference material;
- provide practical examples;
- remain maintainable as Termux and Android evolve.

The project's operating and research rules are defined in "AGENTS.md".

---

3. Project Architecture

The planned repository structure is:

termux-bible/
├── AGENTS.md
├── PLAN.md
├── README.md
├── metadata.yaml
├── epub-style.css
├── build.sh
│
├── 00-foundations/
├── 01-termux/
├── 02-shell/
├── 03-android/
├── 04-adb/
├── 05-shizuku/
├── 06-rish/
├── 07-porter/
├── 08-power-tools/
├── 09-documents-media-data/
├── 10-advanced-termux/
├── 11-git-github/
├── 12-scripting/
├── 13-troubleshooting/
├── 14-security/
├── 15-command-encyclopedia/
├── 16-quick-reference/
│
├── appendices/
└── research/

The structure may evolve if research demonstrates that another organization is substantially better.

---

4. Documentation Volumes

The project is organized conceptually into six major volumes.

Volume I — Foundations

Topics include:

- what Termux is;
- how Termux works;
- installation;
- repositories;
- packages;
- the filesystem;
- storage access;
- basic shell concepts;
- environment variables;
- permissions;
- processes;
- sessions;
- configuration.

Volume II — Shell Command Bible

Topics include:

- navigation;
- files and directories;
- viewing and editing files;
- searching;
- text processing;
- pipes;
- redirection;
- permissions;
- processes;
- networking;
- archives;
- compression;
- system information;
- package management;
- common GNU/Linux utilities.

Volume III — Android Shell and Privileged Access

Topics include:

- Android shell;
- ADB;
- wireless ADB;
- Android debugging;
- Shizuku;
- rish;
- Porter;
- privileged command execution;
- permissions;
- Android-specific utilities;
- interaction between Termux and Android.

Volume IV — Power Tools

Topics include:

- Git;
- GitHub;
- GitHub CLI;
- SSH;
- editors;
- compilers;
- interpreters;
- build tools;
- programming languages;
- databases;
- networking tools;
- APIs;
- automation;
- development environments.

Volume V — Documents, Media, and Data

Topics include:

- PDFs;
- Markdown;
- DOCX;
- EPUB;
- Pandoc;
- images;
- audio;
- video;
- archives;
- JSON;
- CSV;
- XML;
- data conversion;
- document automation;
- file organization.

Volume VI — Advanced Termux and Everyday Use

Topics include:

- advanced shell configuration;
- aliases;
- functions;
- scripting;
- automation;
- background processes;
- notifications;
- Termux:API;
- task automation;
- proot;
- proot-distro;
- Linux distributions;
- remote access;
- servers;
- advanced networking;
- system administration workflows.

---

5. Foundations

The foundations section should establish the concepts required for the rest of the Bible.

Planned topics include:

- Termux terminology;
- Android application sandboxing;
- Termux filesystem;
- "$HOME";
- "$PREFIX";
- external storage;
- "~/storage";
- package repositories;
- package installation;
- updating;
- shell startup files;
- environment variables;
- permissions;
- processes;
- signals;
- jobs;
- foreground/background execution;
- command syntax.

---

6. Termux

The Termux section should document the Termux environment itself.

Topics include:

- installing Termux;
- supported installation sources;
- package management;
- repositories;
- package updates;
- Termux configuration;
- storage setup;
- Termux utilities;
- Termux add-ons;
- Termux:API;
- Termux:Boot;
- Termux:Widget;
- Termux:Styling;
- Termux:Tasker;
- Termux:GUI;
- Termux:Float;
- other relevant Termux components.

---

7. Shell Command Encyclopedia

The command encyclopedia should provide detailed entries for commonly useful commands.

Potential categories include:

Filesystem

- "pwd"
- "ls"
- "cd"
- "mkdir"
- "rmdir"
- "touch"
- "cp"
- "mv"
- "rm"
- "ln"
- "find"
- "locate"

Text

- "cat"
- "less"
- "head"
- "tail"
- "grep"
- "sed"
- "awk"
- "cut"
- "sort"
- "uniq"
- "tr"
- "wc"

Processes

- "ps"
- "top"
- "pgrep"
- "pkill"
- "kill"
- "jobs"
- "fg"
- "bg"

Archives

- "tar"
- "gzip"
- "gunzip"
- "zip"
- "unzip"

Networking

- "curl"
- "wget"
- "ssh"
- "scp"
- "sftp"
- DNS utilities
- socket/network diagnostic utilities

System Information

- "uname"
- "id"
- "whoami"
- "df"
- "du"
- "free"
- "uptime"

The encyclopedia should expand as research identifies additional important commands.

---

8. Android and ADB

The Android section should cover command-line interaction with Android.

Topics include:

- Android shell;
- ADB basics;
- installing ADB;
- connecting devices;
- USB debugging;
- wireless debugging;
- ADB over Wi-Fi;
- "adb shell";
- package management;
- application inspection;
- logcat;
- file transfer;
- screenshots;
- screen recording;
- system information;
- Android properties;
- dumpsys;
- am;
- pm;
- cmd;
- settings;
- input;
- screencap;
- screenrecord.

---

9. Shizuku

The Shizuku section should cover:

- what Shizuku is;
- installation;
- activation;
- supported startup methods;
- wireless debugging;
- ADB-based startup;
- root startup;
- permissions;
- application integration;
- command-line use;
- limitations;
- troubleshooting;
- interaction with Termux.

---

10. rish

The rish section should cover:

- what rish is;
- installation/setup;
- shell usage;
- relationship to privileged Android services;
- interaction with Shizuku;
- interaction with Porter;
- command execution;
- permissions;
- troubleshooting;
- limitations.

---

11. Porter

Porter receives a dedicated section because of its importance to Android privileged command-line workflows.

Planned topics include:

- what Porter is;
- architecture;
- installation;
- command-line access;
- current shell interfaces;
- rish integration where applicable;
- permissions;
- app integration;
- developer integration;
- Termux workflows;
- troubleshooting;
- limitations;
- differences from Shizuku;
- compatibility considerations.

The Porter documentation should reflect the current state of the project and distinguish current functionality from development or planned functionality.

---

12. Power Tools

Planned development and power-user topics include:

- Git;
- GitHub;
- GitHub CLI;
- SSH;
- GPG;
- code editors;
- compilers;
- build systems;
- Python;
- Node.js;
- Java;
- Kotlin;
- Rust;
- Go;
- C/C++;
- shell scripting;
- databases;
- web development;
- local servers;
- networking;
- automation.

The exact tool list may expand as the project develops.

---

13. Documents, Media, and Data

This section should document practical Termux workflows for handling common files.

Topics include:

- Markdown;
- DOCX;
- PDF;
- EPUB;
- Pandoc;
- LibreOffice-compatible formats;
- text files;
- CSV;
- JSON;
- XML;
- YAML;
- images;
- audio;
- video;
- metadata;
- compression;
- conversion;
- batch processing.

---

14. Advanced Termux

Advanced topics include:

- proot;
- proot-distro;
- Ubuntu;
- Debian;
- other Linux distributions;
- chroot concepts;
- SSH servers;
- remote access;
- local web servers;
- databases;
- background services;
- automation;
- cron-like solutions;
- shell customization;
- advanced networking;
- environment management;
- development environments.

---

15. Git and GitHub

A dedicated Git/GitHub section should cover:

- Git installation;
- repository initialization;
- cloning;
- remotes;
- branches;
- commits;
- merging;
- rebasing;
- pull requests;
- tags;
- releases;
- GitHub CLI;
- authentication;
- HTTPS authentication;
- SSH authentication;
- SSH keys;
- commit signing;
- verified commits;
- GitHub Actions;
- repository maintenance.

---

16. Scripting and Automation

Topics include:

- shell scripts;
- Bash;
- POSIX shell concepts;
- variables;
- conditionals;
- loops;
- functions;
- arguments;
- exit codes;
- traps;
- process management;
- text processing;
- automation;
- scheduled tasks;
- Android integration;
- Termux:API;
- notification workflows.

---

17. Troubleshooting Encyclopedia

The troubleshooting section should organize problems by symptom and environment.

Potential categories:

- package installation failures;
- repository problems;
- storage permission problems;
- command not found;
- permission denied;
- broken PATH;
- shell startup problems;
- networking problems;
- DNS problems;
- Git problems;
- GitHub authentication problems;
- ADB problems;
- wireless debugging problems;
- Shizuku problems;
- rish problems;
- Porter problems;
- proot problems;
- proot-distro problems;
- build failures;
- Python problems;
- Node.js problems;
- Java/Kotlin problems;
- file conversion problems.

Each troubleshooting topic should aim to explain:

1. Symptoms
2. Likely causes
3. Diagnostic commands
4. Solutions
5. Prevention
6. Environment/version limitations

---

18. Security

The Bible should contain a dedicated security volume.

Topics include:

- filesystem permissions;
- Android sandboxing;
- Termux permissions;
- root risks;
- ADB risks;
- Shizuku risks;
- Porter risks;
- downloading scripts;
- executing remote code;
- SSH security;
- Git credential security;
- API tokens;
- SSH keys;
- GPG;
- backups;
- file deletion;
- malicious packages/scripts;
- supply-chain considerations.

---

19. Quick Reference

A dedicated quick-reference section should provide concise command and workflow references.

Potential material:

- essential Termux commands;
- essential shell commands;
- package management;
- storage access;
- Git;
- GitHub CLI;
- ADB;
- Shizuku;
- rish;
- Porter;
- file conversion;
- archives;
- networking;
- scripting.

The quick-reference material should point toward detailed documentation where appropriate.

---

20. Appendices

Potential appendices include:

- glossary;
- command index;
- package index;
- Android terminology;
- shell terminology;
- keyboard shortcuts;
- environment variables;
- common file paths;
- file extension reference;
- compatibility notes;
- source/reference index.

---

21. Research Organization

The "research/" directory should contain supporting research material.

Possible organization:

research/
├── termux/
├── android/
├── adb/
├── shizuku/
├── rish/
├── porter/
├── packages/
├── commands/
├── networking/
├── development/
└── unresolved/

Research notes are supporting project material and should remain distinguishable from polished documentation.

---

22. Sources and References

Important technical documentation should maintain useful source references.

Particular attention should be given to:

- official documentation;
- official repositories;
- release notes;
- API documentation;
- developer documentation;
- compatibility information.

Source organization should make future verification and maintenance practical.

---

23. Current vs. Historical Documentation

The completed Bible should make it possible for readers to distinguish:

- current behavior;
- historical behavior;
- deprecated behavior;
- experimental behavior;
- planned behavior;
- version-specific behavior.

This is especially important for Android, Termux, ADB, Shizuku, rish, and Porter.

The detailed rules for how OpenCode handles these distinctions are defined in "AGENTS.md".

---

24. Cross-Linking

The documentation should use internal links to connect related subjects.

Examples:

- package management ↔ Termux packages;
- shell commands ↔ command encyclopedia;
- ADB ↔ Android shell;
- Shizuku ↔ rish;
- Porter ↔ rish;
- Git ↔ GitHub CLI;
- Pandoc ↔ document conversion;
- troubleshooting ↔ relevant command documentation.

Cross-linking should make the Bible navigable as a unified reference rather than a collection of isolated files.

---

25. Beginner and Advanced Organization

Where practical, subjects should provide both beginner and advanced material.

The final documentation should allow a new Termux user to start with fundamentals while allowing experienced users to quickly reach advanced material.

---

26. Reproducibility

The project should favor examples and workflows that readers can reproduce.

Documentation should clearly identify required packages, permissions, environments, and prerequisites.

Detailed operating rules for reproducible examples are defined in "AGENTS.md".

---

27. README

The root "README.md" should eventually explain:

- what the Termux Bible is;
- project goals;
- repository structure;
- how to read it;
- how to contribute;
- how to build the EPUB;
- project status;
- important references.

---

28. EPUB Publishing System

The Markdown documentation should eventually be compiled into an EPUB.

Planned publishing files:

metadata.yaml
epub-style.css
build.sh

The publishing workflow should use Pandoc.

The EPUB should include:

- title metadata;
- author metadata;
- table of contents;
- chapter organization;
- consistent typography;
- readable code blocks;
- internal navigation;
- appropriate page structure.

Markdown remains the canonical source.

---

29. Build System

"build.sh" should eventually provide a reproducible EPUB build process.

The build system should:

1. identify the documentation files;
2. apply metadata;
3. apply EPUB styling;
4. generate the table of contents;
5. build the EPUB;
6. report errors clearly.

The exact Pandoc command should be verified when the build system is implemented.

---

30. Verification Lifecycle

The overall project lifecycle is:

Research
   ↓
Draft
   ↓
Technical Audit
   ↓
Verification
   ↓
Correction
   ↓
Final Review
   ↓
Publication

This lifecycle applies to substantial technical documentation.

The detailed behavior OpenCode should follow during each stage is defined in "AGENTS.md".

---

31. Phase Tracking

The project will be developed in phases rather than attempting to write the entire Bible at once.

Each phase should have:

- defined objectives;
- relevant sections;
- expected deliverables;
- verification requirements;
- completion criteria.

A phase should not be considered complete merely because files exist. The relevant content should be sufficiently researched, organized, and reviewed.

---

32. Development Phases

Phase 1 — Foundation and Repository Setup

Objectives:

- review the existing "AGENTS.md";
- review the existing "PLAN.md";
- inspect the repository;
- verify the project architecture;
- create or refine "README.md" if needed;
- create or refine "metadata.yaml" if needed;
- create or refine "epub-style.css" if needed;
- create or refine "build.sh" if needed;
- establish the initial directory structure.

Important: "AGENTS.md" and "PLAN.md" already exist and must not be recreated as part of this phase.

Deliverable:

A clean repository foundation ready for documentation work.

---

Phase 2 — Termux Foundations

Build the foundational Termux documentation.

Topics:

- installation;
- package management;
- repositories;
- filesystem;
- storage;
- shell basics;
- environment;
- permissions;
- sessions;
- configuration.

Deliverable:

A complete beginner-oriented Termux foundation.

---

Phase 3 — Shell Command Bible

Build the core command reference.

Topics:

- filesystem commands;
- text processing;
- process management;
- permissions;
- archives;
- networking;
- system utilities;
- command pipelines;
- redirection.

Deliverable:

A substantial shell command encyclopedia.

---

Phase 4 — Android and ADB

Document Android command-line workflows.

Topics:

- Android shell;
- ADB;
- wireless debugging;
- package management;
- logcat;
- dumpsys;
- Android commands;
- file transfer;
- screenshots;
- screen recording.

Deliverable:

A practical Android/ADB reference.

---

Phase 5 — Shizuku and rish

Document:

- Shizuku;
- rish;
- privileged command workflows;
- setup;
- permissions;
- limitations;
- troubleshooting;
- Termux integration.

Deliverable:

A reliable Shizuku/rish reference.

---

Phase 6 — Porter

Perform dedicated Porter research and documentation.

Topics:

- Porter architecture;
- current interfaces;
- developer integration;
- command-line access;
- rish interaction;
- permissions;
- Termux workflows;
- limitations;
- troubleshooting.

Deliverable:

A dedicated, current Porter reference.

---

Phase 7 — Power Tools

Document:

- Git;
- GitHub;
- GitHub CLI;
- SSH;
- programming languages;
- compilers;
- build systems;
- editors;
- databases;
- networking tools.

Deliverable:

A practical development/power-user reference.

---

Phase 8 — Documents, Media, and Data

Document workflows involving:

- Markdown;
- DOCX;
- PDF;
- EPUB;
- Pandoc;
- images;
- audio;
- video;
- JSON;
- CSV;
- XML;
- YAML;
- archives;
- batch conversion.

Deliverable:

A practical file/data manipulation reference.

---

Phase 9 — Advanced Termux

Document:

- proot;
- proot-distro;
- Linux distributions;
- SSH servers;
- local services;
- networking;
- automation;
- advanced shell configuration;
- background processes.

Deliverable:

An advanced Termux reference.

---

Phase 10 — Scripting and Automation

Document:

- shell scripting;
- Bash;
- variables;
- loops;
- conditionals;
- functions;
- arguments;
- exit codes;
- process management;
- automation;
- Termux integrations.

Deliverable:

A practical scripting and automation reference.

---

Phase 11 — Troubleshooting and Security

Build the troubleshooting and security encyclopedias.

Deliverable:

A structured problem-solving and security reference covering the major systems documented by the Bible.

---

Phase 12 — Command Encyclopedia and Quick Reference

Consolidate the project into:

- command encyclopedia;
- quick-reference tables;
- indexes;
- glossary;
- cross-links;
- common workflows.

Deliverable:

A highly navigable reference layer.

---

Phase 13 — Final Verification and Publication

Perform a project-wide review.

Tasks include:

- verify important commands;
- review version-sensitive information;
- check internal links;
- check terminology;
- review security warnings;
- review Porter/Shizuku/rish distinctions;
- check EPUB generation;
- verify metadata;
- test the build process;
- correct discovered problems;
- prepare the first complete EPUB release.

Deliverable:

A coherent, verified, publishable Termux Bible.

---

33. Phase Completion Criteria

A phase should be considered complete when:

- planned documentation for that phase exists;
- major technical claims have been researched;
- important commands have been verified;
- prerequisites are documented;
- environment differences are clear;
- known limitations are documented;
- relevant cross-links exist;
- troubleshooting information is present where appropriate;
- the material has undergone review;
- no known major unresolved errors remain without being clearly marked.

---

34. Long-Term Maintenance

The Termux Bible should be treated as a living technical reference.

Future maintenance should account for:

- new Android versions;
- new Termux releases;
- package changes;
- command changes;
- deprecated tools;
- new Termux add-ons;
- ADB changes;
- Shizuku changes;
- rish changes;
- Porter changes;
- changes to development tools;
- changes to Pandoc;
- EPUB build changes.

The project should periodically identify outdated information and update it rather than allowing historical information to silently become presented as current.

---

35. Completion Definition

The Termux Bible is considered substantially complete when it provides:

- a beginner-friendly introduction;
- a comprehensive Termux reference;
- a broad shell command reference;
- Android and ADB documentation;
- Shizuku documentation;
- rish documentation;
- Porter documentation;
- development and Git/GitHub documentation;
- scripting and automation documentation;
- document/media/data workflows;
- advanced Termux workflows;
- troubleshooting;
- security;
- command encyclopedia;
- quick reference;
- cross-linked navigation;
- source/reference material;
- reproducible EPUB generation.

Completion does not mean the project can never change.

The Bible should remain maintainable and updateable as the Android and Termux ecosystems evolve.