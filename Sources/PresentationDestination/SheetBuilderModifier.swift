import SwiftUI

public final class SheetNavigator: ObservableObject {
  @Published public var items = [AnyHashable]()
  
  public func present(_ item: some Hashable) {
    self.items.append(item)
  }
}

struct GlobalSheetModifier: ViewModifier {
  @StateObject private var navigator = SheetNavigator()
  @StateObject private var holder = DestinationBuilderHolder()
  
  func body(content: Content) -> some View {
    Router(rootView: content, screens: $navigator.items)
      .environmentObject(holder)
      .environmentObject(navigator)
  }
}


struct DestinationBuilderModifier<TypedData>: ViewModifier {
  let typedDestinationBuilder: DestinationBuilder<TypedData>
  @EnvironmentObject var destinationBuilder: DestinationBuilderHolder
  
  func body(content: Content) -> some View {
    destinationBuilder.appendBuilder(typedDestinationBuilder)

    return content
      .environmentObject(destinationBuilder)
  }
}


public extension View {
  func sheetDestination<D: Hashable, C: View>(for pathElementType: D.Type, @ViewBuilder destination builder: @escaping (D) -> C) -> some View {
    return modifier(DestinationBuilderModifier(typedDestinationBuilder: { AnyView(builder($0)) }))
  }
  
  func presentationHost() -> some View {
    return modifier(GlobalSheetModifier())
  }
}

extension AnyHashable: Identifiable {
  public var id: Int { hashValue }
}
