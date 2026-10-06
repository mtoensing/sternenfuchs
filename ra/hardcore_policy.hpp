#pragma once

#include <cstdint>

namespace sternenfuchs::ra {

enum class AchievementMode : std::uint8_t {
    disabled,
    casual,
    hardcore
};

enum class SessionOrigin : std::uint8_t {
    clean_boot,
    resumed_state,
    diagnostic
};

enum class PlaybackChange : std::uint8_t {
    normal,
    fast_forward,
    slowdown,
    frame_advance,
    test_super_speed
};

class HardcorePolicy {
public:
    constexpr HardcorePolicy() noexcept = default;

    [[nodiscard]] constexpr AchievementMode mode() const noexcept {
        return mode_;
    }

    [[nodiscard]] constexpr bool is_hardcore() const noexcept {
        return mode_ == AchievementMode::hardcore;
    }

    [[nodiscard]] constexpr bool requires_full_reset_for(
        AchievementMode target) const noexcept {
        return target == AchievementMode::hardcore
            && mode_ != AchievementMode::hardcore;
    }

    [[nodiscard]] constexpr bool can_enter(
        AchievementMode target,
        SessionOrigin origin) const noexcept {
        if (target != AchievementMode::hardcore) return true;
        return origin == SessionOrigin::clean_boot;
    }

    constexpr bool enter(
        AchievementMode target,
        SessionOrigin origin) noexcept {
        if (!can_enter(target, origin)) {
            mode_ = AchievementMode::casual;
            return false;
        }
        mode_ = target;
        return true;
    }

    constexpr void force_casual() noexcept {
        mode_ = AchievementMode::casual;
    }

    [[nodiscard]] constexpr bool can_load_state() const noexcept {
        return !is_hardcore();
    }

    [[nodiscard]] constexpr bool can_save_state() const noexcept {
        return !is_hardcore();
    }

    [[nodiscard]] constexpr bool can_use_cheats() const noexcept {
        return !is_hardcore();
    }

    [[nodiscard]] constexpr bool can_use_scripted_input() const noexcept {
        return !is_hardcore();
    }

    [[nodiscard]] constexpr bool can_use_direct_stage_entry() const noexcept {
        return !is_hardcore();
    }

    [[nodiscard]] constexpr bool can_change_playback(
        PlaybackChange change) const noexcept {
        if (!is_hardcore()) return true;
        switch (change) {
        case PlaybackChange::normal:
            return true;
        case PlaybackChange::fast_forward:
            // Kept conservative until current RA compliance rules are
            // reconfirmed for the production integration.
            return false;
        case PlaybackChange::slowdown:
        case PlaybackChange::frame_advance:
        case PlaybackChange::test_super_speed:
            return false;
        }
        return false;
    }

private:
    AchievementMode mode_{AchievementMode::disabled};
};

} // namespace sternenfuchs::ra
