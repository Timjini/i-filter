# frozen_string_literal: true

require 'net/imap'
require 'mail'
require 'set'
require 'byebug'

class EmailService # rubocop:disable Style/Documentation
  def initialize(email_config)
    @email_config = email_config
    @imap = Net::IMAP.new(email_config['address'], email_config['port'], true)
    @imap.login(email_config['user_name'], email_config['password'])
  end

  def connect_to_imap
    Net::IMAP.new(@email_config['address'], @email_config['port'], @email_config['enable_ssl'])
  rescue StandardError => e
    puts "Error connecting to IMAP: #{e.message}"
    nil
  end

  def login_to_email(imap)
    imap.login(@email_config['user_name'], @email_config['password'])
  rescue StandardError => e
    puts "Error logging in to email: #{e.message}"
    nil
  end

  def fetch_emails(subject) # rubocop:disable Metrics/MethodLength
    imap = connect_to_imap
    return unless imap

    login_to_email(imap)
    imap.select('INBOX')
    unread_uids = imap.search(['UNSEEN', 'SUBJECT', subject])

    puts unread_uids

    unread_emails = unread_uids.map do |uid|
      imap.fetch(uid, 'RFC822').first.attr['RFC822']
    end

    imap.logout
    imap.disconnect

    unread_emails
  end

  def fetch_unread_emails(_folder = 'INBOX') # rubocop:disable Metrics/MethodLength
    @imap.select('chambers')
    unread_emails_ids = @imap.search(['UNSEEN'])

    if unread_emails_ids.empty?
      puts 'No unread emails found.'
      return []
    end

    unread_emails_ids.map do |message_id|
      raw_email = @imap.fetch(message_id, 'RFC822')[0].attr['RFC822']
      Mail.new(raw_email)
    end
  rescue StandardError => e
    puts "Error fetching unread emails: #{e.message}"
    []
  end

  def set_emails_unread(email_ids) # rubocop:disable Naming/AccessorMethodName
    @imap.select('INBOX')
    email_ids.each do |email_id|
      @imap.store(email_id, '-FLAGS', [:Seen])
      puts "Email #{email_id} marked as unread."
    rescue StandardError => e
      puts "Failed to mark email #{email_id} as unread: #{e.message}"
    end
  ensure
    @imap.logout
    @imap.disconnect
  end
end
