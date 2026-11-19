-- =====================================================================
-- Projeto: Sistema de Gestão de Biblioteca
-- Arquivo: 03_queries.sql
-- Banco:   MySQL 8.0+
-- Objetivo: consultas úteis para o dia a dia da biblioteca.
-- Requisito: executar 01_schema.sql e 02_seed.sql antes deste arquivo.
--
-- Observação: as consultas de atraso usam CURDATE(), então o resultado
-- muda conforme o dia em que são executadas.
-- =====================================================================

USE biblioteca;

-- ---------------------------------------------------------------------
-- 1. Catálogo: cada livro com sua categoria e seus autores
--    (GROUP_CONCAT junta vários autores numa única linha)
--    Esperado: 10 linhas; "Database System Concepts" aparece com 3 autores.
-- ---------------------------------------------------------------------
SELECT
    l.titulo,
    c.nome AS categoria,
    GROUP_CONCAT(a.nome ORDER BY a.nome SEPARATOR ', ') AS autores
FROM livros l
JOIN categorias c      ON c.id = l.categoria_id
JOIN livros_autores la ON la.livro_id = l.id
JOIN autores a         ON a.id = la.autor_id
GROUP BY l.id, l.titulo, c.nome
ORDER BY l.titulo;

-- ---------------------------------------------------------------------
-- 2. Quantos exemplares disponíveis cada livro tem agora
--    (LEFT JOIN mantém na lista os livros sem nenhum exemplar disponível)
-- ---------------------------------------------------------------------
SELECT
    l.titulo,
    COUNT(e.id) AS exemplares_disponiveis
FROM livros l
LEFT JOIN exemplares e
       ON e.livro_id = l.id
      AND e.status = 'disponivel'
GROUP BY l.id, l.titulo
ORDER BY exemplares_disponiveis DESC, l.titulo;

-- ---------------------------------------------------------------------
-- 3. Empréstimos em aberto (ainda sem data de devolução)
--    Esperado: 3 linhas (empréstimos 5, 6 e 7).
-- ---------------------------------------------------------------------
SELECT
    em.id AS emprestimo,
    l.titulo,
    ex.codigo_barras,
    m.nome AS membro,
    em.data_emprestimo,
    em.data_prevista_devolucao
FROM emprestimos em
JOIN exemplares ex ON ex.id = em.exemplar_id
JOIN livros l      ON l.id = ex.livro_id
JOIN membros m     ON m.id = em.membro_id
WHERE em.data_devolucao IS NULL
ORDER BY em.data_prevista_devolucao;

-- ---------------------------------------------------------------------
-- 4. Empréstimos atrasados: em aberto e com o prazo já vencido
--    Em 19/11/2026, o esperado é 1 linha (empréstimo 5, 2 dias de atraso).
-- ---------------------------------------------------------------------
SELECT
    em.id AS emprestimo,
    l.titulo,
    m.nome AS membro,
    em.data_prevista_devolucao,
    DATEDIFF(CURDATE(), em.data_prevista_devolucao) AS dias_de_atraso
FROM emprestimos em
JOIN exemplares ex ON ex.id = em.exemplar_id
JOIN livros l      ON l.id = ex.livro_id
JOIN membros m     ON m.id = em.membro_id
WHERE em.data_devolucao IS NULL
  AND em.data_prevista_devolucao < CURDATE()
ORDER BY dias_de_atraso DESC;

-- ---------------------------------------------------------------------
-- 5. Membros mais ativos (quantidade de empréstimos por pessoa)
--    Esperado: Ana Souza e Bruno Lima com 2 empréstimos cada.
-- ---------------------------------------------------------------------
SELECT
    m.nome,
    COUNT(em.id) AS total_emprestimos
FROM membros m
JOIN emprestimos em ON em.membro_id = m.id
GROUP BY m.id, m.nome
ORDER BY total_emprestimos DESC, m.nome;

-- ---------------------------------------------------------------------
-- 6. Empréstimos por categoria
--    Esperado: Romance 2, Ficção Científica 2, Tecnologia 2, História 1.
-- ---------------------------------------------------------------------
SELECT
    c.nome AS categoria,
    COUNT(em.id) AS total_emprestimos
FROM categorias c
JOIN livros l       ON l.categoria_id = c.id
JOIN exemplares ex  ON ex.livro_id = l.id
JOIN emprestimos em ON em.exemplar_id = ex.id
GROUP BY c.id, c.nome
ORDER BY total_emprestimos DESC, c.nome;

-- ---------------------------------------------------------------------
-- 7. Total de multas pendentes por membro
--    Esperado: Ana Souza com R$ 4,50.
-- ---------------------------------------------------------------------
SELECT
    m.nome,
    SUM(mu.valor) AS total_pendente
FROM multas mu
JOIN emprestimos em ON em.id = mu.emprestimo_id
JOIN membros m      ON m.id = em.membro_id
WHERE mu.paga = 0
GROUP BY m.id, m.nome
ORDER BY total_pendente DESC;

-- ---------------------------------------------------------------------
-- 8. Membros que nunca fizeram um empréstimo
--    (LEFT JOIN + IS NULL encontra quem não tem registro relacionado)
--    Esperado: Fábio Teixeira.
-- ---------------------------------------------------------------------
SELECT
    m.nome,
    m.ativo
FROM membros m
LEFT JOIN emprestimos em ON em.membro_id = m.id
WHERE em.id IS NULL;

-- ---------------------------------------------------------------------
-- 9. Checagem de consistência: exemplar marcado como "emprestado" sem
--    empréstimo em aberto, ou o contrário.
--    Esperado: nenhuma linha (se aparecer algo, há dado inconsistente).
-- ---------------------------------------------------------------------
SELECT
    ex.id,
    ex.codigo_barras,
    ex.status
FROM exemplares ex
LEFT JOIN emprestimos em
       ON em.exemplar_id = ex.id
      AND em.data_devolucao IS NULL
WHERE (ex.status = 'emprestado' AND em.id IS NULL)
   OR (ex.status <> 'emprestado' AND em.id IS NOT NULL);

-- ---------------------------------------------------------------------
-- 10. VIEW: empréstimos em aberto, com situação e dias de atraso
--     Uma view guarda a consulta com um nome, como se fosse uma tabela.
--     Ela não expõe e-mail nem telefone dos membros, então pode ser usada
--     mais adiante por um perfil de acesso somente leitura.
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_emprestimos_em_aberto AS
SELECT
    em.id AS emprestimo,
    l.titulo,
    ex.codigo_barras,
    m.nome AS membro,
    em.data_emprestimo,
    em.data_prevista_devolucao,
    CASE
        WHEN em.data_prevista_devolucao < CURDATE() THEN 'atrasado'
        ELSE 'no prazo'
    END AS situacao,
    GREATEST(DATEDIFF(CURDATE(), em.data_prevista_devolucao), 0) AS dias_de_atraso
FROM emprestimos em
JOIN exemplares ex ON ex.id = em.exemplar_id
JOIN livros l      ON l.id = ex.livro_id
JOIN membros m     ON m.id = em.membro_id
WHERE em.data_devolucao IS NULL;

-- Usando a view:
SELECT * FROM v_emprestimos_em_aberto ORDER BY dias_de_atraso DESC;
