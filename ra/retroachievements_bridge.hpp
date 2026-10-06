#pragma once

#include <cstdint>
#include <functional>
#include <memory>
#include <optional>
#include <string_view>

struct rc_runtime_t;
struct rc_runtime_event_t;

namespace sternenfuchs::ra {

class RetroAchievementsBridge {
public:
    struct Event {
        std::uint32_t id{};
        std::int32_t value{};
        std::uint8_t type{};
    };

    struct MeasuredProgress {
        unsigned value{};
        unsigned target{};
    };

    using ByteReader = std::function<std::optional<std::uint8_t>(std::uint32_t)>;
    using TriggerHandler = std::function<void(std::uint32_t)>;
    using EventHandler = std::function<void(const Event&)>;

    RetroAchievementsBridge(
        ByteReader reader,
        TriggerHandler on_trigger = {},
        EventHandler on_event = {});
    ~RetroAchievementsBridge();

    RetroAchievementsBridge(const RetroAchievementsBridge&) = delete;
    RetroAchievementsBridge& operator=(const RetroAchievementsBridge&) = delete;
    RetroAchievementsBridge(RetroAchievementsBridge&&) noexcept;
    RetroAchievementsBridge& operator=(RetroAchievementsBridge&&) noexcept;

    [[nodiscard]] bool activate_achievement(
        std::uint32_t id, std::string_view definition);
    void deactivate_achievement(std::uint32_t id);
    void evaluate_phase();
    [[nodiscard]] std::optional<MeasuredProgress>
        measured_progress(std::uint32_t id) const;
    void reset();

private:
    static std::uint32_t peek(
        std::uint32_t address, std::uint32_t num_bytes, void* userdata);
    static void handle_event(const struct rc_runtime_event_t* event);

    struct Impl;
    std::unique_ptr<Impl> impl_;
};

} // namespace sternenfuchs::ra
