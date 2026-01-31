# Scripts ZSH

Este repositório contém scripts em Zsh para facilitar tarefas de desenvolvimento.

## abrir-workspace-vscode.zsh

Este script permite abrir workspaces do VS Code através de um menu numerado. Ele apresenta uma lista de workspaces pré-definidos (como notes, scripts, blazor, lumia e zshrc) e permite ao usuário selecionar um número correspondente para abrir o workspace ou arquivo no VS Code. O script valida a entrada e verifica se o comando 'code' está disponível.

## new_blazor_app.zsh

Este script automatiza a criação de um novo projeto Blazor usando o .NET. Ele solicita o nome da solução e do projeto, valida as entradas, verifica se o comando 'dotnet' está instalado, cria uma solução, um projeto Blazor com configurações específicas (framework .NET 10.0, interatividade Auto, sem autenticação), ajusta o arquivo de solução, inicializa um repositório Git, adiciona um .gitignore e faz o commit inicial.

## dotnet-gerar-updates.zsh

Este script verifica se há pacotes desatualizados em um projeto .NET. Ele utiliza o comando `dotnet list package --outdated` para listar pacotes que precisam de atualização. O script valida se a CLI do dotnet está instalada e, caso contrário, exibe uma mensagem de erro. Em seguida, ele captura a saída do comando e processa as informações para apresentar ao usuário, dando a opção de atualizar as packages desatualizadas automaticamente.