#!/usr/bin/env bash
# Uninstallation and rollback script for gpu-unlock on Ubuntu / Debian systems

set -euo pipefail

echo "=========================================================="
echo "    gpu-unlock Uninstallation & System Rollback Script    "
echo "=========================================================="

if [ "$(id -u)" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo:"
    echo "   sudo bash $0"
    exit 1
fi

echo "[1/4] Purging gpu-unlock packages and DKMS modules..."
if dpkg -s gpu-unlock-dkms &>/dev/null || dpkg -s gpu-unlock-firmware &>/dev/null; then
    apt-get purge -y gpu-unlock-dkms gpu-unlock-firmware || dpkg -P gpu-unlock-dkms gpu-unlock-firmware
    echo "  -> Packages successfully removed."
else
    echo "  -> Packages are already removed or not installed."
fi

# Clean up any leftover firmware or dkms trees if present
rm -rf /usr/lib/firmware/gpu-unlock /usr/src/gpu-unlock-* /usr/share/doc/gpu-unlock 2>/dev/null || true
rm -f /usr/share/initramfs-tools/modules.d/gpu-unlock.conf /usr/share/initramfs-tools/scripts/init-top/gpu-unlock 2>/dev/null || true

echo "[2/4] Removing gpu_unlock kernel arguments from /etc/default/grub..."
if [ -f /etc/default/grub ]; then
    sed -i 's/[[:space:]]*gpu_unlock\.targets=[^ "]*//g' /etc/default/grub
    sed -i 's/[[:space:]]*gpu_unlock\.resume=[^ "]*//g' /etc/default/grub
    echo "  -> Cleaned GRUB_CMDLINE_LINUX in /etc/default/grub."
fi

echo "[3/4] Updating GRUB bootloader configuration..."
if command -v update-grub &>/dev/null; then
    update-grub
    echo "  -> grub.cfg successfully regenerated."
fi

echo "[4/4] Regenerating initramfs for all installed kernels..."
if command -v update-initramfs &>/dev/null; then
    update-initramfs -u -k all
    echo "  -> initramfs images regenerated without gpu_unlock."
fi

echo ""
echo "=========================================================="
echo "✅ Uninstallation complete! All gpu-unlock traces removed."
echo "   Please reboot your system (sudo reboot) to return to   "
echo "   the stock unmodified NVIDIA driver configuration.      "
echo "=========================================================="
