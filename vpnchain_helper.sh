#!/bin/bash

UP=
DOWN=
LAST=

while getopts “udl” OPTION
do
     case $OPTION in
         u)
             UP=1;
             ;;
         d)
             DOWN=1;
             ;;
         l)
             LAST=1;
             ;;
     esac
done

if [ -n "$UP" ]; then
  if [ -n "$LAST" ]; then
     /sbin/route add -net 0.0.0.0 netmask 128.0.0.0 gw $6;
     /sbin/route add -net 128.0.0.0 netmask 128.0.0.0 gw $6;    
     #echo "[DEBUG] /sbin/route add -net 0.0.0.0 netmask 128.0.0.0 gw $6;"
     /etc/openvpn/update-resolv-conf
  else 
     /sbin/route add -net $2 netmask 255.255.255.255 gw $6;
     #echo "[DEBUG] /sbin/route add -net $2 netmask 255.255.255.255 gw $6"
  fi
fi

if [ -n "$DOWN" ]; then
  if [ -n "$LAST" ]; then
     /etc/openvpn/update-resolv-conf
  else      
     /etc/openvpn/update-resolv-conf
  fi
fi
