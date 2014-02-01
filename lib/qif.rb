require 'rubygems'
require 'qif'

module Qif
  class IO
    attr_accessor :string
    def close; end
    def write(data)
      @string ||= ""
      @string += data.to_s
    end
  end

  def self.print data, type = 'Bank', format = 'dd/mm/yyyy'
    qif_output = IO.new
    Writer.new(qif_output, type, format) do |qif|
      data.each do |row|
        qif << Transaction.new(
          :date   => row[:date],
          :amount => row[:amount],
          :memo   => row[:memo],
          :payee  => row[:payee]
        )
      end
    end
    qif_output.string
  end
end