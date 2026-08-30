package br.com.mercadoexpress.dto.response;

public record MercadoResponse(
        Long id,
        String nome,
        String tipo,
        String setor,
        Double tamanho,
        Double preco
) {
}
