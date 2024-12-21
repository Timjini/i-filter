class AttachmentService

  def save_attachments_to_public(attachment)
    return unless attachment

    attachments_dir = 'public'
    FileUtils.mkdir_p(attachments_dir)

    filename = attachment.filename || "default_filename.pdf"
    extension = File.extname(filename).empty? ? '.pdf' : File.extname(filename)

    file_path = File.join(attachments_dir, filename)

    begin
      if attachment.respond_to?(:decoded) && attachment.decoded
        attachment_data = attachment.decoded
      else
        attachment_data = attachment
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