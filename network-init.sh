#!/bin/bash

uuidstoremove="$(nmcli --fields=UUID,TYPE connection show | grep 'ethernet[[:space:]]*' | cut -d ' ' -f 1)"

nmcli conn add \
    type ethernet \
    con-name "DHCP" \
    ipv4.method auto \
    connection.autoconnect no \
    connection.autoconnect-priority 0 2>/dev/null \
|| echo "Failed to add network connection" >&2

while read uuid
do
    [[ -z "${uuid}" ]] && continue

    nmcli connection del uuid "${uuid}" 2>/dev/null

done <<< "${uuidstoremove}"

