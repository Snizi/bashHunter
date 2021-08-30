#! /usr/bin/bash
DNS_JHADDIX=~/tools/SecLists/Discovery/DNS/dns-Jhaddix.txt

MODE=$1
DOMAINS=$2
NUCLEI_TEMPLATES=~/tools/nuclei-templates/
PARAM_SPIDER=~/tools/ParamSpider/


run_amass()
{
    amass enum -silent -active -brute -w $DNS_JHADDIX -max-dns-queries 3000 -d $DOMAIN -o $RECON_FOLDER/amass.txt
}

run_assetfinder()
{
    assetfinder --subs-only $DOMAIN > $RECON_FOLDER/assetfinder.txt
}

run_sublist3r()
{
    python3 ~/tools/Sublist3r/sublist3r.py -d $DOMAIN -t 50 -v -o $RECON_FOLDER/sublist3r.txt > /dev/null
}

unify_domains()
{
    cat $RECON_FOLDER/sublist3r.txt cat $RECON_FOLDER/amass.txt $RECON_FOLDER/assetfinder.txt | anew $RECON_FOLDER/merged-domains.txt
}

run_waybackurls()
{
    cat $RECON_FOLDER/merged-domains.txt | waybackurls > $RECON_FOLDER/wayback.txt
    cat $RECON_FOLDER/wayback.txt | cut -d "/" -f 3 | cut -d ":" -f 1 | anew $RECON_FOLDER/merged-domains.txt
}

run_httprobe()
{
    cat $RECON_FOLDER/merged-domains.txt | httprobe -c 50 -t 3000 >> $RECON_FOLDER/live-hosts.txt
}

run_nuclei()
{
    nuclei -l $RECON_FOLDER/live-hosts.txt -t $NUCLEI_TEMPLATES/cves/2021/ $NUCLEI_TEMPLATES/takeovers/ -o $RECON_FOLDER/nuclei.txt
}

run_aquatone()
{
    cat $RECON_FOLDER/live-hosts.txt | aquatone -out $RECON_FOLDER -chrome-path /snap/bin/chromium -ports xlarge -silent
}

run_xss_scanner()
{
    python3 $PARAM_SPIDER/paramspider.py --domain $DOMAIN --exclude woff,css,png,svg,jpg --output $RECON_FOLDER/paramspider.txt
    dalfox file $RECON_FOLDER/paramspider.txt -o $RECON_FOLDER/dalfox.txt
}

if [ $MODE == "-d" ]
then
    DOMAIN=$2
    RECON_FOLDER=~/recon/$DOMAIN
    mkdir -p $RECON_FOLDER
    run_amass
    run_sublist3r
    run_assetfinder
    unify_domains
    run_waybackurls
    run_httprobe
    run_nuclei
    run_aquatone
    run_xss_scanner
else
    while read line
    do
        DOMAIN=$line
        RECON_FOLDER=~/recon/$DOMAIN
        mkdir -p $RECON_FOLDER
        run_amass
        run_sublist3r
        run_assetfinder
        unify_domains
        run_waybackurls
        run_httprobe
        run_nuclei
        run_aquatone
        run_xss_scanner
    done < $2
    
fi
