# Architecture Rule Checker: Implementation Todo List

## Iteration 1: Setting Up the Project
- [X] Create the project directory `arch-rule-checker`
- [X] Initialize the Swift package as executable
- [X] Update `Package.swift` with dependencies (SwiftSyntax, ArgumentParser, Swift Testing)
- [X] Build the project to verify dependencies

## Iteration 2: Creating a Basic Command Line Interface
- [X] Create main.swift with CLI structure using ArgumentParser
- [X] Define `--source-path` and `--config-path` options
- [X] Run the CLI to verify it works

## Iteration 3: Creating a Configuration Parser
- [X] Create `Configuration.swift` with model and loader
- [X] Implement default configuration
- [X] Create `ConfigurationTests.swift` using Swift Testing
- [X] Write test for default configuration
- [X] Write test for non-existent configuration file
- [X] Write test for loading valid configuration
- [X] Run tests to verify they pass

## Iteration 4: File Discovery
- [X] Create `FileDiscovery.swift` with finder and classifier
- [X] Implement Swift file finder
- [X] Implement UseCase file classifier
- [X] Create `FileDiscoveryTests.swift`
- [X] Write test for Swift file discovery
- [X] Write test for UseCase detection
- [X] Run tests to verify they pass

## Iteration 5: SwiftSyntax Analyzer
- [X] Create `UseCaseAnalyzer.swift` with visitor pattern
- [X] Define `ArchitectureError` enum
- [X] Implement `UseCaseVisitor` class
- [X] Implement `UseCaseAnalyzer` class with static analyze function
- [X] Create `UseCaseAnalyzerTests.swift`
- [X] Write test for non-violating UseCase
- [X] Write test for violating UseCase
- [X] Write test for Result-wrapped entity
- [X] Write test for Response types
- [X] Run tests to verify they pass

## Iteration 6: Integrating Everything in the Main Command
- [X] Update `main.swift` to load configuration
- [X] Add code to find Swift files
- [X] Add code to analyze UseCase files
- [X] Implement results reporting
- [X] Test the full pipeline

## Iteration 7: Create a Sample Test Project
- [X] Create directory structure for test project
- [X] Create model files (`UserEntity.swift`)
- [X] Create violating use case (`GetUserUseCase.swift`)
- [X] Create compliant use case (`ListUsersUseCase.swift`)
- [X] Create repository interface (`UserRepository.swift`)
- [X] Create repository implementation (`UserRepositoryImpl.swift`)
- [X] Run the tool on the sample project to verify violations are found

## Iteration 8: Create a Swift Package Manager Plugin
- [X] Update `Package.swift` to include plugin target and product
- [X] Create `plugin.swift` in Plugins directory
- [X] Implement CommandPlugin protocol
- [X] Add configuration file handling
- [X] Implement target-specific analysis
- [X] Test the plugin with `swift package check-architecture`

## Iteration 9: Extending with Additional Rules
- [ ] Update `ArchitectureError` enum with new error types
- [ ] Create `InfrastructureAnalyzer.swift`
- [ ] Implement `InfrastructureVisitor` class
- [ ] Add infrastructure detection to `FileDiscovery`
- [ ] Update `main.swift` to use the new analyzer
- [ ] Test the new rule with sample project

## Iteration 10: Xcode Integration
- [ ] Create shell script `check_architecture.sh`
- [ ] Make the script executable
- [ ] Configure Xcode build phase to run the script
- [ ] Test integration by introducing violations and building

## Iteration 11: CI Integration
- [ ] Create GitHub Actions workflow file
- [ ] Configure workflow to build, check architecture, and run tests
- [ ] Test with a sample commit

## Iteration 12: Documentation
- [ ] Create README.md with usage instructions
- [ ] Document configuration options
- [ ] Document how to extend with new rules
- [ ] Add examples
