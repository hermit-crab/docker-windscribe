#! /bin/bash

# Here is where you run the secure service you want to run.  Do not exit.  Run in foreground.
# Overwrite this file in your docker image.  It is run as docker_user and docker_group.

/usr/local/bin/tinyproxy -d -c /etc/tinyproxy.conf
