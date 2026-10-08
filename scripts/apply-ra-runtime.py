#!/usr/bin/env python3
from pathlib import Path
import sys

if len(sys.argv) != 2:
    raise SystemExit("usage: apply-ra-runtime.py STARFOX_SOURCE_DIR")

root = Path(sys.argv[1])

def replace_once(path: str, old: str, new: str) -> None:
    target = root / path
    text = target.read_text()
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{path}: expected exactly one match, found {count}: {old[:100]!r}")
    target.write_text(text.replace(old, new, 1))

# Link the downstream RA bridge into the real starfox_pc binary when the
# Sternenfuchs build supplies the pinned rcheevos paths.
replace_once(
    "CMakeLists.txt",
    """    else()
        add_executable(starfox_pc ${STARFOX_RUNTIME_SOURCES})
    endif()
    if(WINDOWS_STORE)
""",
    """    else()
        add_executable(starfox_pc ${STARFOX_RUNTIME_SOURCES})
    endif()
    if(DEFINED STERNENFUCHS_RA_ROOT
       AND DEFINED STERNENFUCHS_RCHEEVOS_INCLUDE
       AND DEFINED STERNENFUCHS_RCHEEVOS_LIB)
        target_sources(starfox_pc PRIVATE
            "${STERNENFUCHS_RA_ROOT}/ra/retroachievements_bridge.cpp")
        target_include_directories(starfox_pc PRIVATE
            "${STERNENFUCHS_RA_ROOT}"
            "${STERNENFUCHS_RCHEEVOS_INCLUDE}")
        target_link_libraries(starfox_pc PRIVATE
            "${STERNENFUCHS_RCHEEVOS_LIB}")
        target_compile_definitions(starfox_pc PRIVATE
            STERNENFUCHS_RA_ENABLED=1)
    endif()
    if(WINDOWS_STORE)
""")

# Extend the downstream menu shell with host-controlled active state and
# credential restoration across the mandatory Hardcore restart.
replace_once(
    "include/starfox/simulation/game_simulation.hpp",
    """    [[nodiscard]] bool ra_hardcore_requested() const noexcept {
        return ra_hardcore_requested_;
    }
    [[nodiscard]] std::string_view ra_username() const noexcept {
        return ra_username_;
    }
""",
    """    [[nodiscard]] bool ra_hardcore_requested() const noexcept {
        return ra_hardcore_requested_;
    }
    void set_ra_hardcore_requested(bool value) noexcept {
        ra_hardcore_requested_ = value;
    }
    [[nodiscard]] bool ra_hardcore_active() const noexcept {
        return ra_hardcore_active_;
    }
    void set_ra_hardcore_active(bool value) noexcept;
    [[nodiscard]] std::string_view ra_username() const noexcept {
        return ra_username_;
    }
    void set_ra_username(std::string_view value) {
        ra_username_.assign(value);
    }
    void set_ra_password(std::string_view value) {
        ra_password_.assign(value);
    }
""")

replace_once(
    "include/starfox/simulation/game_simulation.hpp",
    """    bool ra_hardcore_requested_{};
    std::string ra_username_;
""",
    """    bool ra_hardcore_requested_{};
    bool ra_hardcore_active_{};
    std::string ra_username_;
""")

# Hardcore activation normalizes every known gameplay-altering option using
# the normal runtime setters so native cartridge-side flags are cleared too.
replace_once(
    "src/simulation/game_simulation.cpp",
    """std::vector<std::uint8_t> GameSimulation::selectable_levels() const {
""",
    """void GameSimulation::set_ra_hardcore_active(bool value) noexcept {
    ra_hardcore_active_ = value;
    if (!value) return;
    set_god_mode(false);
    infinite_bombs_ = false;
    infinite_boost_ = false;
    infinite_lives_ = false;
    selected_level_ = 0U;
    set_default_laser(0U);
}

std::vector<std::uint8_t> GameSimulation::selectable_levels() const {
""")

# Hardcore still allows leaving the Cheats page, but no cheat action may
# mutate the session.
replace_once(
    "src/simulation/game_simulation.cpp",
    """        } else if (activate) {
            const auto backwards = (menu_input.pressed & starfox::input::left) != 0U;
""",
    """        } else if (activate && !ra_hardcore_active_) {
            const auto backwards = (menu_input.pressed & starfox::input::left) != 0U;
""")

# Runtime headers.
replace_once(
    "src/app/starfox_pc.cpp",
    """#include "starfox/state/files.hpp"
""",
    """#include "starfox/state/files.hpp"
#if defined(STERNENFUCHS_RA_ENABLED)
#include "ra/hardcore_policy.hpp"
#include "ra/ra_memory_adapter.hpp"
#include "ra/retroachievements_bridge.hpp"
#include "ra/starfox_achievements.hpp"
#endif
""")

# Session state lives outside the runtime-restart loop, so credentials survive
# a Casual -> Hardcore clean restart while raw passwords remain process-only.
replace_once(
    "src/app/starfox_pc.cpp",
    """        bool restart_runtime = true;
        bool first_runtime = true;
""",
    """        bool restart_runtime = true;
        bool first_runtime = true;
#if defined(STERNENFUCHS_RA_ENABLED)
        sternenfuchs::ra::HardcorePolicy ra_policy;
        bool ra_hardcore_requested = false;
        std::string ra_username;
        std::string ra_password;
        std::uint32_t ra_local_trigger_count = 0U;
#endif
""")

# Resolve requested mode at the clean restart boundary.
replace_once(
    "src/app/starfox_pc.cpp",
    """        while (restart_runtime) {
        restart_runtime = false;
        const auto hud_editor_preview =
""",
    """        while (restart_runtime) {
        restart_runtime = false;
#if defined(STERNENFUCHS_RA_ENABLED)
        if (ra_hardcore_requested && !ra_policy.is_hardcore()) {
            static_cast<void>(ra_policy.enter(
                sternenfuchs::ra::AchievementMode::hardcore,
                sternenfuchs::ra::SessionOrigin::clean_boot));
            initial_map = "BOOT";
        } else if (!ra_hardcore_requested && ra_policy.is_hardcore()) {
            ra_policy.force_casual();
        }
#endif
        const auto hud_editor_preview =
""")

# Restore RA UI/session values after all ordinary saved settings have been
# applied. Hardcore normalization is deliberately last so persisted cheats
# cannot leak into an eligible session.
replace_once(
    "src/app/starfox_pc.cpp",
    """        if (menu_preview) {
            game.set_god_mode(saved_pregame.god_mode);
            game.enable_menu_preview();
        }
        if (std::exchange(launch_game_after_preview, false)) {
            static_cast<void>(game.tick({starfox::input::start, starfox::input::start}));
        }
""",
    """        if (menu_preview) {
            game.set_god_mode(saved_pregame.god_mode);
            game.enable_menu_preview();
        }
        if (std::exchange(launch_game_after_preview, false)) {
            static_cast<void>(game.tick({starfox::input::start, starfox::input::start}));
        }
#if defined(STERNENFUCHS_RA_ENABLED)
        game.set_ra_username(ra_username);
        game.set_ra_password(ra_password);
        game.set_ra_hardcore_requested(ra_hardcore_requested);
        game.set_ra_hardcore_active(ra_policy.is_hardcore());

        std::optional<sternenfuchs::ra::RetroAchievementsBridge> ra_bridge;
        if (active_experience == starfox::simulation::Experience::original) {
            ra_bridge.emplace(
                [&game](std::uint32_t address)
                    -> std::optional<std::uint8_t> {
                    return sternenfuchs::ra::read_wram_byte(
                        game.map(), address);
                },
                [&ra_local_trigger_count](std::uint32_t id) {
                    ++ra_local_trigger_count;
                    std::cerr << "ra-local-trigger id=" << id
                              << " total=" << ra_local_trigger_count << '\\n';
                },
                [](const sternenfuchs::ra::RetroAchievementsBridge::Event& event) {
                    std::cerr << "ra-event id=" << event.id
                              << " type=" << unsigned(event.type)
                              << " value=" << event.value << '\\n';
                });
            for (const auto& achievement :
                 sternenfuchs::ra::kStarFoxAchievements) {
                if (!ra_bridge->activate_achievement(
                        achievement.id, achievement.definition)) {
                    throw std::runtime_error{
                        "Failed to activate embedded Star Fox RA definition"};
                }
            }
            std::cerr << "ra-offline-runtime: activated "
                      << sternenfuchs::ra::kStarFoxAchievements.size()
                      << " Star Fox achievements mode="
                      << (ra_policy.is_hardcore() ? "hardcore" : "casual")
                      << '\\n';
        }
#endif
""")

# Scripted input/state actions cannot drive an eligible Hardcore session.
replace_once(
    "src/app/starfox_pc.cpp",
    """        const auto scripted_presses = parse_scripted_presses(
            std::getenv("STARFOX_TEST_PRESSES"));
""",
    """#if defined(STERNENFUCHS_RA_ENABLED)
        const auto scripted_presses = ra_policy.can_use_scripted_input()
            ? parse_scripted_presses(std::getenv("STARFOX_TEST_PRESSES"))
            : std::vector<ScriptedPress>{};
#else
        const auto scripted_presses = parse_scripted_presses(
            std::getenv("STARFOX_TEST_PRESSES"));
#endif
""")

replace_once(
    "src/app/starfox_pc.cpp",
    """        const auto scripted_state_actions = parse_scripted_presses(
            test_frames ? std::getenv("STARFOX_TEST_STATE_ACTIONS") : nullptr);
""",
    """#if defined(STERNENFUCHS_RA_ENABLED)
        const auto scripted_state_actions = ra_policy.can_use_scripted_input()
            ? parse_scripted_presses(
                test_frames ? std::getenv("STARFOX_TEST_STATE_ACTIONS") : nullptr)
            : std::vector<ScriptedPress>{};
#else
        const auto scripted_state_actions = parse_scripted_presses(
            test_frames ? std::getenv("STARFOX_TEST_STATE_ACTIONS") : nullptr);
#endif
""")

# Save/load/slot UI is rejected as one unit in Hardcore.
replace_once(
    "src/app/starfox_pc.cpp",
    """                    try {
                        if (event.key.scancode == SDL_SCANCODE_F3) {
""",
    """#if defined(STERNENFUCHS_RA_ENABLED)
                    if (ra_policy.is_hardcore()) {
                        window.show_temporary_status(
                            "HARDCORE: SAVE STATES DISABLED");
                        continue;
                    }
#endif
                    try {
                        if (event.key.scancode == SDL_SCANCODE_F3) {
""")

# Host god-mode shortcut is unavailable.
replace_once(
    "src/app/starfox_pc.cpp",
    """                if (event.type == SDL_EVENT_KEY_DOWN
                    && !remap_menu.active
                    && starfox::app::InputBindings::matches_god_mode_shortcut(event.key)) {
""",
    """                if (event.type == SDL_EVENT_KEY_DOWN
                    && !remap_menu.active
#if defined(STERNENFUCHS_RA_ENABLED)
                    && ra_policy.can_use_cheats()
#endif
                    && starfox::app::InputBindings::matches_god_mode_shortcut(event.key)) {
""")

# Frame freeze/step is unavailable.
replace_once(
    "src/app/starfox_pc.cpp",
    """                const auto frame_debug_key = event.type == SDL_EVENT_KEY_DOWN
                    && (event.key.scancode == SDL_SCANCODE_F5
""",
    """                const auto frame_debug_key = event.type == SDL_EVENT_KEY_DOWN
#if defined(STERNENFUCHS_RA_ENABLED)
                    && !ra_policy.is_hardcore()
#endif
                    && (event.key.scancode == SDL_SCANCODE_F5
""")

# All accelerated/slow/debug playback collapses to normal speed in Hardcore.
replace_once(
    "src/app/starfox_pc.cpp",
    """            const auto speed_multiplier = advance_frozen_frame ? 1U
                : test_fast_forward ? 2U
                : starfox::timing::playback_speed_multiplier(tab_fast_forward,
                      control_fast_forward, shift_fast_forward,
                      super_fast_forward);
""",
    """            const auto speed_multiplier = advance_frozen_frame ? 1U
#if defined(STERNENFUCHS_RA_ENABLED)
                : ra_policy.is_hardcore() ? 1U
#endif
                : test_fast_forward ? 2U
                : starfox::timing::playback_speed_multiplier(tab_fast_forward,
                      control_fast_forward, shift_fast_forward,
                      super_fast_forward);
""")

# Evaluate once per preserved SNES/video phase, immediately after the native
# phase update and never per interpolated presentation frame.
replace_once(
    "src/app/starfox_pc.cpp",
    """                game.present_frame();
                rumble.advance(game.map(), gamepad,
""",
    """                game.present_frame();
#if defined(STERNENFUCHS_RA_ENABLED)
                if (ra_bridge) ra_bridge->evaluate_phase();
#endif
                rumble.advance(game.map(), gamepad,
""")

# Detect menu mode changes immediately after the authoritative game tick.
# Casual -> Hardcore persists credentials, requests a clean BOOT rebuild, and
# only becomes active on the next restart. Hardcore -> Casual is immediate.
replace_once(
    "src/app/starfox_pc.cpp",
    """                    const auto tick_result = game.tick(controls);
""",
    """                    const auto tick_result = game.tick(controls);
#if defined(STERNENFUCHS_RA_ENABLED)
                    ra_username.assign(game.ra_username());
                    ra_password.assign(game.ra_password());
                    if (game.ra_hardcore_requested()
                        != ra_hardcore_requested) {
                        ra_hardcore_requested =
                            game.ra_hardcore_requested();
                        if (ra_hardcore_requested) {
                            initial_map = "BOOT";
                            restart_runtime = true;
                            running = false;
                            std::cerr
                                << "ra-hardcore: clean restart requested\\n";
                            break;
                        }
                        ra_policy.force_casual();
                        game.set_ra_hardcore_active(false);
                        std::cerr << "ra-hardcore: switched to casual\\n";
                    }
#endif
""")

print("Applied Sternenfuchs live RetroAchievements runtime integration")
