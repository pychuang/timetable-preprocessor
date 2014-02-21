#!/usr/bin/env ruby
#encoding: utf-8

require 'nokogiri'
require 'open-uri'
require 'yaml'

$station_map = {}

def get_station_mapping
	$station_map = YAML.load_file(File.dirname($PROGRAM_NAME) + '/station-mapping.yaml')
end

def convert_time(t)
	m = t.match(/(\d\d):(\d\d):(\d\d)/)
	hour = m[1].to_i
	min = m[2].to_i
	sec = m[3].to_i
	DateTime.new($year, $month, $day, hour, min, 0, '+8')
end

def parse_timeinfo(t)
	sched = {}
	sched[:arrive_at] = convert_time(t['ARRTime'])
	sched[:depart_at] = convert_time(t['DEPTime'])
	sched[:station] = $station_map[t['Station']]
	if sched[:station].nil?
		puts "Station #{t['Station']} unknown"
	end

	sched
end

$ClassMap = {
	'1100' => :express,
	'1101' => :express,
	'1102' => :express,
	'1107' => :express,
	'1110' => :express,
	'1120' => :rapid,
	'1130' => :local,
	'1131' => :local,
	'1132' => :rapid,
	'1140' => :rapid,
	'1141' => :rapid,
	'1150' => :local,
}
$ClassNameMap = {
	'1100' => '自強',
	'1101' => '自強',
	'1102' => '太魯閣',
	'1107' => '普悠瑪',
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
	train = { :company => :TRA }
	train[:rank] = $ClassMap[ti['CarClass']]
	train[:name] = $ClassNameMap[ti['CarClass']]
	if train[:name].nil?
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
	train[:number] = ti['Train']
	train[:type] = $TypeMap[ti['Type']]
	if train[:type].nil?
		puts "Type #{ti['Type']} unknown"
	end

	train[:date] = Date.new($year, $month, $day)
	array = []
	ti.xpath('TimeInfo').each do |t|
		array.push(parse_timeinfo(t))
	end
	train[:schedule] = array
	train
end

def transform_train_schedule(train)
	stops = train[:schedule]
	departure_station = stops[0][:station]
	departure_time = stops[0][:depart_at]
	stops.shift

	train[:origin] = departure_station

	edges = []
	arrival_station = nil
	stops.each do |stop|
		edge = {}
		edge[:depart_from] = departure_station
		edge[:depart_at] = departure_time

		arrival_station = stop[:station]
		arrival_time = stop[:arrive_at]

		if arrival_time < departure_time
			arrival_time += 1
		end

		edge[:arrive_to] = arrival_station
		edge[:arrive_at] = arrival_time

		departure_station = stop[:station]
		departure_time = stop[:depart_at]

		if departure_time < arrival_time
			departure_time += 1
		end

		edges.push(edge)
	end

	train[:destination] = arrival_station
	train[:schedule] = edges
end

def parse_xml(inf)
	trains = []
	File.open(inf) do |f|
		Nokogiri::XML(f).xpath('//TrainInfo').each do |ti|
			train = parse_train(ti)
			transform_train_schedule(train)
			trains.push(train)
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
	yaml_path = xml_path.chomp(File.extname(xml_path)) + '.yaml'

	trains = parse_xml(xml_path)
	output_yaml(trains, yaml_path)
end

def get_filename_date(path)
	filename = File.basename(path).chomp(File.extname(path))
	m = filename.match(/(\d\d\d\d)(\d\d)(\d\d)/)
	$year = m[1].to_i
	$month = m[2].to_i
	$day = m[3].to_i

	puts "TimeTable for #{$year}/#{$month}/#{$day}"
end

if __FILE__ == $PROGRAM_NAME
	if ARGV.size < 1
		puts "Usage: #{$PROGRAM_NAME} XML..."
		exit
	end

	get_station_mapping

	ARGV.each do |xml_path|
		get_filename_date(xml_path)
		convert_xml(xml_path)
	end
end
