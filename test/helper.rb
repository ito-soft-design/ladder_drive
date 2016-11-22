root = File.expand_path(File.join(File.dirname(__FILE__), ".."))
d = File.join(root, "lib")
$:.unshift d unless $:.include? d
d = File.join(root, "plc")
$:.unshift d unless $:.include? d
