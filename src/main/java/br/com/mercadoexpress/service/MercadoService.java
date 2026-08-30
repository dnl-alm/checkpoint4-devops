package br.com.mercadoexpress.service;

import br.com.mercadoexpress.domain.mercado.Mercado;
import br.com.mercadoexpress.dto.request.MercadoRequest;
import br.com.mercadoexpress.dto.response.MercadoResponse;
import br.com.mercadoexpress.exception.IdNaoEncontradoException;
import br.com.mercadoexpress.repository.MercadoRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class MercadoService {

    @Autowired
    private MercadoRepository mercadoRepository;

    @Transactional
    public MercadoResponse criar(MercadoRequest mercadoRequest) {
        var mercado = Mercado.builder()
                .nome(mercadoRequest.nome())
                .tipo(mercadoRequest.tipo())
                .setor(mercadoRequest.setor())
                .tamanho(mercadoRequest.tamanho())
                .preco(mercadoRequest.preco())
                .build();

        var mercadoSalvo = mercadoRepository.save(mercado);
        return new MercadoResponse(mercadoSalvo.getId(), mercadoSalvo.getNome(), mercadoSalvo.getTipo(),
                mercadoSalvo.getSetor(), mercadoSalvo.getTamanho(), mercadoSalvo.getPreco());
    }

    @Transactional(readOnly = true)
    public Page<MercadoResponse> listarTudo(Pageable pageable) {
        return mercadoRepository.findAll(pageable)
                .map(m -> new MercadoResponse(m.getId(), m.getNome(),
                        m.getTipo(), m.getSetor(), m.getTamanho(), m.getPreco()));
    }

    @Transactional(readOnly = true)
    public MercadoResponse pesquisarPorId(Long id) {
        var mercado = mercadoRepository.findById(id)
                .orElseThrow(() -> new IdNaoEncontradoException(id));
        return new MercadoResponse(mercado.getId(), mercado.getNome(), mercado.getTipo(),
                mercado.getSetor(), mercado.getTamanho(), mercado.getPreco());
    }

    @Transactional
    public MercadoResponse atualizar(Long id, MercadoRequest mercadoRequest) {
        var mercado = mercadoRepository.findById(id)
                .orElseThrow(() -> new IdNaoEncontradoException(id));

        var mercadoAtualizado = Mercado.builder()
                .nome(mercadoRequest.nome())
                .tipo(mercadoRequest.tipo())
                .setor(mercadoRequest.setor())
                .tamanho(mercadoRequest.tamanho())
                .preco(mercadoRequest.preco())
                .build();

        mercadoAtualizado.setId(mercado.getId());
        mercadoRepository.save(mercadoAtualizado);

        return new MercadoResponse(mercadoAtualizado.getId(), mercadoAtualizado.getNome(), mercadoAtualizado.getTipo(),
                mercadoAtualizado.getSetor(), mercadoAtualizado.getTamanho(), mercadoAtualizado.getPreco());
    }

    @Transactional
    public void deletar(Long id) {
        var mercado = mercadoRepository.findById(id)
                .orElseThrow(() -> new IdNaoEncontradoException(id));
        mercadoRepository.delete(mercado);
    }

}
