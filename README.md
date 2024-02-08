# ROS2 Windows Installers
A Simplified all in one ROS2 Installer for windows
- Written in Powershell
- Will also create desktop shortcut for opening the ros terminal
- Will Prompt to add to powershell startup
- Download script and run with powershell.
- Can Update/reinstall and uninstall
- Will always get latest version available
#### Windows 11 support
- rviz2 command does not display anything. (issue)
- ros2 seams to work just fine.
- rqt_graph seams to work as well.
#### Multiple installed versions
You should be able to install multiple versions at once. Just opt out of the last option asking to add to powershell startup. You will have different desktop links pointing to the installed versions.
- This will not install multiple dependencies, only what is not already installed.
## Iron Irwini [Release](https://github.com/ros2/ros2/releases?q=iron+irwini)
- Tested on windows 10 and 11
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

## Colcon Errors:
If you encounter this kind of result in Windows, it is a bug in the notification display, just see Success, you can ignore it
````
Finished <<< simple_230215 [3.75s]

Summary: 1 package finished [4.20s]
  1 package had stderr output: simple_230215
WNDPROC return value cannot be converted to LRESULT
````

## Alternate Builds
### RoboStack
Installs prebuilt packages using mamba, very interesting and inspecting it. Can be found here https://robostack.github.io/index.html
