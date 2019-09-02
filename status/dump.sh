#!/bin/sh

ID=`cat .id`
REQUEST_TOKEN=`cat .requestToken`
RTK=`cat .rtk`
JCB=`cat .jcb`
UNDERSCORE=`cat .underscore`
URL="http://status.renren.com/GetSomeomeDoingList.do?userId=$ID&_jcb=$JCB&requestToken=$REQUEST_TOKEN&_rtk=$RTK&_=$UNDERSCORE&curpage="

for i in `seq 0 21`
do
    filename="${i}_dump.json"
    curl $URL$i -H @header | gunzip -c | sed -e 's/)$//' | sed -e 's/^jQuery[0-9]*_[0-9]*(//' > $filename
    node display.js $filename
done
