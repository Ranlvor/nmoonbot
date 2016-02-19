lanes = require"lanes".configure{
  protect_allocator: true
  verbose_errors: true
}

tf_irc=lanes.gen "*", require "threads.irc"

last_behaviour="threads.init_behaviour"
tf_behaviour=lanes.gen "*", require last_behaviour

li_comm=lanes.linda!
li_ctrl=lanes.linda!

la_irc=tf_irc li_comm
la_behaviour=tf_behaviour li_comm, li_ctrl

li_ctrl\set "mainloop_stayAlive", true
while true == li_ctrl\get "mainloop_stayAlive"
  k,v=li_ctrl\receive 10, "mainloop_cmd"
  if k == "mainloop_cmd"
    switch v.cmd
      when "reload"
        b=v.behaviour and ("threads.behaviours." .. v.behaviour) or last_behaviour
        print "loading behaviour:",b
        package.loaded[last_behaviour]=nil
        package.loaded[b]=nil
        tf_behaviour=lanes.gen "*", require b
        la_behaviour\cancel 0, true, 1
        la_behaviour=tf_behaviour li_comm, li_ctrl
        last_behaviour=b
      when "reconnect"
        print "reconnecting irc…"
        package.loaded["threads.irc"]=nil
        tf_irc=lanes.gen "*", require "threads.irc"
        la_irc\cancel 0, true, 1
        la_irc=tf_irc li_comm
