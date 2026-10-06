#include "ra/retroachievements_bridge.hpp"

#include <array>
#include <cassert>
#include <cstdint>
#include <optional>

int main() {
    using sternenfuchs::ra::RetroAchievementsBridge;

    std::array<std::uint8_t, 0x20000> wram{};
    std::uint32_t triggered = 0;

    RetroAchievementsBridge bridge{
        [&](std::uint32_t address) -> std::optional<std::uint8_t> {
            if (address >= wram.size()) return std::nullopt;
            return wram[address];
        },
        [&](std::uint32_t id) { triggered = id; }};

    assert(bridge.activate_achievement(5158U, "0xH0015af=5"));

    wram[0x15af] = 4;
    bridge.evaluate_phase();
    assert(triggered == 0U);

    wram[0x15af] = 5;
    bridge.evaluate_phase();
    assert(triggered == 5158U);

    bridge.reset();
    triggered = 0U;
    wram[0x15af] = 4;
    bridge.evaluate_phase();
    assert(triggered == 0U);

    bridge.deactivate_achievement(5158U);
}
