#!/bin/sh

VERSION="unknown"

DIRTY=""
git status | grep -q clean || DIRTY='.dirty'

# Special environment variable to signal that we are building a release, as this
# has condequenses for the version number.
if [ "${IS_RELEASE}" = "YES" ]; then
  TAG="$(git describe --tags --exact-match 2> /dev/null | cut -d- -f 2-)"
  if [ -n "${TAG}" ]; then
    # We're on a tag
    echo "${TAG}${DIRTY}" > .version
    printf "${TAG}${DIRTY}"
    exit 0
  fi
  echo 'This is not a tag, either tag this commit or do not set $IS_RELEASE' >&2
  exit 1
fi

#
# Generate the version number based on the branch
#
if [ ! -z "$(git rev-parse --abbrev-ref HEAD 2> /dev/null)" ]; then
  GIT_VERSION="$(git describe --tags)"
  LAST_TAG="$(echo ${GIT_VERSION} | cut -d- -f1)"
  COMMITS_SINCE_TAG="$(echo ${GIT_VERSION} | cut -d- -f2)"
  GIT_HASH="$(echo ${GIT_VERSION} | cut -d- -f3)"
  BRANCH=".$(git rev-parse --abbrev-ref HEAD | perl -p -e 's/-//g;')"
  [ "${BRANCH}" = ".master" ] && BRANCH=''

  TAG="$(git describe --tags --exact-match 2> /dev/null | cut -d- -f 2-)"
  if [ -n "${TAG}" ]; then # We're exactly on a tag
    COMMITS_SINCE_TAG="0"
    GIT_HASH="g$(git show --no-patch --format=format:%h HEAD)"
  fi

  VERSION="${LAST_TAG}+${COMMITS_SINCE_TAG}${BRANCH}.${GIT_HASH}${DIRTY}"
fi

rm -rf /tmp/sniproxy.spec
cp redhat/sniproxy-pdns.spec /tmp/sniproxy.spec

sed -i "s!@VERSION@!${VERSION}!" /tmp/sniproxy.spec

rpmbuild --define "_builddir `pwd`" --define "_sourcedir `pwd`" -bb /tmp/sniproxy.spec

cp $HOME/rpmbuild/RPMS/x86_64/sniproxy*-${VERSION}* .
