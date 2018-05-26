# VPN-Chain
Bash script which makes chained OpenVPN connections.


WARNING: This is beta release and is VERY experimental right now, so use at your own risk. 
WARNING: Please read HOW TO USE VPN CHAIN section, because it contains important security information


#### ABOUT VPN CHAIN ####
VPN Chain is a fork of the original VPNCHAINS bash script. I will be reworking this in either Go or Nim. For now, I will maintain this script and continue to add features and fix bugs.

VPN Chain is bash script which makes chained openvpn connections. You don't need to use virtual machine for this anymore. 
After chain is completed you can use internet in more secure and private way with all openvpn benefits. 

Completed chain looks like this:
	PC <-> OPENVPN1 <-> OPENVPN2 <-> OPENVPN# <-> INTERNET

And yes, you can use TOR on top of chain:
	PC <-> OPENVPN1 <-> OPENVPN2 <-> OPENVPN# <-> TOR <-> INTERNET

There should be no limits on how many hops in chain can be (fix me if i'm wrong). I tested with 3 OpenVPNs in chain, 
but i think it should work with 5 or 10 configs. Ofcourse, there can be some practical limits like speed and stability 
of whole chain.  


#### REQUIREMENTS ####

- Linux (tested on Ubuntu 12.04, but should work on most distributions)
- Config files from your OpenVPN providers
- BASH shell
- OpenVPN client
- iptables
- resolvconf
- awk


#### HOW TO USE VPN CHAIN ####

0. Extract files:
	bash$ unzip vpnchains-XX.zip
	bash$ cd vpnchains

1. Edit vpnchain.sh config section. 

	VPN CHAIN should work with most OpenVPN providers default configs (i tested 3 different ones and all worked 
	without major changes). If you get 'file not found' errors, try to change keys and certificate paths from relative to absolute in config files.

2. Use sudo to run it:
		bash$ sudo ./vpnchain.sh 

3. To exit press CTRL+C keys

4. If you enabled firewall blocking then run this command to flush rules:
	bash$ sudo ./vpnchain.sh flush
	

SECURITY WARNING:
	Your IP address doesn't change UNTIL WHOLE CHAIN IS CONNECTED. If you connect to first openvpn server then to second but LAST ONE doesn't connect, your IP IS NOT changed. For IP to change you need wait for WHOLE CHAIN to be connected (wait for green text saying 'Connected'). 
	To avoid leaks you can disable all OUTPUT traffic in firewall and allow only remote openvpn servers IPs and tun devices. Or you should wait until chain is completed and check your ip before doing any online activity (your ip should be  from your last OpenVPN provider's). 

NOTICE: Automatic firewall blocking option is added in 0.2 version

After connect you can run wireshark and look for traffic:
- eth0 device should see traffic only to Client0 remote server ip (and other local LAN traffic)
- tun0 device should see traffic only from tun0 ip and Client1 remote server ip
- tun1 device should see traffic only from tun1 ip and Client2 remote server ip and so on.
- last tun device should see internet traffic from it's tunX device and all other request to internet (because it's exit node).


#### HOW VPN CHAIN WORKS ####

The main idea is taken from http://forums.openvpn.net/topic7483.html.
You change default routing pushed from OpenVPN server and manualy add your own custom routing:

In ClientA config file add lines:
	route-nopull # disable default routing pushed from server
	route <ClientA_Remote_IP> 255.255.255.255 <Default_Gateway>
	route <ClientB_Remote_IP> 255.255.255.255 <ClientA_Tun_IP>

In ClientB config file add those lines:
	route-nopull # disable default routing pushed from server
	route 0.0.0.0 128.0.0.0 <ClientB_Tun_IP>
	route 128.0.0.0 128.0.0.0 <ClientB_Tun_IP>
	dhcp-option DNS <ClientB_Dns_IP>
	up /etc/openvpn/update-resolv-conf
	down /etc/openvpn/update-resolv-conf

But this can be applied for more than two OpenVPN instances:

Client_First:
	route-nopull # disable default routing pushed from server
	route <Client_First_Remote_IP> 255.255.255.255 <Default_Gateway>
	route <Next_Client_Remote_IP> 255.255.255.255 <Client_First_Tun_IP>

Client#:
	route-nopull # disable default routing pushed from server
	route <Next_Client_Remote_IP> 255.255.255.255 <Previous_Client_Tun_IP>

Client_Last:
	route-nopull # disable default routing pushed from server
	route 0.0.0.0 128.0.0.0 <Cient_Last_Tun_IP>
	route 128.0.0.0 128.0.0.0 <Client_Last_Tun_IP>
	dhcp-option DNS <Client_Last_Dns_IP>
	up /etc/openvpn/update-resolv-conf
	down /etc/openvpn/update-resolv-conf

Basicaly, completed chain looks like this:
	PC <-> OPENVPN1 <-> OPENVPN2 <-> OPENVPN# <-> INTERNET

In theory there is no limits on how many hops in chain can be (fix me if i'm wrong), but there can be some practical limitations like whole chain speed, stability etc. 
I tested with 3 clients and it worked fine. It would be nice to get feedback (see CONTACTS section) on how much clients 
it worked for you and what issues did you have (if any).


#### TODO LIST ####
- Do heavier testing; get feedbacks (please send them to br41n <at> safe-mail.net)
- Add support for remote-random option
- Add sock-proxy support to use with services like TOR


#### CHANGELOG ###
0.2:
- Added firewall block option
- Moved functions to separate file
- Code cleanup

0.1:
- Initial submit


