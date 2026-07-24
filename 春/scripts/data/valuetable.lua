local t_util = require "util/tableutil"
local V = {}


V.RGB = {
    
    ['红色'] = RGB(255, 0, 0),
    ['橙色'] = RGB(255, 125, 0),
    ['黄色'] = RGB(255, 255, 0),
    ['绿色'] = RGB(0, 255, 0),
    ['青色'] = RGB(0, 255, 255),
    ['蓝色'] = RGB(0, 0, 255),
    ['紫色'] = RGB(255, 0, 255),
    ['灰色'] = RGB(75, 75, 75),

    ["呼吸紫"] = RGB(100, 0, 255),
    ["呼吸橙"] = RGB(255, 100, 0),
    ["呼吸蓝"] = RGB(0, 200, 255),
    ["亮蓝色"] = RGB(75, 75, 255),
    ["呼吸白"] = RGB(175, 175, 175),
    
    ['粉色'] = RGB(255, 192, 203),
    ['浅紫红色'] = RGB(219, 112, 147),
    
    ['鲜肉色'] = RGB(250, 128, 114),
    ['深红色'] = RGB(220, 20, 60),
    ['耐火砖色'] = RGB(178, 34, 34),
    ['暗红色'] = RGB(139, 0, 0),
    
    ['番茄色'] = RGB(255, 99, 71),
    ['珊瑚色'] = RGB(255, 127, 80),
    
    ['卡其色'] = RGB(240, 230, 140),
    
    ['玉米绸色'] = RGB(255, 228, 196),
    ['实木色'] = RGB(222, 184, 135),
    ['茶色'] = RGB(210, 180, 140),
    ['玫瑰褐色'] = RGB(188, 143, 143),
    ['沙棕色'] = RGB(244, 164, 96),
    ['金黄色'] = RGB(218, 165, 32),
    ['秘鲁色'] = RGB(205, 133, 63),
    ['巧克力色'] = RGB(210, 105, 30),
    ['重磅马色'] = RGB(139, 69, 19),
    ['棕色'] = RGB(165, 42, 42),
    
    ['春绿色'] = RGB(0, 255, 127),
    
    ['青绿色'] = RGB(64, 224, 208),
    ['墨绿色'] = RGB(0, 128, 128),
    
    ['淡蓝色'] = RGB(135, 206, 250),
    ['矢车菊蓝色'] = RGB(100, 149, 237),
    
    ['淡紫色'] = RGB(230, 230, 250),
    ['蓟色'] = RGB(216, 191, 216),
    ['洋李色'] = RGB(221, 160, 221),
    ['中紫色'] = RGB(147, 112, 219),
    
    ['白色'] = RGB(255, 255, 255),
    ['原色/黑色'] = RGB(0, 0, 0),
    ['黑色'] = {.1, .1, .1, 1},
    ['标红'] = RGB(207, 61, 61),
    ['标绿'] = RGB(59, 222, 99),
    ['标紫'] = RGB(184, 87, 198),
    ['标棕'] = RGB(127, 76, 51),
    ['半白'] = RGB(128, 128, 128),
    ['漆白'] = RGB(243, 244, 243),
}
V.RGB_datatable = t_util:PairToIPair(V.RGB, function(c)
    return {
        data = c,
        description = c
    }
end)

V.WRGB = {
    ['蓝色'] = RGB(149, 191, 242),
    ['黄色'] = RGB(222, 222, 99),
    ['绿色'] = RGB(59, 222, 99),
    ['珊瑚橙色'] = RGB(216, 60, 84),
    ['草绿色'] = RGB(129, 168, 99),
    ['青绿色'] = RGB(150, 206, 169),
    ['魔力紫'] = RGB(206, 145, 192),
    ['呼吸蓝'] = RGB(113, 125, 194),
    ['呼吸黄'] = RGB(205, 191, 121),
    ['品红色'] = RGB(170, 85, 129),
    ['呼吸绿'] = RGB(150, 201, 206),
    ['呼吸橙'] = RGB(206, 150, 100),
    ['橙色'] = RGB(208, 120, 86),
    ['紫色'] = RGB(125, 81, 156),
    
    
    ['西红柿红色'] = RGB(205, 79, 57),
    ['麻色'] = RGB(255, 165, 79),
    ['梅红色'] = RGB(205, 150, 205),
    ['实木色'] = RGB(205, 170, 125),
    ['红色'] = RGB(238, 99, 99),
    ['秘鲁色'] = RGB(205, 133, 63),
    ['暗紫色'] = RGB(139, 102, 139),
    ['鸡蛋壳色'] = RGB(252, 230, 201),
    ['鲑红色'] = RGB(255, 140, 105),
    ['巧克力色'] = RGB(255, 127, 36),
    ['紫红色'] = RGB(139, 71, 93),
    ['沙褐色'] = RGB(244, 164, 96),
    ['棕色'] = RGB(165, 42, 42),
    ['陶坯色'] = RGB(205, 183, 158),
    ['浅紫红色'] = RGB(255, 130, 171),
    ['金黄色'] = RGB(255, 193, 37),
    ['玫瑰褐色'] = RGB(255, 193, 193),
    ['淡紫色'] = RGB(255, 225, 255),
    ['粉色'] = RGB(255, 192, 203),
    ['柠檬黄色'] = RGB(255, 250, 205),
    ['火砖色'] = RGB(238, 44, 44),
    ['浅金色'] = RGB(255, 236, 139),
    ['呼吸紫'] = RGB(171, 130, 255),
    ['蓟色'] = RGB(205, 181, 205)
}

V.gifttype_table = {
    DAILY_GIFT = "每日礼物",
    DEFAULT = "感谢赏玩",
    TWITCH_DROP = "直播掉落",
    YOTP = "猪王之年",
    YOTB = "皮弗牛娄之年",
    LUNAR = "火鸡之年",
    VARG = "座狼之年",
    ANRARG = "远古手杖和箱子",
    ARG = "远古火炬",
    CUPID = "情人节",
    ONI = "缺氧",
    WINTER = "冬季盛宴",
    ROT2 = "贝壳鱼类",
    TOT = "改潮换代",
    HAMLET = "哈姆雷特",
    HOTLAVA = "炽热熔岩",
    ROG = "巨人国赏玩",
    ROGR = "巨人国购买",
    SW = "海难赏玩",
    SWR = "海难购买",
    GORGE = "暴食",
    GORGE_TOURNAMENT = "暴食锦标赛",
    STORE = "商店购买"
}

V.WRGB_datatable = t_util:PairToIPair(V.WRGB, function(c)
    return {
        data = c,
        description = c
    }
end)

V.frame_datatable = t_util:IPairFilter({1, 2, 3, 5, 10, 15, 20, 30, 45, 60, 75, 90}, function(i)
    return {
        data = i,
        description = i .. "帧"
    }
end)

V.range_datatable = t_util:BuildNumInsert(5, 80, 5, function(i)
    return {
        data = i,
        description = i
    }
end)

V.weekday_en_to_cn = {
    Sunday = "星期日",
    Monday = "星期一",
    Tuesday = "星期二",
    Wednesday = "星期三",
    Thursday = "星期四",
    Friday = "星期五",
    Saturday = "星期六"
}

local Fonts = {DEFAULTFONT, DIALOGFONT, TITLEFONT, UIFONT, BUTTONFONT, NEWFONT, NEWFONT_SMALL, NEWFONT_OUTLINE,
               NEWFONT_OUTLINE_SMALL, NUMBERFONT, TALKINGFONT, TALKINGFONT_WORMWOOD, TALKINGFONT_TRADEIN,
               TALKINGFONT_HERMIT, CHATFONT, HEADERFONT, CHATFONT_OUTLINE, SMALLNUMBERFONT, BODYTEXTFONT, CODEFONT,
               FALLBACK_FONT, FALLBACK_FONT_FULL, FALLBACK_FONT_OUTLINE, FALLBACK_FONT_FULL_OUTLINE
            }
V.font_datatable = {}
t_util:IPairs(Fonts, function(font)
    if not table.contains(V.font_datatable, font) then
        table.insert(V.font_datatable, font)
    end
end)
V.font_datatable = t_util:IPairToIPair(V.font_datatable, function(font)
    return {data = font, description = font}
end)
return V
