#!/bin/bash
 
exec 5> >(logger -t $0)
BASH_XTRACEFD="5"
PS4='$LINENO: '
set -x
 
SHELL=/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin
MAILTO=alerts@email.com
 
get_voiprbl='http://voipbl.org/update/'
get_arinonly='http://voipbl.org/update/?wn[]=arin'
 
if [ -e '/etc/ipset/voipbl.txt' ]
then
  echo "/etc/ipset/voipbl.txt file exists."
  echo "Checking timestamp and size..."
  olddt=`stat -c '%y' /etc/ipset/voipbl.txt`
  oldsize=`ls -lh /etc/ipset/voipbl.txt | cut -d" " -f5`
else
  echo "/etc/ipset/voipbl.txt not found."
  echo "Touching file for first run..."
  touch /etc/ipset/voipbl.txt
  olddt=`stat -c '%y' /etc/ipset/voipbl.txt`
  oldsize=`ls -lh /etc/ipset/voipbl.txt | cut -d" " -f5`
fi
 
if [ -e '/etc/ipset/arinonly.txt' ]
then
  echo "/etc/ipset/arinonly.txt file exists."
  echo "Checking timestamp and size..."
  olddtarin=`stat -c '%y' /etc/ipset/arinonly.txt`
  oldsizearin=`ls -lh /etc/ipset/arinonly.txt | cut -d" " -f5`
else
  echo "/etc/ipset/arinonly.txt not found."
  echo "Touching file for first run..."
  touch '/etc/ipset/arinonly.txt'
  olddtarin=`stat -c '%y' /etc/ipset/arinonly.txt`
  oldsizearin=`ls -lh /etc/ipset/arinonly.txt | cut -d" " -f5`
fi
 
echo "Downloading VoIPBL GLOBAL IP network shuns."
wget -qO - $get_voiprbl -O /etc/ipset/voipbl.txt
echo "Downloading US/CA ARIN networks only lists."
wget -qO - $get_arinonly -O /etc/ipset/arinonly.txt
echo ""
newdt=`stat -c '%y' /etc/ipset/voipbl.txt`
newdtarin=`stat -c '%y' /etc/ipset/arinonly.txt`
newsize=`ls -lh /etc/ipset/voipbl.txt | cut -d" " -f5`
newsizearin=`ls -lh /etc/ipset/arinonly.txt | cut -d" " -f5`
echo "voipbl.txt file differentials:"
echo "old: $olddt SIZE: $oldsize"
echo "new: $newdt SIZE: $newsize"
echo ""
echo "arinonly.txt file differentials:"
echo "old: $olddtarin SIZE: $oldsizearin"
echo "new: $newdtarin SIZE: $newsizearin"
echo ""
echo "Creating hash lists in memory..."
ipset create -exist tmp_voipbl hash:net
ipset create -exist tmp_arin hash:net
ipset create -exist voipbl hash:net
ipset create -exist arinonly hash:net
echo ""
 
if [ -e '/etc/ipset/tmp_voipbl' ]; then
  echo "/etc/ipset/tmp_voipbl file exists."
  echo "Preparing hash lists for swaping..."
else
  echo "/etc/ipset/tmp_voipbl not found."
  echo "Touching file for first run..."
  touch '/etc/ipset/tmp_voipbl'
fi
 
cp "/dev/null" "/etc/ipset/tmp_voipbl"
cp "/dev/null" "/etc/ipset/tmp_arin"
echo ""
echo "Parsing new downloads..."
 
for voipblist in `tail -n +2 /etc/ipset/voipbl.txt`; do
  echo add tmp_voipbl $voipblist >> /etc/ipset/tmp_voipbl
done
 
for arin in `tail -n +2 /etc/ipset/arinonly.txt`; do
  echo add tmp_arin $arin >> /etc/ipset/tmp_arin
done
 
# swap the temp ipsets for the live ones
ipset flush tmp_voipbl
ipset flush tmp_arin
ipset restore < /etc/ipset/tmp_voipbl
ipset restore < /etc/ipset/tmp_arin
ipset flush voipbl
ipset flush arinonly
ipset swap tmp_voipbl voipbl
ipset swap tmp_arin arinonly
echo ""
ipset save tmp_voipbl -f /etc/ipset/tmp_voipbl
ipset save tmp_arin -f /etc/ipset/tmp_arin
ipset destroy tmp_voipbl
ipset destroy tmp_arin
ipset save voipbl -f /etc/ipset/voipbl
ipset save arinonly -f /etc/ipset/arinonly
echo "List inventory in RAM and in use by Netfilter:"
echo ""
echo "`ipset list -t`"
 
# log the file modification time for use in minimizing lag in cron schedule
moredt=`date`;
logger -p cron.notice "IPSet: voipbl updated as of: $moredt" ;
 
#Check if rules in iptables
if ! $(/sbin/iptables -w --check INPUT -m set --match-set voipbl src -j LOGNDROP > /dev/null 2>&1); then
  /sbin/iptables -I INPUT 1 -m set --match-set voipbl src -j LOGNDROP
fi
 
if ! $(/sbin/iptables -w --check INPUT -m set --match-set arinonly src -j DROP > /dev/null 2>&1); then
  /sbin/iptables -I INPUT 1 -m set --match-set arinonly src -j DROP
fi
 
echo "";
echo "Netfilter IPSet rules updated and reloaded into RAM";
echo "Successful completion...";
