#!/system/bin/sh

# Copyright (C) MIT License 2023 Nicholas Bissell (TheFreeman193)

MODULEPATH="${0%/*}"
EXTERNALPATH="/data/adb/pifpicker"

# Remove persistent config/storage
rm -rf "$EXTERNALPATH"

# Remove any internal config
if [ -f "$MODULEPATH/config" ]; then
    rm -f "$MODULEPATH/config"
fi
