#!/usr/bin/env ruby
require 'rubygems'
require 'mechanize'
require 'csv'
require_relative 'qif'

# This code is modified from leoc's ledgit credit card handler. 
# https://github.com/leoc/ledgit/blob/876fc22137dc640dd5116bc7caf9386fbbc41f3c/lib/handler/dkb/creditcard.rb

LOCAL_CURRENCY = "EUR"

class CreditCardMM
  def self.transactions!
    cc = CreditCardMM.new
    cc.from_web
    cc.transactions
  end

  def from_web username = nil, password = nil, account = nil
    unless username
      $stderr.print "Username: "; username = gets.strip
    end
    unless password
      $stderr.print "Password: "; password = gets.strip
    end
    unless account
      $stderr.print "Account: ";  account = gets.strip
    end

    account = (account == "" ? "Kreditkarte" : account)
    scraper = Scraper.new username, password, account
    @csv = scraper.csv
  end

  def transactions
    sanitise
    {:creditcard_mm => parse}
  end

  private
  
  def sanitise
    @data = @csv.split("\n").drop(3).join("\n")
  end

  def parse
    CSV.parse(@data, col_sep: ',', headers: :first_row).map do |row|
      {
        :date   => Date.parse(row[3]),
        :amount => amount(row),
        :payee  => row[5],
        :memo   => memo(row)
      }
    end.reverse
  end
  
  def amount row
    raise "Incorrect currency" unless row[11] == LOCAL_CURRENCY
    return (row[13] == "S") ? (row[12].to_f*-1) : (row[12].to_f)
  end
  
  def memo row
    location = row[6].dup
    location.gsub!(/\s+/, ' ')
    
    foreign_currency_amount = "#{row[7]} #{sprintf '%.2f', row[8].to_f}" if row[11] != row[7]
    
    memo = row[5].dup
    memo = [location, memo].join(". ") if (location && (location != ""))
    memo = [foreign_currency_amount, memo].join(". ") if foreign_currency_amount
    return memo
  end
  
  class Scraper
    def initialize username, password, account
      @agent = Mechanize.new
      
      raise "Not implemented."
      login username, password
      return
    end
    
    private 
  end
end

Qif.print_many(CreditCardMM.transactions!) if __FILE__ == $0