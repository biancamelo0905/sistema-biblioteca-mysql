-- =====================================================================
-- Projeto: Sistema de Gestão de Biblioteca
-- Arquivo: 02_seed.sql
-- Banco:   MySQL 8.0+
-- Objetivo: popular o banco com dados FICTÍCIOS para testes.
-- Requisito: executar 01_schema.sql antes deste arquivo.
--
-- Avisos:
--  * Nomes de membros, e-mails e telefones são inventados.
--    (os e-mails usam o domínio reservado example.com)
--  * Os ISBNs são fictícios e não correspondem às edições reais.
--  * As datas dos empréstimos foram escolhidas para gerar casos
--    variados: devolvidos no prazo, devolvidos com atraso (com multa)
--    e ainda em aberto.
-- =====================================================================

USE biblioteca;

-- ---------------------------------------------------------------------
-- Categorias
-- ---------------------------------------------------------------------
INSERT INTO categorias (id, nome) VALUES
    (1, 'Romance'),
    (2, 'Tecnologia'),
    (3, 'História'),
    (4, 'Ficção Científica'),
    (5, 'Infantil');

-- ---------------------------------------------------------------------
-- Autores
-- ---------------------------------------------------------------------
INSERT INTO autores (id, nome, nacionalidade) VALUES
    (1,  'Machado de Assis',     'Brasileira'),
    (2,  'Clarice Lispector',    'Brasileira'),
    (3,  'George Orwell',        'Britânica'),
    (4,  'Isaac Asimov',         'Americana'),
    (5,  'Monteiro Lobato',      'Brasileira'),
    (6,  'Abraham Silberschatz', 'Americana'),
    (7,  'Henry F. Korth',       'Americana'),
    (8,  'S. Sudarshan',         'Indiana'),
    (9,  'Yuval Noah Harari',    'Israelense'),
    (10, 'Andrew S. Tanenbaum',  'Americana');

-- ---------------------------------------------------------------------
-- Livros
-- ---------------------------------------------------------------------
INSERT INTO livros (id, titulo, isbn, editora, ano_publicacao, categoria_id) VALUES
    (1,  'Dom Casmurro',                        '9780000000011', 'Editora Exemplo', 1899, 1),
    (2,  'A Hora da Estrela',                   '9780000000028', 'Editora Exemplo', 1977, 1),
    (3,  '1984',                                '9780000000035', 'Editora Exemplo', 1949, 4),
    (4,  'Eu, Robô',                            '9780000000042', 'Editora Exemplo', 1950, 4),
    (5,  'Reinações de Narizinho',              '9780000000059', 'Editora Exemplo', 1931, 5),
    (6,  'Database System Concepts',            '9780000000066', 'Editora Exemplo', 2019, 2),
    (7,  'Sapiens',                             '9780000000073', 'Editora Exemplo', 2011, 3),
    (8,  'Redes de Computadores',               '9780000000080', 'Editora Exemplo', 2011, 2),
    (9,  'Memórias Póstumas de Brás Cubas',     '9780000000097', 'Editora Exemplo', 1881, 1),
    (10, 'Fundação',                            '9780000000103', 'Editora Exemplo', 1951, 4);

-- ---------------------------------------------------------------------
-- Livros x Autores (o livro 6 tem três autores, exemplo de relação N:N)
-- ---------------------------------------------------------------------
INSERT INTO livros_autores (livro_id, autor_id) VALUES
    (1,  1),
    (2,  2),
    (3,  3),
    (4,  4),
    (5,  5),
    (6,  6),
    (6,  7),
    (6,  8),
    (7,  9),
    (8,  10),
    (9,  1),
    (10, 4);

-- ---------------------------------------------------------------------
-- Exemplares
-- O status acompanha os empréstimos abaixo: os exemplares 10, 12 e 14
-- estão emprestados (empréstimos ainda sem data de devolução).
-- ---------------------------------------------------------------------
INSERT INTO exemplares (id, livro_id, codigo_barras, status) VALUES
    (1,  1,  'BIB-0001', 'disponivel'),
    (2,  1,  'BIB-0002', 'disponivel'),
    (3,  2,  'BIB-0003', 'disponivel'),
    (4,  3,  'BIB-0004', 'disponivel'),
    (5,  3,  'BIB-0005', 'disponivel'),
    (6,  4,  'BIB-0006', 'disponivel'),
    (7,  5,  'BIB-0007', 'manutencao'),
    (8,  6,  'BIB-0008', 'disponivel'),
    (9,  7,  'BIB-0009', 'disponivel'),
    (10, 7,  'BIB-0010', 'emprestado'),
    (11, 8,  'BIB-0011', 'disponivel'),
    (12, 8,  'BIB-0012', 'emprestado'),
    (13, 9,  'BIB-0013', 'disponivel'),
    (14, 10, 'BIB-0014', 'emprestado'),
    (15, 10, 'BIB-0015', 'perdido'),
    (16, 2,  'BIB-0016', 'disponivel');

-- ---------------------------------------------------------------------
-- Membros (todos fictícios)
-- ---------------------------------------------------------------------
INSERT INTO membros (id, nome, email, telefone, data_cadastro, ativo) VALUES
    (1, 'Ana Souza',      'ana.souza@example.com',      '(11) 90000-0001', '2026-01-10', 1),
    (2, 'Bruno Lima',     'bruno.lima@example.com',     '(11) 90000-0002', '2026-02-15', 1),
    (3, 'Carla Mendes',   'carla.mendes@example.com',   '(11) 90000-0003', '2026-03-20', 1),
    (4, 'Diego Alves',    'diego.alves@example.com',    '(11) 90000-0004', '2026-05-05', 1),
    (5, 'Elisa Rocha',    'elisa.rocha@example.com',    '(11) 90000-0005', '2026-07-12', 1),
    (6, 'Fábio Teixeira', 'fabio.teixeira@example.com', NULL,              '2025-11-30', 0);

-- ---------------------------------------------------------------------
-- Empréstimos
--  1 e 3: devolvidos no prazo
--  2 e 4: devolvidos com atraso (geram multa)
--  5, 6 e 7: em aberto (data_devolucao NULL); o 5 já passou do prazo
-- ---------------------------------------------------------------------
INSERT INTO emprestimos
    (id, exemplar_id, membro_id, data_emprestimo, data_prevista_devolucao, data_devolucao)
VALUES
    (1, 1,  1, '2026-09-01', '2026-09-15', '2026-09-14'),
    (2, 3,  2, '2026-09-05', '2026-09-19', '2026-09-25'),
    (3, 5,  3, '2026-10-02', '2026-10-16', '2026-10-15'),
    (4, 8,  1, '2026-10-10', '2026-10-24', '2026-11-02'),
    (5, 10, 4, '2026-11-03', '2026-11-17', NULL),
    (6, 12, 5, '2026-11-10', '2026-11-24', NULL),
    (7, 14, 2, '2026-11-15', '2026-11-29', NULL);

-- ---------------------------------------------------------------------
-- Multas (R$ 0,50 por dia de atraso)
--  Empréstimo 2: 6 dias de atraso = R$ 3,00 (já paga)
--  Empréstimo 4: 9 dias de atraso = R$ 4,50 (pendente)
-- ---------------------------------------------------------------------
INSERT INTO multas (id, emprestimo_id, valor, paga, data_geracao) VALUES
    (1, 2, 3.00, 1, '2026-09-25'),
    (2, 4, 4.50, 0, '2026-11-02');

-- ---------------------------------------------------------------------
-- Verificação rápida: quantidade de registros em cada tabela
-- Esperado: 5, 10, 10, 12, 16, 6, 7, 2
-- ---------------------------------------------------------------------
SELECT 'categorias'     AS tabela, COUNT(*) AS total FROM categorias
UNION ALL SELECT 'autores',        COUNT(*) FROM autores
UNION ALL SELECT 'livros',         COUNT(*) FROM livros
UNION ALL SELECT 'livros_autores', COUNT(*) FROM livros_autores
UNION ALL SELECT 'exemplares',     COUNT(*) FROM exemplares
UNION ALL SELECT 'membros',        COUNT(*) FROM membros
UNION ALL SELECT 'emprestimos',    COUNT(*) FROM emprestimos
UNION ALL SELECT 'multas',         COUNT(*) FROM multas;
