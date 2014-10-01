//
//  HYBRootController.swift
//  WeatherSwiftDemo
//
//  Created by huangyibiao on 14-9-30.
//  Copyright (c) 2014年 Uni2Uni. All rights reserved.
//

import UIKit
import CoreLocation

/*!
@brief 天气预报视图控制器类
@author huangyibiao
*/
class HYBRootController: UIViewController, CLLocationManagerDelegate {
    //-----------
    // 成员变量
    //-----------
    @IBOutlet weak var loadingLabel: UILabel!
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var temperatureLabel: UILabel!
    
    // 定位管理,使用过程中不可变，因此声明为常量
    let locationManager = CLLocationManager();
    
    //-----------
    // 生命周期函数
    //-----------
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 配置定位管理器的相关属性
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // 开启转圈圈
        indicatorView.startAnimating();
        
        // 设置背景
        let backgroundImageView = UIImageView(frame: self.view.bounds)
        backgroundImageView.image = UIImage(named: "background.png")
        backgroundImageView.contentMode = UIViewContentMode.ScaleAspectFill
        self.view.addSubview(backgroundImageView)
        
        // 添加一个点击手势
        let tap = UITapGestureRecognizer(target: self, action: "onTapHandle:")
        self.view.addGestureRecognizer(tap)
        
        // 8.0以后才有的函数，要求经过验证才能开启定位
        if isIOS8OrLater() {
            locationManager.requestAlwaysAuthorization()
        }
        // 启动定位
        locationManager.startUpdatingLocation()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //-----------
    // 事件处理函数
    //-----------
    func onTapHandle(sender: UITapGestureRecognizer!) {
        locationManager.startUpdatingLocation()
    }
    
    //-----------
    // CLLocationManagerDelegate
    //-----------
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        // 获取最后一个位置
        var location = locations.last as CLLocation
        
        if location.horizontalAccuracy > 0 {
            locationManager.stopUpdatingLocation()
            
            // 更新界面显示
            requestWeatherInformation(location)
        }
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        println(error)
    }
    
    //-----------
    // 铺助类函数
    //-----------
    
    //
    // @brief 判断是否是8.0及其以后的操作系统
    //
    func isIOS8OrLater() -> Bool {
        return UIDevice.currentDevice().systemVersion >= "8.0"
    }
    
    //
    // @brief 获取天气信息
    //
    func requestWeatherInformation(location: CLLocation!) {
        // 取得AF的网络请求管理对象
        let httpManager = AFHTTPRequestOperationManager()
        let url = "http://api.openweathermap.org/data/2.5/weather"
        let params = ["lat" : location.coordinate.latitude, "lon" : location.coordinate.longitude, "cnt" : 0]
        
        // GET请求
        httpManager.GET(url, parameters: params, success: {(operation: AFHTTPRequestOperation!, responseObject: AnyObject!) -> Void in             // success
            // 更新UI显示
            self.updateWeather(JSONObject: responseObject as NSDictionary)
            },
            {(operation: AFHTTPRequestOperation!, error: NSError!) -> Void in // failure
                self.loadingLabel.text = "Internet appears down!"
        })
    }
    
    //
    // @brief 更新天气界面信息
    //
    func updateWeather(JSONObject responseObject: NSDictionary!) {
        self.loadingLabel.text = ""
        self.indicatorView.hidden = true
        self.indicatorView.stopAnimating()
        
        var tempResultDict: AnyObject? = responseObject["main"]
        var tempResult: Double = (tempResultDict as NSDictionary)["temp"] as Double

        var temperature = 0.0
        if (responseObject["sys"] as NSDictionary)["country"] as String == "US" {
            temperature = round(((tempResult - 273.15) * 1.8) + 32)
        } else {
            temperature = round(tempResult - 273.15)
        }
        
        // 更新气温值
        self.temperatureLabel.font = UIFont.boldSystemFontOfSize(60)
        self.temperatureLabel.text = "\(temperature)°"
        
        var name = responseObject["name"]! as String
        self.locationLabel.font = UIFont.boldSystemFontOfSize(25)
        self.locationLabel.text = "\(name)"
        
        // 这些写法都是不太好的，一旦为空，会崩溃，初学，再慢慢优化
        var condition = (responseObject["weather"] as NSDictionary)[0]!["id"] as Int
        var sunrise = (responseObject["sys"] as NSDictionary)["sunrise"] as Double
        var sunset = responseObject["sys"]!["sunset"] as Double
        
        var nightTime = false
        var now = NSDate().timeIntervalSince1970
        if (now < sunrise || now > sunset) {
            nightTime = true
        }
        self.updateWeatherimageView(condition, isNightTime: nightTime)
    }
    
    //
    // @brief 更新天气界面信息
    //
    func updateWeatherimageView(condition: Int, isNightTime: Bool) {
        // 雷暴雨
        if (condition < 300) {
            if isNightTime {
                self.imageView.image = UIImage(named: "tstorm1_night")
            } else {
                self.imageView.image = UIImage(named: "tstorm1")
            }
        }
        // Drizzle
        else if (condition < 500) {
            self.imageView.image = UIImage(named: "light_rain")
        }
        // Rain / Freezing rain / Shower rain
        else if (condition < 600) {
            self.imageView.image = UIImage(named: "shower3")
        }
        // Snow
        else if (condition < 700) {
            self.imageView.image = UIImage(named: "snow4")
        }
        // Fog / Mist / Haze / etc.
        else if (condition < 771) {
            if isNightTime {
                self.imageView.image = UIImage(named: "fog_night")
            } else {
                self.imageView.image = UIImage(named: "fog")
            }
        }
        // Tornado / Squalls
        else if (condition < 800) {
            self.imageView.image = UIImage(named: "tstorm3")
        }
        // Sky is clear
        else if (condition == 800) {
            if (isNightTime){
                self.imageView.image = UIImage(named: "sunny_night") // sunny night?
            }
            else {
                self.imageView.image = UIImage(named: "sunny")
            }
        }
        // few / scattered / broken clouds
        else if (condition < 804) {
            if (isNightTime){
                self.imageView.image = UIImage(named: "cloudy2_night")
            }
            else{
                self.imageView.image = UIImage(named: "cloudy2")
            }
        }
        // overcast clouds
        else if (condition == 804) {
            self.imageView.image = UIImage(named: "overcast")
        }
        // Extreme
        else if ((condition >= 900 && condition < 903) || (condition > 904 && condition < 1000)) {
            self.imageView.image = UIImage(named: "tstorm3")
        }
        // Cold
        else if (condition == 903) {
            self.imageView.image = UIImage(named: "snow5")
        }
        // Hot
        else if (condition == 904) {
            self.imageView.image = UIImage(named: "sunny")
        }  else {
            // Weather condition not available
            self.imageView.image = UIImage(named: "dunno")
        }
    }
}
