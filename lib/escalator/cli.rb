require 'thor'
require 'fileutils'

include FileUtils

module Escalator
  class CLI < Thor
    
    desc "create", "Create a new project"
    def create(name)
      template_path = File.join(Escalator_root, "template", "escalator")
      cp_r template_path, name

    end

  end
end
