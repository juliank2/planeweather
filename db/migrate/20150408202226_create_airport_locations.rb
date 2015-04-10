class CreateAirportLocations < ActiveRecord::Migration
  def change
    create_table :airport_locations, id: false do |t|
      t.string :iata_faa_code, :primary_key
      t.float :latitude
      t.float :longitude
    end
    add_index :airport_locations, :iata_faa_code
  end
end
