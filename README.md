# ROS2 Windows Installers
A Simplified all in one ROS2 Installer for windows
- Written in Powershell
- Will also create desktop shortcut for opening the ros terminal
- Will Prompt to add to powershell startup
- Download script and run with powershell.
- Can Update/reinstall and uninstall
- Will always get latest version available
#### Multiple installed versions
You should be able to install multiple versions at once. Just opt out of the last option asking to add to powershell startup. You will have different desktop links pointing to the installed versions.
- This will not install multiple dependencies, only what is not already installed.
## Iron Irwini [Release](https://github.com/ros2/ros2/releases?q=iron+irwini)
- Installer based off of their [documentation](https://docs.ros.org/en/iron/Installation/Windows-Install-Binary.html).
#### To use, run this command inside an administrative shell (Powershell).
`iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/scottcandy34/ros2_windows_install/main/ros2_iron.ps1'))`
## Humble Hawksbill - [Release](https://github.com/ros2/ros2/releases?q=humble+hawksbill)
- Tested on windows 10 and 11
- Installer based off of their [documentation](https://docs.ros.org/en/humble/Installation/Windows-Install-Binary.html).
#### To use, run this command inside an administrative shell (Powershell).
`iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/scottcandy34/ros2_windows_install/main/ros2_humble.ps1'))`
## Galactic Geochelone - [Release](https://github.com/ros2/ros2/releases?q=galactic+geochelone)
- Installer based off of their [documentation](https://docs.ros.org/en/galactic/Installation/Windows-Install-Binary.html).
#### To use, run this command inside an administrative shell (Powershell).
`iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/scottcandy34/ros2_windows_install/main/ros2_galactic.ps1'))`
## Foxy Fitzroy - [Release](https://github.com/ros2/ros2/releases?q=foxy+fitzroy)
- Installer based off of their [documentation](https://docs.ros.org/en/foxy/Installation/Windows-Install-Binary.html).
#### To use, run this command inside an administrative shell (Powershell).
`iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/scottcandy34/ros2_windows_install/main/ros2_foxy.ps1'))`
