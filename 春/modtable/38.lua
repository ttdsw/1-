local SeedImages = {"asparagus_seeds", "carrot_seeds", "corn_seeds", "dragonfruit_seeds", "durian_seeds",
                    "eggplant_seeds", "garlic_seeds", "onion_seeds", "pepper_seeds", "pomegranate_seeds",
                    "potato_seeds", "pumpkin_seeds", "tomato_seeds", "watermelon_seeds"}

local xml = resolvefilepath("images/myseeds.xml")
t_util:IPairs(SeedImages, function(v)
    RegisterInventoryItemAtlas(xml, v .. ".tex")
end)

Mod_ShroomMilk.Setting.SeedImages = true
