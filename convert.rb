# Ruby 1.9.2
require 'csv'
require 'qif'

def run!
  filename = ARGV[0]
  format   = ARGV[1] # giro, credit, sparda
  Encoding.default_external = 'UTF-8'
  
  file = File.read filename
  statement = StatementParser.new file, format
  puts statement.as_qif
end


class StatementParser
  def initialize plaintext, format = :giro
    @plaintext = plaintext
    @format    = format
  end
  
  def as_array
    parsed_csv.map do |row|
      payee = row[:payee]
      payee = row[:memo].shift if (@format == :sparda || @format == :credit)
      {
        :date        => row[:cleared_date],
        :currency    => row[:currency],
        :amount      => row[:amount],
        :payee       => payee,
        :memo        => row_memo(row)
      }
    end
  end
  
  def as_qif
    qif_output = Qif::IO.new
    Qif::Writer.new(qif_output, type = 'Bank', format = 'dd/mm/yyyy') do |qif|
      as_array.each do |row|
        qif << Qif::Transaction.new(
          :date         => row[:date],
          :amount       => row[:amount],
          :memo         => row[:memo],
          :payee        => row[:payee]
        )
      end
    end    
    qif_output.string
  end
  
  private
  
  def row_memo row
    memo = ""
    memo += "BLZ: #{row[:sort_code]} "      unless row[:sort_code].empty?
    memo += "KTO: #{row[:account_number]} " unless row[:account_number].empty?
    memo += "Ref: #{row[:reference]} "      unless row[:reference].empty?
    memo += "Cat: #{row[:category]} "       unless row[:category].empty?
    memo += "Comment: #{row[:comment]} "    unless row[:comment].empty?
    memo += "Memo: #{row[:memo].join(" ").gsub(/\s+/, ' ').strip} " unless row[:memo].empty?
  end
    
  def parsed_csv
    csv_array = CSV.parse reformatted_csv
    parsed_array = csv_array.map do |row|
      parsed_row row
    end
  end
  
  def reformatted_csv
    reformatted = []
    CSV.parse(@plaintext, col_sep: ";") do |rec|
      reformatted.push CSV.generate_line(rec, col_sep: ",", force_quotes: true)
    end
    reformatted.shift
    reformatted.join
  end
  
  def parsed_row row_array
    {
      :number         => row_array[0].to_s.strip,
      :booking_date   => row_array[1].to_s.strip.gsub(".", "/"),
      :cleared_date   => row_array[2].to_s.strip.gsub(".", "/"),
      :currency       => row_array[3].to_s.strip,
      :amount         => row_array[4].to_s.strip.gsub(",", "."),
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

module Qif
  class IO
    attr_accessor :string
    def close; end
    def write(data)
      @string ||= ""
      @string += data.to_s
    end
  end
end

run! if __FILE__==$0


