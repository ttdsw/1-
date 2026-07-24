local HxNote = require "widgets/huxi/huxi_note"
local save_id, str_title, icon = "sw_mynote", "我的笔记", "skill_icon_bw"
local default_data = {}
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)
local funcs = {
    SavePos = function(pos)
        fn_save("posx")(pos.x)
        fn_save("posy")(pos.y)
    end
}

local function GetUIData()
    local ui_data = {}
    local note_data = m_util:GetData("NOTE")
    t_util:Pairs(note_data, function(dot, data)
        local info = {
            id = data.id,
            label = data.title,
            default = true,
            hover = STRINGS.LMB .."查看 " .. data.title,
            fn = function()
                m_util:PopShowScreen()
                h_util:AddAnonUI(HxNote(funcs, save_data, note_data, dot))
            end,
            priority = data.priority,
        }
        
        if data.icon then
            info = t_util:MergeMap(info, {
                type = "imgstr",
                prefab = data.icon,
            })
        end
        table.insert(ui_data, info)
        t_util:SortIPair(ui_data)
    end)

    return ui_data
end

local fn_left = function()
    m_util:AddBindShowScreen({
        title = str_title,
        id = save_id,
        data = GetUIData()
    })()
end

m_util:AddBindConf(save_id, fn_left, nil, {str_title, icon,
                                           STRINGS.LMB .. '饥荒游戏笔记  ' .. STRINGS.RMB .. '重置笔记位置',
                                           true, fn_left, function()
                                            fn_save("posx")(false)
                                            fn_save("posy")(false)
                                           end, 3000})


m_util:AddNoteData("farmplant", "季节农作物", 400, 700, [[
春
1:1    土豆:番茄
1:2    火龙果:番茄
1:1:1    大蒜:洋葱:火龙果
1:2:2    洋葱:土豆:玉米/芦笋

夏
1:2    辣椒/火龙果:番茄
1:1:1    辣椒/火龙果:大蒜:洋葱

秋
1:1    土豆:番茄
1:2    辣椒:番茄
1:1:1    大蒜:洋葱:辣椒
1:2:2    洋葱:土豆:玉米

冬
1:1:1    南瓜:土豆:芦笋
1:2:2    大蒜:土豆:南瓜
]], {icon = "tomato_oversized"})

m_util:AddNoteData("fertilizer", "肥料查询", 400, 500, [[
催长剂	堆肥	粪肥	肥料
  1	    0	    0	  坏小鱼
  2	    0	    0	  坏鱼
  4	    0	    0	  催长剂
  0	    1	    0	  腐烂物
  0	    2	    0	  腐烂蛋
  0	    3	    0	  堆肥
  3	    4	    3	  肥料包
  0	    0	    1	  便便
  0	    0	    2	  鸟粪
  0	    0	    2	  便便桶
  1	    1	    1	  格罗姆
  1	    4	    1	  树果酱
]], {icon = "fertilizer"})

m_util:AddNoteData("farmcook", "种地推荐菜谱", 500, 500, [[
2菜
萨尔萨酱 洋葱+番茄
素食堡 洋葱+叶肉
烤面筋 树枝+土豆*1

2.5菜
鸡尾酒 冰+番茄/芦笋

3菜
奶油土豆泥 大蒜+2土豆

血量：茄子	土豆	番茄	石榴	火龙果
饥饿：南瓜	玉米	榴莲	火龙果
]], {icon = "cookbook"})

m_util:AddNoteData("hermit_crab", "寄居蟹任务", 600, 600, [[
1、第一次房屋：切割机碎片*10 木板*10 萤火虫*1
2、第二次房屋：大理石*10 石砖*5 荧光果*3
3、第三次房屋：月岩*10 绳子*5 地毯地板*5
4、种植10朵花：蝴蝶*10
5、打捞水下垃圾：木板*2 石砖*1 绳子*2 漂流瓶*1
6、清理食人花：春季之后
7、晾晒6个食物：生肉*6（海带已经不行了）
8、种植8个浆果并施肥：浆果丛*8 肥料*8
9、放置座椅：石砖*1(提升好感需其他座椅，遗迹椅子用来解锁锯马)
10、喂食花瓣沙拉：花沙拉*1
11、下雪时给予保暖：犬牙背心~熊皮背心 等
12、下雨时给予雨伞：花伞~眼球伞 等
13、足够重的海鱼*5
14、任意足够重的四季鱼
合计：切割机碎片*10 木板*17 萤火虫*1，大理石*10 石砖*7 荧光果*3 月岩*10 绳子*7 地毯地板*5 蝴蝶*10 漂流瓶*1 生肉*6 燧石*4 浆果从*8 肥料*8
]], {icon = "hermitcrab"})

m_util:AddNoteData("relic", "开局远古", 300, 400, [[
木头*4 石头*4 黄金*9 木板*4 石砖*4 树枝*23 草*22 荧光果*2 肉*2，猪皮*4
]], {icon = "ancient_altar"})

m_util:AddNoteData("wx_78", "wx78 生物扫描仪", 500, 700, [[
1强化电路（50生命）普通蜘蛛
2超级强化电路（150生命）护士蜘蛛
1处理器电路（40SAN）蝴蝶月蛾
2超级处理器电路（100SAN+）影怪
3豆豆电路（100SAN++）蜂后
3合唱盒电路（SAN+）帝王蟹寄居蟹
1胃增益电路（40饥饿）猎犬
2超级胃增益电路（100饥饿+）熊大缀食者
6加速电路（25%）兔子
2超级加速电路（25%-）战车远古守护者
3热能电路（保温）龙蝇火猎犬
3制冷电路（制冷）巨鹿冰猎犬
2电气化电路（30反伤）电羊
4光电电路（夜视）鼹鼠
3照明电路（发光）章鱼荧光虫洞穴蠕虫
]], {icon = "wx78"})

m_util:AddNoteData("alter", "月亮虹吸器", 600, 250, [[
1阶段：废料*4 月熠*5 电子元件*2
2阶段：废料*4 月熠*10 注能月亮碎片*10
3阶段：约束静电*1 天体宝球*1 注能月亮碎片*20 
合计：宝球*1 静电*1 元件*2 月熠*15 废料*8 碎片*30
]], {icon = "moon_device"})

m_util:AddNoteData("crabking", "帝王蟹增益", 500, 400, [[
蓝宝石：+冰冻抗性 +冰屏生命值、击碎时间
红宝石：+炮塔攻击力、+造成船漏洞大小
黄宝石：+炮塔数量、生命值 -被撞掉血
紫宝石：+蟹卫数量、生命值、催眠抗性
橙宝石：+回血量，+打断回血所需次数
绿宝石：+蟹钳数量、生命值、伤害

珍珠的珍珠：所有宝石数量+3
彩色宝石：所有宝石数量+1
]], {icon = "crabking"})

if not m_util:IsHuxi() then
    return
end
m_util:AddNoteData("showme", "控制台方法", 800, 500, [[
    打印数据：FEP(t) FEP_M(t) FEP_K(t) FEP_I(t)
    监听动画：fepAnim(ent, cd, stop)
    获取附近实体：nearEnt_s?(prefab, range, allowTags, banTags, allowAnims, banAnims, func)
    获取物品栏物品：nearSlot(slot)
    打印距离：printDist(ent1, ent2)
    获取标签：getTags(ent, isclone)
    比较标签：compTags(tags1, tags2)
    循环任务：loopStart(cd, func), loopStop
    监听RPC：watchRPC()
    监听事件：watchEvent()
    物品栏UI:getui(slot), ESlot(ui)
]], {icon = icon, priority = 999})
