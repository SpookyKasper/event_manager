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

def clean_date(date)
  Time.strptime(date, '%m/%d/%Y %H:%M')
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

def sort_array_by_most_present_values(array)
  array.tally.sort {|a, b| a[1] <=> b[1] }.reverse
end

def output_top_of_list(list, num, type)
  i = 0
  best = []
  while i < num
    best << list[i][0]
    i += 1
  end
  puts "So the best #{type} are #{best}"
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
array_of_days = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone = clean_phone(row[:homephone])
  hour = clean_date(row[:regdate]).hour
  day = clean_date(row[:regdate]).strftime('%A')
  array_of_hours << hour
  array_of_days << day

  legislators = legislators_by_zipcode(zipcode)

  personal_letter = erb_template.result(binding)

  save_thank_you_letter(id, personal_letter)
end

sorted_hours = sort_array_by_most_present_values(array_of_hours)
sorted_days  = sort_array_by_most_present_values(array_of_days)
output_top_of_list(sorted_hours, 3, 'hours')
output_top_of_list(sorted_days, 3, 'days')

