require 'aws-sdk'
module Gantree
  class ReleaseNotes
    def initializer wiki, app, hash
      @app = app
      @new_hash = hash
      @wiki_url = wiki
    end 

    def create
      get_release_notes
      write_release_notes
      #commit_release_notes
    end
    
    def get_release_notes
      rl_dir = "/tmp/wiki_release_notes"
      FileUtils.rm_rf(rl_dir) if File.directory? rl_dir
      `git clone #{@wiki_url} /tmp/wiki_release_notes/` 
    end
    
    def write_release_notes
      release_notes_file = "Release-notes-br-#{@app}.md"
      `echo "#{release_notes}" | cat - #{release_notes_file} > #{release_notes_file}.tmp  && mv #{release_notes_file}.tmp #{releas_notes_file}`
    end

    def release_notes
      time = Time.now.strftime("%a, %e %b %Y %H:%M:%S %z")
      "#{time} [#{last_deployed_hash}...#{@new_hash}](https://github.com/br/#{app}/compare/#{last_deployed_hash}...#{@new_hash})"
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
  end
end
