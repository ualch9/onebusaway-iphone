//
//  RegionsViewController.swift
//  OneBusAway
//
//  Created by Alan Chu on 8/11/19.
//  Copyright © 2019 OneBusAway. All rights reserved.
//

import UIKit
import CoreData

public class RegionsViewController: OBAFetchedTableViewController<CD_OBARegion> {
	public static let ReuseIdentifier = "RegionsViewController_ReuseIdentifier"
	
	public override func viewDidLoad() {
		let acceptableRegionsOnlyRequest = CD_OBARegion.fetchedRequest
		acceptableRegionsOnlyRequest.predicate = NSPredicate(format: "isActive == YES AND supportsOBARealtimeAPIs == YES")
		acceptableRegionsOnlyRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CD_OBARegion.regionName, ascending: true)]
		self.fetchRequest = acceptableRegionsOnlyRequest
		
		super.viewDidLoad()
	}
	
	public override func loadData() {
		CD_OBAModelDAO.shared.webService.fetch(.regions, as: CD_OBARegion.self).then {
			print("Success: \($0.count)")
		}.catch {
			print("Error: \($0)")
		}.always {
			try! self.fetchedResultsController.performFetch()
		}
	}
	
	public override func cellDidSelect(_ tableView: UITableView, at indexPath: IndexPath, for item: CD_OBARegion) {
		print("Selected \(item.regionName)")
	}
	
	public override func cellForRow(_ tableView: UITableView, at indexPath: IndexPath, for item: CD_OBARegion) -> UITableViewCell {
		let cell = self.tableView.dequeueReusableCell(withIdentifier: RegionsViewController.ReuseIdentifier) ?? UITableViewCell(style: .subtitle, reuseIdentifier: RegionsViewController.ReuseIdentifier)
		cell.textLabel?.text = item.regionName
		cell.detailTextLabel?.text = "OBARegion: \(item.identifier)"
		
		return cell
	}
}
