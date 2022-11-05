require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone(phone)
  phone = phone.tr('^0-9', '')
  return 'invalid phone number' unless phone.length == 10 || phone.length == 11 && phone[0] == '1'

  phone[-10..]
end

def clean_hour(date)
  Time.strptime(date, '%m/%d/%Y %H:%M').hour
end


def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError
    'no legislator found'
  end
end

def save_thank_you_letter(id, personal_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  file_name = "output/thank_you_bro_#{id}.html"

  File.open(file_name, 'w') do |file|
    file.puts personal_letter
  end
end

def order_by_most_people_registering(times)
  times.tally.sort {|a, b| a[1] <=> b[1] }.reverse
end

def print_results_to_human(results_array)
  results_array.each do |v|
    puts "So #{v[1]} people registered at #{v[0]}h"
  end
end

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

puts 'EventMaganerInitialized'

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
array_of_hours = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone = clean_phone(row[:homephone])
  hour = clean_hour(row[:regdate])
  array_of_hours << hour

  legislators = legislators_by_zipcode(zipcode)

  personal_letter = erb_template.result(binding)

  save_thank_you_letter(id, personal_letter)
end

results = order_by_most_people_registering(array_of_hours)
print_results_to_human(results)
puts "So the best times are #{results[0][0]}h and #{results[1][0]}h"

