require 'Qt4'
require 'ampache'

class CollectionModel < Qt::AbstractListModel
  def initialize(ampache, parent = nil)
    super(parent)

    @artists = ampache.artists
  end

  def rowCount(parent = nil)
    @artists.count
  end

  def data(index, role = Qt::DisplayRole)
    item = @artists[index.row]
    return invalid if item.nil?

    return Qt::Variant.new(item.name) if role == Qt::DisplayRole
    return Qt::Variant.from_value(item) if role == Qt::UserRole
    return invalid
  end

  def headerData(section, orientation, role)
    return invalid unless role == Qt::DisplayRole

    'artist' if orientation == Qt::Horizontal
  end

  def flags(index)
    return Qt::ItemIsSelectable | Qt::ItemIsEnabled
  end

  private
    def invalid
      Qt::Variant.new
    end
end

class AlbumModel < Qt::AbstractListModel
  def initialize(artist, parent = nil)
    super(parent)
    
    @albums = Ampache::Session.instance.albums(artist).sort
  end
  
  def rowCount(parent = nil)
    @albums.count
  end
  
  def data(index, role = Qt::DisplayRole)
    item = @albums[index.row]
    return invalid if item.nil?
    
    return Qt::Variant.new(item.name) if role == Qt::DisplayRole
    return Qt::Variant.from_value(item) if role == Qt::UserRole
    return invalid
  end
  
  def headerData(section, orientation, role)
    return invalid unless role == Qt::DisplayRole
    
    'album' if orientation == Qt::Horizontal
  end
  
  def flags(index)
    return Qt::ItemIsSelectable | Qt::ItemIsEnabled
  end
  
  private
    def invalid
      Qt::Variant.new
    end
end

class SongModel < Qt::AbstractListModel
  def initialize(album, parent = nil)
    super(parent)
    
    @songs = Ampache::Session.instance.songs(album).sort
  end
  
  def rowCount(parent = nil)
    @songs.count
  end
  
  def data(index, role = Qt::DisplayRole)
    item = @songs[index.row]
    return invalid if item.nil?
    
    return Qt::Variant.new(item.title) if role == Qt::DisplayRole
    return Qt::Variant.from_value(item) if role == Qt::UserRole
    return invalid
  end
  
  def headerData(section, orientation, role)
    return invalid unless role == Qt::DisplayRole
    
    'song' if orientation == Qt::Horizontal
  end
  
  def flags(index)
    return Qt::ItemIsSelectable | Qt::ItemIsEnabled
  end
  
  private
  def invalid
    Qt::Variant.new
  end
end

class PlaylistModel < Qt::AbstractTableModel
  signals 'dataChanged(int, int)'

  def initialize(songs = [], parent = nil)
    super(parent)
    
    @songs = []
    @songs = songs if (songs)
  end
  
  def rowCount(parent = nil)
    @songs.size
  end
  
  def columnCount(parent = nil)
    4
  end
  
  def data(index, role = Qt::DisplayRole)
    return invalid unless role == Qt::DisplayRole or role == Qt::UserRole
    song = @songs[index.row]
    return invalid if song.nil?
    return Qt::Variant.from_value song if role == Qt::UserRole
    
    v = case index.column
    when 0
      song.track.to_i
    when 1
      song.title
    when 2
      song.artist
    when 3
      song.album
    else
      raise "invalid column #{index.column}"
    end || ""
    return Qt::Variant.new(v)
  end
  
  def headerData(section, orientation, role)
    return invalid unless role==Qt::DisplayRole
    
    v = case orientation
    when Qt::Horizontal
      ["Track","Title","Artist","Album"][section]
    else
      ""
    end

    return Qt::Variant.new v
  end

  def flags(index)
    return Qt::ItemIsSelectable | super(index)
  end

  def setData(index, variant, role=Qt::EditRole)
    if index.valid? and role == Qt::EditRole
      s = variant.toString
      song = @songs[index.row]
      case index.column
      when 0
        song.track = s.to_i
      when 1
        song.title = s
      when 2
        song.artist = s
      when 3
        song.album = s
      else
        raise "invalid column #{index.column}"
      end

      emit dataChanged(index, index)
      return true
    else
      return false
    end
  end
  
  def append(song)
    puts "rowCount: #{rowCount}"
    beginInsertRows(Qt::ModelIndex.new, rowCount, rowCount);
    @songs << song
    endInsertRows
  end
  
  private
    def invalid
      Qt::Variant.new
    end
end