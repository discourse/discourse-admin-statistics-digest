require_relative './spec_helper'

RSpec.describe AdminStatisticsDigest::ActiveUser do

  # setup user
  let!(:user_with_5_topics_and_5_posts_at_80_days_ago) do
    Timecop.freeze 80.days.ago do
      user = Fabricate.create(:user, name: 'user_with_5_topics_and_5_posts_at_80_days_ago')
      5.times do
        topic = create_topic(user: user)
        create_post(user: user, topic: topic)
      end
      user
    end
  end

  let!(:user_with_5_topics_and_5_posts_at_25_days_ago) do
    Timecop.freeze 25.days.ago do
      user = Fabricate.create(:user, name: 'user_with_5_topics_and_5_posts_at_25_days_ago')
      5.times do
        topic = create_topic(user: user)
        create_post(user: user, topic: topic)
      end
      user
    end
  end


  let!(:user_with_3_topics_and_3_posts_at_50_days_ago) do
    Timecop.freeze 50.days.ago do
      user = Fabricate.create(:user, name: 'user_with_3_topics_and_3_posts_at_50_days_ago')
      3.times do
        topic = create_topic(user: user)
        create_post(user: user, topic: topic)
      end
      user
    end
  end

  let!(:user_with_10_posts_at_10_days_ago) do
    topic = Topic.last
    Timecop.freeze 10.days.ago do
      user = Fabricate.create(:user, name: 'user_with_10_posts_at_10_days_ago')
      10.times { create_post(user: user, topic: topic) }
      user
    end
  end


  let!(:user_with_8_posts_at_5_days_ago) do
    topic = Topic.last
    Timecop.freeze 5.days.ago do
      user = Fabricate.create(:user, name: 'user_with_8_posts_at_5_days_ago')
      8.times { create_post(user: user, topic: topic) }
      user
    end
  end

  let!(:user_with_12_topics_at_20_days_ago) do
    Timecop.freeze 20.days.ago do
      user = Fabricate.create(:user, name: 'user_with_12_topics_at_20_days_ago')
      12.times { create_topic(user: user) }
      user
    end
  end

  let!(:user_with_3_topics_at_3_days_ago) do
    Timecop.freeze 3.days.ago do
      user = Fabricate.create(:user, name: 'user_with_3_topics_at_3_days_ago')
      3.times { create_topic(user: user) }
      user
    end
  end

  let!(:admin_with_4_topics_at_12_days_ago) do
    Timecop.freeze 12.days.ago do
      admin = Fabricate.create(:user, admin: true, name: 'Admin - admin_with_4_topics_at_12_days_ago')
      4.times { create_topic(user: admin) }
      admin
    end
  end

  let!(:moderator_with_7_topics_at_yesterday) do
    Timecop.freeze Date.yesterday do
      moderator = Fabricate.create(:user, moderator: true, name: 'Moderator - moderator_with_7_topics_at_yesterday')
      7.times { create_topic(user: moderator) }
      moderator
    end
  end

  describe 'test db data' do
    it 'db has 7 user, 1 moderator, and 1 admin' do
      expect(User.where('admin = false AND moderator = false').length).to eq(7)
      expect(User.staff.where('id != ?', Discourse::SYSTEM_USER_ID).where('admin').length).to eq(1)
      expect(User.staff.where('id != ?', Discourse::SYSTEM_USER_ID).where('moderator').length).to eq(1)
    end
  end
  # end setup user

  describe 'include_staff filter' do
    context 'value is true' do
      let! :result do
        described_class.build { include_staff }.execute
      end

      it 'includes staff users to query' do
        expect(result[:data].size).to eq(9)
      end

      context 'value is false' do
        let! :result do
          active_user = described_class.new do
            include_staff false
          end
          active_user.execute
        end

        it 'excludes staff users from query' do
          expect(result[:data].size).to eq(7)
        end
      end

      context 'include_staff filter is empty' do
        let! :result do
          described_class.new.execute
        end

        it 'exclude staff users from query as default' do
          expect(result[:data].size).to eq(7)
        end
      end
    end

    describe 'limit filter' do
      let! :result do
        described_class.build { limit(3) }.execute
      end

      it 'limits query result' do
        expect(result[:data].size).to eq(3)
      end
    end

    describe 'active_range filter' do
      let! :result do
        described_class.build do
          limit 5
          active_range(60.days.ago..20.days.ago)
        end.execute
      end

      it 'adjusts query based user activity date' do
        expect(result[:error]).to be_nil
        expect(result[:data].map { |d| d['user_id'].to_i }.take(2)).to(
          eq([
               user_with_5_topics_and_5_posts_at_25_days_ago.id,
               user_with_3_topics_and_3_posts_at_50_days_ago.id
             ])
        )
      end
    end

    describe 'signed_up_between filter' do
      let! :result do
        described_class.build do
          limit 5
          signed_up_from(30.days.ago)
        end.execute
      end

      it 'adjusts query based user signed up date' do
        expect(result[:error]).to be_nil
        expect(result[:data].map { |d| d['user_id'].to_i }.take(5)).to(
          match_array([
               user_with_12_topics_at_20_days_ago.id,
               user_with_10_posts_at_10_days_ago.id,
               user_with_5_topics_and_5_posts_at_25_days_ago.id,
               user_with_8_posts_at_5_days_ago.id,
               user_with_3_topics_at_3_days_ago.id,
             ])
        )
      end
    end

    describe 'signed_up_between filter', skip: true do
      let! :result do
        described_class.build do
          limit 5
          signed_up_between(from: 30.days.ago, to: 5.days.ago)
        end.execute
      end

      it 'adjusts query based user signed up date' do
        expect(result[:error]).to be_nil
        expect(result[:data].map { |d| d['user_id'].to_i }.take(5)).to(
          match_array([
               user_with_12_topics_at_20_days_ago.id,
               user_with_10_posts_at_10_days_ago.id,
               user_with_5_topics_and_5_posts_at_25_days_ago.id,
               user_with_8_posts_at_5_days_ago.id,
               user_with_3_topics_at_3_days_ago.id,
             ])
        )
      end
    end


  end
end
