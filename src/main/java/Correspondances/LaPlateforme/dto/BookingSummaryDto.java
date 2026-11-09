package Correspondances.LaPlateforme.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

public record BookingSummaryDto(
        Long id,
        String bookingReference,
        String passengerName,
        String travelerProfile,
        String departureStation,
        String arrivalStation,
        String serviceCode,
        Integer seatNumber,
        String comfortClass,
        LocalDate travelDate,
        BigDecimal totalPrice
) {}
