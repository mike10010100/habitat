#!/bin/bash

set -euo pipefail

# source .buildkite/scripts/shared.sh

# This currently overrides some functions from the pure buildkite
# shared.sh file above. As we migrate, more things will be added to
# this file.
# source .expeditor/scripts/shared.sh

export HAB_AUTH_TOKEN="${ACCEPTANCE_HAB_AUTH_TOKEN}"
export HAB_BLDR_URL="${ACCEPTANCE_HAB_BLDR_URL}"

# This is kinda silly
curl https://raw.githubusercontent.com/habitat-sh/habitat/master/components/hab/install.sh | sudo bash

# `channel` should be channel we are pulling from
#
# e.g. `DEV`, `ACCEPTANCE` etc.
channel=${1}

hab pkg install --binlink --force --channel ${channel} core/hab

hab --version
