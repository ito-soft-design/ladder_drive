require 'rake/testtask'

task :default => [:test]

Rake::TestTask.new do |t|
  t.libs << "./lib/command"
  t.test_files = FileList['test/**/test*.rb']
  t.verbose = true
end
