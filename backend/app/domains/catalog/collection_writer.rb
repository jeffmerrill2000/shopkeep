class CollectionWriter
  def self.create(store:, actor:, title:, handle:, ip_address: nil)
    collection = Collection.create!(store: store, title: title, handle: handle)
    EventRecorder.call(
      store: store, actor: actor, action: "collection.created", subject: collection,
      metadata: { "handle" => collection.handle }, ip_address: ip_address
    )
    collection
  end

  def self.add_product(collection:, actor:, product:, ip_address: nil)
    raise DomainError.new("not_found", "Product not found", status: :not_found) if product.store_id != collection.store_id

    membership = CollectionProduct.create!(store: collection.store, collection: collection, product: product)
    EventRecorder.call(
      store: collection.store, actor: actor, action: "collection.product_added", subject: membership,
      metadata: { "handle" => collection.handle, "product_handle" => product.handle }, ip_address: ip_address
    )
    membership
  end
end
