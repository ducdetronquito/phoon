# Package

version       = "0.1.0"
author        = "Guillaume Paulet"
description   = "A toy Nim web framework heavily inspired by ExpressJS, Echo and Starlette."
license       = "Public Domain"
srcDir = "src"

requires "nim >= 1.0.2"

task integration, "Runs the integration test suite.":
  exec "nim c -r tests/integration/test_simple_server.nim"
