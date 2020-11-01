#!/bin/sh

main() {

    test ! "$PLUGIN_REPO" && echo "missing 'repo' parameter" && exit 1
    test ! "$PLUGIN_TOKEN" && echo "missing 'token' parameter" && exit 1

    MODULE=$(jq -r .name package.json)
    SCOPE=$(echo "$MODULE" | cut -d / -f 1)
    VERSION=$(jq -r .version package.json)
    TOKEN="$PLUGIN_TOKEN"
    REPO=$(echo "$PLUGIN_REPO" | cut -d @ -f 1)
    BRANCH=$(echo "$PLUGIN_REPO" | cut -sd @ -f 2)

    git config --global user.email "bot@drone.io"
    git config --global user.name "dronebot"

    echo "[plugin settings]: repo:$REPO, module:$MODULE@$VERSION"

    npm config set "$SCOPE:registry" https://npm.pkg.github.com
    npm config set //npm.pkg.github.com/:_authToken "$TOKEN"

    cd "$(mktemp -d)" || exit 1

    echo "clonning $REPO..."
    git clone -q ${BRANCH:+ -b "$BRANCH"} --depth 1 --sparse "https://$TOKEN:x-oauth-basic@github.com/$REPO" . || exit 1

    echo "looking for updated $MODULE@$VERSION..."
    npm i \
	--package-lock-only \
	--prefer-offline  \
	--no-audit \
	"$MODULE@$VERSION" || exit 1

    if test "$(git diff --name-only package-lock.json)"; then
	MESSAGE="build(deps): update $MODULE@$VERSION"
	echo "$MODULE updated, pushing changes to $PLUGIN_REPO..."
	git commit -am "$MESSAGE"
	git push origin alpha
    else
	echo "$PLUGIN_REPO already depends on $MODULE@$VERSION"
    fi
}

main "$@"
