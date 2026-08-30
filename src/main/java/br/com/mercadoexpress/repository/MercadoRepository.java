package br.com.mercadoexpress.repository;

import br.com.mercadoexpress.domain.mercado.Mercado;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MercadoRepository extends JpaRepository<Mercado, Long> {
}
