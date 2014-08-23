//
//  CityListController.swift
//  SwiftWeather
//
//  Created by Edward on 14-8-18.
//  Copyright (c) 2014 Edward. All rights reserved.
//

import UIKit
import CoreLocation

protocol updateCityProtocol{
    func updateWeatherInfo(latitude: CLLocationDegrees ,longitude: CLLocationDegrees)
}

class CityListController: UIViewController ,UITableViewDelegate ,UITableViewDataSource {
    
    var cityList:NSArray = NSArray()
    var delegate:updateCityProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        return cityList.count
    }
    
    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        let cell=UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "citys")
        let rowData:NSDictionary = self.cityList[indexPath.row] as NSDictionary
        cell.text = rowData["cityname"] as NSString
        return cell
    }
    
    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        let rowData:NSDictionary = self.cityList[indexPath.row] as NSDictionary
        let latitude = rowData["latitude"] as CLLocationDegrees
        let longitude = rowData["longitude"] as CLLocationDegrees
        delegate?.updateWeatherInfo(latitude,longitude: longitude)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}