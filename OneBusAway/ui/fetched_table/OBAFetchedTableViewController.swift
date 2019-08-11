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

/// Provide a list template for core data fetched data. This differs from OBAStaticTableViewController in that
/// it isn't static, this table view updates automatically ("dynamically") as the core data stack updates, preventing stale data.
/// In addition, this view controllers uses Generics to ensure type safety. This class in not compatible with Obj-C as a result.
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
/// Browse to the section `User configuration methods` to see what you should override.
///
/// For the most part, this view controller works out-of-the-box, but only presents basic information relevant to the fetch request.
public class OBAFetchedTableViewController<O: OBAManagedObject>: UITableViewController, NSFetchedResultsControllerDelegate {
	var fetchedResultsController: NSFetchedResultsController<O>!
	var fetchRequest: NSFetchRequest<O>! {
		didSet {
			fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
																  managedObjectContext: CD_OBAModelDAO.shared.viewContext,
																  sectionNameKeyPath: nil,
																  cacheName: nil)
			fetchedResultsController.delegate = self
		}
	}
	
	override public func viewDidLoad() {
		super.viewDidLoad()
		
		// If a fetch request was not provided during initialization, use the default implementation for the time being.
		if fetchRequest == nil {
			fetchRequest = O.sortedFetchRequest
		}
		
		do {
			try self.fetchedResultsController.performFetch()
		} catch {
			print(error)
		}
	}
	
	override public func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.loadData()
	}
	
	// MARK: - Overridable configuration methods
	public func cellForRow(_ tableView: UITableView, at indexPath: IndexPath, for item: O) -> UITableViewCell {
		// Default implementation
		let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
		cell.textLabel?.text = item.identifier
		cell.detailTextLabel?.text = item.entity.name
		
		return cell
	}
	
	public func cellDidSelect(_ tableView: UITableView, at indexPath: IndexPath, for item: O) { }
	public func loadData() { fatalError("loadData(:_) not implemented.") }
	
	// MARK: - UITableViewController methods
	override public func numberOfSections(in tableView: UITableView) -> Int {
		return self.fetchedResultsController.sections?.count ?? 0
	}
	
	override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.fetchedResultsController.sections?[section].numberOfObjects ?? 0
	}
	
	override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		return self.cellForRow(tableView, at: indexPath, for: self.fetchedResultsController.object(at: indexPath))
	}
	
	override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		self.cellDidSelect(tableView, at: indexPath, for: self.fetchedResultsController.object(at: indexPath))
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
		guard let indexPath = indexPath else { return }
		
		switch type {
		case .insert: 	self.tableView.insertRows(at: [indexPath], with: .automatic)
		case .update: 	self.tableView.reloadRows(at: [indexPath], with: .automatic)
		case .move: 	self.tableView.moveRow(at: indexPath, to: newIndexPath!)
		case .delete:	self.tableView.deleteRows(at: [indexPath], with: .automatic)
		@unknown default: fatalError("Unknown case.")
		}
	}
	
	public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		self.tableView.endUpdates()
	}
}
