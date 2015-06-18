require 'colorize'

module Gantree
  class Config
    class << self
      def merge_defaults(options={})
        configs = ["#{ENV['HOME']}/.gantreecfg",".gantreecfg"]
        hash = {}
        configs.each do |config|
          hash.merge!(merge_config(options,config)) if config_exists?(config)
        end
        Hash[hash.map{ |k, v| [k.to_sym, v] }]
      end

      def merge_config options, config
        defaults = JSON.parse(File.open(config).read)
        defaults.merge(options)
      end

      def config_exists? config
        File.exist? config
      end
    end
  end
end
