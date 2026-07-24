
local cmw = require "widgets/redux/craftingmenu_widget"
local PM = require "data/pinyin_char_map"
local _v = cmw.ValidateRecipeForSearch
if not _v then return end
cmw.ValidateRecipeForSearch = function(self, name, ...)
    _v(self, name, ...)
    if name and self.searched_recipes and not self.searched_recipes[name] and type(self.search_text) == "string" then
        
        local recipe = AllRecipes[name]
        if recipe then
            local name_upper = string.upper(recipe.name)
            local product = recipe.product
            local product_upper = string.upper(product)
            local str = STRINGS.NAMES[name_upper] or STRINGS.NAMES[product_upper]
            if str and PM:Find(str, self.search_text) then
                self.searched_recipes[name] = true
            end
        end
    end
end
