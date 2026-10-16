class ProductImage < ApplicationRecord
  belongs_to :store
  belongs_to :product

  validates :storage_key, :content_type, presence: true
  validate :key_stays_inside_store

  def absolute_path
    root = self.class.storage_root
    path = root.join(storage_key).expand_path
    raise ActiveRecord::RecordNotFound unless path.to_s.start_with?("#{root.expand_path}/") && path.file?

    path
  end

  def file_bytes
    File.binread(absolute_path)
  end

  def self.storage_root
    directory = Rails.env.test? ? "tmp/product_images" : "storage/product_images"
    Rails.root.join(directory)
  end

  private
    def key_stays_inside_store
      return if storage_key.blank?
      return if storage_key.match?(/\A[0-9]+\/[a-f0-9]+\.(png|jpg|webp)\z/) && storage_key.start_with?("#{store_id}/")

      errors.add(:storage_key, "is invalid")
    end
end
