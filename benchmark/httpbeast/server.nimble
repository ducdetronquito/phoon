version = "0.1.0"
description = "Httpbeast implementation"
author = "Guillaume Paulet"
license = "Public Domain"

requires "nim >= 1.0.4"
requires "httpbeast >= 0.2.2"

task release, "Build Httpbeast server in release mode.":
    exec "nimble -y c -d:danger -d:release -y server.nim"
