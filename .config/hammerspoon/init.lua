--
-- For simple keyboard remapping, I'm currently using Karabiner, since it has
-- more low-level control over the keyboard. E.g., Karabiner has `vender_id` to
-- identify keyboards, which is useful for distinguishing between the laptop
-- keyboard and an external keyboard, which Hammerspoon does not.
--

local application = require("hs.application")
local hotkey   = require("hs.hotkey")
local eventtap = require("hs.eventtap")

-- Toggle an application between launching, focusing, and hiding.
local toggle = function(id)
  local app = application.get(id)
  if not app then
    -- There is no running application with the given id.
    application.open(id)
    return
  end

  if not app:isFrontmost() or not app:focusedWindow() then
    -- The application is not frontmost or has no focused window.
    application.launchOrFocusByBundleID(id)
  else
    -- The application is frontmost and has a focused window.
    app:hide()
  end
end

local yabai = function(args)
  return "/opt/homebrew/bin/yabai -m " .. args .. " 2>&1 > /dev/null"
end
local exec = os.execute

-- Create hotkeys with `hs.hotkey.new` instead of `hs.hotkey.bind`.
-- But these hotkeys will not take effect until left-cmd is pressed.
local hotkeys = {
  -- I live in the terminal emulator and the web browser most of the time.
  -- So I need a hotkey to quickly focus on them.
  hotkey.new({ "cmd", "ctrl" }, "j", function()
    toggle("org.alacritty")
  end),
  hotkey.new({ "cmd", "ctrl" }, "k", function()
    toggle("org.mozilla.firefoxdeveloperedition")
  end),
  hotkey.new({ "cmd", "ctrl" }, "h", function()
    toggle("com.openai.chat")
  end),

  -- For window management around, powered by `yabai`, a tiling window manager
  -- for macOS.
  hotkey.new({ "cmd" }, "n", function()
    exec(yabai("space --equalize y-axis"))
  end),
  hotkey.new({ "cmd" }, "m", function()
    exec(
      yabai("space --mirror y-axis")
        .. " && " .. yabai("window --focus largest")
    )
  end),
  hotkey.new({ "cmd" }, ",", function()
    print("cmd-,")
    local script = [[
      yabai=/opt/homebrew/bin/yabai
      jq=/opt/homebrew/bin/jq
      type="$("$yabai" -m query --spaces | "$jq" '.[] | select(.["has-focus"] == true) | .type')"
      if [ "$type" = '"bsp"' ]; then
        "$yabai" -m space --layout stack
      else
        "$yabai" -m space --layout bsp
      fi
    ]]
    exec(script)
  end),
  hotkey.new({ "cmd" }, "h", function()
    exec(yabai("window --focus west"))
  end),
  hotkey.new({ "cmd" }, "j", function()
    exec(yabai("window --focus south"))
  end),
  hotkey.new({ "cmd" }, "k", function()
    exec(yabai("window --focus north"))
  end),
  hotkey.new({ "cmd" }, "l", function()
    exec(yabai("window --focus east"))
  end),
  hotkey.new({ "cmd", "shift" }, "h", function()
    exec(
      yabai("window --resize left:-15:0")
        .. " || " .. yabai("window --resize right:-15:0")
    )
  end),
  hotkey.new({ "cmd", "shift" }, "j", function()
    exec(
      yabai("window --resize bottom:0:15")
        .. " || " .. yabai("window --resize top:0:15")
    )
  end),
  hotkey.new({ "cmd", "shift" }, "k", function()
    exec(
      yabai("window --resize top:0:-15")
        .. " || " .. yabai("window --resize bottom:0:-15")
    )
  end),
  hotkey.new({ "cmd", "shift" }, "l", function()
    exec(
      yabai("window --resize right:15:0")
        .. " || " .. yabai("window --resize left:15:0")
    )
  end),
}

-- This toggles the hotkeys on/off.
-- Use eventtap to detect flag changes only; this puts less strain on
-- Hammerspoon because it isn't having to deal with every single character
-- press.
local activated = false
_et = eventtap.new({ eventtap.event.types.flagsChanged }, function(e)
  local flags = e:rawFlags()
  local masks = eventtap.event.rawFlagMasks
  if flags & masks.deviceLeftCommand > 0 then
    if not activated then
      for _, v in ipairs(hotkeys) do
        v:enable()
      end
      activated = true
    end
  else
    if activated then
      for _, v in ipairs(hotkeys) do
        v:disable()
      end
      activated = false
    end
  end
end):start()
