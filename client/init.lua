if not lib.checkDependency('ox_lib', '3.30.0', true) then return end

local config = require 'config'

require 'client.blips'
require 'client.sync'
require 'client.editor'
require 'client.exports'

if config.debug then
    require 'client.debug'
end
