CREATE TABLE IF NOT EXISTS TDS_TB_mercado (
                                              Id INT AUTO_INCREMENT PRIMARY KEY,
                                              Nome VARCHAR(255) NOT NULL,
    Tipo VARCHAR(100),
    Setor VARCHAR(100),
    Tamanho VARCHAR(50),
    Preco DECIMAL(10,2)
    );