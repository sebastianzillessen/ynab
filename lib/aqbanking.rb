require 'csv'

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

module AQBanking
  extend self
  
  def transactions
    parsed_csv
  end
  
  def condensed_transactions
    h = Hash.new
    parsed_csv.map do |transaction|
      h[transaction[:local_account_number]] ||= Array.new
      h[transaction[:local_account_number]].push({
        :date           => Date.parse(transaction[:date]),
        :amount         => transaction[:value_value],
        :payee          => transaction_payee(transaction),
        :memo           => transaction_memo(transaction)
      })
    end
    h
  end
  
  private

  def transaction_memo t
    memo = ""
    memo += "#{t[:value_currency]} #{t[:value_value]} " unless t[:value_currency] == "EUR"
    memo += "#{t[:purpose]} "                           unless t[:purpose].empty?
    memo += "BLZ: #{t[:remote_bank_code]} "             unless t[:remote_bank_code].empty?
    memo += "KTO: #{t[:remote_account_number]} "        unless t[:remote_account_number].empty?
  end
  
  def transaction_payee transaction
    payee = transaction[:remote_name]
    payee = "Payee Unknown" if (!payee || payee == "")
    payee
  end
  
  def raw_csv
    `aqbanking-cli -n -P ~/.aqbanking/pin request --transactions | aqbanking-cli listtrans`
  end

  def parsed_csv
    CSV.parse(raw_csv, col_sep: ';', headers: true).map do |row|
      next if row.header_row?
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