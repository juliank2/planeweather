task :updateAirportData => :environment do
  require 'csv'

  def deleteAllExisting
    AirportLocation.delete_all
    rescue ActiveRecord::NoDatabaseError
      $stderr.puts "Database '#{configuration['database']}' does not exist"
    rescue Exception => error
      $stderr.puts error, *(error.backtrace)
      $stderr.puts "Couldn't drop #{configuration['database']}\"'"
  end

  def importFromFileCsv path
    # airport-data is expected to be a comma delimited csv with only the fields [code, latitude, longitude] and no header
    lineNumber = 0
    CSV.foreach("#{Rails.root}/other/airport-data.csv") do |row|
      lineNumber += 1
      if row[0]
        AirportLocation.create code: row[0].downcase, latitude: row[1].to_f, longitude: row[2].to_f
      else
        puts "failed to import line number: #{lineNumber}, content: #{row}"
      end
    end
  end

  deleteAllExisting
  importFromFileCsv "#{Rails.root}/other/airport-data.csv"

end
