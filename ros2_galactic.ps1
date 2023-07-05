# Gain Admin permissions
if(!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
 Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList "-File `"$($MyInvocation.MyCommand.Path)`"  `"$($MyInvocation.MyCommand.UnboundArguments)`""
 Exit
}

$DownloadDir = ($env:TEMP + "\ros2_install")
if (-not(Test-Path -Path $DownloadDir)) {
    New-Item -ItemType Directory -Path $DownloadDir
}

# Functions
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
        $Dir
    )
    if (-not(Test-Path -Path $Dir)) {
        Expand-Archive -Path ($DownloadDir + "\" + $File) -DestinationPath $Dir
    }
}

function Add_Links {
    param (
        $Path
    )
    $Startup = "$Path\local_setup.ps1"
    # Creating Desktop Shortcut
    $Link = ([Environment]::GetFolderPath("Desktop") + "\ROS2 Galactic Terminal.lnk")
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

function Standard-Install {
    # Install Python
    choco install -y python --version 3.8.3

    # Install Visual C++ Redistributables
    choco install -y vcredist2013 vcredist140

    # Install OpenSSL
    choco install -y openssl

    # Install Visual Studio Community
    $CONFIG = '{
      "version": "1.0",
      "components": [
        "Microsoft.VisualStudio.Component.CoreEditor",
        "Microsoft.VisualStudio.Workload.CoreEditor",
        "Microsoft.VisualStudio.Component.NuGet",
        "Microsoft.VisualStudio.Component.Roslyn.Compiler",
        "Microsoft.VisualStudio.Component.Roslyn.LanguageServices",
        "Microsoft.VisualStudio.ComponentGroup.WebToolsExtensions",
        "Microsoft.VisualStudio.Component.TypeScript.4.3",
        "Microsoft.VisualStudio.Component.JavaScript.TypeScript",
        "Microsoft.Component.MSBuild",
        "Microsoft.VisualStudio.Component.TextTemplating",
        "Microsoft.VisualStudio.Component.Debugger.JustInTime",
        "Component.Microsoft.VisualStudio.LiveShare",
        "Microsoft.VisualStudio.Component.IntelliCode",
        "Microsoft.VisualStudio.Component.VC.CoreIde",
        "Microsoft.VisualStudio.Component.VC.Tools.x86.x64",
        "Microsoft.VisualStudio.Component.Graphics.Tools",
        "Microsoft.VisualStudio.Component.VC.DiagnosticTools",
        "Microsoft.VisualStudio.Component.Windows10SDK.19041",
        "Microsoft.VisualStudio.Component.VC.Redist.14.Latest",
        "Microsoft.VisualStudio.ComponentGroup.NativeDesktop.Core",
        "Microsoft.VisualStudio.Component.VC.ATL",
        "Microsoft.VisualStudio.Component.VC.TestAdapterForBoostTest",
        "Microsoft.VisualStudio.Component.VC.TestAdapterForGoogleTest",
        "Microsoft.VisualStudio.Component.VC.ASAN",
        "Microsoft.VisualStudio.Workload.NativeDesktop"
      ]
    }'
    Set-Content -Path ($DownloadDir + "\vs_2019_ros2.vsconfig") -Value $CONFIG
    if (Test-Path -Path "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community") {
        Start-Process -FilePath 'C:\Program Files (x86)\Microsoft Visual Studio\Installer\vs_installershell.exe' -ArgumentList ("modify --passive --norestart --force --installpath 'C:\Program Files (x86)\Microsoft Visual Studio\2019\Community' --config " + $DownloadDir + "\vs_2019_ros2.vsconfig --remove Microsoft.VisualStudio.ComponentGroup.WebToolsExtensions.CMake --remove Microsoft.VisualStudio.Component.VC.CMake.Project")
    } else {
        choco install -y visualstudio2019community  --package-parameters ("--passive --config " + $DownloadDir + "\vs_2019_ros2.vsconfig")
    }

    # Install OpenCV
    $URL = “https://github.com/ros2/ros2/releases/download/opencv-archives/opencv-3.4.6-vc16.VS2019.zip”
    $FILE = ”opencv-3.4.6-vc16.VS2019.zip”
    $OPENCV_DIR = "C:\"
    Download-File -Uri $URL -OutFile $FILE
    Extract-File -File $FILE -Dir $OPENCV_DIR
    Set-Env -Name "OpenCV_DIR" -Value ($OPENCV_DIR + "opencv")
    Set-Path -NewPath "C:\opencv\x64\vc16\bin"

    # Install CMake
    choco install -y cmake
    Set-Path -NewPath "C:\Program Files\CMake\bin"

    # Install Dependencies
    $baseUri = 'https://github.com/ros2/choco-packages/releases/download/2020-02-24'
    $files = @(
        @{
            Uri = "$baseUri/asio.1.12.1.nupkg"
            OutFile = 'asio.1.12.1.nupkg'
        },
        @{
            Uri = "$baseUri/bullet.2.89.0.nupkg"
            OutFile = 'bullet.2.89.0.nupkg'
        },
        @{
            Uri = "$baseUri/cunit.2.1.3.nupkg"
            OutFile = 'cunit.2.1.3.nupkg'
        },
        @{
            Uri = "$baseUri/eigen.3.3.4.nupkg"
            OutFile = 'eigen.3.3.4.nupkg'
        },
        @{
            Uri = "$baseUri/tinyxml-usestl.2.6.2.nupkg"
            OutFile = 'tinyxml-usestl.2.6.2.nupkg'
        },
        @{
            Uri = "$baseUri/tinyxml2.6.0.0.nupkg"
            OutFile = 'tinyxml2.6.0.0.nupkg'
        },
        @{
            Uri = "$baseUri/log4cxx.0.10.0.nupkg"
            OutFile = 'log4cxx.0.10.0.nupkg'
        }
    )

    foreach ($file in $files) {
        Download-File @file
    }
    choco install -y -s $DownloadDir asio cunit eigen tinyxml-usestl tinyxml2 log4cxx bullet

    python -m pip install -U catkin_pkg cryptography empy ifcfg importlib-metadata lark-parser lxml matplotlib netifaces numpy opencv-python PyQt5 pip pillow psutil pycairo pydot pyparsing==2.4.7 pyyaml rosdistro setuptools==59.6.0

    # Install Qt5
    choco install -y aqt qtcreator
    if (-not(Test-Path -Path "C:\Qt\5.12.12\msvc2017_64")) {
        aqt install-qt --outputdir C:\Qt windows desktop 5.12.12 win64_msvc2017_64 --modules debug_info
    }
    Set-Env -Name "Qt5_DIR" -Value "C:\Qt\5.12.12\msvc2017_64"
    Set-Env -Name "QT_QPA_PLATFORM_PLUGIN_PATH" -Value "C:\Qt\5.12.12\msvc2017_64\plugins\platforms"

    # Install RQt Dependencies
    choco install -y graphviz
    Set-Path -NewPath "C:\Program Files\Graphviz\bin"

    # Install ROS2
    $release = Get-Release -Search "galactic"
    if ($release -eq $null) {
        Write-Output "Error getting release information"
        pause
        exit
    }
    $ROS_DIR = "C:\dev"
    Download-File -Uri $release.url -OutFile $release.file
    Extract-File -File $release.file -Dir $ROS_DIR
    if (Test-Path -Path "$ROS_DIR\ros2-windows") {
        Rename-Item -NewName "ros2_galactic" -Path "$ROS_DIR\ros2-windows" -Force
    }

    Add_Links -Path "$ROS_DIR\ros2_galactic"
}

function Alternate-Install {
    # Install Visual Studio Community
    $CONFIG = '{
      "version": "1.0",
      "components": [
        "Microsoft.VisualStudio.Component.CoreEditor",
        "Microsoft.VisualStudio.Workload.CoreEditor",
        "Microsoft.VisualStudio.Component.NuGet",
        "Microsoft.VisualStudio.Component.Roslyn.Compiler",
        "Microsoft.VisualStudio.Component.Roslyn.LanguageServices",
        "Microsoft.VisualStudio.ComponentGroup.WebToolsExtensions",
        "Microsoft.VisualStudio.Component.TypeScript.4.3",
        "Microsoft.VisualStudio.Component.JavaScript.TypeScript",
        "Microsoft.Component.MSBuild",
        "Microsoft.VisualStudio.Component.TextTemplating",
        "Microsoft.VisualStudio.Component.Debugger.JustInTime",
        "Component.Microsoft.VisualStudio.LiveShare",
        "Microsoft.VisualStudio.Component.IntelliCode",
        "Microsoft.VisualStudio.Component.VC.CoreIde",
        "Microsoft.VisualStudio.Component.VC.Tools.x86.x64",
        "Microsoft.VisualStudio.Component.Graphics.Tools",
        "Microsoft.VisualStudio.Component.VC.DiagnosticTools",
        "Microsoft.VisualStudio.Component.Windows10SDK.19041",
        "Microsoft.VisualStudio.Component.VC.Redist.14.Latest",
        "Microsoft.VisualStudio.ComponentGroup.NativeDesktop.Core",
        "Microsoft.VisualStudio.Component.VC.ATL",
        "Microsoft.VisualStudio.Component.VC.TestAdapterForBoostTest",
        "Microsoft.VisualStudio.Component.VC.TestAdapterForGoogleTest",
        "Microsoft.VisualStudio.Component.VC.ASAN",
        "Microsoft.VisualStudio.Workload.NativeDesktop",
        "Microsoft.VisualStudio.ComponentGroup.WebToolsExtensions.CMake",
        "Microsoft.VisualStudio.Component.VC.CMake.Project"
      ]
    }'
    Set-Content -Path ($DownloadDir + "\vs_2019_ros2.vsconfig") -Value $CONFIG
    if (Test-Path -Path "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community") {
        Start-Process -FilePath 'C:\Program Files (x86)\Microsoft Visual Studio\Installer\vs_installershell.exe' -ArgumentList ("modify --passive --norestart --force --installpath 'C:\Program Files (x86)\Microsoft Visual Studio\2019\Community' --config " + $DownloadDir + "\vs_2019_ros2.vsconfig")
    } else {
        choco install -y visualstudio2019community  --package-parameters ("--passive --config " + $DownloadDir + "\vs_2019_ros2.vsconfig")
    }

    # Install Git
    choco upgrade git -y

    # Install ROS
    $env:ChocolateyInstall = "c:\opt\chocolatey"
    choco source add -n=ros-win -s="https://aka.ms/ros/public" --priority=1
    choco upgrade ros-galactic-desktop -y --execution-timeout=0 -pre

    Add_Links -Path "C:\opt\ros\galactic\x64\"
}

function Uninstall-Ros {
    # Uninstall ROS2 Standard
    $ROS_DIR = "C:\dev"
    if (Test-Path -Path $ROS_DIR) {
        $ROS_DIR_INSTALL = "$ROS_DIR\ros2_galactic"
        $ROS_START = "$ROS_DIR_INSTALL\local_setup.ps1"
        if (Test-Path -Path $ROS_DIR_INSTALL) {
            Uninstall -Path $ROS_DIR_INSTALL -Title "ROS2 Galactic Standard"
        }
        $ROS_INSTALL_COUNT = (Get-ChildItem -Directory -Path $ROS_DIR | Measure-Object).Count
        if ($ROS_INSTALL_COUNT -eq 0) {
	        Remove-Item -Path $ROS_DIR
        }
    }

    # Uninstall ROS2 Alternate Build
    if (Test-Path -Path "C:\opt") {
        $ROS_START = "C:\opt\ros\galactic\x64\local_setup.ps1"
        $env:ChocolateyInstall = "c:\opt\chocolatey"
        choco uninstall -y ros-galactic-desktop
        $ROS_INSTALL_COUNT = (Get-ChildItem -Directory -Path $ROS_DIR | Measure-Object).Count
        if ($ROS_INSTALL_COUNT -eq 0) {
	        Remove-Item -Path "C:\opt" -Recurse -Force
        }
    }

    # Removing Links
    $Documents = ([Environment]::GetFolderPath("MyDocuments") + "\WindowsPowerShell")
    $ProfileFile = "$Documents\Microsoft.PowerShell_profile.ps1"
    if ((Test-Path -Path $ProfileFile -PathType Leaf) -and $ROS_START -ne $null) {
        $SEL = Select-String -Path $ProfileFile -Pattern $ROS_START -SimpleMatch

        if ($SEL -ne $null)
        {
            $REMOVED_LINK = Get-Content $ProfileFile | Where-Object {$_ -notlike $ROS_START}
            Set-Content $ProfileFile -Value $REMOVED_LINK -Force
        }
    }
    $Link = ([Environment]::GetFolderPath("Desktop") + "\ROS2 Galactic Terminal.lnk")
    if (Test-Path -Path $Link -PathType Leaf) {
        Remove-Item -Path $Link
    }
}

function Uninstall-Dep {
    # Uninstall python packages
    python -m pip uninstall -y catkin_pkg cryptography empy ifcfg importlib-metadata lark-parser lxml matplotlib netifaces numpy opencv-python PyQt5 pip pillow psutil pycairo pydot pyparsing==2.4.7 pyyaml rosdistro setuptools==59.6.0

    # Uninstall Chocolaty packages
    ECHO Y | choco uninstall -y graphviz -n
    choco uninstall -y aqt qtcreator
    choco uninstall -y asio cunit eigen tinyxml-usestl tinyxml2 log4cxx bullet
    ECHO Y | choco uninstall -y cmake
    choco uninstall -y visualstudio2019community
    choco uninstall -y openssl
    choco uninstall -y vcredist2013 vcredist140
    choco uninstall -y python --version 3.8.3 python3 --version 3.8.3

    # Uninstall Others
    Uninstall -Path "C:\Qt" -Title "Qt5"
    Uninstall -Path "C:\opencv" -Title "Qt5"
    Uninstall -Path "C:\Python38" -Title "Python Leftovers"

    # Remove Environment variables
    Set-Env -Name "Qt5_DIR" -Value ""
    Set-Env -Name "QT_QPA_PLATFORM_PLUGIN_PATH" -Value ""
    Set-Env -Name "OpenCV_DIR" -Value ""
    Remove-Path -RemovePath "C:\opencv\x64\vc16\bin"
    Remove-Path -RemovePath "C:\Program Files\CMake\bin"
    Remove-Path -RemovePath "C:\Program Files\Graphviz\bin"
    Remove-Path -RemovePath "C:\Program Files\OpenSSL-Win64\bin"
    Remove-Path -RemovePath "C:\Python38\"
    Remove-Path -RemovePath "C:\Python38\Scripts\"
}

# Install Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Check if installed already
$Standard = "C:\dev\ros2_galactic"
$Alternate = "C:\opt\ros\galactic"
if ((Test-Path -Path $Standard) -or (Test-Path -Path $Alternate)) {
    $title    = 'You already have ROS2 Galactic installed.'
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
    $title    = 'Install ROS 2 Galactic'
    $question = 'What build would you like to install?'
    $choices  = '&0: Standard (From ROS Creators)', '&1: Alternate (Offical Microsoft Build)'
    $decision = $Host.UI.PromptForChoice($title, $question, $choices, 0)

    if ($decision -eq 0) {
        Standard-Install
    } else {
        Alternate-Install
    }
}