require 'csv'
require 'sunlight/congress'
require 'erb'
require 'date'
Sunlight::Congress.api_key = "e179a6973728c4dd3fb1204283aaccb5"

def clean_phone_number(phone_number)
  phone_number = phone_number.scan(/\d+/).join

  if (phone_number.length == 10)
    phone_number.sub(/(\d{4})(\d{3})(\d{3})/, "\\1-\\2-\\3")
  elsif (phone_number.length == 11 && phone_number[0].to_i == 1)
    phone_number[1..10].sub(/(\d{3})(\d{3})(\d{4})/, "\\1-\\2-\\3")
  else
    "bad number!"
  end
end

def check_date(regdate)
  DateTime.strptime(regdate, '%m/%d/%y %H:%M')
end

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def legislators_by_zipcode(zipcode)
  Sunlight::Congress::Legislator.by_zipcode(zipcode)
end

def save_thank_you_letters(id, form_letter)
  Dir.mkdir("output") unless Dir.exists? "output"

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts "EventManager Initialized!"

contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol

template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter

hours = []
weekdays = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  homephone = clean_phone_number(row[:homephone])
  reg_date = check_date(row[:regdate])

  hours << reg_date.hour
  weekdays << reg_date.wday

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letters(id, form_letter)
end

weekdays_frequency = weekdays.sort.group_by { |w| w }.inject({}) do |tmphashday, (k,v)|
  tmphashday[k] = v.size
  tmphashday
end

hours_frequency = hours.sort.group_by { |w| w }.inject({}) do |tmphashhour, (k,v)|
  tmphashhour[k] = v.size
  tmphashhour
end

hours_frequency.each do |k, v|
  puts "#{v} person registered at #{k}:00"
end

weekdays_frequency.each do |k, v|
  puts "#{v} person registered on #{Date::DAYNAMES[k]}"
end
