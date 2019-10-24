import asynchttpserver
import options
import ../response
import route
import tables


type
    Router* = object
        routes: Table[string, Route]


proc get_routes*(self: Router): Table[string, Route] =
    return self.routes


proc get_route*(self: Router, path: string): Option[Route] =
    if self.routes.hasKey(path):
        return some(self.routes[path])
    else:
        return none(Route)


proc add_get_endpoint*(self: var Router, path: string, callback: Callback) =
    if self.routes.hasKey(path):
        self.routes[path].get_callback = some(callback)
        return

    self.routes[path] = Route(
        path: path,
        get_callback: some(callback),
        post_callback: none(Callback),
    )


proc add_post_endpoint*(self: var Router, path: string, callback: Callback) =
    if self.routes.hasKey(path):
        self.routes[path].post_callback = some(callback)
        return

    self.routes[path] = Route(
        path: path,
        get_callback: none(Callback),
        post_callback: some(callback),
    )


proc get*(self: var Router, path: string, callback: proc (request: Request): Response) =
    self.add_get_endpoint(path, callback)


proc post*(self: var Router, path: string, callback: proc (request: Request): Response) =
    self.add_post_endpoint(path, callback)
