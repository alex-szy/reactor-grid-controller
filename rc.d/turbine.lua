local network = require("network")

function start()
  network.startService()
end

function stop()
  network.stopService()
end