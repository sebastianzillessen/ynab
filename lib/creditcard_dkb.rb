#!/usr/bin/env ruby
require 'rubygems'
require 'mechanize'
require 'csv'
require_relative 'qif'

# This code is modified from leoc's ledgit credit card handler. 
# https://github.com/leoc/ledgit/blob/876fc22137dc640dd5116bc7caf9386fbbc41f3c/lib/handler/dkb/creditcard.rb

class CreditCardDKB
  def self.transactions!
    cc = CreditCardDKB.new
    cc.from_web
    cc.transactions
  end

  def from_file filename
    @csv = { :from_file => File.open(filename).read }
  end
  
  def from_web username = nil, password = nil, account = nil
    unless username
      $stderr.print "Username: "; username = gets.strip
    end
    unless password
      $stderr.print "Password: "; password = gets.strip
    end

    scraper = Scraper.new username, password, account
    @csv = {}

    accounts = scraper.enumerate_accounts
    accounts.each do |account|
      account_filename = "dkb_credit_" + account.gsub(/[^0-9a-zA-Z]/, "_").gsub(/_+/, "_").downcase
      @csv[account_filename.to_sym] = scraper.csv(account)
    end
  end

  def transactions
    sanitise
    parse
  end

  private
  
  def sanitise
    @csv.each do |key,value|
      @csv[key] = value.split("\n").drop(7).join("\n")
      @csv[key].encode!('UTF-8', 'ISO-8859-1')
    end
  end
  
  def parse
    @csv.each do |key,value|
      @csv[key] = CSV.parse(value, col_sep: ';', headers: :first_row).map do |row|
        {
          :date   => Date.parse(row['Belegdatum']),
          :amount => amount(row),
          :payee  => row['Umsatzbeschreibung'],
          :memo   => memo(row)
        }
      end.reverse
    end
  end
  
  def amount row
    row['Betrag (EUR)'].gsub('.', '').gsub(',', '.').to_f
  end
    
  
  def memo row
    memo = row['Umsatzbeschreibung']
    
    amount, currency = row[5].split(" ")
    if amount
      amount = sprintf('%.2f', amount.gsub(",", ".").to_f.abs)
      foreign_currency_amount = [currency, amount].join(" ")
      memo = [foreign_currency_amount, memo].join(". ")
    end
    return memo
  end

  private

  class Scraper
    def initialize username, password, account
      @agent = Mechanize.new
      
      login username, password
      return
    end
    
    def login username, password
      # log into the online banking website
      @agent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      @agent.get 'https://banking.dkb.de:443/dkb/-?$javascript=disabled'
      form = @agent.page.forms.first

      form.field_with(name: 'j_username').value = username
      form.field_with(name: 'j_password').value = password

      button = form.button_with(value: /Anmelden/)

      @agent.submit(form, button)
    end
    
    def enumerate_accounts
      @agent.page.link_with(text: /Kreditkartenumsätze/).click
      @agent.page.meta_refresh.first.click unless @agent.page.meta_refresh.empty?
      form = @agent.page.forms[2]
      form.field_with(name: /slCreditCard/).options.map{|x| x.text }
    end
    
    def csv account
      @agent.page.link_with(text: /Kreditkartenumsätze/).click
      @agent.page.meta_refresh.first.click unless @agent.page.meta_refresh.empty?
      form = @agent.page.forms[2]

      posting_date = (Date.today - 180).strftime('%d.%m.%Y')
      to_posting_date = Date.today.strftime('%d.%m.%Y')

      form.field_with(name: /slCreditCard/)
        .option_with(text: /#{Regexp.escape(account)}/).select

      form.radiobutton_with(name: /searchPeriod/, value: '0').check
      form.field_with(name: 'postingDate').value = posting_date
      form.field_with(name: 'toPostingDate').value = to_posting_date
      form.submit

      @agent.page.link_with(href: /csvExport/).click
      ret = @agent.page.body
      @agent.back
      ret
    end
  end
end

Qif.print_many(CreditCardDKB.transactions!) if __FILE__ == $0