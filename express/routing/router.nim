import asynchttpserver
import options
import ../response
import route
import tables

type
    Router* = ref object
        routes: Table[string, Route]


proc new*(router_type: type[Router]): Router =
    var router = system.new(Router)
    return router


proc get*(self: var Router, path: string, callback: proc (request: Request): Response) =
    if self.routes.hasKey(path):
        self.routes[path].get_callback = some(callback)
        return

    var route = new Route
    route.get_callback = some(callback)
    route.post_callback = none(Callback)
    self.routes.add(path, route)


proc post*(self: var Router, path: string, callback: proc (request: Request): Response) =
    if self.routes.hasKey(path):
        self.routes[path].post_callback = some(callback)
        return

    var route = new Route
    route.get_callback = none(Callback)
    route.post_callback = some(callback)
    self.routes.add(path, route)


iterator get_route_pairs*(self: Router): tuple[path: string, route: Route] =
    for path, route in self.routes.pairs:
        yield (path, route)
