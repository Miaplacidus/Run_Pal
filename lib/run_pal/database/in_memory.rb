module RunPal
  module Database
    class InMemory

      def initialize(env)
        clear_everything
      end

      def clear_everything
        @challenge_id_counter = 0
        @circle_id_counter = 0
        @commit_id_counter = 0
        @post_id_counter = 0
        @user_id_counter = 0
        @wallet_id_counter = 0
        @challenges = {} #Key: challenge_id, Value: challenge_obj_attrs hash
        @circles = {} # Key: circle_id, Value: circle_obj_attrs hash
        @commits = {} # Key: commit_id, Value: commit_obj_attrs hash
        @posts = {} # Key: post_id, Value: post_obj_attrs hash
        @users = {} # Key: user_id, Value: user_obj_attrs hash
        @wallets = {} # Key: user_id, Value: wallet_obj_attrs hash
      end

      def create_challenge(attrs)
        cid = @challenge_id_counter+=1
        pid = @post_id_counter+=1
        post_attrs = attrs.clone
        post_attrs[:id] = pid

        # Remove challenge-specific data from post_attrs
        post_attrs.delete_if do |name, value|
          setter = "#{name}="
          !RunPal::Post.method_defined?(setter)
        end
        @posts[pid] = post_attrs
        RunPal::Post.new(post_attrs)

        # Remove post-specific data from attrs
        attrs[:id] = cid
        attrs[:post_id] = pid
        attrs.delete_if do |name, value|
          setter = "#{name}"
          !RunPal::Challenge.method_defined?(setter)
        end
        @challenges[cid] = attrs
        challenge = RunPal::Challenge.new(attrs)
      end

      def get_challenge(id)
        challenge = @challenges[id] ? RunPal::Challenge.new(@challenges[id]) : nil
      end

      def get_circle_rec_challenges(circle_id)
       challenge_arr = []
        @challenges.each do |cid, attrs|
          if attrs[:recipient_id] == circle_id
            challenge_arr << RunPal::Challenge.new(attrs)
          end
        end
        challenge_arr
      end

      def get_circle_sent_challenges(circle_id)
       challenge_arr = []
        @challenges.each do |cid, attrs|
          if attrs[:sender_id] == circle_id
            challenge_arr << RunPal::Challenge.new(attrs)
          end
        end
        challenge_arr
      end


      def update_challenge(id, attrs)
          if @challenges[id]
          # Remove challenge-specific attributes from attrs
          post_changes = attrs.clone
          post_changes.delete_if do |name, value|
            setter = "#{name}="
            !RunPal::Post.method_defined?(setter)
          end
          pid = @challenges[id][:post_id]
          post_attrs = @posts[pid]
          post_attrs.merge!(post_changes)

          attrs.delete_if do |name, value|
            setter = "#{name}="
            !RunPal::Challenge.method_defined?(setter)
          end
        end
        challenge_attrs = @challenges[id]
        challenge_attrs.merge!(attrs)

        RunPal::Challenge.new(challenge_attrs)
      end

      def delete_challenge(id)
        @challenges.delete(id)
      end

      def create_circle(attrs)
        id = @circle_id_counter+=1
        attrs[:id] = id
        circle = RunPal::Circle.new(attrs)
        @circles[id] = attrs
        circle
      end

      def get_circle(id)
        circle = @circles[id] ? RunPal::Circle.new(@circles[id]) : nil
      end

      def get_circle_names
        name_hash = {}
        @circles.each do |cid, attrs|
          name_hash[attrs[:name]] = true
        end
        name_hash
      end

      def all_circles
        circle_arr = []
        @circles.values.each do |attrs|
          circle_arr << RunPal::Circle.new(attrs)
        end
        circle_arr
      end

      def circles_filter_location(user_lat, user_long, radius)
        mi_to_km = 1.60934
        earth_radius = 6371
        circle_arr = []
        radius = radius * mi_to_km
        @circles.each do |cid, attrs|
          circle_lat = attrs[:latitude]
          circle_long = attrs[:longitude]
          distance = Math.acos(Math.sin(user_lat) * Math.sin(circle_lat) + Math.cos(user_lat) * Math.cos(circle_lat) * Math.cos(circle_long - user_long)) * earth_radius
          if distance <= radius
            circle_arr << RunPal::Circle.new(attrs)
          end
        end
        circle_arr
      end

      def circles_filter_full
        circle_arr = []
        circle_attributes = @circles.values
        circle_attributes.each do |attr_hash|

          if attr_hash[:member_ids].length < attr_hash[:max_members]
            circle_arr << RunPal::Circle.new(attr_hash)
          end

        end
        circle_arr
      end

      def update_circle(id, attrs)
        circle_attrs = @circles[id]
        circle_members = circle_attrs[:member_ids]
        circle_attrs.merge!(attrs)
        if attrs[:member_ids]
          circle_attrs[:member_ids] += circle_members
        end
        RunPal::Circle.new(circle_attrs)
      end

      def create_commit(attrs)
        id = @commit_id_counter+=1
        attrs[:id] = id
        @commits[id] = attrs
        RunPal::Commitment.new(attrs)
      end

      def get_commit(id)
        attrs = @commits[id]
        return nil if attrs.nil?
        RunPal::Commitment.new(attrs)
      end

      def get_commits_by_user(user_id)
        commits = @commits.values.select do |commit_attrs|
          commit_attrs[:user_id] == user_id
        end
        commits.map do |commit_attrs|
          RunPal::Commitment.new(commit_attrs)
        end
      end

      def update_commit(id, attrs)
        commit_attrs = @commits[id]
        commit_attrs.merge!(attrs)
        RunPal::Commitment.new(commit_attrs)
      end

      def create_post(attrs)
        id = @post_id_counter+=1
        attrs[:id] = id
        @posts[id] = attrs
        RunPal::Post.new(attrs)
      end

      def get_post(id)
        post = @posts[id] ? RunPal::Post.new(@posts[id]) : nil
      end

      def get_circle_posts(circle_id)
        post_arr = []
        @posts.each do |pid, attrs|
          if attrs[:circle_id] == circle_id
            post_arr << RunPal::Post.new(attrs)
          end
        end
        post_arr
      end

      def all_posts
        post_arr = []
        @posts.each do |pid, attrs|
          post_arr << RunPal::Post.new(attrs)
        end
        post_arr
      end

      def get_committed_users(post_id)
        post_attrs = @posts[post_id]
        post_attrs[:committer_ids]
      end

      def get_attendees(post_id)
        post_attrs = @posts[post_id]
        post_attrs[:attend_ids]
      end

      def update_post(id, attrs)
        post_attrs = @posts[id]
        post_attrs.merge!(attrs)
        RunPal::Post.new(post_attrs)
      end

      def delete_post(id)
        @posts.delete(id)
      end

      def posts_filter_age(age)
        post_arr = []
        post_attributes = @posts.values
        post_attributes.each do |attr_hash|
          if attr_hash[:age_pref] == age
            post_arr << RunPal::Post.new(attr_hash)
          end
        end
        post_arr
      end

      def posts_filter_gender(gender)
        post_arr = []
        post_attributes = @posts.values
        post_attributes.each do |attr_hash|
          if attr_hash[:gender_pref] == gender
            post_arr << RunPal::Post.new(attr_hash)
          end
        end
        post_arr
      end

      def posts_filter_location(user_lat, user_long, radius)
        mi_to_km = 1.60934
        earth_radius = 6371
        post_arr = []
        radius = radius * mi_to_km
        @posts.each do |pid, post_attrs|
          post_lat = post_attrs[:latitude]
          post_long = post_attrs[:longitude]
          distance = Math.acos(Math.sin(user_lat) * Math.sin(post_lat) + Math.cos(user_lat) * Math.cos(post_lat) * Math.cos(post_long - user_long)) * earth_radius
          if distance <= radius
            post_arr << RunPal::Post.new(post_attrs)
          end
        end
        post_arr
      end

      def posts_filter_pace(pace)
        post_arr = []
        post_attributes = @posts.values
        post_attributes.each do |attr_hash|
          if attr_hash[:pace] == pace
            post_arr << RunPal::Post.new(attr_hash)
          end
        end
        post_arr
      end

      def posts_filter_time(start_time, end_time)
        post_arr = []
        post_attributes = @posts.values
        post_attributes.each do |attr_hash|
          if start_time < attr_hash[:time] && attr_hash[:time] < end_time
            post_arr << RunPal::Post.new(attr_hash)
          end
        end
        post_arr
      end

      def create_user(attrs)
        id = @user_id_counter+=1
        attrs[:id] = id
        @users[id] = attrs
        RunPal::User.new(attrs)
      end

      def get_user(id)
        attrs = @users[id]
        return nil if attrs.nil?
        RunPal::User.new(attrs)
      end

      def get_user_by_email(email)
        check = nil
        @users.each do |user_id, attrs|
          if attrs[:email] == email
            check = attrs
          end
        end
        return check
      end

      def all_users
        users_arr = []
        @users.each do |uid, attrs|
          users_arr << RunPal::User.new(attrs)
        end
        users_arr
      end

      def update_user(user_id, attrs)
        user_attrs = @users[user_id]
        user_attrs.merge!(attrs)
        RunPal::User.new(user_attrs)
      end

      def delete_user(id)
        @users.delete(id)
      end

      def from_omniauth(auth)
        gender = 0
        if auth.extra.raw_info.gender == 'female'
          gender = 1
        elsif auth.extra.raw_info.gender == 'male'
          gender = 2
        end

        user_attrs = @users.values
        user = user_attrs.select{|attr_hash| attr_hash[:provider] == auth.provider && attr_hash[:fbid] == auth.uid}
        user = user[0]

        if user == nil
          user = create_user({username: auth.info.first_name, email: auth.info.email, gender: gender, bday: auth.extra.raw_info.birthday, fbid: auth.uid, oauth_token: auth.credentials.token, oauth_expires_at: Time.at(auth.credentials.expires_at) })
        else
          user = update_user(user_attrs[:id], {username: auth.info.first_name, email: auth.info.email, gender: gender, bday: auth.extra.raw_info.birthday, fbid: auth.uid, oauth_token: auth.credentials.token, oauth_expires_at: Time.at(auth.credentials.expires_at)})
        end

        user
      end

      def create_wallet(attrs)
        id = @wallet_id_counter+=1
        attrs[:id] = id
        @wallets[id] = attrs
        RunPal::Wallet.new(attrs)
      end

      def get_wallet_by_userid(user_id)
        attrs = @users[user_id]
        user = RunPal::User.new(attrs)
        wallet_attrs = @wallets[user.id]
        return nil if wallet_attrs.nil?
        wallet = RunPal::Wallet.new(wallet_attrs)
      end

      def update_wallet(user_id, attrs)
        user_attrs = @users[user_id]
        user = RunPal::User.new(user_attrs)
        wallet_attrs = @wallets[user.id]
        wallet_attrs.merge!(attrs)
        RunPal::Wallet.new(wallet_attrs)
      end

      def update_wallet_balance(user_id, transaction)
        wallet_attrs = @wallets[user_id]
        wallet_attrs[:balance] += transaction
        RunPal::Wallet.new(wallet_attrs)
      end

      def delete_wallet(user_id)
        @wallets.delete(user_id)
      end

    end

  end
end
