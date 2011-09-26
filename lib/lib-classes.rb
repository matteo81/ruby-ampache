require 'open4'
require 'timeout'
class AmpacheArtist

  # include play module
  def initialize(ar, uid, name)
    @ar = ar
    @uid = uid
    @name = name
  end

  attr_reader :uid, :name

  def albums
    @albums ||= @ar.albums(self)
  end

  def add_to_playlist(pl)
  albums.each do |s|
    s.add_to_playlist(pl)
    sleep 1
  end
end
end


class AmpacheAlbum

  def initialize(ar, uid, name, artist)
    @ar = ar
    @uid = uid
    @name = name
    @artist = artist
  end

  attr_reader :uid, :name, :artist

  def songs
    @songs ||= @ar.songs(self)
  end

  def add_to_playlist(pl)
    songs.each do |s|
      s.add_to_playlist(pl)
      sleep 5
    end
  end

end

class AmpacheSong

  def initialize(ar, uid, title, artist, album, url)
    @ar = ar
    @uid = uid
    @title = title
    @artist = artist
    @album = album
    @url = url
  end

  attr_reader :uid, :title, :artist, :album, :url

  def add_to_playlist(pl)
    pl.add(self)
  end

end

class AmpachePlaylist

  def initialize
    mplayer_start
    @started = false
  end

  def started?
    @started == true
  end

  def started!
    @started = true
  end

  def mplayer_start
    $options[:path] ||= '/usr/bin/mplayer'
    $options[:timeout] ||= 15
    mplayer_options = "-slave -quiet -idle"
    mplayer = "#{$options[:path]} #{mplayer_options} "
    @pid, @stdin, @stdout, @stderr = Open4.popen4(mplayer)
  end

  def console
    while ((cmd = gets.chomp)  != 'exit' )
      @stdin.puts cmd
    end
  end

  def add(song)

    say(HighLine.new.color("adding song ",:green) + "#{song.title}")
    if !@pid
      started!
      mplayer_start
    end
    begin
      started!
      @stdin.puts "loadfile \"#{song.url}\" 1"

    rescue Errno::EPIPE
      puts "error on adding song to playlist"
      @pid = nil
      @started = false
      add(song)
    end

  end

  def stop
    begin
      @stdin.puts "quit" if @pid
    rescue Errno::EPIPE
      puts "playlist is over"
    end
    @pid = nil
    @started = false
  end

  def pause
    begin
      @stdin.puts "pause" if @pid && started?
    rescue Errno::EPIPE
      puts "playlist is over"
    end
  end

  def next
    begin
      @stdin.puts "pt_step 1 1" unless @pid.nil?
      until @stdout.gets.inspect =~ /playback/ do
        puts   @stdout.gets

      end

    rescue Errno::EPIPE => e
      puts "playlist is over on next"
      @pid = nil
    end
  end

  def now_playing
    return "Not playing man!" unless started?  && !@pid.nil?
    begin
      s = get("meta_title")
      return "data not available OR playlist is over"  if s.nil?
      s+= get("meta_artist") rescue s
      s+= get("meta_album")  rescue s
      s.chomp!
      return s

    rescue Errno::EPIPE => e
      @pid = nil
      @started = false
      return "playlist is over here" #, or you got an ERROR from mplayer: #{e.to_s}"

    end
  end

  # I borrowed these two methods from the author of mplayer-ruby!
  # so my thanks to Artuh Chiu and his great gem mplayer-ruby
  def get(value)
    field = value.to_s
    match = case field
    when "time_pos" then
      "ANS_TIME_POSITION"
    when "time_length" then
      "ANS_LENGTH"
    when "file_name" then
      "ANS_FILENAME"
    else
      "ANS_#{field.upcase}"
    end
    res = command("get_#{value}", /#{match}/)
    res.gsub("#{match}=", "").gsub("'", "")  unless res.nil?
  end

  def command(cmd, match = //)
    @stdin.puts(cmd)
    response = ""
    begin
      t = Timeout::timeout(3) do
        until response =~ match
          response = @stdout.gets
          puts response
    #XXX escaping bad utf8 chars
          ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
          if response
            response =ic.iconv(response + ' ')[0..-2]
          else
            response == ''
          end
        end
      end
      return response.gsub("\e[A\r\e[K", "")
    rescue Timeout::Error
      return
    end

  end

end

