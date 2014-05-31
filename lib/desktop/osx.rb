require 'sqlite3'

module Desktop
  class OSX
    class DesktopImagePermissionsError < StandardError; end

    def self.desktop_image=(image)
      self.new.desktop_image = image
    end

    def self.update_desktop_image_permissions
      self.new.update_desktop_image_permissions
    end

    def desktop_image=(image)
      write_default_desktop image
      clear_custom_desktop_image
      reload_desktop
    rescue Errno::EACCES => e
      raise DesktopImagePermissionsError.new(e)
    end

    def update_desktop_image_permissions
      system "sudo chown root:staff #{desktop_image_path}"
      system "sudo chmod 664 #{desktop_image_path}"
    end

    private

    def write_default_desktop(image)
      File.open(desktop_image_path, 'w') do |desktop|
        desktop.write image.data
      end
    end

    def clear_custom_desktop_image
      db = SQLite3::Database.new(desktop_image_db_path)
      db.execute 'DELETE FROM data'
      db.execute 'VACUUM data'
      db.close
    end

    def reload_desktop
      system 'killall Dock'
    end

    def desktop_image_path
      '/System/Library/CoreServices/DefaultDesktop.jpg'
    end

    def desktop_image_db_path
      File.expand_path '~/Library/Application Support/Dock/desktoppicture.db'
    end
  end
end