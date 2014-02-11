# Ruby 1.9.2
require 'csv'
require './lib/qif'

class HCBIParser
  attr_accessor :csv
  attr_accessor :hash

  def self.run!
    hcbi = HCBIParser.new
    hcbi.connect
    puts Qif.print hcbi.hash, 'Bank'
  end

  def connect
    # To re-create the local aqbanking config files: 
    # aqhbci-tool4 adduser -s https://hbci-pintan-by.s-hbci.de/PinTanServlet -b BLZ -u KTONR -N ANYNAME -t pintan
    # aqhbci-tool4 adduserflags -f forceSsl3
    # aqhbci-tool4 getsysid
    # aqhbci-tool4 listaccounts
    # aqbanking-cli request --balance
    
    # Other common commands: 
    # aqbanking-cli request --transactions
    # aqbanking-cli request --transactions > transaktionen.ctx
    # aqbanking-cli listtrans < transaktionen.ctx
    @csv ||= `aqbanking-cli -n -P ~/.aqbanking/pin request --transactions | aqbanking-cli listtrans`
  end

  def hash
    parsed_csv.map do |row|
      payee = "Payee Unknown" if (!row[:payee] || row[:payee] == "")
      {
        :date        => Date.parse(row[:cleared_date]),
        :currency    => row[:currency],
        :amount      => row[:amount],
        :payee       => payee,
        :memo        => row_memo(row)
      }
    end
  end
    
  private
  
  def row_memo row
    memo = ""
    memo += "BLZ: #{row[:sort_code]} "      unless row[:sort_code].empty?
    memo += "KTO: #{row[:account_number]} " unless row[:account_number].empty?
    memo += "Memo: #{row[:memo]} "          unless row[:memo].empty?
  end
    
  def parsed_csv
    csv_array = CSV.parse reformatted_csv
    parsed_array = csv_array.map do |row|
      parsed_row row
    end
  end
  
  def reformatted_csv
    reformatted = []
    CSV.parse(@csv, col_sep: ";") do |rec|
      reformatted.push CSV.generate_line(rec, col_sep: ",", force_quotes: true)
    end
    reformatted.shift
    reformatted.join
  end
  
  def parsed_row row_array
    {
      :sort_code      => row_array[3].to_s.strip,
      :account_number => row_array[4].to_s.strip,
      :currency       => row_array[8].to_s.strip,
      :amount         => row_array[7].to_s.strip,
      :booking_date   => row_array[6].to_s.strip,
      :cleared_date   => row_array[5].to_s.strip,
      :payee          => row_array[10..11].join.strip,
      :memo           => row_array[12..23].join(" ").strip,
    }
  end
end

HCBIParser.run! if __FILE__==$0


