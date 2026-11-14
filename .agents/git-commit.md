only commit what you change, ignore other changes as they might be another thing I'm working on. 

If I ask you to to multiple things, make sure to you multiple commits.

For every commit, include a deep link back to the conversation so I can go back and see what makes your decision.

SwiftLint & swiftFormat before commit

if you're not the first commit & you're allowed to push (or I'm asking you to push):
- ask me to create a pull request if there's none
- if `gh` commit not logged in, ask me
- after push, leave a comment in the pull request:
    - Not needed:
        - all the classes & functions added (in Swift API format, not words, function body empty), except helpers, private, file only functions or debug purpose functions
        - files in demo target.
        - simple init
    - link to the chat (private, not shared) so I can resume and see your work