-- =====================================================================
-- Projeto: Sistema de Gestão de Biblioteca
-- Arquivo: 01_schema.sql
-- Banco:   MySQL 8.0+
-- Objetivo: criar o banco e todas as tabelas, com chaves, restrições
--           e índices.
-- =====================================================================

DROP DATABASE IF EXISTS biblioteca;

CREATE DATABASE biblioteca
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE biblioteca;

-- ---------------------------------------------------------------------
-- Categorias (ex.: Romance, Tecnologia, História)
-- ---------------------------------------------------------------------
CREATE TABLE categorias (
    id    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    nome  VARCHAR(80)  NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_categorias_nome (nome)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Autores
-- ---------------------------------------------------------------------
CREATE TABLE autores (
    id            INT UNSIGNED NOT NULL AUTO_INCREMENT,
    nome          VARCHAR(120) NOT NULL,
    nacionalidade VARCHAR(60)  NULL,
    PRIMARY KEY (id),
    KEY idx_autores_nome (nome)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Livros (o "título" em si; as cópias físicas ficam em exemplares)
-- ---------------------------------------------------------------------
CREATE TABLE livros (
    id              INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    titulo          VARCHAR(200)  NOT NULL,
    isbn            CHAR(13)      NOT NULL,
    editora         VARCHAR(100)  NULL,
    ano_publicacao  SMALLINT      NULL,
    categoria_id    INT UNSIGNED  NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_livros_isbn (isbn),
    KEY idx_livros_titulo (titulo),
    CONSTRAINT fk_livros_categoria
        FOREIGN KEY (categoria_id) REFERENCES categorias (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT ck_livros_ano
        CHECK (ano_publicacao IS NULL OR ano_publicacao BETWEEN 1000 AND 2100)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Relação N:N entre livros e autores
-- ---------------------------------------------------------------------
CREATE TABLE livros_autores (
    livro_id INT UNSIGNED NOT NULL,
    autor_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (livro_id, autor_id),
    CONSTRAINT fk_la_livro
        FOREIGN KEY (livro_id) REFERENCES livros (id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_la_autor
        FOREIGN KEY (autor_id) REFERENCES autores (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Exemplares (cópias físicas de cada livro)
-- ---------------------------------------------------------------------
CREATE TABLE exemplares (
    id            INT UNSIGNED NOT NULL AUTO_INCREMENT,
    livro_id      INT UNSIGNED NOT NULL,
    codigo_barras VARCHAR(30)  NOT NULL,
    status        ENUM('disponivel', 'emprestado', 'manutencao', 'perdido')
                  NOT NULL DEFAULT 'disponivel',
    PRIMARY KEY (id),
    UNIQUE KEY uq_exemplares_codigo (codigo_barras),
    KEY idx_exemplares_status (status),
    CONSTRAINT fk_exemplares_livro
        FOREIGN KEY (livro_id) REFERENCES livros (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Membros (pessoas cadastradas na biblioteca)
-- Observação: nenhum dado sensível real deve ser usado neste projeto.
-- ---------------------------------------------------------------------
CREATE TABLE membros (
    id             INT UNSIGNED NOT NULL AUTO_INCREMENT,
    nome           VARCHAR(120) NOT NULL,
    email          VARCHAR(150) NOT NULL,
    telefone       VARCHAR(20)  NULL,
    data_cadastro  DATE         NOT NULL DEFAULT (CURRENT_DATE),
    ativo          TINYINT(1)   NOT NULL DEFAULT 1,
    PRIMARY KEY (id),
    UNIQUE KEY uq_membros_email (email)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Empréstimos
-- data_devolucao NULL = ainda não devolvido
-- ---------------------------------------------------------------------
CREATE TABLE emprestimos (
    id                       INT UNSIGNED NOT NULL AUTO_INCREMENT,
    exemplar_id              INT UNSIGNED NOT NULL,
    membro_id                INT UNSIGNED NOT NULL,
    data_emprestimo          DATE         NOT NULL DEFAULT (CURRENT_DATE),
    data_prevista_devolucao  DATE         NOT NULL,
    data_devolucao           DATE         NULL,
    PRIMARY KEY (id),
    KEY idx_emprestimos_membro (membro_id),
    KEY idx_emprestimos_exemplar (exemplar_id),
    KEY idx_emprestimos_devolucao (data_devolucao),
    CONSTRAINT fk_emprestimos_exemplar
        FOREIGN KEY (exemplar_id) REFERENCES exemplares (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_emprestimos_membro
        FOREIGN KEY (membro_id) REFERENCES membros (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT ck_emprestimos_datas
        CHECK (data_prevista_devolucao >= data_emprestimo
               AND (data_devolucao IS NULL OR data_devolucao >= data_emprestimo))
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Multas geradas por atraso na devolução
-- ---------------------------------------------------------------------
CREATE TABLE multas (
    id             INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    emprestimo_id  INT UNSIGNED  NOT NULL,
    valor          DECIMAL(8,2)  NOT NULL,
    paga           TINYINT(1)    NOT NULL DEFAULT 0,
    data_geracao   DATE          NOT NULL DEFAULT (CURRENT_DATE),
    PRIMARY KEY (id),
    KEY idx_multas_emprestimo (emprestimo_id),
    CONSTRAINT fk_multas_emprestimo
        FOREIGN KEY (emprestimo_id) REFERENCES emprestimos (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT ck_multas_valor CHECK (valor >= 0)
) ENGINE=InnoDB;
