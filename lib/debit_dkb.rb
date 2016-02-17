#!/usr/bin/env ruby
require 'rubygems'
require 'mechanize'
require 'csv'
require_relative 'qif'
require_relative 'qif_export'

class DebitCardDKB < QifExport
  def self.credential_selector
    "dkb.debit"
  end
  def from_web username, password, account, attrs={}
    @csv = {}
    scraper = Scraper.new(username, password, account)
    accounts = scraper.enumerate_accounts
    accounts.each do |account|
      account_filename = "dkb_debit_" + account.gsub(/[^0-9a-zA-Z]/, "_").gsub(/_+/, "_").downcase
      @csv[account_filename.to_sym] = scraper.csv(account)
    end
  end

  private

  def sanitise
    @csv.each do |key, value|
      @csv[key] = value.split("\n").drop(6).join("\n")
      @csv[key].encode!('UTF-8', 'ISO-8859-1')
    end
  end

  def parse
    @csv.each do |key, value|
      @csv[key] = CSV.parse(value, col_sep: ';', headers: :first_row).map do |row|
        {
          :date => Date.parse(row['Buchungstag']),
          :amount => amount(row),
          :payee => row['Auftraggeber / Begünstigter'],
          :memo => memo(row)
        }
      end.reverse
    end
  end

  def amount row
    row['Betrag (EUR)'].gsub('.', '').gsub(',', '.').to_f
  end

  def memo row
    memo = row['Verwendungszweck']
    # replace 'DATUM 30.10.2015, 18.26 UHR1.TAN 123456' in memo
    memo = memo.gsub(/DATUM .*TAN \d/, "")
    #remove "2015-09-24T16:54:00 Karte0 2099-12"
    memo = memo.gsub(/\d+-\d+-\d+.+Karte.+-\d+/," ")
    # remove double spaces
    memo = memo.gsub(/\s\s+/," ")
    memo
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

      @agent.submit(form)
    end

    def enumerate_accounts
      @agent.page.link_with(text: /Kontoumsätze/).click
      @agent.page.meta_refresh.first.click unless @agent.page.meta_refresh.empty?
      form = @agent.page.forms[2]
      form.select_with(name: /slBankAccount/).options.map { |x| x.text }
    end

    def csv account
      @agent.page.link_with(text: /Kontoumsätze/).click
      @agent.page.meta_refresh.first.click unless @agent.page.meta_refresh.empty?
      form = @agent.page.forms[2]

      posting_date = (Date.today - 180).strftime('%d.%m.%Y')
      to_posting_date = Date.today.strftime('%d.%m.%Y')

      form.select_with(name: /slBankAccount/)
        .option_with(text: /#{Regexp.escape(account)}/).select

      form.radiobutton_with(name: /searchPeriodRadio/, value: '1').check
      form.field_with(name: 'transactionDate').value = posting_date
      form.field_with(name: 'toTransactionDate').value = to_posting_date
      form.submit

      @agent.page.link_with(href: /csvExport/).click
      ret = @agent.page.body
      @agent.back
      ret
    end
  end
end

Qif.print_many(DebitCardDKB.transactions!) if __FILE__ == $0