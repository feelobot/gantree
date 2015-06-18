require 'aws-sdk'

module Gantree
  class ReleaseNotes
    attr_reader :current_sha
    attr_writer :beanstalk
    def initialize wiki, env_name, current_sha
      @env_name = env_name
      @wiki = wiki
      @org = wiki.split("/")[0..-2].join("/")
      @current_sha = current_sha
    end

    def beanstalk
      return @beanstalk if @beanstalk
      @beanstalk = Aws::ElasticBeanstalk::Client.new(
        :region => ENV['AWS_REGION'] || "us-east-1"
      )
    end

    def environment
      beanstalk.describe_environments(:environment_names => [@env_name]).environments.first
    end

    def previous_tag
      environment.version_label
    end

    def previous_sha
      previous_tag.split("-")[2]
    end

    def app_name
      name = environment.application_name
      name.include?("-") ? name.split("-")[1] : name # TODO: business logic
    end

    def now
      @now ||= Time.now.strftime("%a, %e %b %Y %H:%M:%S %z")
    end

    def commits
      return @commits if @commits
      # Get commits for this release
      commits = git_log
      commits = commits.split("COMMIT_SEPARATOR")
      commits = commits.collect { |x| x.strip }
      # only grab the line with the lighthouse info
      # or the first line if no lighthouse info
      commits = commits.collect do |x|
        lines = x.split("\n")
        lines.select { |y| y =~ /\[#\d+/ }.first || lines.first
      end.compact
      # rid of clean up ticket format [#1234 state:xxx]
      commits = commits.map do |x|
        x.gsub(/\[#(\d+)(.*)\]/, '\1')
      end
      @commits = commits.uniq.sort
    end

    def git_log
      execute("git log --no-merges --pretty=format:'%B COMMIT_SEPARATOR' #{@left}..#{@right}").strip
    end

    def execute(cmd)
      `#{cmd}`
    end

    def notes
      compare = "#{previous_sha}...#{current_sha}"
      notes = <<-EOL
"#{@env_name} #{now} [compare](#{@org}/#{app_name}/compare/#{compare})"

#{commits.collect{|x| "* #{x}" }.join("\n")}
EOL
    end

    def create
      filename = "Release-notes-br-#{app_name}.md" # business logic
      Gantree::Wiki.new(notes, filename, @wiki).update
    end
  end
end