//
//  ViewController.swift
//  weather
//
//  Created by Onur on 11.12.2019.
//  Copyright © 2019 Cemal Onur Tokoglu. All rights reserved.
//

import UIKit

class MainVc: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    @IBOutlet var tableView: UITableView!
    @IBOutlet var textField: UITextField!
    
    private var lastSearch = ""
    private var loadingView: LoadingView?
    private var weatherData: WeatherData? {
        didSet {
            // automatically reload tableview on ui thread when data changed
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    // for adding loading overlay without calling a function
    // e.g self.loading = true adds the loading view, false removes it
    private var loading: Bool {
        get { return false } // not used
        set {
            DispatchQueue.main.async {
                self.loadingView?.removeFromSuperview()
                if newValue {
                    self.addLoading()
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        
        // dismiss keyboard when tapped around
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.allowsSelection = true
        
        self.textField.returnKeyType = .search
        self.textField.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    @objc func dismissKeyboard(){
        self.view.endEditing(true)
    }

    @IBAction func searchTapped(_ sender: Any) {
        guard let city = textField.text, city.count > 2, city != lastSearch else {
            return
        }
        self.loading = true
        self.lastSearch = city
        WeatherService.getInitialForecasts(city: city) { (error, weatherData) in
            self.loading = false
            if let error = error {
                self.weatherData = nil
                self.handleApiError(error: error)
                return
            }
            self.weatherData = weatherData
        }
    }
    
    private var isLoadingForecasts = false
    private func loadMoreForecasts() {
        guard !isLoadingForecasts, let weatherData = self.weatherData else {return}
        isLoadingForecasts = true
        WeatherService.loadMoreForecasts(prevData: weatherData) { (error, data) in
            self.isLoadingForecasts = false
            if let error = error {
                self.handleApiError(error: error)
                return
            }
            self.weatherData = data
        }
    }
    
    private func handleApiError(error: WeatherService.ApiError){
        switch error {
        case .cityNotFound:
            self.showAlert(message: "City not found")
        case .serializationError:
            self.showAlert(message: "Serialization error")
        case .general(let s):
            self.showAlert(message: s)
        }
    }
    
    
    
    private func addLoading(){
        self.loadingView = LoadingView()
        self.loadingView?.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        self.view.addSubview(self.loadingView!)
        self.loadingView?.addFullScreenConstraints(parent: self.view)
    }
    
    private func showAlert(message: String){
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func pushDetail(forecast: Forecast){
        let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "WeatherDetailVc") as! WeatherDetailVc
        vc.setForecast(forecast: forecast)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    
    // MARK: DELEGATES
    
    // Table View
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let weatherData = self.weatherData else { return 0 }
        return weatherData.forecasts.count + (weatherData.hasMoreForcasts ? 1 : 0) // 1 more cell for activity indicator
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let weatherData = self.weatherData else { return UITableViewCell() }
        
        if indexPath.row == weatherData.forecasts.count {
            loadMoreForecasts()
            let cell = tableView.dequeueReusableCell(withIdentifier: "LoadingCell", for: indexPath) as! LoadingCell
            cell.animate()
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "WeatherCell", for: indexPath) as! WeatherCell
        cell.initWithForecast(forecast: weatherData.forecasts[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.setSelected(false, animated: true)
        guard let weatherData = self.weatherData, indexPath.row < weatherData.forecasts.count else { return }
        pushDetail(forecast: weatherData.forecasts[indexPath.row])
    }
    
    // Textfield
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        searchTapped("")
        return true
    }
}


class WeatherCell: UITableViewCell {
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var temperatureLabel: UILabel!
    @IBOutlet var weatherLabel: UILabel!
    
    func initWithForecast(forecast: Forecast){
        self.timeLabel.text = forecast.dateString
        self.temperatureLabel.text = "Temp: \(forecast.temperature)°C"
        self.weatherLabel.text = "Weather: \(forecast.weather)"
    }
    
}

class LoadingCell: UITableViewCell {
    @IBOutlet var activityView: UIActivityIndicatorView!
    
    func animate(){
        activityView.startAnimating()
    }
}


class LoadingView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        addActivity()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        addActivity()
    }
    private func addActivity(){
        let activity = UIActivityIndicatorView(style: .gray)
        activity.startAnimating()
        self.addSubview(activity)
        activity.addCenterConstraints(parent: self)
    }
    deinit {
        print("loading view deinit")
    }
}
