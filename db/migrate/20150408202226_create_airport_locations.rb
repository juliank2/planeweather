class CreateAirportLocations < ActiveRecord::Migration
  def change
    create_table :airport_locations do |t|
      t.string :code
      t.float :latitude
      t.float :longitude
      t.timestamps null: false
    end
  end
end
