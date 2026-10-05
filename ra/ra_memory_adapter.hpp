#pragma once

#include <cstdint>
#include <optional>

namespace sternenfuchs::ra {

constexpr std::uint32_t kLogicalWramStart = 0x000000U;
constexpr std::uint32_t kLogicalWramEnd = 0x01FFFFU;
constexpr std::uint32_t kSnesWramStart = 0x7E0000U;

[[nodiscard]] constexpr std::optional<std::uint32_t>
logical_wram_to_snes(std::uint32_t address) noexcept {
    if (address > kLogicalWramEnd) return std::nullopt;
    return kSnesWramStart + address;
}

template <typename MapVmLike>
[[nodiscard]] std::optional<std::uint8_t>
read_wram_byte(const MapVmLike& map, std::uint32_t ra_address) noexcept {
    const auto snes_address = logical_wram_to_snes(ra_address);
    if (!snes_address) return std::nullopt;
    return map.peek_ram_byte(*snes_address);
}

} // namespace sternenfuchs::ra
