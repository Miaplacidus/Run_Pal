require 'spec_helper'

describe RunPal::CreateCommitment do

  before :each do
    RunPal.db.clear_everything
  end

  it 'creates a new commitment' do
    user = RunPal.db.create_user({username:"Isaac Asimov", gender: 2, email: "write@smarty.com"})
    post = RunPal.db.create_post({latitude: 30.25, longitude: -97.75, creator_id: user.id, max_runners: 10, time: Time.now, pace: 3, notes: "Fun!", min_amt: 12.50, age_pref: 3, gender_pref: 0})

    result = subject.run({user_id: user.id, post_id: post.id, amount: 20})
    expect(result.success?).to eq(true)
    expect(result.commit.user_id).to eq(user.id)

  end

end
