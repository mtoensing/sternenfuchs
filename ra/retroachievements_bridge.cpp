#include "ra/retroachievements_bridge.hpp"

#include <array>
#include <string>
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
    EventHandler on_event;

    Impl(ByteReader r, TriggerHandler h, EventHandler e)
        : reader(std::move(r)),
          on_trigger(std::move(h)),
          on_event(std::move(e)) {
        rc_runtime_init(&runtime);
    }

    ~Impl() {
        rc_runtime_destroy(&runtime);
    }
};

thread_local void* g_active_impl = nullptr;

RetroAchievementsBridge::RetroAchievementsBridge(
    ByteReader reader,
    TriggerHandler on_trigger,
    EventHandler on_event)
    : impl_(std::make_unique<Impl>(
          std::move(reader), std::move(on_trigger), std::move(on_event))) {}

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

std::optional<RetroAchievementsBridge::MeasuredProgress>
RetroAchievementsBridge::measured_progress(std::uint32_t id) const {
    unsigned value = 0U;
    unsigned target = 0U;
    if (!rc_runtime_get_achievement_measured(
            &impl_->runtime, id, &value, &target)) {
        return std::nullopt;
    }
    return MeasuredProgress{value, target};
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
    if (!event) return;
    auto* impl = static_cast<Impl*>(g_active_impl);
    if (!impl) return;
    if (impl->on_event) {
        impl->on_event(Event{event->id, event->value, event->type});
    }
    if (event->type == RC_RUNTIME_EVENT_ACHIEVEMENT_TRIGGERED
        && impl->on_trigger) {
        impl->on_trigger(event->id);
    }
}

} // namespace sternenfuchs::ra
