# Scripts ZSH

Este repositório contém scripts em Zsh para facilitar tarefas de desenvolvimento.

## dotnet-add-project.zsh - Adicionar Projeto à Solução

Este script adiciona um projeto existente a uma solução .NET. Ele solicita ou aceita via argumento o caminho do projeto e da solução, valida as entradas e executa `dotnet sln add` para integrar o projeto à solução alvo.

Uso (exemplos):

```bash
# Adiciona projeto ao .sln especificando caminhos
./dotnet-add-project.zsh ./src/MyProj/MyProj.csproj ./MySolution.sln

# Ou, quando o script suporta argumentos nomeados (exemplo genérico):
./dotnet-add-project.zsh --project ./src/MyProj/MyProj.csproj --sln ./MySolution.sln
```

## dotnet-common.zsh - Helpers Comuns .NET

Contém funções utilitárias e variáveis compartilhadas usadas pelos outros scripts .NET, como verificadores de presença do `dotnet`, manipuladores de caminhos, helpers para logging e rotinas comuns para criação de soluções e projetos.

## dotnet-new-blazor-app.zsh - Criar Novo Projeto Blazor

Este script automatiza a criação de um novo projeto Blazor usando o .NET. Ele solicita o nome da solução e do projeto, valida as entradas, verifica se o comando 'dotnet' está instalado, cria uma solução, um projeto Blazor com configurações específicas (framework .NET 10.0, interatividade Auto, sem autenticação), ajusta o arquivo de solução, inicializa um repositório Git, adiciona um .gitignore e faz o commit inicial.

Uso (exemplos):

```bash
# Criar solução e projeto passando nomes (exemplo):
./dotnet-new-blazor-app.zsh MySolution MyBlazorApp

# Executar interativamente (sem argumentos):
./dotnet-new-blazor-app.zsh
```

## dotnet-new-web-app.zsh - Criar Novo Projeto Web (.NET)

Automatiza a criação de um novo projeto web baseado em .NET (template webapp). Solicita nome da solução/projeto, valida o ambiente, cria a solução e o projeto com configurações padrão, inicializa repositório Git e adiciona arquivos básicos como `.gitignore`.

Uso (exemplos):

```bash
# Criar solução e web app passando nomes (exemplo):
./dotnet-new-web-app.zsh MySolution MyWebApp

# Executar interativamente:
./dotnet-new-web-app.zsh
```

## dotnet-pack-package.zsh - Empacotar Projeto

Gera um pacote NuGet a partir de um projeto .NET usando `dotnet pack`. Permite ajustar versão e diretório de saída, valida a build antes do empacotamento e informa o resultado ao usuário.

Uso (exemplos):

```bash
# Empacotar um projeto especificando o caminho do .csproj:
./dotnet-pack-package.zsh ./src/MyLib/MyLib.csproj

# Exemplo com diretório de saída e versão (exemplo genérico):
./dotnet-pack-package.zsh ./src/MyLib/MyLib.csproj --version 1.2.3 --output ./nupkgs
```

## dotnet-publish-package.zsh - Publicar Pacote

Publica um pacote NuGet para um feed configurável (por exemplo, nuget.org ou feed privado). O script prepara o pacote e usa `dotnet nuget push` ou outra estratégia configurada, lidando com endpoint e API key conforme necessário.

Uso (exemplos):

```bash
# Publicar pacote passando o arquivo .nupkg e o feed (exemplo):
./dotnet-publish-package.zsh ./nupkgs/MyLib.1.2.3.nupkg https://api.nuget.org/v3/index.json

# Com API key via variável de ambiente:
NUGET_API_KEY=xxxxx ./dotnet-publish-package.zsh ./nupkgs/MyLib.1.2.3.nupkg https://api.nuget.org/v3/index.json
```

## dotnet-sdks.zsh - Gerenciar SDKs .NET

Fornece comandos para listar e inspecionar os SDKs .NET instalados na máquina, além de facilitar a criação/atualização de um arquivo `global.json` para fixar a versão do SDK usada pelos scripts e projetos.

Uso (exemplos):

```bash
# Listar SDKs instalados (exemplo):
./dotnet-sdks.zsh list

# Gerar/atualizar global.json para a versão desejada (exemplo):
./dotnet-sdks.zsh set 7.0.100
```

## dotnet-start.zsh - Iniciar Aplicação (.NET)

Script para iniciar a aplicação de desenvolvimento com `dotnet run`. Detecta automaticamente o projeto ou solução no diretório atual, aceita opções de ambiente e, quando aplicável, abre o navegador para a URL da aplicação.

Uso (exemplos):

```bash
# Iniciar aplicação no diretório atual (autodetecta projeto):
./dotnet-start.zsh

# Iniciar um projeto específico com variável de ambiente (exemplo):
DOTNET_ENVIRONMENT=Development ./dotnet-start.zsh ./src/MyApp/MyApp.csproj
```

## dotnet-update-packages.zsh - Verificar e Atualizar Pacotes .NET

Este script verifica se há pacotes desatualizados em um projeto .NET. Ele utiliza o comando `dotnet list package --outdated` para listar pacotes que precisam de atualização. O script valida se a CLI do dotnet está instalada e, caso contrário, exibe uma mensagem de erro. Em seguida, ele captura a saída do comando e processa as informações para apresentar ao usuário, dando a opção de atualizar as packages desatualizadas automaticamente.

Uso (exemplos):

```bash
# Verificar pacotes desatualizados na solução atual:
./dotnet-update-packages.zsh

# Verificar em uma solução específica:
./dotnet-update-packages.zsh ./MySolution.sln

# Executar atualização automática (se suportado pelo script):
./dotnet-update-packages.zsh --update
```

## shared-style.zsh - Estilos Compartilhados

Contém definições de estilo e helpers para saída formatada nos scripts (cores, prefixos de log, funções de prompt), garantindo consistência visual entre os diversos scripts do repositório.

## vscode-open-workspace.zsh - Abrir Workspace no VS Code

Este script permite abrir workspaces do VS Code através de um menu numerado. Ele apresenta uma lista de workspaces pré-definidos (como notes, scripts, blazor, lumia e zshrc) e permite ao usuário selecionar um número correspondente para abrir o workspace ou arquivo no VS Code. O script valida a entrada e verifica se o comando 'code' está disponível.