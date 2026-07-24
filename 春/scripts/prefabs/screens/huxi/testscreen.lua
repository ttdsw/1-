local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local ImageButton = require "widgets/imagebutton"
local Image = require "widgets/image"
local Text = require "widgets/text"
local TextBtn = require "widgets/textbutton"
local t_util = require "util/tableutil"

local TestScreen = Class(Screen, function(self, screen_data)
    Screen._ctor(self, "TestScreen")
end)


return TestScreen
