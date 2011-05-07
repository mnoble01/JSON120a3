class Station < ActiveRecord::Base
	#geokit
	acts_as_mappable :default_units => :miles,
						 :lat_column_name => 'stop_lat',
						 :lng_column_name => 'stop_lng'
end
