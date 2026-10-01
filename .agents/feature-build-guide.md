If it's a bug
- if it's UI related:
    - write a UI test confirming it (if no complicated auth require, if there is, consult me)
    - fix the bug, one-liner style if possible
    - run the whole app again to confirm 

If it's a feature 
- if it's UI related:
    - if it's straightforward and only one module, add a UI test for test driven development
    - otherwise you can UI test with snapshot testing so I can review later

Make sure you have SwiftUI previews down to the smallest UI elements you added.

Use protocol oriented programming and make sure you have:
- a protocol wrapping external feature so I can mock later for testing - like Apple Music, Foundation Models, analytics etc.

Clean up after you finish the main work:
- no raw string allowed, move them all to .strings or .xcstrings
- if .strings, make sure you run swiftgen
- for .xcstrings, build with Xcode to make sure the new string key is generated before using. 