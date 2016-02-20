require_relative "mechanize_extension"
require 'yaml'

class QifExport

  def self.credential_selector
    ""
  end

  def initialize(attrs={})
    print "Starting #{self.class.name} import"
  end

  def transactions()
    sanitise
    parse
  end

  def self.transactions!(attrs={})
    c = credentials()
    c.push(attrs) if !attrs.empty? || c.empty?
    trans= {}
    c.flatten.each do |att|
      att=att.inject({}){|h,(k,v)| h.merge({ k.to_sym => v}) } # symbolize
      cc = self.new
      cc.from_web(*login_data(att), att)
      trans.merge! cc.transactions
    end
    puts " Done!"
    trans
  end

  def from_web(username, password, account, attrs={})
  end

  private

  def self.credentials()
    thing = YAML.load_file('credentials.yml')
    credential_selector.split(".").each do |k|
      thing = thing[k]
    end
    thing
  rescue
    []
  end

  def self.login_data(attrs)
    username = attrs.delete :username
    password = attrs.delete :password
    account = attrs.delete :account
    unless username
      $stderr.print "Username: "; username = gets.strip
    end
    unless password
      $stderr.print "Password: "; password = gets.strip
    end
    [username, password, account]
  end
end
