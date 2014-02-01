require 'rubygems'
require 'mechanize'
require 'csv'
require 'lib/qif'

# This code is modified from leoc's ledgit credit card handler. 
# https://github.com/leoc/ledgit/blob/876fc22137dc640dd5116bc7caf9386fbbc41f3c/lib/handler/dkb/creditcard.rb

class CreditStatement
  def self.run!
    $stderr.print "Username: "; username = gets.strip
    $stderr.print "Password: "; password = gets.strip
    $stderr.print "Account: ";  account = gets.strip

    cc = CreditStatement.new(username, password, account)
    puts Qif.print cc.statement, 'CCard'
  end
  
  def initialize(username, password, account)
    @agent = Mechanize.new
    @username = username
    @password = password
    @account = account
  end
  
  def statement
    @login ||= login
    @statement ||= parse(download_data)
  end
  
  private
  
  def parse data
    data.encode!('UTF-8', 'ISO-8859-1')
    data.gsub!(/\A.*\n\n.*\n\n/m, '')

    result = CSV.parse(data, col_sep: ';', headers: :first_row)
    result.map do |row|
      {
        :date   => Date.parse(row['Belegdatum']),
        :amount => row['Betrag (EUR)'].gsub('.', '').gsub(',', '.').to_f,
        :payee  => row['Umsatzbeschreibung'],
        :memo   => row[5]
      }
    end.reverse
  end

  
  def name_for_label label_text
    @agent.page.labels.select { |l| l.text =~ /#{label_text}/ }
      .first.node.attribute('for').value
  end

  def download_data
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

CreditStatement.run! if __FILE__==$0