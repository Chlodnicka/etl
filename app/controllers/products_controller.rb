class ProductsController < ApplicationController
  before_action :set_product, only: [:show, :edit, :update, :destroy]

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
    @existing_prod = Product.where(:code => product_params["code"]).first
    if @existing_prod == nil
      @product = Product.new(product_params)
      product_info = get_product(@product)

      @proper_product = Product.new(product_info)

      reviews = get_reviews(@product)

      respond_to do |format|
        if @proper_product.save
          reviews.each { |review|
            review['product_id'] = @proper_product.id
            @review = Review.new(review)
            @review.save
          }
          format.html { redirect_to @product, notice: 'Product was successfully created.' }
          format.json { render :show, status: :created, location: @product }
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


  # PATCH/PUT /products/1
  # PATCH/PUT /products/1.json
  def update
    product_info = get_product(@product)
    check_reviews_and_update(@product)
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

  # DELETE /products/1
  # DELETE /products/1.json
  def destroy
    @product.destroy
    respond_to do |format|
      format.html { redirect_to products_url, notice: 'Product was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def delete_reviews
    @reviews = Review.where(:product_id => params["product_id"])
    puts params["product_id"]

    @reviews.each{ |review|
      review.destroy
    }
    respond_to do |format|
      format.html { redirect_to products_url, notice: 'All reviews successfully destroyed' }
      format.json { head :no_content }
    end
  end

  def get_product(product)
    require 'open-uri'
    filename = 'http://www.ceneo.pl/' + product.code + '#tab=spec'
    doc = Nokogiri::HTML(open(filename))
    product = {
        "category" => doc.css('.breadcrumb:last-of-type a span').text,
        "notes" => doc.css('.ProductSublineTags').text,
        "brand" => doc.css('.specs-group:first-of-type table tbody tr:first-of-type td ul li a').text,
        "model" => doc.css('h1.product-name').text,
        "code" => product.code
    }
  end

  def get_reviews(product)
    require 'open-uri'
    filename = 'http://www.ceneo.pl/' + product.code + '#tab=reviews'
    doc = Nokogiri::HTML(open(filename))

    reviews = doc.css('.product-review')
    reviews_content = []
    i = 0
    reviews.each { |review|
      reviews_content[i] = parse_review(review)
      i +=1
    }

    pagination = doc.css('.pagination ul li a')
    pag_count = pagination.size
    if pag_count > 1
      pagination.each { |site|
        filename = 'http://www.ceneo.pl/' + site['href']
        doc = Nokogiri::HTML(open(filename))
        reviews = doc.css('.product-review')
        reviews.each { |review|
          reviews_content[i] = parse_review(review)
          i +=1
        }
      }
    end
    reviews_content
  end

  def parse_review(review)

    require 'json'

    pros_array = []
    cons_array = []
    i = j = 0

    pros = review.css('.pros-cell ul li')
    pros.each { |value|
      pros_array[i] = value.text
      i +=1
    }

    cons = review.css('.cons-cell ul li')
    cons.each { |value|
      cons_array[j] = value.text
      j +=1
    }

    date = review.css('.review-time time')

    score = review.css('.review-score-count').text

    code = review.css('.vote-yes')

    review_info = {
        'author' => review.css('.product-reviewer').text,
        'pros' => pros_array.to_json,
        'cons' => cons_array.to_json,
        'summary' => review.css('.product-review-body').text,
        'score' => score[0...1],
        'time' => date[0]['datetime'],
        'recommendation' => review.css('.product-recommended').text,
        'useful' => review.css('.vote-yes span').text,
        'not_useful' => review.css('.vote-no span').text,
        'code' => code[0]['data-review-id']
    }

  end

  def check_reviews_and_update(product)
    new_reviews = get_reviews(product)
    new_reviews.each { |new_review|
      old_review = Review.find_by_code(new_review['code'])
      if old_review == nil
        new_review['product_id'] = product.id
        review = Review.new(new_review)
        review.save
      else
        old_review.update(new_review)
      end
    }
  end


  private
  # Use callbacks to share common setup or constraints between actions.
  def set_product
    @product = Product.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def product_params
    params.require(:product).permit(:code, :brand, :model, :type, :notes)
  end
end
