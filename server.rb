# Minimal static file server (no getcwd dependency) for local preview.
require 'webrick'
root = File.expand_path(File.dirname(__FILE__))
server = WEBrick::HTTPServer.new(Port: 8000, DocumentRoot: root)
trap('INT') { server.shutdown }
server.start
