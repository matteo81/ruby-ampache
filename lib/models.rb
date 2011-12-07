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

class PlaylistModel < Qt::AbstractTableModel
  attr_accessor :playlist
  def initialize(playlist = [], parent = nil)
    super(parent)
    
    @playlist = playlist
  end
  
  def rowCount(parent)
    @playlist.count
  end
  
  def columnCount(parent)
    4
  end
  
  def data(index, role)
    return invalid if (index.valid? || index.row > @playlist.count || index.row < 0)
    
    if (role == Qt::DisplayRole)
      song = @playlist[index.row]
      case (index.column)
      when 0
        return song.track
      when 1
        return song.title
      when 2
        return song.artist
      when 3
        return song.album
      end
    end
  end
  
  def headerData(section, orientation, role)
    return invalid if role!=Qt::DisplayRole
    
    if (orientation == Qt::Horizontal)
      case section
      when 0
        return "Track"
      when 1
        return "Title"
      when 2
        return "Artist"
      when 3
        return "Album"
      end
    end
  end
  
  def insertRows(position, rows, index)
    beginInsertRows(Qt::ModelIndex.new, position, position+rows-1)
    
    rows.times do |row|
      @playlist.insert(position, nil)
    end
  end
  
  private
    def invalid
      Qt::Variant.new
    end
end