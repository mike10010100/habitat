#!/usr/bin/env powershell

#Requires -Version 5

param (
    # The name of the component to be built. Defaults to none
    [string]$Component
)

$ErrorActionPreference="stop" 

# Import shared functions
. ".buildkite\scripts\shared.ps1"

if($Component.Equals("")) {
    Write-Error "--- :error: Component to build not specified, please use the -Component flag"
}

$Env:HAB_AUTH_TOKEN=$Env:ACCEPTANCE_HAB_AUTH_TOKEN
$Env:HAB_BLDR_URL=$Env:ACCEPTANCE_HAB_BLDR_URL

# TODO: setup shared component in a more idomatic way
$Channel = "habitat-release-$Env:BUILDKITE_BUILD_ID"

Write-Host "Channel: $Channel - bldr url: $Env:HAB_BLDR_URL"

# TODO: do this better
# Get the latest version available from bintray
$current_protocols = [Net.ServicePointManager]::SecurityProtocol
$latestVersionURI = ""
$downloadUrl = ""
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $response = Invoke-WebRequest "https://bintray.com/habitat/stable/hab-x86_64-windows/_latestVersion" -UseBasicParsing -ErrorAction Stop
    $latestVersionURI = ($response).BaseResponse.ResponseUri.AbsoluteUri
}
finally {
    [Net.ServicePointManager]::SecurityProtocol = $current_protocols
}
  
$uriArray = $latestVersionURI.Split("/")
$targetVersion = $uriArray[$uriArray.Length-1]
Write-Host "--- Latest version is $targetVersion"
$downloadUrl = "https://api.bintray.com/content/habitat/stable/windows/x86_64/hab-$targetVersion-x86_64-windows.zip?bt_package=hab-x86_64-windows"
# }
$bootstrapDir = "C:\hab-latest"

# download a hab binary to build hab from source in a studio
Write-Host "--- Downloading from $downloadUrl"
$current_protocols = [Net.ServicePointManager]::SecurityProtocol
try {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  Invoke-WebRequest -UseBasicParsing -Uri "$downloadUrl" -OutFile hab.zip -ErrorAction Stop
}
finally {
  [Net.ServicePointManager]::SecurityProtocol = $current_protocols
}

Write-Host "--- Extracting to $bootstrapDir"
New-Item -ItemType directory -Path $bootstrapDir -Force -ErrorAction Stop
Expand-Archive -Path hab.zip -DestinationPath $bootstrapDir -ErrorAction Stop
Remove-Item hab.zip -Force
$baseHabExe = (Get-Item "$bootstrapDir\hab-$targetVersion-x86_64-windows\hab.exe").FullName

#### UGH WHY DID I HAVE TO DO THAT



# # TODO: make this better
Write-Host "--- :key: Downloading 'core' public keys from Builder"
Invoke-Expression "$baseHabExe origin key download core" -ErrorAction Stop
Write-Host "--- :closed_lock_with_key: Downloading latest 'core' secret key from Builder"
Invoke-Expression "$baseHabExe origin key download core --auth $Env:HAB_AUTH_TOKEN --secret" -ErrorAction Stop
$Env:HAB_CACHE_KEY_PATH = "C:\hab\cache\keys"
$Env:HAB_ORIGIN = "core"




# ##### NOW WE DO MORE THINGS WHY OH GOD WHY




















# # Write a build!
# Push-Location "C:\build"
#     Write-Host "--- Setting HAB_BLDR_CHANNEL channel to $ReleaseChannel"
#     $Env:HAB_BLDR_CHANNEL="$ReleaseChannel"
#     Write-Host "--- Running hab pkg build for $Component"
#     Invoke-Expression "$baseHabExe pkg build components\$Component --keys core"
#     . "results\last_build.ps1"

#     Write-Host "Running hab pkg upload for $Component to channel $ReleaseChannel"
#     Invoke-Expression "$baseHabExe pkg upload results\$pkg_artifact --channel=$ReleaseChannel"
#     Invoke-Expression "buildkite-agent meta-data set ${pkg_ident}-x86_64-windows true"



#     If ($Component -eq 'hab') {
#         Write-Host "--- :buildkite: Recording metadata $pkg_ident"
#         Invoke-Expression "buildkite-agent meta-data set 'hab-version-x86_64-windows' '$pkg_ident'"
#         Invoke-Expression "buildkite-agent meta-data set 'hab-release-x86_64-windows' '$pkg_release'"
#         Invoke-Expression "buildkite-agent meta-data set 'hab-artifact-x86_64-windows' '$pkg_artifact'"
#     } Elseif ($component -eq 'studio') {
#         Write-Host "--- :buildkite: Recording metadata for $pkg_ident"
#         Invoke-Expression "buildkite-agent meta-data set 'studio-version-x86_64-windows' $pkg_ident"       
#     } Else {
#         Write-Host "Not recording any metadata for $pkg_ident, none required."
#     }
#     Invoke-Expression "buildkite-agent annotate --append --context 'release-manifest' '<br>* ${pkg_ident} (x86_64-windows)'"
# Pop-Location

exit 1
# exit $LASTEXITCODE
