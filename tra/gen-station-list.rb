#!/usr/bin/env ruby
#encoding: utf-8

require 'yaml'

def parse_station(path)
	station_list = []

	File.open(path) do |f|
		f.each_line do |line|
			station = { :company => :TRA }
			items = line.split('-')
			station[:name] = items[1]

			station_list.push(station)
		end
	end
	station_list
end

def output_yaml(list, outf)
	File.open(outf, 'w') do |f|
		f.write(list.to_yaml)
	end
end

def convert(path)
	list = parse_station(path)
	output_yaml(list, 'station-list.yaml')
end

if __FILE__ == $PROGRAM_NAME
	if ARGV.size < 1
		puts "Usage: #{$PROGRAM_NAME} station-mapping.txt"
		exit
	end

	convert(ARGV[0])
end
