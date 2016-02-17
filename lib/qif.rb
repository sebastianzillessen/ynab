require 'rubygems'
require 'qif'

module Qif
  class IO
    attr_accessor :string

    def close;
    end

    def write(data)
      @string ||= ""
      @string += data.to_s
    end
  end

  def self.print_many data, type = 'Bank', format = 'dd/mm/yyyy'
    data.each do |account, statement|
      puts "statements length is: #{statement.length}"
      Qif.print statement, type, "export/#{account}.qif", format
    end

  end

  def self.print statement, type = 'Bank', qif_output = IO.new, format = 'dd/mm/yyyy'
    puts "Transaction length is: #{statement.length}"
    Writer.new(qif_output, type, format) do |qif|
      statement.each do |transaction|
        puts "analysing statement #{transaction}"
        if transaction.nil? || transaction.empty?
          puts "Skipping !"
          next
        end
        qif << Transaction.new(
          :date => transaction[:date],
          :amount => transaction[:amount],
          :memo => transaction[:memo],
          :payee => transaction[:payee]
        )
      end
    end
    puts "Respond to string #{qif_output.respond_to?(:string)}"
    return true
    #qif_output.respond_to?(:string) ? qif_output.string : true
  end
end