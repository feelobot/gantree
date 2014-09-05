module Gantree
  class Generate

    def initialize app,options
      @options = options
      AWS.config(
        :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
        :secret_access_key => ENV['AWS_SECRET_ACCES_KEY'])
    end

  end
end
