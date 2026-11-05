# PROJECT-SYNC

- Canonical source: https://github.com/Bettencourtzw/paleOS; primary branch `main`.
- Personal project: no Hours tracking.
- Mac: source editing and local tests. Arch Linux: package, Lua/QML and desktop verification.
- Current work: `fix/audit-hardening`, local worktree only. User explicitly forbids push and merge; PR text is prepared locally only.
- GitHub Actions: off by default; do not add automatic workflows.
- Runtime: local disposable x86-64 emulated test VM only. No production target or deployment authorization.
- Keep VM disks, ISO images, logs, build targets and credentials outside Git. SSH keys and Keychain credentials stay local.
- Setup: Arch packages in `packages.txt`; Rust tool in `tools/pale-apps`; no application secrets required.
- Verify with `python -m unittest discover -s tests -v`, `cargo test --manifest-path tools/pale-apps/Cargo.toml`, Bash syntax checks, and desktop inspection on Arch.
- Never update main or deploy without a separate explicit request. Preserve the previous VM configuration before desktop testing.
