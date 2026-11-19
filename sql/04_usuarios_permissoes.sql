-- =====================================================================
-- Projeto: Sistema de Gestão de Biblioteca
-- Arquivo: 04_usuarios_permissoes.sql
-- Banco:   MySQL 8.0+
-- Objetivo: criar perfis de acesso seguindo o princípio do menor
--           privilégio: cada usuário recebe só o que precisa.
-- Requisito: executar 01, 02 e 03 antes (a view v_emprestimos_em_aberto
--            é criada no 03_queries.sql). Rodar com um usuário que
--            tenha permissão para criar usuários (ex.: root).
--
-- IMPORTANTE SOBRE SENHAS:
--  * As senhas abaixo são apenas MODELOS para estudo.
--  * Nunca use essas senhas em um ambiente real e nunca suba senhas
--    verdadeiras para o GitHub.
--  * Depois de criar os usuários, troque a senha com:
--      ALTER USER 'biblioteca_admin'@'localhost' IDENTIFIED BY 'sua_nova_senha';
-- =====================================================================

-- ---------------------------------------------------------------------
-- Limpeza: permite rodar o script mais de uma vez
-- ---------------------------------------------------------------------
DROP USER IF EXISTS 'biblioteca_admin'@'localhost';
DROP USER IF EXISTS 'biblioteca_atendente'@'localhost';
DROP USER IF EXISTS 'biblioteca_leitura'@'localhost';

-- ---------------------------------------------------------------------
-- Criação dos usuários (acesso apenas a partir da própria máquina)
-- ---------------------------------------------------------------------
CREATE USER 'biblioteca_admin'@'localhost'     IDENTIFIED BY 'Trocar#Admin1Senha';
CREATE USER 'biblioteca_atendente'@'localhost' IDENTIFIED BY 'Trocar#Atend1Senha';
CREATE USER 'biblioteca_leitura'@'localhost'   IDENTIFIED BY 'Trocar#Leitura1Senha';

-- ---------------------------------------------------------------------
-- Perfil 1: ADMINISTRADOR
-- Controle total, mas só sobre o banco "biblioteca" (não sobre o
-- servidor inteiro) e sem poder repassar permissões a outros.
-- ---------------------------------------------------------------------
GRANT ALL PRIVILEGES ON biblioteca.* TO 'biblioteca_admin'@'localhost';

-- ---------------------------------------------------------------------
-- Perfil 2: ATENDENTE (quem trabalha no balcão)
-- Pode consultar tudo e registrar o movimento do dia a dia.
-- Não pode apagar nada (nenhum DELETE) nem alterar a estrutura.
-- ---------------------------------------------------------------------
GRANT SELECT ON biblioteca.* TO 'biblioteca_atendente'@'localhost';

-- Cadastrar e atualizar membros
GRANT INSERT, UPDATE ON biblioteca.membros TO 'biblioteca_atendente'@'localhost';

-- Registrar empréstimos e devoluções
GRANT INSERT, UPDATE ON biblioteca.emprestimos TO 'biblioteca_atendente'@'localhost';

-- Registrar multas e marcar como paga
GRANT INSERT, UPDATE ON biblioteca.multas TO 'biblioteca_atendente'@'localhost';

-- Mudar apenas o STATUS do exemplar (permissão por coluna: ele não
-- consegue alterar o código de barras nem o livro do exemplar)
GRANT UPDATE (status) ON biblioteca.exemplares TO 'biblioteca_atendente'@'localhost';

-- ---------------------------------------------------------------------
-- Perfil 3: LEITURA (consulta pública do catálogo)
-- Só enxerga o catálogo e a view de empréstimos em aberto.
-- NÃO enxerga a tabela de membros (dados pessoais) nem as multas.
-- ---------------------------------------------------------------------
GRANT SELECT ON biblioteca.livros                 TO 'biblioteca_leitura'@'localhost';
GRANT SELECT ON biblioteca.autores                TO 'biblioteca_leitura'@'localhost';
GRANT SELECT ON biblioteca.categorias             TO 'biblioteca_leitura'@'localhost';
GRANT SELECT ON biblioteca.livros_autores         TO 'biblioteca_leitura'@'localhost';
GRANT SELECT ON biblioteca.exemplares             TO 'biblioteca_leitura'@'localhost';
GRANT SELECT ON biblioteca.v_emprestimos_em_aberto TO 'biblioteca_leitura'@'localhost';

-- ---------------------------------------------------------------------
-- Exemplo de REVOKE (retirar uma permissão que já foi concedida).
-- Descomente para testar: o atendente deixaria de registrar multas.
-- ---------------------------------------------------------------------
-- REVOKE INSERT ON biblioteca.multas FROM 'biblioteca_atendente'@'localhost';

-- ---------------------------------------------------------------------
-- Conferindo o que cada usuário pode fazer
-- ---------------------------------------------------------------------
SHOW GRANTS FOR 'biblioteca_admin'@'localhost';
SHOW GRANTS FOR 'biblioteca_atendente'@'localhost';
SHOW GRANTS FOR 'biblioteca_leitura'@'localhost';

-- ---------------------------------------------------------------------
-- Testes sugeridos (rodar no terminal, um usuário por vez):
--
--   mysql -u biblioteca_leitura -p biblioteca
--     SELECT * FROM livros;                      -- funciona
--     SELECT * FROM v_emprestimos_em_aberto;     -- funciona
--     SELECT * FROM membros;                     -- ERRO 1142: acesso negado
--     DELETE FROM livros;                        -- ERRO 1142: acesso negado
--
--   mysql -u biblioteca_atendente -p biblioteca
--     SELECT * FROM membros;                     -- funciona
--     UPDATE exemplares SET status = 'manutencao' WHERE id = 1;   -- funciona
--     UPDATE exemplares SET codigo_barras = 'X' WHERE id = 1;     -- ERRO: só pode alterar "status"
--     DELETE FROM emprestimos;                   -- ERRO 1142: acesso negado
--
-- Observação: a view v_emprestimos_em_aberto funciona para o perfil de
-- leitura porque é executada com as permissões de quem a criou
-- (SQL SECURITY DEFINER, o padrão do MySQL). Assim, a pessoa vê o
-- resultado sem precisar de acesso às tabelas de membros e empréstimos.
-- ---------------------------------------------------------------------
