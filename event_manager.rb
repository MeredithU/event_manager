# Dependencies
require "csv"
require 'sunlight'

# Class Definition
class EventManager

	Sunlight::Base.api_key = "e179a6973728c4dd3fb1204283aaccb5"

	INVALID_PHONE_NUMBER = "0000000000"
	INVALID_ZIPCODE = "00000"

	def initialize(filename)
		puts "EventManager Initialized."
#		filename = "event_attendees.csv"
		@file = CSV.open(filename, {:headers => true, :header_converters => :symbol})
	end


# print first and last names from CSV file
	def print_names
		@file.each do |line|
#			puts line.inspect
			puts line[:first_name] + " " + line[:last_name]
		end
	end


# print phone numbers, looking past how it was inputted (i.e. (), ., -)
	def print_numbers

		@file.each do |line|
			number = clean_number(line[:homephone])
			puts number
		end

	end


	# Clean up the phone numbers that have junk characters
	def clean_number(original)

		original.delete!('./\- ()')
#		new_number = original.delete!('.')

			if original.length == 10
				# Do Nothing	
			elsif original.length == 11 # if length = 11 & starts with 1, delete '1'
				if original.start_with?("1")
					original = original[1..-1]
				else
					original = INVALID_PHONE_NUMBER
				end
			else
				original = INVALID_PHONE_NUMBER
			end
				
		return original
	end


	def print_zipcodes

		@file.each do |line|
			zipcode = clean_zipcode(line[:zipcode])
			puts zipcode
		end

	end


	# Clean up zipcodes that have less than 5 digits
	def clean_zipcode(original)

		if original.nil?
			return result = INVALID_ZIPCODE
		else

			while original.length < 5
				original.insert(0, "0")
			end
			
			return original
		end	
	end


	# creates a new file with the new clean phone numbers & zip codes
	def output_data(filename)

		output = CSV.open(filename, "w")
		@file.each do |line|
			# if this is the first line, output the headers
			if @file.lineno == 2
				output << line.headers
			else
				line[:homephone] = clean_number(line[:homephone])
				line[:zipcode] = clean_zipcode(line[:zipcode])
				output << line
			end
		end

	end


	# lookup the appropriate congresspeople in the CSV file
	def rep_lookup

		20.times do
			line = @file.readline
			
			legislators = Sunlight::Legislator.all_in_zipcode(clean_zipcode(line[:zipcode]))

			# extract title, first & last names and party from API
			names = legislators.collect do |leg|
				rep_title = leg.title
				first_name = leg.firstname
				first_initial = first_name[0]
				last_name = leg.lastname
				rep_party = leg.party
				rep_title + " " + first_initial + ". " + last_name + "(" + rep_party + ")"
			end

			puts "#{line[:last_name]}, #{line[:first_name]}, #{line[:zipcode]}, #{names.join(", ")}"
		end	

	end


	# Which hours of the day did most people register?
	def rank_times

		hours = Array.new(24){0}
		@file.each do |line|
			register_date = line[:regdate]
			split_date = register_date.split(" ")
			time = split_date[1].split(":")
			hour = time[0]
			hours[hour.to_i] = hours[hour.to_i] + 1
		end

		hours.each_with_index{|counter, hour| puts "#{hour}\t#{counter}"}

	end


	# What days of the week did most people register?
	def day_stats

		days = Array.new(7){0}
		@file.each do |line|
			register_date = line[:regdate] # grab registery date
			date = register_date.split(" ")
			new_date_format = Date.strptime(date[0], "%m/%d/%y") # turn the date string into a Ruby Date
			day = new_date_format.wday # pull out day of the week
			days[day.to_i] = days[day.to_i] + 1
		end

		days.each_with_index{|counter, day| puts "#{day}\t#{counter}"}

	end


	# How many attendees are from each state?
	def state_stats

		state_data = {} # new Hash

		@file.each do |line|
			state = line[:state]
			if state_data[state].nil? # Does the state's bucket exist in state_data?
				state_data[state] = 1 # If that bucket was nil then start it with this one person
			else
				state_data[state] = state_data[state] + 1 # If the bucket exists, add one
			end	
		end

		ranks = state_data.sort_by{|state, counter| -counter}.collect{|state, counter| state}
		state_data = state_data.select{|state, counter| counter}.sort_by{|state, counter| -counter}

#		state_data = state_data.select{|state, counter| counter}.sort_by{|state, counter| counter unless counter.nil?}

		state_data.each do |state, counter|
			puts "#{state}:\t#{counter}\t(#{ranks.index(state) + 1})" # Print out state tallies
		end

	end


end

# Script
#manager = EventManager.new
manager = EventManager.new("event_attendees.csv")
#manager.output_data("event_attendees_clean.csv")
#manager.rank_times
manager.state_stats





