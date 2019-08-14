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
/// it isn't static, this table view updates automatically ("dynamically") as the core data stack updates, preventing stale data.
/// There are a number of additions that lets the user know if they do not have a network connection.
/// This view controller uses Generics to ensure type safety. This class is not compatible with Obj-C.
///
/// ## Usage
/// ### Basic
/// ```swift
/// let vc = OBAFetchedTableViewController<OBARegion>()
/// ```
///
/// The block above is enough to get started. If no explicit `fetchRequest` is provided, it will use the default
/// to `OBAManagedObject.fetchRequest`.
///
/// ### Predicates
/// ```swift
/// let vc = OBAFetchedTableViewController<OBARegion>()
/// let fetchRequest = OBARegion.sortedFetchRequest
/// fetchRequest.predicate = NSPredicate(format: "isActive == YES")
///
/// vc.fetchRequest = fetchRequest
/// ```
/// The block above is an example of providing your own fetch request. Note that the entity type of your fetch request
/// **MUST** match the generic type of `OBAFetchedTableViewController`, this is compiler-enforced.
///
/// ## Configuration
/// There are a number of configuration methods you can override to match the appearance and behavior you want. Most
/// are wrappers of `UITableViewDataSource` and `UITableViewDelegate`, but they also include the corresponding
/// object as a method parameter, so you don't have to access `fetchedResultsController.object(at:_)` yourself.
/// Take a look at the headers of this class to see what you should override.
///
/// For the most part, this view controller works out-of-the-box, but only presents basic information relevant to the fetch request.
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
	
	// MARK: - UI State stuff
	public var showActivityIndicator: Bool = false {
		didSet {
			self.showActivityIndicator ? self.activityIndicator.startAnimating() : self.activityIndicator.stopAnimating()
			self.navigationController?.setToolbarHidden(!self.showActivityIndicator, animated: true)
		}
	}
	
	fileprivate lazy var activityIndicator: UIActivityIndicatorView = {
		let view = UIActivityIndicatorView(style: .gray)
		view.hidesWhenStopped = true
		
		return view
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
		
		self.loadData()
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
	
	// default implementation
	public func loadData() {
		fatalError("loadData(:_) not implemented.")
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
		// rdar://43522696 https://openradar.appspot.com/43522696
		UIView.animate(withDuration: 0.3) {
			self.navigationController?.setNavigationBarHidden(true, animated: false)
			self.navigationItem.prompt = prompt
			self.navigationController?.setNavigationBarHidden(false, animated: false)
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
		
		self.loadData()
	}
	
	// MARK: - UITableViewController methods
	override public func numberOfSections(in tableView: UITableView) -> Int {
		return self.fetchedResultsController.sections?.count ?? 0
	}
	
	override public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		guard let sections = self.fetchedResultsController.sections else { return nil }
		return sections[section].name
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
		
		switch type {
		case .insert: 	self.tableView.insertRows(at: [newIndexPath!], with: .automatic)
		case .update: 	self.tableView.reloadRows(at: [indexPath!], with: .automatic)
		case .delete:	self.tableView.deleteRows(at: [indexPath!], with: .automatic)
		case .move:		self.tableView.moveRow(at: indexPath!, to: newIndexPath!)
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
