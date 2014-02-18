#!/usr/bin/env ruby
#encoding: utf-8

require 'nokogiri'
require 'open-uri'
require 'yaml'

$station_map = {}

def get_station_mapping
	File.open(File.dirname($PROGRAM_NAME) + '/tra-stations.txt') do |f|
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
	if sched[:station].nil?
		puts "Station #{t['Station']} unknown"
	end

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
	if train[:car_class].nil?
		puts "CarClass #{ti['CarClass']} unknown"
	end

	train[:cripple] = ti['Cripple'] == 'Y' ? true : false
	train[:dining] = ti['Dinning'] == 'Y' ? true : false	# XML misspelled XD
	train[:line] = $LineMap[ti['Line']]
	if train[:line].nil?
		puts "Line #{ti['Line']} unknown"
	end

	train[:clockwise] = ti['LineDir'] == '0' ? true : false
	train[:note] = ti['Note']
	train[:over_night] = ti['OverNightStn'] == '0' ? false : true
	train[:package] = ti['Package'] == 'Y' ? true : false
	train[:train_id] = ti['Train']
	train[:type] = $TypeMap[ti['Type']]
	if train[:type].nil?
		puts "Type #{ti['Type']} unknown"
	end

	array = []
	ti.xpath('TimeInfo').each do |t|
		array.push(parse_timeinfo(t))
	end
	train[:schedule] = array
	train
end

def parse_xml(inf)
	trains = []
	File.open(inf) do |f|
		Nokogiri::XML(f).xpath('//TrainInfo').each do |ti|
			trains.push(parse_train(ti))
		end
	end
	trains
end

def output_yaml(trains, outf)
	File.open(outf, 'w') do |f|
		f.write(trains.to_yaml)
	end
end

def convert_xml(xml_path)
	dirname = File.dirname(xml_path)
	basename = File.basename(xml_path, File.extname(xml_path))
	yaml_path = dirname + '/' + basename + '.yaml'

	trains = parse_xml(xml_path)
	output_yaml(trains, yaml_path)
end

if __FILE__ == $PROGRAM_NAME
	if ARGV.size < 1
		puts "Usage: #{$PROGRAM_NAME} XMLs"
		exit
	end

	get_station_mapping

	ARGV.each do |xml_path|
		convert_xml(xml_path)
	end
end
