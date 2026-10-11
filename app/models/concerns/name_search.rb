# `Model.search(q)` on the record's own `name`: a plain substring match (ILIKE), plus
# pg_trgm word similarity (`<%`) for partial words and small typos. Ranked by word
# similarity, then by whole-name similarity so an exact name beats a longer one that
# contains it. Backed by a GIN trigram index on `name`.
module NameSearch
  extend ActiveSupport::Concern

  included do
    scope :search, ->(q) {
      q = q.to_s.downcase.strip
      column = "#{quoted_table_name}.name"

      where("#{column} ILIKE :pattern OR :q <% #{column}", pattern: "%#{sanitize_sql_like(q)}%", q: q)
        .order(Arel.sql(sanitize_sql_array([ "word_similarity(?, #{column}) DESC, similarity(?, #{column}) DESC", q, q ])))
    }
  end
end
