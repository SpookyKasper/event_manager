require 'csv'
puts 'Event Manager Initialized!'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

contents.each do |row|
  name = row[:first_name]
  zipcode = row[:zipcode]

  if zipcode.nil?
    zipcode = '00000'
  elsif zipcode.length > 5
    zipcode = zipcode[0..4]
  elsif zipcode.length < 5
    zipcode = zipcode.rjust(5, '0')
  end
  # if the zipcode is exactly five digits, assume it's ok
  # if the zipcode is more than 5 digits truncate until it's 5
  # if the zipcode is less than 5 digits add 0's until it's 5

  puts "This person #{name} lives in #{zipcode}"
end
