//
//  RegionsViewController.swift
//  OneBusAway
//
//  Created by Alan Chu on 8/11/19.
//  Copyright © 2019 OneBusAway. All rights reserved.
//

import UIKit
import CoreData
import os.log

public class RegionsViewController: OBAFetchedTableViewController<CD_OBARegion> {
	public static let ReuseIdentifier = "RegionsViewController_ReuseIdentifier"

	public override func viewDidLoad() {
		self.title = "Regions"
		self.sectionNameKeyPath = "isExperimental"
		
		let acceptableRegionsOnlyRequest = CD_OBARegion.fetchedRequest
		acceptableRegionsOnlyRequest.predicate = NSPredicate(format: "isActive == YES AND supportsOBARealtimeAPIs == YES")
		acceptableRegionsOnlyRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CD_OBARegion.isExperimental, ascending: true),
														NSSortDescriptor(keyPath: \CD_OBARegion.regionName, ascending: true)]
		self.fetchRequest = acceptableRegionsOnlyRequest
		
		super.viewDidLoad()

		NotificationCenter.default.addObserver(self, selector: #selector(regionDidUpdate), name: OBAWebService.Notifications.didChangeRegion.name, object: nil)
		
		if #available(iOS 13, *) {
			self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(createCustomRegion))
		}
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	public override func loadData() -> Promise<[CD_OBARegion]> {
		return CD_OBAModelDAO.shared.webService.fetch(.regions, as: CD_OBARegion.self)
	}
	
	@objc func regionDidUpdate() {
		self.tableView.reloadData()
	}
	
	public override func cellDidSelect(_ tableView: UITableView, at indexPath: IndexPath, for item: CD_OBARegion) {
		CD_OBAModelDAO.shared.currentRegion = item
	}
	
	public override func cellForRow(_ tableView: UITableView, at indexPath: IndexPath, for item: CD_OBARegion) -> UITableViewCell {
		let cell = self.tableView.dequeueReusableCell(withIdentifier: RegionsViewController.ReuseIdentifier) ?? UITableViewCell(style: .subtitle, reuseIdentifier: RegionsViewController.ReuseIdentifier)

		cell.textLabel?.text = item.regionName
		cell.detailTextLabel?.text = item.isCustom ? "Custom Region" : nil
		cell.accessoryType = item.identifier == CD_OBAModelDAO.shared.currentRegion?.identifier ? .checkmark : .none

		return cell
	}
	
	@available(iOS 11.0, *)
	public override func trailingSwipeActionsConfigurationForRowAt(_ tableView: UITableView, at indexPath: IndexPath, for item: CD_OBARegion) -> UISwipeActionsConfiguration? {
		guard item.isCustom else { return nil }
		guard #available(iOS 13, *) else { return nil }
		
		let edit = UIContextualAction(style: .normal, title: "Edit") { action, view, success in
			self.editRegion(item)
			success(true)
		}
		
		let delete = UIContextualAction(style: .destructive, title: "Delete") { action, view, success in
			success(false)
		}
		
		return UISwipeActionsConfiguration(actions: [edit, delete])
	}
	
	public override func sectionName(for sectionIndexName: String) -> String? {
		let isCustom = sectionIndexName == "1"
		if isCustom {
			return NSLocalizedString("region_list_controller.experimental_section_title", comment: "")
		} else {
			return NSLocalizedString("msg_active_regions", comment: "")
		}
	}
}
