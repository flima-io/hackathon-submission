pragma solidity ^0.8.4;

struct Element {
    uint256 id;
    uint256 state;
}

struct Node {
    uint256 next;
    uint256 prev;
    Element element;
}

struct IndexedLinkedList {
    Node[] nodes;
    uint256 head;
    uint256 tail;
}

///  A list like data structure that supports
///  - accessing element by index
///  - find next node of the same state
///  From the above feature we can list a list of active element using startIndex and offset.
library IndexedLinkedListLib {
    uint256 private constant NULL = (2 ** 256) - 1;

    function push(IndexedLinkedList storage self, Element memory element) public {
        if (self.nodes.length == 0) {
            Node memory node = Node(NULL, NULL, element);
            self.head = 0;
            self.tail = 0;
            self.nodes.push(node);
        } else {
            Node storage tail = self.nodes[self.tail];
            Node memory node = Node(self.tail, NULL, element);
            self.nodes.push(node);
            self.tail = self.nodes.length;
            tail.next = self.nodes.length;
        }
    }

    function inactivate(IndexedLinkedList storage self, uint256 index, uint256 newState) public {
        Node storage node = self.nodes[index];
        require(_isActive(node), "E-e0gRQuVc");
        node.element.state = newState;
        self.nodes[node.next].prev = node.prev;
        self.nodes[node.prev].next = node.next;
        node.next = NULL;
        node.prev = NULL;
    }

    ///  to be overridden
    function _isActive(Node storage node) private view returns (bool) {
        return node.element.state == 1;
    }
}