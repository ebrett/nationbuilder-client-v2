# frozen_string_literal: true

module NationbuilderApi
  class Engine < ::Rails::Engine
    isolate_namespace NationbuilderApi

    initializer "nationbuilder_api.logger" do
      config.after_initialize do
        NationbuilderApi.logger = Rails.logger if NationbuilderApi.logger.nil?
      end
    end

    initializer "nationbuilder_api.adapter" do
      config.after_initialize do
        # Set default adapter to ActiveRecord if available and not configured
        if NationbuilderApi.configuration.token_adapter.nil? && defined?(ActiveRecord)
          NationbuilderApi.configuration.token_adapter = :active_record
        end
      end
    end
  end
end
