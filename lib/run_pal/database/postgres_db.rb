module RunPal
  module Database
    class PostgresDB

       def initialize(env)
        config_path = File.join(File.dirname(__FILE__), '../../../db/config.yml')

        ActiveRecord::Base.establish_connection(
          YAML.load_file(config_path)[env]
        )
      end

      def clear_everything
        Circle.destroy_all
        Challenge.destroy_all
        Commitment.destroy_all
        Post.destroy_all
        User.destroy_all
        Wallet.destroy_all
      end

      class Circle < ActiveRecord::Base
        # Differentiate between reg users and administrator
        belongs_to :admin, class_name:"User", foreign_key:"admin_id"

        has_many :circle_users
        has_many :users, :through => :circle_users

        has_many :posts

        has_many :sent_challenges, class_name: "Challenge", foreign_key:"sender_id"
        has_many :received_challenges, class_name: "Challenge", foreign_key:"recipient_id"
      end

      class Challenge < ActiveRecord::Base
        belongs_to :post

        # Differentiate between sender and recipient
        belongs_to :sender, class_name: "Circle", foreign_key: "sender_id"
        belongs_to :recipient, class_name: "Circle", foreign_key: "recipient_id"
      end

      class Commitment < ActiveRecord::Base
        belongs_to :post
        belongs_to :user
      end

      class User < ActiveRecord::Base
        has_many :adm_circles, class_name:"Circle"

        has_many :circle_users
        has_many :circles, :through => :circle_users

        has_many :commitments

        has_many :created_posts, class_name:"Posts", foreign_key:"creator_id"

        has_many :post_users
        has_many :posts, :through => :post_users

        has_one :wallet
      end

      class Wallet < ActiveRecord::Base
        belongs_to :user
      end

      class CircleUsers < ActiveRecord::Base
        belongs_to :circle
        belongs_to :user
      end

      class Post < ActiveRecord::Base
        has_many :commitments

        has_one :challenge
        # differentiate between creator and committers
        belongs_to :creator, class_name:"User", foreign_key:"creator_id"

        has_many :post_users
        has_many :users, :through => :post_users

        belongs_to :circle
      end

      class PostUsers < ActiveRecord::Base
        belongs_to :post
        belongs_to :user
      end

      def create_challenge(attrs)
        post_attrs = attrs.clone

        post_attrs.delete_if do |name, value|
          setter = "#{name}"
          !RunPal::Post.method_defined?(setter)
        end

        ar_post = Post.create(post_attrs)

        attrs.delete_if do |name, value|
          setter = "#{name}"
          !RunPal::Challenge.method_defined?(setter)
        end

        attrs.merge!({post_id: ar_post.id})
        ar_challenge = Challenge.create(attrs)
        RunPal::Challenge.new(ar_challenge.attributes)
      end

      def get_challenge(id)
        ar_challenge = Challenge.where(id: id).first
        return nil if ar_challenge == nil
        RunPal::Challenge.new(ar_challenge.attributes)
      end

      def get_circle_sent_challenges(circle_id)
        ar_circle = Circle.where(id: circle_id).first
        sent_chal = ar_circle.sent_challenges.order(:created_at)
      end

      def get_circle_rec_challenges(circle_id)
        ar_circle = Circle.where(id: circle_id).first
        received_chal = ar_circle.received_challenges.order(:created_at)
      end

      def update_challenge(id, attrs)
        post_attrs = attrs.clone

        post_attrs.delete_if do |name, value|
          setter = "#{name}"
          !RunPal::Post.method_defined?(setter)
        end

        ar_challenge = Challenge.where(id: id).first

        post_id = ar_challenge.post_id
        ar_post = Post.where(id: post_id).first
        ar_post.update_attributes(post_attrs)

        attrs.delete_if do |name, value|
          setter = "#{name}"
          !RunPal::Challenge.method_defined?(setter)
        end

        ar_challenge.update_attributes(attrs)

        updated_chal = Challenge.where(id: id).first
        RunPal::Challenge.new(updated_chal.attributes)
      end

      def delete_challenge(id)
        Challenge.where(id: id).first.delete
      end

      def create_circle(attrs)

        ar_circle = Circle.create(attrs)
        CircleUsers.create(circle_id: ar_circle.id, user_id: ar_circle.admin_id)

        attrs_w_members = ar_circle.attributes
        attrs_w_members[:member_ids] = [ar_circle.admin_id]

        RunPal::Circle.new(attrs_w_members)
      end

      def get_circle(id)
        ar_circle = Circle.where(id: id).first
        return nil if ar_circle == nil

        ar_members = CircleUsers.where(circle_id: ar_circle.id)
        members = []

        ar_members.each do |ar_member|
          members << ar_member.id
        end

        attrs_w_members = ar_circle.attributes
        attrs_w_members[:member_ids] = members
        RunPal::Circle.new(attrs_w_members)
      end

      def get_circle_names
        ar_circles = Circle.all
        name_hash = {}

        ar_circles.each do |ar_circle|
          name_hash[ar_circle.name] = true
        end

        name_hash
      end

      def all_circles
        Circle.all.map do |ar_circle|
          RunPal::Circle.new(ar_circle.attributes)
        end
      end

      def circles_filter_location(user_lat, user_long, radius)
        mi_to_km = 1.60934
        earth_radius = 6371
        ar_circles = Circle.all
        circle_arr = []

        ar_circles.each do |ar_circle|
          circle_lat = ar_circle.latitude
          circle_long = ar_circle.longitude
          distance = Math.acos(Math.sin(user_lat) * Math.sin(circle_lat) + Math.cos(user_lat) * Math.cos(circle_lat) * Math.cos(circle_long - user_long)) * earth_radius

          if distance <= radius
            circle_arr << RunPal::Circle.new(ar_circle.attributes)
          end
        end
        circle_arr
      end

      def circles_filter_full
        ar_circles = Circle.all
        circle_arr = []

        ar_circles.each do |ar_circle|
          num_members = CircleUsers.where(circle_id: ar_circle.id).length

          if num_members < ar_circle.max_members
            circle_arr << RunPal::Circle.new(ar_circle.attributes)
          end
        end

        circle_arr
      end

      def circles_filter_full_by_location (user_lat, user_long, radius)
       nearby_circles = circles_filter_location(user_lat, user_long, radius)

       nearby_circles.each do |circle|
        num_members = circle.max_member


       end

      end

      def update_circle(id, attrs)
        Circle.where(id: id).first.update_attributes(attrs)
        updated_circle = Circle.where(id: id).first
        RunPal::Circle.new(updated_circle.attributes)
      end

      def add_user_to_circle(id, user_id)
        ar_circle_user = CircleUsers.create({circle_id: id, user_id: user_id})
        circle_user = CircleUsers.where("circle_id = ? AND user_id = ?", id, user_id).first

        ar_user = User.where(id: circle_user.user_id).first

        RunPal::User.new(ar_user.attributes)
      end

      def create_commit(attrs)
        ar_commit = Commitment.create(attrs)
        RunPal::Commitment.new(ar_commit.attributes)
      end

      def get_commit(id)
        ar_commit = Commitment.where(id: id).first
        return nil if ar_commit == nil
        RunPal::Commitment.new(ar_commit.attributes)
      end

      def get_commits_by_user(user_id)
        ar_commits = Commitment.where(user_id: user_id)
      end

      def update_commit(id, attrs)
        Commitment.where(id: id).first.update_attributes(attrs)
        updated_commit = Commitment.where(id: id).first
        RunPal::Commitment.new(updated_commit.attributes)
      end

      def create_post(attrs)
        ar_post = Post.create(attrs)
        RunPal::Post.new(ar_post.attributes)
      end

      def get_post(id)
        ar_post = Post.where(id: id).first
        return nil if ar_post == nil
        RunPal::Post.new(ar_post.attributes)
      end

      def get_circle_posts(circle_id)
        ar_circle = Circle.where(id: circle_id).first
        ar_circle.posts
      end

      def all_posts
        ar_posts = Post.all

        ar_posts.map do |ar_post|
          RunPal::Post.new(ar_post.attributes)
        end
      end

      def get_committed_users(post_id)
        ar_post = Post.where(id: post_id).first
        ar_commits = ar_post.commitments

        commit_arr = ar_commits.map do |ar_commit|
          RunPal::Commitment.new(ar_commit.attributes)
        end

        commit_arr.map &:user_id
      end

      def get_attendees(post_id)
        ar_post = Post.where(id: post_id).first
        ar_commits = ar_post.commitments.where(fulfilled: true)

        commit_arr = ar_commits.map do |ar_commit|
          RunPal::Commitment.new(ar_commit.attributes)
        end

        commit_arr.map &:user_id
      end

      def update_post(id, attrs)
        Post.where(id: id).first.update_attributes(attrs)
        updated_post = Post.where(id: id).first
        RunPal::Post.new(updated_post.attributes)
      end

      def delete_post(id)
        Post.where(id: id).first.delete
      end

      def posts_filter_age(age)
        ar_posts = Post.where(age_pref: age)
        post_arr = []

        ar_posts.each do |ar_post|
          post_arr << RunPal::Post.new(ar_post.attributes)
        end
        post_arr
      end

      def posts_filter_gender(gender)
        ar_posts = Post.where(gender_pref: gender)
        post_arr = []

        ar_posts.each do |ar_post|
          post_arr << RunPal::Post.new(ar_post.attributes)
        end
        post_arr
      end

      def posts_filter_location(user_lat, user_long, radius)
        mi_to_km = 1.60934
        earth_radius = 6371
        ar_posts = Post.all
        post_arr = []

        ar_posts.each do |ar_post|
          post_lat = ar_post.latitude
          post_long = ar_post.longitude
          distance = Math.acos(Math.sin(user_lat) * Math.sin(post_lat) + Math.cos(user_lat) * Math.cos(post_lat) * Math.cos(post_long - user_long)) * earth_radius

          if distance <= radius
            post_arr << RunPal::Post.new(ar_post.attributes)
          end
        end
        post_arr
      end

      def posts_filter_pace(pace)
        ar_posts = Post.where(pace: pace)
        post_arr = []

        ar_posts.each do |ar_post|
          post_arr << RunPal::Post.new(ar_post.attributes)
        end
        post_arr
      end

      def posts_filter_time(start_time, end_time)
        post_arr = []
        ar_posts = Post.all

        ar_posts.each do |ar_post|
          if ar_post.time > start_time && ar_post.time < end_time
            post_arr << RunPal::Post.new(ar_post.attributes)
          end
        end
        post_arr
      end

      def create_user(attrs)
        ar_user = User.create(attrs)
        RunPal::User.new(ar_user.attributes)
      end

      def create_from_omniauth(auth)
        User.where(fbid: auth.uid).first_or_initialize.tap do |user|
          # user.provider = auth.provider
          user.fbid = auth.uid
          user.username = auth.info.first_name
          user.oauth_token = auth.credentials.token
          user.oauth_expires_at = Time.at(auth.credentials.expires_at)
          user.img = auth.info.image

          fb_gender = auth.extra.raw_info.gender

          if fb_gender == 'female'
            user.gender = 1
          elsif fb_gender == 'male'
            user.gender = 2
          else
            user.gender = 0
          end

          user.save!
        end

        ar_user = User.where(fbid: auth.slice(:uid)).first
        RunPal::User.new(ar_user.attributes)
      end

      def get_user(id)
        ar_user = User.where(id: id).first
        return nil if !ar_user
        RunPal::User.new(ar_user.attributes)
      end

      def get_user_by_fbid(fbid)
        ar_user = User.where(fbid: fbid).first
        return nil if !ar_user
        RunPal::User.new(ar_user.attributes)
      end

      def get_user_by_email(email)
        ar_user = User.where(email: email).first
        return nil if !ar_user
        RunPal::User.new(ar_user.attributes)
      end

      def all_users
        User.all.map do |ar_user|
          RunPal::User.new(ar_user.attributes)
        end
      end

      def update_user(user_id, attrs)
        User.where(id: user_id).first.update_attributes(attrs)
        updated_user = User.where(id: user_id).first
        RunPal::User.new(updated_user.attributes)
      end

      def delete_user(id)
        User.where(id: id).first.delete
      end

      def create_wallet(attrs)
        ar_wallet = Wallet.create(attrs)
        RunPal::Wallet.new(ar_wallet.attributes)
      end

      def get_wallet_by_userid(user_id)
        ar_wallet = Wallet.where(user_id: user_id).first
        return nil if ar_wallet == nil
        RunPal::Wallet.new(ar_wallet.attributes)
      end

      def update_wallet_balance(user_id, transaction)
        ar_wallet = Wallet.where(user_id: user_id).first
        ar_balance = ar_wallet.balance
        updated_bal = ar_balance + transaction

        ar_wallet.update_attributes({balance: updated_bal})
        updated_wallet = Wallet.where(user_id: user_id).first

        RunPal::Wallet.new(updated_wallet.attributes)
      end

      def delete_wallet(user_id)
        ar_wallet = Wallet.where(user_id: user_id).first.delete
      end

      def create_session(attrs)
        sid = SecureRandom.uuid
        ar_session = Session.create({session_key: sid, user_id: attrs[:user_id]})
        session = RunPal::Session.new(id: ar_session.id, session_key: ar_session.session_key, user_id: ar_session.user_id)
      end

      def get_session(key)
        ar_session = Session.where(session_key: key).first
        return nil if ar_session == nil
        session = RunPal::Session.new(ar_session.attributes)
      end

      def delete_session(key)
        ar_session = Session.where(session_key: key)
        Session.destroy(ar_session.id) if get_session(key)
      end

    end
  end
end
