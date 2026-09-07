module UptimeParser
  module_function

  def parse(output)
    uptime = extract_uptime_segment(output)
    days = uptime[/(?:^|,\s*)(\d+)\s+days?/, 1].to_i
    hours = 0
    minutes = 0

    if uptime =~ /(\d+):(\d+)/
      hours = Regexp.last_match(1).to_i
      minutes = Regexp.last_match(2).to_i
    else
      hours = uptime[/(?:^|,\s*)(\d+)\s+(?:hrs?|hours?)/, 1].to_i
      minutes = uptime[/(?:^|,\s*)(\d+)\s+(?:mins?|minutes?)/, 1].to_i
    end

    { days: days, hours: hours, minutes: minutes }
  end

  def extract_uptime_segment(output)
    output[/\bup\s+(.+?)(?:,\s+\d+\s+users?|\s+\d+\s+users?)/, 1] || output
  end
end
