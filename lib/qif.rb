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
      Qif.print statement, type, "export/#{account}.qif", format
    end

  end

  def self.print statement, type = 'Bank', qif_output = IO.new, format = 'dd/mm/yyyy'
    Writer.new(qif_output, type, format) do |qif|
      statement.each do |transaction|
        if transaction.nil? || transaction.empty?
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
    return true
  end
end