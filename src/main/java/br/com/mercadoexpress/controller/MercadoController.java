package br.com.mercadoexpress.controller;

import br.com.mercadoexpress.domain.mercado.MercadoAssembler;
import br.com.mercadoexpress.dto.request.MercadoRequest;
import br.com.mercadoexpress.dto.response.MercadoResponse;
import br.com.mercadoexpress.service.MercadoService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PagedResourcesAssembler;
import org.springframework.hateoas.EntityModel;
import org.springframework.hateoas.PagedModel;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;


@RestController
@RequiredArgsConstructor
@RequestMapping("/mercado")
public class MercadoController {

    private final MercadoService mercadoService;
    private final MercadoAssembler mercadoAssembler;
    private final PagedResourcesAssembler<MercadoResponse> pagedAssembler;

    @PostMapping
    public ResponseEntity<EntityModel<MercadoResponse>> criar(@RequestBody @Valid MercadoRequest mercadoRequest) {
        var mercado = mercadoService.criar(mercadoRequest);
        return ResponseEntity.status(HttpStatus.CREATED).body(mercadoAssembler.toModel(mercado));
    }

    @GetMapping
    public ResponseEntity<PagedModel<EntityModel<MercadoResponse>>> listarTudo(Pageable pageable) {
        Page<MercadoResponse> page = mercadoService.listarTudo(pageable);
        PagedModel<EntityModel<MercadoResponse>> model = pagedAssembler.toModel(page, mercadoAssembler);
        return ResponseEntity.ok(model);
    }

    @GetMapping("/{id}")
    public ResponseEntity<EntityModel<MercadoResponse>> pesquisarPorId(@PathVariable Long id) {
        var mercado = mercadoService.pesquisarPorId(id);
        return ResponseEntity.ok(mercadoAssembler.toModel(mercado));
    }

    @PutMapping("/{id}")
    public ResponseEntity<EntityModel<MercadoResponse>> atualizar(@PathVariable Long id, @RequestBody @Valid MercadoRequest mercadoRequest) {
        var mercado = mercadoService.atualizar(id, mercadoRequest);
        return ResponseEntity.ok(mercadoAssembler.toModel(mercado));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletar(@PathVariable Long id) {
        mercadoService.deletar(id);
        return ResponseEntity.noContent().build();
    }

}
