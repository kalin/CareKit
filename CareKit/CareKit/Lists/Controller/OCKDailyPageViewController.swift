/*
 Copyright (c) 2019, Apple Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3. Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import CareKitStore
import CareKitUI
import UIKit

/// Conform to this protocol to receive callbacks when important events occur in an `OCKDailPageViewController`.
public protocol OCKDailyPageViewControllerDelegate: AnyObject {
    /// This method will be called anytime an unhandled error is encountered.
    ///
    /// - Parameters:
    ///   - dailyPageViewController: The daily page view controller in which the error occurred.
    ///   - error: The error that occurred
    func dailyPageViewController<S: OCKStoreProtocol>(
        _ dailyPageViewController: OCKDailyPageViewController<S>,
        didFailWithError error: Error)
}

public extension OCKDailyPageViewControllerDelegate {
    /// This method will be called anytime an unhandled error is encountered.
    ///
    /// - Parameters:
    ///   - dailyPageViewController: The daily page view controller in which the error occurred.
    ///   - error: The error that occurred
    func dailyPageViewController<S: OCKStoreProtocol>(
        _ dailyPageViewController: OCKDailyPageViewController<S>,
        didFailWithError error: Error) {}
}

/// Any class that can provide content for an `OCKDailyPageViewController` should conform to this protocol.
public protocol OCKDailyPageViewControllerDataSource: AnyObject {
    /// - Parameters:
    ///   - dailyPageViewController: The daily page view controller for which content should be provided.
    ///   - listViewController: The list view controller that should be populated with content.
    ///   - date: A date that should be used to determine what content to insert into the list view controller.
    func dailyPageViewController<S: OCKStoreProtocol>(
        _ dailyPageViewController: OCKDailyPageViewController<S>,
        prepare listViewController: OCKListViewController,
        for date: Date)
}

/// Displays a calendar page view controller in the header, and a view controllers in the body. The view controllers must
/// be manually queried and set from outside of the class.
open class OCKDailyPageViewController<Store: OCKStoreProtocol>: UIViewController,
    OCKDailyPageViewControllerDataSource, OCKDailyPageViewControllerDelegate,
    OCKCalendarPageViewControllerDelegate, UIPageViewControllerDataSource,
UIPageViewControllerDelegate {
    // MARK: Properties

    public weak var dataSource: OCKDailyPageViewControllerDataSource?
    public weak var delegate: OCKDailyPageViewControllerDelegate?

    public var selectedDate: Date {
        return calendarPageViewController.selectedDate
    }

    /// The store manager the view controller uses for synchronization
    public let storeManager: OCKSynchronizedStoreManager<Store>

    /// Page view managing ListViewControllers.
    private let pageViewController = UIPageViewController(transitionStyle: .scroll,
                                                          navigationOrientation: .horizontal,
                                                          options: nil)
    /// The calendar view controller in the header.
    private let calendarPageViewController: OCKCalendarPageViewController<Store>

    // MARK: Life cycle

    /// Create an instance of the view controller. Will hook up the calendar to the tasks collection,
    /// and query and display the tasks.
    ///
    /// - Parameter storeManager: The store from which to query the tasks.
    public init(storeManager: OCKSynchronizedStoreManager<Store>, adherenceAggregator: OCKAdherenceAggregator<Store.Event> = .countOutcomes) {
        self.storeManager = storeManager
        self.calendarPageViewController = OCKCalendarPageViewController(storeManager: storeManager, aggregator: adherenceAggregator)
        super.init(nibName: nil, bundle: nil)
        self.calendarPageViewController.dataSource = self
        self.pageViewController.dataSource = self
        self.pageViewController.delegate = self
        self.dataSource = self
        self.delegate = self
    }

    @available(*, unavailable)
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func loadView() {
        [calendarPageViewController, pageViewController].forEach { addChild($0) }
        view = OCKHeaderBodyView(headerView: calendarPageViewController.view, bodyView: pageViewController.view)
        [calendarPageViewController, pageViewController].forEach { $0.didMove(toParent: self) }
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        let now = Date()
        calendarPageViewController.calendarDelegate = self
        calendarPageViewController.selectDate(now, animated: false)
        pageViewController.setViewControllers([makePage(date: now)], direction: .forward, animated: false, completion: nil)
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Today", style: .plain, target: self, action: #selector(pressedToday(sender:)))
    }

    public func refreshAdherence() {
        calendarPageViewController.refreshAdherence()
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    private func makePage(date: Date) -> OCKDatedListViewController {
        let listViewController = OCKDatedListViewController(date: date)
        let dateLabel = OCKLabel(textStyle: .title2, weight: .bold)
        dateLabel.text = dateFormatter.string(from: date)
        listViewController.insertView(dateLabel, at: 0, animated: false)

        setInsets(for: listViewController)
        dataSource?.dailyPageViewController(self, prepare: listViewController, for: date)
        return listViewController
    }

    @objc
    private func pressedToday(sender: UIBarButtonItem) {
        let previousDate = selectedDate
        let currentDate = Date()
        guard !Calendar.current.isDate(previousDate, inSameDayAs: currentDate) else { return }
        calendarPageViewController.selectDate(currentDate, animated: true)
        calendarPageViewController(calendarPageViewController, didSelectDate: currentDate, previousDate: previousDate)
    }

    // MARK: OCKCalendarPageViewControllerDelegate

    internal func calendarPageViewController<Store>(_ calendarPageViewController: OCKCalendarPageViewController<Store>,
                                                    didSelectDate date: Date, previousDate: Date) where Store: OCKStoreProtocol {
        let newComponents = Calendar.current.dateComponents([.weekday, .weekOfYear, .year], from: date)
        let oldComponents = Calendar.current.dateComponents([.weekday, .weekOfYear, .year], from: previousDate)
        guard newComponents != oldComponents else { return } // do nothing if we have selected a date for the same day of the year
        let moveLeft = date < previousDate
        let listViewController = makePage(date: date)
        pageViewController.setViewControllers([listViewController], direction: moveLeft ? .reverse : .forward, animated: true, completion: nil)
    }

    func calendarPageViewController<Store>(_ calendarPageViewController: OCKCalendarPageViewController<Store>,
                                           didChangeDateInterval interval: DateInterval) where Store: OCKStoreProtocol {
    }

    // MARK: OCKDailyPageViewControllerDataSource & Delegate

    open func dailyPageViewController<S>(
        _ dailyPageViewController: OCKDailyPageViewController<S>,
        prepare listViewController: OCKListViewController,
        for date: Date) where S: OCKStoreProtocol {
    }

    open func dailyPageViewController<S>(
        _ dailyPageViewController: OCKDailyPageViewController<S>,
        didFailWithError error: Error) where S: OCKStoreProtocol {
    }

    // MARK: OCKCalendarViewControllerDelegate

    func calendarPageViewController<Store>(
        _ calendarPageViewController: OCKCalendarPageViewController<Store>,
        didFailWithError error: Error) where Store: OCKStoreProtocol {
        delegate?.dailyPageViewController(self, didFailWithError: error)
    }

    // MARK: - UIPageViewControllerDelegate

    public func pageViewController(_ pageViewController: UIPageViewController,
                                   viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let currentViewController = viewController as? OCKDatedListViewController else { fatalError("Unexpected type") }
        let targetDate = Calendar.current.date(byAdding: .day, value: -1, to: currentViewController.date)!
        return makePage(date: targetDate)
    }

    public func pageViewController(_ pageViewController: UIPageViewController,
                                   viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let currentViewController = viewController as? OCKDatedListViewController else { fatalError("Unexpected type") }
        let targetDate = Calendar.current.date(byAdding: .day, value: 1, to: currentViewController.date)!
        return makePage(date: targetDate)
    }

    // MARK: - UIPageViewControllerDataSource

    public func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool,
                                   previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed else { return }
        guard let listViewController = pageViewController.viewControllers?.first as? OCKDatedListViewController else { fatalError("Unexpected type") }
        calendarPageViewController.selectDate(listViewController.date, animated: true)
    }

    override open func viewSafeAreaInsetsDidChange() {
        updateScrollViewInsets()
    }

    private func updateScrollViewInsets() {
        pageViewController.viewControllers?.forEach({ child in
            guard let listVC = child as? OCKListViewController else { fatalError("Unexpected type") }
            setInsets(for: listVC)
        })
    }

    private func setInsets(for listViewController: OCKListViewController) {
        guard let listView = listViewController.view as? OCKListView else { fatalError("Unexpected type") }
        guard let headerView = view as? OCKHeaderBodyView else { fatalError("Unexpected type") }
        let insets = UIEdgeInsets(top: headerView.headerInset, left: 0, bottom: 0, right: 0)
        listView.scrollView.contentInset = insets
        listView.scrollView.scrollIndicatorInsets = insets
    }
}

// This is private subclass of the list view controller that imbues it with a date that can be uesd by the page view controller to determine
// which direction was just swiped.
private class OCKDatedListViewController: OCKListViewController {
    let date: Date

    init(date: Date) {
        self.date = date
        super.init(nibName: nil, bundle: nil)
        listView.scrollView.automaticallyAdjustsScrollIndicatorInsets = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
