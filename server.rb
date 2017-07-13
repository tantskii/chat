require 'socket'
require 'colorize'

class Server
  def initialize(port, ip)
    @server                = TCPServer.open(ip, port)
    @connections           = {}
    @rooms                 = {} # { room_name: [clients_names], ... }
    @clients               = {} # { client_name: {client}, ... },
    @connections[:server]  = @server
    @connections[:rooms]   = @rooms
    @connections[:clients] = @clients
    run
  end

  def run
    loop {
      Thread.start(@server.accept) do |client|
        nick_name = client.gets.chomp.to_sym

        @connections[:clients].each do |other_name, other_client|
          if nick_name == other_name || client == other_client
            client.puts 'Пользователь с таким именем уже существует'

            Thread.kill self
          end
        end

        puts "#{nick_name} #{client}".colorize(:green)

        @connections[:clients][nick_name] = client

        client.puts 'Подключение установлено.'

        listen_user_messages(nick_name, client)
      end
    }.join
  end

  def listen_user_messages(username, client)
    loop {
      msg = client.gets.chomp

      @connections[:clients].each do |other_name, other_client|
        begin
          other_client.puts "#{username.to_s}: #{msg}" unless other_name == username
        rescue => error
          print "#{error.message}: ".colorize(:red)

          puts "#{other_name} отключился".colorize(:red) if error.message == 'Broken pipe'

          @connections[:clients].delete(other_name)
        end
      end
    }
  end
end

Server.new(3000, 'localhost')