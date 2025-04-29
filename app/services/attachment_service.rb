# frozen_string_literal: true

class AttachmentService # rubocop:disable Style/Documentation
  def save_attachments_to_public(attachment) # rubocop:disable Metrics/MethodLength
    return unless attachment

    attachments_dir = 'public'
    FileUtils.mkdir_p(attachments_dir)

    filename = attachment.filename || 'default_filename.pdf'

    # Ensure the filename has an extension
    filename += '.pdf' if File.extname(filename).empty?

    file_path = File.join(attachments_dir, filename)

    begin
      attachment_data = if attachment.respond_to?(:decoded) && attachment.decoded
                          attachment.decoded
                        else
                          attachment
                        end

      File.open(file_path, 'wb') do |file|
        file.write(attachment_data)
      end

      file_path
    rescue StandardError => e
      puts "Error saving attachment: #{e.message}"
      nil
    end
  end
end
