#!/bin/sh
# Xcode Cloud runs this script after it clones the repository.
# The Xcode project is not in the repository: XcodeGen makes it from
# project.yml. TestFlight refuses a build number twice, so the script
# first sets the build number to the Xcode Cloud build number.
set -eu

cd "$CI_PRIMARY_REPOSITORY_PATH"

if [ -n "${CI_BUILD_NUMBER:-}" ]; then
    sed -i '' "s/CURRENT_PROJECT_VERSION: .*/CURRENT_PROJECT_VERSION: \"$CI_BUILD_NUMBER\"/" project.yml
fi

brew install xcodegen
xcodegen generate
