package Correspondances.LaPlateforme.repository;

import Correspondances.LaPlateforme.entity.Line;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface LineRepository extends JpaRepository<Line, Long> {
    Optional<Line> findByLineNumber(String lineNumber);
}
