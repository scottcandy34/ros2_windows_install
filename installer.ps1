# Gain Admin permissions
if(!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
 Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList "-File `"$($MyInvocation.MyCommand.Path)`"  `"$($MyInvocation.MyCommand.UnboundArguments)`""
 Exit
}

# Install Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

$DownloadDir = ($env:TEMP + "\ros2_install")
if (-not(Test-Path -Path $DownloadDir)) {
    New-Item -ItemType Directory -Path $DownloadDir
}

# Set version
$Version = "testing"
$Version_Title = "TESTING"

function Set-Env {
    param (
        $Name,
        $Value
    )
    [Environment]::SetEnvironmentVariable($Name, $Value, "Machine")
}

function Set-Path {
    param (
        $NewPath
    )
    $PATH = [System.Environment]::GetEnvironmentVariable('PATH', 'Machine')
    if (-not($PATH.Contains($NewPath))) {
      Set-Env -Name "PATH" -Value ($PATH + ";" + $NewPath)
    }
}

function Remove-Path {
    param (
        $RemovePath
    )
    $PATH = [System.Environment]::GetEnvironmentVariable('PATH', 'Machine')
    $PATH = ($PATH.Split(';') | Where-Object { $_ -ne $RemovePath }) -join ';'
    Set-Env -Name "PATH" -Value $PATH
}

function Uninstall {
    param (
        $Path,
        $Title
    )
    if (Test-Path -Path ($Path)) {
        $filesToDelete = Get-ChildItem $Path -Recurse
        [array]::Reverse($filesToDelete)

        [int]$hundredthStep = $filesToDelete.Count / 100
        for($i = 0; $i -lt $filesToDelete.Count; $i += $hundredthStep){
            # calculate progress percentage
            $percentage = ($i + 1) / $filesToDelete.Count * 100
            Write-Progress -Activity "Uninstalling $Title" -Status "Deleting File up to #$($i+1)/$($filesToDelete.Count)" -PercentComplete $percentage
            # delete file
            $filesToDelete[$i..($i + $hundredthStep - 1)] | Remove-Item -Force -Recurse
        }
        # All done
        Write-Progress -Activity "Uninstalling $Title" -Completed
        if (Test-Path -Path $Path) {
            Remove-Item -Path $Path -Force -Recurse
        }
    }
    
}

function Download-File {
    param (
        $Uri,
        $OutFile
    )
    if (-not(Test-Path -Path ($DownloadDir + "\" + $OutFile) -PathType Leaf)) {
        Invoke-WebRequest -Uri $Uri -OutFile ($DownloadDir + "\" + $OutFile)
    }
}

function Get-Release {
    param (
        $Search,
        $Page = 1
    )

    $repo = "ros2/ros2"
    $api_uri = "https://api.github.com/repos/$repo/releases?page=$Page&per_page=100"

    $releases = (Invoke-WebRequest $api_uri -UseBasicParsing | ConvertFrom-Json)

    if ($releases -eq $null) {
        return $null
    }

    $release = $releases | Where-Object {$_.tag_name -like "*$Search*"} | Select-Object -First 1

    if ($release -eq $null) {
        $Page++
        return Get-Release -Search $Search -Page $Page
    } else {
        $asset = $release.assets | Where-Object {$_.name -like "*-windows-release-amd64.zip"} | Select-Object -First 1
        $file = $asset.name
        $download = $asset.browser_download_url
        return @{ file = $file; url = $download }
    }
}

function Extract-File { 
    param (
        $File,
        $Dir,
        $Folder = ""
    )
    if (-not(Test-Path -Path ($Dir + $Folder))) {
        Expand-Archive -Path ($DownloadDir + "\" + $File) -DestinationPath $Dir
    }
}

function Add_Links {
    param (
        $Path
    )
    $Startup = "$Path\start.ps1"
    if (-not(Test-Path -Path ($Startup) -PathType Leaf)) {
        $Startup = "$Path\local_setup.ps1"
    }

    # Creating Desktop Shortcut
    $Link = ([Environment]::GetFolderPath("Desktop") + "\ROS2 $Version_Title Terminal.lnk")
    if (Test-Path -Path $Link -PathType Leaf) {
        Remove-Item -Path $Link
    }
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($Link)
    $Shortcut.TargetPath = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
    $Shortcut.Arguments = "-ExecutionPolicy Bypass -NoExit -File `"" + $Startup + "`""
    $Shortcut.Save()

    # Optional add to powershell startup
    $Documents = ([Environment]::GetFolderPath("MyDocuments") + "\WindowsPowerShell")
    $title    = 'Add ROS2 to your powershell startup so you can call ROS2 at anytime without loading the script or launching the shortcut.'
    $question = 'Are you sure you want to proceed?'
    $choices  = '&Yes', '&No'

    $decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)
    if ($decision -eq 0) {
        Write-Host 'Adding to Powershell'

        if (-not(Test-Path -Path $Documents)) {
            New-Item -ItemType Directory -Path $Documents
        }

        $ProfileFile = ($Documents + "\Microsoft.PowerShell_profile.ps1")
        if (Test-Path -Path $ProfileFile -PathType Leaf) {
            $SEL = Select-String -Path $ProfileFile -Pattern $Startup -SimpleMatch

            if ($SEL -eq $null)
            {
                Add-Content -Path $ProfileFile -Value $Startup
            }
        } else {
            Set-Content -Path $ProfileFile -Value $Startup
        }
    }
}

function Install-Python {
    # Get all python versions if exists
    $PyVersions = py -0p
    $Py38 = $PyVersions | Select-String -Pattern '(3.8)(?:-\d*)?[\s\*]*(.*)python\.exe'

    # Temporarily remove all other python versions
    $PyDir = $PyVersions | Select-String -Pattern '.:[^:;]*\.exe' -AllMatches
    $PyPaths = @()
    foreach ($_dir in $PyDir.Matches.Value) {
        $PyPaths += $_dir.Replace("python.exe", "Scripts\")
        $PyPaths += $_dir.Replace("python.exe", "")
    }
    foreach ($_dir in $PyPaths) {
        $env:Path = $env:Path.Replace($_dir,'')
        $env:Path = $env:Path.Replace(';;', ';')
        $env:Path = $env:Path -replace('^;', '')
    }

    # Only allow python 3.8 if exists already
    if ($Py38) {
        $env:Path = $Py38.Matches.Groups[2].Value + ";" + $Py38.Matches.Groups[2].Value + "Scripts\;" + $env:Path
    }

    choco upgrade -y python --version=3.8.3
}

function Python-Path {
    $Py38 = py -0p | Select-String -Pattern '(3.8)(?:-\d*)?[\s\*]*(.*\.exe)'
    return $Py38.Matches.Groups[2].Value
}

function Create-Start-File {
    param (
        $Dir
    )

    $Startup = "$Dir\start.ps1"
    if (Test-Path -Path ($Startup) -PathType Leaf) {
        Remove-Item -Path $Startup
    }
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/scottcandy34/ros2_windows_install/main/start.ps1" -OutFile ($Startup)
    "`n$Dir\local_setup.ps1" | Add-Content $Startup
    "`$Host.UI.RawUI.WindowTitle = `"Loading $Version_Title Environment`"`n" + (Get-Content $Startup -Raw) | Set-Content $Startup
}

function Startup-Add {
    param (
        $Content,
        $Dir
    )

    $Startup = "$Dir\start.ps1"
    "$Content`n" + (Get-Content $Startup -Raw) | Set-Content $Startup
}

function Standard-Install {
    $null
}

function Alternate-Install {
    $null
}

function Uninstall-Ros {
    $null
}

function Uninstall-Dep {
    $null
}


function Start-Installer {
    # Check if installed already
    $Standard = "C:\dev\ros2_$Version"
    $Alternate = "C:\opt\ros\$Version"
    if ((Test-Path -Path $Standard) -or (Test-Path -Path $Alternate)) {
        $title    = "You already have ROS2 $Version_Title installed."
        $question = 'What Would you like to do?'
        $choices  = '&0: Update/Reinstall', '&1: Uninstall ROS', '&2: Uninstall Dependencies'
        $decision = $Host.UI.PromptForChoice($title, $question, $choices, 0)

        if ($decision -eq 0) {
            if (Test-Path -Path $Standard) {
                Standard-Install
            } elseIf (Test-Path -Path $Alternate) {
                Alternate-Install
            }
        } elseif ($decision -eq 1) {
            Uninstall-Ros
        } elseif ($decision -eq 2) {
            Uninstall-Dep
        }
    } else {
        # Ask What Build Type
        $title    = "Install ROS 2 $Version_Title"
        $question = 'What build would you like to install?'
        $choices  = '&0: Standard (From ROS Creators)', '&1: Alternate (Offical Microsoft Build)'
        $decision = $Host.UI.PromptForChoice($title, $question, $choices, 0)

        if ($decision -eq 0) {
            Standard-Install
        } else {
            Alternate-Install
        }
    }
}