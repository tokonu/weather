//
//  WeatherService.swift
//  weather
//
//  Created by Onur on 12.12.2019.
//  Copyright © 2019 Cemal Onur Tokoglu. All rights reserved.
//

import Foundation


class WeatherService {
    static let BaseUrl = URL(string: "https://api.openweathermap.org/data/2.5/forecast")!
    static let AppId = "c3369489cb9057038da2acc88cc3b728"
    
    enum ApiError: Error {
        case cityNotFound
        case serializationError
        case general(String)
    }
    
    typealias ForecastCallback = (ApiError?, WeatherData?) -> ()
    
    private static func getForecastFor(city: String, callback: ForecastCallback?){
        let url = BaseUrl.urlWithQueryMap(queryMap: getQueryMap(city: city))
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard error == nil, let data = data else {
                callback?(ApiError.general("Api error: \(error?.localizedDescription ?? "")"), nil)
                return
            }
            do {
                let res = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
                let status = (res["cod"] as? String) ?? (res["cod"] as? NSNumber)?.stringValue ?? "-1"
                if status == "404" {
                    callback?(ApiError.cityNotFound, nil)
                    return
                }
                if status != "200" {
                    callback?(ApiError.general("Api status \(status)"), nil)
                    return
                }
                if let weatherData = WeatherData(dict: res) {
                    callback?(nil, weatherData)
                    return
                }else{
                    callback?(ApiError.serializationError, nil)
                    return
                }
            } catch {
                callback?(ApiError.serializationError, nil)
            }
        }
        task.resume()
    }
    
    static func getInitialForecasts(city: String, callback: ForecastCallback?){
        getForecastFor(city: city) { (error, weatherData) in
            if let weatherData = weatherData {
                sleep(3) // TODO delete
                weatherData.maxResults = weatherData.forecasts.count
                weatherData.forecasts = Array(weatherData.forecasts[0..<10])
                callback?(error, weatherData)
            }else{
                callback?(error, weatherData)
            }
        }
    }
    
    // to simulate paged api response
    static func loadMoreForecasts(prevData: WeatherData, callback: ForecastCallback?){
        if !prevData.hasMoreForcasts {
            print("no more forecasts")
            return
        }
        let startIndex = prevData.forecasts.count
        print("loading forecasts from \(startIndex)")
        getForecastFor(city: prevData.city) { (error, weatherData) in
            sleep(3) // TODO delete
            if let weatherData = weatherData {
                weatherData.forecasts = Array(weatherData.forecasts.prefix(startIndex + 10))
                callback?(error, weatherData)
            }else{
                callback?(error, weatherData)
            }
        }
    }
    
    private static func getQueryMap(city: String) -> [String: String]{
        return [
            "APPID": AppId,
            "units": "metric",
            "q": city
        ]
    }
}

class WeatherData {
    internal init(city: String, timezone: Double, forecasts: [Forecast]) {
        self.city = city
        self.timezone = timezone
        self.forecasts = forecasts
    }
    
    let city: String
    let timezone: Double // offset from gmt in seconds
    var forecasts: [Forecast]
    var maxResults = 40
    var hasMoreForcasts: Bool {
        get {
            return forecasts.count < maxResults
        }
    }
    
    convenience init?(dict: [String: Any]) {
        guard let cityInfo = dict["city"] as? [String: Any],
            let cityName = cityInfo["name"] as? String,
            let timezone = cityInfo["timezone"] as? Double,
            let forecastsList = dict["list"] as? [[String: Any]] else {
            return nil
        }
        var forecasts = [Forecast]()
        for fd in forecastsList {
            if let f = Forecast(dict: fd) {
                forecasts.append(f)
            }
        }
        self.init(city: cityName, timezone: timezone, forecasts: forecasts)
    }
}

class Forecast {
    let timestamp: Double
    let temperature: Double
    let weather: String
    var dateString: String {
        get {
            let date = Date(timeIntervalSince1970: self.timestamp)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEEE HH:mm"
            return dateFormatter.string(from: date)
        }
    }
    
    internal init(timestamp: Double, temperature: Double, weather: String) {
        self.timestamp = timestamp
        self.temperature = temperature
        self.weather = weather
    }
    
    convenience init?(dict: [String: Any]) {
        guard let timestamp = dict["dt"] as? Double,
        let mainDict = dict["main"] as? [String: Any],
        let temperature = mainDict["temp"] as? Double,
        let weatherArr = dict["weather"] as? [[String: Any]],
        let weatherStr = weatherArr.first?["main"] as? String else {
            return nil
        }
        self.init(timestamp: timestamp, temperature: temperature, weather: weatherStr)
    }
}
