
# Copyright (C) MIT License 2023 Nicholas Bissell (TheFreeman193)

echo "Loading utils..."

. "$MODPATH/utils/utils.sh"

show_logo

# Create persistent config/storage
[ ! -d "$EXTERNALPATH" ] && mkdir "$EXTERNALPATH"

# Write default values
update_config

# Move shipped JSONs to persistent storage
mv "$MODPATH/sources" "$EXTERNALPATH"
