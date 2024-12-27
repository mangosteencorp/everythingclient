//
//  MovieListResultModel.swift
//  everythingclient
//
//  Created by Quang on 2024-12-27.
//


import Foundation

public struct MovieListResultModel: Decodable {
    let dates: Dates
    let page: Int
    public let results: [TMDBMovieModel]
    let totalPages: Int
    let totalResults: Int

    enum CodingKeys: String, CodingKey {
        case dates, page, results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

struct Dates: Decodable {
    let maximum: String
    let minimum: String
}

