import SwiftUI
typealias DestinationBuilder<T> = (T) -> AnyView
public typealias DestinationPath = [AnyHashable]

/// Uniquely identifies an instance of a local destination builder.
private struct LocalDestinationID: RawRepresentable, Hashable {
  let rawValue: UUID
}

class DestinationBuilderHolder: ObservableObject {
  private var builders: [String: (Any) -> AnyView?] = [:]

  init() {
    builders = [:]
  }

  func appendBuilder<T>(_ builder: @escaping (T) -> AnyView) {
    let key = Self.identifier(for: T.self)
    builders[key] = { data in
      if let typedData = data as? T {
        return builder(typedData)
      } else {
        return nil
      }
    }
  }
  
  func build<T>(_ typedData: T) -> AnyView {
    let base = (typedData as? AnyHashable)?.base
    if let identifier = (base ?? typedData) as? LocalDestinationID {
      let key = identifier.rawValue.uuidString
      if let builder = builders[key], let output = builder(typedData) {
        return output
      }
      assertionFailure("No view builder found for type \(key)")
    } else {
      var possibleMirror: Mirror? = Mirror(reflecting: base ?? typedData)
      while let mirror = possibleMirror {
        let key = Self.identifier(for: mirror.subjectType)

        if let builder = builders[key], let output = builder(typedData) {
          return output
        }
        possibleMirror = mirror.superclassMirror
      }
      assertionFailure("No view builder found for type \(type(of: base ?? typedData))")
    }
    return AnyView(Image(systemName: "exclamationmark.triangle"))
  }
}

private extension DestinationBuilderHolder {
  func appendLocalBuilder(identifier: LocalDestinationID, _ builder: @escaping () -> AnyView) {
    let key = identifier.rawValue.uuidString
    builders[key] = { _ in builder() }
  }

  func removeLocalBuilder(identifier: LocalDestinationID) {
    let key = identifier.rawValue.uuidString
    builders[key] = nil
  }

  static func identifier(for type: Any.Type) -> String {
    String(reflecting: type)
  }
}
