#!/bin/bash

set -euo pipefail

# source .buildkite/scripts/shared.sh

# This currently overrides some functions from the pure buildkite
# shared.sh file above. As we migrate, more things will be added to
# this file.
# source .expeditor/scripts/shared.sh

export HAB_AUTH_TOKEN="${ACCEPTANCE_HAB_AUTH_TOKEN}"
export HAB_BLDR_URL="${ACCEPTANCE_HAB_BLDR_URL}"

# TODO: use the shared utilities for installation:
curl https://raw.githubusercontent.com/habitat-sh/habitat/master/components/hab/install.sh | sudo bash

########################################################################

# `target_channel` should be channel we are promoting all our artifacts from
#
# e.g. `habitat-release-<build-id>`, `DEV`, `ACCEPTANCE` etc.
target_channel=${1}

# `destination_channel` should be the channel we are promoting to
#
# e.g. `DEV`, `ACCEPTANCE`, `CURRENT`, etc
destination_channel=${2}

# Verify we're setting the variable for package target
export HAB_PACKAGE_TARGET=$BUILD_PKG_TARGET

# TODO - should we clear the destination channel before promoting?

echo "--- Promoting from $target_channel to $destination_channel"

channel_pkgs_json=$(curl -s "${ACCEPTANCE_HAB_BLDR_URL}/v1/depot/channels/${HAB_ORIGIN}/${target_channel}/pkgs")

mapfile -t packages_to_promote < <(echo "${channel_pkgs_json}" | \
                         jq -r \
                         '.data | 
                         map(.origin + "/" + .name + "/" + .version + "/" + .release)
                         | .[]')

for pkg in "${packages_to_promote[@]}"; do
  echo "Do we promote $pkg?"
  found_pkg_target=$(curl -s "${ACCEPTANCE_HAB_BLDR_URL}/v1/depot/pkgs/${pkg}" | \
                    jq -r '.target')

  if [ "$found_pkg_target" = "$HAB_PACKAGE_TARGET" ]; then
    echo "--- Package target of ${pkg} is: ${found_pkg_target} - promoting to ${destination_channel}"
    # TODO: Set hab binary here correctly
    hab pkg promote --auth="${HAB_AUTH_TOKEN}" "${pkg}" "${destination_channel}" "${BUILD_PKG_TARGET}"
  else
    echo "--- Package target is: ${found_pkg_target} - NOT promoting"
  fi
done
