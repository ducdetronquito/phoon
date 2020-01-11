# Package

version       = "0.1.0"
author        = "Guillaume Paulet"
description   = "A web framework inspired by ExpressJS 🐇⚡"
license       = "Public Domain"

srcDir = "src"
skipDirs = @["benchmark", "tests"]

requires "nim >= 1.0.2"

task integration, "Runs the integration test suite.":
  exec "nim c -r tests/integration/test_simple_server.nim"
