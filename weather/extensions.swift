//
//  extensions.swift
//  weather
//
//  Created by Onur on 12.12.2019.
//  Copyright © 2019 Cemal Onur Tokoglu. All rights reserved.
//

import UIKit

extension URL {
    func urlWithQueryMap(queryMap: [String: String]?) -> URL {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)!
        if let qmap = queryMap {
            components.queryItems = []
            for (key, val) in qmap {
                components.queryItems?.append(URLQueryItem(name: key, value: val))
            }
        }
        return components.url!
    }
}


extension UIView {
    func addFullScreenConstraints(parent: UIView){
        self.translatesAutoresizingMaskIntoConstraints = false
        parent.addConstraints([
        NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: parent, attribute: .width, multiplier: 1, constant: 0),
        NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: parent, attribute: .height, multiplier: 1, constant: 0),
        NSLayoutConstraint(item: self, attribute: .centerX, relatedBy: .equal, toItem: parent, attribute: .centerX, multiplier: 1, constant: 0),
        NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: .equal, toItem: parent, attribute: .centerY, multiplier: 1, constant: 0)
        ])
    }
    func addCenterConstraints(parent: UIView){
        self.translatesAutoresizingMaskIntoConstraints = false
        parent.addConstraints([
            NSLayoutConstraint(item: self, attribute: .centerX, relatedBy: .equal, toItem: parent, attribute: .centerX, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: .equal, toItem: parent, attribute: .centerY, multiplier: 1, constant: 0)]
        )
    }
}
