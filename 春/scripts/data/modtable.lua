









local m_table = {}

m_table.load = {
    {
        {"sw_cave"},
        {"洞穴时钟", "Cave Clock"},
        1,
    },
    {
        "sw_mainboard",
        "功能面板",
        2
    },{
        {"sw_beauti", },
        {"滤镜", "画质渲染", "色彩调节", "Post Processor Disabler"},
        {85, 3},
    },{
        {"sw_shutup", },
        {"去除噪音", "噪音", "noise"},
        4
    },
    {
        {"sw_unlock",},
        "本地指令",
        5
    },
    {
        "sw_error",
        {"日志位置", "崩溃处理","错误追踪", "Starve Debugger", "崩溃"},
        6
    },
    {
        "sw_mapseed",
        {"地图种子"},
        7,
    },
    {
        {"sw_cookbook",},
        {"烹饪指南", "Cookbook",},
        8,
    },
    {
        {"sw_C"},
        {"视角变换", "OB视角","Observer Camera",},
        9,
    },{
        "range_board",
        "范围追踪",
        10,
    },{
        "ex_board",
        "物品管理器",
        11
    },{
        "sw_hjsl_unequip",
        {"装备脱落", "自动脱"},
        12
    },
    {
        {"sw_autorow", },
        {"自动划船", "lazy control", "rowing"},
        13,
    },
    {
        {"sw_small",},
        {"小功能绑定", "快捷小功能"},
        14,
    },
    {
        "sw_multiscreen",
        "壁纸模式",
        15,
    },{
        {"sw_autosort", "ex_board"},
        {"物品整理", "自动分类", "autosort", "整理"},
        16
    },
    {
        {"sw_atreel",},
        "自动钓鱼",
        17,
    },
    {
        {"sw_wagstaff",},
        {"静电任务", "风暴任务"},
        18,
    },
    {
        {"sw_wildfires",},
        {"野火警告","自燃警告"},
        19,
    },
    {
        {"sw_fishname",},
        {"海钓助手","自动海钓","海钓大师","Auto fishing","鱼群名字", "鱼群显示"},
        20,
    },
    {
        {"sw_shadowheart"},
        {"雕像制作", "上个雕像","黑心工厂"},
        21,
    },
    {
        {"sw_DAG"},
        {"自动做档案馆任务", "档案馆任务", "ArchiveTask","档案馆标记","档案馆标记"},
        {22,},
    },
    {
        {"sw_hideshell"},
        {"隐藏贝壳"},
        {23},
    },
    {
        {"sw_skinHistory"},
        {"礼物记录","局内开启皮肤","Skins extender","自动开礼物","挂机开皮肤","super AFK"},
        {
            24,
        },
    },
    {
        {"skinqueue_plus"},
        {"重复皮肤分解","重复皮肤", "SkinQueue"},
        25,
    },
    {
        {"sw_rescue"},
        {"一键Rescue"},
        26,
    },
    {
        "sw_craft",
        {"制作栏信息","More Crafting Details"},
        27,
    },
    {
        {"sw__keytweak"},
        {"键位提示"},
        28,
    },
    {
        {"sw_wanda"},
        {"旺达快捷键", "wanda keybinds"},
        29,
    },
    {
        {"rt_take", "sw_right"},
        {"配方拿取", "右键拿取", "右键加强", "记忆力"},
        30,
    },
	{
        {"sw_autoread"},
        {"自动读书","薇克巴顿辅助","老奶奶辅助", "book reader"},
        31,
    },
    {
        {"map_preview","sw_map"},
        {"地形预览", "地图扫描", "地形扫描"},
        32,
    },
    {
        "sw_roll",
        {"精确拿取", "快速拿取", "快捷拿取", "Item Scroller"},
        33,
    },
    {
        "sw_log",
        {"更新日志"},
        34,
    },
    
    {
        "sw_watering",
        {"自动浇灌",},
        36,
    },
    {
        "sw_space",
        {"空格过滤器","空格筛选器", "pickup filter"},
        37,
    },
    {
        {"sw_mySeedTex"},
        {"种子贴图还原", "种子贴图", "Item icon", "高清图标"},
        38,
    },
    {
        "sw_planthant",
        {"耕种图鉴", "耕作先驱","园艺帽","Gardeneer Hat"},
        39,
    },
    {
        "sw_nutrients",
        {"耕作先驱", "园艺帽","Gardeneer Hat"},
        40,
    },
    {
        "sw_stat",
        {"状态变化", "Stat Change Display"},
        41,
    },
    {
        "sw_wall",
        {"不要打墙", "No wall attack", "打墙", "高级控制", "Advanced Attack", "Advanced Controls"},
        42,
    },
    {
        "sw_tele",
        "传送标记",
        43,
    },
    {
        {},
        {"呼吸栏"},
        44,
    },
    {
        "sw_folder",
        {"模组目录",},
        45,
    },
    {
        "sw_nickname",
        {"昵称显示", "nickname"},
        46,
    },
    {
        "sw_peopleNum",
        {"增加人数上限", "人数上限"},
        47,
    },
    {
        "sw_hideshadow",
        {"隐藏影怪", "骨盔禁用影怪", "骨盔：去除影怪","Bone Helm","骨头头盔"},
        48,
    },
    {
        "sw_double",
        {"队列双击", "快速双击", "双击转移", "双击丢弃", "lazy control",},
        49,
    },
    {
        {"sw_castspell", "sw_right"},
        {"精准施法", "取消施法限制", "右键加强", "lazy control",},
        50,
    },
    {
        {"sw_cane"},
        {"自动切手杖", "切个手杖"},
        51,
    },
    {
        {"sw_newrepair"},
        {"按键修复", "快捷修复", "物品修复",},
        52,
    },
    {
        {},
        {"记忆力+", "记忆力"},
        53,
    },
    {
        {"sw_suggest"},
        {"礼包购买建议", "看线轴", "性价比"},
        54,
    },
    {
        {"sw_server",},
        {"模拟重连", "快速重连", "lazy control"},
        55,
    },
    {
        "mid_search",
        {"中键加强", "记忆力"},
        56,
    },
    {
        "sw_autocook1",
        {"自动烹饪", "auto cooking","Crockpot Repeater", "自动做饭","记忆力"},
        57,
    },
    {
        {"huxi_buff","sw_timer"},
        {"BUFF 倒计时", "记忆力"},
        58,
    },
    {
        {"huxi_nightmare","sw_timer"},
        {"暴动倒计时", "梦魇 倒计时", "暴动时钟", "nightmare phase indicator"},
        59,
    },
    {
        {"huxi_rain", "sw_timer"},
        {"降雨倒计时", "天气预报", "Rain Predict"},
        60,
    },
    {
        {"huxi_boss","sw_timer"},
        {"BOSS 倒计时", "记忆力"},
        61,
    },
    {
        {"huxi_warn","sw_timer"},
        {"怪物预警", "怪物警告", "Advanced Warning"},
        62,
    },
    {
        {},
        {"地图图标+", "地图图标", "MapIcon", "扫描地图", "地形预览", "扫描地形"},
        63,
    },
    {
        {"map_animal","sw_map"},
        {"更多生物图标", "Extended Map Icons", },
        64,
    },
    {
        {"huxi_clock","sw_timer"},
        {"当前时间", "现实时钟",},
        65,
    },
    {
        {"huxi_pos","sw_timer"},
        {"当前坐标", "现实坐标",},
        66,
    },
    {
        {"map_wormhole", "sw_map"},
        {"虫洞标记", },
        67,
    },
    {
        {"map_gogo", "sw_map"},
        {"自动寻路", },
        68,
    },
    {
        {"map_alter", "sw_map"},
        {"定位天体", },
        69,
    },
    {
        {"sw_right"},
        {"右键加强"},
        70,
    },
    {
        {"rt_dirtpile", "sw_right", "sw_timer"},
        {"自动翻脚印", "右键加强", "lazy control", "Animal Tracker"},
        71,
    },
    {
        {"rt_double", "sw_right"},
        {"双击传送"},
        72,
    },
    {
        {"sw_modplayer", "sw_right"},
        {"模组角色图标", "角色存档图标", "Show Character Portrait"},
        73,
    },
    {
        {"sw_skinpreset"},
        {"皮肤预设套装",},
        74,
    },
    {
        "sw_starfish",
        {"海星清远古", "Moonnight 定制功能"},
        75,
    },
    {
        "sw_mynote",
        {"我的笔记", "呼吸 定制功能"},
        76,
    },
    {
        "sw_jh_repair",
        {"驯牛辅助", "训牛辅助", },
        77,
    },
    {
        {"sw_autopush",},
        {"自动推挤", "保持跟随", "自动跟随", "如影随形", "keep following",},
        78
    },
    {
        {"sw_winch",},
        {"打捞定位", "Ynou 定制功能",},
        79
    },
    {
        {"sw_indicator",},
        {"方向指示", "虾远山 定制功能",},
        80
    },
    {
        {"sw_compass",},
        {"指南针", "猫头军师 定制功能",},
        81
    },
    {
        {"sw_hjsl_repair",},
        {"自动修复", "物品修复", "快捷修复"},
        82
    },
    {
        {"sw_pinyin",},
        {"拼音搜索"},
        83
    },
    {
        {"sw_beebox",},
        {"火中取蜜"},
        84
    },
    {
        {"sw_drop",},
        {"按键丢弃"},
        86
    },
    {
        {"sw_autoeat",},
        {"自动吃饭", "自动干饭", "记忆力"},
        87
    },
    {
        {"sw_catcher",},
        {"静电任务+", "静电任务", "风暴任务"},
        88,
    },{
        {"sw_showhkit",},
        {"浅海显示", "地皮显示"},
        89
    },{
        {"sw_fishkill",},
        {"自动宰杀", "自动宰鱼"},
        90
    },
    {
        "sw_butterfly",
        {"自动抓蝴蝶"},
        91,
    },
    {
        "sw_autowork",
        {"自动工作"},
        92,
    },{
        "sw_tumbleweed",
        {"风滚草预测", "风滚草"},
        93,
    },
    {
        {"map_cavehole", "sw_map"},
        {"洞穴楼梯标记", "虫洞和天坑", "独行长路", "alone"},
        94,
    },
}


m_table.ban = {"鸡尾酒-永远的神", "生存辅助", "小白客户端", "超级客户端", "Keeth客户端",
"作弊器", "一键客户端", "Pusheen", "欺诈客户端", "合集-客户端", "蘑菇慕斯"}

m_table.close = {}

m_table.clash = {}

return m_table
