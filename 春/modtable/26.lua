local function fn()
    TheNet:SendSlashCmdToServer("rescue")
end
m_util:AddBindConf("sw_rescue", fn, true,
    {"发送Rescue", "atrium_key", "按下后会发送/rescue  或者  /救命", true, fn, nil, 7995})
