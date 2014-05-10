#!/bin/sh

TODAY=`date +%Y%m%d`
DATE=${1-$TODAY}

if [ -f $DATE.xml ]
then
	echo $DATE.xml already existed
else
	echo download timetable of $DATE
	wget http://163.29.3.98/xml/$DATE.zip
	unzip $DATE.zip
	rm $DATE.zip
	echo convert $DATE.xml to $DATE.yaml
	`dirname $0`/tra-xml2yaml.rb $DATE.xml
fi
