enum AppSheet: Identifiable, Hashable {
    case filters

    var id: String {
        switch self {
        case .filters: "filters"
        }
    }
}
