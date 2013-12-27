# Ruby 1.9.2
require 'csv'
require 'qif'

module StatementParser
  extend self
  
  def dkb_giro plaintext
    parsed_csv(plaintext).map do |row|
      {
        :date        => row[:cleared_date],
        :currency    => row[:currency],
        :amount      => row[:amount],
        :payee       => row[:memo].shift,
        :memo        => row_memo(row)
      }
    end
  end
  
  def row_memo row
    memo = ""
    memo += "BLZ: #{row[:sort_code]} "      unless row[:sort_code].empty?
    memo += "KTO: #{row[:account_number]} " unless row[:account_number].empty?
    memo += "Ref: #{row[:reference]} "      unless row[:reference].empty?
    memo += "Cat: #{row[:category]} "       unless row[:category].empty?
    memo += "Comment: #{row[:comment]} "    unless row[:comment].empty?
    memo += "Memo: #{row[:memo].join(" ").gsub(/\s+/, ' ').strip} " unless row[:memo].empty?
  end
    
  def parsed_csv plaintext
    csv_array = CSV.parse(reformatted_csv(plaintext))
    parsed_array = csv_array.map do |row|
      parsed_row row
    end
  end
  
  def reformatted_csv plaintext
    reformatted = []
    CSV.parse(plaintext, col_sep: ";") do |rec|
      reformatted.push CSV.generate_line(rec, col_sep: ",", force_quotes: true)
    end
    reformatted.join
  end
  
  def parsed_row row_array
    {
      :number         => row_array[0].to_s.strip,
      :booking_date   => row_array[1].to_s.strip.gsub(".", "/"),
      :cleared_date   => row_array[2].to_s.strip.gsub(".", "/"),
      :currency       => row_array[3].to_s.strip,
      :amount         => row_array[4].to_s.strip,
      :payee          => row_array[5].to_s.strip,
      :sort_code      => row_array[6].to_s.strip,
      :account_number => row_array[7].to_s.strip,
      :reference      => row_array[8].to_s.strip,
      :text_key       => row_array[9].to_s.strip,
      :category       => row_array[10].to_s.strip,
      :comment        => row_array[11].to_s.strip,
      :memo           => row_array[12..25].map{ |x| x.to_s.strip.gsub(/\s+/, ' ')}
    }
  end
end

Qif::Writer.open("#{file}.qif", type = 'Bank', format = 'dd/mm/yyyy') do |qif|
  bank_input.each do |row|
    payee = row[5]
    date = row[2].gsub(".","/")
    memo = row[9 .. 25].join(" ").to_s.strip.gsub("  "," ")
    # Fix the values depending on what state your CSV data is in
    row.each { |value| value.to_s.gsub!(/^\s+|\s+$/,'') }
    qif << Qif::Transaction.new(
      :date         => date,
      :amount       => row[4],
      :memo         => memo,
      :payee        => payee
    )
  end
end