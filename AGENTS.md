AGENTS.md — Termux Bible

1. Project Role

You are working on the Termux Bible, a comprehensive, practical, technically accurate reference for Termux, Android command-line tools, shell utilities, Android debugging, privileged-access tools, development tools, scripting, automation, troubleshooting, security, and related workflows.

This repository is intended to become a maintainable Markdown documentation project that can also be compiled into an EPUB.

Your job is to help research, verify, write, organize, maintain, and improve the project while preserving technical accuracy.

---

2. Permanent Operating Rules

These rules apply to every task performed in this repository unless a more specific instruction explicitly overrides them.

2.1 Accuracy Over Completeness

Accuracy is more important than filling every section.

Never add information merely because a section is expected to contain something.

If information cannot be verified:

- say that it is unverified;
- mark it as needing research;
- leave it incomplete rather than inventing an answer.

2.2 Never Guess Technical Behavior

Do not invent:

- commands;
- command options;
- package names;
- package repositories;
- file paths;
- environment variables;
- APIs;
- permissions;
- configuration values;
- Android behaviors;
- compatibility claims;
- application capabilities;
- installation procedures;
- undocumented interfaces.

If uncertain, research and verify before documenting it.

AI-generated information is not considered authoritative evidence.

---

3. Research Rules

3.1 Research Before Documentation

When documenting a technical subject that is version-sensitive, obscure, or uncertain:

1. Research it.
2. Prefer authoritative documentation.
3. Cross-check important claims when practical.
4. Determine whether the information is current, historical, experimental, or uncertain.
5. Only then add it to the Bible.

Do not write from memory when current documentation is available.

3.2 Source Priority

Prefer sources in approximately this order:

1. Official project documentation
2. Official repositories
3. Official Android documentation
4. Official Termux documentation/repositories
5. Official documentation for Shizuku, Porter, ADB, rish, and other relevant projects
6. Maintainer documentation or release notes
7. High-quality technical references
8. Community documentation
9. Forums, social media, or discussion threads

Lower-priority sources may be useful for discovering information, but important technical claims should be verified against stronger sources whenever possible.

3.3 Version-Sensitive Information

When behavior depends on:

- Android version;
- Termux version;
- Android API level;
- package version;
- device configuration;
- root status;
- Shizuku state;
- Porter state;
- ADB state;
- proot/proot-distro;
- architecture;

document the relevant limitation.

Do not present version-specific behavior as universally applicable.

---

4. Verification and Audit Workflow

The preferred workflow for substantial technical documentation is:

Research → Draft → Audit → Verify → Correct → Final Review

For work involving AI-generated research:

OpenCode → research/draft → external audit → OpenCode verification → corrections → final review

DeepSeek may be used as an adversarial technical reviewer.

An audit is not automatically considered correct. OpenCode must independently verify proposed corrections before applying them.

When an auditor identifies a possible error:

1. Investigate the claim.
2. Check authoritative sources.
3. Determine whether the auditor is correct.
4. Correct the documentation only when verification supports the correction.

Do not blindly copy corrections from another AI.

---

5. Current vs. Historical Information

Clearly distinguish between:

- current behavior;
- historical behavior;
- deprecated behavior;
- experimental behavior;
- planned behavior;
- unsupported behavior;
- version-specific behavior.

Do not describe an old interface as though it is currently supported.

When useful, include the relevant version, Android release, or date.

---

6. Termux Environment Distinctions

Always distinguish between different execution environments.

At minimum, recognize the differences between:

- normal Termux;
- Termux packages;
- the Android shell;
- ADB shell;
- root shell;
- Shizuku;
- Porter;
- rish;
- proot;
- proot-distro;
- Ubuntu/Debian or another Linux distribution running inside proot.

Do not assume that a command working in one environment automatically works in another.

When documenting a command, make clear which environment it is intended for when that distinction matters.

---

7. Filesystem and Path Rules

Be precise about Android and Termux paths.

Do not casually treat these as identical:

- "$HOME"
- "$PREFIX"
- "/data/data/com.termux/..."
- "/storage/emulated/0"
- "~/storage"
- Android app-private storage
- proot filesystem paths
- root filesystem paths
- ADB shell paths

When a path is environment-dependent, explain the environment.

---

8. Command Documentation Rules

Commands included in the Bible should be:

- syntactically valid;
- realistic;
- copyable;
- appropriately scoped;
- safe for the stated purpose.

Where useful, explain:

- what the command does;
- what each important option means;
- prerequisites;
- expected environment;
- expected output;
- permissions required;
- whether root/ADB/Shizuku/Porter is required;
- whether additional packages are required;
- whether the command modifies files or system state.

Do not provide a command simply because it looks plausible.

---

9. Package Documentation

When documenting a Termux package, include relevant information such as:

- package name;
- purpose;
- installation command;
- common usage;
- important commands;
- dependencies where relevant;
- storage requirements where relevant;
- environment limitations;
- Android/Termux compatibility;
- important configuration;
- removal instructions when useful.

Verify package names and commands against current sources.

Do not assume a package available in another Linux distribution exists in Termux.

---

10. Android Privileged Access

Treat privileged-access systems as distinct technologies.

Do not conflate:

- ADB;
- root;
- Shizuku;
- Porter;
- rish.

Explain the capability and limitations of each system separately.

10.1 Shizuku

Document Shizuku according to current official behavior and documentation.

Do not imply that Shizuku automatically grants unrestricted root access.

10.2 Porter

Use Porter's current official developer documentation as the authoritative source for Porter development behavior.

Clearly distinguish Porter from Shizuku.

Do not assume that a Porter capability exists merely because an equivalent Shizuku capability exists.

If Porter currently uses an interface such as "rish", document the current behavior accurately while avoiding claims about unsupported or future interfaces.

10.3 rish

Treat rish as its own interface/tooling layer.

Explain which backend or privileged-access mechanism is actually being used when relevant.

Do not assume that "rish" means root.

---

11. Security Rules

Security-sensitive information must be handled carefully.

Clearly warn about commands that can:

- delete files;
- overwrite data;
- change permissions;
- modify system state;
- expose credentials;
- download and execute remote code;
- modify repositories;
- alter boot/system configuration;
- grant elevated privileges.

Do not casually recommend destructive commands.

For dangerous commands, explain the risk and provide a safer approach when appropriate.

Never include real credentials, tokens, private keys, passwords, or personal secrets.

Use placeholders in examples.

---

12. Reproducibility

Examples should be reproducible whenever practical.

Avoid relying on unexplained assumptions about:

- installed packages;
- shell configuration;
- aliases;
- environment variables;
- root access;
- device configuration;
- current working directory;
- external files.

If prerequisites are required, state them.

---

13. Documentation Style

The Bible should be:

- clear;
- practical;
- technically precise;
- structured;
- readable by beginners;
- useful to advanced users.

Prefer explanations that answer:

What is it?
Why would I use it?
How do I install it?
How do I use it?
What does it require?
What can go wrong?

Avoid unnecessary filler.

Use examples where they improve understanding.

---

14. Beginner and Advanced Layers

Where appropriate, explain subjects progressively:

1. Basic concept
2. Basic command/use
3. Common examples
4. Important options
5. Practical workflows
6. Advanced usage
7. Troubleshooting
8. Security considerations

Do not assume that every reader already understands Linux or Android internals.

---

15. Cross-Linking

Use internal Markdown links when another section provides useful context.

Avoid unnecessary duplication when a subject is already documented elsewhere.

If two sections depend on one another, link them clearly.

Maintain links when files or sections are renamed.

---

16. Editing Existing Documentation

Before editing an existing file:

1. Read the relevant existing content.
2. Understand its structure.
3. Preserve correct information.
4. Identify what actually needs to change.
5. Make the smallest sensible change.
6. Avoid unrelated rewrites.

Do not overwrite large portions of documentation merely to reformat them.

When improving an existing section, preserve useful research and existing organization unless there is a clear reason to change it.

---

17. Research Notes

Research material should be kept separate from polished documentation when appropriate.

Research notes may contain:

- source links;
- investigation results;
- unresolved questions;
- conflicting information;
- historical information;
- verification notes;
- audit findings.

Do not automatically treat research notes as publication-ready documentation.

---

18. Quality Control

Before considering a substantial section complete, check:

- Are the commands valid?
- Are package names correct?
- Are prerequisites stated?
- Are environment differences explained?
- Are version-sensitive claims identified?
- Are dangerous operations clearly marked?
- Are important claims supported by reliable sources?
- Are examples realistic?
- Are paths accurate?
- Are internal links valid?
- Is the terminology consistent?
- Is outdated information identified?
- Has questionable AI-generated information been independently verified?

---

19. Things OpenCode Must Never Do

OpenCode must not:

- invent commands;
- invent package names;
- invent APIs;
- invent features;
- claim unsupported functionality;
- silently change technical meaning;
- present speculation as fact;
- blindly trust another AI;
- blindly apply audit corrections;
- erase correct existing documentation without reason;
- create duplicate documentation unnecessarily;
- modify unrelated project files;
- expose credentials or secrets;
- perform destructive operations without appropriate caution;
- treat root, ADB, Shizuku, Porter, and rish as interchangeable;
- claim that a feature is current without appropriate verification.

---

20. Git Rules

Git operations should preserve the integrity of the project.

Before major repository changes:

- inspect the current Git state;
- understand existing changes;
- avoid overwriting unrelated work;
- avoid destructive Git commands unless explicitly requested;
- keep commits logically organized when making commits.

Do not discard user changes merely to make the working tree clean.

---

21. EPUB and Publishing Rules

The Markdown files are the canonical documentation source.

Publishing files such as:

- "metadata.yaml";
- "epub-style.css";
- "build.sh";

should support the Markdown source rather than becoming a second source of truth.

Do not manually duplicate the entire Bible into another format.

Changes to the documentation structure should account for EPUB generation.

---

22. Project Structure Rules

Respect the project architecture defined in "PLAN.md".

Do not create arbitrary top-level directories when an existing project section is appropriate.

If the architecture needs to change substantially:

1. Identify why.
2. Check existing documentation and links.
3. Update the plan when appropriate.
4. Preserve compatibility with existing material.

---

23. Phase and Task Handling

"PLAN.md" defines the project's roadmap.

Use it to determine:

- what areas are planned;
- what phase the project is in;
- what deliverables are expected;
- what remains unfinished.

Do not rewrite the roadmap simply because a single task is difficult.

When completing work from a phase, preserve the larger project architecture.

---

24. Task Prompts vs. Permanent Instructions

"AGENTS.md" contains permanent operating rules.

"PLAN.md" contains the project roadmap and intended contents.

A user prompt provides the current task.

Do not put temporary task instructions into "AGENTS.md" unless they are intended to become permanent project rules.

Do not put one-time execution instructions into "PLAN.md".

---

25. Startup Behavior

When first entering this repository, OpenCode should:

1. Read "AGENTS.md".
2. Read "PLAN.md".
3. Inspect the repository.
4. Determine what already exists.
5. Determine the current project state.
6. Identify the appropriate next task.
7. Avoid making large changes without explicit direction.

The startup prompt should be supplied separately by the user rather than stored as a project roadmap section.

---

26. Final Principle

The Termux Bible should favor:

Reliable information over more information.

When forced to choose between a larger document and a more accurate document, preserve accuracy.