#!/bin/bash
while read -r output hex conn; do
    [[ -z "$conn" ]] && conn=${output%%-*}
    echo "$output $conn $(xxd -r -p <<< "$hex")"
done < <(xrandr --prop | awk '
    !/^[ \t]/ {
        if (output && hex && !(output ~ /eDP/) && conn != "Panel") print output, hex, conn
        if (output && output ~ /eDP/ && conn != "Panel") print output, "4c6170746f70206d6f6e69746f72", "eDP"
        if (conn && conn == "Panel") print output, "4c6170746f70206d6f6e69746f72", "Panel"
        output=$1
        hex=""
    }
    /ConnectorType:/ {conn=$2}
    /[:.]/ && h {
        sub(/.*000000fc00/, "", hex)
        hex = substr(hex, 0, 26) "0a"
        sub(/0a.*/, "", hex)
        h=0
    }
    h {sub(/[ \t]+/, ""); hex = hex $0}
    /EDID.*:/ {h=1}
    END {
      if (output && hex && !(output ~ /eDP/) && conn != "Panel") print output, hex, conn
      if (output && output ~ /eDP/ && conn != "Panel") print output, "4c6170746f70206d6f6e69746f72", "eDP"
      if (conn && conn == "Panel") print output, "4c6170746f70206d6f6e69746f72", "Panel"
    }
    ' | sort
)

