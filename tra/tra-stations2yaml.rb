#!/usr/bin/env ruby
#encoding: utf-8

require 'yaml'

def parse_station(path)
	station_map = {}

	File.open(path) do |f|
		f.each_line do |line|
			items = line.split('-')
			xml_station_id = items[0]
			station_name = items[1]

			station_map[xml_station_id] = station_name
		end
	end
	station_map
end

def output_yaml(map, outf)
	File.open(outf, 'w') do |f|
		f.write(map.to_yaml)
	end
end

def convert(path)
	yaml_path = path.chomp(File.extname(path)) + '.yaml'

	map = parse_station(path)
	output_yaml(map, yaml_path)
end

if __FILE__ == $PROGRAM_NAME
	if ARGV.size < 1
		puts "Usage: #{$PROGRAM_NAME} tra-station.txt"
		exit
	end

	convert(ARGV[0])
end
