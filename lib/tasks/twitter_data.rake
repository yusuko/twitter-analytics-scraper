namespace :twitter_data do
  desc "Get the data from twitter_analytics and write it to spreadsheets"
  task :output do

    require 'csv'
    require "google_drive"
    require 'mechanize'
    require 'rails'
    require 'byebug'

    id_array = ['ID']

    id_array.each do |id|

      pass, sp_url = 'PASS', "https://docs.google.com/spreadsheets/d/1mNAJZp0B0nLZ6dYuoMZuYDmIRUd_w8PiiY_NtEUFTW8/edit#gid=0" if id == 'ID'

      start_date = (Time.now.beginning_of_month.tomorrow).to_i.to_s + "000"
      end_date = (Time.now).to_i.to_s + "999"
      agent = Mechanize.new
      page = agent.get('https://twitter.com/')
      form = page.forms[1]
      form.field_with(name: "session[username_or_email]").value = id
      form.field_with(name: "session[password]").value = pass
      form.submit
      export_url = "https://analytics.twitter.com/user/" + id + "/tweets/export.json?start_time=" + start_date + "&end_time=" + end_date + "&lang=ja"
      bundle_url = "https://analytics.twitter.com/user/" + id + "/tweets/bundle?start_time=" + start_date + "&end_time=" + end_date + "&lang=ja"
      agent.post(export_url)
      file = agent.get(bundle_url)
      file.save
      analytics_file = File.read(file.filename)
      session = GoogleDrive::Session.from_config("config.json")
      sp = session.spreadsheet_by_url(sp_url)
      ws = sp.worksheet_by_title("test_volley")
      # CSVをパースし、１行目の１列目から順に埋めていく。
      i = 1
      CSV.parse(analytics_file).each do |csv|
        a = 1
        for a in 1..40 do
          ws[i,a] =csv[a-1]
        end
        i += 1
      end
      i += 1
    end
    puts 'success' if ws.save
    File.delete(file.filename)
    end
  end
end
