require_relative "uptime_parser"

parsed = UptimeParser.parse(ARGV.join(" "))

total_hours = parsed[:days] * 24 + parsed[:hours]
total_mins = total_hours * 60 + parsed[:minutes]
total_seconds = total_mins * 60
since_time = Time.at(Time.now - total_seconds)
puts since_time.strftime("%a, %B %d, %Y from %I:%M %P")
