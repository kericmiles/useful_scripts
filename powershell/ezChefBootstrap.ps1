#install chef solo client, adapted from https://docs.chef.io/install_bootstrap.html
#oneliner to run script remote
#$file = $env:temp + "\bootstrap.ps1";$dl = $env:temp + "\dlfile.ps1";(New-Object System.Net.WebClient).DownloadFile("URL_HERE", $dl);Get-Content $dl|Out-File $file;PowerShell.exe -ExecutionPolicy Bypass -File $file

$clientrb = @"
cookbook_path       'C:\\chef\\cookbook'
file_cache_path     'C:\\chef\\cache'
solo                true
"@
$runlist = @{
    "run_list" = @("role[base]")
}
$tempdir = $env:temp + "\chef"

if (-Not (Test-Path C:\opscode\chef\bin)){    
    New-Item -Path $tempdir -Force -ItemType Directory | Out-Null
    $clientURL = "https://packages.chef.io/files/stable/chef/13.6.4/windows/2012r2/chef-client-13.6.4-1-x64.msi"
    $clientDestination = $tempdir + "\chef-client.msi"
    $clientInstallLog = $tempdir +  "\chef-log.txt"

    try{
        Write-Host "Downloading Chef client from chef.io..."
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile($clientURL, $clientDestination)
        Write-Host "Download complete."
    }
    catch{
        Write-Host "Could not download Chef client`nURL:$clientURL `nDirectory: $tempdir`nERROR: $_`n"
        exit;
    }

    try{
        Write-Host "Starting install of Chef client...."
        $pinfo = New-Object System.Diagnostics.ProcessStartInfo
        $pinfo.FileName = "msiexec.exe "
        $pinfo.RedirectStandardError = $true
        $pinfo.RedirectStandardOutput = $true
        $pinfo.UseShellExecute = $false
        $pinfo.Arguments = @('/qn', "/lv $clientInstallLog", "/i $clientDestination", 'ADDLOCAL="ChefClientFeature,ChefPSModuleFeature"')
        
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $pinfo
        $process.Start() | Out-Null
        $process.WaitForExit()
        $proccessExit = $process.ExitCode
        if($proccessExit -eq 0){
            Write-Host "Install completed sucessfully."
        }
        else{
            Write-Host "Could not install Chef Client `nErrorCode: $proccessExit"
            Write-Host "Try running Powershell as Administrator"
            exit;
        }
    }
    catch{
        Write-Host "Could not install chef client`nERROR: $_`n"
    }
    ## Create first-boot.json
    Set-Content -Path c:\chef\first-boot.json -Value ($runlist | ConvertTo-Json -Depth 10)
    Set-Content -Path c:\chef\client.rb -Value $clientrb
    Write-Host "Config files created."
}
else{
    Write-Host "Chef client appears to be installed, exiting."
}