#!/usr/bin/env ruby
require './lib/qif'
require './lib/aqbanking'

module HCBIParser
  extend self
  attr_accessor :hash

  def self.run!
    t = AQBanking.condensed_transactions
    t.each do |key, value|
      puts Qif.print value, 'Bank', "#{key}.qif"
    end
  end
end

HCBIParser.run! if __FILE__==$0


