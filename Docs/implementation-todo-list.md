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
- [ ] Create `Configuration.swift` with model and loader
- [ ] Implement default configuration
- [ ] Create `ConfigurationTests.swift` using Swift Testing
- [ ] Write test for default configuration
- [ ] Write test for non-existent configuration file
- [ ] Write test for loading valid configuration
- [ ] Run tests to verify they pass

## Iteration 4: File Discovery
- [ ] Create `FileDiscovery.swift` with finder and classifier
- [ ] Implement Swift file finder
- [ ] Implement UseCase file classifier
- [ ] Create `FileDiscoveryTests.swift`
- [ ] Write test for Swift file discovery
- [ ] Write test for UseCase detection
- [ ] Run tests to verify they pass

## Iteration 5: SwiftSyntax Analyzer
- [ ] Create `UseCaseAnalyzer.swift` with visitor pattern
- [ ] Define `ArchitectureError` enum
- [ ] Implement `UseCaseVisitor` class
- [ ] Implement `UseCaseAnalyzer` class with static analyze function
- [ ] Create `UseCaseAnalyzerTests.swift`
- [ ] Write test for non-violating UseCase
- [ ] Write test for violating UseCase
- [ ] Write test for Result-wrapped entity
- [ ] Write test for Response types
- [ ] Run tests to verify they pass

## Iteration 6: Integrating Everything in the Main Command
- [ ] Update `main.swift` to load configuration
- [ ] Add code to find Swift files
- [ ] Add code to analyze UseCase files
- [ ] Implement results reporting
- [ ] Test the full pipeline

## Iteration 7: Create a Sample Test Project
- [ ] Create directory structure for test project
- [ ] Create model files (`UserEntity.swift`)
- [ ] Create violating use case (`GetUserUseCase.swift`)
- [ ] Create compliant use case (`ListUsersUseCase.swift`)
- [ ] Create repository interface (`UserRepository.swift`)
- [ ] Create repository implementation (`UserRepositoryImpl.swift`)
- [ ] Run the tool on the sample project to verify violations are found

## Iteration 8: Create a Swift Package Manager Plugin
- [ ] Update `Package.swift` to include plugin target and product
- [ ] Create `plugin.swift` in Plugins directory
- [ ] Implement CommandPlugin protocol
- [ ] Add configuration file handling
- [ ] Implement target-specific analysis
- [ ] Test the plugin with `swift package check-architecture`

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
