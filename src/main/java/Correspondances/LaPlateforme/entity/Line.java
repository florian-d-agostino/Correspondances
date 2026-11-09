package Correspondances.LaPlateforme.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "line")
@Getter
@Setter
@NoArgsConstructor
public class Line {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "line_number", nullable = false, unique = true, length = 30)
    private String lineNumber;

    public Line(Long id, String lineNumber) {
        this.id = id;
        this.lineNumber = lineNumber;
    }
}
