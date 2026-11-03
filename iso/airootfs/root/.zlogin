# paleOS live ISO: start the installer on the first console
if [[ $(tty) == /dev/tty1 ]]; then
  setfont ter-v20n 2>/dev/null
  paleos-setup || echo "Installer exited. Run 'paleos-setup' to start again, or use the shell."
fi
