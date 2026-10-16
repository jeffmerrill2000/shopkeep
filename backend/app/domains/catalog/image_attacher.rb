class ImageAttacher
  ALLOWED = { "image/png" => "png", "image/jpeg" => "jpg", "image/webp" => "webp" }.freeze
  MAX_BYTES = 5.megabytes

  def self.call(product:, upload:, alt_text: nil)
    extension = ALLOWED[upload.content_type]
    raise DomainError.new("invalid_image", "Upload a PNG, JPEG, or WebP image") if extension.nil?
    raise DomainError.new("invalid_image", "Images must be 5 MB or smaller") if upload.size > MAX_BYTES

    key = "#{product.store_id}/#{SecureRandom.hex(16)}.#{extension}"
    destination = ProductImage.storage_root.join(key)
    destination.dirname.mkpath
    File.binwrite(destination, upload.read)
    ProductImage.create!(
      store: product.store,
      product: product,
      storage_key: key,
      content_type: upload.content_type,
      alt_text: alt_text
    )
  end
end
