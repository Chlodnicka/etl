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
        if result['product'].save
          result['reviews'].each { |review|
            review['product_id'] = result['product'].id
            review = Review.new(review)
            review.save
          }
          format.html { redirect_to result.product, notice: 'Product was successfully updated.' }
          format.json { render :show, status: :ok, location: result.product }
        end
      end
      if is_extract?
        directory_name = "#{Rails.root}/public/tmp/#{product_params["code"]}/extract"
        if !File.exists?(directory_name)
          FileUtils.mkdir_p(directory_name)
        end
        @product.extract(product_params["code"], directory_name)
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
    else
      respond_to do |format|
        format.html { redirect_to @existing_prod, notice: 'Product already exists. Wanna check for updates?' }
        format.json { render :show, status: :created, location: @existing_prod }
      end
    end
  end

  def transform_view
    @product = Product.find(params[:product_id])
  end

  def transform

    @product = Product.find(params[:product_id])
    if @product.status == 'extracted'
      data = @product.transform_data(@product.code)
      File.open("#{Rails.root}/public/tmp/#{product_params["code"]}/#{product_params["code"]}.json", 'w') { |f| f.write(@product.produce_json(data).to_json) }

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
    if @product.status == 'transformed'
      require 'open-uri'
      xml = Nokogiri::XML(open("#{Rails.root}/public/tmp/#{product_params["code"]}/#{product_params["code"]}.xml"))
      @product.category = xml.xpath('//product//category')
      @product.model = xml.xpath('//product//model')
      @product.brand = xml.xpath('//product//brand')
      @product.notes = xml.xpath('//product//notes')
      @product.status = xml.xpath('//product//status')

      if @product.save
        reviews = xml.xpath('//product//reviews')
        reviews.each { |review|
          review_to_save = Review.new()
          review_to_save.product_id = @product.id
          review_to_save.author = review
          review_to_save.pros = @product.id
          review_to_save.cons = @product.id
          review_to_save.summary = @product.id
          review_to_save.useful = @product.id
          review_to_save.not_useful = @product.id
          review_to_save.score = @product.id
          review_to_save.time = @product.id
          review_to_save.recommendation = @product.id
          review_to_save.save
        }
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

  # PATCH/PUT /products/1
  # PATCH/PUT /products/1.json
  def update
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

  def delete_reviews

    @reviews = Review.where(:product_id => params["product_id"])
    puts params["product_id"]

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

  # Never trust parameters from the scary internet, only allow the white list through.
  def product_params
    params.require(:product).permit(:code, :brand, :model, :type, :notes)
  end
end
