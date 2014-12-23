require "cinch/version"

require 'fileutils'
require 'socket'

require 'oj'
require 'rake'
require 'xxhash'

module Easy

module Cinch

  Cinch_home = '.cinch'
  Config = "#{Cinch_home}/config.json"
  Manifest = "#{Cinch_home}/manifest.json"

  module_function


  def add(pattern='**/*', hash=true)
    repo_name = Oj.load_file(Config)['local']
    # One for remotes, one for checksums.
    manifest = Oj.load_file(Manifest) || Hash.new { |h, k| h[k] = [], [] }
    FileList[pattern].each do |f|
      if manifest[f]
        manifest[f][0] <<repo_name
      else
        manifest[f] = [[], [repo_name]]
      end
    end
    Oj.to_file(Manifest, manifest, :mode => :strict)
  end

  def hash(pattern)
    manifest = Oj.load_file(Manifest)
    if pattern.nil?
      pattern = manifest.keys
    end
    FileList[pattern].each do |f|
    end
end

    # 50 MB
    # This is chosen by GitHub's recommended maximum file size in git repo.
    # Need benchmarking xxhash ruby wrapper and xxhsum.
  end

  def init(repo_name)
    repo_name ||= Socket.gethostname
    if File.exist? Config
      puts "#{Config} already exist!"
    else
      FileUtils.mkdir_p Cinch_home
    	open(Config, 'w') do |f|
    		f.puts "{ \"local\": \"#{repo_name}\" }"
      end
    end
  end
end
