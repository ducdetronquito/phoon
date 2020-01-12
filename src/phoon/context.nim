import asynchttpserver
import response
import routing/tree

type
    Context* = ref object
        request*: Request
        parameters*: Parameters
        response*: Response


proc Ok*(self: Context, body: string = "") =
    self.response = response.Ok(body)


proc Created*(self: Context, body: string = "") =
    self.response = response.Created(body)


proc NoContent*(self: Context, body: string = "") =
    self.response = response.NoContent(body)


proc Unauthenticated*(self: Context, body: string = "") =
    self.response = response.Unauthenticated(body)


proc NotFound*(self: Context, body: string = "") =
    self.response = response.NotFound(body)


proc MethodNotAllowed*(self: Context, body: string = "") =
    self.response = response.MethodNotAllowed(body)


proc Teapot*(self: Context, body: string = "") =
    self.response = response.Teapot(body)


proc BadRequest*(self: Context, body: string = "") =
    self.response = response.BadRequest(body)

