# CollectingNETSTAT.ps1
#runs NETSTAT in a loop and constantly extracts current connections info putting it to nested hashtables data structure. 
#After you stop it (by pressing Ctrl+C usually) it shows you statistics on IPs connected to the server (sorted by protocol)
#Author: Aleksandr Reznik aleksandr@reznik.lt 

param (
    [string]$param_LocalIP, #which local address to monitor for connections
    [int]$param_numberOfNetstats2run , #Number of netstats to run. if 0 - not limited, should be stopped with Ctrl+c
    [bool]$param_resolveIPs2FQDNs = $true,
    [bool]$param_collectOnlyEstablished = $true,
    [bool]$param_CreateCSV = $true,
    [string]$pathToSaveFiles=$PSScriptRoot +"\" #by default equals to currently run script directory
)
Function LogWrite{
    [CmdletBinding()]
    Param (
   
    [string]$logstring,
   
    [Parameter(Mandatory=$False)]
    [String] $ForegroundColor = "gray",

    [switch]$NoNewLine

    )

    $Stamp = ""#(Get-Date).toString("yyyy/MM/dd HH:mm:ss")
    $str4file=$Stamp + " "+ $logstring
    #$str4screen $logstring + " -ForegroundColor "+$ForegroundColor
    if ($pathToTxt){
        Add-content $pathToTxt -value $str4file    
    }
    if ($NoNewLine){   
        Write-host $logstring -ForegroundColor $ForegroundColor -NoNewLine
        }
    else{
        Write-host $logstring -ForegroundColor $ForegroundColor 
    }
   

   
}

function getLocalIPfromConsole(){
    $local_NIC_IPs = (
        Get-NetIPConfiguration |
        Where-Object {
            $_.IPv4DefaultGateway -ne $null -and
            $_.NetAdapter.Status -ne "Disconnected"
        }
    ).IPv4Address.IPAddress
       
    $i = 1
    foreach($ip in $local_NIC_IPs){
        Write-host "$i - $ip"
        $i++
    }
    
    $n = Read-host "Choose a number"
    if ($local_NIC_IPs  -is [array]) {
            $local_NIC_IP = $local_NIC_IPs[$n-1].ToString()
        }
    else{
        $local_NIC_IP = $local_NIC_IPs
    }
    return $local_NIC_IP    
}

################################################################ MAIN program start ################################################################

#if local IP is not specified in paramaters - read it from user
if (-not $param_LocalIP){
    $local_NIC_IP = getLocalIPfromConsole
}
else{
    $local_NIC_IP = $param_LocalIP
}

$StartDate = (GET-DATE)
$netstatRunNr = 0
$remoteIP_HT = @{}
$remoteIP2localPortHT = @{}
try{
    while ($true){
        $netstatResult = netstat -nao 
        $netstatRunNr++
        #Write-Host "netstat nr $($netstatRunNr) was run"
        
        if ($param_collectOnlyEstablished){
            $netstatResult = $netstatResult |  select-string "Established"
        }
        else{
            $netstatResult = $netstatResult
        }
        foreach ($netstLine in $netstatResult) {
            $netstLine = $netstLine -replace '\s+', ' '
            $netstLine = $netstLine.Trim()
            $netstArray = $netstLine -split " "
            $line_local_IP = $netstArray[1].split(":")[0]
            $line_local_Port = $netstArray[1].split(":")[1]
            $line_remote_IP = $netstArray[2].split(":")[0]
            #$line_remote_destPort = $netstArray[2].split(":")[1]
            if( $line_local_IP -eq $local_NIC_IP){
                if ($remoteIP2localPortHT.Contains($line_local_Port)){
                        if(-not $remoteIP2localPortHT[$line_local_Port].containsKey($line_remote_IP)){
                            #if new Ip connecting to local port found - adding it to nested hash table linked with local port
                            $remoteIP2localPortHT[$line_local_Port].add($line_remote_IP,"")
                        }
                    }
                    else{
                        #if new local port found - adding it to local port hash table
                        $remoteIP2localPortHT.add($line_local_Port,@{$line_remote_IP = ""})
                    }
                }
            if (-not $remoteIP_HT.Contains($line_remote_IP)){
                #new remote ip found - adding it to remote ip hash table
                $remoteIP_HT.Add($line_remote_IP,"")
            }
            

        } # foraeach line
        if ($param_numberOfNetstats2run -ne 0){
            Write-Host  "Netstats collected : $($netstatRunNr) from $($param_numberOfNetstats2run). Remote clients collected: $($remoteIP_HT.Count); Number of local ports: $($remoteIP2localPortHT.Count). Press Ctrl+C to break"
        }
        else{
            Write-Host  "Netstats collected : $($netstatRunNr). Remote clients collected: $($remoteIP_HT.Count); Number of local ports: $($remoteIP2localPortHT.Count). Press Ctrl+C to break"
        }
        if (($param_numberOfNetstats2run -ne 0) -and ($netstatRunNr -ge $param_numberOfNetstats2run)) {
            break
        }
        Start-Sleep -Milliseconds 500
    } # while true
    
}
finally #executed in case of ctrl+c is pressed
{
    $pathToCSV = "$($pathToSaveFiles)$($CurrDateTimeStr)_$($hostname)_netstat.csv"
    $pathToTxt = "$($pathToSaveFiles)$($CurrDateTimeStr)_$($hostname)_netstat.txt"

    LogWrite
    $CurrDateTimeStr=[DateTime]::Now.ToString("yyyyMMdd-HHmmss")
    $endDate=(GET-DATE)
    $duration = $endDate-$startDate
    $hostname = $env:computername
    LogWrite "Start date/time: $($startDate)"
    LogWrite "End date/time:  $($endDate)"
    LogWrite "loacal hostname: $($hostname)"
    LogWrite "loacal IP: $($local_NIC_IP)"
    LogWrite "Run time: $($duration)"
    LogWrite "Nr of netstat run:$($netstatRunNr)"
        
    LogWrite "Remote IPs having connection to this computer (any port):"
    foreach($item in $remoteIP_HT.GetEnumerator()| Sort-Object Name){
        LogWrite $item.name
    }
    LogWrite
    $PSOobj4CSV = @()
    LogWrite "Remote clents for each port:"
    foreach($item in $remoteIP2localPortHT.GetEnumerator()|Sort-Object Name){
        LogWrite "Remote clients found for local port number: $($item.name)"
        if ($item.value.count -ne 0){
            foreach($subItem in $item.value.GetEnumerator()|Sort-Object Name){
                if ($param_resolveIPs2FQDNs){
                    try{
                        $resolvedHostname = [System.Net.Dns]::GetHostEntry($subItem.name).HostName
                    }
                    catch {
                        $resolvedHostname = "<unknown>"
                    }
                    LogWrite "   $($subItem.name) ($($resolvedHostname))"
                    if ($param_CreateCSV){
                        $PSOline = [pscustomobject]@{
                            'port'    = $item.name
                            'RemoteClient'  = $subItem.name
                            'RemoteClientFQDN' = $resolvedHostname
                        }
                    }
                }
                else{
                    LogWrite "   $($subItem.name)"
                    if ($param_CreateCSV){
                        $PSOline = [pscustomobject]@{
                            'port'    = $item.name
                            'RemoteClient'  = $subItem.name
                        }
                    }
                }
                if ($param_CreateCSV){
                    $PSOobj4CSV += $PSOline
                }
            }#foreach subitem
        }
        LogWrite
    }
    if ($param_CreateCSV){
        $PSOobj4CSV|export-CSV  $pathToCSV -NoTypeInformation -append  -force
        write-host "CSV file created at $($pathToCSV)"
    }
    write-host "TXT log file created at $($pathToTXT)"
}
