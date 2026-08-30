package br.com.mercadoexpress.exception;

public class IdNaoEncontradoException extends RuntimeException {
    public IdNaoEncontradoException(Long id) {
        super("Id não encontrado: " + id);
    }
}
