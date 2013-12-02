require 'mechanize'

stops = [
  {agency: "mbta", route: 66, id: 2560},
  {agency: "mbta", route: 70, id: 1049},
  {agency: "mbta", route: "70A", id: 1049}
]

@a = Mechanize.new

def get_stop_tag(agency, route, keywords)
  routes = @a.get("http://webservices.nextbus.com/service/publicXMLFeed?command=routeConfig&a=#{agency}&r=#{route}")
  # puts routes.xml
  q = routes.xml.to_s.scan(/<stop tag=(.+) title="(.+)" lat.+\/>/)
  g = q.select {|r| !(r[1] =~ /#{keywords}/).nil?}
  # g.each { |r| puts r[0].gsub('"', '').to_i }
  g.map!{ |r| [r[0].gsub('"', '').to_i, r[1].to_s] }
  # w.each {|s| puts s}
  g.each { |r| puts "tag: #{r[0].to_s}, title: #{r[1]}" }

end

def predict(agency, stopId, route)
  @a.get("http://webservices.nextbus.com/service/publicXMLFeed?command=predictions&a=#{agency}&stopId=#{stopId}&r=#{route}")
  return @a.page.xml.to_s.scan(/minutes="(\d+)"/).map{ |r| r.first.to_i }
end

# predictions = predict("mbta", 2650)
# predictions.each { |r| puts "Arrives in #{r.first.first} minutes"}

puts "<ul>"
stops.each do |stop|
  puts "<li>#{stop[:route]}: #{predict(stop[:agency], stop[:id], stop[:route])}</li>"
end
puts "</ul>"

# get_stop_tag("mbta", "70A", "River")

