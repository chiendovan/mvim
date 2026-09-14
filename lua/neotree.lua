local M = {}

local common_renderers = {
  directory = {
    { "indent" },
    { "icon" },
    { "current_filter" },
    { "name" },
    { "clipboard" },
    { "diagnostics" },
    { "git_status" },
  },

  file = {
    { "indent" },
    { "icon" },
    { "name" },
    { "clipboard" },
    { "diagnostics" },
    { "git_status" },
  },
}

M.init = function()
  require("neo-tree").setup({
    use_popups_for_input = false,
    default_component_configs = {
      container = {
        width = "fit_content",
        enable_character_fade = false,
      },
      indent = {
        with_expanders = true,
        expander_collapsed = "▸",
        expander_expanded = "▾",
      },
      git_status = {
         symbols = {
            added     = "+",
            modified  = "✎",
            deleted   = "−",
            renamed   = "→",
            untracked = "?",
            ignored   = "⊘",
            unstaged  = "●",
            staged    = "✓",
            conflict  = "⚠",
         },
      },
    },

    filesystem = {
      renderers = common_renderers,
    },

    buffers = {
      renderers = common_renderers,
    },

    git_status = {
      renderers = common_renderers,
      window = {
        mappings = {
          ["u"] = "git_unstage_file",
          ["a"] = "git_add_file",
          ["r"] = "git_revert_file",
        },
      },
      commands = {
        git_commit = function(state, and_push)
          local inputs = require("neo-tree.ui.inputs")
          local popups = require("neo-tree.ui.popups")
          local events = require("neo-tree.events")

          inputs.input("Commit message: ", "", function(msg)
            if not msg or msg == "" then
              return
            end

            local cmd = { "git", "commit", "-m", msg }
            local title = "git commit"
            local result = vim.fn.systemlist(cmd)
            if vim.v.shell_error ~= 0 or (#result > 0 and vim.startswith(result[1], "fatal:")) then
              popups.alert("ERROR: git commit", result)
              return
            end
            events.fire_event(events.GIT_EVENT)
            popups.alert(title, result)
          end)
        end,
      },
      components = {
        name = function(config, node, state)
          local result = require("neo-tree.sources.git_status.components").name(config, node, state)
          if node.type == "directory" and node:get_depth() == 1 then
            local branch = vim.fn.system({ "git", "branch", "--show-current" })
            if vim.v.shell_error == 0 then
              branch = branch:gsub("%s+$", "")
              if branch ~= "" then
                result.text = result.text .. "  ->" .. branch
              end
            end
          end
          return result
        end,
      },
    },

    window = {
      position = "float",
      popup = {
        size = {
          width = "60%",
          height = "80%",
        },
      },
      mappings = {
        ["yp"] = function(state)
          local node = state.tree:get_node()

          if node and node.path then
            vim.fn.setreg("+", node.path)
          end
        end,
      },
    },

    event_handlers = {
      {
        event = "file_opened",
        handler = function()
          vim.cmd("Neotree close")
        end,
      },
    },
  })

  vim.api.nvim_create_user_command("Cpath", 
    function()
      local manager = require("neo-tree.sources.manager")
      local state = manager.get_state_for_window()

      if state then
        local node = state.tree:get_node()

        if node and node.path then
          vim.fn.setreg("+", node.path)
          vim.notify("NeoTree Copied: " .. node.path)
          return
        end
      end

      local path = vim.api.nvim_buf_get_name(0)

      if path ~= "" then
        vim.fn.setreg("+", path)
        vim.notify("Nvim Copied: " .. path)
      else
        vim.notify("Current buffer has no file path", vim.log.levels.WARN)
      end
    end,
  {})

end

function M.call()
  require("neo-tree.command").execute({ toggle = true })
end

function M.buffers()
  require("neo-tree.command").execute({ source = "buffers", toggle = true })
end

function M.git_status()
  require("neo-tree.command").execute({ source = "git_status", toggle = true })
end

vim.keymap.set("n", "<Space>e", M.call, { silent = true })
vim.keymap.set("n", "<Space>b", M.buffers, { silent = true })
vim.keymap.set("n", "<Space>g", M.git_status, { silent = true })

M.init()

return M
