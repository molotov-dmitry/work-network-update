#!/bin/bash

contains()
{
    local e
    local match="$1"
    shift
  
    for e
    do
        if [[ "$e" == "$match" ]]
        then
            return 0
        fi
    done
    
    return 1
}

get_conn_value()
{
    local conn="$1"
    local field="$2"
    
    nmcli -f "$field" -t connection show "$conn" | cut -d ':' -f 2-
}

update_conn_value()
{
    local conn="$1"
    local field="$2"
    local value="$3"
    
    local oldvalue="$(get_conn_value "$conn" "$field")"
    
    if [[ "$oldvalue" != "$value" ]]
    then
        if nmcli conn modify "$conn" "$field" "$value"
        then
            echo "Updated '$conn' field '$field': '$oldvalue' -> '$value'"
            configured=1
        fi
    fi
}

reconnect()
{
    local conn="$1"
    
    if [[ -n "$(LC_ALL=C nmcli --fields=TYPE,STATE device status | tail -n+2 | grep '^ethernet [ ]*connected[ ]*$')" && $configured -ne 0 ]]
    then
        nmcli conn up "${conn}" >/dev/null 2>/dev/null
    fi
}

readonly CONN_NAME_DHCP='RCZIFORT (DHCP)'
readonly CONN_NAME_STATIC='RCZIFORT (STATIC)'

readonly DNS_SERVERS='172.16.56.14,172.16.56.10'
readonly DNS_DOMAIN='rczifort.local'

readonly MASK='24'
readonly GATEWAY='10.0.0.1'

declare -A STATIC_ADDRESSES

STATIC_ADDRESSES['ac:22:0b:27:c5:ec']='' # 91
STATIC_ADDRESSES['b4:2e:99:be:df:69']='' # 52

configured=0

#### DHCP connection ===========================================================

if nmcli conn show "${CONN_NAME_DHCP}" >/dev/null 2>/dev/null
then
    update_conn_value "${CONN_NAME_DHCP}" ipv4.method auto
    update_conn_value "${CONN_NAME_DHCP}" ipv4.dns "${DNS_SERVERS}"
    update_conn_value "${CONN_NAME_DHCP}" ipv4.dns-search "${DNS_DOMAIN}"
    update_conn_value "${CONN_NAME_DHCP}" ipv4.ignore-auto-dns yes
    update_conn_value "${CONN_NAME_DHCP}" ipv6.method disabled
    update_conn_value "${CONN_NAME_DHCP}" connection.interface-name ''
    update_conn_value "${CONN_NAME_DHCP}" connection.permissions "user:${USER}"
    update_conn_value "${CONN_NAME_DHCP}" connection.autoconnect-priority 30
else
    nmcli conn add \
        type ethernet \
        con-name "${CONN_NAME_DHCP}" \
        ipv4.method auto \
        ipv4.dns "${DNS_SERVERS}" \
        ipv4.dns-search "${DNS_DOMAIN}" \
        ipv4.ignore-auto-dns yes \
        ipv6.method disabled \
        connection.interface-name '' \
        connection.permissions "user:${USER}" \
        connection.autoconnect-priority 30 2>/dev/null \
    || echo "Failed to add network connection" >&2
    
    configured=1
fi

#### STATIC connection =========================================================

if [[ -f '/sys/class/net/eth0/address' ]]
then
    addr="${STATIC_ADDRESSES["$(cat /sys/class/net/eth0/address)"]}"

    if [[ -n "$addr" ]]
    then
        if nmcli conn show "${CONN_NAME_STATIC}" >/dev/null 2>/dev/null
        then
            update_conn_value "${CONN_NAME_STATIC}" ipv4.method manual
            update_conn_value "${CONN_NAME_STATIC}" ipv4.addresses "${addr}/${MASK}"
            update_conn_value "${CONN_NAME_STATIC}" ipv4.gateway "${GATEWAY}"
            update_conn_value "${CONN_NAME_STATIC}" ipv4.dns "${DNS_SERVERS}"
            update_conn_value "${CONN_NAME_STATIC}" ipv4.dns-search "${DNS_DOMAIN}"
            update_conn_value "${CONN_NAME_STATIC}" ipv4.ignore-auto-dns yes
            update_conn_value "${CONN_NAME_STATIC}" ipv6.method disabled
            update_conn_value "${CONN_NAME_STATIC}" connection.interface-name ''
            update_conn_value "${CONN_NAME_STATIC}" connection.permissions "user:${USER}"
            update_conn_value "${CONN_NAME_STATIC}" connection.autoconnect-priority 31
        else
            nmcli conn add \
                type ethernet \
                con-name "${CONN_NAME_STATIC}" \
                ipv4.method manual \
                ipv4.addresses "${addr}/${MASK}" \
                ipv4.gateway "${GATEWAY}" \
                ipv4.dns "${DNS_SERVERS}" \
                ipv4.dns-search "${DNS_DOMAIN}" \
                ipv4.ignore-auto-dns yes \
                ipv6.method disabled \
                connection.interface-name '' \
                connection.permissions "user:${USER}" \
                connection.autoconnect-priority 30 2>/dev/null \
            || echo "Failed to add network connection" >&2
            
            configured=1
        fi
        
        reconnect "${CONN_NAME_STATIC}"
    else
        if nmcli conn show "${CONN_NAME_STATIC}" >/dev/null 2>/dev/null
        then
            nmcli conn del "${CONN_NAME_STATIC}"
            configured=1
        fi

        reconnect "${CONN_NAME_DHCP}"
    fi
fi

