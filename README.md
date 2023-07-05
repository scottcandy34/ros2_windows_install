# ROS2 Windows Installers
A Simplified all in one ROS2 Installer for windows
- Written in Powershell
- Will also create desktop shortcut for opening the ros terminal
- Will Prompt to add to powershell startup
- Download script and run with powershell.
- Can Update/reinstall and uninstall
- Will always get latest version available
## Iron Irwini [Release](https://github.com/ros2/ros2/releases/tag/release-iron-20230523)
- Installer based off of their [documentation](https://docs.ros.org/en/iron/Installation/Windows-Install-Binary.html).
#### To use run this command inside an administrative shell.
`iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/scottcandy34/ros2_windows_install/main/ros2_iron.ps1'))`
## Humble Hawksbill - [Patch Release 3.1](https://github.com/ros2/ros2/releases/tag/release-humble-20230614)
- Tested on windows 10 and 11
- Installer based off of their [documentation](https://docs.ros.org/en/humble/Installation/Windows-Install-Binary.html).
#### To use run this command inside an administrative shell.
`iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/scottcandy34/ros2_windows_install/main/ros2_humble.ps1'))`
## Galactic Geochelone - [Patch Release 2](https://github.com/ros2/ros2/releases/tag/release-galactic-20221209)
- Installer based off of their [documentation](https://docs.ros.org/en/galactic/Installation/Windows-Install-Binary.html).
#### To use run this command inside an administrative shell.
`iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/scottcandy34/ros2_windows_install/main/ros2_galactic.ps1'))`
## Foxy Fitzroy - [Patch Release 11](https://github.com/ros2/ros2/releases/tag/release-foxy-20230620)
- Installer based off of their [documentation](https://docs.ros.org/en/foxy/Installation/Windows-Install-Binary.html).
#### To use run this command inside an administrative shell.
`iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/scottcandy34/ros2_windows_install/main/ros2_foxy.ps1'))`
