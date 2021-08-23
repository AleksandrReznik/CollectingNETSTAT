# CollectingNETSTAT
Continuosly running netstat to collect connections statistics by host and protocol

Prerequisities: Windows operating system with Powershell installed (checked on both 5.2 and 7.3 versions) 

# Instructions:

<p>Script accepts following paramters:</p>



<p><strong>param_LocalIP</strong> - if specified it will use this our server IP for collecting data, if not specified in a parameters it will enumerate local IPs and ask you to choose one to gather statistics on. On Windows Server 2008 enumeration routine is not working (because of older Powershell version) so you have to specify this parameter.</p>



<p><strong>param_numberOfNetstats2run </strong>- number of netstats to run, It will stop automatically after reaching this number. Usually it runs 2-3 netstats per second.</p>



<p><strong>param_resolveIPs2FQDNs</strong> - Perform reverse resolution of collected IPs to hostnames. Default value is "true". It can take several minutes (may be tens of minutes) after it finish looping netstat to perform this.</p>



<p><strong>param_collectOnlyEstablished </strong>- show only connections of "ESTABLISHED" type. Default value is "true".</p>



<p><strong>param_CreateCSV</strong> - generate CSV file with stats on connections collected. Default value is "true".</p>



<p><strong>$pathToSaveFiles </strong>- path to folder where to save both .txt and .csv files.  By default it save them to same folder the script is run from</p>



<p>Example Usage:</p>



<p>simplest way: save code to file with .ps1 extension, lets say collectingNetstat.ps1. Open your powershell console. Perform "<strong>cd &lt;path to your file></strong>".  Then type "<strong>.\collectingNetstat.ps1</strong>". It will ask you IP to gather statistics from. After running it a while press Ctrl+C. As we running it without any parameter it will try to perform reverse DNS queries on all IP - you have to wait till it finish this process. After finishing it will show you path to .txt and .csv files with statistics.</p>



<p><strong>.\collectingNetstat.ps1 -param_numberOfNetstats2run 10 -param_resolveIPs2FQDNs $false </strong>- will perform 10 netstats and don't try to resolve IPs to FQDNs</p>


# <p>N.B.</p>



<p>Use it on your own risk. To my view the risks are minimal. The worst thing if you run it in some remote session on a server and forget to switch it off. It collects all connections stats to in-memory hashtables so some lack of memory problems can theoretically occur if you forget to switch it off.</p>

<p>Unfortunately this script is getting TCP-IP connections only so it very usefull for protocols like LDAP, LDAPS, HTTP, HTTPS etc. Unfortunately it doesn't work with DNS as DNS is using UDP mostly. For DNS statistics we have to analyze DNS log file, I have parser for it - plan to publish it soon.</p>

