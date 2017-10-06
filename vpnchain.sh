#!/bin/bash

##
## CONFIG SECTION:
##

# Config array number is used for ordering chain
#config[1]=config1.ovpn
#config[2]=config2.ovpn
#config[3]=config3.ovpn
#config[4]=config4.ovpn

verbose=0           # verbose level; from 0 to 6
enable_firewall=1   # Block outgoing traffic except openvpn servers (HIGHLY RECOMMENDED)

##
## Don't change anything bellow unless you know what you are doing
##

clear

## Code begins:
# Some vars:
firewall_rules_file='./.vpnchain.firewall'; # set firewall rules file
source './functions.vpnchain' # read functions file

if [ "$1" = "flush" ]; then
    FIREWALL flush
    rm $firewall_rules_file
    exit
fi
if [ $enable_firewall -gt 0 ] && [ -f "$firewall_rules_file" ]; then
    FIREWALL flush
    rm $firewall_rules_file
fi

# execute function on exit
trap " ON_EXIT " INT TERM

config_length=${#config[@]};
i=1
tun_array=()


# Loop for configs array:
while [ $i -le $config_length ]; do
  SHOW info "Using config [$i]: ${config[$i]}"

  # Parse Client's remote server ip from config
  client_remote_ip=$(grep -v '^#' ${config[$i]} | grep -v '^$' | grep remote\  | awk '{print $2}' | head -n 1)
   SHOW info "Client remote ip: $client_remote_ip"

  # For routing purposes we need to get next Client's remote server ip from next config
  let next=$i+1;
  if [ "$next" -le "$config_length" ]; then
    next_client_remote_ip=$(grep -v '^#' ${config[$next]} | grep -v '^$' | grep remote\  | awk '{print $2}' | head -n 1)
    SHOW info "Next client remote ip: $next_client_remote_ip"
    else # leave var empty if there is no next config left
    next_client_remote_ip=
  fi

  # Get default gateway for routing purposes
  default_gateway=$(route -nee | awk 'FNR==3 {print $2}')
    SHOW info "Using default gateway: $default_gateway"

  # Check if we don't have last config or if there is only one config set;
  # or else we don't need to provide any route directly to openvpn command. In that case all needed routing is done
  # by vpnchain_helper.sh script
  if [[ "$i" -eq "1" || "$config_length" -eq "1" ]]; then
      openvpn_route="--route $client_remote_ip 255.255.255.255 $default_gateway"
    else
      openvpn_route=
  fi

  # Check if we have last config and if so, we provide different arguments for vpnchain_helper.sh script;
  # or else we proceed normaly
  if [ "$i" -eq "$config_length" ]; then
      openvpn_up="vpnchain_helper.sh -u -l"
      openvpn_down="vpnchain_helper.sh -d -l"
  else
      openvpn_up="vpnchain_helper.sh -u $next_client_remote_ip"
      openvpn_down="vpnchain_helper.sh -d $next_client_remote_ip"
  fi

  # We need to get available tun device (that is not currently in use). Yes, openvpn can detect this automaticaly,
  # but in our case we need to assign them manualy, because we need to put them in array for function that checks
  # if all chains are connected. Maybe this can be done in more elegant way...
  GET_TUN
  if [ -z "$tun_array" ]; then
    tun_array=( "$client_tun" )
  else
    tun_array=( "${tun_array[@]}" "$client_tun" )
  fi

# Block all outgoing traffic except openvpn servers

  if  [ $enable_firewall -gt 0 ]; then
    if [[ -n "$client_remote_ip" && "$i" -eq "1" ]]; then       
        FIREWALL add "-d $client_remote_ip -j ACCEPT"
    fi
  fi

# Start vpn connection
  CONNECT

# Wait for Client to connect
  TUN=`cat /proc/net/dev | grep -o $client_tun`;
    while [ -z "$TUN" ]
    do
      SHOW info "Waiting for $client_tun..."
      TUN=`cat /proc/net/dev | grep -o $client_tun`
      sleep 5s;
    done

# If all connections done, then we jump to chains connection checking function
if [ "$i" -eq "$config_length" ]; then
  CHECK_CONNECTION
fi

let i++;
done

exit
