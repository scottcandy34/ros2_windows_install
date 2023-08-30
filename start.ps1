$env:ChocolateyInstall = "C:\dev\chocolatey"
$env:Path = "C:\dev\chocolatey\bin;" + $env:Path
$code = & cmd /c '"C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars64.bat" && set'
$environment = $code | Select-String -Pattern '(.*)=(.*)'
for($i=0; $i -lt $environment.Matches.Length; $i++) {
    $_name = $environment.Matches[$i].Groups[1].Value
    $_value = $environment.Matches[$i].Groups[2].Value
    Set-Item -Path env:$_name -Value $_value
}
