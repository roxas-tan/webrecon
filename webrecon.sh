#!/bin/bash

if [ ! -x "$(command -v assetfinder)" ]
then
	echo "[-] assetfinder required to run script"
	exit 1
fi
    
if [ ! -x "$(command -v amass)" ]
then
	echo "[-] amass required to run script"
	exit 1
fi

if [ ! -x "$(command -v gowitness)" ]
then
	echo "[-] gowitness required to run script"
	exit 1
fi
 
if [ ! -x "$(command -v httprobe)" ]
then
	echo "[-] httprobe required to run script"
	exit 1
fi

if [ ! -x "$(command -v subjack)" ]
then
	echo "[-] subjack required to run script"
	exit 1
fi

if [ -z "$1" ]
then
	echo "[-] No domain is suppiled."
	exit 1
fi

url=$1

if [ ! -e "$url/recon" ]
then
	mkdir -p $url/recon
fi

if [ ! -e "$url/recon/gowitness" ]
then
	mkdir $url/recon/gowitness
fi

if [ ! -e "$url/recon/potential_takeovers" ]
then
	mkdir $url/recon/potential_takeovers
fi

echo "[+] Harvesting subdomains with assetfinder..."
assetfinder --subs-only $url > $url/recon/assets.txt

echo "[+] Harvesting subdomains with Amass..."
amass enum -d $url >> $url/recon/assets.txt

echo "[+] Probing for alive domains..."
cat $url/recon/assets.txt | httprobe | sed s/'\(http\|https\):\/\/'/''/g | sort -u > $url/recon/alive.txt

echo "[+] Running gowitness against all compiled domains..."
gowitness file -f $url/recon/alive.txt -P $url/recon/gowitness

echo "[+] Checking for possible subdomain takeover..."
if [ ! -f "$url/recon/potential_takeovers/potential_takeovers.txt" ]
then
	touch $url/recon/potential_takeovers/potential_takeovers.txt
fi
 
subjack -w $url/recon/alive.txt -t 100 -timeout 30 -ssl -c ~/go/src/github.com/haccer/subjack/fingerprints.json -v 3 -o $url/recon/potential_takeovers/potential_takeovers.txt
