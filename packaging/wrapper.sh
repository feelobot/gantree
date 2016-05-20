#!/bin/bash
set -e

# Figure out where this script is located.
SELFDIR="`readlink -f /usr/bin/gantree`"
SELFDIR=`dirname $SELFDIR`

# Tell Bundler where the Gemfile and gems are.
export BUNDLE_GEMFILE="$SELFDIR/lib/vendor/Gemfile"
unset BUNDLE_IGNORE_CONFIG

# Run the actual app using the bundled Ruby interpreter, with Bundler activated.
eval "$SELFDIR/lib/ruby/bin/ruby" -rbundler/setup -rreadline "$SELFDIR/app/bin/gantree $@"

