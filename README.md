# Sistema de Inventario

Sistema de controle de estoque feito em Haskell. Gerencia itens com ID unico, nome, quantidade e categoria. Todas as operacoes sao persistidas em arquivo e auditadas com timestamp.

## Site do Replit
https://replit.com/@Jhonnyz1/Inventario-em-Haskell?v=1#main.hs

## Requisitos

- GHC (Glasgow Haskell Compiler) versao 8.0 ou superior
- Bibliotecas standard do Haskell:
  - Data.Map - estrutura de dados do inventario
  - Data.Time - timestamp dos logs
  - System.IO - entrada/saida
  - Control.Exception - tratamento de erros de arquivo
  - Control.Monad - utilitarios (unless)

## Instalacao e Compilacao

Compilar o programa:
```
ghc -o inventario Main.hs
```

Se der warning de imports nao usados, pode ignorar ou compilar com:
```
ghc -o inventario Main.hs -W
```

## Executando

Rodar o programa:
```
./inventario
```

Na primeira execucao, o sistema:
- Cria os arquivos `Inventario.dat` e `Auditoria.log` quando necessario
- Mostra quantos itens e logs foram carregados
- Entra no modo interativo esperando comandos

O sistema carrega automaticamente:
- `Inventario.dat` - estado atual do estoque
- `Auditoria.log` - historico completo de operacoes

Se os arquivos nao existirem ou estiverem corrompidos, comeca com inventario vazio.

## Comandos Detalhados

### add ID NOME QTD CATEGORIA
Adiciona um novo item ao inventario.

**Parametros:**
- ID: identificador unico (string sem espacos)
- NOME: nome do item (string sem espacos, use underscore se necessario)
- QTD: quantidade inteira positiva
- CATEGORIA: categoria do item (string sem espacos)

**Exemplo:**
```
add 001 Notebook 10 Eletronicos
add 015 Mouse_Gamer 25 Perifericos
```

**Validacoes:**
- Quantidade deve ser maior que zero
- ID nao pode ja existir no inventario
- Se passar, salva no Inventario.dat e registra no Auditoria.log

**Erros possiveis:**
- "Quantidade deve ser maior que zero"
- "Item com ID XXX ja existe no inventario"
- "Quantidade invalida" (se nao for numero)

---

### remove ID QTD
Remove quantidade de um item existente.

**Parametros:**
- ID: identificador do item
- QTD: quantidade a remover (positiva)

**Exemplo:**
```
remove 001 5
```

**Comportamento:**
- Se a quantidade final ficar maior que zero, atualiza o item
- Se a quantidade final for exatamente zero, remove o item do inventario
- Nao permite remover mais do que existe em estoque

**Validacoes:**
- Item tem que existir
- Quantidade a remover deve ser maior que zero
- Nao pode remover mais que o estoque disponivel

**Erros possiveis:**
- "Item XXX nao encontrado no inventario"
- "Quantidade a remover deve ser maior que zero"
- "Estoque insuficiente. Disponivel: X, solicitado: Y"

---

### update ID QTD
Atualiza a quantidade de um item diretamente (nao é incremental).

**Parametros:**
- ID: identificador do item
- QTD: nova quantidade (pode ser zero)

**Exemplo:**
```
update 001 20
update 002 0
```

**Comportamento:**
- Se QTD > 0, atualiza a quantidade
- Se QTD = 0, remove o item do inventario
- Nao permite quantidade negativa

**Validacoes:**
- Item tem que existir
- Quantidade nao pode ser negativa

**Erros possiveis:**
- "Item XXX nao encontrado no inventario"
- "Quantidade nao pode ser negativa"

---

### list
Lista todos os itens do inventario atual.

**Saida:**
```
INVENTARIO ATUAL
ID: 001 | Nome: Notebook | Qtd: 15 | Categoria: Eletronicos
ID: 002 | Nome: Mouse | Qtd: 50 | Categoria: Perifericos
...
```

Se o inventario estiver vazio, mostra "Inventario vazio."

---

### report
Gera relatorio de auditoria com estatisticas dos logs.

**Informacoes exibidas:**
- Total de operacoes realizadas
- Total de erros ocorridos
- Lista detalhada de todos os erros (se houver)
- Item mais movimentado (com mais operacoes add/remove/update)

**Exemplo de saida:**
```
RELATORIO DE LOGS
Total de operacoes: 45
Total de erros: 3
Logs de erro:
  - Item 999 nao encontrado no inventario
  - Quantidade invalida
  - Estoque insuficiente. Disponivel: 5, solicitado: 10
Item mais movimentado: 001
```

---

### populate
Popula o inventario com 10 itens pre-definidos para testes.

**Itens adicionados:**
1. 001 - Notebook (15 unidades, Eletronicos)
2. 002 - Mouse (50 unidades, Perifericos)
3. 003 - Teclado (30 unidades, Perifericos)
4. 004 - Monitor (20 unidades, Eletronicos)
5. 005 - WebCam (25 unidades, Perifericos)
6. 006 - HeadSet (40 unidades, Audio)
7. 007 - Impressora (10 unidades, Eletronicos)
8. 008 - Scanner (8 unidades, Eletronicos)
9. 009 - Microfone (35 unidades, Audio)
10. 010 - Caixa_de_Som (22 unidades, Audio)

**Observacao:** Se algum ID ja existir, pula aquele item.

---

### help
Mostra lista de comandos disponiveis com sintaxe basica.

---

### exit
Encerra o programa. Todos os dados ja foram salvos durante as operacoes.

## Arquivos Gerados e Persistencia

### Inventario.dat
Arquivo que armazena o estado completo do inventario.

**Formato:** Representacao textual de um Map String Item usando Show/Read do Haskell
**Localizacao:** Diretorio onde o programa foi executado
**Atualizacao:** Automatica apos cada operacao bem sucedida (add, remove, update)

**Conteudo exemplo:**
```
fromList [("001",Item {itemID = "001", nome = "Notebook", quantidade = 15, categoria = "Eletronicos"}),("002",Item {itemID = "002", nome = "Mouse", quantidade = 50, categoria = "Perifericos"})]
```

**Importante:** 
- Nao editar manualmente (formato especifico do Haskell)
- Se corromper, deletar o arquivo e o sistema recria vazio
- Backup pode ser feito copiando o arquivo

---

### Auditoria.log
Arquivo de log que registra todas as operacoes do sistema.

**Formato:** Uma linha por LogEntry, usando Show/Read do Haskell
**Localizacao:** Diretorio onde o programa foi executado
**Atualizacao:** Append apos cada operacao (incluindo falhas)

**Estrutura de cada entrada:**
- Timestamp UTC da operacao
- Tipo de acao (Add, Remove, Update, QueryFail)
- Detalhes descritivos da operacao
- Status (Sucesso ou Falha com mensagem)

**Conteudo exemplo:**
```
LogEntry {timestamp = 2025-01-15 10:30:45.123 UTC, acao = Add, detalhes = "Adicionado: 001 - Notebook (qtd: 15)", status = Sucesso}
LogEntry {timestamp = 2025-01-15 10:31:20.456 UTC, acao = Remove, detalhes = "Item 999 nao encontrado no inventario", status = Falha "Item 999 nao encontrado no inventario"}
```

**Importante:**
- Nao deletar para manter historico completo
- Pode crescer indefinidamente (considerar rotacao manual se necessario)
- Usado pelo comando `report` para estatisticas

## Estrutura de Dados e Tipos

### Item
Representa um item no inventario.

```haskell
data Item = Item {
    itemID :: String,      -- Identificador unico
    nome :: String,        -- Nome descritivo
    quantidade :: Int,     -- Quantidade em estoque
    categoria :: String    -- Categoria do produto
}
```

**Derivacoes:** Show, Read, Eq

---

### Inventario
Mapa de itens indexado por ID para acesso O(log n).

```haskell
type Inventario = Map String Item
```

Usa `Data.Map` para eficiencia em buscas, insercoes e remocoes.

---

### AcaoLog
Tipos de acoes que podem ser registradas.

```haskell
data AcaoLog = Add      -- Adicao de item
             | Remove   -- Remocao de quantidade
             | Update   -- Atualizacao de quantidade
             | QueryFail -- Comando invalido
```

---

### StatusLog
Status de uma operacao.

```haskell
data StatusLog = Sucesso           -- Operacao bem sucedida
               | Falha String      -- Operacao falhou com mensagem
```

---

### LogEntry
Entrada no log de auditoria.

```haskell
data LogEntry = LogEntry {
    timestamp :: UTCTime,    -- Momento da operacao
    acao :: AcaoLog,         -- Tipo de acao
    detalhes :: String,      -- Descricao da operacao
    status :: StatusLog      -- Resultado da operacao
}
```

**Derivacoes:** Show, Read

---

### ResultadoOperacao
Retorno das funcoes de manipulacao do inventario.

```haskell
type ResultadoOperacao = (Inventario, LogEntry)
```

Tupla com o novo estado do inventario e o log gerado pela operacao.

## Funcoes Principais

### Operacoes de Inventario

**addItem :: UTCTime -> String -> String -> Int -> String -> Inventario -> Either String ResultadoOperacao**

Adiciona um novo item ao inventario.

Validacoes:
- Quantidade > 0
- ID ainda nao existe

Retorna: Either com mensagem de erro (Left) ou novo inventario + log (Right)

---

**removeItem :: UTCTime -> String -> Int -> Inventario -> Either String ResultadoOperacao**

Remove quantidade de um item existente.

Validacoes:
- Item existe
- Quantidade a remover > 0
- Estoque suficiente

Comportamento especial: Se quantidade final = 0, remove item do Map

Retorna: Either com mensagem de erro (Left) ou novo inventario + log (Right)

---

**updateQty :: UTCTime -> String -> Int -> Inventario -> Either String ResultadoOperacao**

Atualiza quantidade de um item diretamente.

Validacoes:
- Item existe
- Quantidade >= 0

Comportamento especial: Se quantidade = 0, remove item do Map

Retorna: Either com mensagem de erro (Left) ou novo inventario + log (Right)

---

### Funcoes de Analise

**logsDeErro :: [LogEntry] -> [LogEntry]**

Filtra apenas os logs com status de Falha.

Usado pelo comando `report` para listar erros.

---

**historicoPorItem :: String -> [LogEntry] -> [LogEntry]**

Retorna todos os logs que mencionam um ID especifico.

Busca o ID nos detalhes de cada entrada usando `words`.

---

**itemMaisMovimentado :: [LogEntry] -> String**

Identifica qual item teve mais operacoes (Add, Remove, Update).

Algoritmo:
1. Filtra logs de operacoes (ignora QueryFail)
2. Extrai IDs dos detalhes de cada log
3. Conta ocorrencias de cada ID
4. Retorna o ID com maior contagem

Retorna: ID do item ou mensagem se nenhum encontrado

---

### Persistencia

**carregarInventario :: IO Inventario**

Carrega o inventario de `Inventario.dat`.

Tratamento de erros:
- Arquivo nao existe: retorna Map vazio
- Arquivo vazio: retorna Map vazio
- Erro de parse: retorna Map vazio

---

**carregarLogs :: IO [LogEntry]**

Carrega os logs de `Auditoria.log`.

Tratamento de erros:
- Arquivo nao existe: retorna lista vazia
- Arquivo vazio: retorna lista vazia
- Linhas invalidas: sao ignoradas (parse falha)

---

**salvarInventario :: Inventario -> IO ()**

Sobrescreve `Inventario.dat` com estado atual (writeFile).

---

**adicionarLog :: LogEntry -> IO ()**

Adiciona uma linha ao final de `Auditoria.log` (appendFile).

---

### Utilidades

**criarLogFalha :: UTCTime -> AcaoLog -> String -> LogEntry**

Cria um LogEntry com status de Falha.

Usado quando operacoes dao erro para registrar no log.

---

**popularDadosIniciais :: UTCTime -> Inventario -> IO (Inventario, [LogEntry])**

Adiciona 10 itens pre-definidos ao inventario.

Processo:
1. Define lista de 10 tuplas (ID, Nome, Qtd, Cat)
2. Usa foldl para adicionar cada item
3. Salva inventario final
4. Registra todos os logs
5. Retorna novo estado

IDs ja existentes sao pulados silenciosamente.

## Fluxo de Execucao

### Inicializacao (main)

1. Exibe banner "SISTEMA DE INVENTARIO"
2. Carrega `Inventario.dat` (ou cria vazio se nao existir)
3. Carrega `Auditoria.log` (ou cria vazio se nao existir)
4. Mostra quantos itens e logs foram carregados
5. Exibe dica para digitar 'help'
6. Entra no loop interativo

---

### Loop Interativo (loop)

1. Mostra prompt "> "
2. Le comando do usuario (getLine)
3. Se comando = "exit", encerra
4. Caso contrario, processa comando via `processarComando`
5. Recebe novo estado (inventario + logs)
6. Volta ao passo 1 com novo estado

---

### Processamento de Comando (processarComando)

1. Captura timestamp atual (getCurrentTime)
2. Faz parse do comando (words)
3. Match no tipo de comando
4. Executa funcao correspondente
5. Trata resultado (Either)
   - Right: salva inventario, adiciona log, mostra sucesso
   - Left: cria log de falha, adiciona log, mostra erro
6. Retorna novo estado (inventario, logs)

---

### Persistencia Automatica

Toda operacao bem sucedida:
1. Atualiza estado do inventario na memoria
2. Salva `Inventario.dat` (sobrescreve)
3. Adiciona entrada em `Auditoria.log` (append)
4. Retorna novo estado para o loop

Toda operacao com falha:
1. Mantem estado do inventario inalterado
2. Adiciona entrada de erro em `Auditoria.log` (append)
3. Retorna estado original para o loop

## Validacoes e Regras de Negocio

### Regras Gerais
- Todo item tem ID unico (string)
- Quantidade nunca pode ser negativa
- Quantidade em operacoes add/remove deve ser > 0
- Comandos invalidos sao registrados no log

### Regra de Remocao Automatica
Se a quantidade de um item chegar a zero (via remove ou update), o item é completamente removido do inventario usando `Map.delete`.

### Tratamento de Erros
Todas as funcoes de operacao usam `Either String ResultadoOperacao`:
- Left String: contem mensagem de erro
- Right (Inventario, LogEntry): contem novo estado + log

Erros de arquivo (IOException) sao capturados com `try` e tratados retornando valores vazios (Map.empty ou []).

## Exemplos de Uso

### Sessao Basica
```
> populate
Populando sistema com 10 itens iniciais...
10 itens adicionados com sucesso!

> list
INVENTARIO ATUAL
ID: 001 | Nome: Notebook | Qtd: 15 | Categoria: Eletronicos
ID: 002 | Nome: Mouse | Qtd: 50 | Categoria: Perifericos
...

> remove 001 5
Item removido com sucesso!

> update 002 100
Quantidade atualizada com sucesso!

> add 011 SSD_1TB 20 Armazenamento
Item adicionado com sucesso!

> report
RELATORIO DE LOGS
Total de operacoes: 14
Total de erros: 0
Item mais movimentado: 001

> exit
Sistema encerrado.
```

### Tratamento de Erros
```
> add 001 Produto 10 Cat
ERRO: Item com ID 001 ja existe no inventario

> remove 999 5
ERRO: Item 999 nao encontrado no inventario

> remove 001 100
ERRO: Estoque insuficiente. Disponivel: 15, solicitado: 100

> add 002 Item -5 Cat
ERRO: Quantidade deve ser maior que zero

> report
RELATORIO DE LOGS
Total de operacoes: 18
Total de erros: 4
Logs de erro:
  - Item com ID 001 ja existe no inventario
  - Item 999 nao encontrado no inventario
  - Estoque insuficiente. Disponivel: 15, solicitado: 100
  - Quantidade deve ser maior que zero
Item mais movimentado: 001
```
