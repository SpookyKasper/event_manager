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
  date_of_login = row[:regdate]

  time = Time.strptime(date_of_login, '%m/%d/%Y %H:%M')
  array_of_hours << time.hour

  legislators = legislators_by_zipcode(zipcode)

  personal_letter = erb_template.result(binding)

  save_thank_you_letter(id, personal_letter)
end

keepgoing = true
hash_of_hours = array_of_hours.tally
best_times = []
while keepgoing
  peak = hash_of_hours.max_by { |hour, logs| logs }
  p peak
  best_times << peak
  hash_of_hours.delete(peak[0])
  if hash_of_hours.empty? then keepgoing =  false end
end

best_times
