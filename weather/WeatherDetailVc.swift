//
//  WeatherDetailVc.swift
//  weather
//
//  Created by Onur on 12.12.2019.
//  Copyright © 2019 Cemal Onur Tokoglu. All rights reserved.
//

import UIKit

class WeatherDetailVc: UIViewController {
    @IBOutlet var tempLabel: UILabel!
    @IBOutlet var weatherLabel: UILabel!
    private var forecast: Forecast?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let forecast = self.forecast {
            self.tempLabel.text = "Temperature: \(forecast.temperature)°C"
            self.weatherLabel.text = "Weather: \(forecast.weather)"
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    func setForecast(forecast: Forecast){
        self.title = forecast.dateString
        self.forecast = forecast
    }
}
