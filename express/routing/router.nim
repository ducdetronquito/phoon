import asynchttpserver
import options
import ../response
import route
import tables
import tree


type
    Router* = ref object
        routes: Tree[Route]


proc new*(app_type: type[Router]): Router =
    var router = system.new(Router)
    router.routes = Tree[Route].new()
    return router


proc find_route*(self: Router, path: string): Option[Route] =
    return self.routes.retrieve(path)


proc add_get_endpoint*(self: var Router, path: string, callback: Callback) =
    var existing_route = self.routes.retrieve(path)
    if existing_route.isSome:
        existing_route.get().get_callback = some(callback)

    var route = new Route
    route.get_callback = some(callback)
    route.post_callback = none(Callback)

    self.routes.insert(path, route)


proc add_post_endpoint*(self: var Router, path: string, callback: Callback) =
    var existing_route = self.routes.retrieve(path)
    if existing_route.isSome:
        existing_route.get().post_callback = some(callback)

    var route = new Route
    route.get_callback = none(Callback)
    route.post_callback = some(callback)

    self.routes.insert(path, route)


proc get*(self: var Router, path: string, callback: proc (request: Request): Response) =
    self.add_get_endpoint(path, callback)


proc post*(self: var Router, path: string, callback: proc (request: Request): Response) =
    self.add_post_endpoint(path, callback)


proc dispatch*(self: Router, request: Request): Response =
    let path = request.url.path

    let potential_route = self.find_route(path)
    if potential_route.isNone:
        return NotFound("")

    let route = potential_route.get()
    let callback = route.get_callback_of(request.reqMethod)

    if callback.isNone:
        return MethodNotAllowed("")

    {.gcsafe.}:
        return callback.get()(request)
