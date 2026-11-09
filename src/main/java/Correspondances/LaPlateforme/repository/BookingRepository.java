package Correspondances.LaPlateforme.repository;

import Correspondances.LaPlateforme.entity.Booking;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface BookingRepository extends JpaRepository<Booking, Long> {

    Optional<Booking> findByBookingReference(String bookingReference);

    Page<Booking> findByTravelDate(LocalDate travelDate, Pageable pageable);

    // Naive fetch demonstrating N+1 issue when accessing associated entities
    @Query("SELECT b FROM Booking b WHERE b.travelDate = :travelDate")
    List<Booking> findBookingsNaive(@Param("travelDate") LocalDate travelDate, Pageable pageable);

    // Optimized query with JOIN FETCH resolving the N+1 problem in a single SQL query
    @Query("SELECT b FROM Booking b " +
           "JOIN FETCH b.departureStation " +
           "JOIN FETCH b.arrivalStation " +
           "JOIN FETCH b.service s " +
           "JOIN FETCH s.train " +
           "JOIN FETCH s.line " +
           "JOIN FETCH b.seat st " +
           "JOIN FETCH st.car " +
           "WHERE b.travelDate = :travelDate")
    List<Booking> findBookingsOptimized(@Param("travelDate") LocalDate travelDate, Pageable pageable);
}
