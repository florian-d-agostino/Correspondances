package Correspondances.LaPlateforme.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "train")
@Getter
@Setter
@NoArgsConstructor
public class Train {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "train_number", nullable = false, unique = true, length = 30)
    private String trainNumber;

    public Train(Long id, String trainNumber) {
        this.id = id;
        this.trainNumber = trainNumber;
    }
}
