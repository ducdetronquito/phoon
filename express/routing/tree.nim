import tables
import options


type
    Node[T] = ref object
        label*: char
        children*: Table[char, Node[T]]
        value*: T

    Tree*[T] = object
        root*: Node[T]


proc new*[T](tree_type: type[Tree[T]]): Tree[T] =
    var root = system.new(Node[T])
    root.label = '~'
    return tree_type(root: root)


proc insert*[T](self: var Tree, path: string, value: T) =
    var current_node = self.root

    for character in path:
        if current_node.children.hasKey(character):
            current_node = current_node.children[character]
            continue

        var node = new Node[T]
        node.label = character
        current_node.children.add(character, node)
        current_node = node

    current_node.value = value


proc retrieve*[T](self: var Tree[T], path: string): Option[T] =
    var current_node = self.root

    for character in path:
        if current_node.children.hasKey(character):
            current_node = current_node.children[character]
        else:
            return none(T)
    return some(current_node.value)
