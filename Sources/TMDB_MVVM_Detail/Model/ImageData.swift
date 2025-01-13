//
//  ImageData.swift
//  everythingclient
//
//  Created by Quang on 2025-01-08.
//


import Foundation



struct ImageData: Codable, Identifiable {
    var id: String {
        file_path
    }
    let aspect_ratio: Float
    let file_path: String
    let height: Int
    let width: Int
}