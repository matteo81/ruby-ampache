dir = File.dirname(__FILE__)
$LOAD_PATH.unshift dir unless $LOAD_PATH.include?(dir)

require 'nokogiri'
require 'net/http'
require 'open-uri'
require 'digest/sha2'
require 'date'
require 'parseconfig'
require 'singleton'
require 'open4'
require 'timeout'

=begin
A session is a singleton so it cannot be directly initialized. Two initialization methods
are supported:
- Ampache::Session.handshake(host, user, password)
- Ampache::Session.from_config_file( [file] )
Then, access the session with Ampache::Session.instance

An auth token is requested on handshake

To get the artist list from database you can 
call the method artists(nil) and you'll get an array
of AmpacheArtists. 

To get albums from an artist you can use
artist_instance.albums or ampache_ruby.instance.albums(artist_instance)
=end

module Ampache

  class Session    
    include Singleton
    
    attr_reader :stats
    attr_accessor :host, :path, :user, :psw, :token, :playlist

    def self.handshake(host, user, psw)
      uri = URI.parse(host)
      
      session = Session.instance
      session.host = uri.host
      session.path = uri.path
      session.user = user
      session.psw = psw
      session.token = session.get_auth_token(user, psw)
      
      session
    end
    
    def self.from_config_file(file = '~/.ruby-ampache')
      begin
        ar_config = ParseConfig.new(File.expand_path(file))
      rescue
        raise "\nPlease create a .ruby-ampache file on your home\n See http://github.com/matteo81/ruby-ampache for infos\n"
      end

      Session.handshake(ar_config.get_value('AMPACHE_HOST'), ar_config.get_value('AMPACHE_USER'), ar_config.get_value('AMPACHE_USER_PSW'))
    end

    # retrive artists lists from database,
    # name is an optional filter
    def artists(name = nil)
      args = {}
      args = {'filter' => name.to_s} if name # artist search
      artists = []
      doc = call_api_method("artists", args)
      doc.xpath("//artist").each do |a|
        artists << Artist.new(a)
      end
      return artists
    end

    def albums(artist)
      albums = []
      args = {'filter' => artist.uid.to_s}
      doc = call_api_method("artist_albums", args)
      doc.xpath("//album").each do |a|
        albums << Album.new(a)
      end
      return albums
    end

    def songs(album)
      songs = []
      args = {'filter' => album.uid.to_s}
      doc = call_api_method("album_songs", args)
      doc.xpath("//song").each do |s|
        songs << Song.new(s)
      end
      return songs
    end
    
    # tries to obtain an auth token
    def get_auth_token(user, psw)    
      action = "handshake"
      # auth string
      key = Digest::SHA2.new << psw
      time = Time.now.to_i.to_s
      psk = Digest::SHA2.new << (time + key.to_s)
      begin
        args = {'auth' => psk, 'timestamp'=> time, 'version' => '350001', 'user' => user}
        doc = call_api_method(action, args);
        @stats = Stats.new(doc)
        return doc.at("auth").content
      rescue Exception => e 
        raise "Token not valid or expired, check your username and password\n#{e}"
      end
    end

  # generic api method call
    def call_api_method(method, args={})
      begin
        if !ENV['http_proxy'].nil?
          proxy_uri = URI.parse(ENV['http_proxy'])
          http_class = Net::HTTP::Proxy(proxy_uri.host, proxy_uri.port)
        elsif (IO.popen('kreadconfig --file kioslaverc --group Proxy\ Settings --key ProxyType').readlines.first.to_i > 0)
          proxy_uri = URI.parse(IO.popen('kreadconfig --file kioslaverc --group Proxy\ Settings --key httpProxy').readlines.first)
          http_class = Net::HTTP::Proxy(proxy_uri.host, proxy_uri.port)
        else
          http_class = Net::HTTP
        end
        args['auth'] ||= token if token
        url = path + "/server/xml.server.php?action=#{method}&#{args.keys.collect { |k| "#{k}=#{args[k]}" }.join('&')}"
        response = http_class.get_response(host, url)
        return Nokogiri::XML(response.body)
      rescue Errno::ECONNREFUSED => e
        raise "Ampache closed with the following error: #{e.message}"
      end
    end
  end

  class Stats
  attr_reader :songs, :albums, :artists, :update, :add, :clean, :version
    def initialize(doc)
      @songs = doc.at("songs").content.to_i
      @albums = doc.at("albums").content.to_i
      @artists = doc.at("artists").content.to_i
      @update = DateTime.parse doc.at("update").content
      @add = DateTime.parse doc.at("add").content
      @clean = DateTime.parse doc.at("clean").content
      
      # the API version is sometimes called 'api'
      # and sometimes 'version'
      @version = ''
      begin
        @version = doc.at("api").content
      rescue
        @version = doc.at("version").content
      end
    end
       
    def to_s
      "Song #: #{@songs}
Album #: #{@albums}
Artist #: #{@artists}
Last update: #{@update}
Last add: #{@add}
Last clean: #{@clean}"
    end
  end
  
  module XmlAccessor
    def initialize(xml)
      @xml = xml
    end
    
    def method_missing( method_name, *args )
      @xml.children.each do |child|
        return child.content if (child.name == method_name.to_s and child.element?)
      end
      super
    end
    
    def uid
      return @xml['id']
    end
  end
  
  class Artist
    include XmlAccessor

    def get_albums
      @albums ||= Session.instance.albums(self)
    end

    def add_to_playlist(pl)
      albums.each do |s|
        s.add_to_playlist(pl)
        sleep 1
      end
    end  
  end

  class Album
    include Comparable
    include XmlAccessor
    
    def get_songs
      @songs ||= Session.instance.songs(self)
    end

    def add_to_playlist(pl)
      songs.each do |s|
        s.add_to_playlist(pl)
      end
    end

    def <=>(other)
      if name == other.name
        disk.to_i <=> other.disk.to_i
      else 
        year.to_i <=> other.year.to_i
      end
    end
  end

  class Song
    include Comparable
    include XmlAccessor
    
    def add_to_playlist(pl)
      pl.add(self)
    end

    def <=>(other)
      if album == other.album
        track.to_i <=> other.track.to_i
      else
        album <=> other.album
      end
    end
  end

  class Playlist
    def initialize
      @list = []
    end
    
    def add(song)
      @list << song
    end
    
    def <<(song)
      add(song)
    end
    
    def each
      @list.each {|i| yield(i)}
    end
  end
end