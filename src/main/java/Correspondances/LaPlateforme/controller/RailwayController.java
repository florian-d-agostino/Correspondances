package Correspondances.LaPlateforme.controller;

import Correspondances.LaPlateforme.dto.BookingSummaryDto;
import Correspondances.LaPlateforme.entity.Booking;
import Correspondances.LaPlateforme.entity.Line;
import Correspondances.LaPlateforme.entity.Station;
import Correspondances.LaPlateforme.repository.BookingRepository;
import Correspondances.LaPlateforme.repository.LineRepository;
import Correspondances.LaPlateforme.repository.StationRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
@Tag(name = "Railway Network & Bookings", description = "Read-only access endpoints for network and reservations")
public class RailwayController {

    private final StationRepository stationRepository;
    private final LineRepository lineRepository;
    private final BookingRepository bookingRepository;

    @Operation(summary = "List all network stations")
    @GetMapping("/stations")
    public List<Station> getAllStations() {
        return stationRepository.findAll();
    }

    @Operation(summary = "List all railway lines")
    @GetMapping("/lines")
    public List<Line> getAllLines() {
        return lineRepository.findAll();
    }

    @Operation(summary = "Get booking details by reference code")
    @GetMapping("/bookings/{reference}")
    public ResponseEntity<BookingSummaryDto> getBookingByReference(@PathVariable String reference) {
        return bookingRepository.findByBookingReference(reference)
                .map(this::toDto)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @Operation(summary = "Demonstrate N+1 query issue (Naive fetching)")
    @GetMapping("/bookings/benchmark/naive")
    public List<BookingSummaryDto> getBookingsNaive(
            @RequestParam(defaultValue = "2026-03-15") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestParam(defaultValue = "50") int limit) {
        List<Booking> bookings = bookingRepository.findBookingsNaive(date, PageRequest.of(0, limit));
        return bookings.stream().map(this::toDto).toList();
    }

    @Operation(summary = "Demonstrate N+1 query resolution (JOIN FETCH)")
    @GetMapping("/bookings/benchmark/optimized")
    public List<BookingSummaryDto> getBookingsOptimized(
            @RequestParam(defaultValue = "2026-03-15") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestParam(defaultValue = "50") int limit) {
        List<Booking> bookings = bookingRepository.findBookingsOptimized(date, PageRequest.of(0, limit));
        return bookings.stream().map(this::toDto).toList();
    }

    private BookingSummaryDto toDto(Booking b) {
        return new BookingSummaryDto(
                b.getId(),
                b.getBookingReference(),
                b.getPassengerName(),
                b.getTravelerProfile(),
                b.getDepartureStation().getName(),
                b.getArrivalStation().getName(),
                b.getService().getServiceCode(),
                b.getSeat().getSeatNumber(),
                b.getSeat().getComfortClass(),
                b.getTravelDate(),
                b.getTotalPrice()
        );
    }
}
