#!/usr/bin/env ruby
require 'rubygems'
require 'csv'
require_relative 'qif'

# This is an incredibly basic interface to AQBanking. All it does 
# is shell out and fetch the list of recent transactions. It requires
# that AQBanking is already set up correctly. To do this: 

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

class AQBanking
  def self.transactions!
    aq = AQBanking.new
    aq.from_web
    aq.transactions
  end  

  def from_web
    @csv = Fetcher.csv
  end

  def transactions
    @csv.each do |row|
      accounts[row[:local_account_number]].push({
        :date           => Date.parse(row[:date]),
        :amount         => row[:value_value],
        :payee          => payee(row),
        :memo           => memo(row)
      })
    end
    accounts
  end
  
  private
  
  def accounts
    @accounts ||= @csv.reduce({}){|a,v| a[v[:local_account_number]] = []; a}
  end

  def memo row
    memo = ""
    memo += [row[:value_currency], row[:value_value]].join(' ') unless row[:value_currency] == "EUR"
    memo += row[:purpose].to_s + " "                      unless row[:purpose].empty?
    unless row[:remote_bank_code].empty? && row[:remote_account_number].empty?
      memo += "(" + row[:remote_bank_code] + " / " + row[:remote_account_number] + ")"
    end
    memo.gsub("DATUM", " DATUM").gsub(/\s+/, ' ').strip
  end
  
  def payee row
    payee = row[:remote_name]
    (payee && payee != "") ? payee : "Payee Unknown"
  end
  
  module Fetcher
    extend self
    def csv
      unparsed_csv = `aqbanking-cli -n -P ~/.aqbanking/pin request --transactions | aqbanking-cli listtrans`
      unparsed_csv.encode!('UTF-8', 'ISO-8859-1')
      CSV.parse(unparsed_csv, col_sep: ';', headers: true).map do |row|
        row = row.to_a.map{|x| x[1] }
        {
          :transaction_id        => row[0].to_s.strip,
          :local_bank_code       => row[1].to_s.strip,
          :local_account_number  => row[2].to_s.strip,
          :remote_bank_code      => row[3].to_s.strip,
          :remote_account_number => row[4].to_s.strip,
          :date                  => row[5].to_s.strip, # cleared date
          :valuta_date           => row[6].to_s.strip, # booking date
          :value_value           => row[7].to_s.strip,
          :value_currency        => row[8].to_s.strip,
          :local_name            => row[9].to_s.strip,
          :remote_name           => row[10..11].join.strip,
          :purpose               => row[12..23].join(" ").strip,
          :category              => row[24..31].join(" ").strip,
        }
      end
    end
  end
end


Qif.print_many(AQBanking.transactions!) if __FILE__ == $0
