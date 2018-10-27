# Execute it when this file was loaded.
def plugin_blank_init plc
  puts "Blank#init"
end

# Execute it each cycle.
def plugin_blank_exec plc
  puts "Blank#exec"
end
