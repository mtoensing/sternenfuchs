#include "ra/ra_memory_adapter.hpp"

#include <cassert>
#include <cstdint>
#include <optional>

namespace {

struct FakeMapVm {
    mutable std::uint32_t last_address = 0xffffffffU;

    [[nodiscard]] std::optional<std::uint8_t>
    peek_ram_byte(std::uint32_t address) const noexcept {
        last_address = address;
        return static_cast<std::uint8_t>(address & 0xffU);
    }
};

} // namespace

int main() {
    using namespace sternenfuchs::ra;

    static_assert(logical_wram_to_snes(0x000000U) == 0x7E0000U);
    static_assert(logical_wram_to_snes(0x010000U) == 0x7F0000U);
    static_assert(logical_wram_to_snes(0x01FFFFU) == 0x7FFFFFU);
    static_assert(!logical_wram_to_snes(0x020000U).has_value());

    FakeMapVm map;

    const auto first = read_wram_byte(map, 0x000000U);
    assert(first.has_value());
    assert(map.last_address == 0x7E0000U);

    const auto middle = read_wram_byte(map, 0x010000U);
    assert(middle.has_value());
    assert(map.last_address == 0x7F0000U);

    const auto last = read_wram_byte(map, 0x01FFFFU);
    assert(last.has_value());
    assert(map.last_address == 0x7FFFFFU);

    map.last_address = 0x123456U;
    const auto invalid = read_wram_byte(map, 0x020000U);
    assert(!invalid.has_value());
    assert(map.last_address == 0x123456U);
}
