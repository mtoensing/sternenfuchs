#!/usr/bin/env python3
from pathlib import Path
import sys

if len(sys.argv) != 2:
    raise SystemExit("usage: apply-ra-menu.py STARFOX_SOURCE_DIR")

root = Path(sys.argv[1])

def replace_once(path: str, old: str, new: str) -> None:
    target = root / path
    text = target.read_text()
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{path}: expected exactly one match, found {count}: {old[:80]!r}")
    target.write_text(text.replace(old, new, 1))

replace_once(
    "include/starfox/simulation/game_simulation.hpp",
    """enum class PregamePage {
    main,
    options,
    two_d,
    three_d,
    cheats,
};
""",
    """enum class PregamePage {
    main,
    options,
    two_d,
    three_d,
    cheats,
    retroachievements,
};
""")

replace_once(
    "include/starfox/simulation/game_simulation.hpp",
    """inline constexpr std::array<std::uint8_t, 12> options_menu_order{9,0,1,2,3,4,5,6,7,8,12,11};
inline constexpr std::array<std::uint8_t, 7> cheats_menu_order{0,1,2,3,4,5,6};
inline std::span<const std::uint8_t> pregame_menu_order(PregamePage page) {
""",
    """inline constexpr std::array<std::uint8_t, 13> options_menu_order{9,0,1,2,3,4,5,6,7,8,12,30,11};
inline constexpr std::array<std::uint8_t, 7> cheats_menu_order{0,1,2,3,4,5,6};
inline constexpr std::array<std::uint8_t, 4> retroachievements_menu_order{0,1,2,3};
inline std::span<const std::uint8_t> pregame_menu_order(PregamePage page) {
""")

replace_once(
    "include/starfox/simulation/game_simulation.hpp",
    """    case PregamePage::options: return options_menu_order;
    case PregamePage::cheats: return cheats_menu_order;
    default: return main_menu_order;
""",
    """    case PregamePage::options: return options_menu_order;
    case PregamePage::cheats: return cheats_menu_order;
    case PregamePage::retroachievements: return retroachievements_menu_order;
    default: return main_menu_order;
""")

replace_once(
    "include/starfox/simulation/game_simulation.hpp",
    """    [[nodiscard]] PregamePage pregame_page() const noexcept {
        return pregame_page_;
    }
    [[nodiscard]] bool god_mode() const noexcept { return god_mode_; }
""",
    """    [[nodiscard]] PregamePage pregame_page() const noexcept {
        return pregame_page_;
    }
    [[nodiscard]] bool ra_hardcore_requested() const noexcept {
        return ra_hardcore_requested_;
    }
    [[nodiscard]] std::string_view ra_username() const noexcept {
        return ra_username_;
    }
    [[nodiscard]] std::string_view ra_password() const noexcept {
        return ra_password_;
    }
    [[nodiscard]] bool ra_password_set() const noexcept {
        return !ra_password_.empty();
    }
    [[nodiscard]] std::uint8_t ra_editing_field() const noexcept {
        return ra_editing_field_;
    }
    [[nodiscard]] char ra_edit_character() const noexcept {
        constexpr std::string_view characters{
            "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_.abcdefghijklmnopqrstuvwxyz"};
        return characters[ra_edit_char_index_ % characters.size()];
    }
    [[nodiscard]] bool god_mode() const noexcept { return god_mode_; }
""")

replace_once(
    "include/starfox/simulation/game_simulation.hpp",
    """    std::uint8_t pregame_selection_{};
    PregamePage pregame_page_{PregamePage::main};
    bool runtime_options_open_{};
""",
    """    std::uint8_t pregame_selection_{};
    PregamePage pregame_page_{PregamePage::main};
    bool ra_hardcore_requested_{};
    std::string ra_username_;
    std::string ra_password_;
    std::uint8_t ra_editing_field_{};
    std::size_t ra_edit_char_index_{};
    bool runtime_options_open_{};
""")

replace_once(
    "src/simulation/game_simulation.cpp",
    """    const auto previous_selection = pregame_selection_;
""",
    """    if (pregame_page_ == PregamePage::retroachievements
        && ra_editing_field_ != 0U) {
        constexpr std::string_view characters{
            "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_.abcdefghijklmnopqrstuvwxyz"};
        bool changed = false;
        if ((menu_input.pressed & starfox::input::left) != 0U) {
            ra_edit_char_index_ = (ra_edit_char_index_ + characters.size() - 1U)
                % characters.size();
            changed = true;
        } else if ((menu_input.pressed & starfox::input::right) != 0U) {
            ra_edit_char_index_ = (ra_edit_char_index_ + 1U) % characters.size();
            changed = true;
        }
        auto& target = ra_editing_field_ == 1U ? ra_username_ : ra_password_;
        const auto maximum = ra_editing_field_ == 1U ? 20U : 64U;
        if ((menu_input.pressed & starfox::input::a) != 0U
            && target.size() < maximum) {
            target.push_back(characters[ra_edit_char_index_]);
            changed = true;
        }
        if ((menu_input.pressed & starfox::input::y) != 0U && !target.empty()) {
            target.pop_back();
            changed = true;
        }
        if ((menu_input.pressed & (starfox::input::b | starfox::input::start
            | starfox::input::select)) != 0U) {
            ra_editing_field_ = 0U;
            changed = true;
        }
        if (changed) queue_sound_effect(0x11U);
        result.audio_port_writes = map_.take_apu_port_writes();
        return result;
    }

    const auto previous_selection = pregame_selection_;
""")

replace_once(
    "src/simulation/game_simulation.cpp",
    """    if (pregame_page_ == PregamePage::cheats) {
""",
    """    if (pregame_page_ == PregamePage::retroachievements) {
        const auto activate = (menu_input.pressed & (starfox::input::a
            | starfox::input::select | starfox::input::left
            | starfox::input::right)) != 0U;
        if ((menu_input.pressed & starfox::input::b) != 0U
            || (pregame_selection_ == 3U && activate)) {
            pregame_page_ = PregamePage::options;
            pregame_selection_ = 30U;
            queue_sound_effect(0x11U);
        } else if (activate) {
            if (pregame_selection_ == 0U) {
                ra_editing_field_ = 1U;
            } else if (pregame_selection_ == 1U) {
                ra_editing_field_ = 2U;
            } else if (pregame_selection_ == 2U) {
                ra_hardcore_requested_ = !ra_hardcore_requested_;
            }
            queue_sound_effect(0x11U);
        }
        result.audio_port_writes = map_.take_apu_port_writes();
        return result;
    }

    if (pregame_page_ == PregamePage::cheats) {
""")

replace_once(
    "src/simulation/game_simulation.cpp",
    """        if (go_back) {
            pregame_page_ = PregamePage::main;
            pregame_selection_ = 14U;
            queue_sound_effect(0x11U);
        } else if (pregame_selection_ == 0U
""",
    """        if (go_back) {
            pregame_page_ = PregamePage::main;
            pregame_selection_ = 14U;
            queue_sound_effect(0x11U);
        } else if (pregame_selection_ == 30U
                   && (menu_input.pressed & (starfox::input::left
                       | starfox::input::right | starfox::input::select
                       | starfox::input::a)) != 0U) {
            pregame_page_ = PregamePage::retroachievements;
            pregame_selection_ = 0U;
            queue_sound_effect(0x11U);
        } else if (pregame_selection_ == 0U
""")

replace_once(
    "src/simulation/game_state.cpp",
    """        || !valid_enum(result->pregame_page_, PregamePage::cheats)
""",
    """        || !valid_enum(result->pregame_page_, PregamePage::retroachievements)
""")

replace_once(
    "src/app/starfox_pc.cpp",
    """                    if (game.pregame_page() == starfox::simulation::PregamePage::cheats) {
""",
    """                    if (game.pregame_page()
                        == starfox::simulation::PregamePage::retroachievements) {
                        draw_centred("RETROACHIEVEMENTS", 27, 10U);
                        const auto editing = game.ra_editing_field();
                        const auto edit_value = std::string{"ADD "}
                            + game.ra_edit_character();
                        const auto username = game.ra_username().empty()
                            ? std::string{"NOT SET"}
                            : std::string{game.ra_username()};
                        draw_row("USERNAME",
                            editing == 1U ? std::string_view{edit_value}
                                          : std::string_view{username},
                            60, game.pregame_selection() == 0U);
                        draw_row("PASSWORD",
                            editing == 2U ? std::string_view{edit_value}
                                : game.ra_password_set()
                                    ? std::string_view{"********"}
                                    : std::string_view{"NOT SET"},
                            100, game.pregame_selection() == 1U);
                        draw_row("HARDCORE",
                            game.ra_hardcore_requested()
                                ? std::string_view{"ON"}
                                : std::string_view{"OFF"},
                            140, game.pregame_selection() == 2U);
                        draw_row("BACK", "", 180,
                            game.pregame_selection() == 3U);
                        constexpr std::array<std::int32_t, 4> ra_cursor_y{
                            63, 103, 143, 183};
                        draw_cursor(ra_cursor_y[game.pregame_selection()]);
                        if (editing != 0U) {
                            draw_centred(
                                "LEFT/RIGHT CHAR  A ADD  Y DELETE  START DONE",
                                205, 13U);
                        }
                    } else if (game.pregame_page() == starfox::simulation::PregamePage::cheats) {
""")

replace_once(
    "src/app/starfox_pc.cpp",
    """                        draw_row("LANGUAGE", language_names[game.language()], 185,
                            game.pregame_selection() == 12U);
                        draw_row("BACK", "", 200,
                            game.pregame_selection() == 11U);
""",
    """                        draw_row("LANGUAGE", language_names[game.language()], 185,
                            game.pregame_selection() == 12U);
                        draw_row("RETROACHIEVEMENTS", "A  OPEN", 200,
                            game.pregame_selection() == 30U);
                        draw_row("BACK", "", 215,
                            game.pregame_selection() == 11U);
""")

replace_once(
    "src/app/starfox_pc.cpp",
    """                        constexpr std::array<std::int32_t, 13> cursor_y{
                            43, 58, 73, 88, 103, 118, 133, 157, 173, 28, 197, 203, 188};
                        draw_cursor(cursor_y[game.pregame_selection()]);
""",
    """                        std::array<std::int32_t, 31> cursor_y{};
                        cursor_y.fill(0);
                        cursor_y[0]=43; cursor_y[1]=58; cursor_y[2]=73;
                        cursor_y[3]=88; cursor_y[4]=103; cursor_y[5]=118;
                        cursor_y[6]=133; cursor_y[7]=157; cursor_y[8]=173;
                        cursor_y[9]=28; cursor_y[11]=218; cursor_y[12]=188;
                        cursor_y[30]=203;
                        draw_cursor(cursor_y[game.pregame_selection()]);
""")

print("Applied Sternenfuchs RetroAchievements account menu transform")
