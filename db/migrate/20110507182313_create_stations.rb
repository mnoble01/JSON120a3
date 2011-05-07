class CreateStations < ActiveRecord::Migration
  def self.up
    create_table :stations do |t|
      t.string :line
      t.string :platform_key
      t.string :platform_name
      t.string :station_name
      t.integer :platform_order
      t.boolean :startofline
      t.boolean :endofline
      t.string :branch
      t.string :direction
      t.string :stop_id
      t.string :stop_code
      t.string :stop_name
      t.string :stop_desc
      t.decimal :stop_lat, :precision => 8, :scale => 6
      t.decimal :stop_lng, :precision => 8, :scale => 6

      t.timestamps
    end
  end

  def self.down
    drop_table :stations
  end
end
