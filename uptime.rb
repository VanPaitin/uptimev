require_relative "uptime_parser"

parsed = UptimeParser.parse(ARGV.join(" "))
day_label = parsed[:days] == 1 ? "day" : "days"
hour_label = parsed[:hours] == 1 ? "hour" : "hours"
minute_label = parsed[:minutes] == 1 ? "minute" : "minutes"

puts "#{parsed[:days]} #{day_label}, #{parsed[:hours]} #{hour_label} and #{parsed[:minutes]} #{minute_label}"
