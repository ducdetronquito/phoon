version = "0.1.0"
description = "Phoon implementation"
author = "Guillaume Paulet"
license = "Public Domain"

srcDir = "src"

requires "nim >= 1.0.4"

task release, "Build Phoon server in release mode.":
    exec "nimble -y c -d:danger -d:release -y server.nim"
