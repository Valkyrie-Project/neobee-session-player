import Testing
import SwiftUI
@testable import neobee_session_player

struct PlayerUIComponentsTests {
    
    @Test func testSongInfoCardCreation() async throws {
        let testURL = URL(fileURLWithPath: "/test/song.mkv")
        
        // Test that we can create the component without crashing
        // We don't need to test SwiftUI rendering in unit tests
        _ = SongInfoCard(
            url: testURL,
            isHovering: false,
            isFullScreen: false
        )
        
        // If we get here, the component was created successfully
        #expect(true)
    }
    
    @Test func testVideoContainerViewType() async throws {
        // Test that our component types are properly defined
        #expect(VideoContainerView.self is any View.Type)
    }
    
    @Test func testPlayerBackgroundGradientType() async throws {
        // Test that our component types are properly defined
        #expect(PlayerBackgroundGradient.self is any View.Type)
    }
    
    @Test func testURLFileNameExtraction() async throws {
        // Test the URL filename extraction logic that SongInfoCard uses
        let testCases = [
            ("/music/song.mkv", "song"),
            ("/videos/movie.mpg", "movie"),
            ("/path/with spaces/file with spaces.mkv", "file with spaces"),
            ("/single.mkv", "single"),
            ("/path/no-extension", "no-extension")
        ]
        
        for (path, expectedName) in testCases {
            let url = URL(fileURLWithPath: path)
            let extractedName = url.deletingPathExtension().lastPathComponent
            #expect(extractedName == expectedName, "Expected '\(expectedName)' but got '\(extractedName)' for path '\(path)'")
        }
    }
    
    @Test func testFullScreenMouseDetectionType() async throws {
        // Test that FullScreenMouseDetection type is properly defined
        #expect(FullScreenMouseDetection.self is any View.Type)
    }
}
