require 'spec_helper'

describe RunPal::CreateChallenge do

  before :each do
    RunPal.db.clear_everything
  end

  it 'creates a new challenge' do
    user1 = RunPal.db.create_user({username:"Isaac Asimov", gender: 2, email: "isaac@smarty.com"})
    user2 = RunPal.db.create_user({username:"Karl Asimov", gender: 2, email: "karl@smarty.com"})
    circle1 = RunPal.db.create_circle({name: "MakerSquare", admin_id: user1.id, max_members: 30, latitude: 33.99, longitude: -9.34, description: "We teach code.", level: -1})
    circle2 = RunPal.db.create_circle({name: "MassRelevance", admin_id: user2.id, max_members: 30, latitude: -33.49, longitude: -9.22, description: "We ship code", level: -1})
    post = RunPal.db.create_post({ creator_id: user1.id, max_runners: 10, time: Time.now, pace: 3, notes: "Fun!", min_amt: 12.50, age_pref: 3, gender_pref: 0})

    result = subject.run({name: "Maker-Mass Challenge", sender_id: circle1.id, recipient_id: circle2.id, latitude: 30.25, longitude: -97.75, creator_id: user1.id, max_runners: 10, time: Time.now, pace: 3, notes: "Fun!", min_amt: 12.50, age_pref: 3, gender_pref: 0})
    expect(result.success?).to eq(true)
    expect(result.challenge.name).to eq("Maker-Mass Challenge")

  end

end
