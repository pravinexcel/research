class ImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick
  storage :file

  def thumb(size)
    begun_at = Time.now
    size.gsub!(/#/, '!')
    uploader = Class.new(self.class)
    uploader.versions.clear
    uploader.version_names = [size]
    img = uploader.new
    img.retrieve_from_store!(identifier)
    cached = File.join(CarrierWave.root, img.url)
    unless File.exist?(cached)
      img.cache!(self)
      img.send(:original_filename=, original_filename)
      size = size.split('x').map(&:to_i)
      resizer = case size
                  when /[!#]/ then :resize_to_fit
                  # add more like when />/ then ...
                  else :resize_to_fill
                end
      img.send(resizer, *size)
      img.store!
      logger.debug 'RESIZE', begun_at, img.store_path
    end
    img
  end

  def store_dir
    'uploads'
  end



  def extension_white_list
    %w[jpg jpeg gif png]
  end

  def filename
    Digest::MD5.hexdigest(original_filename) << File.extname(original_filename) if original_filename
  end

  def default_url
    '/images/no-image.png'
  end
end