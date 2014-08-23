//
//  ViewController.swift
//  SwiftWeather
//
//  Created by Edward on 14-8-13.
//  Copyright (c) 2014 Edward. All rights reserved.
//

import UIKit
import CoreLocation
import Foundation

class ViewController: UIViewController,CLLocationManagerDelegate ,updateCityProtocol {
    
    @IBOutlet var location : UILabel
    @IBOutlet var temperature : UILabel
    @IBOutlet var switchButton : UIButton
    
    @IBOutlet var loading : UILabel
    @IBOutlet var icon : UIImageView
    @IBOutlet var loadingIndicator : UIActivityIndicatorView
    
    let locationManager:CLLocationManager = CLLocationManager()
    var cityList:NSMutableArray = NSMutableArray()
    var dataFilePath:String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        initDataFilePath()
        self.loadData()
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest //
        locationManager.delegate = self
        self.loadingIndicator.startAnimating()
        
        let background = UIImage(named: "background.png")
        self.switchButton.font = UIFont.boldSystemFontOfSize(9)
        self.view.backgroundColor = UIColor(patternImage: background)
        
        let singleFingerTap = UITapGestureRecognizer(target: self, action: "handleSingleTap:")
        self.view.addGestureRecognizer(singleFingerTap)
        
        if (ios8()){
            locationManager.requestAlwaysAuthorization()
        }
        
        locationManager.startUpdatingLocation()
    }
    
    func ios8() ->Bool{
        return UIDevice.currentDevice().systemVersion == "8.0"
    }
    
    func handleSingleTap(recognizer: UITapGestureRecognizer){
        locationManager.startUpdatingLocation()
    }

    func initDataFilePath()
    {
        var paths:NSArray = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory , NSSearchPathDomainMask.UserDomainMask, true)
        var documentsDirectory = paths.firstObject as String
        dataFilePath = documentsDirectory.stringByAppendingPathComponent("citys.list")
        println(dataFilePath)
    }
    
    func loadData (){
//        var city=["cityname":"ShenZhen Weather","latitude":22.61667,"longitude":114.06667]
//        cityList.addObject(city)
        
        var path:String = dataFilePath
        if(NSFileManager.defaultManager().fileExistsAtPath(path)){
            let data:NSData = NSData(contentsOfFile: path)
            let unarchiver:NSKeyedUnarchiver = NSKeyedUnarchiver(forReadingWithData: data)
            cityList = unarchiver.decodeObjectForKey("citys") as NSMutableArray
            //println("Hello")
            unarchiver.finishDecoding()
        } else {
            var city=["cityname":"ShangHai Weather","latitude":34.50000,"longitude":121.43333]
            cityList.addObject(city)
        }
    }
    
    func loadLocalInfo (latitude: CLLocationDegrees ,longitude: CLLocationDegrees){
        for cityName:AnyObject in cityList {
            if (cityName["cityname"] as NSString == "Local Weather") {
                cityList.removeObject(cityName)
            }
        }
        
        var city=["cityname":"Local Weather","latitude":latitude,"longitude":longitude]
        cityList.insertObject(city, atIndex: 0)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!){
        var citys:CityListController = segue.destinationViewController as CityListController
        citys.delegate = self
        citys.cityList = self.cityList
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: AnyObject[]!){
        var location:CLLocation = locations[locations.count-1] as CLLocation
        
        if ( location.horizontalAccuracy > 0 ){
            println(location.coordinate.latitude)
            println(location.coordinate.longitude)
            
            self.updateWeatherInfo(location.coordinate.latitude, longitude:location.coordinate.longitude)
            loadLocalInfo(location.coordinate.latitude, longitude:location.coordinate.longitude)
            
            locationManager.stopUpdatingLocation()
            savecitylist()
        }
    }
    
    func updateWeatherInfo(latitude: CLLocationDegrees ,longitude: CLLocationDegrees){
        let manager = AFHTTPRequestOperationManager()
        let url = "http://api.openweathermap.org/data/2.5/weather"
        println(url)

        var params = ["lat":latitude, "lon":longitude, "cnt":0]
        manager.GET(url,
            parameters: params,
            success: { (operation:AFHTTPRequestOperation!, responseObject: AnyObject!) in
                println("JSON: " + responseObject.description!)
            
            self.updateUISuccess(responseObject as NSDictionary!)
            },
            failure: { (operation:AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
                
                self.loading.text = "Internet appears down!"
                
                })
    }
    
    func locationManager(manager:CLLocationManager!, didFailWithError error:NSError!){
        println(error)
        self.loading.text = "获取不到地理位置信息"
    }
    
    func updateUISuccess(jsonResult: NSDictionary!){
        
        self.loadingIndicator.hidden = true
        self.loadingIndicator.stopAnimating()
        self.loading.text = nil
        
        if ( jsonResult["main"]?["temp"]? as? Double ){
            var temperature: Double
            let tempResult = jsonResult["main"]?["temp"]? as Double
//            if ( jsonResult["sys"]?["country"]? as String == "US" ){
//                // Convert temperature to Fathrenheit if user is within the US
//                temperature = round(((tempResult - 273.15) * 1.8) + 32 )
//            } else {
                //Otherwise, convert temperature to Celsius
                temperature = round(tempResult - 273.15)
//            }
            
            self.temperature.text = "\(temperature)℃"
            self.temperature.font = UIFont.boldSystemFontOfSize(60)
            
            var cityname = jsonResult["name"]? as String
            self.location.text = "\(cityname)"
            self.location.font = UIFont.boldSystemFontOfSize(25)
            
            var condition = (jsonResult["weather"]? as NSArray)[0]?["id"]? as Int
            var sunrise = jsonResult["sys"]?["sunrise"]? as Double
            var sunset = jsonResult["sys"]?["sunset"]? as Double
            
            var nightTime = false
            var now = NSDate().timeIntervalSince1970
            
            if( now < sunrise || now > sunset ) {
                nightTime = true
            }
            self.updateWeatherIcon(condition,nightTime: nightTime)
        } else {
            self.loading.text = "天气信息不可用"
        }
        
    }
    
    func updateWeatherIcon(condition: Int,nightTime: Bool){
        if( condition < 300 ) {
            if nightTime {
                self.icon.image = UIImage(named: "tstorm1_night")
            } else {
                self.icon.image = UIImage(named: "tstorm1")
            }
        }// Drizzle
        else if ( condition < 500 ) {
            self.icon.image = UIImage(named: "light_rain")
        }// Rain / Freezing rain / Shower rain
        else if ( condition < 600 ) {
            self.icon.image = UIImage(named: "shower3")
        }// Snow
        else if ( condition < 700 ) {
            self.icon.image = UIImage(named: "snow4")
        }// Fog / Mist / Haze / etc
        else if ( condition < 771 ) {
            if nightTime {
                self.icon.image = UIImage(named: "fog_night")
            } else {
                self.icon.image = UIImage(named: "fog")
            }
        }// Tornado / Squalls
        else if ( condition < 800 ) {
            self.icon.image = UIImage(named: "tstorm3")
        }// Sky is clear
        else if ( condition == 800 ) {
            if nightTime {
                self.icon.image = UIImage(named: "sunny_night") // sunny night
            } else {
                self.icon.image = UIImage(named: "sunny")
            }
        }// few / scattered / broken clouds
        else if ( condition < 804 ) {
            if nightTime {
                self.icon.image = UIImage(named: "cloudy2_night")
            } else {
                self.icon.image = UIImage(named: "cloudy2")
            }
        }// overcast clouds
        else if ( condition == 804 ) {
            self.icon.image = UIImage(named: "overcast")
        }// Extreme
        else if (( condition >= 900 && condition < 903 )||( condition > 904 && condition < 1000 )) {
            self.icon.image = UIImage(named: "tstorm3")
        }// Cold
        else if ( condition == 903 ) {
            self.icon.image = UIImage(named: "snow5")
        }// Hot
        else if ( condition == 904 ) {
            self.icon.image = UIImage(named: "sunny")
        }// Weather condition is not available
        else {
            self.icon.image = UIImage(named: "dunno")
        }
    }
    
    func savecitylist() {
        var data:NSMutableData = NSMutableData()
        var archiver:NSKeyedArchiver = NSKeyedArchiver(forWritingWithMutableData: data)
        archiver.encodeObject(cityList, forKey:"citys")
        archiver.finishEncoding()
        data.writeToFile(dataFilePath, atomically:true)
    }
    
}

