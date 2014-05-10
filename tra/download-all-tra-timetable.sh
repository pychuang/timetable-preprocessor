for d in `curl http://163.29.3.98/xml/ | html2text | grep -P "\d{8}\.zip" | awk '{print $5}' | sed 's/\.zip//'`
do
	`dirname $0`/download-tra-timetable.sh $d
done
