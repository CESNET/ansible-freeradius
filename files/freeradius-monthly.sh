#!/bin/bash

WEEKago=`date -d "7 days ago" +"%Y%m"`

cd /var/log/freeradius
tar --bzip2 --create --remove-files --file freeradius-$WEEKago.tar.bz2 `find -type f -name \*$WEEKago\*`
