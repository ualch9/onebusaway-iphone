//
//  OBAFetchedTableViewController.swift
//  OneBusAway
//
//  Created by Alan Chu on 8/11/19.
//  Copyright © 2019 OneBusAway. All rights reserved.
//

import UIKit
import CoreData
import OBAKit
import os.log

/// Provide a list template for core data fetched data. This differs from OBAStaticTableViewController in that
/// it isn't static, this table view updates automatically ("dynamically") as the core data stack updates, preventing
/// stale data. Fetching data from a remote sources is expected to occur on a separate background queue,
/// and automatically merge changes to core data's container view context. This class cannot be used
/// in Objc because it relies on generics.
///
/// # Directly Initialize
/// This method of using OBAFetchedTableViewController only works with getting data from the local stack. To
/// also include fetching from remote, you will need to subclass OBAFetchedTableViewController (see next section).
///
/// ```swift
/// let vc = OBAFetchedTableViewController<OBARegion>()
///
/// // Optional
/// let fetchRequest = OBARegion.sortedFetchRequest
/// fetchRequest.predicate = NSPredicate(format: "isActive == YES")
///
/// vc.fetchRequest = fetchRequest
///
/// present(vc, animated: true)
/// ```
/// If no explicit `fetchRequest` is provided, it will use the default to `OBAManagedObject.fetchRequest`.
/// Note that the entity type of your fetch request must match the generic type of
/// `OBAFetchedTableViewController`.
///
/// # Subclass OBAFetchedTableViewController
/// Subclassing is necessary if you want to customize how the table view looks, or you want to provide means
/// of updating the data from a remote source. The example below only demostrates how to provide a remote source
/// and a custom fetch request.
///
/// ```swift
/// class RegionsViewController: OBAFetchedTableViewController<OBARegion> {
///    // Setting `loadData()` is only needed if you want to load data from remote.
///    override func loadData() -> Promise<OBARegion> {
///       return OBAModelDAO.shared.webService.fetch(.regions, as: OBARegion.self)
///    }
///
///    // Setting the fetch request is optional, as it can be default to `OBAManagedObject.fetchRequest`.
///	   override func viewDidLoad() {
///       let fetchRequest = OBARegion.sortedFetchRequest
///       fetchRequest.predicate = NSPredicate(format: "isActive == YES")
///
///       self.fetchRequest = fetchRequest
///
///       // IMPORTANT: SET THE FETCH REQUEST BEFORE CALLING `super.viewDidLoad()`
///       super.viewDidLoad()
///    }
/// }
/// ```
///
/// # Configuration
/// There are a number of configuration methods you can override to match the appearance and behavior you want. Most
/// are wrappers of `UITableViewDataSource` and `UITableViewDelegate`, but they also include the corresponding
/// object as a method parameter, so you don't have to access `fetchedResultsController.object(at:_)` yourself.
/// Take a look at the headers of this class to see what you should override.
///
/// ** Because this is still under development, I haven't written out configuration docs yet **
///
/// For the most part, this view controller works out-of-the-box, but only presents basic information relevant to the fetch request.
///
/// # Limitation
/// - This controller only handles data in the core data stack. Standalone data cannot be represented using
/// OBAFetchedTableViewController.
public class OBAFetchedTableViewController<O: OBAManagedObject>: UITableViewController, NSFetchedResultsControllerDelegate {
	var fetchedResultsController: NSFetchedResultsController<O>!
	
	/// The keyPath on the fetched objects used to determine the section they belong to.
	var sectionNameKeyPath: String? {
		didSet { self.createFetchedResultsController() }
	}
	
	/// Name of the persistent cached section information.
	var cacheName: String? {
		willSet {
			guard let oldName = cacheName else { return }
			NSFetchedResultsController<O>.deleteCache(withName: oldName)
		}
		didSet {
			self.createFetchedResultsController()
		}
	}
	
	var fetchRequest: NSFetchRequest<O>! {
		didSet { self.createFetchedResultsController() }
	}
	
	fileprivate var currentLoadingPromise: Promise<[O]>?
	
	// MARK: - UI State stuff
	fileprivate var showActivityIndicator: Bool = false {
		didSet {
			if loadingDataShouldDisableUserInteraction {
				if self.showActivityIndicator {
					self.present(loadingIndicatorAlert, animated: true)
				} else {
					guard loadingIndicatorAlert.isBeingPresented else { return }
					loadingIndicatorAlert.dismiss(animated: true)
				}
			} else {
				self.showActivityIndicator ? self.activityIndicator.startAnimating() : self.activityIndicator.stopAnimating()
				self.navigationController?.setToolbarHidden(!self.showActivityIndicator, animated: true)
			}
		}
	}
	
	fileprivate lazy var activityIndicator: UIActivityIndicatorView = {
		let view = UIActivityIndicatorView(style: .gray)
		view.hidesWhenStopped = true
		
		return view
	}()
	
	public var loadingDataShouldDisableUserInteraction: Bool { return false }
	
	// MARK: Blocking Loading Indicator
	fileprivate lazy var loadingIndicatorAlert: UIAlertController = {
		// TODO: Dont use uialertcontroller: https://stackoverflow.com/a/48730050
		let alert = UIAlertController(title: "", message: nil, preferredStyle: .alert)
		let indicator = UIActivityIndicatorView(frame: alert.view.bounds)
        indicator.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        //add the activity indicator as a subview of the alert controller's view
        alert.view.addSubview(indicator)
        indicator.isUserInteractionEnabled = false // required otherwise if there buttons in the UIAlertController you will not be able to press them
        indicator.startAnimating()
		
		return alert
	}()
	
	override public func viewDidLoad() {
		super.viewDidLoad()
		
		// If a fetch request was not provided during initialization, use the default implementation for the time being.
		if fetchRequest == nil {
			fetchRequest = O.sortedFetchRequest
		}
		
		// NOTE: Toolbar height being too high may be an iOS 13 beta bug (https://forums.developer.apple.com/thread/120322).
		self.setToolbarItems([UIBarButtonItem(customView: self.activityIndicator)], animated: false)
		self.navigationController?.toolbar.frame.size.height = 44

		// Watch for network changes.
		NotificationCenter.default.addObserver(self,
											   selector: #selector(networkConnected),
											   name: OBAWebService.Notifications.networkConnected.name,
											   object: nil)
		
		NotificationCenter.default.addObserver(self,
											   selector: #selector(networkDisconnected),
											   name: OBAWebService.Notifications.networkDisconnected.name,
											   object: nil)
	}
	
	override public func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		if fetchedResultsController == nil {
			os_log("fetchResultsController is nil and viewDidAppear-ed, so we will create a fetchResultsController now.")
			createFetchedResultsController()
		}
	}
	
	/// This method does not do anything if `fetchRequest == nil`.
	fileprivate func createFetchedResultsController() {
		guard fetchRequest != nil else { return }
		
		fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
															  managedObjectContext: CD_OBAModelDAO.shared.viewContext,
															  sectionNameKeyPath: self.sectionNameKeyPath,
															  cacheName: self.cacheName)
		fetchedResultsController.delegate = self
		
		if self.isViewLoaded {
			self.tableView.reloadData()
			do {
				try self.fetchedResultsController.performFetch()
			} catch {
				print(error)
			}
		}
	}
	
	override public func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.reloadData()
	}
	
	// MARK: - Overridable configuration methods (bodies below are default implementations)
	public func cellForRow(_ tableView: UITableView, at indexPath: IndexPath, for item: O) -> UITableViewCell {
		// Default implementation
		let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
		cell.textLabel?.text = item.identifier
		cell.detailTextLabel?.text = item.entity.name
		
		return cell
	}
	
	// default implementation
	public func cellDidSelect(_ tableView: UITableView, at indexPath: IndexPath, for item: O) {
		// default implementation is nothing.
	}
	
	@available(iOS 11.0, *)
	public func trailingSwipeActionsConfigurationForRowAt(_ tableView: UITableView, at indexPath: IndexPath, for item: O) -> UISwipeActionsConfiguration? {
		return nil
	}
	
	// MARK: - Loading data from remote
	/// Override this method to fetch data from remote.
	/// Load data from remote. You will need to provide the relevant Promise for this method, and the OBAFetchedViewController
	/// will automatically manage the lifecycle of the Promise.
	/// 1. This method (`loadData()`) is responsible for providing the Promise that makes the remote request.
	/// 2. `reloadData()` is responsible for actually performing the remote request.
	public func loadData() -> Promise<[O]> {
		// Default implementation: if this method is not overridden, then this method returns any empty array.
		return Promise(value: [])
	}
	
	/// # ⚠️ Do not override this method. ⚠️
	/// You can call this method anytime to manually reload data from remote.
	/// This method is responsible for managing the lifecycle of the `loadData()` promise,
	/// in addition to the corresponding UI elements to indicate loading state.
	/// - precondition: A loading operation is not in progress when you call this. If you call reloadData
	/// while a reload operation is pending, it will gracefully ignore your call and let the current pending reload
	/// operation finish.
	public func reloadData() {
		os_log("Called reloadData().", log: .default, type: .info)
		if let currentLoading = currentLoadingPromise, currentLoading.isPending {
			os_log("Called reloadData() when a loading operation is pending. We are going to ignore this call and not make another reload operation.", log: .default, type: .error)
			
			os_log("reloadData() cancelled.", log: .default, type: .info)
			return
		}
		
		DispatchQueue.main.async {
			self.showActivityIndicator = true
		}
		
		self.setPrompt(nil)
		
		os_log("reloadData() pending.", log: .default, type: .info)
		let loadData = self.loadData()
		loadData.then(on: .main) { _ in
			self.setPrompt(nil)
		}.catch(on: .main) {
			self.setPrompt($0.localizedDescription)
			os_log("reloadData() failed: %@", log: .default, type: .error, $0 as NSError)
		}.always(on: .main) {
			try? self.fetchedResultsController.performFetch()
			self.showActivityIndicator = false
			
			os_log("reloadData() resolved.", log: .default, type: .info)
		}
		self.currentLoadingPromise = loadData
	}
	
	// default implementation
	public func cancelLoadData() {
		os_log("Optional method cancelLoadData(:_) not implemented. It is recommended you implement this method to respond to network conditions", log: .default, type: .fault)
	}
	
	// default implementation
	public func sectionName(for sectionIndexName: String) -> String? {
		return nil
	}
	
	// MARK: - State methods
	public func setPrompt(_ prompt: String?) {
		DispatchQueue.main.async {
			// rdar://43522696 https://openradar.appspot.com/43522696
			UIView.animate(withDuration: 0.3) {
				self.navigationController?.setNavigationBarHidden(true, animated: false)
				self.navigationItem.prompt = prompt
				self.navigationController?.setNavigationBarHidden(false, animated: false)
			}
		}
	}
	
	@objc func networkDisconnected() {
		DispatchQueue.main.async {
			guard self.navigationController?.visibleViewController == self else { return }
			self.setPrompt("You are offline.")
		}
	}
	
	@objc func networkConnected() {
		DispatchQueue.main.async {
			guard self.navigationController?.visibleViewController == self else { return }
			self.setPrompt(nil)
		}
		
		self.reloadData()
	}
	
	// MARK: - UITableViewController methods
	override public func numberOfSections(in tableView: UITableView) -> Int {
		return self.fetchedResultsController.sections?.count ?? 0
	}
	
	override public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		guard let sections = self.fetchedResultsController.sections else { return nil }
		let fetchedResultControllerSectionName = sections[section].name
		
		/// If the delegate method is overridden (`sectionName(for:_)`), use the section names from that instead.
		if let configuredSectionName = self.sectionName(for: fetchedResultControllerSectionName) {
			return configuredSectionName
		} else {
			return sections[section].name
		}
	}
	
	override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if let sections = self.fetchedResultsController.sections {
			return sections[section].numberOfObjects
		} else {
			return self.fetchedResultsController.fetchedObjects?.count ?? 0
		}
	}
	
	override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		return self.cellForRow(tableView, at: indexPath, for: self.fetchedResultsController.object(at: indexPath))
	}
	
	override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		self.cellDidSelect(tableView, at: indexPath, for: self.fetchedResultsController.object(at: indexPath))
	}
	
	@available(iOS 11.0, *)
	override public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		self.trailingSwipeActionsConfigurationForRowAt(tableView, at: indexPath, for: self.fetchedResultsController.object(at: indexPath))
	}
	
	// MARK: - NSFetchedResultsControllerDelegate methods
	public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		self.tableView.beginUpdates()
	}
	
	public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
						   didChange sectionInfo: NSFetchedResultsSectionInfo,
						   atSectionIndex sectionIndex: Int,
						   for type: NSFetchedResultsChangeType) {
		let indexSet = IndexSet(integer: sectionIndex)
		switch type {
		case .insert: self.tableView.insertSections(indexSet, with: .automatic)
		case .delete: self.tableView.deleteSections(indexSet, with: .automatic)
		default: break
		}
	}
	
	public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
						   didChange anObject: Any,
						   at indexPath: IndexPath?,
						   for type: NSFetchedResultsChangeType,
						   newIndexPath: IndexPath?) {
		switch (type) {
		case .insert:
			if let indexPath = newIndexPath {
				tableView.insertRows(at: [indexPath], with: .fade)
			}
			break
		case .delete:
			if let indexPath = indexPath {
				tableView.deleteRows(at: [indexPath], with: .fade)
			}
			break
		case .update:
			if let indexPath = indexPath {
				tableView.reloadRows(at: [indexPath], with: .fade)
			}
			break
		case .move:
			if let indexPath = indexPath {
				tableView.deleteRows(at: [indexPath], with: .fade)
			}

			if let newIndexPath = newIndexPath {
				tableView.insertRows(at: [newIndexPath], with: .fade)
			}
			break
		@unknown default: fatalError("Unknown case.")
		}
	}
	
	public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		self.tableView.endUpdates()
	}
	
	public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, sectionIndexTitleForSectionName sectionName: String) -> String? {
		return self.sectionName(for: sectionName)
	}
}
