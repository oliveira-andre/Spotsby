class AddSearchTextToSongs < ActiveRecord::Migration[8.0]
  def up
    enable_extension "pg_trgm"
    add_column :songs, :search_text, :text
    add_index :songs, :search_text, using: :gin, opclass: :gin_trgm_ops
    # Albums, authors and playlists are also searched on their own name (NameSearch).
    add_index :albums, :name, using: :gin, opclass: :gin_trgm_ops, name: "index_albums_on_name_trgm"
    add_index :authors, :name, using: :gin, opclass: :gin_trgm_ops, name: "index_authors_on_name_trgm"
    add_index :playlists, :name, using: :gin, opclass: :gin_trgm_ops, name: "index_playlists_on_name_trgm"

    # Backfill with the same text Song#build_search_text builds. update_column, not
    # save!, so the deploy can't trip on validations, touch every album and author, or
    # queue clip jobs.
    Song.reset_column_information
    Song.includes(:album, :authors).find_each do |song|
      song.send(:build_search_text)
      song.update_column(:search_text, song.search_text)
    end
  end

  def down
    remove_index :playlists, name: "index_playlists_on_name_trgm"
    remove_index :authors, name: "index_authors_on_name_trgm"
    remove_index :albums, name: "index_albums_on_name_trgm"
    remove_index :songs, :search_text
    remove_column :songs, :search_text
    # pg_trgm is left enabled: other code may rely on it, and it costs nothing idle.
  end
end
