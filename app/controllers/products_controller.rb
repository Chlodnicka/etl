class ProductsController < ApplicationController
  before_action :set_product, only: [:show, :edit, :update]

  # GET /products
  # GET /products.json
  def index
    @products = Product.all
  end

  # GET /products/1
  # GET /products/1.json
  def show
    @reviews = @product.reviews
    respond_to do |format|
      format.html
      format.csv { send_data @reviews.to_csv }
    end
  end

  # GET /products/new
  def new
    @product = Product.new
  end

  # GET /products/1/edit
  def edit
  end

  # POST /products
  # POST /products.json
  def create
    existing_prod = Product.where(:code => product_params["code"]).first
    if existing_prod == nil
      @product = Product.new(product_params)
      if is_etl?
        result = @product.etl(product_params["code"])
        @product = result['product']
        if @product.save
          result['reviews'].each { |review|
            review['product_id'] = @product.id
            review = Review.new(review)
            review.save
          }
          respond_to do |format|
            format.html { render :show, id: @product.id, notice: 'Product was successfully updated.' }
            format.json { render :show, status: :ok, location: @product }
          end
        end
      end
      if is_extract?
        extract(product_params)
      end
    else
      respond_to do |format|
        format.html { redirect_to existing_prod, notice: 'Product already exists. Wanna check for updates?' }
        format.json { render :show, status: :created, location: @existing_prod }
      end
    end
  end

  def transform_view
    @product = Product.find(params[:product_id])
  end

  def transform
    require 'json'
    @product = Product.find(params[:product_id])
    if @product.status == 'extracted'
      data = @product.transform_data(@product.code)
      File.open("public/tmp/#{product_params["code"]}.json", "w") do |f|
        f.write(data.to_json)
      end
      @product.status = "transformed"
      if @product.save
        FileUtils.rm_rf("#{Rails.root}/public/tmp/#{product_params["code"]}/extract")
        respond_to do |format|
          format.html { render :load_view, id: @product.id, notice: 'Data could not have been transformed. Try again later.' }
          format.json { render :show, status: :created, location: product }
        end
      else
        format.html { render :transform_view, id: @product.id, notice: 'Data transformed successfully. Wanna continue?' }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end


  def load_view
    @product = Product.find(params[:product_id])
  end


  def load
    @product = Product.find(params[:product_id])
    file = File.read("public/tmp/#{product_params["code"]}.json")
    data = JSON.parse(file)
    puts data["product"]
    if @product.status == 'transformed'
      @product.category = data["product"]['category']
      @product.brand = data["product"]['brand']
      @product.model = data["product"]['model']
      @product.notes = data["product"]['notes']
      @product.status = 'loaded'
      if @product.save
        data['reviews'].each { |rev|
          review = Review.new(rev)
          review.product_id = @product.id
          review.save
        }
        FileUtils.rm_rf("#{Rails.root}/public/tmp/#{product_params["code"]}")
        File.delete("#{Rails.root}/public/tmp/#{product_params["code"]}.json")
        respond_to do |format|
          format.html { render :show, id: @product.id, notice: 'Data has been saved.' }
          format.json { render :show, status: :created, location: @product }
        end
      else
        respond_to do |format|
          format.html { render :load_view, id: @product.id, notice: 'Data could not have been transformed. Try again later or contact with admin.' }
          format.json { render json: @product.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # PATCH/PUT /products/1
  # PATCH/PUT /products/1.json
  def update
    if is_etl?
      product_info = @product.get_product_from_ceneo(@product.code)
      @product.check_reviews_and_update(@product)
      respond_to do |format|
        if @product.update(product_info)
          format.html { redirect_to @product, notice: 'Product was successfully updated.' }
          format.json { render :show, status: :ok, location: @product }
        else
          format.html { render :edit }
          format.json { render json: @product.errors, status: :unprocessable_entity }
        end
      end
    end
    if is_extract?
      @reviews = Review.where(:product_id => @product.id)
      i = 0
      count_reviews = @reviews.size
      @reviews.each { |review|
        review.destroy
        i +=1
      }
      if i == count_reviews
        @product.destroy
        extract(product_params)
      end
    end
  end


  def delete_reviews

    @reviews = Review.where(:product_id => params["product_id"])

    @reviews.each { |review|
      review.destroy
    }
    respond_to do |format|
      format.html { redirect_to products_url, notice: 'All reviews successfully destroyed' }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_product
    @product = Product.find(params[:id])
  end

  def is_etl?
    params[:commit] == "ETL"
  end

  def is_extract?
    params[:commit] == "Extract"
  end

  def extract(params)
    @product = Product.new(params)
    directory_name = "#{Rails.root}/public/tmp/#{params[:code]}/extract"
    if !File.exists?(directory_name)
      FileUtils.mkdir_p(directory_name)
    end
    @product.extract(params[:code], directory_name)
    @product.status = "extracted"
    if @product.save
      respond_to do |format|
        format.html { render :transform_view, id: @product.id, notice: 'Data extracted successfully. Wanna continue?' }
        format.json { render :show, status: :created, location: product }
      end
    else
      format.html { render :new }
      format.json { render json: @product.errors, status: :unprocessable_entity }
    end
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def product_params
    params.require(:product).permit(:code, :brand, :model, :type, :notes)
  end

end
