#!/usr/bin/env ruby
require './lib/qif'
require './lib/aqbanking'
require './lib/creditcard_dkb'
require './lib/debit_dkb'
require './lib/debit_lloyds'

module StatementFetch
  extend self

  def self.run!
    t = [CreditCardDKB, DebitCardDKB, DebitLloyds].inject({}) do |transactions, klass|
      transactions.merge! klass.transactions!
    end
    Qif.print_many t
  end
end

StatementFetch.run! if __FILE__==$0
