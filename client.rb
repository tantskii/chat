require 'socket'
require 'colorize'

class Client
  def initialize(server)
    @server   = server
    @request  = nil
    @response = nil
    listen
    send
    @request.join
    @response.join
  end

  def listen
    @response = Thread.new do
      loop {
        msg = @server.gets.chomp
        puts "#{msg}"
      }
    end
  end

  def send
    puts 'Введите имя пользовалтеля'
    nick_name_color = String.colors.sample
    @request = Thread.new do
      loop {
        msg = STDIN.gets.chomp.colorize(nick_name_color)
        @server.puts(msg)
      }
    end
  end
end

server = TCPSocket.open('localhost', 3000)
Client.new(server)