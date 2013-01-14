Simple MQTT-based chat room client written in Ruby

## Install

1. Install and run an MQTT broker ([mosquitto](http://mosquitto.org) is one choice, this also works with [RabbitMQ](http://rabbitmq.com) version 3 which includes MQTT support)

2. Install the [mqtt](http://github.com/njh/ruby-mqtt) and ncurses-ruby gems 

(NB the plain ncurses gem is harder to natively compile)

    sudo gem install mqtt ncurses-ruby

## Run

1. Run the client 

    ruby ./mqtt-chat.rb <username>

2. If you want to configure the app to run against an alternative MQTT broker running on a different host/post:

modify

    mqtt = MQTT::Client.new('localhost')
    
replacing 'localhost' with the hostname or IP address of your chosen broker, optionally with a port number, e.g.

    mqtt = MQTT::Client.new('m2m.eclipse.org', 1883)
    
## Background

Modified from simple AMQP-based and MQTT-based chat servers originally published as Gists by [glejeune](https://gist.github.com/glejeune)

#### Changes from original

* added exit handler for cleaner end
* updated for newer ruby-mqtt gem
* fixed help text
* updated README