class StockAuditsController < ApplicationController
  around_filter :shopify_session
  protect_from_forgery
  layout "application"
  
  @@shopify_product_limit = 250.0
  
  def index
    @audits = StockAudit.find :all, :conditions => ["shopify_store_id = ? AND deleted = ?", current_shop.shop.id, false]

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @audits }
    end
  end
  
  def new
    # Set up the needed variables
    @audit = StockAudit.new
    fulfillments = []
    @products = {}
    
    # Gather the data from Shopify
    # Products are limited, deal with it.
    product_count = ShopifyAPI::Product.count
    page_count = (product_count / @@shopify_product_limit).ceil
    products = []
    page_count.times do |page|
      # Not only can I not get *all* products with find(:all) but their page indexing starts at 1 instead of 0 :-(
      products += ShopifyAPI::Product.find(:all, :params => {:limit => @@shopify_product_limit, :page => page + 1}, :sort => :title)
    end
    
    orders = ShopifyAPI::Order.find(:all, :params => { :status => "open", :fulfillment_status => "unshipped OR partial"})
    orders.each do |order|
      ShopifyAPI::Fulfillment.find(:all, :params => { :order_id => order.id } ).each do |f|
        unless f.nil?
          fulfillments << f
        end
      end
    end

    # Build all the StockAuditItems with data and insert them into @audit
    products.each do |product|
      product.variants.each do |variant|
        item = StockAuditItem.new
        item.vendor = product.vendor
        item.product_id = product.id
        item.variant_id = variant.id
        item.title = variant.title
        item.product_title = product.title
        item.sku = variant.sku ? variant.sku : "none"
        item.shopify_count = variant.inventory_quantity
        item.pending_count = orders.map{ |order| order.line_items.select{ |i| i.variant_id == item.variant_id }.map{|i| i.quantity }}.flatten.inject(0) {|sum,element| sum + element }
        item.pending_count -= fulfillments.map { |fulfillment| fulfillment.line_items.select { |i| i.variant_id == item.variant_id }.map { |i| i.quantity }}.flatten.inject(0) { |sum, element| sum + element }
        item.expected_count = item.shopify_count + item.pending_count
        @audit.stock_audit_items << item
      end
    end

    @vendors = @audit.stock_audit_items.map{ |item| item.vendor}.uniq.sort{ |a,b| a.casecmp(b)}
    @vendors.each do |vendor|
      @products[vendor] = @audit.stock_audit_items.select{ |item| item.vendor == vendor }.map{ |item| [item.product_title, item.product_id] }.uniq.sort{ |a, b| a[0].casecmp(b[0]) }
    end
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @audit }
    end
  end
  
  def create
    @audit = StockAudit.new(params[:stock_audit])

    respond_to do |format|
      if @audit.save
        flash[:notice] = 'Audit was successfully created.'
        format.html { redirect_to @audit }
        format.xml  { render :xml => @audit, :status => :created, :location => @audit }
      else
        @products = {}
        @vendors = @audit.stock_audit_items.map{ |item| item.vendor}.uniq.sort{ |a,b| a.casecmp(b)}
        @vendors.each do |vendor|
          @products[vendor] = @audit.stock_audit_items.select{ |item| item.vendor == vendor }.map{ |item| [item.product_title, item.product_id] }.uniq.sort{ |a, b| a[0].casecmp(b[0]) }
        end

        format.html { render :action => "new" }
        format.xml  { render :xml => @audit.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def show
    @audit = StockAudit.find(params[:id], :conditions => ["shopify_store_id = ?", current_shop.shop.id], :include => :stock_audit_items)
    @products = {}
    @vendors = @audit.stock_audit_items.map{ |item| item.vendor}.uniq.sort{ |a,b| a.casecmp(b)}
    @vendors.each do |vendor|
      @products[vendor] = @audit.stock_audit_items.select{ |item| item.vendor == vendor }.map{ |item| [item.product_title, item.product_id] }.uniq.sort{ |a, b| a[0].casecmp(b[0]) }
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @audit }
    end
  end

  # Disable editing of stock audits
  #def edit
  #  @audit = StockAudit.find(params[:id], :conditions => ["shopify_store_id = ?", current_shop.shop.id], :include => :stock_audit_items )
  #end
  
  #def update
  #  @audit = StockAudit.find(params[:id], :conditions => ["shopify_store_id = ?", current_shop.shop.id])

  #  respond_to do |format|
  #    if @audit.update_attributes(params[:audit])
  #      flash[:notice] = 'StockAudit was successfully updated.'
  #      format.html { redirect_to(@audit) }
  #      format.xml  { head :ok }
  #    else
  #      format.html { render :action => "edit" }
  #      format.xml  { render :xml => @audit.errors, :status => :unprocessable_entity }
  #    end
  #  end
  #end

  def destroy
    @audit = StockAudit.find(params[:id], :conditions => ["shopify_store_id = ?", current_shop.shop.id])
    # Don't destroy the object. Set it to deleted.
    #@audit.destroy
    @audit.deleted = true
    @audit.save

    respond_to do |format|
      format.html { redirect_to :action => "index" }
      format.xml  { head :ok }
    end
  end
end
