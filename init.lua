local config_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
dofile(config_dir .. "/plugin/indent_guide.lua")

local directory_path = "/Users/chiendv/.config/mvim/lua/"
package.path = package.path .. ";" .. directory_path .. "?.lua"
local function require_all_files_in_directory(directory)
    local files = vim.fn.readdir(directory)

    if files then
        for _, file in ipairs(files) do
            if file:match("%.lua$") then
                local module_name = file:gsub("%.lua$", "")
                require(module_name)
            end
        end
    end
end
require_all_files_in_directory(directory_path)

