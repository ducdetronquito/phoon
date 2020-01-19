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
        self.routes[path].delete_callback = some(callback)
        return

    var route = Route(delete_callback: some(callback))
    self.routes.add(path, route)


proc get*(self: Router, path: string, callback: Callback) =
    if self.routes.hasKey(path):
        self.routes[path].get_callback = some(callback)
        return

    var route = Route(get_callback: some(callback))
    self.routes.add(path, route)


proc head*(self: Router, path: string, callback: Callback) =
    if self.routes.hasKey(path):
        self.routes[path].head_callback = some(callback)
        return

    var route = Route(head_callback: some(callback))
    self.routes.add(path, route)


proc options*(self: Router, path: string, callback: Callback) =
    if self.routes.hasKey(path):
        self.routes[path].options_callback = some(callback)
        return

    var route = Route(options_callback: some(callback))
    self.routes.add(path, route)


proc patch*(self: Router, path: string, callback: Callback) =
    if self.routes.hasKey(path):
        self.routes[path].patch_callback = some(callback)
        return

    var route = Route(patch_callback: some(callback))
    self.routes.add(path, route)


proc post*(self: Router, path: string, callback: Callback) =
    if self.routes.hasKey(path):
        self.routes[path].post_callback = some(callback)
        return

    var route = Route(post_callback: some(callback))
    self.routes.add(path, route)


proc put*(self: Router, path: string, callback: Callback) =
    if self.routes.hasKey(path):
        self.routes[path].put_callback = some(callback)
        return

    var route = Route(put_callback: some(callback))
    self.routes.add(path, route)


proc route*(self: Router, path: string): Route {.discardable.} =
    var route = Route()
    self.routes.add(path, route)
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
        self.routes.add(path & sub_path, compiled_route)


proc use*(self: Router, middleware: Middleware) =
    self.middlewares.add(middleware)
