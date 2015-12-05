require_relative "mechanize_extension"

class QifExport
  def initialize(attrs={})
    puts "Starting #{self.class.name} import"
  end

  def transactions()
    sanitise
    parse
  end

  def self.transactions!(attrs={})
    cc = self.new
    cc.from_web(*login_data(attrs), attrs)
    cc.transactions
  end

  def from_web(username, password, account, attrs={})

  end

  private

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
