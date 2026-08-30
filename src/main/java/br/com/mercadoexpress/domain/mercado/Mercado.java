package br.com.mercadoexpress.domain.mercado;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "TDS_TB_mercado")
@AllArgsConstructor
@NoArgsConstructor
@Data
@Builder
public class Mercado {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 50)
    private String nome;

    @Column(nullable = false, length = 50)
    private String tipo;

    private String setor;

    private Double tamanho;

    @Column(nullable = false)
    private Double preco;

}
