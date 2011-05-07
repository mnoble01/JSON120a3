require 'csv'
Station.delete_all # start fresh with empty db
CSV.foreach "lib/mbta_data.csv" do |row|
    Station.create(:line => row[0], :platform_key => row[1], :platform_name => row[2], :station_name => row[3], :platform_order => row[4], :startofline => row[5], :endofline => row[6], :branch => row[7], :direction => row[8], :stop_id => row[9], :stop_code => row[10], :stop_name => row[11], :stop_desc => row[12], :stop_lat => row[13], :stop_lng => row[14])
end
