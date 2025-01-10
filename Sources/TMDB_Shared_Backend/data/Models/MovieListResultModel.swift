//
//  MovieListResultModel.swift
//  everythingclient
//
//  Created by Quang on 2024-12-27.
//


import Foundation

public struct MovieListResultModel: Decodable {
    public let dates: Dates?
    public let page: Int
    public let results: [TMDBMovieModel]
    public let totalPages: Int
    public let totalResults: Int

    enum CodingKeys: String, CodingKey {
        case dates, page, results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

public struct Dates: Decodable {
    public let maximum: String
    public let minimum: String
}

