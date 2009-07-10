class WarehouseController < ApplicationController
  around_filter :shopify_session
  protect_from_forgery :except => :vendor_products
  
  def enter_shipment
    if(request.post?)
      product_variant_ids = params['product_variant_ids']
      @shipment = Shipment.new()
      @shipment.shipment_items.build()
      @variants = Hash.new()
      product_variant_ids.each do |pvid|
        pid, vid = pvid.split("|")
        product = ShopifyAPI::Product.find(pid)
        variant = ShopifyAPI::Variant.find(vid, :params => { :product_id => pid })
        title = variant.title =~ /Default/ ? product.title : variant.title
        @variants[vid.to_i] = variant unless variant.blank? 
        @shipment.shipment_items << ShipmentItem.new(
          :variant_id => vid, 
          :product_id => pid, 
          :title => title,
          :sku => variant.sku)
      end #each
    end #if
    rescue ActiveResource::ResourceNotFound => e
      # Just ignore it ?!?  
  end
  
  def process_shipment
    raise(params.inspect)
  end
  
  def receive_shipment
    @vendor_names = ShopifyAPI::Product.find(:all).map{|product| product.vendor}.uniq
  end
  
  def vendor_products
    if(request.post?)
      vendor_name = params['vendor_name']
      @products = ShopifyAPI::Product.find(:all, :params => {:vendor => vendor_name})
      render(:layout => false)
    end #if
  end
end
