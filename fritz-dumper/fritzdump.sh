#!/bin/bash


# This is the address of the router (CHANGE IF NEEDED to your specific address)
FRITZIP="http://192.168.178.1"

# This is the WAN interface (Default WAN Interface on MOST Fritzboxes, change if needed but usually works right away) 
# Can be checked from here: https://fritz.box/html/capture.html
IFACE="2-0"

# Lan Interface
#IFACE="2-1"

# If you use password-only authentication with the http://fritz.box login use 'dslf-config' as username.
FRITZUSER="username"
FRITZPWD="password"

SIDFILE="/tmp/fritz.sid"

if [ -z "$FRITZPWD" ] || [ -z "$FRITZUSER" ]  ; then echo "Username/Password empty. Usage: $0 <username> <password>" ; exit 1; fi

echo "Trying to login into $FRITZIP as user $FRITZUSER"

if [ ! -f $SIDFILE ]; then
  touch $SIDFILE
fi

SID=$(cat $SIDFILE)

# Request challenge token from Fritz!Box
CHALLENGE=$(curl -k -s $FRITZIP/login_sid.lua |  grep -o "<Challenge>[a-z0-9]\{8\}" | cut -d'>' -f 2)

# Very proprieatry way of AVM: Create a authentication token by hashing challenge token with password
HASH=$(perl -MPOSIX -e '
    use Digest::MD5 "md5_hex";
    my $ch_Pw = "$ARGV[0]-$ARGV[1]";
    $ch_Pw =~ s/(.)/$1 . chr(0)/eg;
    my $md5 = lc(md5_hex($ch_Pw));
    print $md5;
  ' -- "$CHALLENGE" "$FRITZPWD")
  curl -k -s "$FRITZIP/login_sid.lua" -d "response=$CHALLENGE-$HASH" -d 'username='${FRITZUSER} | grep -o "<SID>[a-z0-9]\{16\}" | cut -d'>' -f 2 > $SIDFILE

SID=$(cat $SIDFILE)

# Check for successfull authentification
if [[ $SID =~ ^0+$ ]] ; then echo "Login failed. Did you create & use explicit Fritz!Box users?" ; exit 1 ; fi

echo "Capturing traffic on Fritz!Box interface $IFACE ..." 1>&2

# In case you want to use tshark instead of ntopng
#wget --no-check-certificate -qO- $FRITZIP/cgi-bin/capture_notimeout?ifaceorminor=$IFACE\&snaplen=\&capture=Start\&sid=$SID | /usr/bin/tshark -r -

echo "Starting Fritz!Box WAN capture and streaming to ntopng..." 1>&2

# Start ntopng and pipe Fritz!Box capture directly to it (like the official script)
# -m specifies local networks - using your specific 192.168.178.0/24 network
# -P specifies the web interface port, -d for data directory
wget --no-check-certificate -qO- $FRITZIP/cgi-bin/capture_notimeout?ifaceorminor=$IFACE\&snaplen=\&capture=Start\&sid=$SID | ntopng -i - -m 192.168.178.0/24 -P /var/lib/ntopng/ntopng.pid -d /var/lib/ntopng -w 3000
