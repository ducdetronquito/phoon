import errors
import ../handler
import options
import route
import strutils
import tables


type
    Router* = ref object
        routes: Table[string, Route]
        middlewares: seq[Middleware]


proc new*(router_type: type[Router]): Router =
    var router = system.new(Router)
    return router


proc get*(self: var Router, path: string, callback: Callback) =
    if self.routes.hasKey(path):
        self.routes[path].get_callback = some(callback)
        return

    var route = new Route
    route.get_callback = some(callback)
    route.post_callback = none(Callback)
    self.routes.add(path, route)


proc post*(self: var Router, path: string, callback: Callback) =
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


proc get_middlewares*(self: Router): seq[Middleware] =
    return self.middlewares


proc mount*(self: var Router, path: string, router: Router) =
    if path.contains("*"):
        raise InvalidPathError(msg: "Cannot mount a sub-router on a wildcard route.")

    let middlewares = router.get_middlewares()

    for sub_path, route in router.get_route_pairs():
        let compiled_route = route.apply(middlewares)
        self.routes.add(path & sub_path, compiled_route)


proc use*(self: Router, middleware: Middleware) =
    self.middlewares.add(middleware)
