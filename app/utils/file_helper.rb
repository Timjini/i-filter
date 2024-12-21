module FileHelper
  def self.save_attachment(attachment, filename)
    attachments_dir = 'public'
    FileUtils.mkdir_p(attachments_dir)

    file_path = File.join(attachments_dir, filename)

    File.open(file_path, 'wb') do |file|
      file.write(attachment.decoded)
    end

    file_path
  end
end
