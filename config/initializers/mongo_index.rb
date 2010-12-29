#added by star, for the index and full-search 
Post.ensure_index(:tags)
Comment.ensure_index(:tags)