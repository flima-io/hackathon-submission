pragma solidity ^0.8.4;

struct Element {
    uint256 id;
    uint256 state;
}

struct Node {
    int256 next;
    int256 prev;
    Element element;
}

struct LinkedList {
    uint256 length;
    mapping(uint256 => uint256) lengths;
    mapping(uint256 => uint256) heads;
    mapping(uint256 => uint256) tails;
    Chunk[] chunks;
}

struct Chunk {
    Node[] nodes;
}

///  A list like data structure that supports
///  - accessing element by index
///  - find next node of the same state
///  From the above feature we can list a list of active element using startIndex and offset.
library IndexedLinkedListLib {
    uint256 private constant MAX_IN_CHUNK = 100;
    int256 private constant NULL = -1;

    function push(LinkedList storage self, Element memory element) internal {
        Node memory node = Node(0, 0, element);
        if (self.length == 0) {
            Chunk storage chunk = self.chunks.push();
            chunk.nodes.push(node);
        } else {
            Chunk storage tail = self.chunks[self.chunks.length - 1];
            tail.nodes.push(node);
            if (tail.nodes.length >= MAX_IN_CHUNK) {
                self.chunks.push();
            }
        }
        self.length += 1;
        self.lengths[element.state] += 1;
    }

    function changeState(LinkedList storage self, uint256 index, uint256 newState) external {
        Node storage node = _findNodeByIndex(self, index);
        node.element.state = newState;
    }

    function _findNodeByIndex(LinkedList storage self, uint256 index) internal view returns (Node storage) {
        uint256 chunkIndex = uint256(index / MAX_IN_CHUNK);
        uint256 indexInChunk = index % MAX_IN_CHUNK;
        return self.chunks[chunkIndex].nodes[indexInChunk];
    }
}