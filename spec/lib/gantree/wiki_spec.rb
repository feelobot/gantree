require "spec_helper"

describe Gantree::Wiki do
  before(:all) do
    @notes = "fake_release_notes"
    filename = "Release-notes-br-rails.md"
    wiki = "git@github.com:br/dev.wiki.git"
    @wiki = Gantree::Wiki.new(@notes, filename, wiki, "tmp/")
  end

  def fake_clone_dir
    FileUtils.mkdir_p(@wiki.wiki_path)
  end

  it "should clone and pull" do    
    FileUtils.rm_rf(@wiki.wiki_path) if ENV['CLEAN']
    allow(@wiki).to receive(:execute).and_return(fake_clone_dir)
    @wiki.pull
    folder_created = File.exist?(@wiki.wiki_path)
    # puts "@wiki.wiki_path #{@wiki.wiki_path.inspect}"
    expect(folder_created).to be true
    @wiki.pull
  end

  it "should add notes to the top" do
    FileUtils.mkdir("tmp") unless File.exist?("tmp")
    @wiki.file_path = "tmp/Release-notes-br-rails.md"
    FileUtils.rm_f(@wiki.file_path)
    @wiki.add_to_top
    notes = IO.read(@wiki.file_path)
    expect(notes).to eq "#{@notes}\n\n"

    @wiki.add_to_top
    notes = IO.read(@wiki.file_path)
    expect(notes).to eq "#{@notes}\n\n#{@notes}\n\n"
  end

  it "should push" do
    allow(@wiki).to receive(:execute).and_return(fake_clone_dir)
    @wiki.push
  end

  it "should update" do
    allow(@wiki).to receive(:pull)
    allow(@wiki).to receive(:add_to_top).and_return(true)
    allow(@wiki).to receive(:push)
    @wiki.update
  end
end