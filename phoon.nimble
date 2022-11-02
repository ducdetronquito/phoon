# Package

version       = "0.1.1"
author        = "Guillaume Paulet"
description   = "A web framework inspired by ExpressJS 🐇⚡"
license       = "Public Domain"

srcDir = "src"
skipDirs = @["tests"]

requires "nim >= 1.6"

task integration, "Runs the integration test suite.":
  exec "nim c -r tests/integration/test_simple_server.nim"
