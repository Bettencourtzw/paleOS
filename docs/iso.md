# Building the ISO

Requirements: Arch Linux, `archiso`, and optionally `rust` (to prebuild the app index).

```bash
sudo pacman -S archiso rust
sudo ./iso/build.sh          # -> out/paleos-<date>-x86_64.iso
```

`iso/build.sh` starts from Arch's official ISO profile (`releng`), adds the packages in
`iso/packages.txt`, the installer (`iso/airootfs/usr/local/bin/paleos-setup`) and a copy of this
repo, then runs `mkarchiso`. Set `WORK=/some/dir` if `/tmp` is small (it needs ~6 GB).

Try it in a VM:

```bash
qemu-system-x86_64 -enable-kvm -m 4G -cpu host -bios /usr/share/edk2/x64/OVMF.4m.fd \
  -cdrom out/paleos-*.iso -drive file=test.qcow2,if=virtio -vga virtio
```
