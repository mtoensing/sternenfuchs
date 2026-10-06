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
    using ByteReader = std::function<std::optional<std::uint8_t>(std::uint32_t)>;
    using TriggerHandler = std::function<void(std::uint32_t)>;

    RetroAchievementsBridge(ByteReader reader, TriggerHandler on_trigger = {});
    ~RetroAchievementsBridge();

    RetroAchievementsBridge(const RetroAchievementsBridge&) = delete;
    RetroAchievementsBridge& operator=(const RetroAchievementsBridge&) = delete;
    RetroAchievementsBridge(RetroAchievementsBridge&&) noexcept;
    RetroAchievementsBridge& operator=(RetroAchievementsBridge&&) noexcept;

    [[nodiscard]] bool activate_achievement(
        std::uint32_t id, std::string_view definition);
    void deactivate_achievement(std::uint32_t id);
    void evaluate_phase();
    void reset();

private:
    static std::uint32_t peek(
        std::uint32_t address, std::uint32_t num_bytes, void* userdata);
    static void handle_event(const struct rc_runtime_event_t* event);

    struct Impl;
    std::unique_ptr<Impl> impl_;
};

} // namespace sternenfuchs::ra
