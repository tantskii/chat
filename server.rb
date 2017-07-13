require 'socket'
require 'colorize'

class Server
  def initialize(port, ip)
    @server                = TCPServer.open(ip, port)
    @connections           = {}
    @rooms                 = {} # { room_name: [{clients_name: client}, ...], ... }
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

        client.puts 'Подключение установлено. Введите название комнаты.'

        name_of_room = client.gets.chomp.to_sym

        client.puts "Вы подключились в комнату #{name_of_room}"

        if @connections[:rooms][name_of_room].nil?
          @connections[:rooms][name_of_room] = [{nick_name => client}]
        else
          @connections[:rooms][name_of_room] << {nick_name => client}
        end

        puts "#{name_of_room}".colorize(:blue) +
                 " участники: " + @connections[:rooms][name_of_room].map(&:keys).join(', ')

        listen_user_messages(nick_name, client, name_of_room)
      end
    }.join
  end

  def listen_user_messages(username, client, room_name)
    loop {
      msg = client.gets.chomp

      @connections[:rooms][room_name].each do |client_hash|
        other_name   = client_hash.keys.first
        other_client = client_hash.values.first

        begin
          other_client.puts "#{username.to_s}: #{msg}" unless other_name == username
        rescue => error
          print "#{error.message}: ".colorize(:red)

          puts "#{other_name} отключился".colorize(:red) if error.message == 'Broken pipe'

          @connections[:clients].delete(other_name)
          @connections[:rooms][room_name].delete(client_hash)
          @connections[:rooms].delete(room_name) if @connections[:rooms][room_name].empty?
        end
      end
    }
  end
end

Server.new(3000, 'localhost')