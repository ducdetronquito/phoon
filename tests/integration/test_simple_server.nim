import httpClient
import osproc
import unittest


suite "Integration tests":
    var process = startProcess(
        "nim",
        args=["c", "-r", "tests/integration/simple_server.nim"],
        options={ProcessOption.poUsePath}
    )

    var client = newHttpClient()

    test "Get request":
        let response = client.get("http://localhost:3000/")
        check(response.status == "200 OK")
        check(response.body == "I am a boring home page")

    test "Get request on an endpoint defined in a sub-router":
        let response = client.get("http://localhost:3000/nice/users")
        check(response.status == "200 OK")
        check(response.body == "Here are some nice users")

    test "Get request on a wildcard endpoint":
        let response = client.get("http://localhost:3000/abstract")
        check(response.status == "200 OK")
        check(response.body == "I am a wildard page !")
    
    test "Get request on a parametrized endpoint":
        let response = client.get("http://localhost:3000/books/how-to-poop-in-the-wood")
        check(response.status == "200 OK")
        check(response.body == "Of course I read 'how-to-poop-in-the-wood' !")

    test "Post request":
        let response = client.post("http://localhost:3000/about")
        check(response.status == "201 Created")
        check(response.body == "What are you talking about ?")

    test "Endpoint Not Found":
        let response = client.get("http://localhost:3000/an-undefined-url")
        check(response.status == "404 Not Found")
        check(response.body == "")

    test "Method not allowed on endpoint":
        let response = client.post("http://localhost:3000/")
        check(response.status == "405 Method Not Allowed")
        check(response.body == "")

    test "Fail to pass an authentication middleware":
        let response = client.get("http://localhost:3000/admins/")
        check(response.status == "401 Unauthorized")
        check(response.body == "")

    test "Succeed to pass an authentication middleware":
        client.headers = newHttpHeaders({ "simple-auth": "trust me" })
        let response = client.get("http://localhost:3000/admins/")
        check(response.status == "200 OK")
        check(response.body == "Admins, he is doing it sideways !")

    # TODO: The process is still running even after being killed.
    process.kill()
    process.close()
