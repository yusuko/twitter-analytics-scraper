# frozen_string_literal: true

require 'csv'
require 'googleauth'
require 'google_drive'

class GoogleSheetClient
  def initialize(url)
    @url = url
    @logger = Logger.new(STDOUT)
    start_session_with_auth
  end

  def write_in_spreadsheet(csv, worksheet_name)
    worksheet = worksheet(worksheet_name)
    worksheet.delete_rows(1, worksheet.num_rows)
    begin
      CSV.parse(csv).each_slice(50).with_index do |csv, slice_index|
        csv.each.with_index do |row, index|
          head_line = slice_index * 50
          for j in 1..row.count do
            worksheet[head_line + index + 1, j] = row[j - 1]
          end
        end
        puts "success! @#{worksheet_name} at #{slice_index+1}" if worksheet.save
        sleep (5)
      end
      puts "All success! @#{worksheet_name}"
    rescue => e
      @logger.debug(e.inspect)
      raise 'Error is occurred!'
    end
  end

  private

  def start_session_with_auth
    credentials = Google::Auth::UserRefreshCredentials.new(
      client_id: ENV['GOOGLE_CLIENT_ID'],
      client_secret: ENV['GOOGLE_CLIENT_SECRET'],
      scope: [
        'https://www.googleapis.com/auth/drive',
        'https://spreadsheets.google.com/feeds/'
      ],
      refresh_token: ENV['GOOGLE_REFRESH_TOKEN']
    )
    @session = GoogleDrive::Session.from_credentials(credentials)
  end

  def worksheet(name)
    spreadsheet = @session.spreadsheet_by_url(@url)
    spreadsheet.worksheet_by_title(name)
  end
end
