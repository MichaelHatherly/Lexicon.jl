module Utilities

import Docile: Cache

export packagemodules

packagemodules(mod::Module) = [m for (m, d) in Cache.getpackage(mod).modules]

end
