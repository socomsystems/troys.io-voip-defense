# troys.io-voip-defense
# Block countries, networks and VoIP blacklists combining Netfilter’s iptables, ipset and voipbl.org

My original posts:
https://troys.io/block-countries-networks-and-voip-blacklists-efficiently-combining-netfilters-iptables-and-ipset/

Make ipset a service,keeping block lists alive and surviving power cycles:

create /lib/systemd/system/ipset.service

systemctl daemon-reload
systemctl enable ipset

create /usr/local/bin/voipbl.sh

crontab -e 0 1 * * * /usr/local/bin/voipbl.sh

=================================================

Sample daily emails received:

/etc/ipset/voipbl.txt file exists.
Checking timestamp and size...
/etc/ipset/arinonly.txt file exists.
Checking timestamp and size...
Downloading VoIPBL GLOBAL IP network shuns.
Downloading US/CA ARIN networks only lists.
 
voipbl.txt file differentials:
old: 2018-11-25 11:00:21.502886736 -0600 SIZE: 868K
new: 2018-11-26 01:00:19.904743514 -0600 SIZE: 879K
 
arinonly.txt file differentials:
old: 2018-11-25 11:00:30.438886415 -0600 SIZE: 631K
new: 2018-11-26 01:00:21.100743556 -0600 SIZE: 651K
 
Creating hash lists in memory...
 
/etc/ipset/tmp_voipbl file exists.
Preparing hash lists for swaping...
 
Parsing new downloads...
 
List inventory in RAM and in use by Netfilter:
 
Name: voipbl
Type: hash:net
Revision: 5
Header: family inet hashsize 32768 maxelem 65536
Size in memory: 1394616
References: 1
 
Name: arinonly
Type: hash:net
Revision: 5
Header: family inet hashsize 16384 maxelem 65536
Size in memory: 792280
References: 1
 
Netfilter IPSet rules updated and reloaded into RAM
Successful completion...
