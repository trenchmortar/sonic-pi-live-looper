# Live Looper Library with TouchOSC Control (beta-1)
# filename: lib-live-looper-plus-feedback-touchosc.rb

# TODO: THINGS TO DO

# Check problem with live loop :metro
# From touchosc create live loop with length and name
# set current_metro, ":metro" + track1_len (=> :metro8) for
# metronome loop and sync param live_loop :track1

# complete feedback section

# solve problem: if track_len initially 4, :metro will also be
# thus the playback loop will initially be synchronised with :metro
# if e. g. track1_len = 8 this loop will play 4 beats to early because
# synchronised with a :metro of 4 beats

# Go button: let only be the record section (and whatever is necessary)
# be dependant on reevaluation; all that can be should be done by
# the control script

# check issue with recording amp 


use_osc get(:ip), get(:port)

use_bpm get(:my_bpm)

t1 = buffer[:track1, get(:track1_len)]
t2 = buffer[:track2, get(:track2_len)]
t3 = buffer[:track3, get(:track3_len)]
t4 = buffer[:track4, get(:track4_len)]
tfb = buffer[:tfb, 8]

# Get/set track to be armed
live_loop :t1 do
  use_real_time
  c = sync "/osc/looper/track_arm/2/1"
  set :track1, c[0]
  set :track_len, get(:track1_len)
  # set current metronom identifier
  set :sync_metro, ("metro" + get(:track_len).to_s).to_sym
  #puts "ARM 1: #{get(:sync_metro)} ---"
end

live_loop :t2 do
  use_real_time
  c = sync "/osc/looper/track_arm/2/2"
  set :track2, c[0]
  set :track_len, get(:track2_len)
  set :sync_metro, ("metro" + get(:track_len).to_s).to_sym
  #puts "ARM 2: #{get(:sync_metro)} ---"
  end

live_loop :t3 do
  use_real_time
  c = sync "/osc/looper/track_arm/1/1"
  set :track3, c[0]
  set :track_len, get(:track3_len)
  set :sync_metro, ("metro" + get(:track_len).to_s).to_sym
  #puts "ARM 3: #{get(:sync_metro)} ---"
end

live_loop :t4 do
  use_real_time
  c = sync "/osc/looper/track_arm/1/2"
  set :track4, c[0]
  set :track_len, get(:track4_len)
  set :sync_metro, ("metro" + get(:track_len).to_s).to_sym
  #puts "ARM 4: #{get(:sync_metro)} ---"
end

# Get/set metronom volume
live_loop :m_vol do
  use_real_time
  c = sync "/osc/looper/metro_vol"
  set :metro_vol, c[0]
end
live_loop :m do
  use_real_time
  c = sync "/osc/looper/metro"
  set :metro_toggle, c[0]
end

# set metronom according to track currently armed
live_loop :beat do
  sleep 1
end

live_loop :metro, sync: :beat do

  f = get(:track_len) - 1
  sample :elec_tick, amp: get(:metro_vol) * get(:metro_vol_master), rate: 1.25 if get(:metro_toggle) == 1
  sleep 1
  f.times do
    sample :elec_tick, amp: get(:metro_vol) * get(:metro_vol_master), rate: 1 if get(:metro_toggle) == 1
    sleep 1
  end
end

live_loop get(:sync_metro), sync: :metro do
  sleep get(:track_len)
  stop # run only only to start syncing
end

# Get/set playback volume
live_loop :t1_vol do
  use_real_time
  c = sync "/osc/looper/track1_vol"
  set :track1_vol, c[0]
end
live_loop :t2_vol do
  use_real_time
  c = sync "/osc/looper/track2_vol"
  set :track2_vol, c[0]
end
live_loop :t3_vol do
  use_real_time
  c = sync "/osc/looper/track3_vol"
  set :track3_vol, c[0]
end
live_loop :t4_vol do
  use_real_time
  c = sync "/osc/looper/track4_vol"
  set :track4_vol, c[0]
end

# Record track 1
if get(:track1) == 1.0
  in_thread sync: get(:sync_metro) do
    #puts "RECORD T1: #{get(:sync_metro)} ---"
    with_fx :record, buffer: t1, pre_amp: get(:rec_level) do
      osc "/looper/track1_rec", 1
      live_audio :audio_in1, stereo: true
    end
    sleep get(:track1_len)
    live_audio :audio_in1, :stop
    osc "/looper/track_arm/2/1", 0
    osc "/looper/track1_rec", 0
    set :track1, 0
  end
end
# Record track 2
if get(:track2) == 1.0
  in_thread sync: get(:sync_metro) do
    #puts "RECORD T2: #{get(:sync_metro)} ---"
    with_fx :record, buffer: t2, pre_amp: get(:rec_level) do
      osc "/looper/track2_rec", 1
      live_audio :audio_in2, stereo: true
    end
    sleep get(:track2_len)
    live_audio :audio_in2, :stop
    osc "/looper/track_arm/2/2", 0
    osc "/looper/track2_rec", 0
    set :track2, 0
  end
end
# Record track 3
if get(:track3) == 1.0
  in_thread sync: get(:sync_metro) do
    #puts "RECORD T3: #{get(:sync_metro)} ---"
    with_fx :record, buffer: t3, pre_amp: get(:rec_level) do
      osc "/looper/track3_rec", 1
      live_audio :audio_in3, stereo: true
    end
    sleep get(:track3_len)
    live_audio :audio_in3, :stop
    osc "/looper/track_arm/1/1", 0
    osc "/looper/track3_rec", 0
    set :track3, 0
  end
end
# Record track 4
if get(:track4) == 1.0
  in_thread sync: get(:sync_metro) do
    #puts "RECORD T4: #{get(:sync_metro)} ---"
    with_fx :record, buffer: t4, pre_amp: get(:rec_level) do
      osc "/looper/track4_rec", 1
      live_audio :audio_in4, stereo: true
    end
    sleep get(:track4_len)
    live_audio :audio_in4, :stop
    osc "/looper/track_arm/1/2", 0
    osc "/looper/track4_rec", 0
    set :track4, 0
  end
end

# (Re)Play Tracks
live_loop :play_t1, sync: get(:sync_metro) do
  sample t1, amp: get(:track1_vol)
  sleep get(:track1_len)
end
live_loop :play_t2, sync: get(:sync_metro) do
  sample t2, amp: get(:track2_vol)
  sleep get(:track2_len)
end
live_loop :play_t3, sync: get(:sync_metro) do
  sample t3, amp: get(:track3_vol)
  sleep get(:track3_len)
end
live_loop :play_t4, sync: get(:sync_metro) do
  sample t4, amp: get(:track4_vol)
  sleep get(:track4_len)
end

# # Feedback section
# # Get/set feedback volume = fader delay
live_loop :osc_sync_feedback_vol0 do
  use_real_time
  c = sync "/osc/looper/feedback_vol/1/1"
  if c[0] == 1.0
    set :fb_vol, 0
  end
  puts "-+-+-+- #{get(:fb_vol)} -+-+-+-"
end
live_loop :osc_sync_feedback_vol1 do
  use_real_time
  c = sync "/osc/looper/feedback_vol/2/1"
  if c[0] == 1.0
    set :fb_vol, 1.05
  end
  puts "-+-+-+- #{get(:fb_vol)} -+-+-+-"
end
live_loop :osc_sync_feedback_vol2 do
  use_real_time
  c = sync "/osc/looper/feedback_vol/3/1"
  if c[0] == 1.0
    set :fb_vol, 1.15
  end
  puts "-+-+-+- #{get(:fb_vol)} -+-+-+-"
end
live_loop :osc_sync_feedback_vol3 do
  use_real_time
  c = sync "/osc/looper/feedback_vol/4/1"
  if c[0] == 1.0
    set :fb_vol, 1.25
  end
  puts "-+-+-+- #{get(:fb_vol)} -+-+-+-"
end
live_loop :osc_sync_feedback_vol4 do
  use_real_time
  c = sync "/osc/looper/feedback_vol/5/1"
  if c[0] == 1.0
    set :fb_vol, 1.35
  end
  puts "-+-+-+- #{get(:fb_vol)} -+-+-+-"
end
live_loop :osc_sync_feedback_vol5 do
  use_real_time
  c = sync "/osc/looper/feedback_vol/6/1"
  if c[0] == 1.0
    set :fb_vol, 1.45
  end
  puts "-+-+-+- #{get(:fb_vol)} -+-+-+-"
end

live_loop :record_fb, sync: :audible_metro do
  with_fx :record, buffer: tfb, pre_amp: get(:fb_vol), pre_mix: 1 do
    sample tfb, amp: 1
    live_audio :audio_fb
  end
  sleep 8
end

# (Re)Play Tracks
live_loop :play_fb, sync: :metro do
  sample tfb, amp: 1
  sleep 8
end