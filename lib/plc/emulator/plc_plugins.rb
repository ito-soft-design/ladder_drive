#
# Copyright (c) 2018 ITO SOFT DESIGN Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

dir = Dir.pwd
$:.unshift dir unless $:.include? dir

module PlcPlugins

  #def self.included(klass)
  #  load_plugins
  #end

  private

    def plugins
      @plugins ||= []
    end

    def load_plugins
      return unless plugins.empty?
      seen = {}

      Dir.glob("plugins/*_plugin.rb").each do |plugin_path|
        name = File.basename plugin_path, "_plugin.rb"
        next if seen[name]
        seen[name] = true

        require plugin_path.gsub(/\.rb$/, "")
        plugins << name
      end
      init_plugins
    end

    def init_plugins
      send_message_plugins "init", self
    end

    def exec_plugins
      send_message_plugins "exec", self
    end

    def send_message_plugins method, arg
      plugins.each do |plugin|
        msg = "plugin_#{plugin}_#{method}"
        unless arg
          send msg if Object.respond_to?(msg, true)
        else
          send msg, arg if Object.respond_to?(msg, true)
        end
      end
    end

end

def load_plugin_config name
  h = {}
  path = File.join("config", "plugins", "#{name}.yml")
  if File.exist?(path)
    h = YAML.load(File.read(path))
    h = JSON.parse(h.to_json, symbolize_names: true)
  end
  h
end
