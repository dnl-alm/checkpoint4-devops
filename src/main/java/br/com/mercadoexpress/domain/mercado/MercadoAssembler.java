package br.com.mercadoexpress.domain.mercado;

import br.com.mercadoexpress.controller.MercadoController;
import br.com.mercadoexpress.dto.response.MercadoResponse;
import org.springframework.data.domain.Pageable;
import org.springframework.hateoas.EntityModel;
import org.springframework.hateoas.server.RepresentationModelAssembler;
import org.springframework.stereotype.Component;

import static org.springframework.hateoas.server.mvc.WebMvcLinkBuilder.linkTo;
import static org.springframework.hateoas.server.mvc.WebMvcLinkBuilder.methodOn;

@Component
public class MercadoAssembler
        implements RepresentationModelAssembler<MercadoResponse, EntityModel<MercadoResponse>> {

    @Override
    public EntityModel<MercadoResponse> toModel(MercadoResponse mercado) {

        return EntityModel.of(
                mercado,
                linkTo(methodOn(MercadoController.class)
                        .pesquisarPorId(mercado.id())).withSelfRel(),

                linkTo(methodOn(MercadoController.class)
                        .listarTudo(Pageable.unpaged())).withRel("mercados"),

                linkTo(methodOn(MercadoController.class)
                        .atualizar(mercado.id(), null)).withRel("atualizar"),

                linkTo(methodOn(MercadoController.class)
                        .deletar(mercado.id())).withRel("deletar")
        );
    }
}
