#!/usr/bin/env ruby

require "rubygems"
require "ncurses"
require "mqtt"

class ChatGui
   def read_line(y, x,
                 window     = Ncurses.stdscr,
                 max_len    = (window.getmaxx - x - 1),
                 string     = "",
                 cursor_pos = 0)
      loop do
         window.mvaddstr(y,x,string)
         window.move(y,x+cursor_pos)
         ch = window.getch
         case ch
         when Ncurses::KEY_ENTER, ?\n.ord, ?\r.ord
            return string
         when Ncurses::KEY_BACKSPACE, 127
            string = string[0...([0, cursor_pos-1].max)] + string[cursor_pos..-1]
            cursor_pos = [0, cursor_pos-1].max
            window.mvaddstr(y, x+string.length, " ")
         when (" "[0].ord..255)
            if (cursor_pos < max_len)
               string[cursor_pos,0] = ch.chr
               cursor_pos += 1
            else
               Ncurses.beep
            end
         else
            Ncurses.beep
         end
      end
   end

   def add_message(message)
      @messages += message.split("\n")
      if @messages.size > @max_messages
         @messages.shift
      end

      refresh_messages_window
   end

   def refresh_messages_window
      @messages_window.clear
      y = 0
      @messages.each do |message|
         @messages_window.mvaddstr(y, 0, message)
         y = y + 1
      end
      @messages_window.refresh
   end

   def initialize(nick)
      @messages = []
      Ncurses.initscr
      Ncurses.cbreak
      Ncurses.noecho
      Ncurses.keypad(Ncurses.stdscr, true)

      @window = Ncurses.stdscr
      @maxy = @window.getmaxy - 1
      @maxx = @window.getmaxx - 1

      @prompt_window = Ncurses.newwin(2, @maxx, @maxy - 2, 0)
      @prompt = "#{nick} >"

      @messages_window = Ncurses.newwin(@maxy - 2, @maxx, 0, 0)
      @max_messages = @messages_window.getmaxy
   end

   def run(&b)
      loop do
         # refresh_messages_window

         @prompt_window.mvaddstr(0, 0, "-"*@maxx)
         @prompt_window.mvaddstr(1, 0, @prompt)
         message = read_line(1, @prompt.length + 1, @prompt_window)
         yield message
         @prompt_window.clear
      end
   end

   def quit
      Ncurses.endwin
   end
end

# -- main --

def help(gui)
   gui.add_message <<EOH
   /help : display this help
   /me <message> : send an action message
   /privmsg <nickname> <message> : send a private message
   /quit : Quit MQTT chat
   /who : ask who is here
EOH
end

begin

   nickname = ARGV[0]
   raise "Usage : #{$0} <nickname>" if nickname.nil?

gui = ChatGui.new(nickname)
mqtt = MQTT::Client.new('localhost')

mqtt.connect do |client|
   client.subscribe('chat/public')
   client.subscribe('chat/system')
   client.subscribe("chat/private/#{nickname}")

   client.publish 'chat/public', "** #{nickname} enter"

   Thread.new do
      gui.run do |message|
         case message
         when /^\/quit\s*(.*)/
            client.publish 'chat/public', "** #{nickname} has quit (#{$1})"
            client.disconnect
            gui.quit
            exit 1
         when /^\/privmsg\s*([^\s]*)\s*(.*)/
            client.publish "chat/private/#{$1}", ">> [#{Time.now.strftime('%H:%M:%S')}] #{nickname} : #{$2}"
            client.publish "chat/private/#{nickname}", ">> [#{Time.now.strftime('%H:%M:%S')}] #{nickname} : #{$2}"
         when /^\/who/
            client.publish "chat/system", nickname
         when /^\/help/
            help gui
         else
            client.publish 'chat/public', "[#{Time.now.strftime('%H:%M:%S')}] #{nickname} : #{message}"
         end
      end
   end

   loop do
      topic,message = client.get
      if topic =~ /chat\/system/
         client.publish "chat/private/#{message}", "-- #{nickname} is here"
      else
         gui.add_message message
      end
   end
end

rescue Interrupt
  puts "\nexiting..."
rescue Exception => e
  puts e

end
