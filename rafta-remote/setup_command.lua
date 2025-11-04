-- setup_command.lua - User command integration for Setup handler
-- This file should be placed at: /home/master/Workspace/plugins/rafta.nvim/plugin/setup.lua

local rafta = require("rafta")

-- Create RaftaSetup user command
vim.api.nvim_create_user_command("RaftaSetup", function(args)
  local success, result = pcall(function()
    return rafta.setup_command(args.fargs)
  end)
  
  if success then
    vim.notify("Setup completed: " .. vim.inspect(result), vim.log.levels.INFO)
  else
    vim.notify("Setup failed: " .. tostring(result), vim.log.levels.ERROR)
  end
end, {
  nargs = "*",
  desc = "Setup Rafta remote connection",
  complete = function(_, _, _)
    return {"--user", "--pass", "--host", "--port", "--disable-ssl"}
  end
})

-- Alternative: Create RaftaSetupLua command for direct Lua table usage
vim.api.nvim_create_user_command("RaftaSetupLua", function(args)
  -- Example usage: :RaftaSetupLua {user="admin", pass="secret", host="localhost", port=1157}
  local opts_str = table.concat(args.fargs, " ")
  local success, opts = pcall(function()
    return loadstring("return " .. opts_str)()
  end)
  
  if not success then
    vim.notify("Invalid Lua table format", vim.log.levels.ERROR)
    return
  end
  
  local setup_success, result = pcall(function()
    return rafta.setup(opts)
  end)
  
  if setup_success then
    vim.notify("Setup completed: " .. vim.inspect(result), vim.log.levels.INFO)
  else
    vim.notify("Setup failed: " .. tostring(result), vim.log.levels.ERROR)
  end
end, {
  nargs = "*",
  desc = "Setup Rafta remote connection with Lua table"
})