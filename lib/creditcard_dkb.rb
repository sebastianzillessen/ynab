#!/usr/bin/env ruby
require 'rubygems'
require 'mechanize'
require 'csv'
require './lib/qif'

# This code is modified from leoc's ledgit credit card handler. 
# https://github.com/leoc/ledgit/blob/876fc22137dc640dd5116bc7caf9386fbbc41f3c/lib/handler/dkb/creditcard.rb

class CreditCardDKB
  def initialize(username, password, account)
    @agent = Mechanize.new
    @username = username
    @password = password
    @account = (account == "" ? "Kreditkarte" : account)
  end

  def connect
    @login ||= login
    @csv ||= raw_csv
  end

  # This is to make the output of this method similar to the one from aqbanking.

  def condensed_transactions
    h = Hash.new
    h[:dkb_credit] = Array.new
    hash.map do |transaction|
      h[:dkb_credit].push(transaction)
    end
    h
  end

  private

  def hash
    data = @csv
    data.encode!('UTF-8', 'ISO-8859-1')
    data.gsub!(/\A.*\n\n.*\n\n/m, '')

    CSV.parse(data, col_sep: ';', headers: :first_row).map do |row|
      memo = row['Umsatzbeschreibung']
      if foreign_currency_amount(row[5])
        memo = [foreign_currency_amount(row[5]),row['Umsatzbeschreibung']].join(". ")
      end
      {
        :date   => Date.parse(row['Belegdatum']),
        :amount => row['Betrag (EUR)'].gsub('.', '').gsub(',', '.').to_f,
        :payee  => row['Umsatzbeschreibung'],
        :memo   => memo
      }
    end.reverse
  end

  def foreign_currency_amount string
    return nil if string == ""
    amount, currency = string.split(" ")
    return "#{currency} #{sprintf '%.2f', amount.gsub(",", ".").to_f.abs}"
  end
  
  def name_for_label label_text
    @agent.page.labels.select { |l| l.text =~ /#{label_text}/ }
      .first.node.attribute('for').value
  end

  def raw_csv
    form = @agent.page.forms[2]

    posting_date = (Date.today - 180).strftime('%d.%m.%Y')
    to_posting_date = Date.today.strftime('%d.%m.%Y')

    form.field_with(name: /slCreditCard/)
      .option_with(text: /#{Regexp.escape(@account)}/).select

    form.radiobutton_with(name: /searchPeriod/, value: '0').check
    form.field_with(name: 'postingDate').value = posting_date
    form.field_with(name: 'toPostingDate').value = to_posting_date
    form.submit

    @agent.page.link_with(href: /csvExport/).click
    @agent.page.body
  end

  def login
    # log into the online banking website
    @agent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    @agent.get 'https://banking.dkb.de:443/dkb/-?$javascript=disabled'
    form = @agent.page.forms.first

    form.field_with(name: name_for_label(/Anmeldename/)).value = @username
    form.field_with(name: name_for_label(/PIN/)).value = @password

    button = form.button_with(value: /Anmelden/)

    @agent.submit(form, button)

    # go to the transaction listing for the correct account type
    @agent.page.link_with(text: /Kreditkartenumsätze/).click
    @agent.page.meta_refresh.first.click unless @agent.page.meta_refresh.empty?
  end
end