# frozen_string_literal: true

require 'spec_helper'
require 'net/imap'
require 'mail'
require_relative '../../app/services/email_service'

RSpec.describe EmailService do # rubocop:disable Metrics/BlockLength
  let(:email_config) do
    {
      'address' => 'imap.hostinger.com',
      'port' => 993,
      'enable_ssl' => true,
      'user_name' => 'info@devhl.dev',
      'password' => '150150@Hl'
    }
  end

  let(:imap_double) { instance_double(Net::IMAP) }
  subject(:service) { EmailService.new(email_config) }

  before do
    allow(Net::IMAP).to receive(:new).and_return(imap_double)
    allow(imap_double).to receive(:login)
  end

  describe '#connect_to_imap' do
    it 'connects to the IMAP server successfully' do
      expect(Net::IMAP).to receive(:new).with('imap.hostinger.com', 993, true)
      service.connect_to_imap
    end

    it 'handles connection errors gracefully' do
      allow(Net::IMAP).to receive(:new).and_raise(StandardError.new('connection failed'))
      expect { service.connect_to_imap }.to output(/Error connecting to IMAP: connection failed/).to_stdout
    end
  end

  describe '#login_to_email' do
    it 'logs in successfully' do
      expect(imap_double).to receive(:login).with('user@example.com', 'secret')
      service.login_to_email(imap_double)
    end

    it 'handles login errors gracefully' do
      allow(imap_double).to receive(:login).and_raise(StandardError.new('login failed'))
      expect { service.login_to_email(imap_double) }.to output(/Error logging in to email: login failed/).to_stdout
    end
  end

  describe '#fetch_emails' do
    it 'fetches unread emails matching the subject' do
      allow(service).to receive(:connect_to_imap).and_return(imap_double)
      allow(service).to receive(:login_to_email)
      allow(imap_double).to receive(:select)
      allow(imap_double).to receive(:search).and_return([1, 2])
      allow(imap_double).to receive(:fetch).with(1, 'RFC822').and_return([double(attr: { 'RFC822' => 'Email1' })])
      allow(imap_double).to receive(:fetch).with(2, 'RFC822').and_return([double(attr: { 'RFC822' => 'Email2' })])
      allow(imap_double).to receive(:logout)
      allow(imap_double).to receive(:disconnect)

      result = service.fetch_emails('Test Subject')
      expect(result).to eq(%w[Email1 Email2])
    end
  end

  describe '#fetch_unread_emails' do # rubocop:disable Metrics/BlockLength
    it 'returns Mail objects for unread emails' do
      raw_email = Mail.new(to: 'user@example.com', from: 'sender@example.com', subject: 'Test').to_s

      allow(imap_double).to receive(:select).with('chambers')
      allow(imap_double).to receive(:search).with(['UNSEEN']).and_return([1])
      allow(imap_double).to receive(:fetch).with(1, 'RFC822').and_return([double(attr: { 'RFC822' => raw_email })])

      service_with_imap = EmailService.allocate
      service_with_imap.instance_variable_set(:@email_config, email_config)
      service_with_imap.instance_variable_set(:@imap, imap_double)

      result = service_with_imap.fetch_unread_emails
      expect(result.first).to be_a(Mail::Message)
      expect(result.first.subject).to eq('Test')
    end

    it 'handles no unread emails' do
      allow(imap_double).to receive(:select).with('chambers')
      allow(imap_double).to receive(:search).with(['UNSEEN']).and_return([])

      service_with_imap = EmailService.allocate
      service_with_imap.instance_variable_set(:@email_config, email_config)
      service_with_imap.instance_variable_set(:@imap, imap_double)

      expect { service_with_imap.fetch_unread_emails }.to output(/No unread emails found/).to_stdout
    end

    it 'handles fetch errors gracefully' do
      allow(imap_double).to receive(:select).with('chambers').and_raise(StandardError.new('error'))

      service_with_imap = EmailService.allocate
      service_with_imap.instance_variable_set(:@email_config, email_config)
      service_with_imap.instance_variable_set(:@imap, imap_double)

      expect { service_with_imap.fetch_unread_emails }.to output(/Error fetching unread emails: error/).to_stdout
    end
  end

  describe '#set_emails_unread' do
    before do
      allow(imap_double).to receive(:select).with('INBOX')
    end

    it 'marks given email IDs as unread' do
      expect(imap_double).to receive(:store).with(1, '-FLAGS', [:Seen])
      expect(imap_double).to receive(:logout)
      expect(imap_double).to receive(:disconnect)

      service_with_imap = EmailService.allocate
      service_with_imap.instance_variable_set(:@imap, imap_double)

      expect { service_with_imap.set_emails_unread([1]) }.to output(/Email 1 marked as unread/).to_stdout
    end

    it 'handles errors per email and continues' do
      allow(imap_double).to receive(:store).with(1, '-FLAGS', [:Seen]).and_raise(StandardError.new('failed'))
      allow(imap_double).to receive(:logout)
      allow(imap_double).to receive(:disconnect)

      service_with_imap = EmailService.allocate
      service_with_imap.instance_variable_set(:@imap, imap_double)

      expect do
        service_with_imap.set_emails_unread([1])
      end.to output(/Failed to mark email 1 as unread: failed/).to_stdout
    end
  end
end
