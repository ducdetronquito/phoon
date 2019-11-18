import httpClient
import osproc
import unittest


suite "Integration tests":
    var process = startProcess(
        "nim",
        args=["c", "-r", "tests/example.nim"],
        options={ProcessOption.poUsePath}
    )

    setup:
        var client = newHttpClient()

    test "Get request":
        let response = client.get("http://localhost:8080/")
        check(response.status == "200 OK")
        check(response.body == "I am a boring home page")

    test "Get request on an endpoint defined in a sub-router":
        let response = client.get("http://localhost:8080/nice/users")
        check(response.status == "200 OK")
        check(response.body == "Here are some nice users")

    test "Post request":
        let response = client.post("http://localhost:8080/about")
        check(response.status == "201 Created")
        check(response.body == "What are you talking about ?")

    test "Endpoint Not Found":
        let response = client.get("http://localhost:8080/an-undefined-url")
        check(response.status == "404 Not Found")
        check(response.body == "")

    test "Method not allowed on endpoint":
        let response = client.post("http://localhost:8080/")
        check(response.status == "405 Method Not Allowed")
        check(response.body == "")

    process.terminate()
    process.close()
