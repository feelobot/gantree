module Gantree
  class Wiki
    attr_reader :wiki_path
    attr_accessor :file_path
    def initialize(notes, filename, wiki_url, path='/tmp/')
      @notes = notes
      @wiki_url = wiki_url
      wiki_path = wiki_url.split("/").last.sub(".git","")
      @wiki_path = "#{path}#{wiki_path}"
      @file_path = "#{@wiki_path}/#{filename}"
    end

    def update
      pull
      added = add_to_top
      push if added
    end

    def pull
      puts "Updating wiki cached repo".colorize(:yellow)
      if File.exist?(@wiki_path)
        Dir.chdir(@wiki_path) do
          execute("git checkout master") unless execute("git branch").include?("* master")
          execute("git pull origin master")
        end
      else
        dirname = File.dirname(@wiki_path)
        FileUtils.mkdir_p(dirname) unless File.exist?(dirname)
        cmd = "cd #{dirname} && git clone #{@wiki_url}"
        execute(cmd)
      end
    end

    def add_to_top
      data = IO.read(@file_path) if File.exist?(@file_path)
      File.open(@file_path, "w") do |file|
        file.write(@notes)
        file.write("\n")
        file.write(data) if data
      end
      true
    end

    def push
      Dir.chdir(@wiki_path) do
        basename = File.basename(@file_path)
        execute("git add #{basename}")
        execute(%Q|git commit -m "Update release notes"|)
        execute("git push origin master")
      end
    end

    def execute(cmd)
      `#{cmd}`
    end
  end
end