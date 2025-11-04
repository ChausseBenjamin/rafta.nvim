-- rafta_setup.lua - Integration for the Setup handler
-- This file should be placed at: /home/master/Workspace/plugins/rafta.nvim/lua/rafta_setup.lua

local grpc = require("rafta.remote.grpc")

local M = {}

-- Setup function to configure remote connection
-- @param opts table with keys: user, pass, host, port, disableSSL
M.setup = function(opts)
  opts = opts or {}

  -- Validate required parameters
  if not opts.user then
    error("user is required for setup")
  end
  if not opts.pass then
    error("pass is required for setup")
  end
  if not opts.host then
    error("host is required for setup")
  end

  -- Set defaults
  local setup_args = {
    user = opts.user,
    pass = opts.pass,
    host = opts.host,
    port = opts.port or 1157,
    disableSSL = opts.disableSSL or false
  }

  -- Validate port is a positive number
  if type(setup_args.port) ~= "number" or setup_args.port <= 0 then
    error("port must be a positive number")
  end

  -- Call the remote Setup handler
  local success, result = pcall(function()
    return vim.fn.rpcrequest(grpc.remote(), "Setup", setup_args)
  end)

  if not success then
    error("Failed to setup remote connection: " .. tostring(result))
  end

  return result
end

-- Convenience function for command line usage
M.setup_command = function(args)
  local opts = {}

  -- Parse command line arguments
  for i = 1, #args, 2 do
    local key = args[i]
    local value = args[i + 1]

    if not value then
      error("Missing value for argument: " .. key)
    end

    if key == "--port" then
      opts.port = tonumber(value)
      if not opts.port then
        error("Invalid port number: " .. value)
      end
    elseif key == "--disable-ssl" then
      opts.disableSSL = (value:lower() == "true")
    elseif key == "--user" then
      opts.user = value
    elseif key == "--pass" then
      opts.pass = value
    elseif key == "--host" then
      opts.host = value
    else
      error("Unknown argument: " .. key)
    end
  end

  return M.setup(opts)
end

return M
