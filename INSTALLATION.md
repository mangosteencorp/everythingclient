# TOOLS INSTALLATION GUIDES

## Apollo Codegen

### Generating CLI binary file

At root level, run: `swift package --allow-writing-to-package-directory apollo-cli-install`

### Downloading & generating schema

```zsh
./apollo-ios-cli generate --path ./Sources/GraphQLAPI/apollo-pokedex-codegen-config.json
./apollo-ios-cli fetch-schema --path ./Sources/Pokedex_Shared_Backend/apollo-pokedex-codegen-config.json
```