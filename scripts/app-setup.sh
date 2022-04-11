#! /bin/bash

# Here is where you set up the environment for the app.  This is run as root.

cat /opt/tinyproxy/tinyproxy.conf.tmpl \
    | sed s/USER/$TINYPROXY_USER/ | sed s/PASS/$TINYPROXY_PASS/ \
    > /etc/tinyproxy.conf
