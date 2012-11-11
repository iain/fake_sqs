require 'sinatra/base'

module FakeSQS
  class WebInterface < Sinatra::Base

    helpers do

      def action
        underscore(params.fetch("Action"))
      end

      def underscore(string)
        string.gsub(/([A-Z])/) { |m| "_#{m[0]}".downcase }.sub(/^_/, '')
      end

    end

    get "/" do
      200
    end

    delete "/" do
      settings.sqs.reset
      200
    end

    put "/" do
      settings.sqs.expire
      200
    end

    post "/" do
      settings.sqs.call(action, params)
    end

    post "/:queue" do |queue|
      settings.sqs.call(action, queue, params)
    end

  end
end
