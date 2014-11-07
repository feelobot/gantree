module Gantree
  class Base
    def print_options
      @options.each do |param, value|
        puts "#{param}: #{value}"
      end
    end
  end
end

