-- Let Bluetooth nodes suspend when idle so other hosts (phone) can take over A2DP.
-- Overrides the hardcoded node.pause-on-idle=false in
-- /usr/share/wireplumber/scripts/monitors/bluez.lua
bluez_monitor.rules = {
  {
    matches = {
      { { "node.name", "matches", "bluez_output.*" } },
      { { "node.name", "matches", "bluez_input.*" } },
    },
    apply_properties = {
      ["node.pause-on-idle"] = true,
      ["session.suspend-timeout-seconds"] = 5,
    },
  },
}
