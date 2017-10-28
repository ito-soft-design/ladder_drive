require "bundler/gem_tasks"
require 'rake/testtask'
require 'fileutils'

include FileUtils

task :default => [:test]

Rake::TestTask.new do |t|
  t.test_files = FileList['test/**/test*.rb']
  t.verbose = true
end

namespace :doc do

  desc "Make epub documentation."
  task :epub do
    dst_dir = "tmp/doc"
    FileList['doc/**/*.md'].each do |src|
      dst = dst_dir + src.gsub(/^doc/, "").gsub(/md$/, "epub")
      mkdir_p File.dirname(dst), verbose: false
      cmd = "pandoc -f markdown -t epub3 #{src} -o #{dst}"
      puts `#{cmd}`
    end
  end

=begin FIXME:It does not work on my mac.
  desc "Make pdf documentation."
  task :pdf do
    dst_dir = "tmp/doc"
    FileList['doc/**/*.md'].each do |src|
      dst = dst_dir + src.gsub(/^doc/, "").gsub(/md$/, "pdf")
      mkdir_p File.dirname(dst), verbose: false
      cmd = "pandoc #{src} -o #{dst}"
      puts `#{cmd}`
    end
  end
=end

end
