module Gantree
  class Uploads3
    
    attr_reader :options
    desc ""
    def initialize options
      @s3 = AWS::S3.new
      @options = options
    end
    
    desc ""
    def rename

    end

    desc "Gives a version"
    def version
      branch = `git branch`
      branch = branch[2..-1]
      hash = `git rev-parse --verify --short #{branch}`.strip
      "#{@options.env}-#{hash}"
    end

  end
end
