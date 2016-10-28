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
    default = {input: "asm/main.asm", output: "build/main.hex"}
    @config = options.merge default
  end

  def protocol
    @protocol ||= begin
      plc_info = @config[:plc]
      p = eval("#{plc_info[:protocol].camelize}.new")
      p.host = plc_info[:host]
      p.port = plc_info[:port]
      p
    rescue
      nil
    end
  end

  def method_missing(name, *args)
    name = name.to_s unless name.is_a? String
    case name.to_s
    when /(.*)=$/
      @config[$1.to_sym] = args.first
    else
      @config[name.to_sym]
    end
  end

end
