require "escalator/protocols/protocol"

class EscalatorConfig

  include Protocol::Mitsubishi

  def self.default
    @config ||= begin
      config_path = File.join "config", "plc.yml"
      new File.exist?(config_path) ? YAML.load(config_path) : {}
    end
  end

  def initialize options={}
    @config = options
  end

  def protocol
    @protocol ||= begin
      p = eval("#{@config[:protocol].camelize}.new")
      p.ip = @config[:ip]
      p.port = @config[:port]
      p
    rescue
      nil
    end
  end

end
