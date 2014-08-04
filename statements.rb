#!/usr/bin/env ruby
require './lib/qif'
require './lib/aqbanking'
require './lib/creditcard_dkb'

module StatementFetch
  extend self

  def self.run!
    t = [AQBanking, CreditCardDKB].inject({}) do |transactions, klass| 
      transactions.merge! klass.transactions!
    end
    
    Qif.print_many t
  end
end

StatementFetch.run! if __FILE__==$0
