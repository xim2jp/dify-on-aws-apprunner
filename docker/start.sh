#!/bin/bash
# Initialize plugin database in background, start supervisord immediately
/usr/local/bin/init-db.sh &
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
