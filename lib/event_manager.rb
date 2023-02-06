require "csv"
require "google/apis/civicinfo_v2"
require "erb"
require "date"

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, "0")[0..4]
end

# Assignment 1 - Clean phone numbers
def clean_numbers(number)
  number.delete("^0-9")
  if number.length < 10 || (number.length >= 11 && number[0] != "1")
    "Invalid Number"
  elsif number.length == 11 && number[0] == "1"
    number[1..]
  else
    number
  end
end

# Assignment 2 - Most common registration time
def time_target
  contents = CSV.open("event_attendees.csv", headers: true, header_converters: :symbol)
  time_arr = []
  contents.each do |row|
    time = row[:regdate].split(" ")
    time_arr.push(time[1].split(":")[0])
  end
  time_tally = time_arr.tally
  max_count = time_tally.values.max
  time_tally.key(max_count)
end

# Assignment 3 - Most common registration day
def day_target
  contents = CSV.open("event_attendees.csv", headers: true, header_converters: :symbol)
  day_arr = []
  weekdays = {0 => "Sunday",
              1 => "Monday",
              2 => "Tuesday",
              3 => "Wednesday",
              4 => "Thursday",
              5 => "Friday",
              6 => "Saturday"}

  contents.each do |row|
    time = Date.strptime(row[:regdate], "%m/%d/%y %H:%M")
    day_arr.push(time.wday)
  end
  
  day_tally = day_arr.tally
  max_count = day_tally.values.max
  weekdays[day_tally.key(max_count)]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = "AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw"

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels:  "country",
      roles:   ["legislatorUpperBody", "legislatorLowerBody"]
    ).officials
  rescue
    "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir("output") unless Dir.exist?("output")

  filename = "output/thanks_#{id}.html"

  File.open(filename, "w") do |file|
    file.puts form_letter
  end
end

puts "EventManager initialized."

contents = CSV.open(
  "event_attendees.csv",
  headers:           true,
  header_converters: :symbol
)

template_letter = File.read("form_letter.erb")
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  phone_number = clean_numbers(row[:homephone])
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end

puts "Most common registration hour is #{time_target}h"
puts "Most common registration day is #{day_target}"
