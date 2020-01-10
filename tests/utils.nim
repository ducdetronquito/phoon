import asynchttpserver
import uri


proc GetRequest*(path: string): Request =
    let uri = parseUri(path)
    return Request(
      reqMethod: HttpMethod.HttpGet,
      url: uri
    )

proc PostRequest*(path: string): Request =
    let uri = parseUri(path)
    return Request(
        reqMethod: HttpMethod.HttpPost,
        url: uri
    )

proc PutRequest*(path: string): Request =
    let uri = parseUri(path)
    return Request(
        reqMethod: HttpMethod.HttpPut,
        url: uri
    )
