import errors
import options
import route
import strutils
import tables


type
    Router* = ref object
        routes: Table[string, Route]
        middlewares: seq[Middleware]


proc delete*(self: Router, path: string, callback: Callback) =
    if self.routes.hasKey(path):
        self.routes[path].onDelete = some(callback)
        return

    var route = Route(onDelete: some(callback))
    self.routes[path] =  route


proc get*(self: Router, path: string, callback: Callback) =
    if self.routes.hasKey(path):
        self.routes[path].onGet = some(callback)
        return

    var route = Route(onGet: some(callback))
    self.routes[path] = route


proc head*(self: Router, path: string, callback: Callback) =
    if self.routes.hasKey(path):
        self.routes[path].onHead = some(callback)
        return

    var route = Route(onHead: some(callback))
    self.routes[path] = route


proc options*(self: Router, path: string, callback: Callback) =
    if self.routes.hasKey(path):
        self.routes[path].onOptions = some(callback)
        return

    var route = Route(onOptions: some(callback))
    self.routes[path] = route


proc patch*(self: Router, path: string, callback: Callback) =
    if self.routes.hasKey(path):
        self.routes[path].onPatch = some(callback)
        return

    var route = Route(onPatch: some(callback))
    self.routes[path] = route


proc post*(self: Router, path: string, callback: Callback) =
    if self.routes.hasKey(path):
        self.routes[path].onPost = some(callback)
        return

    var route = Route(onPost: some(callback))
    self.routes[path] = route


proc put*(self: Router, path: string, callback: Callback) =
    if self.routes.hasKey(path):
        self.routes[path].onPut = some(callback)
        return

    var route = Route(onPut: some(callback))
    self.routes[path] = route


proc route*(self: Router, path: string): Route {.discardable.} =
    var route = Route()
    self.routes[path] = route
    return route


iterator get_route_pairs*(self: Router): tuple[path: string, route: Route] =
    for path, route in self.routes.pairs:
        yield (path, route)


proc get_middlewares*(self: Router): seq[Middleware] =
    return self.middlewares


proc mount*(self: Router, path: string, router: Router) =
    if path.contains("*"):
        raise InvalidPathError(msg: "Cannot mount a sub-router on a wildcard route.")

    let middlewares = router.get_middlewares()

    for sub_path, route in router.get_route_pairs():
        let compiled_route = route.apply(middlewares)
        self.routes[path & sub_path] = compiled_route


proc use*(self: Router, middleware: Middleware) =
    self.middlewares.add(middleware)
