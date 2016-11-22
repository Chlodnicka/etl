json.extract! product, :id, :code, :brand, :model, :type, :notes, :created_at, :updated_at
json.url product_url(product, format: :json)