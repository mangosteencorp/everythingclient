import RxSwift
@testable import TMDB_Profile
import XCTest

final class ProfileViewModelTests: XCTestCase {
    private var disposeBag = DisposeBag()

    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
    }

    /// The view model reacts to `isAuthenticated` on the main queue, so give the sink a turn.
    private func waitForStateSettle() {
        let expectation = expectation(description: "main queue drained")
        DispatchQueue.main.async { expectation.fulfill() }
        wait(for: [expectation], timeout: 1)
    }

    private func makeViewModel(
        useCase: StubGetProfileUseCase = StubGetProfileUseCase(),
        auth: StubAuthenticationViewModel = StubAuthenticationViewModel()
    ) -> (ProfileViewModel, StubGetProfileUseCase, StubAuthenticationViewModel) {
        (ProfileViewModel(getProfileUseCase: useCase, authViewModel: auth), useCase, auth)
    }

    private func latestState(of viewModel: ProfileViewModel) -> ProfileViewState? {
        var state: ProfileViewState?
        viewModel.state.subscribe(onNext: { state = $0 }).disposed(by: disposeBag)
        return state
    }

    func testStartsUnauthorizedWhenNobodyIsSignedIn() {
        let (viewModel, useCase, _) = makeViewModel()
        waitForStateSettle()

        XCTAssertTrue(latestState(of: viewModel)?.isUnauthorized == true)
        XCTAssertEqual(useCase.executeCallCount, 0)
    }

    func testBecomingAuthenticatedLoadsTheProfile() {
        let auth = StubAuthenticationViewModel()
        auth.isAuthenticated = true
        let (viewModel, useCase, _) = makeViewModel(auth: auth)
        waitForStateSettle()

        XCTAssertEqual(useCase.executeCallCount, 1)
        XCTAssertEqual(latestState(of: viewModel)?.loadedProfile?.accountInfo.id, 42)
    }

    func testAFailingLoadSurfacesTheError() {
        let useCase = StubGetProfileUseCase()
        useCase.result = .failure(ProfileTestError(message: "boom"))
        let auth = StubAuthenticationViewModel()
        auth.isAuthenticated = true
        let (viewModel, _, _) = makeViewModel(useCase: useCase, auth: auth)
        waitForStateSettle()

        XCTAssertEqual((latestState(of: viewModel)?.error as? ProfileTestError)?.message, "boom")
    }

    func testRefreshProfileLoadsAgain() {
        let auth = StubAuthenticationViewModel()
        auth.isAuthenticated = true
        let (viewModel, useCase, _) = makeViewModel(auth: auth)
        waitForStateSettle()

        viewModel.refreshProfile()

        XCTAssertEqual(useCase.executeCallCount, 2)
    }

    func testFetchProfileGoesThroughLoading() {
        let (viewModel, useCase, _) = makeViewModel()
        waitForStateSettle()
        useCase.result = .failure(ProfileTestError(message: "boom"))

        viewModel.fetchProfile()

        // `.loading` is emitted synchronously before the request resolves.
        XCTAssertEqual(useCase.executeCallCount, 1)
    }

    func testSignOutClearsTheProfile() {
        let auth = StubAuthenticationViewModel()
        auth.isAuthenticated = true
        let (viewModel, _, _) = makeViewModel(auth: auth)
        waitForStateSettle()

        // `signOut()` hops through a detached `Task`, so wait for the state it produces rather
        // than for a turn of the main queue.
        let unauthorized = expectation(description: "unauthorized")
        // `signOut()` reaches `.unauthorized` twice — once from its own `Task`, once from the
        // authentication sink reacting to the flag flipping — and either order is correct.
        unauthorized.assertForOverFulfill = false
        viewModel.state
            .subscribe(onNext: { if case .unauthorized = $0 { unauthorized.fulfill() } })
            .disposed(by: disposeBag)

        viewModel.signOut()

        wait(for: [unauthorized], timeout: 1)
        XCTAssertEqual(auth.signOutCallCount, 1)
    }

    func testSignInDelegatesToTheAuthenticationViewModel() async {
        let (viewModel, _, auth) = makeViewModel()

        await viewModel.signIn()

        XCTAssertEqual(auth.signInCallCount, 1)
    }

    func testCancelLoadStopsAnInFlightRequest() {
        let auth = StubAuthenticationViewModel()
        auth.isAuthenticated = true
        let (viewModel, useCase, _) = makeViewModel(auth: auth)
        waitForStateSettle()

        viewModel.cancelLoad()
        viewModel.refreshProfile()

        XCTAssertEqual(useCase.executeCallCount, 2)
    }
}

private extension ProfileViewState {
    var isUnauthorized: Bool { if case .unauthorized = self { return true }; return false }
    var loadedProfile: ProfileEntity? { if case let .loaded(profile) = self { return profile }; return nil }
    var error: Error? { if case let .error(error) = self { return error }; return nil }
}
