#!/usr/bin/env ruby
require './lib/qif'
require './lib/aqbanking'
require './lib/creditcard_dkb'

module StatementFetch
  extend self

  def self.run!
    t = AQBanking.condensed_transactions
    
    $stderr.print "Username: "; username = gets.strip
    $stderr.print "Password: "; password = gets.strip
    $stderr.print "Account: ";  account = gets.strip

    cc = CreditCardDKB.new(username, password, account)
    cc.connect
    t.merge!(cc.condensed_transactions)

    t.each do |key, value|
      puts Qif.print value, 'Bank', "#{key}.qif"
    end
  end
end

StatementFetch.run! if __FILE__==$0
