if not lib.checkDependency('ox_lib', '3.30.0', true) then return end

local Store = require 'server.store'

require 'server.editor'
require 'server.exports'

Store.load()
