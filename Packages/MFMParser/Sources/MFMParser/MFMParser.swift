import Foundation

public enum MFMParser {
  /**
   * Generates a MfmNode tree from the MFM string.
  */
  public static func parse(_ input: String, nestLimit: Int? = nil) -> [MFMNode] {
    fullParser(input, FullParserOpts(nestLimit: nestLimit))
  }

  /**
   * Generates a MfmSimpleNode tree from the MFM string.
  */
  public static func parseSimple(_ input: String) -> [MFMNode] {
    simpleParser(input)
  }

  /**
   * Generates a MFM string from the MfmNode tree.
  */
  public static func toString(_ nodes: [MFMNode]) -> String {
    stringifyTree(nodes)
  }

  /**
   * Generates a MFM string from the MfmNode tree.
  */
  public static func toString(_ node: MFMNode) -> String {
    stringifyNode(node)
  }

  /**
   * Inspects the MfmNode tree.
  */
  public static func inspect(_ nodes: [MFMNode], _ action: (MFMNode) -> Void) {
    for node in nodes {
      inspectOne(node, action)
    }
  }

  /**
   * Inspects the MfmNode tree.
  */
  public static func inspect(_ node: MFMNode, _ action: (MFMNode) -> Void) {
    inspectOne(node, action)
  }

  /**
   * Inspects the MfmNode tree and returns as an array the nodes that match the conditions
   * of the predicate function.
  */
  public static func extract(_ nodes: [MFMNode], _ predicate: (MFMNode) -> Bool) -> [MFMNode] {
    var dest: [MFMNode] = []
    inspect(nodes) { node in
      if predicate(node) { dest.append(node) }
    }
    return dest
  }
}
