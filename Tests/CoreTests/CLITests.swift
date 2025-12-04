import Testing
@testable import Core

struct CLITests {
    @Test func determineActionWithListExecutablesFlag() {
        let action = determineAction(
            listExecutablesFlag: true,
            specifiedExec: nil,
            executables: ["tool1", "tool2"],
            arguments: []
        )
        #expect(action == .listExecutables(["tool1", "tool2"]))
    }

    @Test func determineActionWithSpecifiedExec() {
        let action = determineAction(
            listExecutablesFlag: false,
            specifiedExec: "tool1",
            executables: ["tool1", "tool2"],
            arguments: ["--help"]
        )
        #expect(action == .run(executable: "tool1", arguments: ["--help"]))
    }

    @Test func determineActionWithSingleExecutable() {
        let action = determineAction(
            listExecutablesFlag: false,
            specifiedExec: nil,
            executables: ["onlyone"],
            arguments: []
        )
        #expect(action == .run(executable: "onlyone", arguments: []))
    }

    @Test func determineActionWithMultipleExecutablesAndNoneSpecified() {
        let action = determineAction(
            listExecutablesFlag: false,
            specifiedExec: nil,
            executables: ["tool1", "tool2"],
            arguments: []
        )
        #expect(action == .listExecutables(["tool1", "tool2"]))
    }
}
