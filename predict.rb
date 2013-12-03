require 'mechanize'

@a = Mechanize.new
@routes = Hash.new
@stops = Hash.new


html = false
agency = "mbta"

stops = [
  {
    agency: "mbta",
    route: 66,
    id: 2560
  },
  {
    agency: "mbta",
    route: "86",
    id: 1049
  },
  {
    agency: "mbta",
    route: 70,
    id: 1049
  },
  {
    agency: "mbta",
    route: "70A",
    id: 1049
  }
]


def get_stop_tag(agency, route, keywords)
  routes = @a.get("http://webservices.nextbus.com/service/publicXMLFeed?command=routeConfig&a=#{agency}&r=#{route}")
  q = routes.xml.to_s.scan(/<stop tag=(.+) title="(.+)" lat.+\/>/)
  g = q.select {|r| !(r[1] =~ /#{keywords}/).nil?}
  g.map! { |r| [r[0].gsub('"', '').to_i, r[1].to_s] }
  g.each { |r| puts "tag: #{r[0].to_s}, title: #{r[1]}" }

end

def predict(agency, stopId, route)
  @a.get("http://webservices.nextbus.com/service/publicXMLFeed?command=predictions&a=#{agency}&stopId=#{stopId}&r=#{route}")
  all_busses = @a.page.xml.to_s.scan(/minutes="(\d+)"/).map{ |r| r.first.to_i }
  unless all_busses.empty?
    first_bus = all_busses.shift
    first_bus = "Arriving" if first_bus == 0
    return {first_bus: first_bus, next_busses: all_busses, running: true}
  else
    return {running: false}
  end
end

def route_list(agency="mbta")
  @a.get("http://webservices.nextbus.com/service/publicXMLFeed?command=routeList&a=#{agency}").xml.to_s.scan(/<route tag="([\d\w]+)" title="([\w\d\/]+)"\/>/).map {|tag, title| @routes[title] = {title: title, tag: tag} }
  return @routes
end

def stops_list(route, agency="mbta")
  stops = @a.get("http://webservices.nextbus.com/service/publicXMLFeed?command=routeConfig&a=#{agency}&r=#{route}").xml.to_s
  stops = stops.scan(/<stop tag="([\w\d]+)" title="([\w\s@]+)" lat="([\d\.]+)" lon="([-+\d\.]+)" stopId="(\d+)".>/).map { |tag, title, lat, lon, stop_id| @stops[stop_id] = {tag: tag, title: title, lat: lat, lon: lon, id: stop_id} }
  return @stops
end



if ARGV[0] == "-s"
  get_stop_tag("mbta", ARGV[1], ARGV[2])
else
  puts "#{ARGV[1]}: #{predict("mbta", ARGV[0], ARGV[1])}" unless ARGV.empty?
  puts "<ul>" if html
  stops.each do |stop|
    result = predict(stop[:agency], stop[:id], stop[:route])
    if result[:running]
      info = "#{stop[:route]}: \n\tFirst bus: \t#{result[:first_bus]} minutes\n\tNext: \t\t#{result[:next_busses]}"
      if html
        puts "<li>#{info}</li>"
      else
        puts info
      end
    else
      puts "#{stop[:route]}: \n\tNo busses"
    end
  end
  puts "</ul>" if html
end
