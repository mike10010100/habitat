#!/usr/bin/env powershell

#Requires -Version 5

param (
    # The name of the component to be built. Defaults to none
    [string]$Component
)

$ErrorActionPreference="stop" 

if($Component.Equals("")) {
  Write-Error "--- :error: Component to build not specified, please use the -Component flag"
}

$destination_channel = $Env:BUILDKITE_BUILD_ID

$Env:HAB_LICENSE = "accept-no-persist"
$Env:HAB_STUDIO_SECRET_HAB_LICENSE = "accept-no-persist"
$Env:HAB_BLDR_URL = "https://bldr.acceptance.habitat.sh"

choco install habitat -y

hab pkg install "core/hab"

$hab_bin_path = & hab pkg path core/hab
$hab_binary="$hab_bin_path/bin/hab"
$hab_binary_version = & $hab_binary --version

Write-Host "--- Using habitat version $hab_binary_version"

Write-Host "--- Running a build $Env:HAB_ORIGIN / $Component / $destination_channel"
& $hab_binary origin key download $Env:HAB_ORIGIN
& $hab_binary origin key download --auth $Env:SCOTTHAIN_HAB_AUTH_TOKEN --secret $Env:HAB_ORIGIN


# Write-Host "--- Using $hab_binary_version"
# & $hab_binary pkg build "components/$Component"
# # components/studio/bin/hab-studio.sh build "components/${component}"
# . results/last_build.env

# # Always upload to the destination channel.
# & $hab_binary pkg upload --auth $SCOTTHAIN_HAB_AUTH_TOKEN --channel $destination_channel "results/$pkg_artifact"

exit $LASTEXITCODE
