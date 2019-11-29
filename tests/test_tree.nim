import express/routing/errors
import express/routing/tree
import options
import unittest


suite "Tree":

    test "Node children are prioratized":
        var tree = new Tree[string]
        tree.insert("/*", "wildcard")
        tree.insert("/{id}", "parametrized")
        tree.insert("/a", "strict")

        let children = tree.root.children[0].children
        check(children.len() == 3)
        check(children[0].path_type == PathType.Strict)
        check(children[1].path_type == PathType.Parametrized)
        check(children[2].path_type == PathType.Wildcard)

    test "A leaf node knows it's available parameters":
        var tree = new Tree[string]
        tree.insert("/{api_version}/users/{id}", "Bobby")

        let last_node = tree.root.children[0].children[0].children[0].children[0].children[0].children[0].children[0].children[0].children[0].children[0]
        check(last_node.is_leaf == true)
        check(last_node.parameters == ["api_version", "id"])


suite "Strict routes":

    test "Insert root route":
        var tree = Tree[string].new()
        tree.insert("/", "Home")
        let result = tree.retrieve("/").get()
        check(result.value == "Home")

    test "Insert route":
        var tree = Tree[string].new()
        tree.insert("/users", "Bobby")
        let result = tree.retrieve("/users").get()
        check(result.value == "Bobby")

    test "Insert multiple routes":
        var tree = Tree[string].new()

        tree.insert("/", "Home")
        tree.insert("/users", "Bobby")
        tree.insert("/users/age", "42")

        check(tree.retrieve("/").get().value == "Home")
        check(tree.retrieve("/users").get().value == "Bobby")
        check(tree.retrieve("/users/age").get().value == "42")

    test "Fail to retrieve an undefined route.":
        var tree = Tree[string].new()
        tree.insert("/users", "Bobby")
        let result = tree.retrieve("/admins")
        check(result.isNone)

    test "Fail to retrieve a partial route.":
        var tree = Tree[string].new()
        tree.insert("/users-that-are-nice", "Bobby")
        let result = tree.retrieve("/users")
        check(result.isNone)


suite "Wilcard routes":

    test "Insert a route with a wildcard":
        var tree = Tree[string].new()
        tree.insert("/user*", "Bobby")
        let last_node = tree.root.children[0].children[0].children[0].children[0].children[0].children[0]
        check(last_node.path == '*')
        check(last_node.path_type == PathType.Wildcard)

    test "Cannot insert route with characters after wildcard":
        var tree = Tree[string].new()

        doAssertRaises(InvalidPathError):
            tree.insert("/user*-that-are-sexy", "Bobby")

    test "Retrieve a wildcard route":
        var tree = Tree[string].new()
        tree.insert("/users-that-are-grumpy", "Grumpy Cat")
        tree.insert("/users*", "Bobby")

        let result = tree.retrieve("/users-that-are-nice").get()
        check(result.value == "Bobby")

    test "Retrieve a wildcard route on partial match":
        var tree = Tree[string].new()
        tree.insert("/users-that-are-nice", "John")
        tree.insert("/*", "Bobby")

        let result = tree.retrieve("/users").get()
        check(result.value == "Bobby")

    test "Retrieve a match-all route":
        var tree = Tree[string].new()
        tree.insert("*", "Gotta catch'em all!")
        tree.insert("/earth", "Diglett")
        tree.insert("/wind", "Charmander")
        tree.insert("/fire", "Pidgey")

        check(tree.retrieve("/").get().value == "Gotta catch'em all!")
        check(tree.retrieve("/random-pokemon").get().value == "Gotta catch'em all!")


suite "Parametrized routes":

    test "Retrieve a route with a parameter":
        var tree = Tree[string].new()
        tree.insert("/users/{id}", "Bobby")

        let result = tree.retrieve("/users/10").get()
        check(result.value == "Bobby")
        check(result.parameters.get("id") == "10")

    test "Retrieve a route with a parameter followed by a strict path":
        var tree = Tree[string].new()
        tree.insert("/users/{id}/books", "Bobby")

        let result = tree.retrieve("/users/10/books").get()
        check(result.value == "Bobby")
        check(result.parameters.get("id") == "10")

    test "Retrieve a route with a parameter followed by a wildcard path":
        var tree = Tree[string].new()
        tree.insert("/users/{id}/boo*", "A boo")

        let result = tree.retrieve("/users/10/booking").get()
        check(result.value == "A boo")
        check(result.parameters.get("id") == "10")

    test "Retrieve a route with two parameters":
        var tree = Tree[string].new()
        tree.insert("/users/{id}/books/{title}", "A book title")

        let result = tree.retrieve("/users/10/books/the-capital").get()
        check(result.value == "A book title")
        check(result.parameters.get("id") == "10")
        check(result.parameters.get("title") == "the-capital")

    test "Insert a route with a parameter":
        var tree = new Tree[string]
        tree.insert("/users/{id}", "Bobby")
        let parameter_node = tree.root.children[0].children[0].children[0].children[0].children[0].children[0].children[0].children[0]
        check(parameter_node.path == '{')
        check(parameter_node.path_type == PathType.Parametrized)
        check(parameter_node.parameter_name == "id")
        check(parameter_node.parameters == ["id"])

    test "Insert a route with two parameters":
        var tree = new Tree[string]
        tree.insert("/users/{id}/books/{title}", "Bobby")
        let id = tree.root.children[0].children[0].children[0].children[0].children[0].children[0].children[0].children[0]
        let books = id.children[0].children[0].children[0].children[0].children[0].children[0].children[0]
        let title = books.children[0]
        check(title.path == '{')
        check(title.path_type == PathType.Parametrized)
        check(title.parameter_name == "title")
        check(title.parameters == ["id", "title"])

    test "Fail to insert a route with a parameter name that contains the character {":
        var tree = new Tree[string]
        doAssertRaises(InvalidPathError):
            tree.insert("/users/{i{d}", "Bobby")

    test "Fail to insert a route with a parameter name that does not start with the character {":
        var tree = new Tree[string]
        doAssertRaises(InvalidPathError):
            tree.insert("/users/id}", "Bobby")

    test "Fail to insert a parametrized route if one already exists":
        var tree = new Tree[string]
        tree.insert("/users/{id}", "1")

        doAssertRaises(InvalidPathError):
            tree.insert("/users/{name}", "Bobby")
