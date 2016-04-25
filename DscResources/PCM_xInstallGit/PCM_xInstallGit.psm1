function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Version,
                
        [ValidateScript({Test-Path $_ -PathType 'Leaf'})]
        [System.String[]]
        $InstallerPath,
        
        [parameter(Mandatory = $true)]
        [Alias("Arch")]
        [ValidateSet("x64","x86")]
        [System.String]
        $InstallerArchitecture
    )
    
    Write-Verbose "Getting uninstall key from registry."
    if ($InstallerArchitecture -eq "x64")
    {
        if ((Get-WmiObject -Class Win32_ComputerSystem).SystemType -match '(x64)')
        {
            $UninstallRegPath = "hklm:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Git_is1"
        }
        else
        {
            throw "Cannot install 64-bit executable on 32-bit operating system."
        }
    }
    else
    {
        if ((Get-WmiObject -Class Win32_ComputerSystem).SystemType -match '(x86)')
        {
            $UninstallRegPath = "hklm:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Git_is1"
        }
        else
        {
            $UninstallRegPath = "hklm:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Git_is1"
        }
    }
    Write-Verbose "Using registry key: $UninstallRegPath"

    $SoftwareRegPath = "hklm:\SOFTWARE\GitForWindows"
    if (Test-Path $SoftwareRegPath)
    {
        $item = Get-Item $SoftwareRegPath
        $InstalledVersion = $item.GetValue("CurrentVersion")
        Write-Verbose "Currently installed git version: $InstalledVersion"
        if ($InstalledVersion -eq $Version)
        {
            $Ensure = "Present"
        }
        else
        {
            $Ensure = "AnyVersionPresent"
        }
        $ReturnValue = @{
            "Ensure" = $Ensure;
            "Version" = $InstalledVersion
        }
    }
    elseif (Test-Path $UninstallRegPath)
    {
        $item = Get-Item $UninstallRegPath
        $InstalledVersion = $item.GetValue("DisplayVersion")
        Write-Verbose "Currently installed git version: $InstalledVersion"
        if ($InstalledVersion -eq $Version)
        {
            $Ensure = "Present"
        }
        else
        {
            $Ensure = "AnyVersionPresent"
        }
        $ReturnValue = @{
            "Ensure" = $Ensure;
            "Version" = $InstalledVersion
        }
    }
    else
    {
        $ReturnValue = @{
            "Ensure" = "Absent";
            "Version"="0"
        }
    }

    return $ReturnValue
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Version,

        [parameter(Mandatory = $true)]
        [Alias("Arch")]
        [ValidateSet("x64","x86")]
        [System.String]
        $InstallerArchitecture,
        
        [ValidateScript({Test-Path $_ -PathType 'Leaf'})]
        [System.String[]]
        $InstallerPath,

        [parameter(Mandatory = $true)]
        [ValidateSet("Present","AnyVersionPresent","Absent")]
        [System.String]
        $Ensure
    )
    
    if (($Ensure -eq "Present") -or ($Ensure -eq "Absent"))
    {
        if (($InstallerArchitecture -eq "x64") -or ((Get-WmiObject -Class Win32_ComputerSystem).SystemType -match '(x86)'))
        {
            Write-Verbose "Uninstalling the previous Git install"
            # Uninstall the old Version.
            $GitReg = Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\ | ? { $_.Name -match "Git_is1" }
            $UninstallString = $GitReg.GetValue("QuietUninstallString").Replace('"', "").Replace("Program Files", "Program`` Files")
            $UninstallString        
        }
        elseif (($InstallerArchitecture -eq "x86") -and ((Get-WmiObject -Class Win32_ComputerSystem).SystemType -match '(x64)'))
        {
            Write-Verbose "Uninstalling the previous Git install"
            # Uninstall the old Version.
            $GitReg = Get-ChildItem HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\ | ? { $_.Name -match "Git_is1" }
            $UninstallString = $GitReg.GetValue("QuietUninstallString").Replace('"', "").Replace("Program Files", "Program`` Files")
            $UninstallString
        }
    }
    
    if ((($Ensure -eq "Present") -or ($Ensure -eq "AnyVersionPresent")) -and (Test-Path $InstallerPath -PathType 'Leaf'))
    {
        $GitInstallerBaseName = (Get-Item $InstallerPath).BaseName
        $ScriptArgs = "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /NOCANCEL /SP- /NOICONS /COMPONENTS=`"icons,icons\quicklaunch,ext,ext\reg,ext\reg\shellhere,ext\reg\guihere,assoc,assoc_sh`" /LOG=$env:temp\$GitInstallerBaseName.log"
        $cmd = "$InstallerPath $ScriptArgs"

        Invoke-Expression $cmd | Write-Verbose
        $i = 0
        while (@(Get-Process $GitInstaller -ErrorAction SilentlyContinue).Count -ne 0)
        {
            Write-Verbose "Waiting for Git to finish installing..."
            $i++
            if ($i > 100)
            {
                exit 1;
            }
            Start-Sleep 20
        }
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Version,
        
        [parameter(Mandatory = $true)]
        [Alias("Arch")]
        [ValidateSet("x64","x86")]
        [System.String]
        $InstallerArchitecture,
        
        [ValidateScript({Test-Path $_ -PathType 'Leaf'})]
        [System.String[]]
        $InstallerPath,

        [ValidateSet("Present","AnyVersionPresent","Absent")]
        [System.String]
        $Ensure
    )
    
    $testResult = $false;
    $Git = Get-TargetResource -Version $Version -InstallerArchitecture $InstallerArchitecture #-ErrorAction SilentlyContinue -ErrorVariable ev

    if ($Ensure -eq "Present")
    {
        if ($Git.Ensure -eq "Present")
        {
            $Params = 'Version', 'Ensure'
            if ($Git.Version -eq $Version)
            {
                Write-Verbose "Compliant: Installer version equals installed version: $Version"
                $testResult = $true
            }
            else
            {
                Write-Verbose "Not Compliant: Installer version ($Version) does not equal installed version ($($Git.Version))"
                $testResult = $false
            }
        }
        elseif (($Git.Ensure -eq "Absent") -or ($Git.Ensure -eq "AnyVersionPresent"))
        {
            Write-Verbose "Not Compliant: Installer version ($Version) does not equal installed version ($($Git.Version))"
            $testResult = $false
        }
    }
    elseif ($Ensure -eq "AnyVersionPresent")
    {
        if (($Git.Ensure -eq "Present") -or ($Git.Ensure -eq "AnyVersionPresent"))
        {
            $Params = 'Version', 'Ensure'
            if ($Git.Version -ne "0")
            { 
                $testResult = $true
                Write-Verbose "Compliant: Installer version ($Version) greater than or equal to installed version ($($Git.Version))"
            }
            else
            {
                # Impossible to get here?
                $testResult = $false
                Write-Verbose "Not Compliant: Git is not installed. This shouldn't be possible."
            }
        }
        elseif ($Git.Ensure -eq "Absent")
        {   
            $testResult = $false
            Write-Verbose "Not Compliant: Git is not installed"
        }
    }
    else
    {
        if ($Git.Ensure -eq "Absent")
        {
            $testResult = $true
            Write-Verbose "Compliant: Git is not Installed"
        }
        else
        {
            $testResult = $false
            Write-Verbose "Not Compliant: Git is installed."
        }
    }
    return $testResult
}

Export-ModuleMember -Function *-TargetResource

