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
    @product = Product.new(product_params)

    product_info = get_product(@product)
    reviews = get_reviews(@product)

    # respond_to do |format|
    #    if @product.save
    #     format.html { redirect_to @product, notice: 'Product was successfully created.' }
    #    format.json { render :show, status: :created, location: @product }
    #  else
    #    format.html { render :new }
    #    format.json { render json: @product.errors, status: :unprocessable_entity }
    #   end
    # end
  end

  # PATCH/PUT /products/1
  # PATCH/PUT /products/1.json
  def update
    respond_to do |format|
      if @product.update(product_params)
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

  def get_product(product)
    require 'open-uri'
    filename = 'http://www.ceneo.pl/' + product.code + '#tab=spec'
    doc = Nokogiri::HTML(open(filename))
    puts doc.css('.breadcrumb:last-of-type a span').text
    puts doc.css('.ProductSublineTags').text
    puts doc.css('.specs-group:first-of-type table tbody tr:first-of-type td ul li a').text
    puts doc.css('h1.product-name').text
  end

  def get_reviews(product)
    require 'open-uri'
    filename = 'http://www.ceneo.pl/' + product.code + '#tab=reviews'
    doc = Nokogiri::HTML(open(filename))

    reviews = doc.css('.product-review')
    reviews_content = []
    i = 0
    reviews.each { |review|
      reviews_content[i] = get_review(review)
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
          reviews_content[i] = get_review(review)
          i +=1
        }
      }
    end
    puts reviews_content
  end

  def get_review(review)

    require 'json'

    pros_array = cons_array = []
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

    [
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
    ]

  end

  def parse_product()

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
