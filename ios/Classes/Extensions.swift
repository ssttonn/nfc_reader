//
//  Extensions.swift
//  nfc_reader
//
//  Created by sstonn on 02/09/2022.
//

import Foundation

extension Data{
    func encode(encoding: String.Encoding = .utf8) -> String?{
        return String(data: self, encoding: encoding)
    }
}


