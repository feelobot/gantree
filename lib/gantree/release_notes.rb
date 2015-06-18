require 'aws-sdk'

module Gantree
  class ReleaseNotes
    attr_reader :current_sha
    attr_writer :beanstalk
    def initialize(wiki, env_name, packaged_version)
      @env_name = env_name
      @wiki = wiki
      @org = wiki.split("/")[0..-2].join("/")
      @packaged_version = packaged_version
    end

    def current_sha
      @packaged_version.split("-")[2]
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

    def pacific_time
      Time.now.strftime '%Y-%m-%d %a %I:%M%p PDT'
    end

    def commits
      return @commits if @commits
      # Get commits for this release
      commits = git_log
      commits = commits.split("COMMIT_SEPARATOR")
      commits = commits.collect { |x| x.strip }.reject {|x| x.empty? }
      tickets = []
      commits.each do |msg|
        md = msg.match(/(\w+-\d+)/)
        if md
          ticket_id = md[1]
          tickets << msg unless tickets.detect {|t| t =~ Regexp.new("^#{ticket_id}") }
        else
          tickets << msg
        end
      end
      tickets
    end

    def commits_list
      commits.collect{|x| "* #{x}" }.join("\n")
    end

    def git_log
      execute("git log --no-merges --pretty=format:'%B COMMIT_SEPARATOR' #{previous_sha}..#{current_sha}").strip
    end

    def execute(cmd)
      `#{cmd}`
    end

    def notes
      compare = "#{previous_sha}...#{current_sha}"
      notes = <<-EOL
#{@env_name} #{pacific_time} [#{compare}](#{@org}/#{app_name}/compare/#{compare}) by #{ENV['USER']} (#{@packaged_version})
#{commits_list}
EOL
    end

    def create
      filename = "Release-notes-br-#{app_name}.md" # business logic
      Gantree::Wiki.new(notes, filename, @wiki).update
    end
  end
end