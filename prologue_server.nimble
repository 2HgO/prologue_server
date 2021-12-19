# Package

version       = "0.1.0"
author        = "Oghogho Odemwingie"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"
bin           = @["prologue_server"]

# Dependencies

requires "nim >= 1.6.0"
requires "https://github.com/sesco-llc/mongo >= 0.7.0"
requires "bcrypt >= 0.2.1"
requires "prologue >= 0.5.0"
requires "jsony >= 1.1.1"
requires "morelogging >= 0.2.0"
requires "jwt >= 0.2"
