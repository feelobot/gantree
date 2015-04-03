require 'aws-sdk'
module Gantree
  class ReleaseNotes
    def initialize wiki, app, hash
      @application = app
      @new_hash = hash
      @wiki_url = wiki
    end 

    def create
      get_release_notes
      write_release_notes
      commit_release_notes
    end
    
    def get_release_notes
      rl_dir = "/tmp/wiki_release_notes"
      FileUtils.rm_rf(rl_dir) if File.directory? rl_dir
      `git clone #{@wiki_url} /tmp/wiki_release_notes/` 
    end
    
    def write_release_notes
      wiki_dir = "/tmp/wiki_release_notes/"
      release_notes_file = "Release-notes-br-#{@application}.md"
      path_to_wiki_file = "#{wiki_dir}#{release_notes_file}"
      `touch #{path_to_wiki_file}` unless File.exist? "#{path_to_wiki_file}"
      `printf "#{release_notes}\n\n" | cat - #{path_to_wiki_file} > #{path_to_wiki_file}.tmp  && mv #{path_to_wiki_file}.tmp #{path_to_wiki_file}`
    end

    def release_notes
      time = Time.now.strftime("%a, %e %b %Y %H:%M:%S %z")
      "#{time} [#{last_deployed_hash}...#{@new_hash}](https://github.com/br/#{@application}/compare/#{last_deployed_hash}...#{@new_hash})"
    end

    def last_deployed_hash
      get_latest_tag(@app).split("-").last
    end

    def get_latest_tag repo
      Aws.config[:credentials]
      beanstalk = Aws::ElasticBeanstalk::Client.new
      resp = beanstalk.describe_application_versions(
        application_name: repo,
      )
      label = resp["application_versions"].select {|version| version["version_label"].include?("br-master") }.first
      if label
        label["version_label"].split("-")[0..2].join('-')
      else
        raise "No Master Tags Deployed:\n #{resp["application_versions"].inspect}"
        500
      end
    end
    def commit_release_notes
      `cd /tmp/wiki_release_notes && git add . && git commit -am "Updated release notes" && git push origin master`
    end
  end
end
