# xInstallGit

The **xInstallGit** module contains the **xInstallGit** DSC resource for setting up and configuring [Git](https://git-scm.com/) for Windows.

## Resources

### xInstallGit

* **Version**: Version of Git to Install.
* **InstallerPath**: Path to the Git Installer. The machine account must have access to this path if hosted on anetwork location.
* **InstallerArchitecture**: Architecture of the Git installer (x86 or x64)
* **Ensure**: Specifies if git should be Present, Absent, or AnyVersionPresent (any version installed).

## Examples
#### Ensure that the specified version of git is installed

This configuration ensures that the specified version of Git is installed.

```powershell
Configuration InstallOrUpgradeGit
{
    Import-DscResource -Name PCM_xInstallGit
    # A Configuration block can have zero or more Node blocks
    Node localhost
    {
        xInstallGit InstallGit
        {
            Ensure = "Present" 
            Version   = "2.8.1"
            InstallerPath = "\\DC\installers\git\Git-2.8.1-64-bit.exe"  
            InstallerArchitecture = "x64"
        }
    }
} 

InstallOrUpgradeGit
```

### Ensure that some version of Git is installed

This configuration ensures that git is installed, but will not upgrade to the latest.

```powershell
Configuration InstallSomeVersionOfGit
{
    Import-DscResource -Name PCM_xInstallGit
    Node localhost
    {
        # Next, specify one or more resource blocks

        xInstallGit SomeGitInstalled
        {
            Ensure = "AnyVersionPresent" 
            Version   = "2.8.1"
            InstallerPath = "\\DC\installers\git\Git-2.8.1-64-bit.exe"
            InstallerArchitecture = "x64"        
        } 
    }
}
InstallSomeVersionOfGit
```

### Remove Git

This example removes git if it is installed

```powershell
Configuration RemoveGit
{
    Import-DscResource -Name PCM_xInstallGit
    Node localhost
    {
        xInstallGit RemoveGit
        {
            Ensure = "Absent" 
            Version   = "2.8.1"
            InstallerPath = "\\DC\installers\git\Git-2.8.1-64-bit.exe"
            InstallerArchitecture = "x64"          
        }
    }
} 

RemoveGit
```
