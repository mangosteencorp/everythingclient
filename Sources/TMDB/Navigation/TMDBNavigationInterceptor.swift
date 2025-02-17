import Foundation

public protocol TMDBNavigationInterceptor {
    func willNavigate(to route: TMDBRoute)
}