local size = GetModConfigData("sw_peopleNum")
if size == 6 then
    return
else
    TUNING.MAX_SERVER_SIZE = size
end
