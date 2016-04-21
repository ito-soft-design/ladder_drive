require 'thor'
require 'fileutils'

include FileUtils

module Escalator
  class CLI < Thor
    
    desc "create", "Create a new project"
    def create(name)
      mkdir 
    end

  end
end
