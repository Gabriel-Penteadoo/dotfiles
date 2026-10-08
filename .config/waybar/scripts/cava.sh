#!/usr/bin/env bash
# Stream cava output as bar glyphs for waybar's custom/cava module.
bars="▁▂▃▄▅▆▇█"
conf=$(mktemp)
trap 'rm -f "$conf"' EXIT
cat > "$conf" <<CFG
[general]
bars = 10
framerate = 30
[input]
method = pulse
source = auto
[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
CFG
sed_expr="s/;//g;"
for i in {0..7}; do sed_expr+="s/$i/${bars:$i:1}/g;"; done
exec cava -p "$conf" | sed -u "$sed_expr"
