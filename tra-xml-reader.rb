#!/usr/bin/env ruby
#encoding: utf-8

require 'nokogiri'
require 'open-uri'

$station_map = {}

def get_station_mapping
	File.open('tra-opendata/tra-stations.txt') do |f|
		f.each_line do |line|
			items = line.split('-')
			xml_station_id = items[0]
			station_name = items[1]

			$station_map[xml_station_id] = station_name
		end
	end
end

def parse_timeinfo(t)
	sched = {}
	sched[:arrival_time] = t['ARRTime']
	sched[:depart_time] = t['DEPTime']
	sched[:station] = $station_map[t['Station']]
	sched
end

$ClassMap = {
	'1100' => '自強',
	'1101' => '自強',
	'1102' => '太魯閣',
	'1107' => '新自強',
	'1110' => '莒光',
	'1120' => '復興',
	'1130' => '電車',
	'1131' => '區間車',
	'1132' => '區間快',
	'1140' => '普快車',
	'1141' => '柴快車',
	'1150' => '柴油車',
}
$LineMap = {
	'0' => '',
	'1' => '山線',
	'2' => '海線',
}
$TypeMap = {
	'0' => '常態列車',
	'1' => '臨時',
	'2' => '團體列車',
	'3' => '春節加開車',
}

def parse_train(ti)
	train = {}
	train[:car_class] = $ClassMap[ti['CarClass']]
	train[:cripple] = ti['Cripple'] == 'Y' ? true : false
	train[:dining] = ti['Dinning'] == 'Y' ? true : false	# XML misspelled XD
	train[:line] = $LineMap[ti['Line']]
	train[:clockwise] = ti['LineDir'] == '0' ? true : false
	train[:note] = ti['Note']
	train[:over_night] = ti['OverNightStn'] == '0' ? false : true
	train[:package] = ti['Package'] == 'Y' ? true : false
	train[:train_id] = ti['Train']
	train[:type] = $TypeMap[ti['Type']]

	array = []
	ti.xpath('TimeInfo').each do |t|
		array.push(parse_timeinfo(t))
	end
	train[:schedule] = array
	puts train
end

def parse_xml(doc)
	trains = []
	doc.xpath('//TrainInfo').each do |ti|
		parse_train(ti)
		break
	end
end

if __FILE__ == $PROGRAM_NAME
	if ARGV.size == 0
		puts "Usage: #{$PROGRAM_NAME} XML"
		exit
	end

	get_station_mapping

	doc = Nokogiri::XML(File.open(ARGV[0]))
	parse_xml(doc)
end
