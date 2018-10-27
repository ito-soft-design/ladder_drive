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
