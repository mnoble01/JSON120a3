include Geokit
require 'json'
require 'net/http'

class MapperController < ApplicationController

respond_to :json, :except => :index
respond_to :html, :only => :index

# API that returns all information on an MBTA station in JSON format, provided a stop_id
  def station
	respond_with(@station = Station.find_all_by_stop_id(params[:stop_id]))
  end


# API that returns information on the CLOSEST MBTA subway stations within 10 miles in JSON format, provided latitude and longitude
  def find_closest_stations
	userLoc = [params[:lat], params[:lng]]
	bounds = Geokit::Bounds.from_point_and_radius(userLoc, 10) 
	@stations = Station.in_bounds(bounds).all # get all stations within 10 miles	
	@stations.each do |s| # calc distance
		s['distance'] = s.distance_from(userLoc, :units => :miles)
	end
	puts "num stations found: " + @stations.size.to_s
	render :json => @stations.to_json
	#render :json => Station.find_all_by_stop_lat_and_stop_lng(params[:lat], params[:lng]).to_json #works
	#repond_with was not working, not sure why
  end


# API that returns schedule of recently departed and predicted arrival times of trains for a subway station in JSON format, provided stop_id
  def station_schedule
		info_array = Station.find_all_by_stop_id(params[:stop_id])
			info1 = info_array[0] # for first station
			pkey_base = info1.platform_key.chop
			pkey_base = pkey_base[1,3] # middle chars of platform key (i.e. ignore North, South, Line Color ==> mostly b/c of stations on intersecting lines
		json1 = getjson(info1.line, pkey_base, info1)

		# get more json if station is at LINE intersect
		info2 = intersect_station?(info_array) # returns db entry of second line if station is intersection
		if (!info2.blank?) 
			puts "not blank: "
			puts info2.line
			json2 = getjson(info2.line, pkey_base, info2)
			@json = json1 +  json2
		else
			@json = json1
		end
		respond_with(@json)
  end


# renders view of all the MBTA Red, Blue, Orange Line stations on a Google Map
# All MBTA stations shall share a distinct icon marker
# Clicking on a station marker shall generate a schedule of upcoming trains heading northbound and southbound (in infowindow OR in <div> on page)
# If a station is on MORE than 1 line, north and southbound schedules for EACH line must be displayed
# Must be a marker with a unique icon that denotes your location whose infowindow contains the closest MBTA subway station, + approximate miles away
  def index
	# fill data array to add data to map
	stations = Station.find(:all)
=begin
	#user markers
	#polylines
    	@map = initialize_map()
    	@map.zoom = :bound
    	@icon = Cartographer::Gicon.new()
    	# create icons & 
	@map.icons << @icon
	# create & add station markers
	@markers = Array.new
	stations.each do |s|
		m = Cartographer::Gmarker.new(:name => s.station_name,
						:position => [s.stop_lat, s.stop_lng],
              					:icon => @icon) 
		@markers.push(m)
	end

	#@map.marker_group_global_init(Cartographer::MarkerGroup(markers, true), "yes")
#@map.markers << @1
	#@map.markers << @markers
	#@markers.each do |m|
	#	@map.markers << m
	#send
	# draw polylines    
    marker1 = Cartographer::Gmarker.new(:name=> "org11", :marker_type => "Organization",
              :position => [27.173006,78.042086],
              :info_window_url => "/welcome/sample_ajax",
              :icon => @icon) 
    marker2 = Cartographer::Gmarker.new(:name=> "org12", :marker_type => "Organization",
              :position => [28.614309,77.201353],
              :info_window_url => "/welcome/sample_ajax",
              :icon => @icon)    
    @map.markers << marker1
    @map.markers << marker2
=end
    
  end

  #def sample_ajax
    #render :text => "Success"
  #end
=begin
  private
  def initialize_map
    @map = Cartographer::Gmap.new( 'map' )    
    @map.controls << :type
    @map.controls << :large
    @map.controls << :scale
    @map.controls << :overview
    @map.debug = false 
    @map.marker_mgr = true
     
     return @map
   end
=end

  def intersect_station?(info_array)
    info_array.each do |s|     
     	if info_array[0].line != s.line
	   return s
        end
     end  
     return nil
  end

  def getjson(line_name, pkey_base, info)
	feed_url = "http://developer.mbta.com/Data/" + line_name + ".json"
	response = Net::HTTP.get_response(URI.parse(feed_url))
	data = response.body

	json = JSON.parse(data) # json1 is an Array of Hashes!!!
	json = json.delete_if { |x|    x['PlatformKey'][1,4] != pkey_base + "N" &&
						          x['PlatformKey'][1,4] != pkey_base + "S"  &&
							    x['PlatformKey'][1,4] != pkey_base + "E" &&
							    x['PlatformKey'][1,4] != pkey_base + "W" } # b/c see note below about j['platform_order']

	json.each do |j| # format json to match assign. specifications
		j['time_remaining'] = j.delete("TimeRemaining")
		j['trip'] = j.delete("Trip")
		j['time'] = j.delete("Time")
		j['platform_key'] = j.delete("PlatformKey")
		j['information_type'] = j.delete("InformationType")
		j['line'] = j.delete("Line")
		j['route'] = j.delete("Route")
		j.delete("Revenue") # don't include "Revenue" key b/c not in assign. specs example output
		#now add required info from database
		j['stop_lat'] = info.stop_lat
		j['stop_lng'] = info.stop_lng
		j['platform_order'] =  info.platform_order # not entirely reliable. NB and SB give different platform orders, which is indeterminable from just a STOP_ID
		j['stop_id'] = info.stop_id
		j['stop_name'] = info.stop_name
	end
	return json
  end

end
