#!/bin/bash

# Set the source database connection info in a secrets file where it can be
# read by settings.migrate-on-pantheon.php
export D7_MYSQL_URL=$(terminus site connection-info --site=$PANTHEON_D7_SITE --env=$PANTHEON_D7_BRANCH --field=mysql_url)
terminus secrets set migrate_source_db__url $D7_MYSQL_URL

export PANTHEON_D7_URL="http://$PANTHEON_D7_BRANCH-$PANTHEON_D7_SITE.pantheonsite.io"

# Run a cache clear to take time. Otherwise immediately enabling modules
# after a code push might not work.
terminus site clear-cache
terminus drush "en -y migrate_plus migrate_tools migrate_upgrade"
terminus site set-connection-mode --mode=sftp
terminus drush "config-export -y"

# Make sure the source site is available.
terminus site wake --site=$PANTHEON_D7_SITE --env=$PANTHEON_D7_BRANCH

terminus drush "migrate-upgrade --legacy-db-key=drupal_7 --configure-only  --legacy-root=$PANTHEON_D7_URL"
# These cache rebuilds might not be necessary but I have seen odd errors
# related to migration registration go away after cache-rebuild.
terminus drush "cache-rebuild"
terminus drush  "config-export -y"
terminus drush "cache-rebuild"

#terminus site code diffstat
# @todo commit the code change. But there seems to be a multidev bug preventing
# Terminus from seeing the code change. Terminus will only report a code change
# in terminus site code diffstat after the dashboard is refreshed.
