require 'net/imap'
require 'mail'

class EmailService
  def initialize(email_config)
    @email_config = email_config
  end

  def connect_to_imap
    begin
      Net::IMAP.new(@email_config['address'], @email_config['port'], @email_config['enable_ssl'])
    rescue StandardError => e
      puts "Error connecting to IMAP: #{e.message}"
      nil
    end
  end

  def login_to_email(imap)
    begin
      imap.login(@email_config['user_name'], @email_config['password'])
    rescue StandardError => e
      puts "Error logging in to email: #{e.message}"
      nil
    end
  end

  def fetch_emails(subject)
    imap = connect_to_imap
    return unless imap

    login_to_email(imap)
    imap.select('INBOX')
    unread_uids = imap.search(['UNSEEN', 'SUBJECT', subject])
    
    unread_emails = unread_uids.map do |uid|
      imap.fetch(uid, 'RFC822').first.attr['RFC822']
    end

    imap.logout
    imap.disconnect

    unread_emails
  end
end
