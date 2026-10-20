import Foundation
@testable import Plex_Shared_Backend
import Testing

extension PlexAPISampleTests {
    // MARK: - Watch state

    @Test func watchStateMutations() async throws {
        let requests = try await stubbed { api in
            try await api.markWatched(ratingKey: "42")
            try await api.markUnwatched(ratingKey: "42")
            try await api.reportTimeline(ratingKey: "42", state: .playing, time: 600_000, duration: 7_200_000)
            try await api.rate(ratingKey: "42", rating: 8)
            try await api.removeFromContinueWatching(ratingKey: "42")
        }.requests
        #expect(requests == [
            "GET /:/scrobble?key=42&identifier=com.plexapp.plugins.library",
            "GET /:/unscrobble?key=42&identifier=com.plexapp.plugins.library",
            "POST /:/timeline?ratingKey=42&key=/library/metadata/42&state=playing&time=600000&duration=7200000",
            "PUT /:/rate?key=42&identifier=com.plexapp.plugins.library&rating=8.0",
            "PUT /actions/removeFromContinueWatching?ratingKey=42",
        ])
    }

    // MARK: - Collections and playlists

    @Test func collections() async throws {
        let (collections, requests) = try await stubbed(#"""
        {"MediaContainer":{"size":1,"Metadata":[
          {"ratingKey":"500","key":"/library/collections/500/children","type":"collection","subtype":"movie","title":"Sample Collection",
           "childCount":2,"smart":false}]}}
        """#) { try await $0.collections(sectionID: "1") }
        #expect(requests == ["GET /library/sections/1/collections"])
        #expect(collections.metadata.first?.type == "collection" && collections.metadata.first?.childCount == 2)
    }

    @Test func collectionItems() async throws {
        let (items, requests) = try await stubbed(#"""
        {"MediaContainer":{"size":2,"Metadata":[
          {"ratingKey":"42","type":"movie","title":"Sample Movie"},{"ratingKey":"43","type":"movie","title":"Another Movie"}]}}
        """#) { try await $0.collectionItems(collectionID: "500") }
        #expect(requests == ["GET /library/collections/500/children"])
        #expect(items.metadata.map(\.ratingKey) == ["42", "43"])
    }

    @Test func createCollection() async throws {
        let (collection, requests) = try await stubbed(#"""
        {"MediaContainer":{"size":1,"Metadata":[
          {"ratingKey":"501","key":"/library/collections/501/children","type":"collection","subtype":"movie","title":"Favorites",
           "childCount":2,"smart":false}]}}
        """#) { try await $0.createCollection(sectionID: "1", title: "Favorites", type: 1, ratingKeys: ["42", "43"]) }
        #expect(requests == [
            "POST /library/collections?type=1&title=Favorites&smart=0&sectionId=1&uri=server://machine/com.plexapp.plugins.library/library/metadata/42,43",
        ])
        #expect(collection?.ratingKey == "501" && collection?.smart == false)
    }

    @Test func playlists() async throws {
        let (playlists, requests) = try await stubbed(#"""
        {"MediaContainer":{"size":1,"Metadata":[
          {"ratingKey":"600","key":"/playlists/600/items","type":"playlist","title":"Weekend","playlistType":"video","smart":false,
           "leafCount":2,"duration":9900000,"composite":"/playlists/600/composite/1700000000"}]}}
        """#) { try await $0.playlists() }
        #expect(requests == ["GET /playlists?playlistType=video"])
        #expect(playlists.metadata.first?.posterPath == "/playlists/600/composite/1700000000")
    }

    @Test func playlist() async throws {
        let (playlist, requests) = try await stubbed(#"""
        {"MediaContainer":{"size":1,"Metadata":[
          {"ratingKey":"600","type":"playlist","title":"Weekend","playlistType":"video","smart":false,"leafCount":2,"duration":9900000}]}}
        """#) { try await $0.playlist(id: "600") }
        #expect(requests == ["GET /playlists/600"])
        #expect(playlist.playlistType == "video" && playlist.leafCount == 2)
    }

    @Test func playlistItems() async throws {
        let (items, requests) = try await stubbed(#"""
        {"MediaContainer":{"size":2,"totalSize":2,"Metadata":[
          {"ratingKey":"42","playlistItemID":9001,"type":"movie","title":"Sample Movie"},
          {"ratingKey":"101","playlistItemID":9002,"type":"episode","title":"Pilot","grandparentTitle":"Sample Show"}]}}
        """#) { try await $0.playlistItems(id: "600") }
        #expect(requests == ["GET /playlists/600/items"])
        #expect(items.metadata.map(\.playlistItemID) == ["9001", "9002"])
    }

    @Test func createPlaylist() async throws {
        let (playlist, requests) = try await stubbed(#"""
        {"MediaContainer":{"size":1,"Metadata":[
          {"ratingKey":"600","type":"playlist","title":"Weekend","playlistType":"video","smart":false,"leafCount":2}]}}
        """#) { try await $0.createPlaylist(title: "Weekend", ratingKeys: ["42", "101"]) }
        #expect(requests == ["POST /playlists?type=video&title=Weekend&smart=0&uri=server://machine/com.plexapp.plugins.library/library/metadata/42,101"])
        #expect(playlist?.ratingKey == "600")
    }

    @Test func listMutations() async throws {
        let requests = try await stubbed { api in
            try await api.addToCollection(collectionID: "500", ratingKeys: ["42"])
            try await api.deleteCollection(collectionID: "500")
            try await api.addToPlaylist(id: "600", ratingKeys: ["42"])
        }.requests
        #expect(requests == [
            "PUT /library/collections/500/items?uri=server://machine/com.plexapp.plugins.library/library/metadata/42",
            "DELETE /library/collections/500",
            "PUT /playlists/600/items?uri=server://machine/com.plexapp.plugins.library/library/metadata/42",
        ])
    }

    // MARK: - Play queues

    @Test func playQueues() async throws {
        let json = #"""
        {"MediaContainer":{"size":2,"playQueueID":77,"playQueueVersion":1,"playQueueSelectedItemID":7001,"playQueueTotalCount":2,
         "playQueueShuffled":false,"Metadata":[
           {"ratingKey":"101","playQueueItemID":7001,"type":"episode","title":"Pilot"},
           {"ratingKey":"102","playQueueItemID":7002,"type":"episode","title":"Episode 2"}]}}
        """#
        let (queue, requests) = try await stubbed(json) {
            try await $0.createPlayQueue(source: .path("/library/metadata/10/children"), startingRatingKey: "101")
        }
        #expect(requests == [
            "POST /playQueues?type=video&shuffle=0&repeat=0&continuous=1&uri=server://machine/com.plexapp.plugins.library/library/metadata/10/children&key=/library/metadata/101",
        ])
        #expect(queue.id == "77" && queue.selectedItemID == "7001" && queue.totalCount == 2 && queue.items.map(\.ratingKey) == ["101", "102"])
        #expect(try await stubbed(json) { try await $0.playQueue(id: "77") }.requests == ["GET /playQueues/77?window=50&includeBefore=1&includeAfter=1"])
    }

    // MARK: - Media

    @Test func mediaRequests() async throws {
        let (image, requests) = try await stubbed("image-bytes") {
            try await $0.imageData(path: "/library/metadata/42/thumb/1700000000", width: 300, height: 450)
        }
        #expect(image == Data("image-bytes".utf8))
        #expect(requests == ["GET /photo/:/transcode?width=300&height=450&minSize=1&upscale=1&url=/library/metadata/42/thumb/1700000000"])
        let api = try PlexAPIService(configuration: testConfiguration())
        #expect(try requestLine(api.imageRequest(path: "/library/metadata/42/thumb/1700000000")) == "GET /library/metadata/42/thumb/1700000000")
        #expect(try requestLine(api.directPlayRequest(part: PlexMediaPart(key: "/library/parts/7/1700000000/file.mkv"))) == "GET /library/parts/7/1700000000/file.mkv")
        #expect(try requestLine(api.previewThumbnailsRequest(partID: "7")) == "GET /library/parts/7/indexes/sd")
        #expect(try requestLine(api.streamRequest(PlexStreamOptions(ratingKey: "42", session: "session-1")))
            .hasPrefix("GET /video/:/transcode/universal/start.m3u8?path=%2Flibrary%2Fmetadata%2F42&mediaIndex=0&partIndex=0&protocol=hls"))
    }

    @Test func mediaMutations() async throws {
        let requests = try await stubbed { api in
            try await api.stopStream(session: "session-1")
            try await api.selectStreams(partID: "7", audioStreamID: "101", subtitleStreamID: "0")
        }.requests
        #expect(requests == [
            "GET /video/:/transcode/universal/stop?session=session-1",
            "PUT /library/parts/7?audioStreamID=101&subtitleStreamID=0&allParts=1",
        ])
    }

    @Test func subtitles() async throws {
        let (results, search) = try await stubbed(#"""
        {"MediaContainer":{"size":1,"Stream":[
          {"key":"/subtitles/provider/sample-1","streamType":3,"codec":"srt","language":"English","languageCode":"eng",
           "displayTitle":"English (SRT)","providerTitle":"OpenSubtitles","score":"92","hearingImpaired":false,"forced":false}]}}
        """#) { try await $0.searchSubtitles(ratingKey: "42", language: "en") }
        #expect(search == ["GET /library/metadata/42/subtitles?language=en&hearingImpaired=0&forced=0"])
        let result = try #require(results.first)
        #expect(result.language == "eng" && result.score == 92 && !result.hearingImpaired)
        let download = try await stubbed { try await $0.downloadSubtitle(ratingKey: "42", result: result) }.requests
        #expect(download == [
            "PUT /library/metadata/42/subtitles?key=/subtitles/provider/sample-1&codec=srt&language=eng&hearingImpaired=0&forced=0&providerTitle=OpenSubtitles",
        ])
    }

    // MARK: - Server and admin

    @Test func serverInfo() async throws {
        let (info, requests) = try await stubbed(#"""
        {"MediaContainer":{"size":0,"friendlyName":"Home Server","machineIdentifier":"machine","version":"1.40.0.0000","platform":"Linux",
         "transcoderVideo":true,"myPlex":true}}
        """#) { try await $0.serverInfo() }
        #expect(requests == ["GET /"])
        #expect(info.friendlyName == "Home Server" && info.machineIdentifier == "machine" && info.transcoderVideo && info.myPlex)
    }

    @Test func serverPreferences() async throws {
        let json = #"""
        {"MediaContainer":{"size":2,"Setting":[
          {"id":"FriendlyName","label":"Friendly name","summary":"The server's display name.","type":"text","default":"","value":"Home Server"},
          {"id":"LibraryVideoPlayedThreshold","label":"Video played threshold","type":"int","default":90,"value":90}]}}
        """#
        let (settings, requests) = try await stubbed(json) { try await $0.serverPreferences() }
        #expect(requests == ["GET /:/prefs"])
        #expect(settings.map(\.value) == ["Home Server", "90"])
        #expect(try await stubbed(json) { try await $0.watchedThreshold() }.value == 0.9)
    }

    @Test func activities() async throws {
        let (activities, requests) = try await stubbed(#"""
        {"MediaContainer":{"size":1,"Activity":[
          {"uuid":"activity-1","type":"library.update.section","cancellable":true,"userID":1,"title":"Scanning Movies",
           "subtitle":"Sample Movie","progress":40}]}}
        """#) { try await $0.activities() }
        #expect(requests == ["GET /activities"])
        #expect(activities.first?.id == "activity-1" && activities.first?.progress == 40 && activities.first?.cancellable == true)
    }

    @Test func adminMutations() async throws {
        let requests = try await stubbed { api in
            try await api.cancelActivity(uuid: "activity-1")
            try await api.scanLibrary(sectionID: "1")
            try await api.scanLibrary(sectionID: "1", force: true)
            try await api.analyzeLibrary(sectionID: "1")
            try await api.emptyTrash(sectionID: "1")
            try await api.refreshMetadata(ratingKey: "42")
            try await api.deleteItem(ratingKey: "42")
        }.requests
        #expect(requests == [
            "DELETE /activities/activity-1",
            "GET /library/sections/1/refresh",
            "GET /library/sections/1/refresh?force=1",
            "PUT /library/sections/1/analyze",
            "PUT /library/sections/1/emptyTrash",
            "PUT /library/metadata/42/refresh",
            "DELETE /library/metadata/42",
        ])
    }

    @Test func dvrs() async throws {
        let (dvrs, requests) = try await stubbed(#"""
        {"MediaContainer":{"size":1,"Dvr":[{"key":"3","uuid":"dvr-uuid","title":"Antenna","lineupTitle":"Sample Lineup","language":"eng"}]}}
        """#) { try await $0.dvrs() }
        #expect(requests == ["GET /livetv/dvrs"])
        #expect(dvrs.map(\.id) == ["3"] && dvrs.first?.lineupTitle == "Sample Lineup")
    }

    @Test func recordingRules() async throws {
        let (rules, requests) = try await stubbed(#"""
        {"MediaContainer":{"size":1,"MediaSubscription":[
          {"key":"sub-1","type":2,"targetLibrarySectionID":2,"title":"Sample Show","Directory":{"ratingKey":"10","type":"show","title":"Sample Show"}}]}}
        """#) { try await $0.recordingRules() }
        #expect(requests == ["GET /media/subscriptions?includeGrabs=1&includeStorage=1"])
        #expect(rules.size == 1)
    }

    @Test func scheduledRecordings() async throws {
        let (scheduled, requests) = try await stubbed(#"""
        {"MediaContainer":{"size":1,"MediaGrabOperation":[
          {"mediaSubscriptionID":"sub-1","status":"scheduled",
           "Metadata":{"ratingKey":"1003","type":"episode","title":"Episode 3","grandparentTitle":"Sample Show"}}]}}
        """#) { try await $0.scheduledRecordings() }
        #expect(requests == ["GET /media/subscriptions/scheduled"])
        #expect(scheduled.size == 1)
    }

    // MARK: - Notifications

    @Test func notifications() async throws {
        let request = try PlexAPIService(configuration: testConfiguration()).notificationsRequest()
        #expect(requestLine(request) == "GET /:/eventsource/notifications" && request.value(forHTTPHeaderField: "Accept") == "text/event-stream")
        let stream = SampleEvents(text: #"""
        event: activity
        data: {"ActivityNotification":{"event":"updated","uuid":"activity-1","Activity":{"uuid":"activity-1","type":"library.update.section","progress":40}}}

        event: playing
        data: {"PlaySessionStateNotification":{"sessionKey":"1","ratingKey":"42","state":"playing","viewOffset":600000}}

        """#)
        var events: [PlexServerEvent] = []
        for try await event in stream.events(for: request) { events.append(event) }
        #expect(events.map(\.name) == ["activity", "playing"])
        #expect(try events.allSatisfy { try JSONSerialization.jsonObject(with: $0.data) is [String: Any] })
    }
}

/// Replays a server-sent-event body line by line.
private struct SampleEvents: PlexEventStreaming {
    let text: String

    func lines(for request: URLRequest) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            text.split(separator: "\n", omittingEmptySubsequences: false).forEach { continuation.yield(String($0)) }
            continuation.finish()
        }
    }
}
