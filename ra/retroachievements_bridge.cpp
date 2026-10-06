#include "ra/retroachievements_bridge.hpp"

#include <array>
#include <utility>

extern "C" {
#include "rc_error.h"
#include "rc_runtime.h"
}

namespace sternenfuchs::ra {

struct RetroAchievementsBridge::Impl {
    rc_runtime_t runtime{};
    ByteReader reader;
    TriggerHandler on_trigger;

    Impl(ByteReader r, TriggerHandler h)
        : reader(std::move(r)), on_trigger(std::move(h)) {
        rc_runtime_init(&runtime);
    }

    ~Impl() {
        rc_runtime_destroy(&runtime);
    }
};

thread_local RetroAchievementsBridge::Impl* g_active_impl = nullptr;

RetroAchievementsBridge::RetroAchievementsBridge(
    ByteReader reader, TriggerHandler on_trigger)
    : impl_(std::make_unique<Impl>(
          std::move(reader), std::move(on_trigger))) {}

RetroAchievementsBridge::~RetroAchievementsBridge() = default;
RetroAchievementsBridge::RetroAchievementsBridge(
    RetroAchievementsBridge&&) noexcept = default;
RetroAchievementsBridge& RetroAchievementsBridge::operator=(
    RetroAchievementsBridge&&) noexcept = default;

bool RetroAchievementsBridge::activate_achievement(
    std::uint32_t id, std::string_view definition) {
    const std::string owned{definition};
    return rc_runtime_activate_achievement(
        &impl_->runtime, id, owned.c_str(), nullptr, 0) == RC_OK;
}

void RetroAchievementsBridge::deactivate_achievement(std::uint32_t id) {
    rc_runtime_deactivate_achievement(&impl_->runtime, id);
}

void RetroAchievementsBridge::evaluate_phase() {
    g_active_impl = impl_.get();
    rc_runtime_do_frame(
        &impl_->runtime,
        &RetroAchievementsBridge::handle_event,
        &RetroAchievementsBridge::peek,
        impl_.get(),
        nullptr);
    g_active_impl = nullptr;
}

void RetroAchievementsBridge::reset() {
    rc_runtime_reset(&impl_->runtime);
}

std::uint32_t RetroAchievementsBridge::peek(
    std::uint32_t address, std::uint32_t num_bytes, void* userdata) {
    auto* impl = static_cast<Impl*>(userdata);
    if (!impl || !impl->reader || num_bytes == 0U || num_bytes > 4U)
        return 0U;

    std::uint32_t value = 0U;
    for (std::uint32_t i = 0; i < num_bytes; ++i) {
        const auto byte = impl->reader(address + i);
        if (!byte) return 0U;
        value |= static_cast<std::uint32_t>(*byte) << (i * 8U);
    }
    return value;
}

void RetroAchievementsBridge::handle_event(
    const rc_runtime_event_t* event) {
    if (!event || event->type != RC_RUNTIME_EVENT_ACHIEVEMENT_TRIGGERED)
        return;
    if (g_active_impl && g_active_impl->on_trigger)
        g_active_impl->on_trigger(event->id);
}

} // namespace sternenfuchs::ra
