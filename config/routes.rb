Instock::Application.routes.draw do
  root :to                   => 'home#index'

  match 'contact'            => 'home#contact'
  match 'about'              => 'home#about'
  match 'preferences'        => 'home#preferences'
  match 'support'            => 'home#support'
  match 'dashboard'          => 'home#dashboard'

  match 'login'              => 'login#index'
  match 'login/authenticate' => 'login#authenticate'
  match 'login/finalize'     => 'login#finalize'
  match 'login/logout'       => 'login#logout'

  match 'client_shop_management/record_shop'  => 'client_shop_management#record_shop'

  match 'ajax/receiving_items'  => 'ajax#receiving_items'
  match 'ajax/stock_adjustment_items'  => 'ajax#stock_adjustment_items'
  match 'ajax/vendor_products'  => 'ajax#vendor_products'
  match 'ajax/methods'  => 'ajax#methods'
  match 'ajax/collection_products'  => 'ajax#collection_products'

  resources :stock_audits do
    resources :stock_audit_items, :only => :none
  end

  resources :receivings do |receivings|
    resources :receiving_items, :only => :none
  end

  resources :stock_adjustments do
    resources :stock_adjustment_items, :only => :none
  end

  resources :client_shops

  #Admin
  #map.admin_logout "admin_logout", :controller => "admin_sessions", :action => "destroy"
  #Resources
  #map.resource :account, :controller => "admins"
  #map.resources :admins 
  #map.resource :admin_session
    #map.root :controller => "admin_session_sessions", :action => "new"
end
