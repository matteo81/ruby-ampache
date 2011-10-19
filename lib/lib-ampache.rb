require 'nokogiri'
require 'net/http'
require 'open-uri'
require 'digest/sha2'
require 'date'

require File.join(File.dirname(__FILE__), 'lib-ampache')

=begin
Class is initialized with Hostname, user and password
An auth token is requested on class initialization

To get the artist list from database you can 
call the method artists(nil) and you'll get an array
of AmpacheArtists. 

To get albums from an artist you can use
artist_instance.albums or ampache_ruby.instance.albums(artist_instance)
=end

class AmpacheRuby
  def initialize(host, user, psw)
    uri = URI.parse(host)
    @host = uri.host
    @path = uri.path
    @user = user
    @psw = psw
    @token = getAuthToken(user, psw)
  end

  attr_reader :stats
  attr_accessor :host, :path, :user, :psw, :token, :playlist

  # tries to obtain an auth token
  def getAuthToken(user, psw)
    begin
      action = "handshake"
      # auth string
      key = Digest::SHA2.new << psw
      time = Time.now.to_i.to_s
      psk = Digest::SHA2.new << (time + key.to_s)

      args = {'auth' => psk, 'timestamp'=> time, 'version' => '350001', 'user' => user}
      doc = callApiMethod(action, args);

      @stats = AmpacheStats.new(doc.at("songs").content, doc.at("albums").content, doc.at("artists").content, 
                                doc.at("update").content, doc.at("add").content, doc.at("clean").content)
      return doc.at("auth").content
    rescue Exception => e 
      raise "token not valid or expired, check your username and password"
    end
  end

  # generic api method call
  def callApiMethod(method, args={})
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

  # retrive artists lists from database,
  # name is an optional filter
  def artists(name = nil)
    args = {}
    args = {'filter' => name.to_s} if name # artist search
    artists = []
    doc = callApiMethod("artists", args)
    doc.xpath("//artist").each do |a|
      artists << AmpacheArtist.new(self, a)
    end
    return artists
  end

  def albums(artist)
    albums = []
    args = {'filter' => artist.uid.to_s}
    doc = callApiMethod("artist_albums", args)
    doc.xpath("//album").each do |a|
      albums << AmpacheAlbum.new(self, a)
    end
    return albums
  end

  def songs(album)
    songs = []
    args = {'filter' => album.uid.to_s}
    doc = callApiMethod("album_songs", args)
    doc.xpath("//song").each do |s|
      songs << AmpacheSong.new(self, s)
    end
    return songs
  end
end

class AmpacheStats
attr_reader :songs, :albums, :artists, :update, :add, :clean
  def initialize(songs, albums, artists, update, add, clean)
    @songs = songs.to_i
    @albums = albums.to_i
    @artists = artists.to_i
    @update = DateTime.parse update
    @add = DateTime.parse add
    @clean = DateTime.parse clean
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
