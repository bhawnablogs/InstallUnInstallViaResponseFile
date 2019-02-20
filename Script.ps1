#function for writing into log file
$Logfile = "$ScriptDir\TempLog.log"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
[string] $TargetLocation = "C:\TEMP"
$<Product>Build = "<Product>_23.20.96_2018_Update_1.0_BETA2.exe"
$unzipPath = "C:\Unzipped_<Product>"
$Path= <PathwhereproductGetInstalled>
$setupPath =<PathWhereSetUpFileIsPresent>
Function LogWrite([string]$logstring)
{
    Add-content $Logfile -value $logstring
}

Function InstallBuild([string]$<Product>BuildNumber)
{
    LogWrite "Started--------------------------------------------------------------------------------Started"
    LogWrite "BuildNumber $<Product>BuildNumber"
    if(Test-Path $unzipPath)
    {
        Remove-Item -Path $unzipPath -Recurse
    }
    New-Item -ItemType directory -Path $unzipPath 
    LogWrite "Unzipping at"+ $unzipPath
    Add-Type -assembly "system.io.compression.filesystem"
    [io.compression.zipfile]::ExtractToDirectory($<Product>LocalInstaller, $unzipPath)
    LogWrite "Starting installation"

    $sw = [Diagnostics.Stopwatch]::StartNew()
    $installResponseFile = "Install_"+$<Product>BuildNumber.Replace(".exe",".iss")
    $myargs = "/s /f1""" + "$ScriptDir\$installResponseFile"""
    $procExitCode = (Start-Process -FilePath $setupPath -ArgumentList $myargs -Wait).ExitCode
    $sw.Stop()

    $sec = $sw.Elapsed.Seconds
    $min = $sw.Elapsed.Minutes
    $hours = $sw.Elapsed.Hours
    $sw1 = $sw.Elapsed.ToString('hh\:mm\:ss')
    LogWrite "Installation Time Elapsed:$sw1" 

    
    if(Test-Path $Path)
    { 
        LogWrite "Installation Completed"
    }
    else
    {
        LogWrite "Installation Failed; Either with Error Code $procExitCode Or Some Other Problem"
    }
}
    LogWrite "Verification Started"
    #for editing adding exact to directories in xml file
    $dir = Get-Content $ScriptDir\GoldenSetup.xml
    # $word = "exact="
    # if($dir -Match $word)
    # {
    #     #do nothing
    # }

    # else 
    # {   
    #     (Get-Content $ScriptDir\GoldenSetup.xml) | 
    #     Foreach-Object { If ($_ -match "<dir name") { $_ -replace ">", " exact=`"true`">"} else { $_ } } | 
    #     Set-Content $ScriptDir\GoldenSetup.xml
    # } 

    # #only to change build version in xml file
    # $product= Get-Content -Path "C:\UnZipped_<Product>\89600 Software\setup.ini" | select-string -pattern "Product="
    # $betasplit = $product -split'='
    # $BV = $betasplit.Split()
    # if($BV[5])
    # {
    #     $betaFromIni = $BV[4]+" " +$BV[5]
    # }
    # else
    # {
    #     $betaFromIni = $BV[4]
    # } 
    # $abc = '<variable name="BuildVersion" type="EXPAND_SZ">'+$betaFromIni+'</variable>'
    # (Get-Content $ScriptDir\GoldenSetup.xml) | %{ $_ -replace '<variable name="BuildVersion" type="EXPAND_SZ">(.*)</variable>',$abc}| Set-Content $ScriptDir\GoldenSetup.xml

    #to append results of install verifier to log file
    Start-Process "C:\Program Files (x86)\Agilent\InstallVerifier\InstallVerifier.exe" $ScriptDir\GoldenSetup.xml -RedirectStandardOutput $ScriptDir\error.log -wait
    Add-Content -Path $ScriptDir\TempLog.log -value (Get-Content $ScriptDir\error.log)
    remove-item $ScriptDir\error.log
    LogWrite "Verification Ended"

} 
Function <Product>Install([string]$<Product>BuildNumber)
{ 
#Writing start time in LogFile
    $startedProcessAt = Get-Date  -format "dd/MM/yyyy-hh:mm"
    LogWrite "Starting Process at $startedProcessAt"
    $<Product>LocalInstaller = (Get-ChildItem -Path $TargetLocation\* -include $<Product>BuildNumber -file).FullName
    if($<Product>LocalInstaller)
    {   
           LogWrite "Local Installer present; we will directly install it"
           InstallBuild($<Product>BuildNumber)          
    } 
    else
    {
            LogWrite "Copying from Remote Location and then install"
            $<Product>RemoteInstaller = (Get-ChildItem -Path "\\srsnas01.srs.is.keysight.com\glacier\archive\untested\WhitneyMR\*" -include $<Product>Build -file).FullName
            if($<Product>RemoteInstaller)
            {
            Copy-Item $<Product>RemoteInstaller -Destination $TargetLocation
            InstallBuild($<Product>BuildNumber)
            }
            else
            {
            LogWrite "Build Not Present at shared location"
            }
    }
}
Function <Product>UnInstall([string]$<Product>BuildNumber)
{ 
    #Writing start time in LogFile
    $startedProcessAt = Get-Date  -format "dd/MM/yyyy-hh:mm"
    LogWrite "Starting Process at $startedProcessAt"    
    if(Test-Path $unzipPath)
    {        
        LogWrite "Starting Un installation"
        $sw = [Diagnostics.Stopwatch]::StartNew()
        $uninstallResponseFile = "UnInstall_"+$<Product>BuildNumber.Replace(".exe",".iss");
        #$uninstallResponseFile = "UnInstall_<Product>_20180911_23.20.262.iss"
        $myargs = "/s /f1""" + "$ScriptDir\$uninstallResponseFile"""
        
        $procExitCode = (Start-Process -FilePath $setupPath -ArgumentList $myargs -Wait).ExitCode
        $sw.Stop()

        $sec = $sw.Elapsed.Seconds
        $min = $sw.Elapsed.Minutes
        $hours = $sw.Elapsed.Hours
        $sw1 = $sw.Elapsed.ToString('hh\:mm\:ss')
        LogWrite "Installation Time Elapsed:$sw1" 

        #to check if application file is there or not
        if(!(Test-Path $Path))
        { 
            LogWrite "UnInstall Successfull"
        }
        
        else
        {
            LogWrite "UnInstall Not Successfull"
        }
    }
    else
    {
        LogWrite "Local Installer is not present; To UnInstall local Installer should be present"
    }
    LogWrite "Ended--------------------------------------------------------------------------------Ended"
    LogWrite "BuildNumber $<Product>BuildNumber"
}
<Product>Install $<Product>Build
<Product>UnInstall $<Product>Build
