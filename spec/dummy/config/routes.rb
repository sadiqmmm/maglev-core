# frozen_string_literal: true

Rails.application.routes.draw do
  # FIXME: We might want to mount `Maglev::Engine` here
  mount Maglev::Engine, as: :maglev, at: '/maglev'

  get '(*path)', to: 'maglev/page_preview#index', defaults: { path: 'index' }

  direct :cdn_image do |model, options|
    if model.respond_to?(:signed_id)
      route_for(
        :rails_service_blob_proxy,
        model.signed_id,
        model.filename,
        options.merge(host: ENV['CDN_HOST'] || 'http://example.local')
      )
    else
      signed_blob_id = model.blob.signed_id
      variation_key  = model.variation.key
      filename       = model.blob.filename

      route_for(
        :rails_blob_representation_proxy,
        signed_blob_id,
        variation_key,
        filename,
        options.merge(host: ENV['CDN_HOST'] || 'http://example.local')
      )
    end
  end

  get '/nocoffee_site', to: redirect('https://www.nocoffee.fr'), as: :nocoffee
end
