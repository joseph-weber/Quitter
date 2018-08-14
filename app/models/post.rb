class Post
  # Connect to the database
  DB = PG.connect({
    :host => 'localhost',
    :port => 5432,
    :dbname => 'quitter_app_development'
  })

  #Pulls all the posts along with their user who created it
  def self.all
    results = DB.exec(
      <<-SQL
        SELECT
          posts.*,
          users.avatar,
          users.user_name,
          comments.id AS id_comment,
          comments.comment_content,
          comments.user_id,
          likes.id AS like_id,
          likes.post_id AS likes_post_id,
          likes.user_id AS likes_user_id
        FROM posts
        JOIN users
          ON posts.user_id = users.id
        LEFT JOIN comments
          ON posts.id = comments.post_id
        LEFT JOIN likes
          ON posts.id = likes.post_id
        ORDER BY posts.id DESC;
      SQL
    )
    posts = []
    likes = []
    last_post_id = nil
    results.each do |result|
      if result["id"] != last_post_id
      new_post = {
        "id" => result["id"].to_i,
        "post_content" => result["post_content"],
        "image" => result["image"],
        "user_id" => result["user_id"].to_i,
        "user_name" => result["user_name"],
        "avatar" => result["avatar"],
        "comments" => [],
        "likes" => [],
        "likes_amount" => nil
      }
      posts.push(new_post)
      last_post_id = result["id"]
    end
    comments = []
    last_comment_id = nil
    if result["id_comment"] != last_comment_id
      new_comment = ({
        "id" => result["id_comment"].to_i,
        "comment_content" => result["comment_content"],
        "user_name" => result["user_name"],
        "image" => result["comment_image"]
        })
        posts.last["comments"].push(new_comment)
        last_comment_id = result["id_comment"]
    end
    last_like_id = nil
    if result["like_id"] != last_like_id
      likes = []
      new_like = ({
        "id" => result["like_id"].to_i,
        })
        posts.last["likes"].push(new_like)
        last_like_id = result["like_id"]
    end
  end
  posts.each do |post|
    post["likes"] = post["likes"].uniq
    post["likes_amount"] = post["likes"].length
    post["comments"] = post["comments"].uniq
  end
  return posts
end

  # Pulls one specific Post
  def self.find(id)
    results = DB.exec(
      <<-SQL
        SELECT
          posts.*,
          users.id AS user_id,
          users.user_name,
          users.avatar
        FROM posts
        JOIN users
          ON posts.user_id = users.id
        WHERE posts.id = #{id};
      SQL
    ).first
    return {
      "id" => results["id"].to_i,
      "post_content" => results["post_content"],
      "image" => results["image"],
      "user_id" => results["user_id"].to_i,
      "user_name" => results["user_name"],
      "avatar" => results["avatar"]
    }
  end

  # Create a new Post
  def self.create(opts)
    results = DB.exec(
      <<-SQL
        INSERT INTO posts (post_content, image, user_id)
        VALUES ( '#{opts["post_content"]}', '#{opts["image"]}', #{opts["user_id"]})
        RETURNING id, post_content, image, user_id;
      SQL
    ).first
    return {
      "id" => results["id"].to_i,
      "post_content" => results["post_content"],
      "image" => results["image"],
      "user_id" => results["user_id"].to_i
    }
  end

  # Delete a post at ID
  def self.delete(id)
    results = DB.exec(
      <<-SQL
        DELETE FROM posts WHERE id = #{id};
      SQL
    )
    return { "DELETED" => true }
  end

  # Update a post at ID
  def self.update(id, opts)
    results = DB.exec(
      <<-SQL
        UPDATE posts
        SET post_content = '#{opts["post_content"]}',
            image = '#{opts["image"]}',
            user_id = #{opts["user_id"]}
        WHERE id = #{id}
        RETURNING id, post_content, image, user_id;
      SQL
    ).first
    return {
      "id" => results["id"].to_i,
      "post_content" => results["post_content"],
      "image" => results["image"],
      "user_id" => results["user_id"].to_i
    }
  end
end
