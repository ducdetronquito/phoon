import options
import strutils


type
    InvalidPathError* = ref object of Exception

    PathType* = enum
        Strict,
        Wildcard

    Node[T] = ref object
        path*: char
        path_type*: PathType
        children*: seq[Node[T]]
        value*: Option[T]
        is_leaf: bool

    Tree*[T] = ref object
        root*: Node[T]


proc new*[T](tree_type: type[Tree[T]]): Tree[T] =
    var root = system.new(Node[T])
    root.path = '~'
    return tree_type(root: root)


proc find_child_by_path[T](self: Node[T], path: char): Option[Node[T]] =
    for child in self.children:
        if child.path == path:
            return some(child)

    return none(Node[T])


proc check_illegal_patterns(path: string) =
    if not path.contains("*"):
        return

    let after_wildcard_part = path.rsplit("*", maxsplit = 1)[1]
    if after_wildcard_part.len != 0:
        raise InvalidPathError(msg: "A path cannot defined character after a wildcard.")


proc insert*[T](self: var Tree, path: string, value: T) =
    path.check_illegal_patterns()

    var current_node = self.root

    for character in path:

        let child = current_node.find_child_by_path(character)
        if child.isSome:
            current_node = child.get()
            continue

        var node = new Node[T]
        node.path = character

        current_node.children.add(node)
        current_node = node

    current_node.value = some(value)
    current_node.is_leaf = true

    if current_node.path == '*':
        current_node.path_type = PathType.Wildcard


proc retrieve*[T](self: var Tree[T], path: string): Option[T] =
    var current_node = self.root

    for character in path:
        let child = current_node.find_child_by_path(character)
        if child.isNone:
            return none(T)

        current_node = child.get()

    if current_node.is_leaf:
        return some(current_node.value.get())
    else:
        return none(T)
