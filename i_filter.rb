# frozen_string_literal: true

require_relative 'app/services/email_service'
require_relative 'app/utils/file_helper'
require 'dotenv'
Dotenv.load

# Configure your email credentials
email_config = {
  'address' => 'imap.gmail.com',
  'port' => 993,
  'enable_ssl' => true,
  'user_name' => ENV['USERNAME'],
  'password' => ENV['PASSWORD']
}

# Initialize services
email_service = EmailService.new(email_config)

# Fetch unread emails with a specific subject
emails = email_service.fetch_emails('Your Subject')
puts emails
folder = 'INBOX'
emails = email_service.fetch_unread_emails(folder)

# Process and save PDF attachments
emails.each do |email|
  Mail.new(email).attachments.each do |attachment|
    next unless attachment.content_type.start_with?('application/pdf')

    filename = attachment.filename || 'unknown.pdf'
    file_path = FileHelper.save_attachment(attachment, filename)
    puts "Saved attachment to: #{file_path}"
  end
end
