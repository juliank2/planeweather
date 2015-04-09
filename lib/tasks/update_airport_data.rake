task :updateAirportData => :environment do
  require 'csv'

  def deleteAllExisting
    configuration = ActiveRecord::Base.configurations[Rails.env]
    # .delete_all does not reset the primary key which will grow with each import.
    # following some research it is apparently not easy or supported to drop/recreate tables using the rails schema definition.
    AirportLocation.delete_all
    rescue ActiveRecord::NoDatabaseError
      $stderr.puts "Database '#{configuration['database']}' does not exist"
    rescue Exception => error
      $stderr.puts error, *(error.backtrace)
      $stderr.puts "Couldn't drop #{AirportLocation.table_name}"
  end

  # the file at path is expected to be a comma delimited csv with only the fields [code, latitude, longitude] and no header.
  def importFromFileCsv path
    lineNumber = 0
    CSV.foreach(path) do |row|
      lineNumber += 1
      if row[0] and row[1] and row[2]
        AirportLocation.create code: row[0].downcase, latitude: row[1].to_f, longitude: row[2].to_f
      else
        puts "failed to import line number: #{lineNumber}, content: #{row}"
      end
    end
  end

  deleteAllExisting
  importFromFileCsv "#{Rails.root}/other/airport-data.csv"
end
