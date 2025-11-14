import qualified Data.Map as Map
import Data.Map (Map)
import Data.Time
import System.IO
import Control.Exception
import Control.Monad (unless)

data Item = Item {
    itemID :: String,
    nome :: String,
    quantidade :: Int,
    categoria :: String
} deriving (Show, Read, Eq)

type Inventario = Map String Item

data AcaoLog = Add | Remove | Update | QueryFail
    deriving (Show, Read, Eq)

data StatusLog = Sucesso | Falha String
    deriving (Show, Read, Eq)

data LogEntry = LogEntry {
    timestamp :: UTCTime,
    acao :: AcaoLog,
    detalhes :: String,
    status :: StatusLog
} deriving (Show, Read)

type ResultadoOperacao = (Inventario, LogEntry)

addItem :: UTCTime -> String -> String -> Int -> String -> Inventario 
        -> Either String ResultadoOperacao
addItem t idItem nomeItem qtd cat inv =
    if qtd <= 0 then
        Left "Quantidade deve ser maior que zero"
    else if Map.member idItem inv then
        Left ("Item com ID " ++ idItem ++ " ja existe no inventario")
    else
        let item = Item idItem nomeItem qtd cat
            inv2 = Map.insert idItem item inv
            log = LogEntry t Add 
                       ("Adicionado: " ++ idItem ++ " - " ++ nomeItem ++ " (qtd: " ++ show qtd ++ ")")
                       Sucesso
        in Right (inv2, log)

removeItem :: UTCTime -> String -> Int -> Inventario 
           -> Either String ResultadoOperacao
removeItem t idItem qtd inv =
    case Map.lookup idItem inv of
        Nothing -> Left ("Item " ++ idItem ++ " nao encontrado no inventario")
        Just i ->
            if qtd <= 0 then
                Left "Quantidade a remover deve ser maior que zero"
            else if quantidade i < qtd then
                Left ("Estoque insuficiente. Disponivel: " ++ show (quantidade i) ++ 
                      ", solicitado: " ++ show qtd)
            else
                let q = quantidade i - qtd
                    i2 = i { quantidade = q }
                    inv2 = if q == 0 
                              then Map.delete idItem inv
                              else Map.insert idItem i2 inv
                    log = LogEntry t Remove
                               ("Removido: " ++ idItem ++ " - " ++ nome i ++ 
                                " (qtd removida: " ++ show qtd ++ ")")
                               Sucesso
                in Right (inv2, log)

updateQty :: UTCTime -> String -> Int -> Inventario 
          -> Either String ResultadoOperacao
updateQty t idItem novaQtd inv =
    case Map.lookup idItem inv of
        Nothing -> Left ("Item " ++ idItem ++ " nao encontrado no inventario")
        Just i ->
            if novaQtd < 0 then
                Left "Quantidade nao pode ser negativa"
            else
                let i2 = i { quantidade = novaQtd }
                    inv2 = if novaQtd == 0
                              then Map.delete idItem inv
                              else Map.insert idItem i2 inv
                    log = LogEntry t Update
                               ("Atualizado: " ++ idItem ++ " - " ++ nome i ++ 
                                " (nova qtd: " ++ show novaQtd ++ ")")
                               Sucesso
                in Right (inv2, log)

logsDeErro :: [LogEntry] -> [LogEntry]
logsDeErro ls = filter ehErro ls
    where ehErro entry = case status entry of
                            Falha _ -> True
                            _ -> False

historicoPorItem :: String -> [LogEntry] -> [LogEntry]
historicoPorItem itemId logs = filter (temItem itemId) logs
    where temItem id entry = id `elem` words (detalhes entry)

itemMaisMovimentado :: [LogEntry] -> String
itemMaisMovimentado logs =
    let logsOps = filter (\e -> acao e `elem` [Add, Remove, Update]) logs
    in if null logsOps then
        "Nenhum item movimentado"
    else
        let extrairID entrada = case words (detalhes entrada) of
                                  (_:id:_) -> Just id
                                  _ -> Nothing
            ids = [id | Just id <- map extrairID logsOps]
            counts = Map.toList $ foldr (\id m -> 
                Map.insertWith (+) id (1 :: Int) m) Map.empty ids
        in if null counts then "Nenhum item identificado"
           else snd $ maximum [(c, i) | (i, c) <- counts]

carregarInventario :: IO Inventario
carregarInventario = do
    r <- try (readFile "Inventario.dat") :: IO (Either SomeException String)
    case r of
        Left _ -> return Map.empty
        Right txt -> 
            if null txt then return Map.empty
            else case reads txt of
                    [(inv, "")] -> return inv
                    _ -> return Map.empty

carregarLogs :: IO [LogEntry]
carregarLogs = do
    r <- try (readFile "Auditoria.log") :: IO (Either SomeException String)
    case r of
        Left _ -> return []
        Right txt ->
            if null txt then return []
            else let linhas = lines txt
                     parseLinha l = case reads l of
                                      [(entry, "")] -> Just entry
                                      _ -> Nothing
                 in return [entry | Just entry <- map parseLinha linhas]

salvarInventario :: Inventario -> IO ()
salvarInventario inv = writeFile "Inventario.dat" (show inv)

adicionarLog :: LogEntry -> IO ()
adicionarLog entry = appendFile "Auditoria.log" (show entry ++ "\n")

criarLogFalha :: UTCTime -> AcaoLog -> String -> LogEntry
criarLogFalha t acaoTipo msg = LogEntry t acaoTipo msg (Falha msg)

listarInventario :: Inventario -> IO ()
listarInventario inv = do
    putStrLn "INVENTARIO ATUAL"
    if Map.null inv then putStrLn "Inventario vazio."
    else mapM_ mostrarItem (Map.elems inv)
    where
        mostrarItem i = putStrLn $ 
            "ID: " ++ itemID i ++ 
            " | Nome: " ++ nome i ++ 
            " | Qtd: " ++ show (quantidade i) ++ 
            " | Categoria: " ++ categoria i

exibirRelatorios :: [LogEntry] -> IO ()
exibirRelatorios logs = do
    putStrLn "RELATORIO DE LOGS"
    putStrLn $ "Total de operacoes: " ++ show (length logs)
    let erros = logsDeErro logs
    putStrLn $ "Total de erros: " ++ show (length erros)
    unless (null erros) $ do
        putStrLn "Logs de erro:"
        mapM_ (\e -> putStrLn $ "  - " ++ detalhes e) erros
    putStrLn $ "Item mais movimentado: " ++ itemMaisMovimentado logs

popularDadosIniciais :: UTCTime -> Inventario -> IO (Inventario, [LogEntry])
popularDadosIniciais t inv = do
    putStrLn "Populando sistema com 10 itens iniciais..."
    let itens = [
            ("001", "Notebook", 15, "Eletronicos"),
            ("002", "Mouse", 50, "Perifericos"),
            ("003", "Teclado", 30, "Perifericos"),
            ("004", "Monitor", 20, "Eletronicos"),
            ("005", "WebCam", 25, "Perifericos"),
            ("006", "HeadSet", 40, "Audio"),
            ("007", "Impressora", 10, "Eletronicos"),
            ("008", "Scanner", 8, "Eletronicos"),
            ("009", "Microfone", 35, "Audio"),
            ("010", "Caixa_de_Som", 22, "Audio")
          ]
    
    let adicionarItem' (inv', logs') (id', nome', qtd', cat') =
            case addItem t id' nome' qtd' cat' inv' of
                Right (inv'', log) -> (inv'', log : logs')
                Left _ -> (inv', logs')
    
    let (invFinal, logsFinal) = foldl adicionarItem' (inv, []) itens
    
    salvarInventario invFinal
    mapM_ adicionarLog logsFinal
    putStrLn "10 itens adicionados com sucesso!"
    return (invFinal, logsFinal)

processarComando :: Inventario -> [LogEntry] -> String -> IO (Inventario, [LogEntry])
processarComando inv logs cmd = do
    t <- getCurrentTime
    case words cmd of
        ["add", idItem, nomeItem, qtdStr, cat] ->
            case reads qtdStr :: [(Int, String)] of
                [(qtd, "")] ->
                    case addItem t idItem nomeItem qtd cat inv of
                        Right (inv2, log) -> do
                            salvarInventario inv2
                            adicionarLog log
                            putStrLn "Item adicionado com sucesso!"
                            return (inv2, log : logs)
                        Left err -> do
                            let log = criarLogFalha t Add err
                            adicionarLog log
                            putStrLn $ "ERRO: " ++ err
                            return (inv, log : logs)
                _ -> do
                    let log = criarLogFalha t Add "Quantidade invalida"
                    adicionarLog log
                    putStrLn "ERRO: Quantidade invalida"
                    return (inv, log : logs)
        
        ["remove", idItem, qtdStr] ->
            case reads qtdStr :: [(Int, String)] of
                [(qtd, "")] ->
                    case removeItem t idItem qtd inv of
                        Right (inv2, log) -> do
                            salvarInventario inv2
                            adicionarLog log
                            putStrLn "Item removido com sucesso!"
                            return (inv2, log : logs)
                        Left err -> do
                            let log = criarLogFalha t Remove err
                            adicionarLog log
                            putStrLn $ "ERRO: " ++ err
                            return (inv, log : logs)
                _ -> do
                    let log = criarLogFalha t Remove "Quantidade invalida"
                    adicionarLog log
                    putStrLn "ERRO: Quantidade invalida"
                    return (inv, log : logs)
        
        ["update", idItem, qtdStr] ->
            case reads qtdStr :: [(Int, String)] of
                [(qtd, "")] ->
                    case updateQty t idItem qtd inv of
                        Right (inv2, log) -> do
                            salvarInventario inv2
                            adicionarLog log
                            putStrLn "Quantidade atualizada com sucesso!"
                            return (inv2, log : logs)
                        Left err -> do
                            let log = criarLogFalha t Update err
                            adicionarLog log
                            putStrLn $ "ERRO: " ++ err
                            return (inv, log : logs)
                _ -> do
                    let log = criarLogFalha t Update "Quantidade invalida"
                    adicionarLog log
                    putStrLn "ERRO: Quantidade invalida"
                    return (inv, log : logs)
        
        ["list"] -> do
            listarInventario inv
            return (inv, logs)
        
        ["report"] -> do
            exibirRelatorios logs
            return (inv, logs)
        
        ["populate"] -> do
            (invNovo, logsNovos) <- popularDadosIniciais t inv
            return (invNovo, logsNovos ++ logs)
        
        ["help"] -> do
            putStrLn "Comandos disponiveis:"
            putStrLn "add ID NOME QTD CATEGORIA - Adicionar item"
            putStrLn "remove ID QTD - Remover quantidade"
            putStrLn "update ID QTD - Atualizar quantidade"
            putStrLn "list - Listar inventario"
            putStrLn "report - Gerar relatorio"
            putStrLn "populate - Popular com 10 itens"
            putStrLn "help - Mostrar ajuda"
            putStrLn "exit - Sair"
            return (inv, logs)
        
        ["exit"] -> do
            putStrLn "Encerrando o sistema..."
            return (inv, logs)
        
        _ -> do
            let log = criarLogFalha t QueryFail ("Comando invalido: " ++ cmd)
            adicionarLog log
            putStrLn "Comando invalido. Digite 'help' para ver os comandos disponiveis."
            return (inv, log : logs)

loop :: Inventario -> [LogEntry] -> IO ()
loop inv logs = do
    putStr "> "
    hFlush stdout
    cmd <- getLine
    if cmd == "exit" then putStrLn "Sistema encerrado."
    else do
        (inv2, logs2) <- processarComando inv logs cmd
        loop inv2 logs2

main :: IO ()
main = do
    putStrLn "SISTEMA DE INVENTARIO"
    putStrLn "Carregando dados..."
    inv <- carregarInventario
    logs <- carregarLogs
    putStrLn $ "Inventario carregado: " ++ show (Map.size inv) ++ " itens"
    putStrLn $ "Logs carregados: " ++ show (length logs) ++ " entradas"
    putStrLn "Digite 'help' para ver os comandos disponiveis."
    loop inv logs
