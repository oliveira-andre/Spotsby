# Seeds

# Reset database

puts 'Are you sure you want to reset the database? (y/N)'
result = gets.chomp

if result == "y" || result == "Y"
  puts "Resetting database..."
  ActiveRecord::Base.connection.tables.each do |table|
    SongAuthor.destroy_all
    Song.destroy_all
    Album.destroy_all
    Author.destroy_all
    Category.destroy_all
    User.delete_all
    Session.destroy_all
    Playlist.destroy_all
    PlaylistSong.destroy_all
    PlayHistory.destroy_all
    SongQueue.destroy_all
    ActiveStorage::Attachment.destroy_all
    ActiveStorage::Blob.destroy_all
  end
else
  puts "Skipping database reset."
end

# Users

puts "Creating users..."

# Admin user
admin = User.create(
  first_name: 'Admin',
  last_name: FFaker::Name.last_name,
  email_address: 'admin@codeline.company',
  password: '12345678',
  status: :admin
)

# Customer user
customer = User.create(
  first_name: 'customer',
  last_name: FFaker::Name.last_name,
  email_address: 'customer@codeline.company',
  password: '12345678',
  status: :active
)

# Blocked User

blocked = User.create(
  first_name: 'blocked',
  last_name: FFaker::Name.last_name,
  email_address: 'blocked@codeline.company',
  password: '12345678',
  status: :blocked
)

# Rock => Freddie Mercury // Freddie music
# Pop => Michael Jackson // Katy Perry music
# Classical => Ludwig van Beethoven // Mozart music
# Jazz => Miles Davis // John Coltrane music
# Electronic => Daft Punk // The Prodigy music
# Hip Hop => Kanye West // Jay-Z music
# Country => Johnny Cash // Dolly Parton music
# Blues => Muddy Waters // Robert Johnson music
# Folk => Bob Dylan // Woody Guthrie music
# Reggae => Bob Marley // Peter Tosh music

# Categories

puts "Creating categories..."
rock = Category.create(name: 'Rock', color: '#006450')
rock.image.attach(io: File.open(Rails.root.join('tmp/images/queen_album.jpg')), filename: 'rock.jpg')

pop = Category.create(name: 'Pop', color: '#dc148c')
pop.image.attach(io: File.open(Rails.root.join('tmp/images/michael.jpg')), filename: 'pop.jpg')

classical = Category.create(name: 'Classical', color: '#8d67ab')
classical.image.attach(io: File.open(Rails.root.join('tmp/images/beethoven.jpg')), filename: 'classical.jpg')

jazz = Category.create(name: 'Jazz', color: '#777777')
jazz.image.attach(io: File.open(Rails.root.join('tmp/images/miles.jpg')), filename: 'jazz.jpg')

electronic = Category.create(name: 'Electronic', color: '#e61e32')
electronic.image.attach(io: File.open(Rails.root.join('tmp/images/daft_punk.jpg')), filename: 'electronic.jpg')

hip_hop = Category.create(name: 'Hip Hop', color: '#1e3264')
hip_hop.image.attach(io: File.open(Rails.root.join('tmp/images/kanye.jpg')), filename: 'hip_hop.jpg')

# Authors

puts "Creating authors..."
queen = Author.create(name: 'Queen')
queen.image.attach(io: File.open(Rails.root.join('tmp/images/queen.jpg')), filename: 'freddie.jpg')

katy_perry = Author.create(name: 'Katy Perry')
katy_perry.image.attach(io: File.open(Rails.root.join('tmp/images/katy_perry.webp')), filename: 'katy_perry.webp')

michael = Author.create(name: 'Michael Jackson')
michael.image.attach(io: File.open(Rails.root.join('tmp/images/michael.jpg')), filename: 'michael.jpg')

mozart = Author.create(name: 'Mozart')
mozart.image.attach(io: File.open(Rails.root.join('tmp/images/mozart.jpg')), filename: 'mozart.jpg')

beethoven = Author.create(name: 'Ludwig van Beethoven')
beethoven.image.attach(io: File.open(Rails.root.join('tmp/images/beethoven.jpg')), filename: 'beethoven.jpg')

miles = Author.create(name: 'Miles Davis')
miles.image.attach(io: File.open(Rails.root.join('tmp/images/miles.jpg')), filename: 'miles.jpg')

john = Author.create(name: 'John Coltrane')
john.image.attach(io: File.open(Rails.root.join('tmp/images/john.jpg')), filename: 'john.jpg')

daft_punk = Author.create(name: 'Daft Punk')
daft_punk.image.attach(io: File.open(Rails.root.join('tmp/images/daft_punk.jpg')), filename: 'daft_punk.jpg')

the_prodigy = Author.create(name: 'The Prodigy')
the_prodigy.image.attach(io: File.open(Rails.root.join('tmp/images/the_prodigy.jpg')), filename: 'the_prodigy.jpg')

kanye = Author.create(name: 'Kanye West')
kanye.image.attach(io: File.open(Rails.root.join('tmp/images/kanye.jpg')), filename: 'kanye.jpg')

jay_z = Author.create(name: 'Jay-Z')
jay_z.image.attach(io: File.open(Rails.root.join('tmp/images/jay_z.jpg')), filename: 'jay_z.jpg')

# Albums

puts "Creating albums..."
queen_album = Album.create(name: 'Bohemian Rhapsody', release_date: '1973-01-01', category: rock, author: queen)
queen_album.image.attach(io: File.open(Rails.root.join('tmp/images/queen_album.jpg')), filename: 'queen_album.jpg')

katy_perry_album = Album.create(name: 'Teenage Dream', release_date: '2010-08-24', category: pop, author: katy_perry)
katy_perry_album.image.attach(io: File.open(Rails.root.join('tmp/images/katy_perry_album.png')), filename: 'katy_perry_album.jpg')

mozart_album = Album.create(name: 'Ave verum corpus', release_date: '1791-07-17', category: classical, author: mozart)
mozart_album.image.attach(io: File.open(Rails.root.join('tmp/images/mozart_album.png')), filename: 'mozart_album.jpg')

miles_album = Album.create(name: 'Kind of Blue', release_date: '1959-08-17', category: jazz, author: miles)
miles_album.image.attach(io: File.open(Rails.root.join('tmp/images/miles_album.jpg')), filename: 'miles_album.jpg')

john_album = Album.create(name: 'A Love Supreme', release_date: '1964-01-01', category: jazz, author: john)
john_album.image.attach(io: File.open(Rails.root.join('tmp/images/john_album.jpg')), filename: 'john_album.jpg')

the_prodigy_album = Album.create(name: 'The Fat of the Land', release_date: '1997-09-02', category: electronic, author: the_prodigy)
the_prodigy_album.image.attach(io: File.open(Rails.root.join('tmp/images/the_prodigy_album.jpg')), filename: 'the_prodigy_album.jpg')

jay_z_album = Album.create(name: 'The Blueprint', release_date: '2001-06-18', category: hip_hop, author: jay_z)
jay_z_album.image.attach(io: File.open(Rails.root.join('tmp/images/jay_z_album.png')), filename: 'jay_z_album.jpg')


# Songs

puts "Creating songs..."
queen_song = Song.create(name: 'Bohemian Rhapsody', duration_ms: 355000, age: 1973, category: rock, album: queen_album)
queen_song.image.attach(io: File.open(Rails.root.join('tmp/images/queen_song.jpg')), filename: 'queen_song.jpg')
queen_song.audio.attach(io: File.open(Rails.root.join('tmp/audio/queen_song.mp3')), filename: 'queen_song.mp3')

katy_perry_song = Song.create(name: 'E.T.', duration_ms: 302000, age: 2010, category: pop, album: katy_perry_album)
katy_perry_song.image.attach(io: File.open(Rails.root.join('tmp/images/katy_perry_song.png')), filename: 'katy_perry_song.jpg')
katy_perry_song.audio.attach(io: File.open(Rails.root.join('tmp/audio/katy_perry_song.mp3')), filename: 'katy_perry_song.mp3')

mozart_song = Song.create(name: 'Ave verum corpus', duration_ms: 19000, age: 1791, category: classical, album: mozart_album)
mozart_song.image.attach(io: File.open(Rails.root.join('tmp/images/mozart_album.png')), filename: 'mozart_song.jpg')
mozart_song.audio.attach(io: File.open(Rails.root.join('tmp/audio/mozart_song.mp3')), filename: 'mozart_song.mp3')

miles_song = Song.create(name: 'Blue in green', duration_ms: 339000, age: 1959, category: jazz, album: miles_album)
miles_song.image.attach(io: File.open(Rails.root.join('tmp/images/miles_album.jpg')), filename: 'miles_song.jpg')
miles_song.audio.attach(io: File.open(Rails.root.join('tmp/audio/miles_song.mp3')), filename: 'miles_song.mp3')

john_song = Song.create(name: 'Acknowledgement', duration_ms: 463000, age: 1964, category: jazz, album: john_album)
john_song.image.attach(io: File.open(Rails.root.join('tmp/images/john_album.jpg')), filename: 'john_song.jpg')
john_song.audio.attach(io: File.open(Rails.root.join('tmp/audio/john_song.mp3')), filename: 'john_song.mp3')

the_prodigy_song = Song.create(name: 'Smack my bitch up', duration_ms: 343000, age: 1997, category: electronic, album: the_prodigy_album)
the_prodigy_song.image.attach(io: File.open(Rails.root.join('tmp/images/the_prodigy_album.jpg')), filename: 'the_prodigy_song.jpg')
the_prodigy_song.audio.attach(io: File.open(Rails.root.join('tmp/audio/the_prodigy_song.mp3')), filename: 'the_prodigy_song.mp3')

jay_z_song = Song.create(name: "The ruler's back", duration_ms: 228000, age: 2001, category: hip_hop, album: jay_z_album)
jay_z_song.image.attach(io: File.open(Rails.root.join('tmp/images/jay_z_album.png')), filename: 'jay_z_song.jpg')
jay_z_song.audio.attach(io: File.open(Rails.root.join('tmp/audio/jay_z_song.mp3')), filename: 'jay_z_song.mp3')

# Song Authors

puts "Attaching authors to songs..."
queen_song.authors << queen
katy_perry_song.authors << katy_perry
katy_perry_song.authors << kanye
mozart_song.authors << mozart
miles_song.authors << miles
john_song.authors << john
the_prodigy_song.authors << the_prodigy
jay_z_song.authors << jay_z